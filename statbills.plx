#! /usr/bin/perl

(-d "$ENV{MMS_HOME}/cdr/stat") || die "Directory $ENV{MMS_HOME}/cdr/stat not exist.\n";
chdir "$ENV{MMS_HOME}/cdr/stat";

#####���ò���#########################

#�Ƿ���OT�����������ԣ������ǰת�����轫Դ��Ŀ��MMSG�Ļ������е�һ����
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

#####���ò���#########################
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
my %Stat = ("0100"  => "SPӦ���ύ��ý����Ϣ�ɹ�" ,
            "0400"  => "��������ת�����ŵ����سɹ�" ,
            "1000"  => "Retrieved" ,
            "1100"  => "���շ�SPӦ�ý��ն�ý����Ϣ�ɹ�",
            "2000"  => "Recipient Rejected",
            "4100"  => "�ն˷��͵�Ӧ��ʧ��" ,
            "4300"  => "����ת��MMSC�Ѿ��ɹ�����Ч����δ�յ�״̬����",
            "4400"  => "MT�����·�����ʧ��",
            "4414"  => "Rejected",
            "4448"  => "Expired",
            "6000"  => "��MM1�ӿڲ������ͷ���Ȩʧ��",
            "6001"  => "��MM1�ӿڲ������շ���Ȩʧ��",
            "6003"  => "����MM1�ӿڲ���MMSCϵͳ�ܾ�����",
            "6005"  => "��MM1�ӿڲ�����Ϣ�ֶ����÷Ƿ����ؼ��ֶ�û�����",
            "6010"  => "��MM1�ӿڲ�����ϵͳ�����������µľܾ�" ,
            "6012"  => "�����û�Ⱥ����������ϵͳ���ôӶ�����ʧ��" ,
            "6100"  => "����MM7�ӿڲ������ͷ���Ȩʧ��",
            "6101"  => "��MM7�ӿڲ������շ���Ȩʧ��" ,
            "6103"  => "����MM7�ӿڲ���MMSCϵͳ�ܾ�����" ,
            "6104"  => "����MM7�ӿڲ���MMSCϵͳ�ܾ�����" ,
            "6110"  => "��MM7�ӿڣ����շ�Ϊϵͳ�������û�" ,
            "6112"  => "����SPȺ����������ϵͳ���ôӶ�����ʧ��",
            "6150"  => "MT��Ϣת��MMSCʧ��",
            );
####################################
#begin added by zhengyin begin

my %BNumMap = ();
#���������б��������к�����շ�����Ķ�Ԫ��
my %OBNum_MSISDN = ();
my %TBNum_MSISDN = ();
#������б�����MSGID���������кŵ�ǰ21λ����R1��R2����Ԫ��
my %MsgID_R1R2 = ();
my $tmpR1 = 0;
my $tmpR2 = 0;
#��ʱ����
my $tmpStr1 = "";
my $tmpStr2 = "";
my $tmpInt1 = 0;
my $tmpInt2 = 0;

my @BNumLost = ();
my $CfOBills = 0;
my $CfTBills = 0;
my $QsOBills = 0;
my $QsTBills = 0;

#MMSGͳ��R1 R2
my $R1MOSum = 0;
my $R2ATSum = 0;
my $R1AOSum = 0;
my $R2MTSum = 0;

my %cdrtypemap = (0 => "MO����",1 => "EO����",2 => "AO����",3 => "MT����",4 => "ET����",5 => "AT����");
my %feeusertype = (0 => "�󸶷��û�",1 => "�������û�",9 => "SP�û�");
my %flowtype = (0 => "MOMT",1 => "EOMT",2 => "MOET",3 => "AOMT",4 => "MOAT");
my %feetype =(0 => "���",1 => "����",2 => "���¿۷�",3 => "���²�ѯ");
my %beartype =(0 => "CSD��ʽ",1 => "GPRS��ʽ",2 => "IP��ʽ",3 => "����");
my %msgtype =(1 => "Personal",2 => "Advertisement",3 => "Informational",4 => "Auto",5 => "other");
my %msgpri =(0 => "��",1 => "��",2 => "��");
my %DRreq =(0 => "�޵��ͱ�����Ķ���������",1 => "������ͱ���",2 => "�����Ķ�����",3 => "������ͱ�����Ķ�����");
my %TerminalType =(0 => "��MMS�ն�",1 => "MMS�ն�",2 => "δ֪�ն�");

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

#���OT����������
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
