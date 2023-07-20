1.脚本先上传到其中一台服务器上（执行这些脚本的服务器）

2.脚本依赖expect程序，需要在执行这些脚本的服务器上安装expect,安装方式：yum install expect

3.修改脚本的用户名和密码

4.脚本需要使用root用户或者有sudo权限的普通用户执行

5.修改node.list和node.txt文件，改成待部署集群的节点信息

5.命令操作如下：
	
	batch_cmd.sh：批量执行命令脚本，如：sh batch_cmd.sh node.list "ls /"
	batch_scp.sh: 批量拷贝文件命令，如：sh batch_scp.sh node.list src target
	batch_rename.sh: 批量修改主机名，如: sh batch_rename_cmd.sh node.txt