#!/usr/bin/perl
use warnings;
use strict 'vars';

#########################################################################################
#    ###############################################################################    #
#   #      说明：   对文本文件进行压缩，压缩成source.tar.gz包                       #   #
#   #                                                                               #   #
#   #      使用：   perl   tar.plx                                                  #   #
#   #      AUTH：   wangyunzeng                                                     #   #
#   #      VER ：   1.0                                                             #   #
#   #      TIME：   2012-10-30   17:35   create                                     #   #
#    ###############################################################################    #
#########################################################################################

#判断source目录是否存在
(-d "source") || die "\n[Error] Dir source is: $!\n\n";

print "\n开始压缩文件到source.tar.gz\n\n";
chdir "source";
system("tar -zcf source.tar.gz *.txt");

#判断压缩后的文件是否存在
if (-f "source.tar.gz")
{
    print "\n成功压缩文件到source.tar.gz\n\n";
}
else
{
    print "\n[Error] 压缩source.tar.gz包过程出错，请手工检查.\n\n";
    exit;
}

#移动source.tar.gz文件到上层目录
system("mv source.tar.gz ../");