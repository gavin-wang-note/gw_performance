#/usr/bin/perl
use warnings;
use strict 'vars';
use Sys::Hostname;
use Socket;
use Getopt::Std;
use vars qw($opt_a $opt_s $opt_m $opt_e);

#########################################################################################
#    ###############################################################################    #
#   #      说明：   对source目录下文件进行重命名操作                                #   #
#   #      使用：   perl   rename.plx                                               #   #
#   #      AUTH：   wangyunzeng                                                     #   #
#   #      VER ：   1.0                                                             #   #
#   #      TIME：   2012-08-28   19:41   create                                     #   #
#    ###############################################################################    #
#########################################################################################

#使用方法 
getopts("amse");
if (!($opt_a || $opt_m || $opt_s|| $opt_e))
{
   print "\n【使用方法】\n";
   print "\n perl perform.plx \n \n      选项:  -a  -m  -s  -e\n\n\t     -a: MMSG-彩信   表示网关类型为彩信网关\n\n\t     -m: M模块       表示类型为M模块\n\n\t     -s: SMS-业务    表示短信业务网关\n\n\t     -e: SMS-行业    表示短信行业网关\n \n \n";
   exit;
}

##全局变量
my $dir="source";           #原始文件与处理后的相关txt文件所在的目录
my $file;                   #目录下文件名称


#获取当前机器IP地址
my $host = hostname();
my $ip = inet_ntoa(scalar gethostbyname($host || 'localhost'));
chomp($ip);

##rename操作
if($opt_a)
{
  (-d "$dir") || die "\n$dir dir is not exist:$!\n\n";
  
  #文件列表
  opendir(DIR,"$dir") || die "\nOpen dir $dir failed : $!\n\n";
  
  while($file=readdir(DIR))
  {
      my $old_name=$file;     #可以不用赋值，直接使用,这里为了区分，重新赋值一下，使得脚本易读
      
      if(($file eq ".") ||($file eq "..") || ($file eq "mmsg_speed.xt") || ($file eq "mmsg_statbills.txt"))   #不对统计话单文件做重命名处理
      {
        next;
      }
      
      (my $file_name,my $file_postfix)=split(/\./,"$file");
      my $con1=".";
      my $con2="_";
      
      #得到重命名后的文件名
      my $new_name=$file_name.$con2.$ip.$con1.$file_postfix;
      rename("$dir/$old_name","$dir/$new_name") || die "\n$!\n\n";
  }
}
elsif($opt_s)
{
  (-d "$dir") || die "\n$dir dir is not exist:$!\n\n";
  
  #文件列表
  opendir(DIR,"$dir") || die "\nOpen dir $dir failed : $!\n\n";
  
  while($file=readdir(DIR))
  {
      my $old_name=$file;     #可以不用赋值，直接使用,这里为了区分，重新赋值一下，使得脚本易读
      
      if(($file eq ".") ||($file eq "..") || ($file eq "smpp_result.txt"))      #不对统计话单文件做重命名处理
      {
        next;
      }
      
      (my $file_name,my $file_postfix)=split(/\./,"$file");
      my $con1=".";
      my $con2="_";
      
      #得到重命名后的文件名
      my $new_name=$file_name.$con2.$ip.$con1.$file_postfix;
      rename("$dir/$old_name","$dir/$new_name") || die "\n$!\n\n";
  }
}
elsif($opt_e)
{
  (-d "$dir") || die "\n$dir dir is not exist:$!\n\n";
  
  #文件列表
  opendir(DIR,"$dir") || die "\nOpen dir $dir failed : $!\n\n";
  
  while($file=readdir(DIR))
  {
      my $old_name=$file;     #可以不用赋值，直接使用,这里为了区分，重新赋值一下，使得脚本易读
      
      if(($file eq ".") ||($file eq "..") || ($file eq "smpp_result.txt"))      #不对统计话单文件做重命名处理
      {
        next;
      }
      
      (my $file_name,my $file_postfix)=split(/\./,"$file");
      my $con1=".";
      my $con2="_";
      
      #得到重命名后的文件名
      my $new_name=$file_name.$con2.$ip.$con1.$file_postfix;
      rename("$dir/$old_name","$dir/$new_name") || die "\n$!\n\n";
  }
}
elsif($opt_m)
{
  (-d "$dir") || die "\n$dir dir is not exist:$!\n\n";
  
  #文件列表
  opendir(DIR,"$dir") || die "\nOpen dir $dir failed : $!\n\n";
  
  while($file=readdir(DIR))
  {
      my $old_name=$file;     #可以不用赋值，直接使用,这里为了区分，重新赋值一下，使得脚本易读
      
      if(($file eq ".") ||($file eq "..") || ($file eq "mmsg_speed.xt") || ($file eq "mmsg_statbills.txt"))   #不对统计话单文件做重命名处理
      {
        next;
      }
      
      (my $file_name,my $file_postfix)=split(/\./,"$file");
      my $con1=".";
      my $con2="_";
      
      #得到重命名后的文件名
      my $new_name=$file_name.$con2.$ip.$con1.$file_postfix;
      rename("$dir/$old_name","$dir/$new_name") || die "\n$!\n\n";
  }
}
else
{
   print "\n输入非法，请参考上面的【使用方法】\n\n";
   exit;
}
