#!/bin/bash
function reportError(){
    echo $(date)_error : $1
 }

function reportLog(){
    echo $(date)_log : $1
}
function getPassByService(){
local v_namespace=$1
local v_service=$2

vTemp=`kubectl describe deploy -n ${v_namespace} -l $(kubectl describe service ${v_service} -n ${v_namespace} |grep Selector |awk '{print $2}')|grep -i mysql-root-password `
if [ ! -z "${vTemp}" ];then
    v_secret=$(echo ${vTemp}|awk -F "['']" '{print $(NF-1)}')
    v_pass=`kubectl get secret ${v_secret} -n ${v_namespace} -o yaml |grep mysql-root-password |awk '{print $2}'`
    echo ${v_pass}|base64 -d 
else
    v_pass=`kubectl describe deploy -n ${v_namespace} -l $(kubectl describe service ${v_service} -n ${v_namespace} |grep Selector |awk '{print $2}')|grep MYSQL_ROOT_PASSWORD|awk '{print $2}'`
    if [ ! -z "${v_pass}" ];then
       echo ${v_pass}|awk '{print $1}'
    else
        reportError "未找到 mysql_root_password 或者 未使用secret文件"
    fi
fi
}

_main(){
    if [ $# -eq 2 ];then
        getPassByService $@
    else
    	echo "eg: getPass.sh namespace service "
	
    fi
}

_main "$@"
