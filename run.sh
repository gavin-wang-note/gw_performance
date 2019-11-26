./gather.sh -s 1 -d 120 -f ./source/cpu_mem.txt -t a &

##参数描述如下:
#-s ： 是指统计数据间隔；
#-d ： 是统计次数；
#-f ： 是各进程系统信息保存文件,-f后面文件名请不要修改；
#-t ： 表示产品类型，取值为a/s/m/e，a:彩信  s:短信业务 m:M模块  e:短信行业

#run.sh         是启动脚本
#gather.sh      是采集数据脚本
