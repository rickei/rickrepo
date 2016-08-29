#!/bin/bash

### script check haproxy log and count unique ip address had accessed

remoteuser="root"
remotehost="[haproxy host]"
sshkeyfile="[ssh key file]"
remotecommand="cat /var/log/haproxy.log"
ssh -i $sshkeyfile $remoteuser@$remotehost "$remotecommand" |grep GET |grep -v [ip not count]|awk '{print $6}' |cut -d : -f 1 |sort|uniq|wc -l
