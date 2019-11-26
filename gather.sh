#! /usr/bin/ksh
OS_Type=`uname -s`

if [ ! -d source ]; then
  mkdir source
fi

if [[ "$OS_Type" = "AIX" ]]
then
    ARG='pid thcount pcpu vsz args'
    HEAD='  PID THCNT  %CPU   VSZ COMMAND'
elif [[ "$OS_Type" = "SunOS" ]]
then
    ARG='pid nlwp pcpu vsz rss args'
    HEAD='  PID NLWP %CPU  VSZ  RSS COMMAND'
elif [[ "$OS_Type" = "Linux" ]]
then
    ARG='pid nlwp pcpu vsz rss args'
    HEAD='  PID NLWP %CPU  VSZ  RSS COMMAND'
else
    echo "\nThis script cannot run in $OS_Type system\n"
    exit 1
fi

MMSG_COMMAND="MsgidMapper|mms_server|mms_charging_server|mmsc_server|vasp_server|VASPClient|MMSCClient"     #彩信用
SMS_COMMAND="agent|startapp|drserver|billserver|smserver|dbserver|msgstore|billclient"                      #短信用
M_COMMAND="mdspmon|uclient|umsgsrv|smpa|cmanager|taskmgr|memrefresh"                                        #M模块用

S=6
U=$LOGNAME

while getopts :s:d:f:u:t: OPTION
do
    case "$OPTION" in
        s) S=$OPTARG ;;
        d) D=$OPTARG ;;
        f) F=$OPTARG ;;
        u) U=$OPTARG ;;
        t) T=$OPTARG ;;
        ?) if [[ "$OPTARG" = "u" ]]; then
               U=$LOGNAME
           else
               echo "Usage: ${0##*/} [-s Seconds] [-d Display] [-f Filename] [-u [Username]] [-t [gateway type,m:MMSG;s:SMS]]"
               exit 1
           fi
           ;;
    esac
done



if [[ -z "$F" ]]; then
    cols=`tput cols`
fi

if [[ -z "$D" ]]; then
    echo "$HEAD"
    PS=`ps -u $U -o "$ARG"`
    #echo "$PS" | egrep "$COMMAND" | cut -c1-$cols
     if [[ "$T" = "a" ]];then
        echo "$PS" | egrep "$MMSG_COMMAND" | cut -c1-$cols
     elif [[ "$T" = "s" ]];then
        echo "$PS" | egrep "$SMS_COMMAND" | cut -c1-$cols
     elif [[ "$T" = "m" ]];then
        echo "$PS" | egrep "$M_COMMAND" | cut -c1-$cols
     fi
    exit 0
fi

###modify by wyz add OS type check###

if [[ "$OS_Type" = "AIX" ]]
then
      
      iostat -d  $S $D >> ./source/iostat.txt &
      vmstat  $S $D >> ./source/vmstat.txt &
      #sar -P ALL $S $D >> ./source/sar.txt &
      sar $S $D >> ./source/sar.txt &
      
elif [[ "$OS_Type" = "SunOS" ]]
then
      ####增加脚本
      echo "\n暂时不做SunOS\n"

elif [[ "$OS_Type" = "Linux" ]]
then
    # gather running data about I/O
    iostat -dxt $S $D >> ./source/iostat.txt &
    
    # gather running data about Virtual Memory and CPU
    vmstat  -n $S $D >> ./source/vmstat.txt &
    
    # gather running data about CPU
    sar -P ALL $S $D >> ./source/sar.txt &
    
    ##调用perl获取内存使用状况
    perl ./memused.plx -s $S -d $D -f &

else
    echo "\nThis script cannot run in $OS_Type system\n"
    exit 1
fi

N=0
while true
do
    PS=`ps -u $U -o "$ARG"`

    if [[ -n "$F" ]]; then
        date '+%Y-%m-%d %H:%M:%S' >> $F
        echo "$HEAD" >> $F
        if [[ "$T" = "a" ]];then
           echo "$PS" | egrep "$MMSG_COMMAND" >> $F
        elif [[ "$T" = "s" ]];then
           echo "$PS" | egrep "$SMS_COMMAND" >> $F
        elif [[ "$T" = "m" ]];then
           echo "$PS" | egrep "$M_COMMAND" >> $F           
        fi
     
        #echo "$PS" | egrep "$COMMAND" >> $F
        echo "" >> $F
    else
        echo "$HEAD"
        #echo "$PS" | egrep "$COMMAND" | cut -c1-$cols
        if [[ "$T" = "a" ]];then
           echo "$PS" | egrep "$MMSG_COMMAND" | cut -c1-$cols
        elif [[ "$T" = "s" ]];then
           echo "$PS" | egrep "$SMS_COMMAND" | cut -c1-$cols
        elif [[ "$T" = "m" ]];then
           echo "$PS" | egrep "$M_COMMAND" | cut -c1-$cols
        fi
    fi

    let N+=1
    if [[ $D -gt 0 && $N -ge $D ]]; then
        break
    fi
    sleep $S
done