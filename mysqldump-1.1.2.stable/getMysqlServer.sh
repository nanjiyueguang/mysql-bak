# cat getMysqlServer.sh 
#!/bin/bash
function reportError(){
    echo $(date)_error : $1
 }

function reportLog(){
    echo $(date)_log : $1
}

function getMysqlDeploy(){
#    kubectl get namespace |tail -n +2 |awk '{print $1}'|while read v_namespace
cat source.txt |while read v_namespace
    do
        tmp_mysql_deploy=`kubectl get deploy -n ${v_namespace} |tail -n +2 | awk '{if($2=="1"||$2=="1/1") print $1}'|grep mysql`
        if [ -z "${tmp_mysql_deploy}" ];then 
            continue
            reportLog "未搜索到mysql deployment"
        fi
        
        for v_deploy in `echo ${tmp_mysql_deploy}`
        do
            tmp_mysql_label=`kubectl describe deploy ${v_deploy} -n ${v_namespace} |grep Selector: |tail -n -1|awk '{print $2}'`
            if [ -z "${tmp_mysql_label}" ];then 
                continue
                reportLog "未搜索到 ${v_deploy} 的label 标签"
            fi
            
            for tmp_service in `kubectl get service -n ${v_namespace}|tail -n +2 |awk '{print $1}'`
            do
                kubectl describe service ${tmp_service} -n ${v_namespace} |grep "Selector:"|grep "${tmp_mysql_label}" 
                if [ $? -eq 0 ];then
                	# 生成统计文件
                    echo ${v_namespace} ${tmp_service} ${v_deploy} ${tmp_mysql_label}|tee >>detail.txt
                    echo ${v_namespace} ${tmp_service} >>namespace.txt
                    
                fi
            done
        done
    done
}

_is_sourced() {
        [ "${#FUNCNAME[@]}" -ge 2 ] \
                && [ "${FUNCNAME[0]}" = '_is_sourced' ] \
                && [ "${FUNCNAME[1]}" = 'source' ]
}
_main()
{
    getMysqlDeploy
}

if ! _is_sourced; then
        _main "$@"
fi
