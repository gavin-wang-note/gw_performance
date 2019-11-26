#!/usr/bin/perl
use warnings;
use strict 'vars';
use Getopt::Std;;
use Net::FTP;
use vars qw($opt_i $opt_n $opt_p $opt_r $opt_d);

#########################################################################################
#    ###############################################################################    #
#   #      说明：   获取linxu机器上相关性能数据到指定位置                           #   #
#   #      使用：   perl   getFile.plx                                              #   #
#   #      AUTH：   wangyunzeng                                                     #   #
#   #      VER ：   1.0                                                             #   #
#   #      TIME：   2012-10-30   18:50   create                                     #   #
#    ###############################################################################    #
#########################################################################################



#使用方法
getopts("i:n:p:r:d:");

if (!($opt_i || $opt_n || $opt_p || $opt_r || $opt_d))
{
   print "\n【使用方法】\n";
   print "\n perl getFile.plx \n \n      选项:  -i  -n  -p  -r -d\n\n\t     -i: 性能数据所在服务器的IP地址\n\n\t     -n: 登录FTP服务器的用户名\n\n\t     -p: 登录FTP服务器用户名对应m密码\n\n\t     -r: FTPf服务器上文件存放的位置\n\n\t     -d: 获取的文件存放在本机器的位置，默认为当前目录\n \n \n";
   print "      示例： perl getFiles.plx -i 10.41.16.50 -n mmsg -p mmsg -r /home/wyz -d D:\\MMSG\\集群\n\n";
   exit;
}

##说明
$~="getFiles";
write;

format getFiles=

============================================================
【说明】

    1、本脚本在windows平台上执行;

    2、脚本执行后，自动获取服务器端压缩包到指定位置.

============================================================

.

##平台判断
my $osType = $^O;
#print "\nostype: $osType\n\n";

#仅支持win平台
if($osType =~ /Win32/)
{
    &ftpget;
}
else
{
    print "\n【出错啦】请在windows平台执行该脚本.\n\n";
    exit;
}


##定义子函数，完成ftp获取文件操作
sub ftpget()
{
##ftp操作去获取文件,IP 用户名 密码等作为参数传入
   my $ftpobj;
   
   if($opt_d eq "")
   {
     print "\n输入的文件存放路径为空.\n";
     print "\n请参考【使用方法】\n\n";
     
     print "\n perl getFile.plx \n \n      选项:  -i  -n  -p  -r -d\n\n\t     -i: 性能数据所在服务器的IP地址\n\n\t     -n: 登录FTP服务器的用户名\n\n\t     -p: 登录FTP服务器用户名对应m密码\n\n\t     -r: FTPf服务器上文件存放的位置\n\n\t     -d: 获取的文件存放在本机器的位置，默认为当前目录\n \n \n";
     print "      示例： perl getFiles.plx -i 10.41.16.50 -n mmsg -p mmsg -r /home/wyz -d D:\\MMSG\\集群\n\n";
     exit;
   }
   else
   {
       if( -d "$opt_d")
      {
          chdir "$opt_d";
          
          print "\n开始ftp获取文件\n\n";
          
          $ftpobj = Net::FTP -> new ("$opt_i");
          $ftpobj -> login("$opt_n","$opt_p");
          $ftpobj -> cwd ("$opt_r");
          $ftpobj -> get ("source.tar.gz");
          $ftpobj -> quit;
          
          if(-f "$opt_d/source.tar.gz")
          {
              print  "文件大小：", -s "$opt_d/source.tar.gz","bytes\n\n";
              print "\n获取文件成功.\n\n";
          }
          else
          {
              print "\n【出错啦】获取文件失败，可能FTP服务器侧[$opt_r]目录下无source.tar.gz文件.\n\n";
              exit;
          }   
      }
      else
      {
          print "\n【出错啦】$opt_d目录不存在\n\n";
      }   
   }   
    
}


