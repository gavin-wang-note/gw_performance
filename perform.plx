#!/usr/bin/perl

#use strict;
#use warnings;
use Cwd;
use Config::IniFiles;
use Getopt::Std;
use vars qw($opt_a $opt_s $opt_e $opt_m);


#使用方法 
getopts("amse");
if (!($opt_a || $opt_m || $opt_s|| $opt_e))
{
   print "\n【使用方法】\n";
   print "\nperl perform.plx \n \n            选项:  -a  -m  -s  -e\n\n\t           -a: MMSG-彩信   表示网关类型为彩信网关\n\n\t           -m: M模块       表示类型为M模块\n\n\t           -s: SMS-业务    表示短信业务网关\n\n\t           -e: SMS-行业    表示短信行业网关\n \n \n";
}

##定义全局变量
my $os_type = $^O;
#my $line;
#my @fields;
#my @agentary;
#my $scalar;
#my $mdspagentinfo;
#my $smgagentinfo;
#my $smcagentinfo;
#my $ecagentinfo;
#my $scpagentinfo;
#my @umsgsrvary;
#my $disk;
#my @mms_iops_write;


#获取当前登录用户名
#my  $Sys_name = $^O;
#if ($Sys_name =~ m/linux/)
#{
#    #print $ENV{'USER'},"\n";
#}
#elsif ($Sys_name =~ /aix/)
#{
#    #print $ENV{'USER'},"\n";
#}
#else
#{
#    print "\n不支持的OS类型，无法获取当前登录用户名!\n\n";
#    exit;
#}

sub killproc()
{
   #获取性能测试过程中run.sh脚本产生的进程id号
   my $pid_iostat = `ps -fu $ENV{'USER'} | grep iostat | grep -v grep | awk '{if \(\$8 == \"iostat\"\) print \$2}'`;               #iostat进程
   my $pid_vmstat = `ps -fu $ENV{'USER'} | grep vmstat | grep -v grep | awk '{if \(\$8 == \"vmstat\"\) print \$2}'`;               #vmstat进程
   my $pid_sar    = `ps -fu $ENV{'USER'} | grep sar | grep -v grep | awk '{if \(\$8 == \"sar\"\) print \$2}'`;                     #sar进程
   my $pid_gather = `ps -fu $ENV{'USER'} | grep gather.sh | grep -v grep | awk '{if \(\$9 == \"./gather.sh\"\) print \$2}'`;       #gather.sh进程
   my $pid_memuse = `ps -fu $ENV{'USER'} | grep memused.plx | grep -v grep | awk '{if \(\$9 == \"./memused.plx\"\) print \$2}'`;   #memused.plx进程

   chomp($pid_iostat);
   chomp($pid_vmstat);
   chomp($pid_sar);
   chomp($pid_gather);
   chomp($pid_memuse); 
   
   if($pid_iostat ne "")
   {
     system("kill -9 $pid_iostat");
   }
   
   if($pid_vmstat ne "")
   {
     system("kill -9 $pid_vmstat");
   }
   
   if($pid_sar ne "")
   {
     system("kill -9 $pid_sar");
   }
   
   if($pid_gather ne "")
   {
     system("kill -9 $pid_gather");
   
   }
   if($pid_memuse ne "")
   {
      system("kill -9 $pid_memuse");
   }
}


my $cpu_mem_file="./source/cpu_mem.txt";	
my $iostat_file="./source/iostat.txt";	
my $CPU_MEM=$ARGV[0];

##判断文件是否存在
(-f "$cpu_mem_file") || die "\n【$cpu_mem_file】文件不存在，请检查是否执行了 run.sh 脚本生成./source/cpu_mem.txt文件\n\n";
(-f "$iostat_file") || die "\n【$iostat_file】文件不存在，请检查是否执行了 run.sh 脚本生成./source/iostat.txt文件\n\n";


#定义子函数
##彩信用
sub cpu_mem_mmsg()
{
   my @mms_server_cpu=();
   my @mms_charging_server_cpu=();
   my @mmsc_server_cpu=();
   my @vasp_server_cpu=();
   my @VASPClient_cpu=();
   my @MMSCClient_cpu=();
   my @mms_server_mem=();
   my @mms_charging_server_mem=();
   my @mmsc_server_mem=();
   my @vasp_server_mem=();
   my @VASPClient_mem=();
   my @MMSCClient_mem=();
   
   my $time_index=-1;
   my @time_array=();
   
   #open input file
   @ARGV=("$cpu_mem_file");
   while ($line = <>)
   {
       $line=~s/^(\s+)/0/;
       @fields=split(/\s+/,$line);
       
       if ($line =~ m/mms_server/) 
       {
         $mms_server_cpu[$time_index] += $fields[2];
         $mms_server_mem[$time_index] += $fields[3];
       }
       elsif ( $line =~ m/mms_charging_server/)
       {
             $mms_charging_server_cpu[$time_index] += $fields[2];
             $mms_charging_server_mem[$time_index] += $fields[3];
       }
       elsif ( $line =~ m/mmsc_server/)
       {
             $mmsc_server_cpu[$time_index] += $fields[2];
             $mmsc_server_mem[$time_index] += $fields[3];
       }
       elsif ( $line =~ m/vasp_server/)
       {
             $vasp_server_cpu[$time_index] += $fields[2];
             $vasp_server_mem[$time_index] += $fields[3];
       }
       elsif ( $line =~ m/VASPClient/)
       {
             $VASPClient_cpu[$time_index] += $fields[2];
             $VASPClient_mem[$time_index] += $fields[3];
       }
       elsif ( $line =~ m/MMSCClient/)
       {
             $MMSCClient_cpu[$time_index] += $fields[2];
             $MMSCClient_mem[$time_index] += $fields[3];
       }
       elsif( $line =~ /\d{4}-\d{2}-\d{2}/)             #采样时间点获取
       {
             $time_array[++$time_index] = $fields[1];
       }    
   }
   open CPU_MEM, "> ./source/cpu_mem_dp.txt"
      or die "can not open filefor write!\n";
      print CPU_MEM "Time     \t";
      
      print CPU_MEM "server_cpu\t";
      print CPU_MEM "cs_cpu\t";
      print CPU_MEM "mmscserver_cpu\t";
      print CPU_MEM "vaspserver_cpu\t";
      print CPU_MEM "VASPClient_cpu\t";
      print CPU_MEM "MMSCClient_cpu\t";
      
      print CPU_MEM "server_mem\t";
      print CPU_MEM "cs_mem\t";
      print CPU_MEM "mmscserver_mem\t";
      print CPU_MEM "vaspserver_mem\t";
      print CPU_MEM "VASPClient_mem\t";
      print CPU_MEM "MMSCClient_mem\t";
      
      print CPU_MEM "\n";
       
      for($time_index=0;$time_index<@time_array;$time_index++)
      {
          print CPU_MEM $time_array[$time_index],"\t";
          
          print CPU_MEM $mms_server_cpu[$time_index],"        \t";
          print CPU_MEM $mms_charging_server_cpu[$time_index],"        \t";
          print CPU_MEM $mmsc_server_cpu[$time_index],"        \t";
          print CPU_MEM $vasp_server_cpu[$time_index],"        \t";
          print CPU_MEM $VASPClient_cpu[$time_index],"         \t";
          print CPU_MEM $MMSCClient_cpu[$time_index],"\t";
      
          print CPU_MEM $mms_server_mem[$time_index],"    \t";
          print CPU_MEM $mms_charging_server_mem[$time_index],"    \t";
          print CPU_MEM $mmsc_server_mem[$time_index],"    \t";
          print CPU_MEM $vasp_server_mem[$time_index],"    \t";
          print CPU_MEM $VASPClient_mem[$time_index],"    \t";
          print CPU_MEM $MMSCClient_mem[$time_index],"    \t";
      
          print CPU_MEM "\n";
      }
   close(CPU_MEM);
}


##短信业务用
sub cpu_mem_sms_s()
{
   my $cur_path=getcwd;
   chomp($cur_path);
   
   #my $basehome=`env |grep HOME | grep -vi _ | grep -vi db2 | awk -F "=" '{print \$2}'`;
   my $basehome=$ENV{INFOX_ROOT}; 
   chomp($basehome);

   #判断文件是否存在，防止脚本报错
   (-f "$basehome/config/infox.proc") || die "\n 你选择的是：【短信业务网关】，config目录下不存在 infox.proc 文件.\n\n";
   
   my $agent=`cat $basehome/config/infox.proc  | grep agent | grep -v smmcagent  | awk -F " " '{print \$1,\$2,\$3,\$4}'`;
   @agentary=split("\n",$agent);
   $scalar = @agentary; 
   chomp($scalar);

   if($scalar != 0)
   {
      for(my $i=0;$i<$scalar;$i++)
      {
           my $agentinfo=$agentary[$i];
       
           if($agentinfo =~ /ecagent/)
           {
              #print "\n $agentinfo \n";
              $ecagentinfo=substr($agentinfo,0,9);
              #print "\n $ecagentinfo \n";
           }
           elsif($agentinfo =~ /smcagent/)
           {
              $smcagentinfo=substr($agentinfo,0,9);
              #print "\n $smcagentinfo \n";
           }
           elsif($agentinfo =~ /smgagent/)
           {
              $smgagentinfo=substr($agentinfo,0,9);
              #print "\n $smgagentinfo \n";
           }
           elsif($agentinfo =~ /mdspagent/)
           {
              $mdspagentinfo=substr($agentinfo,0,9);
              #print "\n $mdspagentinfo \n";
           }
           elsif($agentinfo =~ /scpagent/)
           {
              $scpagentinfo=substr($agentinfo,0,9);
              #print "\n $scpagentinfo \n";
           }
           #elsif($agentinfo =~ /smmcagent/)
           #{
           #   $smmcagentinfo=substr($agentinfo,0,9);
           #   #print "\n $smmcagentinfo \n";
           #}
           else
           {
            #do nothing  
           }
      }
   }
   else
   {
     print "\n当前节点下无agent模块，继续处理....\n\n"; 
   }
   

   my @startapp_cpu=();
   #my @cmcenter_cpu=();
   #my @spyres_cpu=();
   my @drserver_cpu=();
   my @billserver_cpu=();
   my @smserver_cpu=();
   my @dbserver_cpu=();
   my @msgstore_cpu=();
   my @billclient_cpu=();
   my @spagent_cpu=();   
   my @smcagent_cpu=();
   my @smgagent_cpu=();
   my @mdspagent_cpu=();
   my @scpagent_cpu=();
   #my @smmcagent_cpu=();

   my @startapp_mem=();
   #my @cmcenter_mem=();
   #my @spyres_mem=();
   my @drserver_mem=();
   my @billserver_mem=();
   my @smserver_mem=();
   my @dbserver_mem=();
   my @msgstore_mem=();
   my @billclient_mem=();
   my @spagent_mem=();
   my @smcagent_mem=();
   my @smgagent_mem=();
   my @mdspagent_mem=();
   my @scpagent_mem=();
   #my @smmcagent_mem=();
    
   my $time_index=-1;
   my @time_array=();

   #open input file
   @ARGV=("$cpu_mem_file");
   while ($line = <>)
   {
      $line=~s/^(\s+)/0/;
      @fields=split(/\s+/,$line);
      
      if($scalar != 0)
      {
         if ( $line =~ m/$ecagentinfo$/)  #ecagent
          {
                $spagent_cpu[$time_index] += $fields[2];
                $spagent_mem[$time_index] += $fields[3];	
          }
          elsif ( $line =~ m/$smcagentinfo$/)  #smcagent
          {
                $smcagent_cpu[$time_index] += $fields[2];
                $smcagent_mem[$time_index] += $fields[3];
          }
          elsif ( $line =~ m/$smgagentinfo$/)  #smgagent
          {
                $smgagent_cpu[$time_index] += $fields[2];
                $smgagent_mem[$time_index] += $fields[3];
          }
          elsif ( $line =~ m/$mdspagentinfo$/)  #mdspagent
          {
                $mdspagent_cpu[$time_index] += $fields[2];
                $mdspagent_mem[$time_index] += $fields[3];
          }
          elsif ( $line =~ m/$scpagentinfo$/)  #scpagent
          {
                $scpagent_cpu[$time_index] += $fields[2];
                $scpagent_mem[$time_index] += $fields[3];
          }
          #elsif ( $line =~ m/$smmcagentinfo$/)  #smmcagent
          #{
              #  $smmcagent_cpu[$time_index] += $fields[2];
              #  $smmcagent_mem[$time_index] += $fields[3];
          #}
          elsif ($line =~ m/startapp/)
          {
               $startapp_cpu[$time_index] += $fields[2];
               $startapp_mem[$time_index] += $fields[3];
          }
          #elsif ( $line =~ m/cmcenter/)
          #{
             #  $cmcenter_cpu[$time_index] += $fields[2];
             #  $cmcenter_mem[$time_index] += $fields[3];		
          #}
          #elsif ( $line =~ m/spyres/)
          #{
             #  $spyres_cpu[$time_index] += $fields[2];	
             #  $spyres_mem[$time_index] += $fields[3];	
          #}
          elsif ( $line =~ m/drserver/)
          {
               $drserver_cpu[$time_index] += $fields[2];
               $drserver_mem[$time_index] += $fields[3];
          }
          elsif ( $line =~ m/billserver/)
          {
               $billserver_cpu[$time_index] += $fields[2];
               $billserver_mem[$time_index] += $fields[3];
          }
          elsif ( $line =~ m/smserver/)
          {
               $smserver_cpu[$time_index] += $fields[2];
               $smserver_mem[$time_index] += $fields[3];
          }
          elsif ( $line =~ m/dbserver/)
          {
               $dbserver_cpu[$time_index] += $fields[2];
               $dbserver_mem[$time_index] += $fields[3];
          }
          elsif ( $line =~ m/msgstore/)
          {
               $msgstore_cpu[$time_index] += $fields[2];
               $msgstore_mem[$time_index] += $fields[3];
          }
          elsif ( $line =~ m/billclient/)
          {
               $billclient_cpu[$time_index] += $fields[2];	
               $billclient_mem[$time_index] += $fields[3];
          }
          elsif( $line =~ /\d{4}-\d{2}-\d{2}/)		#采样时间点获取
          {
               $time_array[++$time_index] = $fields[1];
          }
      }
      else
      {
         if ($line =~ m/startapp/)
          {
            $startapp_cpu[$time_index] += $fields[2];
            $startapp_mem[$time_index] += $fields[3];
          }
          #elsif ( $line =~ m/cmcenter/)
          #{
              #  $cmcenter_cpu[$time_index] += $fields[2];
              #  $cmcenter_mem[$time_index] += $fields[3];		
          #}
          #elsif ( $line =~ m/spyres/)
          #{
              #  $spyres_cpu[$time_index] += $fields[2];	
              #  $spyres_mem[$time_index] += $fields[3];	
          #}
          elsif ( $line =~ m/drserver/)
          {
                $drserver_cpu[$time_index] += $fields[2];
                $drserver_mem[$time_index] += $fields[3];
          }
          elsif ( $line =~ m/billserver/)
          {
                $billserver_cpu[$time_index] += $fields[2];
                $billserver_mem[$time_index] += $fields[3];
          }
          elsif ( $line =~ m/smserver/)
          {
                $smserver_cpu[$time_index] += $fields[2];
                $smserver_mem[$time_index] += $fields[3];
          }
          elsif ( $line =~ m/dbserver/)
          {
                $dbserver_cpu[$time_index] += $fields[2];
                $dbserver_mem[$time_index] += $fields[3];
          }
          elsif ( $line =~ m/msgstore/)
          {
                $msgstore_cpu[$time_index] += $fields[2];
                $msgstore_mem[$time_index] += $fields[3];
          }
          elsif ( $line =~ m/billclient/)
          {
                $billclient_cpu[$time_index] += $fields[2];	
                $billclient_mem[$time_index] += $fields[3];
          }
          elsif( $line =~ /\d{4}-\d{2}-\d{2}/)		#采样时间点获取
          {
                $time_array[++$time_index] = $fields[1];
          }
      }

   }##end while
   open CPU_MEM, "> ./source/cpu_mem_dp.txt" or die "can not open filefor write!\n";
   print CPU_MEM "Time     \t";

   if($scalar != 0)
   {
      print CPU_MEM "spagent_cpu  \t";   
      print CPU_MEM "smcagent_cpu\t";
      print CPU_MEM "smgagent_cpu\t";
      print CPU_MEM "mdspagent_cpu\t";
      print CPU_MEM "scpagent_cpu\t";
      #print CPU_MEM "smmcagent_cpu\t";
      print CPU_MEM "startapp_cpu\t";
      #print CPU_MEM "cmcenter_cpu\t";
      #print CPU_MEM "spyres_cpu\t";
      print CPU_MEM "drserver_cpu\t";
      print CPU_MEM "billserver_cpu\t";
      print CPU_MEM "smserver_cpu\t";
      print CPU_MEM "dbserver_cpu\t";
      print CPU_MEM "msgstore_cpu\t";
      print CPU_MEM "billclient_cpu   \t";
   

      print CPU_MEM "spagent_mem  \t";   
      print CPU_MEM "smcagent_mem\t";
      print CPU_MEM "smgagent_mem\t";
      print CPU_MEM "mdspagent_mem\t";
      print CPU_MEM "scpagent_mem\t";
      #print CPU_MEM "smmcagent_mem\t";      
      print CPU_MEM "startapp_mem\t";
      #print CPU_MEM "cmcenter_mem\t";
      #print CPU_MEM "spyres_mem\t";
      print CPU_MEM "drserver_mem\t";
      print CPU_MEM "billserver_mem\t";
      print CPU_MEM "smserver_mem\t";
      print CPU_MEM "dbserver_mem\t";
      print CPU_MEM "msgstore_mem\t";
      print CPU_MEM "billclient_mem\t";

      
      print CPU_MEM "\n";
       
      for($time_index=0;$time_index<@time_array;$time_index++)
      {
          print CPU_MEM $time_array[$time_index],"\t";
          
          print CPU_MEM $spagent_cpu[$time_index],"         \t";
          print CPU_MEM $smcagent_cpu[$time_index],"        \t";
          print CPU_MEM $smgagent_cpu[$time_index],"        \t";
          print CPU_MEM $mdspagent_cpu[$time_index],"        \t";
          print CPU_MEM $scpagent_cpu[$time_index],"        \t";                 
          #print CPU_MEM $smmcagent_cpu[$time_index],"        \t";
          print CPU_MEM $startapp_cpu[$time_index],"        \t";
          #print CPU_MEM $cmcenter_cpu[$time_index],"        \t";
          #print CPU_MEM $spyres_cpu[$time_index],"        \t";
          print CPU_MEM $drserver_cpu[$time_index],"        \t";
          print CPU_MEM $billserver_cpu[$time_index],"         \t";
          print CPU_MEM $smserver_cpu[$time_index],"        \t";
          print CPU_MEM $dbserver_cpu[$time_index],"        \t";
          print CPU_MEM $msgstore_cpu[$time_index],"        \t";
          print CPU_MEM $billclient_cpu[$time_index],"   \t";


          print CPU_MEM $spagent_mem[$time_index],"         \t";
          print CPU_MEM $smcagent_mem[$time_index],"        \t";
          print CPU_MEM $smgagent_mem[$time_index],"        \t";
          print CPU_MEM $mdspagent_mem[$time_index],"        \t";
          print CPU_MEM $scpagent_mem[$time_index],"        \t";                 
          #print CPU_MEM $smmcagent_mem[$time_index],"       \t";
          print CPU_MEM $startapp_mem[$time_index],"        \t";
          #print CPU_MEM $cmcenter_mem[$time_index],"        \t";
          #print CPU_MEM $spyres_mem[$time_index],"        \t";
          print CPU_MEM $drserver_mem[$time_index],"        \t";
          print CPU_MEM $billserver_mem[$time_index],"         \t";
          print CPU_MEM $smserver_mem[$time_index],"        \t";
          print CPU_MEM $dbserver_mem[$time_index],"        \t";
          print CPU_MEM $msgstore_mem[$time_index],"        \t";
          print CPU_MEM $billclient_mem[$time_index],"        \t";
          print CPU_MEM "\n";
      }   
   }
   else
   {
      #print CPU_MEM "spagent_cpu  \t";   
      #print CPU_MEM "smcagent_cpu\t";
      #print CPU_MEM "smgagent_cpu\t";
      #print CPU_MEM "mdspagent_cpu\t";
      #print CPU_MEM "scpagent_cpu\t";
      #print CPU_MEM "smmcagent_cpu\t";
      print CPU_MEM "startapp_cpu\t";
      #print CPU_MEM "cmcenter_cpu\t";
      #print CPU_MEM "spyres_cpu\t";
      print CPU_MEM "drserver_cpu\t";
      print CPU_MEM "billserver_cpu\t";
      print CPU_MEM "smserver_cpu\t";
      print CPU_MEM "dbserver_cpu\t";
      print CPU_MEM "msgstore_cpu\t";
      print CPU_MEM "billclient_cpu   \t";
   

      #print CPU_MEM "spagent_mem  \t";   
      #print CPU_MEM "smcagent_mem\t";
      #print CPU_MEM "smgagent_mem\t";
      #print CPU_MEM "mdspagent_mem\t";
      #print CPU_MEM "scpagent_mem\t";
      #print CPU_MEM "smmcagent_mem\t";      
      print CPU_MEM "startapp_mem\t";
      #print CPU_MEM "cmcenter_mem\t";
      #print CPU_MEM "spyres_mem\t";
      print CPU_MEM "drserver_mem\t";
      print CPU_MEM "billserver_mem\t";
      print CPU_MEM "smserver_mem\t";
      print CPU_MEM "dbserver_mem\t";
      print CPU_MEM "msgstore_mem\t";
      print CPU_MEM "billclient_mem\t";

      
      print CPU_MEM "\n";
       
      for($time_index=0;$time_index<@time_array;$time_index++)
      {
          print CPU_MEM $time_array[$time_index],"\t";
          
          #print CPU_MEM $spagent_cpu[$time_index],"         \t";
          #print CPU_MEM $smcagent_cpu[$time_index],"        \t";
          #print CPU_MEM $smgagent_cpu[$time_index],"        \t";
          #print CPU_MEM $mdspagent_cpu[$time_index],"        \t";
          #print CPU_MEM $scpagent_cpu[$time_index],"        \t";                 
          #print CPU_MEM $smmcagent_cpu[$time_index],"        \t";
          print CPU_MEM $startapp_cpu[$time_index],"        \t";
          #print CPU_MEM $cmcenter_cpu[$time_index],"        \t";
          #print CPU_MEM $spyres_cpu[$time_index],"        \t";
          print CPU_MEM $drserver_cpu[$time_index],"        \t";
          print CPU_MEM $billserver_cpu[$time_index],"         \t";
          print CPU_MEM $smserver_cpu[$time_index],"        \t";
          print CPU_MEM $dbserver_cpu[$time_index],"        \t";
          print CPU_MEM $msgstore_cpu[$time_index],"        \t";
          print CPU_MEM $billclient_cpu[$time_index],"   \t";


          #print CPU_MEM $spagent_mem[$time_index],"         \t";
          #print CPU_MEM $smcagent_mem[$time_index],"        \t";
          #print CPU_MEM $smgagent_mem[$time_index],"        \t";
          #print CPU_MEM $mdspagent_mem[$time_index],"        \t";
          #print CPU_MEM $scpagent_mem[$time_index],"        \t";                 
          #print CPU_MEM $smmcagent_mem[$time_index],"       \t";
          print CPU_MEM $startapp_mem[$time_index],"        \t";
          #print CPU_MEM $cmcenter_mem[$time_index],"        \t";
          #print CPU_MEM $spyres_mem[$time_index],"        \t";
          print CPU_MEM $drserver_mem[$time_index],"        \t";
          print CPU_MEM $billserver_mem[$time_index],"         \t";
          print CPU_MEM $smserver_mem[$time_index],"        \t";
          print CPU_MEM $dbserver_mem[$time_index],"        \t";
          print CPU_MEM $msgstore_mem[$time_index],"        \t";
          print CPU_MEM $billclient_mem[$time_index],"        \t";
          print CPU_MEM "\n";
      }   
   }
      
   close(CPU_MEM);
}


#短信行业用
sub cpu_mem_sms_e()
{
   my $cur_path=getcwd;
   chomp($cur_path);
   
   #my $basehome=`env |grep HOME | grep -vi _ | grep -vi db2 | awk -F "=" '{print \$2}'`;
   my $basehome=$ENV{INFOX_ROOT}; 
   chomp($basehome);

   #判断文件是否存在，防止用户选择网关类型不匹配时脚本报错
   (-f "$basehome/config/infox.proc") || die "\n 你选择的是：【短信行业网关】，config目录下不存在 infox.proc 文件.\n\n";
   
   my $agent=`cat $basehome/config/infox.proc  | grep agent | grep -v npagent | awk -F " " '{print \$2,\$1,\$4}'`;
   @agentary=split("\n",$agent);
   $scalar = @agentary; 
   chomp($scalar);

   if($scalar != 0)
   {
      for(my $i=0;$i<$scalar;$i++)
      {
           my $agentinfo=$agentary[$i];
       
           if($agentinfo =~ /ecagent/)
           {
              $ecagentinfo=substr($agentinfo,0,4);
              chop($ecagentinfo);
           }
           elsif($agentinfo =~ /smcagent/)
           {
              $smcagentinfo=substr($agentinfo,0,4);
              chop($smcagentinfo);
           }
           elsif($agentinfo =~ /smgagent/)
           {
              $smgagentinfo=substr($agentinfo,0,4);
              chop($smgagentinfo);
           }
           elsif($agentinfo =~ /mdspagent/)
           {
              $mdspagentinfo=substr($agentinfo,0,4);
              chop($mdspagentinfo);
           }
           elsif($agentinfo =~ /scpagent/)
           {
              $scpagentinfo=substr($agentinfo,0,4);
              chop($scpagentinfo);
           }
           else
           {
              #do nothing
           }
      }   
   }
   else
   {
      print "\n当前节点下无Agent模块，继续处理......\n\n";
   }


   my @startapp_cpu=();
   my @drserver_cpu=();
   my @billserver_cpu=();
   my @smserver_cpu=();
   my @dbserver_cpu=();
   my @msgstore_cpu=();
   my @billclient_cpu=();
   my @ecagent_cpu=();   
   my @smcagent_cpu=();
   my @smgagent_cpu=();
   my @mdspagent_cpu=();
   my @scpagent_cpu=();

   my @startapp_mem=();
   my @drserver_mem=();
   my @billserver_mem=();
   my @smserver_mem=();
   my @dbserver_mem=();
   my @msgstore_mem=();
   my @billclient_mem=();
   my @ecagent_mem=();
   my @smcagent_mem=();
   my @smgagent_mem=();
   my @mdspagent_mem=();
   my @scpagent_mem=();
    
   my $time_index=-1;
   my @time_array=();

   #open input file
   @ARGV=("$cpu_mem_file");
   while ($line = <>)
   {
       $line=~s/^(\s+)/0/;
       @fields=split(/\s+/,$line);
      
      if($scalar != 0)
      {
         if ( $line =~ m/$ecagentinfo$/)       #ecagent
          {
                $ecagent_cpu[$time_index] += $fields[2];
                $ecagent_mem[$time_index] += $fields[3];
          }
          elsif ( $line =~ m/$smcagentinfo$/)   #smcagent
          {
                $smcagent_cpu[$time_index] += $fields[2];
                $smcagent_mem[$time_index] += $fields[3];
          }
          elsif ( $line =~ m/$smgagentinfo$/)   #smgagent
          {
                $smgagent_cpu[$time_index] += $fields[2];
                $smgagent_mem[$time_index] += $fields[3];
          }
          elsif ( $line =~ m/$mdspagentinfo$/)   #mdspagent
          {
                $mdspagent_cpu[$time_index] += $fields[2];
                $mdspagent_mem[$time_index] += $fields[3];
          }
          elsif ( $line =~ m/$scpagentinfo$/)    #scpagent
          {
                $scpagent_cpu[$time_index] += $fields[2];
                $scpagent_mem[$time_index] += $fields[3];
          }
          elsif ( $line =~ m/smserver/)
          {
                $smserver_cpu[$time_index] += $fields[2];
                $smserver_mem[$time_index] += $fields[3];
          }
          elsif ( $line =~ m/billclient/)
          {
                $billclient_cpu[$time_index] += $fields[2];	
                $billclient_mem[$time_index] += $fields[3];
          }
          elsif ( $line =~ m/msgstore/)
          {
                $msgstore_cpu[$time_index] += $fields[2];
                $msgstore_mem[$time_index] += $fields[3];     	 
          }
          elsif ( $line =~ m/dbserver/)
          {
                $dbserver_cpu[$time_index] += $fields[2];
                $dbserver_mem[$time_index] += $fields[3];
          }
          elsif ( $line =~ m/drserver/)
          {
                $drserver_cpu[$time_index] += $fields[2];
                $drserver_mem[$time_index] += $fields[3];
          }
          elsif ( $line =~ m/billserver/)
          {
                $billserver_cpu[$time_index] += $fields[2];
                $billserver_mem[$time_index] += $fields[3];
          }
          elsif ( $line =~ m/startapp/) 
          {
            $startapp_cpu[$time_index] += $fields[2];
            $startapp_mem[$time_index] += $fields[3];
          }
          elsif( $line =~ /\d{4}-\d{2}-\d{2}/)		#采样时间点获取
          {
                $time_array[++$time_index] = $fields[1];
          }
      }
      else
      {
         if ( $line =~ m/smserver/)
          {
                $smserver_cpu[$time_index] += $fields[2];
                $smserver_mem[$time_index] += $fields[3];
          }
          elsif ( $line =~ m/billclient/)
          {
                $billclient_cpu[$time_index] += $fields[2];	
                $billclient_mem[$time_index] += $fields[3];
          }
          elsif ( $line =~ m/msgstore/)
          {
                $msgstore_cpu[$time_index] += $fields[2];
                $msgstore_mem[$time_index] += $fields[3];     	 
          }
          elsif ( $line =~ m/dbserver/)
          {
                $dbserver_cpu[$time_index] += $fields[2];
                $dbserver_mem[$time_index] += $fields[3];
          }
          elsif ( $line =~ m/drserver/)
          {
                $drserver_cpu[$time_index] += $fields[2];
                $drserver_mem[$time_index] += $fields[3];
          }
          elsif ( $line =~ m/billserver/)
          {
                $billserver_cpu[$time_index] += $fields[2];
                $billserver_mem[$time_index] += $fields[3];
          }
          elsif ( $line =~ m/startapp/) 
          {
            $startapp_cpu[$time_index] += $fields[2];
            $startapp_mem[$time_index] += $fields[3];
          }
          elsif( $line =~ /\d{4}-\d{2}-\d{2}/)		#采样时间点获取
          {
               $time_array[++$time_index] = $fields[1];
          }   
      }
       
   }
   open CPU_MEM, "> ./source/cpu_mem_dp.txt" or die "can not open filefor write!\n";
      print CPU_MEM "Time     \t";
      
      if($scalar != 0)
      {
         print CPU_MEM "ecagent_cpu  \t";   
         print CPU_MEM "smcagent_cpu\t";
         print CPU_MEM "smgagent_cpu\t";
         print CPU_MEM "mdspagent_cpu\t";
         print CPU_MEM "scpagent_cpu\t";
         print CPU_MEM "startapp_cpu\t";
         print CPU_MEM "drserver_cpu\t";
         print CPU_MEM "billserver_cpu\t";
         print CPU_MEM "smserver_cpu\t";
         print CPU_MEM "dbserver_cpu\t";
         print CPU_MEM "msgstore_cpu\t";
         print CPU_MEM "billclient_cpu   \t";
      
   
         print CPU_MEM "ecagent_mem  \t";   
         print CPU_MEM "smcagent_mem\t";
         print CPU_MEM "smgagent_mem\t";
         print CPU_MEM "mdspagent_mem\t";
         print CPU_MEM "scpagent_mem\t";
         print CPU_MEM "startapp_mem\t";
         print CPU_MEM "drserver_mem\t";
         print CPU_MEM "billserver_mem\t";
         print CPU_MEM "smserver_mem\t";
         print CPU_MEM "dbserver_mem\t";
         print CPU_MEM "msgstore_mem\t";
         print CPU_MEM "billclient_mem\t";
   
         
         print CPU_MEM "\n";
          
         for($time_index=0;$time_index<@time_array;$time_index++)
         {
             print CPU_MEM $time_array[$time_index],"\t";
             
             print CPU_MEM $ecagent_cpu[$time_index],"         \t";
             print CPU_MEM $smcagent_cpu[$time_index],"        \t";
             print CPU_MEM $smgagent_cpu[$time_index],"        \t";
             print CPU_MEM $mdspagent_cpu[$time_index],"        \t";
             print CPU_MEM $scpagent_cpu[$time_index],"        \t";                 
             print CPU_MEM $startapp_cpu[$time_index],"        \t";
             print CPU_MEM $drserver_cpu[$time_index],"        \t";
             print CPU_MEM $billserver_cpu[$time_index],"         \t";
             print CPU_MEM $smserver_cpu[$time_index],"        \t";
             print CPU_MEM $dbserver_cpu[$time_index],"        \t";
             print CPU_MEM $msgstore_cpu[$time_index],"        \t";
             print CPU_MEM $billclient_cpu[$time_index],"   \t";
   
   
             print CPU_MEM $ecagent_mem[$time_index],"         \t";
             print CPU_MEM $smcagent_mem[$time_index],"        \t";
             print CPU_MEM $smgagent_mem[$time_index],"        \t";
             print CPU_MEM $mdspagent_mem[$time_index],"        \t";
             print CPU_MEM $scpagent_mem[$time_index],"        \t";                 
             print CPU_MEM $startapp_mem[$time_index],"        \t";
             print CPU_MEM $drserver_mem[$time_index],"        \t";
             print CPU_MEM $billserver_mem[$time_index],"         \t";
             print CPU_MEM $smserver_mem[$time_index],"        \t";
             print CPU_MEM $dbserver_mem[$time_index],"        \t";
             print CPU_MEM $msgstore_mem[$time_index],"        \t";
             print CPU_MEM $billclient_mem[$time_index],"        \t";
         
             print CPU_MEM "\n";
         }   
      }
      else
      {
         print CPU_MEM "startapp_cpu\t";
         print CPU_MEM "drserver_cpu\t";
         print CPU_MEM "billserver_cpu\t";
         print CPU_MEM "smserver_cpu\t";
         print CPU_MEM "dbserver_cpu\t";
         print CPU_MEM "msgstore_cpu\t";
         print CPU_MEM "billclient_cpu   \t";

         print CPU_MEM "startapp_mem\t";
         print CPU_MEM "drserver_mem\t";
         print CPU_MEM "billserver_mem\t";
         print CPU_MEM "smserver_mem\t";
         print CPU_MEM "dbserver_mem\t";
         print CPU_MEM "msgstore_mem\t";
         print CPU_MEM "billclient_mem\t";
   
         
         print CPU_MEM "\n";
          
         for($time_index=0;$time_index<@time_array;$time_index++)
         {
             print CPU_MEM $time_array[$time_index],"\t";
             
             print CPU_MEM $scpagent_cpu[$time_index],"        \t";                 
             print CPU_MEM $startapp_cpu[$time_index],"        \t";
             print CPU_MEM $drserver_cpu[$time_index],"        \t";
             print CPU_MEM $billserver_cpu[$time_index],"         \t";
             print CPU_MEM $smserver_cpu[$time_index],"        \t";
             print CPU_MEM $dbserver_cpu[$time_index],"        \t";
             print CPU_MEM $msgstore_cpu[$time_index],"        \t";
             print CPU_MEM $billclient_cpu[$time_index],"   \t";
            
             print CPU_MEM $startapp_mem[$time_index],"        \t";
             print CPU_MEM $drserver_mem[$time_index],"        \t";
             print CPU_MEM $billserver_mem[$time_index],"         \t";
             print CPU_MEM $smserver_mem[$time_index],"        \t";
             print CPU_MEM $dbserver_mem[$time_index],"        \t";
             print CPU_MEM $msgstore_mem[$time_index],"        \t";
             print CPU_MEM $billclient_mem[$time_index],"        \t";
         
             print CPU_MEM "\n";
         }   
      }
      
   close(CPU_MEM);
}


#M模块用
sub cpu_mem_M()
{
   my $cur_path=getcwd;
   chomp($cur_path);
   
   my $basehome=`env | grep HOME | grep -vi _ | awk -F "=" '{print \$2}'`;
   chomp($basehome);

   #判断文件是否存在，防止用户选择网关类型不匹配时脚本报错
   (-f "$basehome/config/imuseubb") || die "\n 你选择的是：【M模块】，config目录下不存在 imuseubb 文件.\n\n";
   (-f "./source/cpu_mem.txt") || die "\nCant't find file cpu_mem.txt for M in source dir.\n\n";
   
   my $umsgsrv=`cat ./source/cpu_mem.txt | head -10 | grep umsgsrv | awk -F " " '{print \$6,\$7,\$8,\$9,\$10}'`;
   
   @umsgsrvary=split("\n",$umsgsrv);
   my $umsgsrv_no1=$umsgsrvary[0];
   my $umsgsrv_no2=$umsgsrvary[1];
   my $umsgsrv_no3=$umsgsrvary[2];
   my $umsgsrv_no4=$umsgsrvary[3];
   my $umsgsrv_no5=$umsgsrvary[4];

   my @mdspmon_cpu=();
   my @uclient_cpu=();
   my @umsgsrv_no1_cpu=();
   my @umsgsrv_no2_cpu=();
   my @umsgsrv_no3_cpu=();
   my @umsgsrv_no4_cpu=();
   my @umsgsrv_no5_cpu=();
   my @smpa_cpu=();   
   my @cmanager_cpu=();
   my @taskmgr_cpu=();
   my @memrefresh_cpu=();

   my @mdspmon_mem=();    
   my @uclient_mem=();    
   my @umsgsrv_no1_mem=();
   my @umsgsrv_no2_mem=();
   my @umsgsrv_no3_mem=();
   my @umsgsrv_no4_mem=();
   my @umsgsrv_no5_mem=();
   my @smpa_mem=();       
   my @cmanager_mem=();   
   my @taskmgr_mem=();    
   my @memrefresh_mem=();
    
   my $time_index=-1;
   my @time_array=();

   #open input file
   @ARGV=("$cpu_mem_file");
   while ($line = <>)
   {
       $line=~s/^(\s+)/0/;
       @fields=split(/\s+/,$line);

       if ( $line =~ m/mdspmon/)       #mdspmon
       {
   	     $mdspmon_cpu[$time_index] += $fields[2];
   	     $mdspmon_mem[$time_index] += $fields[3];
       }
       elsif ( $line =~ m/uclient/)   #uclient
       {
   	     $uclient_cpu[$time_index] += $fields[2];
   	     $uclient_mem[$time_index] += $fields[3];
       }
       elsif ( $line =~ m/$umsgsrv_no1/)
       {
   	     $umsgsrv_no1_cpu[$time_index] += $fields[2];
   	     $umsgsrv_no1_mem[$time_index] += $fields[3];
       }
       elsif ( $line =~ m/$umsgsrv_no2/)
       {
   	     $umsgsrv_no2_cpu[$time_index] += $fields[2];
   	     $umsgsrv_no2_mem[$time_index] += $fields[3];
       }
       elsif ( $line =~ m/$umsgsrv_no3/)
       {
   	     $umsgsrv_no3_cpu[$time_index] += $fields[2];
   	     $umsgsrv_no3_mem[$time_index] += $fields[3];
       }
       elsif ( $line =~ m/$umsgsrv_no4/)
       {
   	     $umsgsrv_no4_cpu[$time_index] += $fields[2];
   	     $umsgsrv_no4_mem[$time_index] += $fields[3];
       }
       elsif ( $line =~ m/$umsgsrv_no5/)
       {
   	     $umsgsrv_no5_cpu[$time_index] += $fields[2];	
   	     $umsgsrv_no5_mem[$time_index] += $fields[3];
       }
       elsif ( $line =~ m/smpa/)
       {
   	     $smpa_cpu[$time_index] += $fields[2];
   	     $smpa_mem[$time_index] += $fields[3];
       }
       elsif ( $line =~ m/cmanager/)
       {
   	     $cmanager_cpu[$time_index] += $fields[2];
   	     $cmanager_mem[$time_index] += $fields[3];
       }
       elsif ( $line =~ m/taskmgr/)
       {
   	     $taskmgr_cpu[$time_index] += $fields[2];
   	     $taskmgr_mem[$time_index] += $fields[3];
       }
       elsif ( $line =~ m/memrefresh/)
       {
   	     $memrefresh_cpu[$time_index] += $fields[2];
   	     $memrefresh_mem[$time_index] += $fields[3];
       }
       elsif( $line =~ /\d{4}-\d{2}-\d{2}/)		#采样时间点获取
       {
   	     $time_array[++$time_index] = $fields[1];
       }    
   }
   
   open CPU_MEM, "> ./source/cpu_mem_dp.txt" or die "can not open filefor write!\n";
      print CPU_MEM "Time     \t";
      
      print CPU_MEM "mdspmon_cpu  \t";   
      print CPU_MEM "uclient_cpu  \t";
      print CPU_MEM "umsgsrv_no1_cpu  \t";
      print CPU_MEM "umsgsrv_no2_cpu  \t";
      print CPU_MEM "umsgsrv_no3_cpu  \t";
      print CPU_MEM "umsgsrv_no4_cpu  \t";
      print CPU_MEM "umsgsrv_no5_cpu  \t";
      print CPU_MEM "smpa_cpu  \t";
      print CPU_MEM "cmanager_cpu  \t";
      print CPU_MEM "taskmgr_cpu  \t";
      print CPU_MEM "memrefresh_cpu  \t";

      print CPU_MEM "mdspmon__mem  \t";   
      print CPU_MEM "uclient_mem  \t";
      print CPU_MEM "umsgsrv_no1_mem  \t";
      print CPU_MEM "umsgsrv_no2_mem  \t";
      print CPU_MEM "umsgsrv_no3_mem  \t";
      print CPU_MEM "umsgsrv_no4_mem  \t";
      print CPU_MEM "umsgsrv_no5_mem  \t";
      print CPU_MEM "smpa_mem  \t";
      print CPU_MEM "cmanager_mem  \t";
      print CPU_MEM "taskmgr_mem  \t";
      print CPU_MEM "memrefresh_mem  \t";

      print CPU_MEM "\n";
       
      for($time_index=0;$time_index<@time_array;$time_index++)
      {
          print CPU_MEM $time_array[$time_index],"\t";
          
          print CPU_MEM $mdspmon_cpu[$time_index],"         \t";
          print CPU_MEM $uclient_cpu[$time_index],"        \t";
          print CPU_MEM $umsgsrv_no1_cpu[$time_index],"        \t";
          print CPU_MEM $umsgsrv_no2_cpu[$time_index],"        \t";
          print CPU_MEM $umsgsrv_no3_cpu[$time_index],"        \t";                 
          print CPU_MEM $umsgsrv_no4_cpu[$time_index],"        \t";
          print CPU_MEM $umsgsrv_no5_cpu[$time_index],"        \t";
          print CPU_MEM $smpa_cpu[$time_index],"         \t";
          print CPU_MEM $cmanager_cpu[$time_index],"        \t";
          print CPU_MEM $taskmgr_cpu[$time_index],"        \t";
          print CPU_MEM $memrefresh_cpu[$time_index],"      \t";


          print CPU_MEM $mdspmon_mem[$time_index],"         \t";
          print CPU_MEM $uclient_mem[$time_index],"        \t";
          print CPU_MEM $umsgsrv_no1_mem[$time_index],"        \t";
          print CPU_MEM $umsgsrv_no2_mem[$time_index],"        \t";
          print CPU_MEM $umsgsrv_no3_mem[$time_index],"        \t";                 
          print CPU_MEM $umsgsrv_no4_mem[$time_index],"        \t";
          print CPU_MEM $umsgsrv_no5_mem[$time_index],"        \t";
          print CPU_MEM $smpa_mem[$time_index],"         \t";
          print CPU_MEM $cmanager_mem[$time_index],"        \t";
          print CPU_MEM $taskmgr_mem[$time_index],"        \t";
          print CPU_MEM $memrefresh_mem[$time_index],"        \t";
      
          print CPU_MEM "\n";
      }
   close(CPU_MEM);
}



sub iostat()
{
   ##从配置文件读取信息
   my $cfg = Config::IniFiles->new( -file => "./config/config.ini" );
   my $iostat_file="./source/iostat.txt";
   my $disk=$cfg->val('GW_PERFROMANCE','Disk' ) || '';                             #要分析的分区名称

   ##判断os类型
   if($os_type=~ m/linux/)
   {
      my @mms_time=();
      my @mms_iops_read=();
      my @mms_iops_writ=();
      my @mms_iops_wait=();
      my @mms_iops_util=();
      
      my $iostat_index=-1;
      
      #print "\n请输入待分析文件名：";
      #chomp($iostat_file=<STDIN>);
   
      #print "\n请输入待分析磁盘名:";
      #chomp($disk=<STDIN>);
      #$disk = lc($disk);
   
      #open input file
      @ARGV=("$iostat_file");
      while ($line = <>)
      {
          @fields=split(/\s+/,$line);
          if ( $line =~ m/$disk/)
          {
                $mms_iops_read[$iostat_index] += $fields[3];
                $mms_iops_write[$iostat_index] += $fields[4];
                $mms_iops_wait[$iostat_index] += $fields[9];
                $mms_iops_util[$iostat_index] += $fields[11];
          }
          elsif( $line =~ m/^Time/)		#采样时间点获取
          {
                $mms_time[++$iostat_index] = $fields[1];
          }    
      }
      open IOSTAT, "> ./source/iostat_dp.txt"
      or die "can not open filefor write!\n";
      
      print IOSTAT "Time    \t\t";
      print IOSTAT "rKB\/s\t\t";
      print IOSTAT "wKB\/s\t\t";
      print IOSTAT "await\/ms\t\t";
      print IOSTAT "util\/%\t";
      print IOSTAT "\n";
       
      for($iostat_index=1;$iostat_index<@mms_time;$iostat_index++)
      {
         print IOSTAT $mms_time[$iostat_index],"\t\t";            
         print IOSTAT $mms_iops_read[$iostat_index],"\t\t";
         print IOSTAT $mms_iops_write[$iostat_index],"\t\t";
         print IOSTAT $mms_iops_wait[$iostat_index],"\t\t";
         print IOSTAT $mms_iops_util[$iostat_index],"\t\t";
              
         print IOSTAT "\n";
      }
      close(IOSTAT);   
   }
   elsif($os_type=~ m/aix/)
   {
      system("cat ./source/iostat.txt | grep $disk | grep -v lcpu | grep -v \"\%\" | sed \'\/\^\$\/d\' | awk -F \" \" \'\{print \$1,\$5,\$6\}\'  > ./source/iostat_tmp.txt");
   
      open(INFILE,"./source/iostat_tmp.txt") || die "\nOpen file failed:$!\n\n";
      
      my @ary1=<INFILE>;                   #一维数组
      
      close(INFILE);
      
      foreach $eachline (@ary1)
      {
          chomp($eachline);
          my @tmp=split(/ /,$eachline);    #拆分每行中值，获取的值放到临时数组中
          push @ary2,[@tmp];               #将一维数组插入二维数组
      }
      
      open(IOSTAT,">./source/iostat_dp.txt") || die "\nOpen file failed:$@\n\n";
      
      for $i(0..$#ary2)
      {
          ##定义格式
          $~="IOSTAT";
     
          format IOSTAT=
     @<<<<<<<<<<     @<<<<<<<<<<     @<<<<<<<<<<
          $ary2[$i][0]  , $ary2[$i][1]  , $ary2[$i][2]
.
     
         write IOSTAT;
     }
     
     close(IOSTAT);
     
     ##清理过度文件
     unlink("./source/iostat_tmp.txt");
   }
}


#cpu_mem.txt文件处理
if($opt_a)
{
  killproc();
  cpu_mem_mmsg();
}
elsif($opt_m)
{
  killproc();
  cpu_mem_M();
}
elsif($opt_s)
{
  killproc();
  cpu_mem_sms_s();
}
elsif($opt_e)
{
  killproc();
  cpu_mem_sms_e();
}
else
{
  print "\n参数输入不合法，请参照上面的使用方法.\n\n\n";
  exit;
}

#iostat.txt文件处理
iostat();
