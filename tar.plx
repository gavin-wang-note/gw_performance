#!/usr/bin/perl
use warnings;
use strict 'vars';

#########################################################################################
#    ###############################################################################    #
#   #      ˵����   ���ı��ļ�����ѹ����ѹ����source.tar.gz��                       #   #
#   #                                                                               #   #
#   #      ʹ�ã�   perl   tar.plx                                                  #   #
#   #      AUTH��   wangyunzeng                                                     #   #
#   #      VER ��   1.0                                                             #   #
#   #      TIME��   2012-10-30   17:35   create                                     #   #
#    ###############################################################################    #
#########################################################################################

#�ж�sourceĿ¼�Ƿ����
(-d "source") || die "\n[Error] Dir source is: $!\n\n";

print "\n��ʼѹ���ļ���source.tar.gz\n\n";
chdir "source";
system("tar -zcf source.tar.gz *.txt");

#�ж�ѹ������ļ��Ƿ����
if (-f "source.tar.gz")
{
    print "\n�ɹ�ѹ���ļ���source.tar.gz\n\n";
}
else
{
    print "\n[Error] ѹ��source.tar.gz�����̳������ֹ����.\n\n";
    exit;
}

#�ƶ�source.tar.gz�ļ����ϲ�Ŀ¼
system("mv source.tar.gz ../");