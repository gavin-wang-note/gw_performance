#/usr/bin/perl
use warnings;
use strict 'vars';
use Sys::Hostname;
use Socket;
use Getopt::Std;
use vars qw($opt_a $opt_s $opt_m $opt_e);

#########################################################################################
#    ###############################################################################    #
#   #      ˵����   ��sourceĿ¼���ļ���������������                                #   #
#   #      ʹ�ã�   perl   rename.plx                                               #   #
#   #      AUTH��   wangyunzeng                                                     #   #
#   #      VER ��   1.0                                                             #   #
#   #      TIME��   2012-08-28   19:41   create                                     #   #
#    ###############################################################################    #
#########################################################################################

#ʹ�÷��� 
getopts("amse");
if (!($opt_a || $opt_m || $opt_s|| $opt_e))
{
   print "\n��ʹ�÷�����\n";
   print "\n perl perform.plx \n \n      ѡ��:  -a  -m  -s  -e\n\n\t     -a: MMSG-����   ��ʾ��������Ϊ��������\n\n\t     -m: Mģ��       ��ʾ����ΪMģ��\n\n\t     -s: SMS-ҵ��    ��ʾ����ҵ������\n\n\t     -e: SMS-��ҵ    ��ʾ������ҵ����\n \n \n";
   exit;
}

##ȫ�ֱ���
my $dir="source";           #ԭʼ�ļ��봦�������txt�ļ����ڵ�Ŀ¼
my $file;                   #Ŀ¼���ļ�����


#��ȡ��ǰ����IP��ַ
my $host = hostname();
my $ip = inet_ntoa(scalar gethostbyname($host || 'localhost'));
chomp($ip);

##rename����
if($opt_a)
{
  (-d "$dir") || die "\n$dir dir is not exist:$!\n\n";
  
  #�ļ��б�
  opendir(DIR,"$dir") || die "\nOpen dir $dir failed : $!\n\n";
  
  while($file=readdir(DIR))
  {
      my $old_name=$file;     #���Բ��ø�ֵ��ֱ��ʹ��,����Ϊ�����֣����¸�ֵһ�£�ʹ�ýű��׶�
      
      if(($file eq ".") ||($file eq "..") || ($file eq "mmsg_speed.xt") || ($file eq "mmsg_statbills.txt"))   #����ͳ�ƻ����ļ�������������
      {
        next;
      }
      
      (my $file_name,my $file_postfix)=split(/\./,"$file");
      my $con1=".";
      my $con2="_";
      
      #�õ�����������ļ���
      my $new_name=$file_name.$con2.$ip.$con1.$file_postfix;
      rename("$dir/$old_name","$dir/$new_name") || die "\n$!\n\n";
  }
}
elsif($opt_s)
{
  (-d "$dir") || die "\n$dir dir is not exist:$!\n\n";
  
  #�ļ��б�
  opendir(DIR,"$dir") || die "\nOpen dir $dir failed : $!\n\n";
  
  while($file=readdir(DIR))
  {
      my $old_name=$file;     #���Բ��ø�ֵ��ֱ��ʹ��,����Ϊ�����֣����¸�ֵһ�£�ʹ�ýű��׶�
      
      if(($file eq ".") ||($file eq "..") || ($file eq "smpp_result.txt"))      #����ͳ�ƻ����ļ�������������
      {
        next;
      }
      
      (my $file_name,my $file_postfix)=split(/\./,"$file");
      my $con1=".";
      my $con2="_";
      
      #�õ�����������ļ���
      my $new_name=$file_name.$con2.$ip.$con1.$file_postfix;
      rename("$dir/$old_name","$dir/$new_name") || die "\n$!\n\n";
  }
}
elsif($opt_e)
{
  (-d "$dir") || die "\n$dir dir is not exist:$!\n\n";
  
  #�ļ��б�
  opendir(DIR,"$dir") || die "\nOpen dir $dir failed : $!\n\n";
  
  while($file=readdir(DIR))
  {
      my $old_name=$file;     #���Բ��ø�ֵ��ֱ��ʹ��,����Ϊ�����֣����¸�ֵһ�£�ʹ�ýű��׶�
      
      if(($file eq ".") ||($file eq "..") || ($file eq "smpp_result.txt"))      #����ͳ�ƻ����ļ�������������
      {
        next;
      }
      
      (my $file_name,my $file_postfix)=split(/\./,"$file");
      my $con1=".";
      my $con2="_";
      
      #�õ�����������ļ���
      my $new_name=$file_name.$con2.$ip.$con1.$file_postfix;
      rename("$dir/$old_name","$dir/$new_name") || die "\n$!\n\n";
  }
}
elsif($opt_m)
{
  (-d "$dir") || die "\n$dir dir is not exist:$!\n\n";
  
  #�ļ��б�
  opendir(DIR,"$dir") || die "\nOpen dir $dir failed : $!\n\n";
  
  while($file=readdir(DIR))
  {
      my $old_name=$file;     #���Բ��ø�ֵ��ֱ��ʹ��,����Ϊ�����֣����¸�ֵһ�£�ʹ�ýű��׶�
      
      if(($file eq ".") ||($file eq "..") || ($file eq "mmsg_speed.xt") || ($file eq "mmsg_statbills.txt"))   #����ͳ�ƻ����ļ�������������
      {
        next;
      }
      
      (my $file_name,my $file_postfix)=split(/\./,"$file");
      my $con1=".";
      my $con2="_";
      
      #�õ�����������ļ���
      my $new_name=$file_name.$con2.$ip.$con1.$file_postfix;
      rename("$dir/$old_name","$dir/$new_name") || die "\n$!\n\n";
  }
}
else
{
   print "\n����Ƿ�����ο�����ġ�ʹ�÷�����\n\n";
   exit;
}
