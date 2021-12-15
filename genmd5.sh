#!/bin/bash

sfile="dhwebchklist.txt"


while read line
do
        #echo $line
        chksum=$(curl -s -k  $line |sed '/csrf\|token/Id'|md5sum| awk '{ print $1 }')
        echo $line" "$chksum" "0
done < $sfile
