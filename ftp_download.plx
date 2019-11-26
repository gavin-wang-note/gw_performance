#!/usr/bin/perl
use warnings;
use strict 'vars';
use Config::IniFiles;
use Net::SCP::Expect;
use Sys::Hostname;
use Socket;
use Expect;
use Getopt::Std;;
use vars qw($opt_a $opt_s $opt_m $opt_e);

#########################################################################################
#    ###############################################################################    #
#   #      ˵����   ��perform.plx�ű��ϴ���ִ�в���ȡ���ĵ�����                     #   #
#   #      ʹ�ã�   perl   ftp_download.plx                                         #   #
#   #      AUTH��   wangyunzeng                                                     #   #
#   #      VER ��   1.0                                                             #   #
#   #      TIME��   2012-08-29   13:59   create                                     #   #
#    ###############################################################################    #
#########################################################################################

#ʹ�÷���
getopts("asme");

if (!($opt_a || $opt_m || $opt_s|| $opt_e))
{
   print "\n��ʹ�÷�����\n";
   print "\n perl ftp_download.plx  \n \n      ѡ��:  -a  -m  -s  -e\n\n\t     -a: MMSG-����   ��ʾ��������Ϊ��������\n\n\t     -m: Mģ��       ��ʾ����ΪMģ��\n\n\t     -s: SMS-ҵ��    ��ʾ����ҵ������\n\n\t     -e: SMS-��ҵ    ��ʾ������ҵ����\n \n \n";
   exit;
}

##����˵����Ϣ����ʾ��ʹ�÷���ǰ(2012-09-04 14:03)
$~="TOPFORMAT";
write;
format TOPFORMAT=

======================================================================

 ˵����
      1�����ű���Ҫ��ɸ��Ӳ�Ʒ��Ҫ����ؽű��ϴ���ִ�в�����
      2���ű���Զ�˷�����ִ�к���IP��ַ����������ļ���
      3�����txt�ļ�������ȡ������sourceĿ¼��

======================================================================
.

##�������ļ���ȡ��Ϣ
my $cfg = Config::IniFiles->new( -file => "./config/config.ini" );
my $list_tmp=$cfg->val('GW_PERFROMANCE','Remote_IP') || '';                     #��ȡԶ�˷�������IP��Ϣ
#my $remote_path=$cfg->val('GW_PERFROMANCE','Remote_path' ) || '';               #Զ�˴�Žű�·��

my $remote_path_mmsg=$cfg->val('GW_PERFROMANCE','MMSG_SCP_Path' ) || '';        #Զ�˴�Žű�·��,����ʹ��
my $remote_path_sms=$cfg->val('GW_PERFROMANCE','SMS_SCP_Path' ) || '';          #Զ�˴�Žű�·��,����ʹ��
my $remote_path_m=$cfg->val('GW_PERFROMANCE','M_SCP_Path') || '';               #Mģ��Զ�˴�Žű���·��

my $remote_user=$cfg->val('GW_PERFROMANCE','Remote_user') || '';                #��¼Զ�˷��������û�
my $remote_user_pass=$cfg->val('GW_PERFROMANCE','Remote_user_pass') || '';      #��¼Զ�˷��������û���Ӧ�Ŀ���
my $remote_root_pass=$cfg->val('GW_PERFROMANCE','Remote_root_pass') || '';      #��¼Զ�˷�����root�û���Ӧk����

#my $sms_bill_ip=$cfg->val('GW_PERFROMANCE','SMS_BILL_IP') || '';                #����SMPP�������ڷ�����
my $sms_bill_user=$cfg->val('GW_PERFROMANCE','SMS_BILL_User' ) || '';           #����ͳ��SMPP�������û�
#my $sms_bill_root_pass=$cfg->val('GW_PERFROMANCE','SMS_BILL_ROOT_Pass') || '';  #��¼SMPP�������ڷ�������root�û�����


#��ȡ��ǰ����IP��ַ
my $host = hostname();
my $localip = inet_ntoa(scalar gethostbyname($host || 'localhost'));
chomp($localip);



##���ӱ����Ƿ�ִ��run.sh�ű�(2012-09-04 14:09)
print "\n�����Ƿ���Ҫִ����ؽű��������ݵĶ��δ���?[yes/no]\n\n";
chomp (my $response = <STDIN>);
$response = lc($response);               #��Сдת��
  
if($response eq "yes" || $response eq "y")
{
   ##����Ӳ�Ʒ���½ű����ӣ����������Ҫ����ִ�в���
   print "\n������ʼ�����������ݵĶ��δ���\n\n";
   if($opt_a)
   {
      system("perl perform.plx -a");
      system("perl sar_dp.plx");
      system("perl mmsg_query.plx");
      system("perl osinfo.plx");
      system("perl rename.plx -a");
   }
   elsif($opt_s)
   {
      system("perl perform.plx -s");
      system("perl sar_dp.plx");
      system("perl osinfo.plx");
      system("perl rename.plx -s");
   }
   elsif($opt_e)
   {
      system("perl perform.plx -e");
      system("perl sar_dp.plx");
      system("perl osinfo.plx");
      system("perl rename.plx -e");
   }
   elsif($opt_m)
   {
      system("perl perform.plx -m");
      system("perl sar_dp.plx");
      system("perl osinfo.plx");
      system("perl rename.plx -m");
   }
}
elsif($response eq "no" || $response eq "n")
{
   print "\n��������ִ���������ݵĶ��δ���!\n\n";
}
else
{
   print "\n��ERROR���Ƿ���[yes/no]���룬�˳�ִ��!\n\n";
   exit;
}


sub scp_files 
{
   my $host= shift;
   my $pass= shift;
   my $scpe = Net::SCP::Expect->new(user=>'root',password=>$pass);
   
   #Ҫ�ϴ����ļ�
   $scpe->scp("perform.plx","$host:/");                                         #���ϴ�����Ŀ¼�£�Ȼ��root�û�mv����
   $scpe->scp("dispose.plx","$host:/");
   $scpe->scp("rename.plx","$host:/");
   $scpe->scp("sar_dp.plx","$host:/");                                          #��sar.txt�ļ����ж��δ���
   $scpe->scp("osinfo.plx","$host:/");                                          #�鿴OSӲ��������Ϣ
   
   #��Բ�Ʒ���ͣ��ϴ�������Ҫ�������ű�����������
   if($opt_a)
   {
      $scpe->scp("mmsg_query.plx","$host:/");
   }
   elsif($opt_s)
   {
      #$scpe->scp("sms_statbills.plx","$host:/");   
   }
   elsif($opt_m)
   {
      #$scpe->scp("mmsg_query.plx","$host:/");   
   }
   elsif($opt_e)
   {
      #$scpe->scp("sms_statbills.plx","$host:/");   
   }
}


##ִ��
sub all_hosts
{
   my $host = shift ;
   my $pass = shift ;
   $ENV{TERM} = "vt100";
   my $exp = Expect->new;
   $exp = Expect->spawn("ssh -l root $host");
   #$exp->log_file("output.log","w");                  #������־
   $exp->log_stdout( 0 );                              #�رչ�������
   #$exp->log_stdout( 1 );
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

   #����$opt����
   if($opt_a)
   {
      ##��perform.plx �� rename.plx �ű�mv��perlĿ¼��
      $exp->send("cd /\n") if ($exp->expect(undef,"#"));
      
      $exp->send("chown -R $remote_user.users perform.plx\n") if ($exp->expect(undef,"#"));
      $exp->send("chown -R $remote_user.users rename.plx\n") if ($exp->expect(undef,"#"));
      $exp->send("chown -R $remote_user.users mmsg_query.plx\n") if ($exp->expect(undef,"#"));
      $exp->send("chown -R $remote_user.users dispose.plx\n") if ($exp->expect(undef,"#"));
      $exp->send("chown -R $remote_user.users sar_dp.plx\n") if ($exp->expect(undef,"#"));
      $exp->send("chown -R $remote_user.users osinfo.plx\n") if ($exp->expect(undef,"#"));
      
      $exp->send("mv perform.plx $remote_path_mmsg\n") if ($exp->expect(undef,"#"));
      $exp->send("mv dispose.plx $remote_path_mmsg\n") if ($exp->expect(undef,"#"));
      $exp->send("mv rename.plx $remote_path_mmsg\n") if ($exp->expect(undef,"#"));
      $exp->send("mv mmsg_query.plx $remote_path_mmsg\n") if ($exp->expect(undef,"#"));
      $exp->send("mv sar_dp.plx $remote_path_mmsg\n") if ($exp->expect(undef,"#"));
      $exp->send("mv osinfo.plx $remote_path_mmsg\n") if ($exp->expect(undef,"#"));
   
   
      ##�л���Զ�˵�¼�û�������ű����Ȩ��,��ִ��run.sh�ű��������ݵĻ�ȡ
      $exp->send("su - $remote_user\n") if ($exp->expect(undef,"#"));
      $exp->send("cd $remote_path_mmsg\n") if ($exp->expect(undef,">"));
   
      $exp->send("perl perform.plx -a\n") if ($exp->expect(undef,">"));
      $exp->send("perl sar_dp.plx\n") if ($exp->expect(undef,">"));
      $exp->send("perl mmsg_query.plx -a\n") if ($exp->expect(undef,">"));
      $exp->send("perl osinfo.plx\n") if ($exp->expect(undef,">"));
      $exp->send("perl rename.plx -a\n") if ($exp->expect(undef,">"));
   }
   elsif($opt_s)
   {
      ##��perform.plx �� rename.plx �ű�mv��perlĿ¼��
      $exp->send("cd /\n") if ($exp->expect(undef,"#"));
      
      $exp->send("chown -R $remote_user.users perform.plx\n") if ($exp->expect(undef,"#"));
      $exp->send("chown -R $remote_user.users rename.plx\n") if ($exp->expect(undef,"#"));
      $exp->send("chown -R $remote_user.users dispose.plx\n") if ($exp->expect(undef,"#"));
      $exp->send("chown -R $remote_user.users sar_dp.plx\n") if ($exp->expect(undef,"#"));
      $exp->send("chown -R $remote_user.users osinfo.plx\n") if ($exp->expect(undef,"#"));
      
      $exp->send("mv perform.plx $remote_path_sms\n") if ($exp->expect(undef,"#"));
      $exp->send("mv rename.plx $remote_path_sms\n") if ($exp->expect(undef,"#"));
      $exp->send("mv dispose.plx $remote_path_sms\n") if ($exp->expect(undef,"#"));
      $exp->send("mv sar_dp.plx $remote_path_sms\n") if ($exp->expect(undef,"#"));
      $exp->send("mv osinfo.plx $remote_path_sms\n") if ($exp->expect(undef,"#"));
   
   
      ##�л���Զ�˵�¼�û�������ű����Ȩ��,��ִ��run.sh�ű��������ݵĻ�ȡ
      $exp->send("su - $remote_user\n") if ($exp->expect(undef,"#"));
      $exp->send("cd $remote_path_sms\n") if ($exp->expect(undef,">"));
      
      $exp->send("perl perform.plx -s\n") if ($exp->expect(undef,">"));
      $exp->send("perl sar_dp.plx\n") if ($exp->expect(undef,">"));
      $exp->send("perl osinfo.plx\n") if ($exp->expect(undef,">"));
      $exp->send("perl rename.plx -s\n") if ($exp->expect(undef,">"));
   }
   elsif($opt_m)
   {
      ###��perform.plx �� rename.plx �ű�mv��perlĿ¼��
      $exp->send("cd /\n") if ($exp->expect(undef,"#"));
      
      $exp->send("chown -R $remote_user.users perform.plx\n") if ($exp->expect(undef,"#"));
      $exp->send("chown -R $remote_user.users rename.plx\n") if ($exp->expect(undef,"#"));
      $exp->send("chown -R $remote_user.users sar_dp.plx\n") if ($exp->expect(undef,"#"));
      $exp->send("chown -R $remote_user.users osinfo.plx\n") if ($exp->expect(undef,"#"));
      
      $exp->send("mv perform.plx $remote_path_m\n") if ($exp->expect(undef,"#"));
      $exp->send("mv rename.plx $remote_path_m\n") if ($exp->expect(undef,"#"));
      $exp->send("mv sar_dp.plx $remote_path_m\n") if ($exp->expect(undef,"#"));
      $exp->send("mv osinfo.plx $remote_path_m\n") if ($exp->expect(undef,"#"));
      
      
      ###�л���Զ�˵�¼�û�������ű����Ȩ��,��ִ��run.sh�ű��������ݵĻ�ȡ
      $exp->send("su - $remote_user\n") if ($exp->expect(undef,"#"));
      $exp->send("cd $remote_path_m\n") if ($exp->expect(undef,">"));
      
      $exp->send("perl perform.plx -m\n") if ($exp->expect(undef,">"));
      $exp->send("perl sar_dp.plx\n") if ($exp->expect(undef,">"));
      $exp->send("perl osinfo.plx\n") if ($exp->expect(undef,">"));
      $exp->send("perl rename.plx -m\n") if ($exp->expect(undef,">"));
   }
   elsif($opt_e)
   {
      ##��perform.plx �� rename.plx �ű�mv��perlĿ¼��
      $exp->send("cd /\n") if ($exp->expect(undef,"#"));
      
      $exp->send("chown -R $remote_user.users perform.plx\n") if ($exp->expect(undef,"#"));
      $exp->send("chown -R $remote_user.users rename.plx\n") if ($exp->expect(undef,"#"));
      $exp->send("chown -R $remote_user.users dispose.plx\n") if ($exp->expect(undef,"#"));
      $exp->send("chown -R $remote_user.users sar_dp.plx\n") if ($exp->expect(undef,"#"));
      $exp->send("chown -R $remote_user.users osinfo.plx\n") if ($exp->expect(undef,"#"));
      
      $exp->send("mv perform.plx $remote_path_sms\n") if ($exp->expect(undef,"#"));
      $exp->send("mv rename.plx $remote_path_sms\n") if ($exp->expect(undef,"#"));
      $exp->send("mv dispose.plx $remote_path_sms\n") if ($exp->expect(undef,"#"));
      $exp->send("mv sar_dp.plx $remote_path_sms\n") if ($exp->expect(undef,"#"));
      $exp->send("mv osinfo.plx $remote_path_sms\n") if ($exp->expect(undef,"#"));
   
   
      ##�л���Զ�˵�¼�û�������ű����Ȩ��,��ִ��run.sh�ű��������ݵĻ�ȡ
      $exp->send("su - $remote_user\n") if ($exp->expect(undef,"#"));
      $exp->send("cd $remote_path_sms\n") if ($exp->expect(undef,">"));
      
      $exp->send("perl perform.plx -e\n") if ($exp->expect(undef,">"));
      $exp->send("perl sar_dp.plx\n") if ($exp->expect(undef,">"));
      $exp->send("perl osinfo.plx\n") if ($exp->expect(undef,">"));
      $exp->send("perl rename.plx -e\n") if ($exp->expect(undef,">"));
   }

   $exp->send("exit\n") if ($exp->expect(undef,">"));
   $exp->send("exit\n") if ($exp->expect(undef,"#"));
   $exp->log_file(undef);
}

#print '-' x 60,"\n";

#�Ի������д���(�������ĸ��ڵ����У��Կ���)
if($opt_a)
{
   system("perl dispose.plx -a");
}
elsif($opt_s)
{
   system("perl dispose.plx -s");
}
elsif($opt_m)
{
   system("perl dispose.plx -m");
}
elsif($opt_e)
{
   system("perl dispose.plx -e");
}
   
#ִ��perform.plx�ű�
print '-' x 60 ,"\n";
print "\n��ʼ�ϴ��ű�[perform.plx]������������ִ��perform.plx�ű����������ݽ��д���.\n\n";

my @list=split(/\,/,$list_tmp);   #��ȡIP�б�
for (my $i=0;$i<=$#list;$i++)
{
   #����IP��ַ�뱾��IP��ַƥ��
   if($localip eq "$list[$i]")
   {
      print "\n$list[$i]�Ǳ���IP.\n\n";
      print "\n   ��ʼ�Ա���������ݽ��ж��δ���.\n\n";
      if($opt_a)
      {
         system("perl perform.plx -a");
         system("perl sar_dp.plx");
         system("perl mmsg_query.plx");
         system("perl osinfo.plx");
         system("perl rename.plx -a");
         print "\n����������ɡ�\n\n";
      }
      elsif($opt_s)
      {
         system("perl perform.plx -s");
         system("perl sar_dp.plx");
         system("perl osinfo.plx");
         system("perl rename.plx -s");
         print "\n����������ɡ�\n\n";
      }
      elsif($opt_m)
      {
         system("perl perform.plx -m");
         system("perl sar_dp.plx");
         system("perl osinfo.plx");
         system("perl rename.plx -m");
         print "\n����������ɡ�\n\n";
      }
      elsif($opt_e)
      {
         system("perl perform.plx -e");
         system("perl sar_dp.plx");
         system("perl osinfo.plx");
         system("perl rename.plx -e");
         print "\n����������ɡ�\n\n";
      }
   }
   else
   {
         print "\n��ʼ����$list[$i]���ڵ��������.\n\n";
         scp_files($list[$i],"$remote_root_pass");
         all_hosts($list[$i],"$remote_root_pass");
         print "\n   IP��ַΪ:$list[$i] ��Զ�˷������������perform.plx��ؽű��ϴ���ִ�в���.\n\n";
         
         
         print "\n   ��ʼ��IP��ַΪ[$list[$i]]�Ľڵ��ȡ������ļ�������sourceĿ¼��.\n\n";
         my $ftp = Expect->spawn( "ftp $list[$i]" ) or die "Could not connect to $list[$i] us ftp, $!"; 
	     $ftp->log_stdout(0);       # ���ζ������
         #$ftp->log_stdout(1);    
       	 
         # �ȴ��û���������ʾ
         unless ( $ftp->expect(10, -re=>qr/name \(.*?\):\s*$/i) ) 
         { 
           die "   FTP��$list[$i]���û�δ����FTP�û���, ".$ftp->error( )."\n"; 
         } 
       
         #�����û���
         $ftp->send( "$remote_user\r" ); 
         
          #�ȴ�����������ʾ
         unless ( $ftp->expect( 10, -re=>qr/password:\s*$/i ) ) 
         { 
            die "   FTP��$list[$i]���û�δ����FTP�û�����Ӧ������, ".$ftp->error( )."\n"; 
         } 
         
         #��������
         $ftp->send( "$remote_user_pass\r" ); 
      
          # �ȴ� ftp ��������ʾ
          unless ( $ftp->expect(30,"ftp>") ) 
          { 
             die "   �����û�������δ�õ�password prompt��Ϣ, ".$ftp->error( )."\n"; 
          } 
       
       
         # �����ļ�
         ##���Ӳ��������ж�
         if($opt_a)
         {
            $ftp->expect(1); 
	        $ftp->send( "cd $remote_path_mmsg/source\r" );
	        $ftp->expect(1);
            $ftp->send( "asc\r" );
            $ftp->expect(1);
            $ftp->send( "mget *.txt\r" );    
         }
         elsif($opt_s)
         {
            $ftp->expect(1);
            $ftp->send( "cd $remote_path_sms/source\r" );
            $ftp->expect(1);
            $ftp->send( "asc\r" );
            $ftp->expect(1);
            $ftp->send( "mget *.txt\r" );    
         }
         elsif($opt_m)
         {
            $ftp->expect(1);
            $ftp->send( "cd $remote_path_m/source\r" );
            $ftp->expect(1);
            $ftp->send( "asc\r" );
            $ftp->expect(1);
            $ftp->send( "mget *.txt\r" );    
         }
         elsif($opt_e)
         {
            $ftp->expect(1);
            $ftp->send( "cd $remote_path_sms/source\r" );
            $ftp->expect(1);
            $ftp->send( "asc\r" );
            $ftp->expect(1);
            $ftp->send( "mget *.txt\r" );     
         }

         unless ( $ftp->expect( 30,"mget " ) ) 
         { 
            die "   ����txt�ļ�ʱ����δ���յ�ftp prompt, ".$ftp->error( )."\n"; 
         }
         
         $ftp->expect(1);
         $ftp->send( "A\r" );
      
        
         # �Ͽ� ftp ����
         print "\n   FTP�ļ��������Ͽ�FTP���� ... \n"; 
         $ftp->send( "bye\r" ); 
         $ftp->soft_close( );
         
         #sleep 3;  #���ӳ�3s�ɣ���ֹftp��ʱ
         
         #�ж�FTP�ļ����(��ڵ�������ȷ�����޷��ж��ļ������ļ��ǰ�IP�������ж��ļ�����)
         if($opt_a)  ##�����ļ��ж�
         {  
            my $file_count=`ls -l  \*.txt | wc -l`;
            chomp($file_count);
            if($file_count >= 7)
            {
                #�ƶ��ļ���sourceĿ¼��
                system("mv *.txt ./source/");
                print "\n   ������A���ļ��ɹ���ȡ������sourceĿ¼��.\n\n";
            }
            else
            {
                 print "\n   ������A���ļ���ȡʧ�ܣ�����ԭ��(�����������ftp��ʱ�������������).\n\n";
                 system("rm -rf *10.*");
                 exit;
            }
         }
         elsif($opt_s)  ##����ҵ���ж�
         {
            my $file_count=`ls -l  *.txt | wc -l`;
            chomp($file_count);
            if($file_count >= 5)
            {
                #�ƶ��ļ���sourceĿ¼��
                system("mv *.txt ./source/");
                print "\n   ������A-ҵ���ļ��ɹ���ȡ������sourceĿ¼��.\n\n";
            }
            else
            {
                 print "\n   ������A-ҵ���ļ���ȡʧ�ܣ�����ԭ��(�����������ftp��ʱ�������������).\n\n";
                 system("rm -rf *10.*");
                 exit;
            }   
         }
         elsif($opt_m)  #Mģ���ж�
         {
            my $file_count=`ls -l  *.txt | wc -l`;
            chomp($file_count);
            if($file_count >= 5)
            {
                #�ƶ��ļ���sourceĿ¼��
                system("mv *.txt ./source/");
                print "\n   ��Mģ�顿�ļ��ɹ���ȡ������sourceĿ¼��.\n\n";
            }
            else
            {
                 print "\n   ��Mģ�顿�ļ���ȡʧ�ܣ�����ԭ��(�����������ftp��ʱ�������������).\n\n";
                 system("rm -rf *10.*");
                 exit;
            }    
         }
         elsif($opt_e)  ##������ҵ�ж�  
         {
            my $file_count=`ls -l  *.txt | wc -l`;
            chomp($file_count);
            if($file_count >= 5)
            {
                #�ƶ��ļ���sourceĿ¼��
                system("mv *.txt ./source/");
                print "\n   ������A-��ҵ���ļ��ɹ���ȡ������sourceĿ¼��.\n\n";
            }
            else
            {
               print "\n   ������A-��ҵ���ļ���ȡʧ�ܣ�����ԭ��(�����������ftp��ʱ�������������).\n\n";
               system("rm -rf *10.*");
               exit;
            }   
         }

      }
   }
      print "\n����˷Ǳ����ġ����������ڵ�Ľű��ϴ���ִ�����ļ���ȡ����,��ȡ���ļ�����ڱ���
sourceĿ¼�£���IP��ַ��������������.\n\n";

print '-' x 60,"\n\n";

$~="DESC";
write;
format DESC=

˵��:
      ��������FTP�ļ�ȫ���ɹ��󣬲�������yes��y��
      
      ����������no��n.

------------------------------------------------------------
.

print "\n�Ƿ���ļ����кϲ�����?[yes/no]\n\n";
chomp (my $res = <STDIN>);
$res = lc($res);                                                      #��Сдת��

if($res eq "yes" || $res eq "y")
{
   system("perl unite.plx");
   
   #add by wangyunzeng 2012-10-30 ����tarѹ��������
   system("perl tar.plx");
}
elsif($res eq "no" || $res eq "n" || $res eq "" || $res eq "\n"|| $res eq "\r")                 #���ӿա����л�س�����Ϊ����Ƿ�
{
   print "\n�������ļ��ĺϲ�����.\n\n";
   exit;
}
else
{
   print "\n[ERROR]����ֵ��yes��no���˳�.\n\n";
   exit;
}
