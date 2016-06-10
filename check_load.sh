#!/bin/bash


if [ ! -z "$1" ] && [ $1 = "n" ]; then
	dryrun='true'
else
	dryrun='false'
fi

echo "--------------------"
echo $(date +"%Y-%m-%d_%H:%M:%S")A
if [ "$dryrun" = "true" ]; then
	echo "Dryrun mode"
fi


haproxycfg="/etc/haproxy/haproxy.cfg"
ofile="lb_member_list"

doproxy_dir='/root/doproxy/'
doproxy_invfile='inventory'

minloading="40"
maxloading="70"

if [ ! -f $haproxycfg ]; then
	echo $haproxycfg" not find, please check!!"
	exit
fi

## read /etc/haproxy/haproxy.cfg, get the backend server lines, which have 'specialmark' for reconizing 
cat $haproxycfg |grep -A99 specialmark|grep server|awk {'print $3'}|sed 's/:80//g' > $ofile



nproccommand="nproc"
uptimecommand="uptime"
linecount=0
remotecommand=$nproccommand";"$uptimecommand
while read line 
do
	if [ "$line" != "" ]; then
		ipaddr=$(echo $line)
		#echo $ipaddr
		commandresult=$(ssh -o StrictHostKeyChecking=no root@$ipaddr $remotecommand  < /dev/null)
		echo $commandresult
		cpucount=$(echo $commandresult|awk {'print $1'})

		## use 5min loading : $4
		loading_5min=$(echo $commandresult| grep -ohe 'load average[s:][: ].*' | awk '{ print $4 }'|sed 's/,//g')
		
		#echo $cpucount
		#echo $loading_5min
		loadpercent=$(awk "BEGIN {print $loading_5min/$cpucount*100}")
		#echo $loadpercent
		loadarray[linecount]=$loadpercent
		linecount=$[linecount + 1]
	fi
done < $ofile

#echo $linecount
#echo ${loadarray[*]}

#sortarray=($(for i in "${loadarray[@]}"; do echo "$i"; done | sort -n))

#echo ${sortarray[*]}

average=$(echo ${loadarray[@]} | awk '{ total=0; for (i=1; i<=NF; i++) total+=$i; } END { printf("%.2f\n", total/NF); }')
echo "Avg Load of "$linecount "servers :" $average"%"


if [ "$dryrun" = "true" ]; then
	exit
fi

if (( $(echo "$average > $maxloading" |bc -l) )); then
	echo "create droplet"
	cd $doproxy_dir
	ruby doproxy.rb create
	ruby doproxy.rb reload
else
	if (( $(echo "$average < $minloading" |bc -l) )); then

		echo "remove spin"
		if [ -s $doproxy_dir$doproxy_invfile ]; then
			echo "delete droplet list in inventory, line 0"
			cd $doproxy_dir
			ruby doproxy.rb delete 0
			ruby doproxy.rb reload
		else
			echo "empty inventory, no additional droplet, do nothing"
		fi
	else
		echo "loading between "$minloading" and "$maxloading"%, keep current"
	fi
fi
