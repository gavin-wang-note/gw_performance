#!/usr/bin/perl
use warnings;
use strict 'vars';
use Getopt::Std;;
use vars qw($opt_a $opt_s $opt_m $opt_e);

#########################################################################################
#    ###############################################################################    #
#   #      ˵����   �����ڵ������������                                          #   #
#   #      ʹ�ã�   perl   oneMode.plx                                              #   #
#   #      AUTH��   wangyunzeng                                                     #   #
#   #      VER ��   1.0                                                             #   #
#   #      TIME��   2012-09-07   15:01   create                                     #   #
#    ###############################################################################    #
######################################################################################### 

#ʹ�÷���
getopts("asme");

if (!($opt_a || $opt_m || $opt_s|| $opt_e))
{
   print "\n��ʹ�÷�����\n";
   print "\n perl oneMode.plx  \n \n      ѡ��:  -a  -m  -s  -e\n\n\t     -a: MMSG-����   ��ʾ��������Ϊ��������\n\n\t     -m: Mģ��       ��ʾ����ΪMģ��\n\n\t     -s: SMS-ҵ��    ��ʾ����ҵ������\n\n\t     -e: SMS-��ҵ    ��ʾ������ҵ����\n \n \n";
   exit;
}

##˵��
$~="ONNodeDec";
write;

format ONNodeDec=

============================================================
��˵����

    1�����ű��������ڵ���������ִ����ؽű���������ű�����
        
       �����û�����ִ�нű������鷳��ͬʱ����ű�ִ�е���©;

    2��ִ�б��ű�ǰ����ȷ���Ѿ�ִ����run.sh�������������ݵ�
     
       �ռ�����.

============================================================

.

##�ж�source·���Ƿ���ڣ��Լ����txt�ļ��Ƿ����
(-d "./source") || die "Dir [source] is not exist,$!\n\n";
(-f "./source/iostat.txt") || die "File [iostat.txt] is not exist,$!\n\n";
(-f "./source/cpu_mem.txt") || die "File [cpu_mem.txt] is not exist,$!\n\n";
(-f "./source/memused.txt") || die "File [memused.txt] is not exist,$!\n\n";
(-f "./source/sar.txt") || die "File [sar.txt] is not exist,$!\n\n";
(-f "./source/vmstat.txt") || die "File [vmstat.txt] is not exist,$!\n\n";


if($opt_a)
{
   system("perl perform.plx -a");           #���������ļ�����
   system("perl sar_dp.plx");               #���������ļ�����
   system("perl dispose.plx -a");           #������ش���
   system("perl mmsg_query.plx");           #server manager��Ϣ���д���
   system("perl osinfo.plx");               #����ϵͳӲ��������Ϣ
   
   #add by wangyunzeng 2012-10-30 ����tarѹ��������
   system("perl tar.plx");
}
elsif($opt_s)
{
   system("perl perform.plx -s");           #���������ļ�����
   system("perl sar_dp.plx");               #���������ļ�����
   system("perl dispose.plx -s");           #������ش���
   system("perl osinfo.plx");               #����ϵͳӲ��������Ϣ
   
   #add by wangyunzeng 2012-10-30 ����tarѹ��������
   system("perl tar.plx");
}
elsif($opt_m)
{
   system("perl perform.plx -m");           #���������ļ�����
   system("perl sar_dp.plx");               #���������ļ�����
   system("perl dispose.plx -m");           #������ش���
   system("perl osinfo.plx");               #����ϵͳӲ��������Ϣ
   
   #add by wangyunzeng 2012-10-30 ����tarѹ��������
   system("perl tar.plx");   
}
elsif($opt_e)
{
   system("perl perform.plx -e");           #���������ļ�����
   system("perl sar_dp.plx");               #���������ļ�����
   system("perl dispose.plx -e");           #������ش���
   system("perl osinfo.plx");               #����ϵͳӲ��������Ϣ
   
   #add by wangyunzeng 2012-10-30 ����tarѹ��������
   system("perl tar.plx");  
}
