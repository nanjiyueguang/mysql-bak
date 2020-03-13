mysqldump 自动部署脚本

# 作用

- 根据筛选出的namespace 和 service 自动部署dump cronjob
- 使用私有镜像 `docker pull harbor.cloudminds.com/mysql/mysqldump:1.1.2`
- 自动获取部分部署的 root 密码 `getPass.sh`

# 使用方式

> 部署的主脚本 `deploment_cronjob.sh ` 可以通过不加参数执行该脚本获取帮助

1. 如果在集群上不存在存放备份的pvc 需要先创建pvc `./deploment_cronjob.sh NAMESPACE PVC-NAME`

2.  存在pvc

   1. 开始之前，当前目录下需要有一个文件 `source.txt` ，此文件包含所有的要添加备份的namespace信息

      ```shell
      |># less source.txt 
      big-data
      big-data-dev
      ......
      ```

      

   2. 执行脚本`getMysqlServer.sh*`，该脚本自动获取service等信息，在当前目录下生成 detail.txt 和 namespace.txt 文件

   3. 执行 `deployment_cronjob.sh now` 生成 cron-{namespace}_{servicename}.yaml 文件

   4. 检查yaml文件正确后，使用`kubectl apply -f cron-{namespace}_{servicename}.yaml `部署cronjob