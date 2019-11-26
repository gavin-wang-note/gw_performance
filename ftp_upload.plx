#!/usr/bin/perl
use warnings;
use strict 'vars';
use Config::IniFiles;
use Net::SCP::Expect;
use Expect;
use Sys::Hostname;
use Socket;
use Getopt::Std;;
use vars qw($opt_a $opt_s $opt_m $opt_e);

#########################################################################################
#    ###############################################################################    #
#   #      说明：   将run和gather脚本上传到其他服务器上并执行                       #   #
#   #      使用：   perl   ftp_upload.plx                                           #   #
#   #      AUTH：   wangyunzeng                                                     #   #
#   #      VER ：   1.0                                                             #   #
#   #      TIME：   2012-08-28   20:09   create                                     #   #
#    ###############################################################################    #
#########################################################################################

##增加说明信息，显示在使用方法前(2012-09-04 13:54)
$~="TOPFORMAT";
write;
format TOPFORMAT=

======================================================================

 说明：
      1、本脚本主要完成脚本上传与执行操作；
      2、根据用户输入，判定本机是否进行性能数据收集操作；
      3、脚本上传到远端服务器后，自动创建相关目录并进行性能数据的收集

======================================================================
.

##检查文件
(-f "dircheck.plx") || die "\nFile is not exist,$!\n\n";
(-f "dispose.plx") || die "\nFile is not exist,$!\n\n";
(-f "ftp_download.plx") || die "\nFile is not exist,$!\n\n";
(-f "ftp_upload.plx") || die "\nFile is not exist,$!\n\n";
(-f "gather.sh") || die "\nFile is not exist,$!\n\n";
(-f "memused.plx") || die "\nFile is not exist,$!\n\n";
(-f "mmsg_query.plx") || die "\nFile is not exist,$!\n\n";
(-f "perform.plx") || die "\nFile is not exist,$!\n\n";
(-f "rename.plx") || die "\nFile is not exist,$!\n\n";
(-f "run.sh") || die "\nFile is not exist,$!\n\n";
(-f "sar_dp.plx") || die "\nFile is not exist,$!\n\n";
(-f "sms_statbills.plx") || die "\nFile is not exist,$!\n\n";
(-f "statbills.plx") || die "\nFile is not exist,$!\n\n";

#使用方法
getopts("asme");

if (!($opt_a || $opt_m || $opt_s|| $opt_e))
{
   print "\n【使用方法】\n";
   print "\n perl ftp_upload.plx \n \n      选项:  -a  -m  -s  -e\n\n\t     -a: MMSG-彩信   表示网关类型为彩信网关\n\n\t     -m: M模块       表示类型为M模块\n\n\t     -s: SMS-业务    表示短信业务网关\n\n\t     -e: SMS-行业    表示短信行业网关\n \n \n";
   exit;
}

##从配置文件读取信息
my $cfg = Config::IniFiles->new( -file => "./config/config.ini" );

my $remote_path_mmsg=$cfg->val('GW_PERFROMANCE','MMSG_SCP_Path' ) || '';        #远端存放脚本路径,彩信使用
my $remote_path_sms=$cfg->val('GW_PERFROMANCE','SMS_SCP_Path' ) || '';          #远端存放脚本路径,短信使用
my $remote_path_m=$cfg->val('GW_PERFROMANCE','M_SCP_Path' ) || '';              #远端存放脚本路径,M模块使用

my $remote_user=$cfg->val('GW_PERFROMANCE','Remote_user') || '';                #登录远端服务器的用户
my $remote_root_pass=$cfg->val('GW_PERFROMANCE','Remote_root_pass') || '';      #登录远端服务器root用户对应k口令
my $list_tmp=$cfg->val('GW_PERFROMANCE','Remote_IP') || '';                     #获取IP信息
my $iscluster=$cfg->val('GW_PERFROMANCE','IsCluster') || '';                    #是否是进群环境
$iscluster=lc($iscluster);                                                      #防止配置文件中输入了大写

if($iscluster eq "no" || $iscluster eq "n")
{
   print "\n非集群环境（单机环境），请将脚本上传至该节点\n\n";
   
   if($opt_a)
   {
      print "\n[彩信网关]需要执行如下相关脚本：
      
      步骤1、sh run.sh              ----性能数据收集
      
      步骤2、perl oneMode.plx -a    ----性能数据文件处理
      
      \n";
   }
   elsif($opt_s)
   {
      print "\n[短信业务网关]需要执行如下相关脚本：
      
      步骤1、sh run.sh              ----性能数据收集
      
      步骤2、perl oneMode.plx -s    ----性能数据文件处理
      
      \n";   
   }
   elsif($opt_m)
   {
      print "\n[M模块]需要执行如下相关脚本：
      
      步骤1、sh run.sh              ----性能数据收集
      
      步骤2、perl oneMode.plx -m    ----性能数据文件处理
      
      \n";      
   }
   elsif($opt_e)
   {
      print "\n[短信行业网关]需要执行如下相关脚本：
      
      步骤1、sh run.sh              ----性能数据收集
      
      步骤2、perl oneMode.plx -e    ----性能数据文件处理
      
      \n";    
   }
   
}
elsif($iscluster eq "yes" || $iscluster eq "y")
{
  ##增加本机是否执行run.sh脚本(2012-09-04 13:47)
  print "\n本机是否需要执行run.sh进行数据的收集?[yes/no]\n\n";
  chomp (my $response = <STDIN>);
  $response = lc($response);               #大小写转换
    
  if($response eq "yes" || $response eq "y")
  {
     print "\n本机开始执行run.sh，进行性能数据的收集\n\n";
     system("sh run.sh");
  }
  elsif($response eq "no" || $response eq "n")
  {
     print "\n本机无需执行性能数据收集操作!\n\n";
  }
  else
  {
     print "\n【ERROR】非法的[yes/no]输入，退出执行!\n\n";
     exit;
  }
  
  #获取当前机器IP地址
  my $host = hostname();
  my $localip = inet_ntoa(scalar gethostbyname($host || 'localhost'));
  chomp($localip);
  
  
  sub scp_files 
  {
     my $host= shift;
     my $pass= shift;
     my $scpe = Net::SCP::Expect->new(user=>'root',password=>$pass);
     
     #要上传的文件
     $scpe->scp("run.sh","$host:/");                                            #先上传到根目录下，然后rooty用户mv操作
     $scpe->scp("gather.sh","$host:/");
     $scpe->scp("dircheck.plx","$host:/");
     $scpe->scp("./config/config.ini","$host:/");
     $scpe->scp("memused.plx","$host:/");                                       #run.sh脚本调用该脚本
  };
  
  
  ##执行
  sub all_hosts
  {
     my $host = shift ;
     my $pass = shift ;
     $ENV{TERM} = "vt100";
     my $exp = Expect->new;
     $exp = Expect->spawn("ssh -l root $host");
     #$exp->log_file("output.log","w");                 #过程日志
     $exp->log_stdout( 0 );                             #关闭过程屏显
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
  
     ##先判断远端存放文件目录是否存在，如果不存在则创建
     $exp->send("cd /\n") if ($exp->expect(undef,"#"));
     if($opt_a)
     {
        $exp->send("perl dircheck.plx -a\n") if ($exp->expect(undef,"#"));
        $exp->send("mv run.sh $remote_path_mmsg\n") if ($exp->expect(undef,"#"));
        $exp->send("mv gather.sh $remote_path_mmsg\n") if ($exp->expect(undef,"#"));
        $exp->send("mv dircheck.plx $remote_path_mmsg\n") if ($exp->expect(undef,"#"));
        $exp->send("mv config.ini $remote_path_mmsg/config\n") if ($exp->expect(undef,"#"));
        $exp->send("mv memused.plx $remote_path_mmsg\n") if ($exp->expect(undef,"#"));
      
        $exp->send("chown -R $remote_user.users $remote_path_mmsg\n") if ($exp->expect(undef,"#"));
        
        ##切换到远端登录用户，赋予脚本相关权限,并执行run.sh脚本进行数据的获取
        $exp->send("su - $remote_user\n") if ($exp->expect(undef,"#"));
        $exp->send("cd $remote_path_mmsg\n") if ($exp->expect(undef,">"));
        $exp->send("chmod 775 *\n") if ($exp->expect(undef,">"));
        $exp->send("sh run.sh\n") if ($exp->expect(undef,">"));
     }
     elsif($opt_s)
     {
        $exp->send("perl dircheck.plx -s\n") if ($exp->expect(undef,"#"));
        $exp->send("mv run.sh $remote_path_sms\n") if ($exp->expect(undef,"#"));
        $exp->send("mv gather.sh $remote_path_sms\n") if ($exp->expect(undef,"#"));
        $exp->send("mv dircheck.plx $remote_path_sms\n") if ($exp->expect(undef,"#"));
        $exp->send("mv config.ini $remote_path_sms/config\n") if ($exp->expect(undef,"#"));
        $exp->send("mv memused.plx $remote_path_sms\n") if ($exp->expect(undef,"#"));
        
        $exp->send("chown -R $remote_user.users $remote_path_sms\n") if ($exp->expect(undef,"#"));
        
        ##切换到远端登录用户，赋予脚本相关权限,并执行run.sh脚本进行数据的获取
        $exp->send("su - $remote_user\n") if ($exp->expect(undef,"#"));
        $exp->send("cd $remote_path_sms\n") if ($exp->expect(undef,">"));
        $exp->send("chmod 775 *\n") if ($exp->expect(undef,">"));
        $exp->send("sh run.sh\n") if ($exp->expect(undef,">"));
     }
     elsif($opt_m)
     {
        $exp->send("perl dircheck.plx -m\n") if ($exp->expect(undef,"#"));
        $exp->send("mv run.sh $remote_path_m\n") if ($exp->expect(undef,"#"));
        $exp->send("mv gather.sh $remote_path_m\n") if ($exp->expect(undef,"#"));
        $exp->send("mv dircheck.plx $remote_path_m\n") if ($exp->expect(undef,"#"));
        $exp->send("mv config.ini $remote_path_m/config\n") if ($exp->expect(undef,"#"));
        $exp->send("mv memused.plx $remote_path_m\n") if ($exp->expect(undef,"#"));
        
        $exp->send("chown -R $remote_user.users $remote_path_m\n") if ($exp->expect(undef,"#"));
        
        ##切换到远端登录用户，赋予脚本相关权限,并执行run.sh脚本进行数据的获取
        $exp->send("su - $remote_user\n") if ($exp->expect(undef,"#"));
        $exp->send("cd $remote_path_m\n") if ($exp->expect(undef,">"));
        $exp->send("chmod 775 *\n") if ($exp->expect(undef,">"));
        $exp->send("sh run.sh\n") if ($exp->expect(undef,">")); 
     }
     elsif($opt_e)
     {
        $exp->send("perl dircheck.plx -e\n") if ($exp->expect(undef,"#"));
        $exp->send("mv run.sh $remote_path_sms\n") if ($exp->expect(undef,"#"));
        $exp->send("mv gather.sh $remote_path_sms\n") if ($exp->expect(undef,"#"));
        $exp->send("mv dircheck.plx $remote_path_sms\n") if ($exp->expect(undef,"#"));
        $exp->send("mv config.ini $remote_path_sms/config\n") if ($exp->expect(undef,"#"));
        $exp->send("mv memused.plx $remote_path_sms\n") if ($exp->expect(undef,"#"));
        
        $exp->send("chown -R $remote_user.users $remote_path_sms\n") if ($exp->expect(undef,"#"));
        
        ##切换到远端登录用户，赋予脚本相关权限,并执行run.sh脚本进行数据的获取
        $exp->send("su - $remote_user\n") if ($exp->expect(undef,"#"));
        $exp->send("cd $remote_path_sms\n") if ($exp->expect(undef,">"));
        $exp->send("chmod 775 *\n") if ($exp->expect(undef,">"));
        $exp->send("sh run.sh\n") if ($exp->expect(undef,">"));   
     }
     else
     {
        #do nothins
     }
     #退出操作
     $exp->send("exit\n") if ($exp->expect(undef,">"));
     $exp->send("exit\n") if ($exp->expect(undef,"#"));
     $exp->log_file(undef);
  }
  
  print '-' x 60,"\n"; 
  print "\n开始上传脚本到服务器，并执行run.sh脚本获取性能数据.\n\n";
  
  my @list=split(/\,/,$list_tmp);
  #for my $i (@list)
  #{
  #   scp_files($i,"$remote_root_pass");
  #   all_hosts($i,"$remote_root_pass");
  #}
  
  for (my $i=0;$i<=$#list;$i++)
  {
     ##增加IP地址判断，是否是本机IP，如果是，则在本地运行相关程序
     #增加IPd地址与本机IP地址匹配
     if($localip eq "$list[$i]")
     {
        print "\n$list[$i]是本机IP.\n\n";
        print "\n   在本机执行run.sh操作.\n\n";
        if($opt_a)
        {
           system("sh run.sh");
           print "\n本机操作完成。\n\n";
        }
        elsif($opt_s)
        {
           system("sh run.sh");
           print "\n本机操作完成。\n\n";
        }
        elsif($opt_m)
        {
           system("sh run.sh");
           print "\n本机操作完成。\n\n";
        }
        elsif($opt_e)
        {
           system("sh run.sh");
           print "\n本机操作完成。\n\n";
        }
        else
        {
           #do nothing
        }
     }
     else
     {
        print "\n   向IP地址为:$list[$i] 的远端服务器上传脚本并执行\n\n";
        scp_files($list[$i],"$remote_root_pass");
        all_hosts($list[$i],"$remote_root_pass");
        print "\n   IP地址为:$list[$i] 的远端服务器，完成了脚本上传与执行操作.\n";   
     }
  }
  
  print "\n完成向各个节点上传脚本与执行操作.\n\n";
  print '-' x 60,"\n\n";   
}
else
{
   print "\n【Error】配置文件中IsCluster取值非yes或no，请检查配置文件!\n\n";
   exit;
}