#!/usr/bin/perl
use warnings;
use strict 'vars';
use Getopt::Std;;
use Net::FTP;
use vars qw($opt_i $opt_n $opt_p $opt_r $opt_d);

#########################################################################################
#    ###############################################################################    #
#   #      ˵����   ��ȡlinxu����������������ݵ�ָ��λ��                           #   #
#   #      ʹ�ã�   perl   getFile.plx                                              #   #
#   #      AUTH��   wangyunzeng                                                     #   #
#   #      VER ��   1.0                                                             #   #
#   #      TIME��   2012-10-30   18:50   create                                     #   #
#    ###############################################################################    #
#########################################################################################



#ʹ�÷���
getopts("i:n:p:r:d:");

if (!($opt_i || $opt_n || $opt_p || $opt_r || $opt_d))
{
   print "\n��ʹ�÷�����\n";
   print "\n perl getFile.plx \n \n      ѡ��:  -i  -n  -p  -r -d\n\n\t     -i: �����������ڷ�������IP��ַ\n\n\t     -n: ��¼FTP���������û���\n\n\t     -p: ��¼FTP�������û�����Ӧm����\n\n\t     -r: FTPf���������ļ���ŵ�λ��\n\n\t     -d: ��ȡ���ļ�����ڱ�������λ�ã�Ĭ��Ϊ��ǰĿ¼\n \n \n";
   print "      ʾ���� perl getFiles.plx -i 10.41.16.50 -n mmsg -p mmsg -r /home/wyz -d D:\\MMSG\\��Ⱥ\n\n";
   exit;
}

##˵��
$~="getFiles";
write;

format getFiles=

============================================================
��˵����

    1�����ű���windowsƽ̨��ִ��;

    2���ű�ִ�к��Զ���ȡ��������ѹ������ָ��λ��.

============================================================

.

##ƽ̨�ж�
my $osType = $^O;
#print "\nostype: $osType\n\n";

#��֧��winƽ̨
if($osType =~ /Win32/)
{
    &ftpget;
}
else
{
    print "\n��������������windowsƽִ̨�иýű�.\n\n";
    exit;
}


##�����Ӻ��������ftp��ȡ�ļ�����
sub ftpget()
{
##ftp����ȥ��ȡ�ļ�,IP �û��� �������Ϊ��������
   my $ftpobj;
   
   if($opt_d eq "")
   {
     print "\n������ļ����·��Ϊ��.\n";
     print "\n��ο���ʹ�÷�����\n\n";
     
     print "\n perl getFile.plx \n \n      ѡ��:  -i  -n  -p  -r -d\n\n\t     -i: �����������ڷ�������IP��ַ\n\n\t     -n: ��¼FTP���������û���\n\n\t     -p: ��¼FTP�������û�����Ӧm����\n\n\t     -r: FTPf���������ļ���ŵ�λ��\n\n\t     -d: ��ȡ���ļ�����ڱ�������λ�ã�Ĭ��Ϊ��ǰĿ¼\n \n \n";
     print "      ʾ���� perl getFiles.plx -i 10.41.16.50 -n mmsg -p mmsg -r /home/wyz -d D:\\MMSG\\��Ⱥ\n\n";
     exit;
   }
   else
   {
       if( -d "$opt_d")
      {
          chdir "$opt_d";
          
          print "\n��ʼftp��ȡ�ļ�\n\n";
          
          $ftpobj = Net::FTP -> new ("$opt_i");
          $ftpobj -> login("$opt_n","$opt_p");
          $ftpobj -> cwd ("$opt_r");
          $ftpobj -> get ("source.tar.gz");
          $ftpobj -> quit;
          
          if(-f "$opt_d/source.tar.gz")
          {
              print  "�ļ���С��", -s "$opt_d/source.tar.gz","bytes\n\n";
              print "\n��ȡ�ļ��ɹ�.\n\n";
          }
          else
          {
              print "\n������������ȡ�ļ�ʧ�ܣ�����FTP��������[$opt_r]Ŀ¼����source.tar.gz�ļ�.\n\n";
              exit;
          }   
      }
      else
      {
          print "\n����������$opt_dĿ¼������\n\n";
      }   
   }   
    
}


