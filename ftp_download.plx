#!/usr/bin/perl
use warnings;
use strict 'vars';
use Config::IniFiles;
use Net::SCP::Expect;
use Sys::Hostname;
use Socket;
use Expect;
use Getopt::Std;;
use vars qw($opt_a $opt_s $opt_m $opt_e);

#########################################################################################
#    ###############################################################################    #
#   #      说明：   将perform.plx脚本上传、执行并获取数的到本机                     #   #
#   #      使用：   perl   ftp_download.plx                                         #   #
#   #      AUTH：   wangyunzeng                                                     #   #
#   #      VER ：   1.0                                                             #   #
#   #      TIME：   2012-08-29   13:59   create                                     #   #
#    ###############################################################################    #
#########################################################################################

#使用方法
getopts("asme");

if (!($opt_a || $opt_m || $opt_s|| $opt_e))
{
   print "\n【使用方法】\n";
   print "\n perl ftp_download.plx  \n \n      选项:  -a  -m  -s  -e\n\n\t     -a: MMSG-彩信   表示网关类型为彩信网关\n\n\t     -m: M模块       表示类型为M模块\n\n\t     -s: SMS-业务    表示短信业务网关\n\n\t     -e: SMS-行业    表示短信行业网关\n \n \n";
   exit;
}

##增加说明信息，显示在使用方法前(2012-09-04 14:03)
$~="TOPFORMAT";
write;
format TOPFORMAT=

======================================================================

 说明：
      1、本脚本主要完成各子产品需要的相关脚本上传与执行操作；
      2、脚本在远端服务器执行后，以IP地址重命名相关文件；
      3、相关txt文件均被获取到本机source目录下

======================================================================
.

##从配置文件读取信息
my $cfg = Config::IniFiles->new( -file => "./config/config.ini" );
my $list_tmp=$cfg->val('GW_PERFROMANCE','Remote_IP') || '';                     #获取远端服务器的IP信息
#my $remote_path=$cfg->val('GW_PERFROMANCE','Remote_path' ) || '';               #远端存放脚本路径

my $remote_path_mmsg=$cfg->val('GW_PERFROMANCE','MMSG_SCP_Path' ) || '';        #远端存放脚本路径,彩信使用
my $remote_path_sms=$cfg->val('GW_PERFROMANCE','SMS_SCP_Path' ) || '';          #远端存放脚本路径,短信使用
my $remote_path_m=$cfg->val('GW_PERFROMANCE','M_SCP_Path') || '';               #M模块远端存放脚本的路径

my $remote_user=$cfg->val('GW_PERFROMANCE','Remote_user') || '';                #登录远端服务器的用户
my $remote_user_pass=$cfg->val('GW_PERFROMANCE','Remote_user_pass') || '';      #登录远端服务器的用户对应的口令
my $remote_root_pass=$cfg->val('GW_PERFROMANCE','Remote_root_pass') || '';      #登录远端服务器root用户对应k口令

#my $sms_bill_ip=$cfg->val('GW_PERFROMANCE','SMS_BILL_IP') || '';                #短信SMPP话单所在服务器
my $sms_bill_user=$cfg->val('GW_PERFROMANCE','SMS_BILL_User' ) || '';           #进行统计SMPP话单的用户
#my $sms_bill_root_pass=$cfg->val('GW_PERFROMANCE','SMS_BILL_ROOT_Pass') || '';  #登录SMPP话单所在服务器的root用户密码


#获取当前机器IP地址
my $host = hostname();
my $localip = inet_ntoa(scalar gethostbyname($host || 'localhost'));
chomp($localip);



##增加本机是否执行run.sh脚本(2012-09-04 14:09)
print "\n本机是否需要执行相关脚本进行数据的二次处理?[yes/no]\n\n";
chomp (my $response = <STDIN>);
$response = lc($response);               #大小写转换
  
if($response eq "yes" || $response eq "y")
{
   ##如果子产品有新脚本增加，这里可能需要增加执行步骤
   print "\n本机开始进行性能数据的二次处理\n\n";
   if($opt_a)
   {
      system("perl perform.plx -a");
      system("perl sar_dp.plx");
      system("perl mmsg_query.plx");
      system("perl osinfo.plx");
      system("perl rename.plx -a");
   }
   elsif($opt_s)
   {
      system("perl perform.plx -s");
      system("perl sar_dp.plx");
      system("perl osinfo.plx");
      system("perl rename.plx -s");
   }
   elsif($opt_e)
   {
      system("perl perform.plx -e");
      system("perl sar_dp.plx");
      system("perl osinfo.plx");
      system("perl rename.plx -e");
   }
   elsif($opt_m)
   {
      system("perl perform.plx -m");
      system("perl sar_dp.plx");
      system("perl osinfo.plx");
      system("perl rename.plx -m");
   }
}
elsif($response eq "no" || $response eq "n")
{
   print "\n本机无需执行性能数据的二次处理!\n\n";
}
else
{
   print "\n【ERROR】非法的[yes/no]输入，退出执行!\n\n";
   exit;
}


sub scp_files 
{
   my $host= shift;
   my $pass= shift;
   my $scpe = Net::SCP::Expect->new(user=>'root',password=>$pass);
   
   #要上传的文件
   $scpe->scp("perform.plx","$host:/");                                         #先上传到根目录下，然后root用户mv操作
   $scpe->scp("dispose.plx","$host:/");
   $scpe->scp("rename.plx","$host:/");
   $scpe->scp("sar_dp.plx","$host:/");                                          #对sar.txt文件进行二次处理
   $scpe->scp("osinfo.plx","$host:/");                                          #查看OS硬件配置信息
   
   #针对产品类型，上传各自需要的其他脚本到服务器上
   if($opt_a)
   {
      $scpe->scp("mmsg_query.plx","$host:/");
   }
   elsif($opt_s)
   {
      #$scpe->scp("sms_statbills.plx","$host:/");   
   }
   elsif($opt_m)
   {
      #$scpe->scp("mmsg_query.plx","$host:/");   
   }
   elsif($opt_e)
   {
      #$scpe->scp("sms_statbills.plx","$host:/");   
   }
}


##执行
sub all_hosts
{
   my $host = shift ;
   my $pass = shift ;
   $ENV{TERM} = "vt100";
   my $exp = Expect->new;
   $exp = Expect->spawn("ssh -l root $host");
   #$exp->log_file("output.log","w");                  #过程日志
   $exp->log_stdout( 0 );                              #关闭过程屏显
   #$exp->log_stdout( 1 );
   $exp->expect(2,
                   [
                      'connecting (yes/no)?',
                      sub
                      {
                         my $new_self = shift ;
                         $new_self->send("yes\n");
                      }
                    ],
                    [
                     qr/password:/i,
                     
                     sub 
                     {
                         my $selt = shift ;
                         $selt->send("$pass\n");
                         exp_continue;
                     }
                   ]);

   #传递$opt参数
   if($opt_a)
   {
      ##将perform.plx 和 rename.plx 脚本mv到perl目录下
      $exp->send("cd /\n") if ($exp->expect(undef,"#"));
      
      $exp->send("chown -R $remote_user.users perform.plx\n") if ($exp->expect(undef,"#"));
      $exp->send("chown -R $remote_user.users rename.plx\n") if ($exp->expect(undef,"#"));
      $exp->send("chown -R $remote_user.users mmsg_query.plx\n") if ($exp->expect(undef,"#"));
      $exp->send("chown -R $remote_user.users dispose.plx\n") if ($exp->expect(undef,"#"));
      $exp->send("chown -R $remote_user.users sar_dp.plx\n") if ($exp->expect(undef,"#"));
      $exp->send("chown -R $remote_user.users osinfo.plx\n") if ($exp->expect(undef,"#"));
      
      $exp->send("mv perform.plx $remote_path_mmsg\n") if ($exp->expect(undef,"#"));
      $exp->send("mv dispose.plx $remote_path_mmsg\n") if ($exp->expect(undef,"#"));
      $exp->send("mv rename.plx $remote_path_mmsg\n") if ($exp->expect(undef,"#"));
      $exp->send("mv mmsg_query.plx $remote_path_mmsg\n") if ($exp->expect(undef,"#"));
      $exp->send("mv sar_dp.plx $remote_path_mmsg\n") if ($exp->expect(undef,"#"));
      $exp->send("mv osinfo.plx $remote_path_mmsg\n") if ($exp->expect(undef,"#"));
   
   
      ##切换到远端登录用户，赋予脚本相关权限,并执行run.sh脚本进行数据的获取
      $exp->send("su - $remote_user\n") if ($exp->expect(undef,"#"));
      $exp->send("cd $remote_path_mmsg\n") if ($exp->expect(undef,">"));
   
      $exp->send("perl perform.plx -a\n") if ($exp->expect(undef,">"));
      $exp->send("perl sar_dp.plx\n") if ($exp->expect(undef,">"));
      $exp->send("perl mmsg_query.plx -a\n") if ($exp->expect(undef,">"));
      $exp->send("perl osinfo.plx\n") if ($exp->expect(undef,">"));
      $exp->send("perl rename.plx -a\n") if ($exp->expect(undef,">"));
   }
   elsif($opt_s)
   {
      ##将perform.plx 和 rename.plx 脚本mv到perl目录下
      $exp->send("cd /\n") if ($exp->expect(undef,"#"));
      
      $exp->send("chown -R $remote_user.users perform.plx\n") if ($exp->expect(undef,"#"));
      $exp->send("chown -R $remote_user.users rename.plx\n") if ($exp->expect(undef,"#"));
      $exp->send("chown -R $remote_user.users dispose.plx\n") if ($exp->expect(undef,"#"));
      $exp->send("chown -R $remote_user.users sar_dp.plx\n") if ($exp->expect(undef,"#"));
      $exp->send("chown -R $remote_user.users osinfo.plx\n") if ($exp->expect(undef,"#"));
      
      $exp->send("mv perform.plx $remote_path_sms\n") if ($exp->expect(undef,"#"));
      $exp->send("mv rename.plx $remote_path_sms\n") if ($exp->expect(undef,"#"));
      $exp->send("mv dispose.plx $remote_path_sms\n") if ($exp->expect(undef,"#"));
      $exp->send("mv sar_dp.plx $remote_path_sms\n") if ($exp->expect(undef,"#"));
      $exp->send("mv osinfo.plx $remote_path_sms\n") if ($exp->expect(undef,"#"));
   
   
      ##切换到远端登录用户，赋予脚本相关权限,并执行run.sh脚本进行数据的获取
      $exp->send("su - $remote_user\n") if ($exp->expect(undef,"#"));
      $exp->send("cd $remote_path_sms\n") if ($exp->expect(undef,">"));
      
      $exp->send("perl perform.plx -s\n") if ($exp->expect(undef,">"));
      $exp->send("perl sar_dp.plx\n") if ($exp->expect(undef,">"));
      $exp->send("perl osinfo.plx\n") if ($exp->expect(undef,">"));
      $exp->send("perl rename.plx -s\n") if ($exp->expect(undef,">"));
   }
   elsif($opt_m)
   {
      ###将perform.plx 和 rename.plx 脚本mv到perl目录下
      $exp->send("cd /\n") if ($exp->expect(undef,"#"));
      
      $exp->send("chown -R $remote_user.users perform.plx\n") if ($exp->expect(undef,"#"));
      $exp->send("chown -R $remote_user.users rename.plx\n") if ($exp->expect(undef,"#"));
      $exp->send("chown -R $remote_user.users sar_dp.plx\n") if ($exp->expect(undef,"#"));
      $exp->send("chown -R $remote_user.users osinfo.plx\n") if ($exp->expect(undef,"#"));
      
      $exp->send("mv perform.plx $remote_path_m\n") if ($exp->expect(undef,"#"));
      $exp->send("mv rename.plx $remote_path_m\n") if ($exp->expect(undef,"#"));
      $exp->send("mv sar_dp.plx $remote_path_m\n") if ($exp->expect(undef,"#"));
      $exp->send("mv osinfo.plx $remote_path_m\n") if ($exp->expect(undef,"#"));
      
      
      ###切换到远端登录用户，赋予脚本相关权限,并执行run.sh脚本进行数据的获取
      $exp->send("su - $remote_user\n") if ($exp->expect(undef,"#"));
      $exp->send("cd $remote_path_m\n") if ($exp->expect(undef,">"));
      
      $exp->send("perl perform.plx -m\n") if ($exp->expect(undef,">"));
      $exp->send("perl sar_dp.plx\n") if ($exp->expect(undef,">"));
      $exp->send("perl osinfo.plx\n") if ($exp->expect(undef,">"));
      $exp->send("perl rename.plx -m\n") if ($exp->expect(undef,">"));
   }
   elsif($opt_e)
   {
      ##将perform.plx 和 rename.plx 脚本mv到perl目录下
      $exp->send("cd /\n") if ($exp->expect(undef,"#"));
      
      $exp->send("chown -R $remote_user.users perform.plx\n") if ($exp->expect(undef,"#"));
      $exp->send("chown -R $remote_user.users rename.plx\n") if ($exp->expect(undef,"#"));
      $exp->send("chown -R $remote_user.users dispose.plx\n") if ($exp->expect(undef,"#"));
      $exp->send("chown -R $remote_user.users sar_dp.plx\n") if ($exp->expect(undef,"#"));
      $exp->send("chown -R $remote_user.users osinfo.plx\n") if ($exp->expect(undef,"#"));
      
      $exp->send("mv perform.plx $remote_path_sms\n") if ($exp->expect(undef,"#"));
      $exp->send("mv rename.plx $remote_path_sms\n") if ($exp->expect(undef,"#"));
      $exp->send("mv dispose.plx $remote_path_sms\n") if ($exp->expect(undef,"#"));
      $exp->send("mv sar_dp.plx $remote_path_sms\n") if ($exp->expect(undef,"#"));
      $exp->send("mv osinfo.plx $remote_path_sms\n") if ($exp->expect(undef,"#"));
   
   
      ##切换到远端登录用户，赋予脚本相关权限,并执行run.sh脚本进行数据的获取
      $exp->send("su - $remote_user\n") if ($exp->expect(undef,"#"));
      $exp->send("cd $remote_path_sms\n") if ($exp->expect(undef,">"));
      
      $exp->send("perl perform.plx -e\n") if ($exp->expect(undef,">"));
      $exp->send("perl sar_dp.plx\n") if ($exp->expect(undef,">"));
      $exp->send("perl osinfo.plx\n") if ($exp->expect(undef,">"));
      $exp->send("perl rename.plx -e\n") if ($exp->expect(undef,">"));
   }

   $exp->send("exit\n") if ($exp->expect(undef,">"));
   $exp->send("exit\n") if ($exp->expect(undef,"#"));
   $exp->log_file(undef);
}

#print '-' x 60,"\n";

#对话单进行处理(无论在哪个节点运行，皆可以)
if($opt_a)
{
   system("perl dispose.plx -a");
}
elsif($opt_s)
{
   system("perl dispose.plx -s");
}
elsif($opt_m)
{
   system("perl dispose.plx -m");
}
elsif($opt_e)
{
   system("perl dispose.plx -e");
}
   
#执行perform.plx脚本
print '-' x 60 ,"\n";
print "\n开始上传脚本[perform.plx]到服务器，并执行perform.plx脚本对性能数据进行处理.\n\n";

my @list=split(/\,/,$list_tmp);   #获取IP列表
for (my $i=0;$i<=$#list;$i++)
{
   #增加IP地址与本机IP地址匹配
   if($localip eq "$list[$i]")
   {
      print "\n$list[$i]是本机IP.\n\n";
      print "\n   开始对本机相关数据进行二次处理.\n\n";
      if($opt_a)
      {
         system("perl perform.plx -a");
         system("perl sar_dp.plx");
         system("perl mmsg_query.plx");
         system("perl osinfo.plx");
         system("perl rename.plx -a");
         print "\n本机操作完成。\n\n";
      }
      elsif($opt_s)
      {
         system("perl perform.plx -s");
         system("perl sar_dp.plx");
         system("perl osinfo.plx");
         system("perl rename.plx -s");
         print "\n本机操作完成。\n\n";
      }
      elsif($opt_m)
      {
         system("perl perform.plx -m");
         system("perl sar_dp.plx");
         system("perl osinfo.plx");
         system("perl rename.plx -m");
         print "\n本机操作完成。\n\n";
      }
      elsif($opt_e)
      {
         system("perl perform.plx -e");
         system("perl sar_dp.plx");
         system("perl osinfo.plx");
         system("perl rename.plx -e");
         print "\n本机操作完成。\n\n";
      }
   }
   else
   {
         print "\n开始处理【$list[$i]】节点相关数据.\n\n";
         scp_files($list[$i],"$remote_root_pass");
         all_hosts($list[$i],"$remote_root_pass");
         print "\n   IP地址为:$list[$i] 的远端服务器，完成了perform.plx相关脚本上传与执行操作.\n\n";
         
         
         print "\n   开始从IP地址为[$list[$i]]的节点获取处理后文件到本机source目录下.\n\n";
         my $ftp = Expect->spawn( "ftp $list[$i]" ) or die "Could not connect to $list[$i] us ftp, $!"; 
	     $ftp->log_stdout(0);       # 屏蔽多余输出
         #$ftp->log_stdout(1);    
       	 
         # 等待用户名输入提示
         unless ( $ftp->expect(10, -re=>qr/name \(.*?\):\s*$/i) ) 
         { 
           die "   FTP到$list[$i]，用户未输入FTP用户名, ".$ftp->error( )."\n"; 
         } 
       
         #发送用户名
         $ftp->send( "$remote_user\r" ); 
         
          #等待密码输入提示
         unless ( $ftp->expect( 10, -re=>qr/password:\s*$/i ) ) 
         { 
            die "   FTP到$list[$i]，用户未输入FTP用户名对应的密码, ".$ftp->error( )."\n"; 
         } 
         
         #发送密码
         $ftp->send( "$remote_user_pass\r" ); 
      
          # 等待 ftp 命令行提示
          unless ( $ftp->expect(30,"ftp>") ) 
          { 
             die "   发送用户名后尚未得到password prompt信息, ".$ftp->error( )."\n"; 
          } 
       
       
         # 下载文件
         ##增加参数类型判断
         if($opt_a)
         {
            $ftp->expect(1); 
	        $ftp->send( "cd $remote_path_mmsg/source\r" );
	        $ftp->expect(1);
            $ftp->send( "asc\r" );
            $ftp->expect(1);
            $ftp->send( "mget *.txt\r" );    
         }
         elsif($opt_s)
         {
            $ftp->expect(1);
            $ftp->send( "cd $remote_path_sms/source\r" );
            $ftp->expect(1);
            $ftp->send( "asc\r" );
            $ftp->expect(1);
            $ftp->send( "mget *.txt\r" );    
         }
         elsif($opt_m)
         {
            $ftp->expect(1);
            $ftp->send( "cd $remote_path_m/source\r" );
            $ftp->expect(1);
            $ftp->send( "asc\r" );
            $ftp->expect(1);
            $ftp->send( "mget *.txt\r" );    
         }
         elsif($opt_e)
         {
            $ftp->expect(1);
            $ftp->send( "cd $remote_path_sms/source\r" );
            $ftp->expect(1);
            $ftp->send( "asc\r" );
            $ftp->expect(1);
            $ftp->send( "mget *.txt\r" );     
         }

         unless ( $ftp->expect( 30,"mget " ) ) 
         { 
            die "   下载txt文件时，尚未接收到ftp prompt, ".$ftp->error( )."\n"; 
         }
         
         $ftp->expect(1);
         $ftp->send( "A\r" );
      
        
         # 断开 ftp 连接
         print "\n   FTP文件结束，断开FTP连接 ... \n"; 
         $ftp->send( "bye\r" ); 
         $ftp->soft_close( );
         
         #sleep 3;  #再延迟3s吧，防止ftp超时
         
         #判断FTP文件结果(因节点数量不确定，无法判断文件，且文件是按IP命名，判断文件数量)
         if($opt_a)  ##彩信文件判断
         {  
            my $file_count=`ls -l  \*.txt | wc -l`;
            chomp($file_count);
            if($file_count >= 7)
            {
                #移动文件到source目录下
                system("mv *.txt ./source/");
                print "\n   【彩信A】文件成功获取到本机source目录下.\n\n";
            }
            else
            {
                 print "\n   【彩信A】文件获取失败，请检查原因(多数情况下是ftp超时，网络问题造成).\n\n";
                 system("rm -rf *10.*");
                 exit;
            }
         }
         elsif($opt_s)  ##短信业务判断
         {
            my $file_count=`ls -l  *.txt | wc -l`;
            chomp($file_count);
            if($file_count >= 5)
            {
                #移动文件到source目录下
                system("mv *.txt ./source/");
                print "\n   【短信A-业务】文件成功获取到本机source目录下.\n\n";
            }
            else
            {
                 print "\n   【短信A-业务】文件获取失败，请检查原因(多数情况下是ftp超时，网络问题造成).\n\n";
                 system("rm -rf *10.*");
                 exit;
            }   
         }
         elsif($opt_m)  #M模块判断
         {
            my $file_count=`ls -l  *.txt | wc -l`;
            chomp($file_count);
            if($file_count >= 5)
            {
                #移动文件到source目录下
                system("mv *.txt ./source/");
                print "\n   【M模块】文件成功获取到本机source目录下.\n\n";
            }
            else
            {
                 print "\n   【M模块】文件获取失败，请检查原因(多数情况下是ftp超时，网络问题造成).\n\n";
                 system("rm -rf *10.*");
                 exit;
            }    
         }
         elsif($opt_e)  ##短信行业判断  
         {
            my $file_count=`ls -l  *.txt | wc -l`;
            chomp($file_count);
            if($file_count >= 5)
            {
                #移动文件到source目录下
                system("mv *.txt ./source/");
                print "\n   【短信A-行业】文件成功获取到本机source目录下.\n\n";
            }
            else
            {
               print "\n   【短信A-行业】文件获取失败，请检查原因(多数情况下是ftp超时，网络问题造成).\n\n";
               system("rm -rf *10.*");
               exit;
            }   
         }

      }
   }
      print "\n完成了非本机的、其他各个节点的脚本上传、执行与文件获取操作,获取的文件存放在本机
source目录下，以IP地址做了重命名操作.\n\n";

print '-' x 60,"\n\n";

$~="DESC";
write;
format DESC=

说明:
      仅在上述FTP文件全部成功后，才能输入yes或y；
      
      否则请输入no或n.

------------------------------------------------------------
.

print "\n是否对文件进行合并处理?[yes/no]\n\n";
chomp (my $res = <STDIN>);
$res = lc($res);                                                      #大小写转换

if($res eq "yes" || $res eq "y")
{
   system("perl unite.plx");
   
   #add by wangyunzeng 2012-10-30 增加tar压缩包操作
   system("perl tar.plx");
}
elsif($res eq "no" || $res eq "n" || $res eq "" || $res eq "\n"|| $res eq "\r")                 #增加空、换行或回车，认为输入非法
{
   print "\n不进行文件的合并操作.\n\n";
   exit;
}
else
{
   print "\n[ERROR]输入值非yes或no，退出.\n\n";
   exit;
}
