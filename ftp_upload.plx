#!/usr/bin/perl
use warnings;
use strict 'vars';
use Config::IniFiles;
use Net::SCP::Expect;
use Expect;
use Sys::Hostname;
use Socket;
use Getopt::Std;;
use vars qw($opt_a $opt_s $opt_m $opt_e);

#########################################################################################
#    ###############################################################################    #
#   #      ˵����   ��run��gather�ű��ϴ��������������ϲ�ִ��                       #   #
#   #      ʹ�ã�   perl   ftp_upload.plx                                           #   #
#   #      AUTH��   wangyunzeng                                                     #   #
#   #      VER ��   1.0                                                             #   #
#   #      TIME��   2012-08-28   20:09   create                                     #   #
#    ###############################################################################    #
#########################################################################################

##����˵����Ϣ����ʾ��ʹ�÷���ǰ(2012-09-04 13:54)
$~="TOPFORMAT";
write;
format TOPFORMAT=

======================================================================

 ˵����
      1�����ű���Ҫ��ɽű��ϴ���ִ�в�����
      2�������û����룬�ж������Ƿ�������������ռ�������
      3���ű��ϴ���Զ�˷��������Զ��������Ŀ¼�������������ݵ��ռ�

======================================================================
.

##����ļ�
(-f "dircheck.plx") || die "\nFile is not exist,$!\n\n";
(-f "dispose.plx") || die "\nFile is not exist,$!\n\n";
(-f "ftp_download.plx") || die "\nFile is not exist,$!\n\n";
(-f "ftp_upload.plx") || die "\nFile is not exist,$!\n\n";
(-f "gather.sh") || die "\nFile is not exist,$!\n\n";
(-f "memused.plx") || die "\nFile is not exist,$!\n\n";
(-f "mmsg_query.plx") || die "\nFile is not exist,$!\n\n";
(-f "perform.plx") || die "\nFile is not exist,$!\n\n";
(-f "rename.plx") || die "\nFile is not exist,$!\n\n";
(-f "run.sh") || die "\nFile is not exist,$!\n\n";
(-f "sar_dp.plx") || die "\nFile is not exist,$!\n\n";
(-f "sms_statbills.plx") || die "\nFile is not exist,$!\n\n";
(-f "statbills.plx") || die "\nFile is not exist,$!\n\n";

#ʹ�÷���
getopts("asme");

if (!($opt_a || $opt_m || $opt_s|| $opt_e))
{
   print "\n��ʹ�÷�����\n";
   print "\n perl ftp_upload.plx \n \n      ѡ��:  -a  -m  -s  -e\n\n\t     -a: MMSG-����   ��ʾ��������Ϊ��������\n\n\t     -m: Mģ��       ��ʾ����ΪMģ��\n\n\t     -s: SMS-ҵ��    ��ʾ����ҵ������\n\n\t     -e: SMS-��ҵ    ��ʾ������ҵ����\n \n \n";
   exit;
}

##�������ļ���ȡ��Ϣ
my $cfg = Config::IniFiles->new( -file => "./config/config.ini" );

my $remote_path_mmsg=$cfg->val('GW_PERFROMANCE','MMSG_SCP_Path' ) || '';        #Զ�˴�Žű�·��,����ʹ��
my $remote_path_sms=$cfg->val('GW_PERFROMANCE','SMS_SCP_Path' ) || '';          #Զ�˴�Žű�·��,����ʹ��
my $remote_path_m=$cfg->val('GW_PERFROMANCE','M_SCP_Path' ) || '';              #Զ�˴�Žű�·��,Mģ��ʹ��

my $remote_user=$cfg->val('GW_PERFROMANCE','Remote_user') || '';                #��¼Զ�˷��������û�
my $remote_root_pass=$cfg->val('GW_PERFROMANCE','Remote_root_pass') || '';      #��¼Զ�˷�����root�û���Ӧk����
my $list_tmp=$cfg->val('GW_PERFROMANCE','Remote_IP') || '';                     #��ȡIP��Ϣ
my $iscluster=$cfg->val('GW_PERFROMANCE','IsCluster') || '';                    #�Ƿ��ǽ�Ⱥ����
$iscluster=lc($iscluster);                                                      #��ֹ�����ļ��������˴�д

if($iscluster eq "no" || $iscluster eq "n")
{
   print "\n�Ǽ�Ⱥ�������������������뽫�ű��ϴ����ýڵ�\n\n";
   
   if($opt_a)
   {
      print "\n[��������]��Ҫִ��������ؽű���
      
      ����1��sh run.sh              ----���������ռ�
      
      ����2��perl oneMode.plx -a    ----���������ļ�����
      
      \n";
   }
   elsif($opt_s)
   {
      print "\n[����ҵ������]��Ҫִ��������ؽű���
      
      ����1��sh run.sh              ----���������ռ�
      
      ����2��perl oneMode.plx -s    ----���������ļ�����
      
      \n";   
   }
   elsif($opt_m)
   {
      print "\n[Mģ��]��Ҫִ��������ؽű���
      
      ����1��sh run.sh              ----���������ռ�
      
      ����2��perl oneMode.plx -m    ----���������ļ�����
      
      \n";      
   }
   elsif($opt_e)
   {
      print "\n[������ҵ����]��Ҫִ��������ؽű���
      
      ����1��sh run.sh              ----���������ռ�
      
      ����2��perl oneMode.plx -e    ----���������ļ�����
      
      \n";    
   }
   
}
elsif($iscluster eq "yes" || $iscluster eq "y")
{
  ##���ӱ����Ƿ�ִ��run.sh�ű�(2012-09-04 13:47)
  print "\n�����Ƿ���Ҫִ��run.sh�������ݵ��ռ�?[yes/no]\n\n";
  chomp (my $response = <STDIN>);
  $response = lc($response);               #��Сдת��
    
  if($response eq "yes" || $response eq "y")
  {
     print "\n������ʼִ��run.sh�������������ݵ��ռ�\n\n";
     system("sh run.sh");
  }
  elsif($response eq "no" || $response eq "n")
  {
     print "\n��������ִ�����������ռ�����!\n\n";
  }
  else
  {
     print "\n��ERROR���Ƿ���[yes/no]���룬�˳�ִ��!\n\n";
     exit;
  }
  
  #��ȡ��ǰ����IP��ַ
  my $host = hostname();
  my $localip = inet_ntoa(scalar gethostbyname($host || 'localhost'));
  chomp($localip);
  
  
  sub scp_files 
  {
     my $host= shift;
     my $pass= shift;
     my $scpe = Net::SCP::Expect->new(user=>'root',password=>$pass);
     
     #Ҫ�ϴ����ļ�
     $scpe->scp("run.sh","$host:/");                                            #���ϴ�����Ŀ¼�£�Ȼ��rooty�û�mv����
     $scpe->scp("gather.sh","$host:/");
     $scpe->scp("dircheck.plx","$host:/");
     $scpe->scp("./config/config.ini","$host:/");
     $scpe->scp("memused.plx","$host:/");                                       #run.sh�ű����øýű�
  };
  
  
  ##ִ��
  sub all_hosts
  {
     my $host = shift ;
     my $pass = shift ;
     $ENV{TERM} = "vt100";
     my $exp = Expect->new;
     $exp = Expect->spawn("ssh -l root $host");
     #$exp->log_file("output.log","w");                 #������־
     $exp->log_stdout( 0 );                             #�رչ�������
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
  
     ##���ж�Զ�˴���ļ�Ŀ¼�Ƿ���ڣ�����������򴴽�
     $exp->send("cd /\n") if ($exp->expect(undef,"#"));
     if($opt_a)
     {
        $exp->send("perl dircheck.plx -a\n") if ($exp->expect(undef,"#"));
        $exp->send("mv run.sh $remote_path_mmsg\n") if ($exp->expect(undef,"#"));
        $exp->send("mv gather.sh $remote_path_mmsg\n") if ($exp->expect(undef,"#"));
        $exp->send("mv dircheck.plx $remote_path_mmsg\n") if ($exp->expect(undef,"#"));
        $exp->send("mv config.ini $remote_path_mmsg/config\n") if ($exp->expect(undef,"#"));
        $exp->send("mv memused.plx $remote_path_mmsg\n") if ($exp->expect(undef,"#"));
      
        $exp->send("chown -R $remote_user.users $remote_path_mmsg\n") if ($exp->expect(undef,"#"));
        
        ##�л���Զ�˵�¼�û�������ű����Ȩ��,��ִ��run.sh�ű��������ݵĻ�ȡ
        $exp->send("su - $remote_user\n") if ($exp->expect(undef,"#"));
        $exp->send("cd $remote_path_mmsg\n") if ($exp->expect(undef,">"));
        $exp->send("chmod 775 *\n") if ($exp->expect(undef,">"));
        $exp->send("sh run.sh\n") if ($exp->expect(undef,">"));
     }
     elsif($opt_s)
     {
        $exp->send("perl dircheck.plx -s\n") if ($exp->expect(undef,"#"));
        $exp->send("mv run.sh $remote_path_sms\n") if ($exp->expect(undef,"#"));
        $exp->send("mv gather.sh $remote_path_sms\n") if ($exp->expect(undef,"#"));
        $exp->send("mv dircheck.plx $remote_path_sms\n") if ($exp->expect(undef,"#"));
        $exp->send("mv config.ini $remote_path_sms/config\n") if ($exp->expect(undef,"#"));
        $exp->send("mv memused.plx $remote_path_sms\n") if ($exp->expect(undef,"#"));
        
        $exp->send("chown -R $remote_user.users $remote_path_sms\n") if ($exp->expect(undef,"#"));
        
        ##�л���Զ�˵�¼�û�������ű����Ȩ��,��ִ��run.sh�ű��������ݵĻ�ȡ
        $exp->send("su - $remote_user\n") if ($exp->expect(undef,"#"));
        $exp->send("cd $remote_path_sms\n") if ($exp->expect(undef,">"));
        $exp->send("chmod 775 *\n") if ($exp->expect(undef,">"));
        $exp->send("sh run.sh\n") if ($exp->expect(undef,">"));
     }
     elsif($opt_m)
     {
        $exp->send("perl dircheck.plx -m\n") if ($exp->expect(undef,"#"));
        $exp->send("mv run.sh $remote_path_m\n") if ($exp->expect(undef,"#"));
        $exp->send("mv gather.sh $remote_path_m\n") if ($exp->expect(undef,"#"));
        $exp->send("mv dircheck.plx $remote_path_m\n") if ($exp->expect(undef,"#"));
        $exp->send("mv config.ini $remote_path_m/config\n") if ($exp->expect(undef,"#"));
        $exp->send("mv memused.plx $remote_path_m\n") if ($exp->expect(undef,"#"));
        
        $exp->send("chown -R $remote_user.users $remote_path_m\n") if ($exp->expect(undef,"#"));
        
        ##�л���Զ�˵�¼�û�������ű����Ȩ��,��ִ��run.sh�ű��������ݵĻ�ȡ
        $exp->send("su - $remote_user\n") if ($exp->expect(undef,"#"));
        $exp->send("cd $remote_path_m\n") if ($exp->expect(undef,">"));
        $exp->send("chmod 775 *\n") if ($exp->expect(undef,">"));
        $exp->send("sh run.sh\n") if ($exp->expect(undef,">")); 
     }
     elsif($opt_e)
     {
        $exp->send("perl dircheck.plx -e\n") if ($exp->expect(undef,"#"));
        $exp->send("mv run.sh $remote_path_sms\n") if ($exp->expect(undef,"#"));
        $exp->send("mv gather.sh $remote_path_sms\n") if ($exp->expect(undef,"#"));
        $exp->send("mv dircheck.plx $remote_path_sms\n") if ($exp->expect(undef,"#"));
        $exp->send("mv config.ini $remote_path_sms/config\n") if ($exp->expect(undef,"#"));
        $exp->send("mv memused.plx $remote_path_sms\n") if ($exp->expect(undef,"#"));
        
        $exp->send("chown -R $remote_user.users $remote_path_sms\n") if ($exp->expect(undef,"#"));
        
        ##�л���Զ�˵�¼�û�������ű����Ȩ��,��ִ��run.sh�ű��������ݵĻ�ȡ
        $exp->send("su - $remote_user\n") if ($exp->expect(undef,"#"));
        $exp->send("cd $remote_path_sms\n") if ($exp->expect(undef,">"));
        $exp->send("chmod 775 *\n") if ($exp->expect(undef,">"));
        $exp->send("sh run.sh\n") if ($exp->expect(undef,">"));   
     }
     else
     {
        #do nothins
     }
     #�˳�����
     $exp->send("exit\n") if ($exp->expect(undef,">"));
     $exp->send("exit\n") if ($exp->expect(undef,"#"));
     $exp->log_file(undef);
  }
  
  print '-' x 60,"\n"; 
  print "\n��ʼ�ϴ��ű�������������ִ��run.sh�ű���ȡ��������.\n\n";
  
  my @list=split(/\,/,$list_tmp);
  #for my $i (@list)
  #{
  #   scp_files($i,"$remote_root_pass");
  #   all_hosts($i,"$remote_root_pass");
  #}
  
  for (my $i=0;$i<=$#list;$i++)
  {
     ##����IP��ַ�жϣ��Ƿ��Ǳ���IP������ǣ����ڱ���������س���
     #����IPd��ַ�뱾��IP��ַƥ��
     if($localip eq "$list[$i]")
     {
        print "\n$list[$i]�Ǳ���IP.\n\n";
        print "\n   �ڱ���ִ��run.sh����.\n\n";
        if($opt_a)
        {
           system("sh run.sh");
           print "\n����������ɡ�\n\n";
        }
        elsif($opt_s)
        {
           system("sh run.sh");
           print "\n����������ɡ�\n\n";
        }
        elsif($opt_m)
        {
           system("sh run.sh");
           print "\n����������ɡ�\n\n";
        }
        elsif($opt_e)
        {
           system("sh run.sh");
           print "\n����������ɡ�\n\n";
        }
        else
        {
           #do nothing
        }
     }
     else
     {
        print "\n   ��IP��ַΪ:$list[$i] ��Զ�˷������ϴ��ű���ִ��\n\n";
        scp_files($list[$i],"$remote_root_pass");
        all_hosts($list[$i],"$remote_root_pass");
        print "\n   IP��ַΪ:$list[$i] ��Զ�˷�����������˽ű��ϴ���ִ�в���.\n";   
     }
  }
  
  print "\n���������ڵ��ϴ��ű���ִ�в���.\n\n";
  print '-' x 60,"\n\n";   
}
else
{
   print "\n��Error�������ļ���IsClusterȡֵ��yes��no�����������ļ�!\n\n";
   exit;
}