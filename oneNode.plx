#!/usr/bin/perl
use warnings;
use strict 'vars';
use Getopt::Std;;
use vars qw($opt_a $opt_s $opt_m $opt_e);

#########################################################################################
#    ###############################################################################    #
#   #      说明：   处理单节点相关性能数据                                          #   #
#   #      使用：   perl   oneMode.plx                                              #   #
#   #      AUTH：   wangyunzeng                                                     #   #
#   #      VER ：   1.0                                                             #   #
#   #      TIME：   2012-09-07   15:01   create                                     #   #
#    ###############################################################################    #
######################################################################################### 

#使用方法
getopts("asme");

if (!($opt_a || $opt_m || $opt_s|| $opt_e))
{
   print "\n【使用方法】\n";
   print "\n perl oneMode.plx  \n \n      选项:  -a  -m  -s  -e\n\n\t     -a: MMSG-彩信   表示网关类型为彩信网关\n\n\t     -m: M模块       表示类型为M模块\n\n\t     -s: SMS-业务    表示短信业务网关\n\n\t     -e: SMS-行业    表示短信行业网关\n \n \n";
   exit;
}

##说明
$~="ONNodeDec";
write;

format ONNodeDec=

============================================================
【说明】

    1、本脚本仅适用于单机环境下执行相关脚本，避免因脚本过多
        
       导致用户单个执行脚本过于麻烦，同时避免脚本执行的遗漏;

    2、执行本脚本前，请确认已经执行了run.sh进行了性能数据的
     
       收集操作.

============================================================

.

##判断source路径是否存在，以及相关txt文件是否存在
(-d "./source") || die "Dir [source] is not exist,$!\n\n";
(-f "./source/iostat.txt") || die "File [iostat.txt] is not exist,$!\n\n";
(-f "./source/cpu_mem.txt") || die "File [cpu_mem.txt] is not exist,$!\n\n";
(-f "./source/memused.txt") || die "File [memused.txt] is not exist,$!\n\n";
(-f "./source/sar.txt") || die "File [sar.txt] is not exist,$!\n\n";
(-f "./source/vmstat.txt") || die "File [vmstat.txt] is not exist,$!\n\n";


if($opt_a)
{
   system("perl perform.plx -a");           #性能数据文件处理
   system("perl sar_dp.plx");               #性能数据文件处理
   system("perl dispose.plx -a");           #话单相关处理
   system("perl mmsg_query.plx");           #server manager消息队列处理
   system("perl osinfo.plx");               #操作系统硬件配置信息
   
   #add by wangyunzeng 2012-10-30 增加tar压缩包操作
   system("perl tar.plx");
}
elsif($opt_s)
{
   system("perl perform.plx -s");           #性能数据文件处理
   system("perl sar_dp.plx");               #性能数据文件处理
   system("perl dispose.plx -s");           #话单相关处理
   system("perl osinfo.plx");               #操作系统硬件配置信息
   
   #add by wangyunzeng 2012-10-30 增加tar压缩包操作
   system("perl tar.plx");
}
elsif($opt_m)
{
   system("perl perform.plx -m");           #性能数据文件处理
   system("perl sar_dp.plx");               #性能数据文件处理
   system("perl dispose.plx -m");           #话单相关处理
   system("perl osinfo.plx");               #操作系统硬件配置信息
   
   #add by wangyunzeng 2012-10-30 增加tar压缩包操作
   system("perl tar.plx");   
}
elsif($opt_e)
{
   system("perl perform.plx -e");           #性能数据文件处理
   system("perl sar_dp.plx");               #性能数据文件处理
   system("perl dispose.plx -e");           #话单相关处理
   system("perl osinfo.plx");               #操作系统硬件配置信息
   
   #add by wangyunzeng 2012-10-30 增加tar压缩包操作
   system("perl tar.plx");  
}
