#!/usr/bin/perl
#use warnings;
use strict 'vars';
use Config::IniFiles;

#########################################################################################
#    ###############################################################################    #
#   #      ˵����   �ϲ����txt�ļ����ȶ��ļ�                                       #   #
#   #      ʹ�ã�   perl   unite.plx                                                #   #
#   #      AUTH��   wangyunzeng                                                     #   #
#   #      VER ��   1.0                                                             #   #
#   #      TIME��   2012-09-07   16:54   create                                     #   #
#    ###############################################################################    #
#########################################################################################

##˵��
$~="UNITE";
write;

format UNITE=

============================================================
��˵����

    1�����ű��ϲ���Ⱥ�����и����ڵ����������;

    2����Ҫ�ϲ�sar_dp.txt��memused��iowait������ļ�.

============================================================

.


##�������ļ���ȡ��Ϣ
my $cfg = Config::IniFiles->new( -file => "./config/config.ini" );
my $iscluster=$cfg->val('GW_PERFROMANCE','IsCluster') || '';                    #�Ƿ��ǽ�Ⱥ����
$iscluster=lc($iscluster);                                                      #��ֹ�����ļ��������˴�д

(-d "source") || die "\nSource dir is not eixst,$!\n\n";

chdir "source";
my $list_tmp=`ls -l | grep memused | grep -vi tmp | grep -vi uni | awk -F \" \" \'\{print \$NF\}\' | sed \'s\/memused\_\/\/g\' | sed \'s\/\.txt\/\/g\'`;

my @each_ip=split(/\n/,$list_tmp);

##��ȡ�ļ���IP��Ӧ�ļ�������
my $memfile_nums=`ls -l memused*.txt | wc -l`;
my $sarfile_nums=`ls -l sar_dp_*.txt | wc -l`;
my $iofile_nums=`ls -l iostat_dp_*.txt | wc -l`;
chomp($memfile_nums);
chomp($sarfile_nums);
chomp($iofile_nums);

##add by wangyunzneg ����iowait�ļ����  2012-10-23
my $iowait_nums=`ls -l sar* | grep -v sar_dp | wc -l`;
chomp($iowait_nums);
##end add by wangyunzeng 2012-10-23

#######################��memused�ļ����д���################################
unlink("uni_memused.txt");                                                      #Ԥ��ɾ���ļ�,��ֹ�ļ�����(׷��)

if($memfile_nums==1)
{
   print "\n�Ǽ�Ⱥ�������������memused�ļ��ϲ�����.\n\n";
   exit;
}
elsif($memfile_nums == 2)
{
   print "\n�ܹ��� ��$memfile_nums�� ��memused�����ļ���Ҫ�ϲ�.\n\n";

   print "\n��ʼ��memused�ļ����кϲ�����......\n\n";

   my $tmp=`cat ./memused_$each_ip[1].txt | awk -F \" \" \'\{print \$3\}\' > ./mem_tmp.txt`;
   my $file_tmp="./mem_tmp.txt";
   
   open(FILE1,"./memused_$each_ip[0].txt") || die "\nOpen file ./memused_$each_ip[0].txt failed,$!\n\n";
   my @content1 = <FILE1>;
   chomp(@content1);
   close FILE1;
   
   
   open(FILE2,"$file_tmp") || die "\nOpen file $file_tmp failed,$!\n\n";
   my @content2 = <FILE2>;
   chomp(@content2);
   close FILE2;
   
   my $len1 = scalar(@content1);
   my $len2 = scalar(@content2);
   my $num = $len1 > $len2 ? $len1-1:$len2-1;

   open(FILE3,">> ./uni_memused.txt") || die "\nOpen file uni_memused.txt failed,$!\n\n";
   for (0..$num)
   {
      print FILE3 "$content1[$_]           $content2[$_]\n";
   }
      
   close FILE3;
   unlink("./mem_tmp.txt");
   
   ##����һ�б���
   system("sed -i \'1s\/\^\/    Time             $each_ip[0]    $each_ip[1]\\n\/\' ./uni_memused.txt");
}
elsif($memfile_nums > 2)
{
   print "\n�ܹ��� ��$memfile_nums�� ��memused�����ļ���Ҫ�ϲ�.\n\n";

   print "\n��ʼ��memused�ļ����кϲ�����......\n\n";
   
   ##����1����ȡÿ���ļ�����Ҫ�У����ļ���
   ##����2��paste�����ϲ���
   ##����3��ͨ���ļ�������ϲ����ļ�
   ##����4���ļ�����һ�У�����time IP��ַ
   
   my $memused_tmp_times=`cat memused_$each_ip[0].txt | awk -F \" \" \'\{print \$1,\$2\}\' > tmp_memused_times.txt`;
   
   for(my $i=0;$i<$memfile_nums;$i++)
   {
      my $ip=$each_ip[$i];
      chomp($ip);
      
      my $memused_tmp_value=`cat memused_$ip.txt | awk -F \" \" \'\{print \$3\}\' > tmp_memused_value$i.txt`;
   }
   
   ##��ȡ�ļ�������pasteʹ�ã���ʹ��*�����ļ�������У�
   my $tmp_memused_value_list=`ls -l | grep tmp_memused_value | awk -F \" \" \'\{print \$NF\}\'`;
   my @list_memused_files=split(/\n/,$tmp_memused_value_list);
   chomp(@list_memused_files);
   
   #system("paste -d  -s tmp_memused_times.txt @list_memused_files > tmp_memused.txt");
   #system("cat tmp_memused.txt |  sed \'s\/\-\/ \/g\' | sed \'s\/s\/ \/g\' > uni_memused.txt");
   system("paste -d @ tmp_memused_times.txt @list_memused_files > tmp_memused.txt");                #�ָ���@
   system("cat tmp_memused.txt |  sed \'s\/\-\/ \/g\' | sed \'s\/s\/ \/g\' | sed 's/@/     /g' > uni_memused.txt");   
   
   #����һ�б���
   chomp(@each_ip);
   system("sed -i \'1s\/\^\/    Time          @each_ip\\n\/\' uni_memused.txt");

   ##ɾ�������ļ�
   system("rm -f tmp_memused_value*.txt");
   unlink("tmp_memused.txt");
   unlink("tmp_memused_times.txt");
}


#########################��sar_dp�ļ����д���#########################
##���Թ����У����ڸ���ƽ̨Ӳ�����ÿ��ܻ᲻һ��(����)��������sar�����л�ȡ��all��¼

unlink("uni_sar.txt");

if($sarfile_nums==1)
{
   print "\n�Ǽ�Ⱥ�������������sar_dp�ļ��ϲ�����.\n\n";
   exit;
}
elsif($sarfile_nums == 2)
{
   print "\n�ܹ��� ��$sarfile_nums�� ��sar_dp�����ļ���Ҫ�ϲ�.\n\n";

   print "\n��ʼ��sar_dp�ļ����кϲ�����......\n\n";

   my $tmp1=`cat ./sar_dp_$each_ip[0].txt |grep -i all | awk -F \" \" \'\{print \$1,\$3\}\' > ./sar_dp_1.txt`;
   my $tmp2=`cat ./sar_dp_$each_ip[1].txt |grep -i all | awk -F \" \" \'\{print \$NF\}\' > ./sar_dp_2.txt`;
   
   open(FILE1,"sar_dp_1.txt") || die "\nOpen file sar_dp_1.txt failed,$!\n\n";
   my @content1 = <FILE1>;
   chomp(@content1);
   close FILE1;
   
   
   open(FILE2,"sar_dp_2.txt") || die "\nOpen file sar_dp_2.txt failed,$!\n\n";
   my @content2 = <FILE2>;
   chomp(@content2);
   close FILE2;
   
   my $len1 = scalar(@content1);
   my $len2 = scalar(@content2);
   my $num = $len1 > $len2 ? $len1-1:$len2-1;

   open(FILE3,">> ./uni_sar.txt") || die "\nOpen file uni_sar.txt failed,$!\n\n";
   for (0..$num)
   {
      print FILE3 "$content1[$_]           $content2[$_]\n";
   }
      
   close FILE3;
   unlink("./sar_dp_1.txt");
   unlink("./sar_dp_2.txt");
   
   ##����һ�б���
   system("sed -i \'1s\/\^\/Time   $each_ip[0]    $each_ip[1]\\n\/\' ./uni_sar.txt");
}
elsif($sarfile_nums > 2)
{
   print "\n�ܹ��� ��$sarfile_nums�� ��sar_dp�����ļ���Ҫ�ϲ�.\n\n";

   print "\n��ʼ��sar_dp�ļ����кϲ�����......\n\n";
   
   my $sar_tmp_times=`cat sar_dp_$each_ip[0].txt | awk -F \" \" \'\{print \$1\}\' > tmp_sar_times.txt`;
   
   for(my $i=0;$i<$sarfile_nums;$i++)
   {
      my $ip=$each_ip[$i];
      chomp($ip);
      
      my $sar_tmp_value=`cat sar_dp_$ip.txt | awk -F \" \" \'\{print \$3\}\' > tmp_sar_value$i.txt`;
   }
   
   my $tmp_sar_value_list=`ls -l | grep tmp_sar_value | awk -F \" \" \'\{print \$NF\}\'`;
   my @list_sar_files=split(/\n/,$tmp_sar_value_list);
   chomp(@list_sar_files);
   
   #system("paste -d -s tmp_sar_times.txt @list_sar_files > tmp_sar.txt");
   #system("cat tmp_sar.txt |  sed \'s\/\-\/ \/g\' | sed \'s\/s\/ \/g\' > uni_sar.txt");
   system("paste -d @ tmp_sar_times.txt @list_sar_files > tmp_sar.txt");
   system("cat tmp_sar.txt |  sed \'s\/\-\/ \/g\' | sed \'s\/s\/ \/g\' | sed 's/@/     /g'> uni_sar.txt");
   
   #����һ�б���
   chomp(@each_ip);
   system("sed -i \'1s\/\^\/Time     @each_ip\\n\/\' uni_sar.txt");

   ##ɾ�������ļ�
   system("rm -f tmp_sar_value*.txt");
   unlink("tmp_sar.txt");
   unlink("tmp_sar_times.txt");
}

#########################iostat�ļ���ÿ���кϲ���һ���ļ�#######################
unlink("uni_io_read.txt");
unlink("uni_io_write.txt");
unlink("uni_io_await.txt");
unlink("uni_io_util.txt");

if($iofile_nums==1)
{
   print "\n�Ǽ�Ⱥ�������������iostat_dp�ļ��ϲ�����.\n\n";
   exit;
}
elsif($iofile_nums == 2)
{
   #######################���̶���Ϣ######################
   print "\n�ܹ��� ��$iofile_nums�� ��iostat_dp�����ļ���Ҫ�ϲ�.\n\n";
   
   print "\n��ʼ��iostat_dp�ļ����кϲ�����......\n\n";

   my $tmp1=`cat ./iostat_dp_$each_ip[0].txt | grep -vi Time | awk -F \" \" \'\{print \$1,\$2\}\' > ./iostat_read_1.txt`;
   my $tmp2=`cat ./iostat_dp_$each_ip[1].txt | grep -vi Time  | awk -F \" \" \'\{print \$2\}\' > ./iostat_read_2.txt`;
   
   open(IOREAD1,"iostat_read_1.txt") || die "\nOpen file iostat_read_1.txt failed,$!\n\n";
   my @content1 = <IOREAD1>;
   chomp(@content1);
   close IOREAD1;
   
   
   open(IOREAD2,"iostat_read_2.txt") || die "\nOpen file iostat_read_2.txt failed,$!\n\n";
   my @content2 = <IOREAD2>;
   chomp(@content2);
   close IOREAD2;
   
   my $len1 = scalar(@content1);
   my $len2 = scalar(@content2);
   my $num = $len1 > $len2 ? $len1-1:$len2-1;

   open(IOREAD3,">> ./uni_io_read.txt") || die "\nOpen file uni_io_read.txt failed,$!\n\n";
   for (0..$num)
   {
      print IOREAD3 "$content1[$_]   $content2[$_]\n";
   }

   close IOREAD3;
   unlink("./iostat_read_1.txt");
   unlink("./iostat_read_2.txt");
   
   ##����һ�б���
   system("sed -i \'1s\/\^\/Time     $each_ip[0]    $each_ip[1]\\n\/\' ./uni_io_read.txt");
   system("cat uni_io_read.txt | sed \'s\/ʱ\/\:\/g\' | sed \'s\/��\/\:\/g\' | sed \'s\/��\/\/g\' > uni_io_read_tmp.txt");
   system("mv uni_io_read_tmp.txt uni_io_read.txt");
   
   #####################����д��Ϣ######################
   my $tmp3=`cat ./iostat_dp_$each_ip[0].txt | grep -vi Time | awk -F \" \" \'\{print \$1,\$3\}\' > ./iostat_write_1.txt`;
   my $tmp4=`cat ./iostat_dp_$each_ip[1].txt | grep -vi Time  | awk -F \" \" \'\{print \$3\}\' > ./iostat_write_2.txt`;
   
   open(IOWRITE1,"iostat_write_1.txt") || die "\nOpen file iostat_write_1.txt failed,$!\n\n";
   my @content3 = <IOWRITE1>;
   chomp(@content3);
   close IOWRITE1;
   
   
   open(IOWRITE2,"iostat_write_2.txt") || die "\nOpen file iostat_write_2.txt failed,$!\n\n";
   my @content4 = <IOWRITE2>;
   chomp(@content4);
   close IOWRITE2;
   
   my $len3 = scalar(@content3);
   my $len4 = scalar(@content4);
   my $num2 = $len3 > $len4 ? $len3-1:$len4-1;

   open(IOWRITE3,">> ./uni_io_write.txt") || die "\nOpen file uni_io_write.txt failed,$!\n\n";
   for (0..$num2)
   {
      print IOWRITE3 "$content3[$_]   $content4[$_]\n";
   }
 
   close IOWRITE3;
   unlink("./iostat_write_1.txt");
   unlink("./iostat_write_2.txt");
   
   ##����һ�б���
   system("sed -i \'1s\/\^\/Time     $each_ip[0]    $each_ip[1]\\n\/\' ./uni_io_write.txt");
   system("cat uni_io_write.txt | sed \'s\/ʱ\/\:\/g\' | sed \'s\/��\/\:\/g\' | sed \'s\/��\/\/g\' > uni_io_write_tmp.txt");
   system("mv uni_io_write_tmp.txt uni_io_write.txt");   
   
   ###################������Ӧʱ��######################
   my $tmp5=`cat ./iostat_dp_$each_ip[0].txt | grep -vi Time | awk -F \" \" \'\{print \$1,\$4\}\' > ./iostat_await_1.txt`;
   my $tmp6=`cat ./iostat_dp_$each_ip[1].txt | grep -vi Time  | awk -F \" \" \'\{print \$4\}\' > ./iostat_await_2.txt`;
   
   open(IOAWAIT1,"iostat_await_1.txt") || die "\nOpen file iostat_await_1.txt failed,$!\n\n";
   my @content5 = <IOAWAIT1>;
   chomp(@content5);
   close IOAWAIT1;
   
   
   open(IOAWAIT2,"iostat_await_2.txt") || die "\nOpen file iostat_await_2.txt failed,$!\n\n";
   my @content6 = <IOAWAIT2>;
   chomp(@content6);
   close IOAWAIT2;
   
   my $len5 = scalar(@content5);
   my $len6 = scalar(@content6);
   my $num3 = $len5 > $len6 ? $len5-1:$len6-1;

   open(IOAWAIT3,">> ./uni_io_await.txt") || die "\nOpen file uni_io_await.txt failed,$!\n\n";
   for (0..$num3)
   {
      print IOAWAIT3 "$content5[$_]   $content6[$_]\n";
   }
 
   close IOAWAIT3;
   unlink("./iostat_await_1.txt");
   unlink("./iostat_await_2.txt");
   
   ##����һ�б���
   system("sed -i \'1s\/\^\/Time     $each_ip[0]    $each_ip[1]\\n\/\' ./uni_io_await.txt");
   system("cat uni_io_await.txt | sed \'s\/ʱ\/\:\/g\' | sed \'s\/��\/\:\/g\' | sed \'s\/��\/\/g\' > uni_io_await_tmp.txt");
   system("mv uni_io_await_tmp.txt uni_io_await.txt");    
   
   
   ###################������æ��######################
   my $tmp7=`cat ./iostat_dp_$each_ip[0].txt | grep -vi Time | awk -F \" \" \'\{print \$1,\$5\}\' > ./iostat_util_1.txt`;
   my $tmp8=`cat ./iostat_dp_$each_ip[1].txt | grep -vi Time  | awk -F \" \" \'\{print \$5\}\' > ./iostat_util_2.txt`;
   
   open(UTIL1,"iostat_util_1.txt") || die "\nOpen file iostat_util_1.txt failed,$!\n\n";
   my @content7 = <UTIL1>;
   chomp(@content7);
   close UTIL1;
   
   
   open(UTIL2,"iostat_util_2.txt") || die "\nOpen file iostat_util_2.txt failed,$!\n\n";
   my @content8 = <UTIL2>;
   chomp(@content8);
   close UTIL2;
   
   my $len7 = scalar(@content7);
   my $len8 = scalar(@content8);
   my $num4 = $len7 > $len8 ? $len7-1:$len8-1;

   open(UTIL3,">> ./uni_io_util.txt") || die "\nOpen file uni_io_util.txt failed,$!\n\n";
   for (0..$num4)
   {
      print UTIL3 "$content7[$_]   $content8[$_]\n";
   }
 
   close UTIL3;
   unlink("./iostat_util_1.txt");
   unlink("./iostat_util_2.txt");
   
   ##����һ�б���
   system("sed -i \'1s\/\^\/Time     $each_ip[0]    $each_ip[1]\\n\/\' ./uni_io_util.txt");
   system("cat uni_io_util.txt | sed \'s\/ʱ\/\:\/g\' | sed \'s\/��\/\:\/g\' | sed \'s\/��\/\/g\' > uni_io_util_tmp.txt");
   system("mv uni_io_util_tmp.txt uni_io_util.txt");    
}
elsif($sarfile_nums > 2)
{
   print "\n�ܹ��� ��$iofile_nums�� ��iostat_dp�����ļ���Ҫ�ϲ�.\n\n";
   
   print "\n��ʼ��iostat_dp�ļ����кϲ�����......\n\n";
   
   ##ʱ��
   my $io_tmp_times=`cat iostat_dp_$each_ip[0].txt | grep -vi Time | awk -F \" \" \'\{print \$1\}\' > tmp_io_times.txt`;
   
   ##���̶���Ϣ,д������ļ�tmp_io_value$i.txt
   for(my $i=0;$i<$iofile_nums;$i++)
   {
      my $ip=$each_ip[$i];
      chomp($ip);
      
      my $io_read_value=`cat iostat_dp_$ip.txt  | grep -vi Time | awk -F \" \" \'\{print \$2\}\' > tmp_io_read$i.txt`;    #io����Ϣ
      my $io_write_value=`cat iostat_dp_$ip.txt | grep -vi Time | awk -F \" \" \'\{print \$3\}\' > tmp_io_write$i.txt`;  #ioд��Ϣ
      my $io_await_value=`cat iostat_dp_$ip.txt  | grep -vi Time | awk -F \" \" \'\{print \$4\}\' > tmp_io_await$i.txt`;    #io����Ϣ
      my $io_util_value=`cat iostat_dp_$ip.txt | grep -vi Time | awk -F \" \" \'\{print \$5\}\' > tmp_io_util$i.txt`;  #ioд��Ϣ
      
   }
   
   ##��ȡ�ļ��б����ݸ�paste����
   #io��
   my $tmp_io_read_list=`ls -l | grep tmp_io_read | awk -F \" \" \'\{print \$NF\}\'`;
   my @list_ioread_files=split(/\n/,$tmp_io_read_list);
   chomp(@list_ioread_files);
   
   #ioд
   my $tmp_io_write_list=`ls -l | grep tmp_io_write | awk -F \" \" \'\{print \$NF\}\'`;
   my @list_iowrite_files=split(/\n/,$tmp_io_write_list);
   chomp(@list_iowrite_files);
   
   ##io await
   my $tmp_io_await_list=`ls -l | grep tmp_io_await | awk -F \" \" \'\{print \$NF\}\'`;
   my @list_ioawait_files=split(/\n/,$tmp_io_await_list);
   chomp(@list_ioawait_files);   
   
   ##io util
   my $tmp_io_util_list=`ls -l | grep tmp_io_util | awk -F \" \" \'\{print \$NF\}\'`;
   my @list_ioutil_files=split(/\n/,$tmp_io_util_list);
   chomp(@list_ioutil_files);
   
   
   #system("paste -d  -s tmp_io_times.txt @list_ioread_files > tmp_ioread.txt");
   #system("cat tmp_ioread.txt |  sed \'s\/\-\/ \/g\' | sed \'s\/s\/ \/g\' > uni_io_read.txt");
   #
   #system("paste -d  -s tmp_io_times.txt @list_iowrite_files > tmp_iowrite.txt");
   #system("cat tmp_iowrite.txt |  sed \'s\/\-\/ \/g\' | sed \'s\/s\/ \/g\' > uni_io_write.txt");
   
   ##io read
   system("paste -d @ tmp_io_times.txt @list_ioread_files > tmp_ioread.txt");
   system("cat tmp_ioread.txt |  sed \'s\/\-\/ \/g\' | sed \'s\/s\/ \/g\' | sed 's/@/     /g' > uni_io_read.txt");

   ##io write   
   system("paste -d @ tmp_io_times.txt @list_iowrite_files > tmp_iowrite.txt");
   system("cat tmp_iowrite.txt |  sed \'s\/\-\/ \/g\' | sed \'s\/s\/ \/g\' | sed 's/@/     /g' > uni_io_write.txt");

   ##io await
   system("paste -d @ tmp_io_times.txt @list_ioawait_files > tmp_ioawait.txt");
   system("cat tmp_ioawait.txt |  sed \'s\/\-\/ \/g\' | sed \'s\/s\/ \/g\' | sed 's/@/     /g' > uni_io_await.txt");

   ##io util  
   system("paste -d @ tmp_io_times.txt @list_ioutil_files > tmp_ioutil.txt");
   system("cat tmp_ioutil.txt |  sed \'s\/\-\/ \/g\' | sed \'s\/s\/ \/g\' | sed 's/@/     /g' > uni_io_util.txt");
   
   #����һ�б���
   chomp(@each_ip);
   system("sed -i \'1s\/\^\/Time     @each_ip\\n\/\' uni_io_read.txt");
   system("sed -i \'1s\/\^\/Time     @each_ip\\n\/\' uni_io_write.txt");
   system("sed -i \'1s\/\^\/Time     @each_ip\\n\/\' uni_io_await.txt");
   system("sed -i \'1s\/\^\/Time     @each_ip\\n\/\' uni_io_util.txt");
   
   
   system("cat uni_io_read.txt | sed \'s\/ʱ\/\:\/g\' | sed \'s\/��\/\:\/g\' | sed \'s\/��\/\/g\' > uni_io_read_tmp.txt");
   system("mv uni_io_read_tmp.txt uni_io_read.txt");
   
   system("cat uni_io_write.txt | sed \'s\/ʱ\/\:\/g\' | sed \'s\/��\/\:\/g\' | sed \'s\/��\/\/g\' > uni_io_write_tmp.txt");
   system("mv uni_io_write_tmp.txt uni_io_write.txt"); 

   system("cat uni_io_await.txt | sed \'s\/ʱ\/\:\/g\' | sed \'s\/��\/\:\/g\' | sed \'s\/��\/\/g\' > uni_io_await_tmp.txt");
   system("mv uni_io_await_tmp.txt uni_io_await.txt");
   
   system("cat uni_io_util.txt | sed \'s\/ʱ\/\:\/g\' | sed \'s\/��\/\:\/g\' | sed \'s\/��\/\/g\' > uni_io_util_tmp.txt");
   system("mv uni_io_util_tmp.txt uni_io_util.txt");
   
   ##ɾ�������ļ�
   system("rm -f tmp_io_read*.txt");
   system("rm -f tmp_io_write*.txt");
   system("rm -f tmp_io_await*.txt");
   system("rm -f tmp_io_util*.txt");   
   unlink("tmp_ioread.txt");
   unlink("tmp_iowrite.txt");
   unlink("tmp_ioawait.txt");
   unlink("tmp_ioutil.txt");   
   unlink("tmp_io_times.txt");
}


##add by wangyunzeng 2012-10-23
#######################��iowait�ļ����д���################################
unlink("uni_iowait.txt");                                                      #Ԥ��ɾ���ļ�,��ֹ�ļ�����(׷��)

if($iowait_nums==1)
{
   print "\n��������������Ҫ�ϲ�sar.txt��iowait����.\n\n";
   exit;
}
elsif($iowait_nums == 2)
{
   print "\n�ܹ��� ��$iowait_nums�� ��iowait�����ļ���Ҫ�ϲ�.\n\n";

   print "\n��ʼ��sar�ļ���iowait���ݽ��кϲ�����......\n\n";

   my $tmp1=`cat ./sar_$each_ip[0].txt | grep all | grep -v Average | sed \'\/\^\$\/d\' | sed \'s\/ʱ\/\:\/g\' | sed \'s\/��\/\:\/g\' | sed \'s\/��\/\/g\'  | sed \'s\/PM\/\/g\' | sed \'s\/AM\/\/g\' | awk -F \" \" \'\{print \$1,\$6\}\'  > ./sar_tmp1.txt`;
   my $tmp2=`cat ./sar_$each_ip[1].txt | grep all | | grep -v Average awk -F \" \" \'\{print \$6\}\'  > ./sar_tmp2.txt`;
   my $file_tmp1="./sar_tmp1.txt";
   my $file_tmp2="./sar_tmp2.txt";
   
   open(FILE1,"$file_tmp1") || die "\nOpen file $file_tmp1 failed,$!\n\n";
   my @content1 = <FILE1>;
   chomp(@content1);
   close FILE1;
   
   
   open(FILE2,"$file_tmp2") || die "\nOpen file $file_tmp2 failed,$!\n\n";
   my @content2 = <FILE2>;
   chomp(@content2);
   close FILE2;
   
   my $len1 = scalar(@content1);
   my $len2 = scalar(@content2);
   my $num = $len1 > $len2 ? $len1-1:$len2-1;

   open(FILE3,">> ./uni_iowait.txt") || die "\nOpen file uni_iowait.txt failed,$!\n\n";
   for (0..$num)
   {
      print FILE3 "$content1[$_]           $content2[$_]\n";
   }
      
   close FILE3;
   unlink("./sar_tmp1.txt");
   unlink("./sar_tmp2.txt");
   
   ##����һ�б���
   system("sed -i \'1s\/\^\/Time     $each_ip[0]    $each_ip[1]\\n\/\' ./uni_iowait.txt");
}
elsif($iowait_nums > 2)
{
   print "\n�ܹ��� ��$iowait_nums�� ��iowait�����ļ���Ҫ�ϲ�.\n\n";

   print "\n��ʼ��sar�ļ���iowait���ݽ��кϲ�����......\n\n";
   
   ##����1����ȡÿ���ļ�����Ҫ�У����ļ���
   ##����2��paste�����ϲ���
   ##����3��ͨ���ļ�������ϲ����ļ�
   ##����4���ļ�����һ�У�����time IP��ַ
   
   my $iowait_tmp_times=`cat sar_$each_ip[0].txt | grep all | grep -v Average | sed \'\/\^\$\/d\' | sed \'s\/ʱ\/\:\/g\' | sed \'s\/��\/\:\/g\' | sed \'s\/��\/\/g\'  | sed \'s\/PM\/\/g\' | sed \'s\/AM\/\/g\' | awk -F \" \" \'\{print \$1\}\' > tmp_iowait_times.txt`;
   
   for(my $i=0;$i<$iowait_nums;$i++)
   {
      my $ip=$each_ip[$i];
      chomp($ip);
      
      my $iowait_tmp_value=`cat sar_$ip.txt | grep all | grep -v Average | awk -F \" \" \'\{print \$6\}\' > tmp_iowait_value$i.txt`;
   }

   ##��ȡ�ļ�������pasteʹ�ã���ʹ��*�����ļ�������У�
   my $tmp_iowait_value_list=`ls -l | grep tmp_iowait_value | awk -F \" \" \'\{print \$NF\}\'`;
   my @list_iowait_files=split(/\n/,$tmp_iowait_value_list);
   chomp(@list_iowait_files);

   system("paste -d @ tmp_iowait_times.txt @list_iowait_files > tmp_iowait.txt");                #�ָ���@
   system("cat tmp_iowait.txt |  sed \'s\/\-\/ \/g\' | sed \'s\/s\/ \/g\' | sed 's/@/     /g' > uni_iowait.txt");   
   
   #����һ�б���
   chomp(@each_ip);
   system("sed -i \'1s\/\^\/Time     @each_ip\\n\/\' uni_iowait.txt");

   ##ɾ�������ļ�
   system("rm -f tmp_iowait_value*.txt");
   unlink("tmp_iowait.txt");
   unlink("tmp_iowait_times.txt");
}

print '-' x 60,"\n\n";