#!/bin/bash

sfile="dhweblist"
nfile="new_chkfile"
senderemail="noreply@sunnyvision.com"
recpemail="frankie_wc_cheng@dh.gov.hk freddy_bh_ma@dh.gov.hk horace_kh_chung@dh.gov.hk patrick_wk_lam@dh.gov.hk raymond_h_yeung@dh.gov.hk tony_tm_so@dh.gov.hk support.dcs2@sunnyvision.com"
smtpserver="192.168.254.22"

cumcount=0
maxcount=3

date >> chks.log

while read line
do
        old_chksum=$(echo $line|awk '{print $2}')
        chk_file=$(echo $line|awk '{print $1}')
        chksum=$(curl -s -k $chk_file |sed '/csrf\|token/Id'|md5sum| awk '{ print $1 }')
        cumcount=$(echo $line|awk '{print $3}')
        if [ "$chksum" != "$old_chksum" ]; then
                if [ "$cumcount" -gt "$maxcount" ]; then
                        echo "DH web file chksum error : "$chk_file" , please check!" |mailx -S smtp=$smtpserver -r $senderemail -s  "DH web file checksum error" -v $recpemail
                        echo "DH web file chksum error : "$chk_file >> chks.log
                fi
                echo $line|awk '$3 = $3+1' >> $nfile
        else
                echo $line|awk '$3 = "0"' >> $nfile
        fi
done < $sfile

rm $sfile
mv $nfile $sfile
