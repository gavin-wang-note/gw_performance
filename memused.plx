#!/usr/bin/perl
use warnings;
use strict 'vars';
use Getopt::Std;
use vars qw($opt_s $opt_d $opt_f);

#########################################################################################
#    ###############################################################################    #
#   #      说明：   获取操作系统内存使用情况                                        #   #
#   #               内存使用：1-($MemFree+$Inactive)/$MemTotal                      #   #
#   #      使用：   perl   memused.plx                                              #   #
#   #      AUTH：   wangyunzeng                                                     #   #
#   #      VER ：   1.0                                                             #   #
#   #      TIME：   2012-08-25   15:16   create                                     #   #
#    ###############################################################################    #
#########################################################################################


#使用方法
getopts("s:d:f");

if(!(($opt_s)|| ($opt_d) || ($opt_f)))
{
    print "\n【使用方法】\n\n";
    print "\nperl memused.plx  -s 5  -d 720 -f\n \n      选项: -s   -d   -f\n\n\t    -s: 时间间隔 [带参数] 示例中为5m秒\n\n\t    -d: 收集c次数 [带参数]\n \n\t    -f: 收集的数据写入到的文件名称 [不带参数]\n\n";
    print "\n      【说明】内存使用：1-(MemFree+Inactive)/MemTotal \n\n";
    exit;
}
else
{
    ##操作系统类型
    my $os_type=$^O;
    
    my $count=$opt_s*$opt_d;
    my $opt_f="./source/memused.txt";
    unlink("./source/$opt_f");
    
    ##不同操作系统类型
    if($os_type=~m/linux/)
    {
        for(my $i=0;$i<$count;$i++)
        {
           ##定义时间(直接使用linux，不使用自定义的，提高性能)
           my $daytime=`date +'%Y%m%d %H:%M:%S'`;
           chomp($daytime);
        
           my $MemTotal=`cat /proc/meminfo | grep MemTotal | awk -F \" \" \'\{print \$2\}\'`;
           my $MemFree=`cat /proc/meminfo | grep MemFree | awk -F \" \" \'\{print \$2\}\'`;
           my $Inactive=`cat /proc/meminfo | grep Inactive | awk -F \" \" \'\{print \$2\}\'`;
        
           chomp($MemTotal);
           chomp($MemFree);
           chomp($Inactive);
        
           my $used_mem=sprintf("%2.2f",(1-($MemFree+$Inactive)/$MemTotal)*100);
        
           open(FILE,">>$opt_f") || die "\nOpen file $opt_f failed:$!\n\n";
           print FILE "$daytime    $used_mem\n";
        
           sleep $opt_s;
           
        }
       close(FILE);
    }
    elsif($os_type=~m/aix/)
    {
        #for(my $i=0;$i<$count;$i++)
        #{
           ##定义时间(直接使用linux，不使用自定义的，提高性能)
           #my $daytime=`date +'%Y%m%d %H:%M:%S'`;
           #chomp($daytime);
        
           #my $MemTotal=`cat /proc/meminfo | grep MemTotal | awk -F \" \" \'\{print \$2\}\'`;
           #my $MemFree=`cat /proc/meminfo | grep MemFree | awk -F \" \" \'\{print \$2\}\'`;
           #my $Inactive=`cat /proc/meminfo | grep Inactive | awk -F \" \" \'\{print \$2\}\'`;
           #
           #chomp($MemTotal);
           #chomp($MemFree);
           #chomp($Inactive);
           #
           #my $used_mem=sprintf("%2.2f",(1-($MemFree+$Inactive)/$MemTotal)*100);
           #
           #open(FILE,">>$opt_f") || die "\nOpen file $opt_f failed:$!\n\n";
           #print FILE "$daytime    $used_mem\n";
           #
           #sleep $opt_s;
           
        #}
       #close(FILE);
       print "\n【不支持】AIX不支持通过 1-(MemFree+Inactive)/MemTotal 计算内存使用率\n";
       print "\nAIX平台下暂时不做.\n\n";
    }
    elsif($os_type=~m/sunos/)
    {
       print "\n【不支持】SUN平台不支持通过 1-(MemFree+Inactive)/MemTotal 计算内存使用率\n";
       print "\nSUN平台下暂时不做.\n\n";
    }

}