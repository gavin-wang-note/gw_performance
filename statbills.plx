#! /usr/bin/perl

(-d "$ENV{MMS_HOME}/cdr/stat") || die "Directory $ENV{MMS_HOME}/cdr/stat not exist.\n";
chdir "$ENV{MMS_HOME}/cdr/stat";

#####配置参数#########################

#是否检查OT话单的完整性，如果是前转流程需将源和目的MMSG的话单集中到一起检查
my $IsChkOT = 1;
$time_diff = 0;
if($ARGV[0] == "")
{
    $time_diff = 172800;
 }
 else
{ 
    $time_diff = $ARGV[0];
}

#####配置参数#########################
#####bak/date   and buffer###########
my $today=`date +%Y%m%d` ;
chomp($today);
my $CurDir="$ENV{MMS_HOME}/cdr/stat/bak/$today";
opendir(DIR, "$CurDir") || die "Open directory $CurDir error,$!\n";
#opendir(DIR, "$ENV{MMS_HOME}/cdr/stat/send") || die "Open directory error.\n";
@ARGV = grep {/^\d+\.\d{4}$/o && ($_ = "bak/$today/$_")} readdir(DIR);
closedir(DIR);

opendir(DIR, "$ENV{MMS_HOME}/cdr/stat/buffer") || die "Open directory error,$!\n";
my @DIRS = grep {/^\d+\.\d{4}$/o && ($_ = "buffer/$_")} readdir(DIR);
closedir(DIR);

unshift @ARGV, @DIRS;
die "No stat file found.\n" if (@ARGV == 0);

my $Fee = 0;
my $Count = 0;
my (@AppType, @AppBill, @AppBillStatus, @BillType, @BillStatus);
my @AppT = ("MOMT", "EOMT", "MOET", "AOMT", "MOAT");
my @BillT = ("MO", "EO", "AO", "MT", "ET", "AT");
my %Stat = ("0100"  => "SP应用提交多媒体消息成功" ,
            "0400"  => "彩信中心转发彩信到网关成功" ,
            "1000"  => "Retrieved" ,
            "1100"  => "接收方SP应用接收多媒体消息成功",
            "2000"  => "Recipient Rejected",
            "4100"  => "终端发送到应用失败" ,
            "4300"  => "彩信转发MMSC已经成功，有效期内未收到状态报告",
            "4400"  => "MT由于下发流控失败",
            "4414"  => "Rejected",
            "4448"  => "Expired",
            "6000"  => "在MM1接口产生发送方鉴权失败",
            "6001"  => "在MM1接口产生接收方鉴权失败",
            "6003"  => "因在MM1接口产生MMSC系统拒绝服务",
            "6005"  => "在MM1接口产生消息字段设置非法、关键字段没有填充",
            "6010"  => "在MM1接口产生因系统黑名单而导致的拒绝" ,
            "6012"  => "由于用户群发个数超过系统设置从而导致失败" ,
            "6100"  => "因在MM7接口产生发送方鉴权失败",
            "6101"  => "在MM7接口产生接收方鉴权失败" ,
            "6103"  => "因在MM7接口产生MMSC系统拒绝服务" ,
            "6104"  => "因在MM7接口产生MMSC系统拒绝服务" ,
            "6110"  => "在MM7接口，接收方为系统黑名单用户" ,
            "6112"  => "由于SP群发个数超过系统设置从而导致失败",
            "6150"  => "MT消息转发MMSC失败",
            );
####################################
#begin added by zhengyin begin

my %BNumMap = ();
#下面两个列表，保存序列号与接收方号码的二元组
my %OBNum_MSISDN = ();
my %TBNum_MSISDN = ();
#下面的列表，保存MSGID（话单序列号的前21位）与R1、R2的三元组
my %MsgID_R1R2 = ();
my $tmpR1 = 0;
my $tmpR2 = 0;
#临时变量
my $tmpStr1 = "";
my $tmpStr2 = "";
my $tmpInt1 = 0;
my $tmpInt2 = 0;

my @BNumLost = ();
my $CfOBills = 0;
my $CfTBills = 0;
my $QsOBills = 0;
my $QsTBills = 0;

#MMSG统计R1 R2
my $R1MOSum = 0;
my $R2ATSum = 0;
my $R1AOSum = 0;
my $R2MTSum = 0;

my %cdrtypemap = (0 => "MO话单",1 => "EO话单",2 => "AO话单",3 => "MT话单",4 => "ET话单",5 => "AT话单");
my %feeusertype = (0 => "后付费用户",1 => "神州行用户",9 => "SP用户");
my %flowtype = (0 => "MOMT",1 => "EOMT",2 => "MOET",3 => "AOMT",4 => "MOAT");
my %feetype =(0 => "免费",1 => "按条",2 => "包月扣费",3 => "包月查询");
my %beartype =(0 => "CSD方式",1 => "GPRS方式",2 => "IP方式",3 => "其他");
my %msgtype =(1 => "Personal",2 => "Advertisement",3 => "Informational",4 => "Auto",5 => "other");
my %msgpri =(0 => "低",1 => "中",2 => "高");
my %DRreq =(0 => "无递送报告和阅读报告请求",1 => "请求递送报告",2 => "请求阅读报告",3 => "请求递送报告和阅读报告");
my %TerminalType =(0 => "非MMS终端",1 => "MMS终端",2 => "未知终端");

my $AOtotal=0;
my $MTsucc=0;
my $MOtotal=0;
my $ATsucc=0;
for (my $i=0; $i<@AppType; ++$i)
{
    next unless ($AppType[$i]);
    print "\n$AppT[$i] Bill: $AppType[$i]\n";


    for (my $j=0; $j<@{$AppBill[$i]}; ++$j)
    {
        next unless ($AppBill[$i][$j]);
        print "    $BillT[$j] Bill: $AppBill[$i][$j]\n";
        if ($BillT[$j] eq "AO")
        {
            $AOtotal=$AppBill[$i][$j];
    	   
        }
        elsif($BillT[$j] eq "MO")
        {
            $MOtotal=$AppBill[$i][$j];
        }
        foreach $k (sort keys %{$AppBillStatus[$i][$j]})
        {
            my $Result = sprintf "Status $k Bill: $AppBillStatus[$i][$j]{$k}(%.2f%%)",
                                  $AppBillStatus[$i][$j]{$k}/$AppBill[$i][$j]*100;
            printf "        %-40s $Stat{$k}\n", $Result;
        }
        if ($BillT[$j] eq "MT")
        {
            $MTsucc=$AppBillStatus[$i][$j]{1000};         
        }
        elsif($BillT[$j] eq "AT")
        {
            $ATsucc=$AppBillStatus[$i][$j]{1100};
        }
    }
    print "\n";
   if($AppT[$i] eq "AOMT")
   {
     my $SuccPercent = printf "AOMT SUCCESS PERCENT: (%.2f%%)\n",$MTsucc/$AOtotal*100;
     print $SuccPercent;
   }
   elsif($AppT[$i] eq "MOAT")
   {
     my $SuccPercent = printf "MOAT SUCCESS PERCENT: (%.2f%%)\n",$ATsucc/$MOtotal*100;
     print $SuccPercent;
   }
}

        
#for (my $i=0; $i<@BillType; ++$i)
#{
#    next unless ($BillType[$i]);
#    print "\nTotal $BillT[$i]: $BillType[$i]\n";

 #   foreach $k (sort(keys %{$BillStatus[$i]}))
 #   {
 #       my $Result = sprintf "Status $k Bill: $BillStatus[$i]{$k}(%.2f%%)",
 #                             $BillStatus[$i]{$k}*100/$BillType[$i];
 #       printf "    %-44s $Stat{$k}\n", $Result;
 #   }
#}

print " MO R1 SUM: $R1MOSum\n";
print " AT R2 SUM: $R2ATSum\n";
print " AO R1 SUM: $R1AOSum\n";
print " MT R2 SUM: $R2MTSum\n";

while(($MsgID, $R1R2) = each(%MsgID_R1R2)) {
    my @R1_R2 = split (/,/, $R1R2);
    if ($R1_R2[0] != $R1_R2[1])
    {
    	#print "$MsgID  ";
    	#print $R1_R2[0];
    	
    	#print " ";
    	#print $R1_R2[1];
    	#print "\n";
    }
}

#检查OT话单完整性
if( $IsChkOT == 1 )
{
#        foreach( sort keys %BNumMap )
#        {
#            $serial_num = substr( $_, 0, 25 );
#            $type = substr( $_, 25, 1 );
#
#            if( $type == "O" )
#            {
#                if( exists $BNumMap{$serial_num . "T"} )
#                {
#                }
#                else
#                {
#                    ++$QsTBills;
#                    print "$_ no T Bill\n";
#                }
#            }

#          if( $type == "T" )
#            {
#                if( exists $BNumMap{$serial_num . "O"} )
#                {
#                }
#                else
#                {
#                    ++$QsOBills;
#                    print "$_ no O Bill\n";
#                }
#            }
#        }
        
        foreach ( keys %TBNum_MSISDN )
        {
        	push(@BNumLost, $_) unless exists $TBNum_MSISDN{$_};
        	#print "\nLeak O Bills: $_" unless exists $OBNum_MSISDN{$_};
        }
        foreach ( keys %OBNum_MSISDN )
        {
        	push(@BNumLost, $_) unless exists $TBNum_MSISDN{$_};
        	#print "\nLeak T Bills: $_" unless exists $TBNum_MSISDN{$_};
        }
        print "\n";	

#    print "\nLeak O Bills: $QsOBills \n";
#    print "Leak T Bills: $QsTBills \n";

}
