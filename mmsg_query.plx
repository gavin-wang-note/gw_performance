#!/usr/bin/perl
use warnings;
use strict 'vars';

#########################################################################################
#    ###############################################################################    #
#   #      ˵����   ��MMSG��server sys��־������Ϣ����                              #   #
#   #                                                                               #   #
#   #      ʹ�ã�   perl   masg_query.plx                                           #   #
#   #      AUTH��   wangyunzeng                                                     #   #
#   #      VER ��   1.0                                                             #   #
#   #      TIME��   2012-08-25   10:05   create                                     #   #
#    ###############################################################################    #
#########################################################################################

##����ȫ�ֱ���
my $line;
my @fields=();

my $manager_file="./source/mmsg_query.txt";
my $modid_file="./source/mmsg.info";
system("mms status \>./source/mmsg.info");
my $MANAGER=$ARGV[0];

##�ж�mmsg.info�ļ���С
my @args = stat ($modid_file);
my $size = $args[7];
chomp($size);

if($size eq 0)
{
   print "\n��Error��mmsg.info�ļ���СΪ�գ���ȷ�ϵ�ǰ�û��ܷ�ִ��[mms status]����\n\n";
   unlink("./source/mmsg.info");
   exit;
}
else
{
   #server module ID  ��  server manager��
   my $server_id=`cat ./source/mmsg.info | grep MMSServer | awk -F \" \" \'\{print substr\(\$2,2\,2\)\}\' | sed \'s\/\\\/\/\/\'`;
   my $manager_id=`mms list SrvServiceManagerAmount | grep SrvServiceManagerAmount | awk -F \"=\" \'\{print substr\(\$2,3,1\)\}\'`;

   chomp($server_id);
   chomp($manager_id);
   
   #print "\nserver_id: $server_id\n";
   #print "\n$manager_id\n";
   
   #�����ļ�����ֹ�����Ŀ¼�жϺ����Ŀ¼�����ڣ�����mmsg.info�ļ������ڣ�������
   unlink("./source/mmsg.info");
   
   #�ж�·��
   my $dir="$ENV{MMS_HOME}/log/server_$server_id/sys";
   (-d "$dir") || die "\nĿ¼[$dir]�����ڣ����ܵ�ǰ�ڵ㲻��ҵ��ڵ�\n\n";

   print '-' x 60,"\n";
   print "\n��ȡMMSG��server sys��־��mmanager ������Ϣ......\n\n";

   #��ȡԭ��query��Ϣ���ļ�
   system("cat $dir/* | grep \"Message Queue Length in Server Srv_Manager\" > ./source/mmsg_query_first.txt");
   system("cat ./source/mmsg_query_first.txt | sed \'s\/\\[/\/g\' | sed \'s\/\\]\/ \/g\' | sed \'s/Message Queue Length in Server Srv_Manager\/\/g\' | sed \'s\/\:\/ \/g\' | sed \'s\/,\/ \/g\' | sed \'s\/QueueCurrentSize\/\/g\' | sed \'s\/QueueAvaliableSize\/\/g\' | awk -F \" \" \'\{print \$6,\$7,\$8,\$9,\$10\}\' > ./source/mmsg_query_second.txt");
   
   #��ȡʱ��
   system("cat ./source/mmsg_query_first.txt | sed \'s\/\\[\/\/g\' | awk -F \" \" \'\{print \$1,\$2\}\' > ./source/time_tmp.txt");
   
   #�ļ��ϲ�
   open(FILE1,"./source/time_tmp.txt");
   my @content1 = <FILE1>;
   chomp(@content1);
   close FILE1;

   open(FILE2,"./source/mmsg_query_second.txt");
   my @content2 = <FILE2>;
   chomp(@content2);
   close FILE2;

   my $len1 = scalar(@content1);
   my $len2 = scalar(@content2);
   my $num = $len1 > $len2 ? $len1-1:$len2-1;

   open(FILE3,">./source/mmsg_query_third.txt");
   for (0..$num)
      {
         print FILE3 "$content1[$_] $content2[$_]\n";
      }

   close FILE3;
 
   #�Ժϲ����ļ�������ʽ����g������һЩ
   my @ary_query=();           #������

   open(INFILE,"./source/mmsg_query_third.txt") || die "\nOpen file failed:$@\n\n";
   my @ary_manfile=<INFILE>;   #һά����
   close(INFILE);
   
   foreach my $eachline (@ary_manfile)
   {
       chomp($eachline);
       my @tmp=split(/ /,$eachline);          #���ÿ����ֵ����ȡ��ֵ�ŵ���ʱ������
       push @ary_query,[@tmp];                #��һά��������ά����
   }
   
   open(MANAGER,">./source/manager_query.txt") || die "\nOpen file failed:$@\n\n";
   
   for my $i(0..$#ary_query)
   {
      ##�����ʽ
      $~="MANAGER";
   
      format MANAGER=
@<<<< @<<<<<<<<<<           @<<<<         @<<<<         @<<<<
      $ary_query[$i][0],$ary_query[$i][1],$ary_query[$i][2],$ary_query[$i][3],$ary_query[$i][4]
.
      write MANAGER;
   }

   close(MANAGER);
 
   ##���ӱ���
   system("sed -i \'1s\/\^\/    Time               MangerNum    QueueCurrentSize   QueueAvaliableSize\\n\/\' ./source/manager_query.txt");
 
   #��������ļ�
   unlink("./source/mmsg.info");
   unlink("./source/mmsg_query_first.txt");
   unlink("./source/mmsg_query_second.txt");
   unlink("./source/mmsg_query_third.txt");
   unlink("./source/time_tmp.txt");
}