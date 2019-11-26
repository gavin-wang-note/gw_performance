#!/usr/bin/perl
use warnings;
use strict 'vars';
use Getopt::Std;
use vars qw($opt_s $opt_d $opt_f);

#########################################################################################
#    ###############################################################################    #
#   #      ˵����   ��ȡ����ϵͳ�ڴ�ʹ�����                                        #   #
#   #               �ڴ�ʹ�ã�1-($MemFree+$Inactive)/$MemTotal                      #   #
#   #      ʹ�ã�   perl   memused.plx                                              #   #
#   #      AUTH��   wangyunzeng                                                     #   #
#   #      VER ��   1.0                                                             #   #
#   #      TIME��   2012-08-25   15:16   create                                     #   #
#    ###############################################################################    #
#########################################################################################


#ʹ�÷���
getopts("s:d:f");

if(!(($opt_s)|| ($opt_d) || ($opt_f)))
{
    print "\n��ʹ�÷�����\n\n";
    print "\nperl memused.plx  -s 5  -d 720 -f\n \n      ѡ��: -s   -d   -f\n\n\t    -s: ʱ���� [������] ʾ����Ϊ5m��\n\n\t    -d: �ռ�c���� [������]\n \n\t    -f: �ռ�������д�뵽���ļ����� [��������]\n\n";
    print "\n      ��˵�����ڴ�ʹ�ã�1-(MemFree+Inactive)/MemTotal \n\n";
    exit;
}
else
{
    ##����ϵͳ����
    my $os_type=$^O;
    
    my $count=$opt_s*$opt_d;
    my $opt_f="./source/memused.txt";
    unlink("./source/$opt_f");
    
    ##��ͬ����ϵͳ����
    if($os_type=~m/linux/)
    {
        for(my $i=0;$i<$count;$i++)
        {
           ##����ʱ��(ֱ��ʹ��linux����ʹ���Զ���ģ��������)
           my $daytime=`date +'%Y%m%d %H:%M:%S'`;
           chomp($daytime);
        
           my $MemTotal=`cat /proc/meminfo | grep MemTotal | awk -F \" \" \'\{print \$2\}\'`;
           my $MemFree=`cat /proc/meminfo | grep MemFree | awk -F \" \" \'\{print \$2\}\'`;
           my $Inactive=`cat /proc/meminfo | grep Inactive | awk -F \" \" \'\{print \$2\}\'`;
        
           chomp($MemTotal);
           chomp($MemFree);
           chomp($Inactive);
        
           my $used_mem=sprintf("%2.2f",(1-($MemFree+$Inactive)/$MemTotal)*100);
        
           open(FILE,">>$opt_f") || die "\nOpen file $opt_f failed:$!\n\n";
           print FILE "$daytime    $used_mem\n";
        
           sleep $opt_s;
           
        }
       close(FILE);
    }
    elsif($os_type=~m/aix/)
    {
        #for(my $i=0;$i<$count;$i++)
        #{
           ##����ʱ��(ֱ��ʹ��linux����ʹ���Զ���ģ��������)
           #my $daytime=`date +'%Y%m%d %H:%M:%S'`;
           #chomp($daytime);
        
           #my $MemTotal=`cat /proc/meminfo | grep MemTotal | awk -F \" \" \'\{print \$2\}\'`;
           #my $MemFree=`cat /proc/meminfo | grep MemFree | awk -F \" \" \'\{print \$2\}\'`;
           #my $Inactive=`cat /proc/meminfo | grep Inactive | awk -F \" \" \'\{print \$2\}\'`;
           #
           #chomp($MemTotal);
           #chomp($MemFree);
           #chomp($Inactive);
           #
           #my $used_mem=sprintf("%2.2f",(1-($MemFree+$Inactive)/$MemTotal)*100);
           #
           #open(FILE,">>$opt_f") || die "\nOpen file $opt_f failed:$!\n\n";
           #print FILE "$daytime    $used_mem\n";
           #
           #sleep $opt_s;
           
        #}
       #close(FILE);
       print "\n����֧�֡�AIX��֧��ͨ�� 1-(MemFree+Inactive)/MemTotal �����ڴ�ʹ����\n";
       print "\nAIXƽ̨����ʱ����.\n\n";
    }
    elsif($os_type=~m/sunos/)
    {
       print "\n����֧�֡�SUNƽ̨��֧��ͨ�� 1-(MemFree+Inactive)/MemTotal �����ڴ�ʹ����\n";
       print "\nSUNƽ̨����ʱ����.\n\n";
    }

}