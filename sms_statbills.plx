#!/usr/bin/perl
#use warnings;
use strict 'vars';
use Cwd;
use Config::IniFiles;

#########################################################################################
#    ###############################################################################    #
#   #      说明：   到计费节点进行统计话单统计处理，60/62/63话单的发送              #   #
#   #               成功率(16字段)，以及错误码分布；65话单最终状态成功率(20字段)，  #   #
#   #               以及状态分布                                                    #   #
#   #      使用：   perl   sms_statbills.plx                                        #   #
#   #      AUTH：   wangyunzeng                                                     #   #
#   #      VER ：   1.0                                                             #   #
#   #      TIME：   2012-08-30   17:52   create                                     #   #
#    ###############################################################################    #
#########################################################################################


##定义全局变量
my $Count = 0;
my (@BillType, @BillStatus, @AppBillStatus);
my @BillT = ("60", "62","63","65");
$BillT[60] = "60";
$BillT[62] = "62";
$BillT[63] = "63";
$BillT[65] = "65";

my $cur_path=getcwd;          #当前路径



##话单路径
###-------Begin-----按照李寅要求，话单路径固定，这里读取配置文件中路径，注释原从环境变量中获取话单l路径---------------
#my $today=`date +%Y-%m-%d`;
#chomp($today);

#my $CurDir="$ENV{INFOX_ROOT}/bin/smppbillstore/$today";
###-------End-----

####Begin add ---------------
##从配置文件读取信息
my $cfg = Config::IniFiles->new( -file => "./config/config.ini" );
my $CurDir=$cfg->val('GW_PERFROMANCE','SMS_SMPP_PATH' ) || '';                  #计费节点存放SMPP话单路径,短信使用
####End add -----------------

opendir(DIR, "$CurDir") || die "Open directory $CurDir error,$!\n";
@ARGV = grep {"/^d+"} readdir(DIR);        #匹配.前一个或多个数字
closedir(DIR);
#unshift @ARGV;
die "No SMPP bill files found.\n" if (@ARGV == 0);

print "\n开始分析SMPP话单文件\n\n";
print '-' x 60,"\n";

#文件存放路径
unless (-d "source")
{
    mkdir("source", 0755) || die "Make directory source error.\n";
}


##遍历$CurDir目录下的所有文件
chdir "$CurDir";
while (<>)
{
    my $nf = split /,/;
    ++$Count;
    ++$BillType[$_[1]]; 
    ++$BillStatus[$_[1]]{$_[15]};
}

open(SMPPSTAT,">$cur_path/source/smpp_result.txt") || die "\nOpen file failed,$!\n\n";
print SMPPSTAT  "   Total SMPP Bills: $Count\n"; 

for (my $i=0; $i<@BillType; ++$i)
{
    next unless ($BillType[$i]);
    print SMPPSTAT "\n   Total $BillT[$i]: $BillType[$i]\n"; 
    foreach my $k (sort(keys %{@BillStatus[$i]}))
    {
        my $Result = sprintf "   Status $k Bill: $BillStatus[$i]{$k}(%.2f%%)",
                                 $BillStatus[$i]{$k}*100/$BillType[$i];
        printf SMPPSTAT "    %-44s \n", $Result;
    }
}
print "\n";

close SMPPSTAT;
system("cat $cur_path/source/smpp_result.txt");

print '-' x 60,"\n";
print "\n完成SMPP话单分析\n\n";

