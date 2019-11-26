#!/usr/bin/perl
use warnings;
use strict 'vars';
use Config::IniFiles;
use Getopt::Std;;
use vars qw($opt_a $opt_s $opt_m $opt_e);

#########################################################################################
#    ###############################################################################    #
#   #      ˵����   ���Զ�˷��������Ƿ����performanceĿ¼                         #   #
#   #      ʹ�ã�   perl   dircheck.plx                                             #   #
#   #      AUTH��   wangyunzeng                                                     #   #
#   #      VER ��   1.0                                                             #   #
#   #      TIME��   2012-08-29   10:41   create                                     #   #
#    ###############################################################################    #
#########################################################################################

my $cfg = Config::IniFiles->new( -file => "/config.ini" );
my $remote_path_mmsg=$cfg->val('GW_PERFROMANCE','MMSG_SCP_Path' ) || '';        #Զ�˴�Žű�·��,����ʹ��
my $remote_path_sms=$cfg->val('GW_PERFROMANCE','SMS_SCP_Path' ) || '';          #Զ�˴�Žű�·��,����ʹ��
my $remote_path_m=$cfg->val('GW_PERFROMANCE','M_SCP_Path' ) || '';              #Զ�˴�Žű�·��,Mģ��ʹ��
#my $config=$cfg->val('GW_PERFROMANCE','Config') || '';                          #�����ļ���Ϣ

#ʹ�÷���
getopts("asme");

if (!($opt_a || $opt_m || $opt_s|| $opt_e))
{
   print "\n��ʹ�÷�����\n";
   print "\n perl perform.plx \n \n      ѡ��:  -a  -m  -s  -e\n\n\t     -a: MMSG-����   ��ʾ��������Ϊ��������\n\n\t     -m: Mģ��       ��ʾ����ΪMģ��\n\n\t     -s: SMS-ҵ��    ��ʾ����ҵ������\n\n\t     -e: SMS-��ҵ    ��ʾ������ҵ����\n \n \n";
   exit;
}

if($opt_a)
{
    #�ļ����·��
    unless (-d "$remote_path_mmsg")
    {
        mkdir("$remote_path_mmsg", 0755) || die "Make directory $remote_path_mmsg error,$!\n";
    }

    if(-d "$remote_path_mmsg")
    {
        system("mkdir -p $remote_path_mmsg/config");
        if(! -d "$remote_path_mmsg/config")
        {
           print "\n����A������configĿ¼ʧ��.\n\n";
           exit;
        }
    }
}
elsif($opt_s)
{
    #�ļ����·��
    unless (-d "$remote_path_sms")
    {
        mkdir("$remote_path_sms", 0755) || die "Make directory $remote_path_sms error,$!\n";
    }

    if(-d "$remote_path_sms")
    {
        system("mkdir -p $remote_path_sms/config");
        if(! -d "$remote_path_sms/config")
        {
           print "\n����A������configĿ¼ʧ��.\n\n";
           exit;
        }
    }
}
elsif($opt_m)
{
    #�ļ����·��
    unless (-d "$remote_path_m")
    {
        mkdir("$remote_path_m", 0755) || die "Make directory $remote_path_m error,$!\n";
    }
    if(-d "$remote_path_m")
    {
        system("mkdir -p $remote_path_m/config");
        if(! -d "$remote_path_m/config")
        {
           print "\nMģ�飺����configĿ¼ʧ��.\n\n";
           exit;
        }
    }    
}
elsif($opt_e)
{
    #�ļ����·��
    unless (-d "$remote_path_sms")
    {
        mkdir("$remote_path_sms", 0755) || die "Make directory $remote_path_sms error,$!\n";
    }

    if(-d "$remote_path_sms")
    {
        system("mkdir -p $remote_path_sms/config");
        if(! -d "$remote_path_sms/config")
        {
           print "\n����A������configĿ¼ʧ��.\n\n";
           exit;
        }
    }
}
else
{
  #do nothing  
}