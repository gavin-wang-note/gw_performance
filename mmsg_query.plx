#!/usr/bin/perl
use warnings;
use strict 'vars';

#########################################################################################
#    ###############################################################################    #
#   #      说明：   对MMSG的server sys日志队列信息过滤                              #   #
#   #                                                                               #   #
#   #      使用：   perl   masg_query.plx                                           #   #
#   #      AUTH：   wangyunzeng                                                     #   #
#   #      VER ：   1.0                                                             #   #
#   #      TIME：   2012-08-25   10:05   create                                     #   #
#    ###############################################################################    #
#########################################################################################

##定义全局变量
my $line;
my @fields=();

my $manager_file="./source/mmsg_query.txt";
my $modid_file="./source/mmsg.info";
system("mms status \>./source/mmsg.info");
my $MANAGER=$ARGV[0];

##判断mmsg.info文件大小
my @args = stat ($modid_file);
my $size = $args[7];
chomp($size);

if($size eq 0)
{
   print "\n【Error】mmsg.info文件大小为空，请确认当前用户能否执行[mms status]命令\n\n";
   unlink("./source/mmsg.info");
   exit;
}
else
{
   #server module ID  和  server manager数
   my $server_id=`cat ./source/mmsg.info | grep MMSServer | awk -F \" \" \'\{print substr\(\$2,2\,2\)\}\' | sed \'s\/\\\/\/\/\'`;
   my $manager_id=`mms list SrvServiceManagerAmount | grep SrvServiceManagerAmount | awk -F \"=\" \'\{print substr\(\$2,3,1\)\}\'`;

   chomp($server_id);
   chomp($manager_id);
   
   #print "\nserver_id: $server_id\n";
   #print "\n$manager_id\n";
   
   #清理文件，防止下面的目录判断后，如果目录不存在，导致mmsg.info文件还存在，故清理
   unlink("./source/mmsg.info");
   
   #判断路径
   my $dir="$ENV{MMS_HOME}/log/server_$server_id/sys";
   (-d "$dir") || die "\n目录[$dir]不存在，可能当前节点不是业务节点\n\n";

   print '-' x 60,"\n";
   print "\n获取MMSG的server sys日志中mmanager 队列消息......\n\n";

   #获取原生query信息到文件
   system("cat $dir/* | grep \"Message Queue Length in Server Srv_Manager\" > ./source/mmsg_query_first.txt");
   system("cat ./source/mmsg_query_first.txt | sed \'s\/\\[/\/g\' | sed \'s\/\\]\/ \/g\' | sed \'s/Message Queue Length in Server Srv_Manager\/\/g\' | sed \'s\/\:\/ \/g\' | sed \'s\/,\/ \/g\' | sed \'s\/QueueCurrentSize\/\/g\' | sed \'s\/QueueAvaliableSize\/\/g\' | awk -F \" \" \'\{print \$6,\$7,\$8,\$9,\$10\}\' > ./source/mmsg_query_second.txt");
   
   #获取时间
   system("cat ./source/mmsg_query_first.txt | sed \'s\/\\[\/\/g\' | awk -F \" \" \'\{print \$1,\$2\}\' > ./source/time_tmp.txt");
   
   #文件合并
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
 
   #对合并后文件处理，格式化后g更美观一些
   my @ary_query=();           #空数组

   open(INFILE,"./source/mmsg_query_third.txt") || die "\nOpen file failed:$@\n\n";
   my @ary_manfile=<INFILE>;   #一维数组
   close(INFILE);
   
   foreach my $eachline (@ary_manfile)
   {
       chomp($eachline);
       my @tmp=split(/ /,$eachline);          #拆分每行中值，获取的值放到临时数组中
       push @ary_query,[@tmp];                #将一维数组插入二维数组
   }
   
   open(MANAGER,">./source/manager_query.txt") || die "\nOpen file failed:$@\n\n";
   
   for my $i(0..$#ary_query)
   {
      ##定义格式
      $~="MANAGER";
   
      format MANAGER=
@<<<< @<<<<<<<<<<           @<<<<         @<<<<         @<<<<
      $ary_query[$i][0],$ary_query[$i][1],$ary_query[$i][2],$ary_query[$i][3],$ary_query[$i][4]
.
      write MANAGER;
   }

   close(MANAGER);
 
   ##增加标题
   system("sed -i \'1s\/\^\/    Time               MangerNum    QueueCurrentSize   QueueAvaliableSize\\n\/\' ./source/manager_query.txt");
 
   #清除过度文件
   unlink("./source/mmsg.info");
   unlink("./source/mmsg_query_first.txt");
   unlink("./source/mmsg_query_second.txt");
   unlink("./source/mmsg_query_third.txt");
   unlink("./source/time_tmp.txt");
}