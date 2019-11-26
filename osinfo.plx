#!/usr/bin/perl
use warnings;
use strict 'vars';
use Sys::Hostname;
use Socket;

#########################################################################################
#    ###############################################################################    #
#   #      说明：   获取OS相关硬件信息                                              #   #
#   #                                                                               #   #
#   #      使用：   perl   osinfo.plx                                               #   #
#   #      AUTH：   wangyunzeng                                                     #   #
#   #      VER ：   1.0                                                             #   #
#   #      TIME：   2012-09-07   11:36   create                                     #   #
#    ###############################################################################    #
#########################################################################################
##全局变量
#操作系统类型
my $Os_type=$^O;

#获取当前机器IP地址
my $host = hostname();
my $localip = inet_ntoa(scalar gethostbyname($host || 'localhost'));
chomp($localip);
  
if($Os_type=~ m/linux/)
{
   #print '-' x 60,"\n"; 
   my $OS_info=`cat /etc/issue | grep -i Linux | awk -F " " '{print \$3,\$4,\$5,\$6,\$7,\$8,\$9}'`;
   my $cpu_info=`cat /proc/cpuinfo | grep name | cut -f2 -d: | uniq -c`;
   my $logic_cpu_num=`cat /proc/cpuinfo | grep "processor" | wc -l`;
   my $physical_cpu_num_all=`cat /proc/cpuinfo | grep "physical id" | sort | wc -l`;
   my $physical_cpu_num_uniq=`cat /proc/cpuinfo | grep "physical id" | sort | uniq  | wc -l`;
   my $peer_cpu_core_num=`cat /proc/cpuinfo | grep "physical id" | sort | uniq | wc -l`;
   my $mem_tmp=`cat /proc/meminfo | grep MemTotal | awk -F ":" '{print \$2}' | awk -F " " '{print \$1}'`;
   my $eth_info=`/sbin/lspci | grep Ethernet | awk -F ":" '{print \$3}' | head -1`;   #网卡信息
   
   chomp($OS_info);
   chomp($cpu_info);
   chomp($logic_cpu_num);
   chomp($physical_cpu_num_all);
   chomp($physical_cpu_num_uniq);
   chomp($peer_cpu_core_num);
   chomp($eth_info);
   chomp($mem_tmp);
   
   my $physical_cpu_num=$physical_cpu_num_all/$physical_cpu_num_uniq;
   my $mem=int($mem_tmp/1000/1000);
   
   print "\n当前操作系统是:                 $OS_info  \n";
   print "\n内存大小是:                     $mem G  \n";+
   print "\nCPU信息（型号）是:        $cpu_info  \n";
   print "\n逻辑CPU个数:                    $logic_cpu_num  \n";
   print "\n物理CPU个数:                    $physical_cpu_num  \n";
   print "\n每个物理CPU中Core的个数:        $peer_cpu_core_num  \n";
   print "\n网卡信息:                      $eth_info  \n";
   print "\n\n";
   
   ##写入文件
   open(OSINFO,">./source/osinfo.txt") || die "\nLinux:Open file failed,$!\n\n";
   print OSINFO "\n当前节点IP：$localip\n";
   print OSINFO "\n当前操作系统是:                 $OS_info\n";
   print OSINFO "\n内存大小是:                     $mem G\n";
   print OSINFO "\nCPU信息（型号）是:        $cpu_info\n";
   print OSINFO "\n逻辑CPU个数:                    $logic_cpu_num\n";
   print OSINFO "\n物理CPU个数:                    $physical_cpu_num\n";
   print OSINFO "\n每个物理CPU中Core的个数:        $peer_cpu_core_num\n";
   print OSINFO "\n网卡信息:                      $eth_info\n";
   print OSINFO "\n\n";
   close(OSINFO);
   
   print '-' x 60,"\n"; 
}
elsif($Os_type=~ m/aix/)
{
   system("prtconf > prtconf.txt");
   my $physical_cpu_nums=`cat prtconf.txt  | grep Processors | awk -F \"\:\" \'\{print \$2\}\'`;
   my $logic_cpu_num_tmp=`bindprocessor -q | awk -F \"\:\" \'\{print \$2\}\' | awk -F \" \" \'\{print \$NF\}\'`;
   my $logic_cpu_nums=$logic_cpu_num_tmp+1;
   
   my $mem_size=`cat prtconf.txt | grep \"Good Memory Size\" | awk -F \"\:\" \'\{print \$2\}\'`;
   my $speed=`cat prtconf.txt | grep \"Processor Clock Speed\" | awk -F \"\:\" \'\{print \$2\}\'`;
   my $cpu_type=`cat prtconf.txt | grep \"CPU Type\" | awk -F \"\:\" \'\{print \$2\}\'`;
   my $kernel_Type=`cat prtconf.txt | grep \"Kernel Type\" |  awk -F \"\:\" \'\{print \$2\}\'`;
   my $pageSpace=`cat prtconf.txt | grep \"Total Paging Space\" | awk -F \"\:\" \'\{print \$2\}\'`;
   
   chomp($physical_cpu_nums);
   chomp($logic_cpu_num_tmp);
   chomp($mem_size);
   chomp($speed);
   chomp($cpu_type);
   chomp($kernel_Type);
   chomp($pageSpace);
   
   print "\n物理CPU个数：$physical_cpu_nums (个)\n";
   
   if($logic_cpu_num_tmp==1)
   {
      print "\n逻辑CPU个数： $logic_cpu_nums (个)\n";  
   }
   elsif($logic_cpu_num_tmp==3)
   {
      print "\n逻辑CPU个数： $logic_cpu_nums (个)\n";
   }
   elsif($logic_cpu_num_tmp==7)
   {
      print "\n逻辑CPU个数： $logic_cpu_nums (个)\n";
   }
   elsif($logic_cpu_num_tmp==15)
   {
      print "\n逻辑CPU个数： $logic_cpu_nums (个)\n";
   }
   
   
   print "\nCPU主频：    $speed\n";
   print "\nCPU Type：   $cpu_type\n";
   print "\n内存大小：   $mem_size\n";
   print "\nKernel Type：$kernel_Type\n";
   print "\nPageSpace ： $pageSpace\n";
   
   ##写入文件
   open(OSINFO,">./source/osinfo.txt") || die "\nAIX:Open file failed,$!\n\n";
   print OSINFO "\n当前节点IP：$localip\n";
   print OSINFO "\n当前操作系统是:                 AIX\n";
   print OSINFO "\n内存大小是:                     $mem_size\n";
   print OSINFO "\nCPU类型是:                      $cpu_type\n";
   print OSINFO "\n逻辑CPU个数:                    $logic_cpu_nums\n";
   print OSINFO "\n物理CPU个数:                    $physical_cpu_nums\n";
   print OSINFO "\n\n";
   close(OSINFO);
   
   
   ##过渡文件清理
   unlink("prtconf.txt");
   
   print '-' x 60,"\n"; 
}
elsif($Os_type=~ m/SUNOS/)
{
   print "\nSUNOS,暂不支持,余留\n\n";
}
else
{
   print "\n不支持的OS类型:[$Os_type]\n\n";
   exit;
}

