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
#   #      ˵����   ���Ʒѽڵ����ͳ�ƻ���ͳ�ƴ���                                  #   #
#   #               ������O����ÿ�뻰������ ���Լ���������                          #   #
#   #      ʹ�ã�   perl   dispose.plx                                              #   #
#   #      AUTH��   wangyunzeng                                                     #   #
#   #      VER ��   1.0                                                             #   #
#   #      TIME��   2012-08-27   10:18   create                                     #   #
#    ###############################################################################    #
#########################################################################################

#ʹ�÷��� 
getopts("amse");
if (!($opt_a || $opt_m || $opt_s|| $opt_e))
{
   print "\n��ʹ�÷�����\n";
   print "\n perl perform.plx \n \n      ѡ��:  -a  -m  -s  -e\n\n\t     -a: MMSG-����   ��ʾ��������Ϊ��������\n\n\t     -m: Mģ��       ��ʾ����ΪMģ��\n\n\t     -s: SMS-ҵ��    ��ʾ����ҵ������\n\n\t     -e: SMS-��ҵ    ��ʾ������ҵ����\n \n \n";
   exit;
}


##ȫ�ֱ���
my $cur_path=getcwd;                #��ȡ��ǰ·��

#��ȡ��ǰ����IP��ַ
my $host = hostname();
my $address = inet_ntoa(scalar gethostbyname($host || 'localhost'));
chomp($address);

#����ϵͳ����
my $Os_type=$^O;

#�������ļ���ȡ��Ϣ
my $cfg = Config::IniFiles->new( -file => "./config/config.ini" );

##����ʹ��    
my $BILL_IP = $cfg->val('GW_PERFROMANCE', 'Bill_IP') || '';                     #�Ʒѽڵ�IP��ַ
my $MMSG_Stat_path = $cfg->val('GW_PERFROMANCE', 'MMSG_Stat_path') || '';       #�Ʒѽڵ�ͳ�ƻ���·��
my $BILL_User=$cfg->val('GW_PERFROMANCE', 'BILL_User') || '';                   #�Ʒѽڵ��¼�û���
my $BILL_Pss=$cfg->val('GW_PERFROMANCE', 'BILL_Pss') || '';                     #�Ʒѽڵ��¼�û�����Ӧ�Ŀ���

my $BILL_Root_Pass=$cfg->val('GW_PERFROMANCE', 'BILL_Root_Pass') || '';         #root�û���Ӧ����
    
my $BILL_Pass=$cfg->val('GW_PERFROMANCE', 'BILL_Pass') || '';                   #�Ʒѽڵ��¼�û�����Ӧ�Ŀ���
my $MMSG_SCP_File=$cfg->val('GW_PERFROMANCE', 'MMSG_SCP_File') || '';           #����Ҫ�ϴ���ͳ�ƻ���ͳ�ƽű�
my $MMSG_SCP_Path=$cfg->val('GW_PERFROMANCE', 'MMSG_SCP_Path') || '';           #������ͳ�ƽű����·��

##����ʹ��
my $smpp_ip = $cfg->val('GW_PERFROMANCE', 'SMS_BILL_IP') || '';                 #SMPP�������ڽڵ�IP��ַ
my $smpp_user=$cfg->val('GW_PERFROMANCE', 'SMS_BILL_User') || '';               #��SMPP��������ͳ�Ʋ������û�
my $smpp_user_pass=$cfg->val('GW_PERFROMANCE', 'SMS_BILL_User_pass') || '';     #��SMPP��������ͳ�Ʋ������û���Ӧ�Ŀ���
my $sms_smpp_path=$cfg->val('GW_PERFROMANCE','SMS_SMPP_PATH') || '';            #SMPP����·��
my $smpp_root_pass=$cfg->val('GW_PERFROMANCE', 'SMS_BILL_ROOT_Pass') || '';     #�Ʒѽڵ��¼�û�����Ӧ�Ŀ���
my $sms_scp_file=$cfg->val('GW_PERFROMANCE', 'SMS_SCP_FILE') || '';             #����Ҫ�ϴ���ͳ�ƻ���ͳ�ƽű�
my $sms_scp_path=$cfg->val('GW_PERFROMANCE', 'SMS_SCP_Path') || '';             #������ͳ�ƽű����·��


##��ȡ·�������Ŀ¼��ʱ��Ŀ¼��
#������
my @path=split(/\//,$MMSG_Stat_path);
my $leth=scalar(@path);
my $path_day=$path[$leth-1];
chomp($path_day);

#������
my $path_day_sms=`cat ./config/config.ini | grep SMS_SMPP_PATH | awk -F \"\/\" \'\{print \$NF\}\' | sed \'s\/\\\-\/\\\/\/g\'`;
chomp($path_day_sms);

##�����smpp�����ļ������ڸ�ʽ��2011/09/03��ֱ�Ӵ��ݻ����awk���⣬��������ڷ�Ϊ3���������ݣ���ϳ�������
my @year_mon_day=split(/\//,"$path_day_sms");
my $year=shift(@year_mon_day);
my $month=shift(@year_mon_day);
my $day=shift(@year_mon_day);

#�ļ����·��
unless (-d "source")
{
   mkdir("source", 0755) || die "Make directory source error.\n";
}


if($opt_a)
{
   #print "\nѡ���˲�������.\n\n";
   &mmsg_dispose;
   &mmsg_statbill;           #��ftp������MMSG��ͳ�ƻ�������ļ����ж��δ����õ� mmsg_statbills.txt �ļ�
}
elsif($opt_s)
{
   #print "\nѡ���˶���ҵ����������.\n\n";
   &sms_dispose;
}
elsif($opt_e)
{
   #print "\nѡ���˶�����ҵ����.\n\n";
   &sms_dispose;
}
elsif($opt_m)
{
   #print "\nѡ����Mģ��.\n\n";
}
else
{
   print "\n����Ƿ�����ο�����ġ�ʹ�÷�����\n\n";
   exit;
}


sub mmsg_dispose()
{
   ##����������ļ��л�ȡ��IP�ͱ���IPһ�£�˵����ǰ�ǼƷѽڵ㣬���贫��ű����ڱ���ֱ��ִ�нű�����ͳ�ƽű��ȿ�
   if($address eq $BILL_IP)
   {
       ##�ж�·���Ƿ����(Ҫ���ڼƷѽڵ�����жϣ�����ǼƷѽڵ�澯����·��������)
       (-d "$MMSG_Stat_path") || die "\nDir $MMSG_Stat_path is not exist!Pease check config.ini file.\n\n";
       
       #print '-' x 60,"\n";
       print "\n��MMSGͳ�ƻ������д���.\n\n";
       print "\n  ��ǰ���ǼƷѽڵ�.\n\n";
       print "\n  ��ʼִ�� [statbills.plx] �ű���ͳ��MMSGͳ�ƻ���......\n\n";
       system("perl statbills.plx > ./source/mmsg_stat_result.txt");              #�õ�ͳ�ƻ���ͳ�ƽ��
       
       print "\n  ����ͳ�ƻ���ÿ����������ٶ�......\n\n";
       chdir "$MMSG_Stat_path";
       system("awk -F\, \'\{if\(\$8==2 \&\& substr\(\$25,1,8\)==$path_day\)\{print \$25\",\"\$5\}\}\' * > $cur_path/source/AO.txt");
       system("awk -F\',\' \'\{a\[\$1\]++\}END\{for\(i in a\)printf\"\%s,\%d\\n\",i,a\[i\]\}\' $cur_path/source/AO.txt | sort > $cur_path/source/mmsg_speed.txt");
       
       #����ԭ·��
       chdir "$cur_path";
       unlink("./source/AO.txt");
       print "\n";
       print '-' x 60,"\n";    
   }
   else
   {
       #print '-' x 60,"\n";
       print "\n��MMSGͳ�ƻ������д���.\n\n";
       
       print "\n��������ʾ��\n";
       print "\n   ��ǰ�ڵ㲻�ǼƷѽڵ㣬�ýű��Ὣͳ�ƽű��ϴ����Ʒѽڵ㣬\n\n   �����л���ͳ�ƣ�ͳ����ɺ󽫽����ȡ������sourceĿ¼�¡�\n\n";
       sleep 1;  ##��ͣһ�£������Ķ���ʾ��Ϣ
       
       ##�Ʒѽڵ�ִ�л���tͳ�ƽű���ftp�ļ�������
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
   #$exp->log_file("output.log","w");  #������־
   $exp->log_stdout( 0 );              #���ζ������
   
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


   print "\n   ��ʼִ�� [statbills.plx] �ű���ͳ��MMSGͳ�ƻ���......\n\n";
   
   $exp->send("cd /home/$BILL_User/perl\n") if ($exp->expect(undef,"#"));
   $exp->send("chown -R $BILL_User.users statbills.plx \n") if ($exp->expect(undef,"#"));
   $exp->send("su - $BILL_User\n") if ($exp->expect(undef,"#"));
   $exp->send("cd ./perl\n") if ($exp->expect(undef,">"));  
   $exp->send("perl statbills.plx > mmsg_stat_result.txt\n") if ($exp->expect(undef,">"));
   #$exp->send("rm statbills.plx\n") if ($exp->expect(undef,">"));
   
   ##����ÿ������ٶ�
   print "\n   ����ͳ�ƻ���ÿ����������ٶ�......\n\n";

   $exp->send("cd $MMSG_Stat_path\n") if ($exp->expect(undef,">"));
   $exp->send("awk -F\, \'\{if\(\$8==2 \&\& substr\(\$25,1,8\)==$path_day\)\{print \$25\",\"\$5\}\}\' * > /home/$BILL_User/AO.txt\n") if ($exp->expect(undef,">"));
   $exp->send("awk -F\',\' \'\{a\[\$1\]++\}END\{for\(i in a\)printf\"\%s,\%d\\n\",i,a\[i\]\}\' /home/$BILL_User/AO.txt | sort > /home/$BILL_User/mmsg_speed.txt\n") if ($exp->expect(undef,">"));
   $exp->send("rm /home/$BILL_User/AO.txt\n") if ($exp->expect(undef,">"));
   $exp->send("exit\n") if ($exp->expect(undef,">"));
   
   $exp->send("exit\n") if ($exp->expect(undef,">"));
   $exp->send("exit\n") if ($exp->expect(undef,"#"));
   $exp->log_file(undef);
   print "\n   ������ͳ�Ʋ���.\n";
   


   print "\n   ��ʼ�ӼƷѽڵ��ȡ������ļ�.\n\n";
   $ftp = Expect->spawn( "ftp $BILL_IP" ) or die "Could not connect to $BILL_IP us ftp, $!"; 
   $ftp->log_stdout( 0 );   # ���ζ������
                 
   # �ȴ��û���������ʾ
   unless ( $ftp->expect(10, -re=>qr/name \(.*?\):\s*$/i) ) 
   { 
     die "   FTP��$BILL_IP���û�δ����FTP�û���, ".$ftp->error( )."\n"; 
   } 
 
   #�����û���
   $ftp->send( "$BILL_User\r" ); 
   #sleep 2;
   
    # �ȴ�����������ʾ
   unless ( $ftp->expect( 10, -re=>qr/password:\s*$/i ) ) 
   { 
      die "   FTP��$BILL_IP���û�δ����FTP�û�����Ӧ������, ".$ftp->error( )."\n"; 
   } 
   
   #��������
   $ftp->send( "$BILL_Pss\r" ); 

    # �ȴ� ftp ��������ʾ
    unless ( $ftp->expect(30,"ftp>") ) 
    { 
       die "   Never got ftp prompt after sending username, ".$ftp->error( )."\n"; 
    } 
 
 
    # �����ļ�
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

   
    # �Ͽ� ftp ����
    print "\n   FTP�ļ��������Ͽ�FTP���� ... \n"; 
    $ftp->send( "bye\r" ); 
    $ftp->soft_close( ); 
    if(-f "mmsg_speed.txt" and -f "mmsg_stat_result.txt")
    {
        system("mv mmsg_speed.txt ./source/mmsg_speed.txt");
        system("mv mmsg_stat_result.txt ./source/mmsg_stat_result.txt");
        print "\n   ���š�mmsg_speed.txt/mmsg_stat_result.txt���ļ��ɹ���ȡ��sourceĿ¼��.\n\n";
    }
    else
    {
         print "\n   ���š�mmsg_speed.txt/mmsg_stat_result.txt���ļ���ȡʧ�ܣ�����ԭ��.\n\n";
         exit;
    }
}

#��MMSGͳ�ƻ����������ļ����ж��δ����ϲ��� mmsg_statbills.txt �ļ�

sub mmsg_statbill()
{
   print "\n\nͳ�ƻ����ɹ���ͳ�ƽ������:\n\n";
   
   my $AOMT_BILL_NUMS=`cat ./source/mmsg_stat_result.txt | grep "AOMT Bill" | sed s\'\/ \/\/g\' | awk -F ":" '{print \$2}'`;   #AOMT��������
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
   
   print "\n����������£�\n";
   print "\n    AO���������ǣ�        $AO_BILL_NUMS  (��)  \n";
   print "\n    MT���������ǣ�        $MT_BILL_NUMS  (��)  \n";
   print "\n    AOMT���������ǣ�       $AOMT_BILL_NUMS  (��)  \n";
   print "\n    AO�����ɹ����ǣ�       $AO_SUCC_PERCENT  \n";
   print "\n    MT�����ɹ����ǣ�       $MT_SUCC_PERCENT  \n";
   print "\n    AOMT�����ɹ����ǣ�     $AOMT_SUCC_PERCENT  \n";
   
   if($AOMT_BILL_NUMS gt $AO_MT_NUMS)
   {
      print "\n    AOMT�������� [$AOMT_BILL_NUMS] ���� AO+MT [$AO_MT_NUMS] ��������.\n\n";
   }
   elsif($AOMT_BILL_NUMS eq $AO_MT_NUMS)
   {
      print "\n    AOMT�������� [$AOMT_BILL_NUMS] ���� AO+MT [$AO_MT_NUMS] ��������.\n\n";
   }
   else
   {
      print "\n    AOMT�������� [$AOMT_BILL_NUMS] С�� AO+MT [$AO_MT_NUMS] ��������.\n\n";
   }
   
   #print '-' x 60,"\n";

   
   #ͳ�ƽ��д���ļ�
   $~="MMSG_STAT";
   open(MMSG_STAT,">./source/mmsg_statbill.txt") || die "Out file mmsg_statbill.txt:$!\n";  
   format MMSG_STAT=
  
��������������£�

====================================================================================================================================
   
   AO��������(��)          MT��������(��)         AOMT��������(��)         AO�����ɹ���        MT�����ɹ���       AOMT�����ɹ���
   @<<<<<<<<<<             @<<<<<<<<<<            @<<<<<<<<<<              @<<<<<<<<<<         @<<<<<<<<<<        @<<<<<<<<<<
   $AO_BILL_NUMS      ,    $MT_BILL_NUMS     ,    $AOMT_BILL_NUMS     ,    $AO_SUCC_PERCENT  , $MT_SUCC_PERCENT  ,$AOMT_SUCC_PERCENT
   
   AOMT��������(��)        AO��0100��+MT��1000����������(��)
   @<<<<<<<<<<             @<<<<<<<<<<    
   $AOMT_BILL_NUMS    ,    $AO_MT_NUMS
   
====================================================================================================================================

.
   write MMSG_STAT;
   close(MMSG_STAT);

   #�ļ��ϲ�
   system("cat ./source/mmsg_stat_result.txt ./source/mmsg_statbill.txt > ./source/mmsg_statbills.txt");
   
   ##��������ļ�
   unlink("./source/mmsg_stat_result.txt");
   unlink("./source/mmsg_statbill.txt");
}

##SMS
sub sms_dispose()
{
  if($address eq $smpp_ip)
     {
         ##�ж�·���Ƿ����(Ҫ���ڼƷѽڵ�����жϣ�����ǼƷѽڵ�澯����·��������)
         (-d "$sms_smpp_path") || die "\nDir $sms_smpp_path is not exist!Pease check config.ini file.\n\n";
         
         print '-' x 60,"\n";
         print "\n�Զ���SMPP�������д���.\n\n";
         print "\n  ��ǰ���ǼƷѽڵ�.\n\n";
         print "\n  ��ʼִ�� [sms_statbills.plx] �ű���ͳ��SMPP����......\n\n";
         system("perl sms_statbills.plx");                #�õ�ͳ�ƻ���ͳ�ƽ��
         
         print "\n  ����SMPP����ÿ����������ٶ�......\n\n";
         chdir "$sms_smpp_path";
         system("awk -F\, \'\{if\(\$2==60 \&\& substr\(\$11,1,10\)==$year\/$month\/$day\)\{print \$11\",\"\$46\}\}\' \* > $cur_path/source/AO.txt\n");
         system("awk -F\',\' \'\{a\[\$1\]++\}END\{for\(i in a\)printf\"\%s,\%d\\n\",i,a\[i\]\}\' $cur_path/source/AO.txt | sort > $cur_path/source/smpp_speed.txt\n");


         #����ԭ·��
         chdir "$cur_path";
         unlink("./source/AO.txt");
         print "\n";
         print '-' x 60,"\n";
     }
     else
     {
        print '-' x 60,"\n";
        print "\n�Զ���SMPP�������д���.\n\n";
        
        print "\n��������ʾ��\n";
        print "\n   ��ǰ�ڵ㲻�ǼƷѽڵ㣬�ýű��Ὣͳ�ƽű��ϴ����Ʒѽڵ㣬\n\n   �����л���ͳ�ƣ�ͳ����ɺ󽫽����ȡ������sourceĿ¼�¡�\n\n";
        sleep 1;  ##��ͣһ�£������Ķ���ʾ��Ϣ
        
        ##�Ʒѽڵ�ִ�л���tͳ�ƽű���ftp�ļ�������
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
   #$exp->log_file("output.log","w");  #������־
   $exp->log_stdout( 0 );              #���ζ������
   #$exp->exp_internal(1);             #ƥ�����
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
   

   print "\n   ��ʼִ�� [sms_statbills.plx] �ű���ͳ�ƶ���SMPPͳ�ƻ���......\n\n";
   
   $exp->send("cd /home/$smpp_user/perl\n") if ($exp->expect(undef,"#"));
   $exp->send("chown -R $smpp_user.users sms_statbills.plx \n") if ($exp->expect(undef,"#"));
   $exp->send("su - $smpp_user\n") if ($exp->expect(undef,"#"));
   $exp->send("cd ./perl\n") if ($exp->expect(undef,">"));                      ##ע�⣬����ط��Ѿ�����perlĿ¼��
   $exp->send("perl sms_statbills.plx\n") if ($exp->expect(undef,">"));
   #$exp->send("rm sms_statbills.plx\n") if ($exp->expect(undef,">"));
   
   ##����ÿ������ٶ�
   print "\n   ����SMPP����ÿ����������ٶ�......\n\n";

   $exp->send("cd $sms_smpp_path\n") if ($exp->expect(undef,">"));
   $exp->send("awk -F\, \'\{if\(\$2==60 \&\& substr\(\$11,1,10\)==\"$year\/$month\/$day\"\)\{print \$11\",\"\$46\}\}\' \* > /home/$smpp_user/perl/AO.txt\n") if ($exp->expect(undef,">"));
   $exp->send("awk -F\',\' \'\{a\[\$1\]++\}END\{for\(i in a\)printf\"\%s,\%d\\n\",i,a\[i\]\}\' /home/$smpp_user/perl/AO.txt | sort > /home/$smpp_user/perl/smpp_speed.txt\n") if ($exp->expect(undef,">"));
   $exp->send("rm /home/$smpp_user/perl/AO.txt\n") if ($exp->expect(undef,">"));
   $exp->send("exit\n") if ($exp->expect(undef,">"));

   $exp->send("exit\n") if ($exp->expect(undef,">"));
   $exp->send("exit\n") if ($exp->expect(undef,"#"));
   $exp->log_file(undef);
   print "\n   ������SMPP����ͳ�Ʋ���.\n";
   
   
   print "\n   ��ʼ�ӼƷѽڵ��ȡ������ļ�.\n\n";
   $ftp = Expect->spawn( "ftp $smpp_ip" ) or die "Could not connect to $smpp_ip us ftp, $!"; 
   $ftp->log_stdout( 0 );   # ���ζ������
                 
   # �ȴ��û���������ʾ
   unless ( $ftp->expect(10, -re=>qr/name \(.*?\):\s*$/i) ) 
   { 
     die "   FTP��$smpp_ip���û�δ����FTP�û���, ".$ftp->error( )."\n"; 
   } 
 
   #�����û���
   $ftp->send( "$smpp_user\r" ); 
   #sleep 2;
   
    # �ȴ�����������ʾ
   unless ( $ftp->expect( 10, -re=>qr/password:\s*$/i ) ) 
   { 
      die "   FTP��$smpp_ip���û�δ����FTP�û�����Ӧ������, ".$ftp->error( )."\n"; 
   } 
   
   #��������
   $ftp->send( "$smpp_user_pass\r" ); 

    # �ȴ� ftp ��������ʾ
    unless ( $ftp->expect(30,"ftp>") ) 
    { 
       die "   Never got ftp prompt after sending username, ".$ftp->error( )."\n"; 
    } 
 
 
    # �����ļ�
    $ftp->send( "cd /home/$smpp_user/perl\r" ); 
    $ftp->send( "get ./source/smpp_result.txt\r" );
    unless ( $ftp->expect( 30,"ftp> " ) ) 
    { 
       die "   ��ȡsmpp_result.txt�ļ�ʱ��δ���յ�ftp����ʾ����Ϣ, ".$ftp->error( )."\n"; 
    }

    #$ftp->send( "cd source\r" ); 
    $ftp->send( "get ./smpp_speed.txt\r" ); 
    unless ( $ftp->expect( 30,"ftp> " ) ) 
    { 
       die "   ��ȡsmpp_speed.txt�ļ�ʱ��δ���յ�ftp����ʾ����Ϣ, ".$ftp->error( )."\n"; 
    }     
   
    # �Ͽ� ftp ����
    print "\n   FTP�ļ��������Ͽ�FTP���� ... \n"; 
    $ftp->send( "bye\r" ); 
    $ftp->soft_close( );
   
   
    #ftp���������ƶ�λ��
    if(-f "smpp_speed.txt")
    {
        #system("mv smpp_result.txt ./source/smpp_result.txt");
        system("mv smpp_speed.txt ./source/smpp_speed.txt");
        
        print "\n   ���š�smpp_speed.txt���ļ��ɹ���ȡ��sourceĿ¼��.\n\n";
    }
    else
    {
         print "\n   ���š�smpp_speed.txt���ļ���ȡʧ�ܣ�����ԭ��.\n\n";
         exit;
    }
}