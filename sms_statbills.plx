#!/usr/bin/perl
#use warnings;
use strict 'vars';
use Cwd;
use Config::IniFiles;

#########################################################################################
#    ###############################################################################    #
#   #      ˵����   ���Ʒѽڵ����ͳ�ƻ���ͳ�ƴ���60/62/63�����ķ���              #   #
#   #               �ɹ���(16�ֶ�)���Լ�������ֲ���65��������״̬�ɹ���(20�ֶ�)��  #   #
#   #               �Լ�״̬�ֲ�                                                    #   #
#   #      ʹ�ã�   perl   sms_statbills.plx                                        #   #
#   #      AUTH��   wangyunzeng                                                     #   #
#   #      VER ��   1.0                                                             #   #
#   #      TIME��   2012-08-30   17:52   create                                     #   #
#    ###############################################################################    #
#########################################################################################


##����ȫ�ֱ���
my $Count = 0;
my (@BillType, @BillStatus, @AppBillStatus);
my @BillT = ("60", "62","63","65");
$BillT[60] = "60";
$BillT[62] = "62";
$BillT[63] = "63";
$BillT[65] = "65";

my $cur_path=getcwd;          #��ǰ·��



##����·��
###-------Begin-----��������Ҫ�󣬻���·���̶��������ȡ�����ļ���·����ע��ԭ�ӻ��������л�ȡ����l·��---------------
#my $today=`date +%Y-%m-%d`;
#chomp($today);

#my $CurDir="$ENV{INFOX_ROOT}/bin/smppbillstore/$today";
###-------End-----

####Begin add ---------------
##�������ļ���ȡ��Ϣ
my $cfg = Config::IniFiles->new( -file => "./config/config.ini" );
my $CurDir=$cfg->val('GW_PERFROMANCE','SMS_SMPP_PATH' ) || '';                  #�Ʒѽڵ���SMPP����·��,����ʹ��
####End add -----------------

opendir(DIR, "$CurDir") || die "Open directory $CurDir error,$!\n";
@ARGV = grep {"/^d+"} readdir(DIR);        #ƥ��.ǰһ����������
closedir(DIR);
#unshift @ARGV;
die "No SMPP bill files found.\n" if (@ARGV == 0);

print "\n��ʼ����SMPP�����ļ�\n\n";
print '-' x 60,"\n";

#�ļ����·��
unless (-d "source")
{
    mkdir("source", 0755) || die "Make directory source error.\n";
}


##����$CurDirĿ¼�µ������ļ�
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
print "\n���SMPP��������\n\n";

