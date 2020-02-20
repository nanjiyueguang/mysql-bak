#!/bin/bash
function reportError(){
    echo $(date)_error : $1
 }

function reportLog(){
    echo $(date)_log : $1
}

function createMysqlUser(){
local v_namespace=$1
local v_service=$2
local v_deployment=$3
local v_label=$4

#获取密码
local v_pass=`./getPass.sh ${v_namespace} ${v_service}`


#获取IP并判断ip 是否正确
local v_mysql_ip=`kubectl get pod -n ${v_namespace} -o wide -l ${v_label} |awk '{print $6}' |tail -n +2`

regex="\b(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[1-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[1-9])\b"
echo -e " \n 为以下IP创建用户：$v_mysql_ip，ns: ${v_namespace}，service: ${v_service}"
ck=`echo $v_mysql_ip | egrep $regex | wc -l`
#创建user
if [ ${ck} -eq 1 ];then
        local v_version=`mysql -h${v_mysql_ip} -uroot -p${v_pass} -N -e 'select version();' 2>&1 |grep -v "Warning"`
        if [ "${v_version}" == "5.7.*" ];then
              mysql -h${v_mysql_ip} -uroot -p${v_pass}<57user.sql 2>&1 |grep -v "Warning"
        else
              mysql -h${v_mysql_ip} -uroot -p${v_pass}<56user.sql 2>&1 |grep -v "Warning"
        fi
else
        reportError "获取IP错误 ."
fi

}

function changeNamespace(){
    local v_namespace=$1
    local v_pvc=$2
    sed -i s/"namespace: *.*"/"namespace: ${v_namespace}"/g mysqldump.yaml
    sed -i s/"claimName: *.*"/"claimName: ${v_pvc}"/g mysqldump.yaml
}

function copyFile(){
    local v_namespace=$1
    local v_service=$2
    if [ -f mysqldump.yaml ];then
        cp -rf mysqldump.yaml cron_${v_namespace}_${v_service}.yaml
        # 修改各部分的name值
        sed -i s/'name: config-mysqldump'/"name: conf-${v_namespace}-${v_service}"/g cron_${v_namespace}_${v_service}.yaml
        sed -i s/'name: srt-mysqldump'/"name: srt-${v_namespace}-${v_service}"/g cron_${v_namespace}_${v_service}.yaml
        sed -i s/'name: cron-mysqldump'/"name: cron-${v_namespace}-${v_service}"/g cron_${v_namespace}_${v_service}.yaml
        # 修改service 
        sed -i s/'dbhost: svc-mysql-test-02.default'/"dbhost: ${v_service}.${v_namespace}"/g cron_${v_namespace}_${v_service}.yaml
    else
        reportError "mysqldump.cronjob.*.txt 文件不存在"
    fi
}

function changeTime(){
    declare -i i=0
    for cronjob in `ls cron_*`
    do
        local time=`date +"%M %H" -d "+ $i minutes 18:01"`
        sed -i s/"schedule: *.* \* \* \*"/"schedule: ${time} \* \* \*"/g ${cronjob}
        i=i+2
    done
}

_is_sourced() {
        [ "${#FUNCNAME[@]}" -ge 2 ] \
                && [ "${FUNCNAME[0]}" = '_is_sourced' ] \
                && [ "${FUNCNAME[1]}" = 'source' ]
}

_main1()
{
    if [ -f "namespace.txt" ];then
        cat namespace.txt |grep -Ev "^$|#"|while read v_namespace v_service
        do
            copyFile ${v_namespace} ${v_service}
            reportLog "${v_service} in namespace ${v_namespace} deploy succeed "
        done
        
        #change schedule time
        changeTime
    else
        reportError "namespace.txt 文件不存在"
    fi
}

_main2(){
    changeNamespace $@
}


if ! _is_sourced; then
    if [ $# -eq 1 ] && [ "$@" == 'now' ];then
        _main1
    elif [ $# -eq 1 ] && [ "$@" == 'create_user' ];then
        if [ -f detail.txt ];then
                cat detail.txt|while read namespace service deployment label 
                do
                        createMysqlUser ${namespace} ${service} ${deployment} ${label}
                done

        else
                reportError "detail.txt 文件不存在 ."
        fi
    elif [ $# -eq 2 ];then
        _main2 "$@"
    else
        reportError "如果是第一次在本节点执行脚本，请使用 ./deploment_cronjob.sh NAMESPACE PVC-NAME ."
        reportError "如果是重复部署，请使用 ./deploment_cronjob.sh now ."
    fi
fi
