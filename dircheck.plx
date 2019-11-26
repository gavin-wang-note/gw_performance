#!/usr/bin/perl
use warnings;
use strict 'vars';
use Config::IniFiles;
use Getopt::Std;;
use vars qw($opt_a $opt_s $opt_m $opt_e);

#########################################################################################
#    ###############################################################################    #
#   #      说明：   检查远端服务器上是否存在performance目录                         #   #
#   #      使用：   perl   dircheck.plx                                             #   #
#   #      AUTH：   wangyunzeng                                                     #   #
#   #      VER ：   1.0                                                             #   #
#   #      TIME：   2012-08-29   10:41   create                                     #   #
#    ###############################################################################    #
#########################################################################################

my $cfg = Config::IniFiles->new( -file => "/config.ini" );
my $remote_path_mmsg=$cfg->val('GW_PERFROMANCE','MMSG_SCP_Path' ) || '';        #远端存放脚本路径,彩信使用
my $remote_path_sms=$cfg->val('GW_PERFROMANCE','SMS_SCP_Path' ) || '';          #远端存放脚本路径,短信使用
my $remote_path_m=$cfg->val('GW_PERFROMANCE','M_SCP_Path' ) || '';              #远端存放脚本路径,M模块使用
#my $config=$cfg->val('GW_PERFROMANCE','Config') || '';                          #配置文件信息

#使用方法
getopts("asme");

if (!($opt_a || $opt_m || $opt_s|| $opt_e))
{
   print "\n【使用方法】\n";
   print "\n perl perform.plx \n \n      选项:  -a  -m  -s  -e\n\n\t     -a: MMSG-彩信   表示网关类型为彩信网关\n\n\t     -m: M模块       表示类型为M模块\n\n\t     -s: SMS-业务    表示短信业务网关\n\n\t     -e: SMS-行业    表示短信行业网关\n \n \n";
   exit;
}

if($opt_a)
{
    #文件存放路径
    unless (-d "$remote_path_mmsg")
    {
        mkdir("$remote_path_mmsg", 0755) || die "Make directory $remote_path_mmsg error,$!\n";
    }

    if(-d "$remote_path_mmsg")
    {
        system("mkdir -p $remote_path_mmsg/config");
        if(! -d "$remote_path_mmsg/config")
        {
           print "\n彩信A：创建config目录失败.\n\n";
           exit;
        }
    }
}
elsif($opt_s)
{
    #文件存放路径
    unless (-d "$remote_path_sms")
    {
        mkdir("$remote_path_sms", 0755) || die "Make directory $remote_path_sms error,$!\n";
    }

    if(-d "$remote_path_sms")
    {
        system("mkdir -p $remote_path_sms/config");
        if(! -d "$remote_path_sms/config")
        {
           print "\n短信A：创建config目录失败.\n\n";
           exit;
        }
    }
}
elsif($opt_m)
{
    #文件存放路径
    unless (-d "$remote_path_m")
    {
        mkdir("$remote_path_m", 0755) || die "Make directory $remote_path_m error,$!\n";
    }
    if(-d "$remote_path_m")
    {
        system("mkdir -p $remote_path_m/config");
        if(! -d "$remote_path_m/config")
        {
           print "\nM模块：创建config目录失败.\n\n";
           exit;
        }
    }    
}
elsif($opt_e)
{
    #文件存放路径
    unless (-d "$remote_path_sms")
    {
        mkdir("$remote_path_sms", 0755) || die "Make directory $remote_path_sms error,$!\n";
    }

    if(-d "$remote_path_sms")
    {
        system("mkdir -p $remote_path_sms/config");
        if(! -d "$remote_path_sms/config")
        {
           print "\n短信A：创建config目录失败.\n\n";
           exit;
        }
    }
}
else
{
  #do nothing  
}