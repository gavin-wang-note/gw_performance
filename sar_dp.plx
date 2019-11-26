#!/usr/bin/perl

use strict 'vars';
use warnings;
use Cwd;
use Config::IniFiles;

#########################################################################################
#    ###############################################################################    #
#   #      说明：   对sar.txt文件进行二次处理                                       #   #
#   #                                                                               #   #
#   #      使用：   perl   sar_dp.plx                                               #   #
#   #      AUTH：   wangyunzeng                                                     #   #
#   #      VER ：   1.0                                                             #   #
#   #      TIME：   2012-08-24   09:12   create                                     #   #
#   #               2012-09-11   20:21   modify     增加按CPU类型分列显示数据       #   #
#   #               2012-09-19   09:57   modify     仅集群时候，按CPU类型分列显示   #   #
#    ###############################################################################    #
#########################################################################################

#定义全局变量
my $line;
my $eachline;
my $i;
my $j;
my @ary2=();

##操作系统类型
my $os_type=$^O;
my $cur_path=getcwd;


##从配置文件读取信息
my $cfg = Config::IniFiles->new( -file => "./config/config.ini" );
my $iscluster=$cfg->val('GW_PERFROMANCE','IsCluster') || '';                    #是否是进群环境
$iscluster=lc($iscluster);

print '-' x 60,"\n";
print "\n对sar.txt文件进行二次处理.\n\n";

if($os_type=~ m/linux/)
{
   &linux_type;
   
   ##add by wangyunzeng  2012-09-19   仅非集群环境下，才对文件进行再次处理
   if($iscluster eq "no" || $iscluster eq "n")
   {
      &dispose_sar;
   }
}
elsif($os_type=~ m/aix/)
{
    &aix_type;
}

sub linux_type()
{
   system("cat ./source/sar.txt | grep -v \"Linux\" | grep -v CPU | grep -v Average | sed \'\/\^\$\/d\' | sed \'s\/时\/\:\/g\' | sed \'s\/分\/\:\/g\' | sed \'s\/秒\/\/g\'  | sed \'s\/PM\/\/g\' | sed \'s\/AM\/\/g\' | awk -F \" \" \'\{print \$1,\$2,\$3+\$5+\$6\}\' > ./source/sar_tmp.txt");
   open(INFILE,"./source/sar_tmp.txt") || die "\nOpen file failed:$!\n\n";
   
   my @ary1=<INFILE>;                   #一维数组
   
   close(INFILE);
   
   foreach $eachline (@ary1)
   {
       chomp($eachline);
       my @tmp=split(/ /,$eachline);    #拆分每行中值，获取的值放到临时数组中
       push @ary2,[@tmp];               #将一维数组插入二维数组
   }
   
   open(SARFORMAT,">./source/sar_dp.txt") || die "\nOpen file failed:$@\n\n";
   
   for $i(0..$#ary2)
   {
       ##定义格式
       $~="SARFORMAT";
       
       
       format SARFORMAT=
       @<<<<<<<<<<     @<<<<<<<<<<     @<<<<<<<<<<
       $ary2[$i][0]  , $ary2[$i][1]  , $ary2[$i][2]
.
       write SARFORMAT;
   }
   
   close(SARFORMAT);
   
   ##清理过度文件
   unlink("./source/sar_tmp.txt");
}

sub aix_type()
{
   system("cat ./source/sar.txt | grep -v AIX | grep -v System | grep -v cpu | grep -v Average | grep -v \"\-\"| sed \'\/\^\$\/d\' | sed \'s\/时\/\:\/g\' | sed \'s\/分\/\:\/g\' | sed \'s\/秒\/\/g\'  | sed \'s\/PM\/\/g\' | sed \'s\/AM\/\/g\' | awk -F \" \" \'\{print \$1,\$2+\$3+\$4\}\' | sed \'1,1d\'> ./source/sar_dp.txt");
}


##2012-09-11 20:21 增加对sar_dp.txt文件进行处理，得到类似如下数据
##  time      all     0     1     2     3     4     5
##  10:16:01  2.56   2.15   2.64  2.15  1.16  1.45  2.16

sub dispose_sar()
{
   (-d "source") || die "\nDir source is not exist,$!\n\n";
   
   if($os_type=~ m/linux/)
   {
       #获取逻辑CPU个数
       my $logic_cpu_num=`cat /proc/cpuinfo | grep "processor" | wc -l`;
       chomp($logic_cpu_num);
       
       #print "\nlogic_cpu_num:$logic_cpu_num\n\n";
       
       system("cat ./source/sar_dp.txt | grep all | awk -F \" \" \'\{print \$1,\$3\}\' > ./source/sar_dp_all.txt");
           
       for(my $i=0;$i<$logic_cpu_num;$i++)
       {
          system("cat ./source/sar_dp.txt | awk -F \" \" \'\{if\(\$2==$i\) print \$3}' > ./source/sar_dp_each$i.txt");
       }
       
       ##文件列表
       my $each_file_list=`ls -l ./source/ | grep sar_dp_each | awk -F \" \" \'\{print \$NF\}\'`;
       chomp($each_file_list);
       my @file_list=split(/\n/,$each_file_list);
       
       #print "\n@file_list\n";
       
       #文件合并
       chdir "source";
       system("paste -d @ sar_dp_all.txt @file_list > sar_dp_split_tmp.txt");
       
       system("cat sar_dp_split_tmp.txt | sed \'s\/\@\/    \/g\' > sar_dp_split.txt");       
       chdir "$cur_path";
       
       ##增加标题
       my @cpu_num=(0 .. $logic_cpu_num-1);
       system("sed -i \'1s\/\^\/Time     all     @cpu_num\\n\/\' ./source/sar_dp_split.txt");       
       ##过渡文件清理
       unlink("./source/sar_dp_all.txt");
       unlink("./source/sar_dp_split_tmp.txt");
       system("rm -f ./source/sar_dp_each*.txt");
       
       ##add by wangyunzneg 2012-10-23 增加iowait数据信息
       system("cat ./source/sar.txt | grep all | grep -v Average | sed \'\/\^\$\/d\' | sed \'s\/时\/\:\/g\' | sed \'s\/分\/\:\/g\' | sed \'s\/秒\/\/g\'  | sed \'s\/PM\/\/g\' | sed \'s\/AM\/\/g\' | awk -F \" \" \'\{print \$1,\$6\}\' > ./source/sar_iowait.txt");
       
       #增加标题
       system("sed -i \'1s\/\^\/Time     iowait\\n\/\' ./source/sar_iowait.txt");
       ##end add by wangyunzeng 2012-10-23
   }
   else
   {
      print "\n脚本暂不支持的OS类型:$os_type\n\n";
      exit;
   }
}