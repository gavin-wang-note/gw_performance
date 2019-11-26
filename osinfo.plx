#!/usr/bin/perl
use warnings;
use strict 'vars';
use Sys::Hostname;
use Socket;

#########################################################################################
#    ###############################################################################    #
#   #      ˵����   ��ȡOS���Ӳ����Ϣ                                              #   #
#   #                                                                               #   #
#   #      ʹ�ã�   perl   osinfo.plx                                               #   #
#   #      AUTH��   wangyunzeng                                                     #   #
#   #      VER ��   1.0                                                             #   #
#   #      TIME��   2012-09-07   11:36   create                                     #   #
#    ###############################################################################    #
#########################################################################################
##ȫ�ֱ���
#����ϵͳ����
my $Os_type=$^O;

#��ȡ��ǰ����IP��ַ
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
   my $eth_info=`/sbin/lspci | grep Ethernet | awk -F ":" '{print \$3}' | head -1`;   #������Ϣ
   
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
   
   print "\n��ǰ����ϵͳ��:                 $OS_info  \n";
   print "\n�ڴ��С��:                     $mem G  \n";+
   print "\nCPU��Ϣ���ͺţ���:        $cpu_info  \n";
   print "\n�߼�CPU����:                    $logic_cpu_num  \n";
   print "\n����CPU����:                    $physical_cpu_num  \n";
   print "\nÿ������CPU��Core�ĸ���:        $peer_cpu_core_num  \n";
   print "\n������Ϣ:                      $eth_info  \n";
   print "\n\n";
   
   ##д���ļ�
   open(OSINFO,">./source/osinfo.txt") || die "\nLinux:Open file failed,$!\n\n";
   print OSINFO "\n��ǰ�ڵ�IP��$localip\n";
   print OSINFO "\n��ǰ����ϵͳ��:                 $OS_info\n";
   print OSINFO "\n�ڴ��С��:                     $mem G\n";
   print OSINFO "\nCPU��Ϣ���ͺţ���:        $cpu_info\n";
   print OSINFO "\n�߼�CPU����:                    $logic_cpu_num\n";
   print OSINFO "\n����CPU����:                    $physical_cpu_num\n";
   print OSINFO "\nÿ������CPU��Core�ĸ���:        $peer_cpu_core_num\n";
   print OSINFO "\n������Ϣ:                      $eth_info\n";
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
   
   print "\n����CPU������$physical_cpu_nums (��)\n";
   
   if($logic_cpu_num_tmp==1)
   {
      print "\n�߼�CPU������ $logic_cpu_nums (��)\n";  
   }
   elsif($logic_cpu_num_tmp==3)
   {
      print "\n�߼�CPU������ $logic_cpu_nums (��)\n";
   }
   elsif($logic_cpu_num_tmp==7)
   {
      print "\n�߼�CPU������ $logic_cpu_nums (��)\n";
   }
   elsif($logic_cpu_num_tmp==15)
   {
      print "\n�߼�CPU������ $logic_cpu_nums (��)\n";
   }
   
   
   print "\nCPU��Ƶ��    $speed\n";
   print "\nCPU Type��   $cpu_type\n";
   print "\n�ڴ��С��   $mem_size\n";
   print "\nKernel Type��$kernel_Type\n";
   print "\nPageSpace �� $pageSpace\n";
   
   ##д���ļ�
   open(OSINFO,">./source/osinfo.txt") || die "\nAIX:Open file failed,$!\n\n";
   print OSINFO "\n��ǰ�ڵ�IP��$localip\n";
   print OSINFO "\n��ǰ����ϵͳ��:                 AIX\n";
   print OSINFO "\n�ڴ��С��:                     $mem_size\n";
   print OSINFO "\nCPU������:                      $cpu_type\n";
   print OSINFO "\n�߼�CPU����:                    $logic_cpu_nums\n";
   print OSINFO "\n����CPU����:                    $physical_cpu_nums\n";
   print OSINFO "\n\n";
   close(OSINFO);
   
   
   ##�����ļ�����
   unlink("prtconf.txt");
   
   print '-' x 60,"\n"; 
}
elsif($Os_type=~ m/SUNOS/)
{
   print "\nSUNOS,�ݲ�֧��,����\n\n";
}
else
{
   print "\n��֧�ֵ�OS����:[$Os_type]\n\n";
   exit;
}

