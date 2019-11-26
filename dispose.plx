#!/usr/bin/perl
#use warnings;
use strict 'vars';
use Config::IniFiles;
use Net::SCP::Expect;
use Sys::Hostname;
use Socket;
use Cwd;
use Getopt::Std;
use vars qw($opt_a $opt_s $opt_m $opt_e);

#########################################################################################
#    ###############################################################################    #
#   #      说明：   到计费节点进行统计话单统计处理                                  #   #
#   #               并处理O流程每秒话单速率 ，以及其他处理                          #   #
#   #      使用：   perl   dispose.plx                                              #   #
#   #      AUTH：   wangyunzeng                                                     #   #
#   #      VER ：   1.0                                                             #   #
#   #      TIME：   2012-08-27   10:18   create                                     #   #
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
my $cur_path=getcwd;                #获取当前路径

#获取当前机器IP地址
my $host = hostname();
my $address = inet_ntoa(scalar gethostbyname($host || 'localhost'));
chomp($address);

#操作系统类型
my $Os_type=$^O;

#从配置文件获取信息
my $cfg = Config::IniFiles->new( -file => "./config/config.ini" );

##彩信使用    
my $BILL_IP = $cfg->val('GW_PERFROMANCE', 'Bill_IP') || '';                     #计费节点IP地址
my $MMSG_Stat_path = $cfg->val('GW_PERFROMANCE', 'MMSG_Stat_path') || '';       #计费节点统计话单路径
my $BILL_User=$cfg->val('GW_PERFROMANCE', 'BILL_User') || '';                   #计费节点登录用户名
my $BILL_Pss=$cfg->val('GW_PERFROMANCE', 'BILL_Pss') || '';                     #计费节点登录用户名对应的口令

my $BILL_Root_Pass=$cfg->val('GW_PERFROMANCE', 'BILL_Root_Pass') || '';         #root用户对应密码
    
my $BILL_Pass=$cfg->val('GW_PERFROMANCE', 'BILL_Pass') || '';                   #计费节点登录用户名对应的口令
my $MMSG_SCP_File=$cfg->val('GW_PERFROMANCE', 'MMSG_SCP_File') || '';           #彩信要上传的统计话单统计脚本
my $MMSG_SCP_Path=$cfg->val('GW_PERFROMANCE', 'MMSG_SCP_Path') || '';           #彩信用统计脚本存放路径

##短信使用
my $smpp_ip = $cfg->val('GW_PERFROMANCE', 'SMS_BILL_IP') || '';                 #SMPP话单所在节点IP地址
my $smpp_user=$cfg->val('GW_PERFROMANCE', 'SMS_BILL_User') || '';               #对SMPP话单进行统计操作的用户
my $smpp_user_pass=$cfg->val('GW_PERFROMANCE', 'SMS_BILL_User_pass') || '';     #对SMPP话单进行统计操作的用户对应的口令
my $sms_smpp_path=$cfg->val('GW_PERFROMANCE','SMS_SMPP_PATH') || '';            #SMPP话单路径
my $smpp_root_pass=$cfg->val('GW_PERFROMANCE', 'SMS_BILL_ROOT_Pass') || '';     #计费节点登录用户名对应的口令
my $sms_scp_file=$cfg->val('GW_PERFROMANCE', 'SMS_SCP_FILE') || '';             #短信要上传的统计话单统计脚本
my $sms_scp_path=$cfg->val('GW_PERFROMANCE', 'SMS_SCP_Path') || '';             #短信用统计脚本存放路径


##获取路径中最后目录（时间目录）
#彩信用
my @path=split(/\//,$MMSG_Stat_path);
my $leth=scalar(@path);
my $path_day=$path[$leth-1];
chomp($path_day);

#短信用
my $path_day_sms=`cat ./config/config.ini | grep SMS_SMPP_PATH | awk -F \"\/\" \'\{print \$NF\}\' | sed \'s\/\\\-\/\\\/\/g\'`;
chomp($path_day_sms);

##因短信smpp话单文件中日期格式是2011/09/03，直接传递会出在awk问题，这里把日期分为3个参数传递，组合成年月日
my @year_mon_day=split(/\//,"$path_day_sms");
my $year=shift(@year_mon_day);
my $month=shift(@year_mon_day);
my $day=shift(@year_mon_day);

#文件存放路径
unless (-d "source")
{
   mkdir("source", 0755) || die "Make directory source error.\n";
}


if($opt_a)
{
   #print "\n选择了彩信网关.\n\n";
   &mmsg_dispose;
   &mmsg_statbill;           #对ftp过来的MMSG的统计话单结果文件进行二次处理，得到 mmsg_statbills.txt 文件
}
elsif($opt_s)
{
   #print "\n选择了短信业务网关网关.\n\n";
   &sms_dispose;
}
elsif($opt_e)
{
   #print "\n选择了短信行业网关.\n\n";
   &sms_dispose;
}
elsif($opt_m)
{
   #print "\n选择了M模块.\n\n";
}
else
{
   print "\n输入非法，请参考上面的【使用方法】\n\n";
   exit;
}


sub mmsg_dispose()
{
   ##如果从配置文件中获取的IP和本地IP一致，说明当前是计费节点，无需传输脚本，在本地直接执行脚本话单统计脚本既可
   if($address eq $BILL_IP)
   {
       ##判断路径是否存在(要放在计费节点进行判断，否则非计费节点告警报错路径不存在)
       (-d "$MMSG_Stat_path") || die "\nDir $MMSG_Stat_path is not exist!Pease check config.ini file.\n\n";
       
       #print '-' x 60,"\n";
       print "\n对MMSG统计话单进行处理.\n\n";
       print "\n  当前已是计费节点.\n\n";
       print "\n  开始执行 [statbills.plx] 脚本，统计MMSG统计话单......\n\n";
       system("perl statbills.plx > ./source/mmsg_stat_result.txt");              #得到统计话单统计结果
       
       print "\n  计算统计话单每秒接入网关速度......\n\n";
       chdir "$MMSG_Stat_path";
       system("awk -F\, \'\{if\(\$8==2 \&\& substr\(\$25,1,8\)==$path_day\)\{print \$25\",\"\$5\}\}\' * > $cur_path/source/AO.txt");
       system("awk -F\',\' \'\{a\[\$1\]++\}END\{for\(i in a\)printf\"\%s,\%d\\n\",i,a\[i\]\}\' $cur_path/source/AO.txt | sort > $cur_path/source/mmsg_speed.txt");
       
       #返回原路径
       chdir "$cur_path";
       unlink("./source/AO.txt");
       print "\n";
       print '-' x 60,"\n";    
   }
   else
   {
       #print '-' x 60,"\n";
       print "\n对MMSG统计话单进行处理.\n\n";
       
       print "\n【友情提示】\n";
       print "\n   当前节点不是计费节点，该脚本会将统计脚本上传到计费节点，\n\n   并进行话单统计，统计完成后将结果获取到本机source目录下。\n\n";
       sleep 1;  ##暂停一下，方便阅读提示信息
       
       ##计费节点执行话单t统计脚本和ftp文件到本机
       &mmsg_scp_file($BILL_IP,"$BILL_Root_Pass");
       &mmsg_stat_file($BILL_IP,"$BILL_Root_Pass");
   }
      
}


sub mmsg_scp_file
{
   my $host= shift;
   my $pass= shift;
   my $scpe = Net::SCP::Expect->new(user=>'root',password=>$pass);
   $scpe->scp("$MMSG_SCP_File","$host:$MMSG_SCP_Path");
};

sub mmsg_stat_file
{
   my $host = shift;
   my $pass = shift;
   $ENV{TERM} = "vt100";
   my $exp = Expect->new;
   my $ftp = Expect->new;       
 
   $exp = Expect->spawn("ssh -l root $host");
   #$exp->log_file("output.log","w");  #调测日志
   $exp->log_stdout( 0 );              #屏蔽多余输出
   
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


   print "\n   开始执行 [statbills.plx] 脚本，统计MMSG统计话单......\n\n";
   
   $exp->send("cd /home/$BILL_User/perl\n") if ($exp->expect(undef,"#"));
   $exp->send("chown -R $BILL_User.users statbills.plx \n") if ($exp->expect(undef,"#"));
   $exp->send("su - $BILL_User\n") if ($exp->expect(undef,"#"));
   $exp->send("cd ./perl\n") if ($exp->expect(undef,">"));  
   $exp->send("perl statbills.plx > mmsg_stat_result.txt\n") if ($exp->expect(undef,">"));
   #$exp->send("rm statbills.plx\n") if ($exp->expect(undef,">"));
   
   ##计算每秒接入速度
   print "\n   计算统计话单每秒接入网关速度......\n\n";

   $exp->send("cd $MMSG_Stat_path\n") if ($exp->expect(undef,">"));
   $exp->send("awk -F\, \'\{if\(\$8==2 \&\& substr\(\$25,1,8\)==$path_day\)\{print \$25\",\"\$5\}\}\' * > /home/$BILL_User/AO.txt\n") if ($exp->expect(undef,">"));
   $exp->send("awk -F\',\' \'\{a\[\$1\]++\}END\{for\(i in a\)printf\"\%s,\%d\\n\",i,a\[i\]\}\' /home/$BILL_User/AO.txt | sort > /home/$BILL_User/mmsg_speed.txt\n") if ($exp->expect(undef,">"));
   $exp->send("rm /home/$BILL_User/AO.txt\n") if ($exp->expect(undef,">"));
   $exp->send("exit\n") if ($exp->expect(undef,">"));
   
   $exp->send("exit\n") if ($exp->expect(undef,">"));
   $exp->send("exit\n") if ($exp->expect(undef,"#"));
   $exp->log_file(undef);
   print "\n   完成相关统计操作.\n";
   


   print "\n   开始从计费节点获取处理后文件.\n\n";
   $ftp = Expect->spawn( "ftp $BILL_IP" ) or die "Could not connect to $BILL_IP us ftp, $!"; 
   $ftp->log_stdout( 0 );   # 屏蔽多余输出
                 
   # 等待用户名输入提示
   unless ( $ftp->expect(10, -re=>qr/name \(.*?\):\s*$/i) ) 
   { 
     die "   FTP到$BILL_IP，用户未输入FTP用户名, ".$ftp->error( )."\n"; 
   } 
 
   #发送用户名
   $ftp->send( "$BILL_User\r" ); 
   #sleep 2;
   
    # 等待密码输入提示
   unless ( $ftp->expect( 10, -re=>qr/password:\s*$/i ) ) 
   { 
      die "   FTP到$BILL_IP，用户未输入FTP用户名对应的密码, ".$ftp->error( )."\n"; 
   } 
   
   #发送密码
   $ftp->send( "$BILL_Pss\r" ); 

    # 等待 ftp 命令行提示
    unless ( $ftp->expect(30,"ftp>") ) 
    { 
       die "   Never got ftp prompt after sending username, ".$ftp->error( )."\n"; 
    } 
 
 
    # 下载文件
    $ftp->send( "get mmsg_speed.txt\r" ); 
    unless ( $ftp->expect( 30,"ftp> " ) ) 
    { 
       die "   Never got ftp prompt after attempting to get mmsg_speed.txt, ".$ftp->error( )."\n"; 
    } 

    $ftp->send( "get mmsg_stat_result.txt\r" ); 
    unless ( $ftp->expect( 30,"ftp> " ) ) 
    { 
       die "   Never got ftp prompt after attempting to get mmsg_stat_result.txt, ".$ftp->error( )."\n"; 
    } 

   
    # 断开 ftp 连接
    print "\n   FTP文件结束，断开FTP连接 ... \n"; 
    $ftp->send( "bye\r" ); 
    $ftp->soft_close( ); 
    if(-f "mmsg_speed.txt" and -f "mmsg_stat_result.txt")
    {
        system("mv mmsg_speed.txt ./source/mmsg_speed.txt");
        system("mv mmsg_stat_result.txt ./source/mmsg_stat_result.txt");
        print "\n   彩信【mmsg_speed.txt/mmsg_stat_result.txt】文件成功获取到source目录下.\n\n";
    }
    else
    {
         print "\n   彩信【mmsg_speed.txt/mmsg_stat_result.txt】文件获取失败，请检查原因.\n\n";
         exit;
    }
}

#对MMSG统计话单处理后的文件进行二次处理并合并成 mmsg_statbills.txt 文件

sub mmsg_statbill()
{
   print "\n\n统计话单成功率统计结果如下:\n\n";
   
   my $AOMT_BILL_NUMS=`cat ./source/mmsg_stat_result.txt | grep "AOMT Bill" | sed s\'\/ \/\/g\' | awk -F ":" '{print \$2}'`;   #AOMT话单总数
   my $AO_BILL_NUMS=`cat ./source/mmsg_stat_result.txt | grep "AO Bill" | awk -F ":" '{print \$2}'`;
   my $MT_BILL_NUMS=`cat ./source/mmsg_stat_result.txt | grep -v "AOMT Bill" | grep "MT Bill" | awk -F ":" '{print \$2}'`;
   my $AO_SUCC_PERCENT=`cat ./source/mmsg_stat_result.txt | grep "Status 0100 Bill" | awk -F ":" '{print \$2}' | awk -F "(" '{print substr(\$2,1,7)}'`;
   my $MT_SUCC_PERCENT=`cat ./source/mmsg_stat_result.txt | grep "Status 1000 Bill" | awk -F ":" '{print \$2}' | awk -F "(" '{print substr(\$2,1,7)}'`;
   my $AOMT_SUCC_PERCENT=`cat ./source/mmsg_stat_result.txt | grep "AOMT SUCCESS PERCENT" | awk -F ":" '{print \$2}' | awk -F "(" '{print substr(\$2,1,7)}'`;   
   my $AO_MT_NUMS=$AO_BILL_NUMS + $MT_BILL_NUMS;
   
   chomp($AOMT_BILL_NUMS);
   chomp($AO_BILL_NUMS);
   chomp($MT_BILL_NUMS);
   chomp($AO_SUCC_PERCENT);
   chomp($MT_SUCC_PERCENT);
   chomp($AOMT_SUCC_PERCENT);
   chomp($AO_MT_NUMS);
   
   print "\n结果分析如下：\n";
   print "\n    AO话单数量是：        $AO_BILL_NUMS  (条)  \n";
   print "\n    MT话单数量是：        $MT_BILL_NUMS  (条)  \n";
   print "\n    AOMT话单数量是：       $AOMT_BILL_NUMS  (条)  \n";
   print "\n    AO话单成功率是：       $AO_SUCC_PERCENT  \n";
   print "\n    MT话单成功率是：       $MT_SUCC_PERCENT  \n";
   print "\n    AOMT话单成功率是：     $AOMT_SUCC_PERCENT  \n";
   
   if($AOMT_BILL_NUMS gt $AO_MT_NUMS)
   {
      print "\n    AOMT话单数量 [$AOMT_BILL_NUMS] 大于 AO+MT [$AO_MT_NUMS] 话单数量.\n\n";
   }
   elsif($AOMT_BILL_NUMS eq $AO_MT_NUMS)
   {
      print "\n    AOMT话单数量 [$AOMT_BILL_NUMS] 等于 AO+MT [$AO_MT_NUMS] 话单数量.\n\n";
   }
   else
   {
      print "\n    AOMT话单数量 [$AOMT_BILL_NUMS] 小于 AO+MT [$AO_MT_NUMS] 话单数量.\n\n";
   }
   
   #print '-' x 60,"\n";

   
   #统计结果写入文件
   $~="MMSG_STAT";
   open(MMSG_STAT,">./source/mmsg_statbill.txt") || die "Out file mmsg_statbill.txt:$!\n";  
   format MMSG_STAT=
  
上述分析结果如下：

====================================================================================================================================
   
   AO话单数量(条)          MT话单数量(条)         AOMT话单数量(条)         AO话单成功率        MT话单成功率       AOMT话单成功率
   @<<<<<<<<<<             @<<<<<<<<<<            @<<<<<<<<<<              @<<<<<<<<<<         @<<<<<<<<<<        @<<<<<<<<<<
   $AO_BILL_NUMS      ,    $MT_BILL_NUMS     ,    $AOMT_BILL_NUMS     ,    $AO_SUCC_PERCENT  , $MT_SUCC_PERCENT  ,$AOMT_SUCC_PERCENT
   
   AOMT话单数量(条)        AO（0100）+MT（1000）话单数量(条)
   @<<<<<<<<<<             @<<<<<<<<<<    
   $AOMT_BILL_NUMS    ,    $AO_MT_NUMS
   
====================================================================================================================================

.
   write MMSG_STAT;
   close(MMSG_STAT);

   #文件合并
   system("cat ./source/mmsg_stat_result.txt ./source/mmsg_statbill.txt > ./source/mmsg_statbills.txt");
   
   ##清理过度文件
   unlink("./source/mmsg_stat_result.txt");
   unlink("./source/mmsg_statbill.txt");
}

##SMS
sub sms_dispose()
{
  if($address eq $smpp_ip)
     {
         ##判断路径是否存在(要放在计费节点进行判断，否则非计费节点告警报错路径不存在)
         (-d "$sms_smpp_path") || die "\nDir $sms_smpp_path is not exist!Pease check config.ini file.\n\n";
         
         print '-' x 60,"\n";
         print "\n对短信SMPP话单进行处理.\n\n";
         print "\n  当前已是计费节点.\n\n";
         print "\n  开始执行 [sms_statbills.plx] 脚本，统计SMPP话单......\n\n";
         system("perl sms_statbills.plx");                #得到统计话单统计结果
         
         print "\n  计算SMPP话单每秒接入网关速度......\n\n";
         chdir "$sms_smpp_path";
         system("awk -F\, \'\{if\(\$2==60 \&\& substr\(\$11,1,10\)==$year\/$month\/$day\)\{print \$11\",\"\$46\}\}\' \* > $cur_path/source/AO.txt\n");
         system("awk -F\',\' \'\{a\[\$1\]++\}END\{for\(i in a\)printf\"\%s,\%d\\n\",i,a\[i\]\}\' $cur_path/source/AO.txt | sort > $cur_path/source/smpp_speed.txt\n");


         #返回原路径
         chdir "$cur_path";
         unlink("./source/AO.txt");
         print "\n";
         print '-' x 60,"\n";
     }
     else
     {
        print '-' x 60,"\n";
        print "\n对短信SMPP话单进行处理.\n\n";
        
        print "\n【友情提示】\n";
        print "\n   当前节点不是计费节点，该脚本会将统计脚本上传到计费节点，\n\n   并进行话单统计，统计完成后将结果获取到本机source目录下。\n\n";
        sleep 1;  ##暂停一下，方便阅读提示信息
        
        ##计费节点执行话单t统计脚本和ftp文件到本机
        &sms_scp_file($smpp_ip,"$smpp_root_pass");
        &sms_stat_file($smpp_ip,"$smpp_root_pass");
     }
      

}

sub sms_scp_file
{
   my $host= shift;
   my $pass= shift;
   my $scpe = Net::SCP::Expect->new(user=>'root',password=>$pass);
   $scpe->scp("$sms_scp_file","$host:$sms_scp_path");
};

sub sms_stat_file
{
   my $host = shift;
   my $pass = shift;
   $ENV{TERM} = "vt100";
   my $exp = Expect->new;
   my $ftp = Expect->new;       
 
   $exp = Expect->spawn("ssh -l root $host");
   #$exp->log_file("output.log","w");  #调测日志
   $exp->log_stdout( 0 );              #屏蔽多余输出
   #$exp->exp_internal(1);             #匹配过程
   $exp->expect(2,
                  [
                     qr/password:/i,
                     sub 
                     {
                        my $selt = shift ;
                        $selt->send("$pass\n");
                        exp_continue;
                     }
                  ],
                  [
                      #'connecting (yes/no)?',
                      #'connecting (yes/no)',
                      #qr/connecting \(yes\/no\)/i,                      
                      'connecting',
                      sub
                      {
                        my $self = shift;
                        $self->send("yes\n");
                        exp_continue;
                      }
                  ]
                  
               );
   

   print "\n   开始执行 [sms_statbills.plx] 脚本，统计短信SMPP统计话单......\n\n";
   
   $exp->send("cd /home/$smpp_user/perl\n") if ($exp->expect(undef,"#"));
   $exp->send("chown -R $smpp_user.users sms_statbills.plx \n") if ($exp->expect(undef,"#"));
   $exp->send("su - $smpp_user\n") if ($exp->expect(undef,"#"));
   $exp->send("cd ./perl\n") if ($exp->expect(undef,">"));                      ##注意，这个地方已经进入perl目录了
   $exp->send("perl sms_statbills.plx\n") if ($exp->expect(undef,">"));
   #$exp->send("rm sms_statbills.plx\n") if ($exp->expect(undef,">"));
   
   ##计算每秒接入速度
   print "\n   计算SMPP话单每秒接入网关速度......\n\n";

   $exp->send("cd $sms_smpp_path\n") if ($exp->expect(undef,">"));
   $exp->send("awk -F\, \'\{if\(\$2==60 \&\& substr\(\$11,1,10\)==\"$year\/$month\/$day\"\)\{print \$11\",\"\$46\}\}\' \* > /home/$smpp_user/perl/AO.txt\n") if ($exp->expect(undef,">"));
   $exp->send("awk -F\',\' \'\{a\[\$1\]++\}END\{for\(i in a\)printf\"\%s,\%d\\n\",i,a\[i\]\}\' /home/$smpp_user/perl/AO.txt | sort > /home/$smpp_user/perl/smpp_speed.txt\n") if ($exp->expect(undef,">"));
   $exp->send("rm /home/$smpp_user/perl/AO.txt\n") if ($exp->expect(undef,">"));
   $exp->send("exit\n") if ($exp->expect(undef,">"));

   $exp->send("exit\n") if ($exp->expect(undef,">"));
   $exp->send("exit\n") if ($exp->expect(undef,"#"));
   $exp->log_file(undef);
   print "\n   完成相关SMPP话单统计操作.\n";
   
   
   print "\n   开始从计费节点获取处理后文件.\n\n";
   $ftp = Expect->spawn( "ftp $smpp_ip" ) or die "Could not connect to $smpp_ip us ftp, $!"; 
   $ftp->log_stdout( 0 );   # 屏蔽多余输出
                 
   # 等待用户名输入提示
   unless ( $ftp->expect(10, -re=>qr/name \(.*?\):\s*$/i) ) 
   { 
     die "   FTP到$smpp_ip，用户未输入FTP用户名, ".$ftp->error( )."\n"; 
   } 
 
   #发送用户名
   $ftp->send( "$smpp_user\r" ); 
   #sleep 2;
   
    # 等待密码输入提示
   unless ( $ftp->expect( 10, -re=>qr/password:\s*$/i ) ) 
   { 
      die "   FTP到$smpp_ip，用户未输入FTP用户名对应的密码, ".$ftp->error( )."\n"; 
   } 
   
   #发送密码
   $ftp->send( "$smpp_user_pass\r" ); 

    # 等待 ftp 命令行提示
    unless ( $ftp->expect(30,"ftp>") ) 
    { 
       die "   Never got ftp prompt after sending username, ".$ftp->error( )."\n"; 
    } 
 
 
    # 下载文件
    $ftp->send( "cd /home/$smpp_user/perl\r" ); 
    $ftp->send( "get ./source/smpp_result.txt\r" );
    unless ( $ftp->expect( 30,"ftp> " ) ) 
    { 
       die "   获取smpp_result.txt文件时尚未接收到ftp的提示符信息, ".$ftp->error( )."\n"; 
    }

    #$ftp->send( "cd source\r" ); 
    $ftp->send( "get ./smpp_speed.txt\r" ); 
    unless ( $ftp->expect( 30,"ftp> " ) ) 
    { 
       die "   获取smpp_speed.txt文件时尚未接收到ftp的提示符信息, ".$ftp->error( )."\n"; 
    }     
   
    # 断开 ftp 连接
    print "\n   FTP文件结束，断开FTP连接 ... \n"; 
    $ftp->send( "bye\r" ); 
    $ftp->soft_close( );
   
   
    #ftp到本机后，移动位置
    if(-f "smpp_speed.txt")
    {
        #system("mv smpp_result.txt ./source/smpp_result.txt");
        system("mv smpp_speed.txt ./source/smpp_speed.txt");
        
        print "\n   短信【smpp_speed.txt】文件成功获取到source目录下.\n\n";
    }
    else
    {
         print "\n   短信【smpp_speed.txt】文件获取失败，请检查原因.\n\n";
         exit;
    }
}