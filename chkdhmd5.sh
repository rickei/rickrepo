#!/bin/bash

sfile="dhweblist"
senderemail="noreply@sunnyvision.com"
recpemail="rickyfong@sunnyvision.com chrisyeung@sunnyvision.com alexng@sunnyvision.com"
smtpserver="192.168.254.22"

date >> chks.log

while read line
do
        old_chksum=$(echo $line|awk '{print $2}')
        #echo $old_chksum
        chk_file=$(echo $line|awk '{print $1}')
        chksum=$(curl -s -k $chk_file |sed '/csrf\|token/Id'|md5sum| awk '{ print $1 }')
        #echo $chksum
        if [ "$chksum" != "$old_chksum" ]; then
                echo "DH web file chksum error : "$chk_file" , please check!" |mailx -S smtp=$smtpserver -r $senderemail -s  "DH web file checksum error" -v $recpemail
                echo "DH web file chksum error : "$chk_file >> chks.log

        fi
        #echo $line" "$chksum
done < $sfile
