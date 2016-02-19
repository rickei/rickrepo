#!/bin/bash

### script to automatic backup jira, since jira limited back perform every 48hrs
### crontab should be : 0 2 */3 * * jirabackup.sh
### */3 mean do every 3 days (try /2 but it will skip, maybe caused by the 48hrs limitation) 


USERNAME=[username]
PASSWORD=[password]
INSTANCE=[jira_account_domain].atlassian.net

## save backup path
LOCATION=~/jirabackup

# Grabs cookies and generates the backup on the UI.
TODAY=`date +%Y%m%d`
COOKIE_FILE_LOCATION=jiracookie
curl --silent -u $USERNAME:$PASSWORD --cookie-jar $COOKIE_FILE_LOCATION https://${INSTANCE}/Dashboard.jspa --output /dev/null
BKPMSG=`curl -s --cookie $COOKIE_FILE_LOCATION --header "X-Atlassian-Token: no-check" -H "X-Requested-With: XMLHttpRequest" -H "Content-Type: application/json"  -X POST https://${INSTANCE}/rest/obm/1.0/runbackup -d '{"cbAttachments":"true" }' `
rm $COOKIE_FILE_LOCATION

#Checks if the backup procedure has failed
if [ `echo $BKPMSG | grep -i backup | wc -l` -ne 0 ]; then
#The $BKPMSG variable will print the error message, you can use it if you're planning on sending an email
exit
fi

#Checks if the backup exists in WebDAV every 10 seconds, 20 times. If you have a bigger instance with a larger backup file you'll probably want to increase that.

## increase to sleep 60 and count 100

for (( c=1; c<=100; c++ ))
do
wget --user=$USERNAME --password=$PASSWORD --spider https://${INSTANCE}/webdav/backupmanager/JIRA-backup-${TODAY}.zip >/dev/null 2>/dev/null
OK=$?
if [ $OK -eq 0 ]; then
break
fi
sleep 60
done

#If after 20 attempts it still fails it ends the script.
if [ $OK -ne 0 ];
then
exit
else

#If it's confirmed that the backup exists on WebDAV the file get's copied to the $LOCATION directory.
wget --user=$USERNAME --password=$PASSWORD -t 0 --retry-connrefused https://${INSTANCE}/webdav/backupmanager/JIRA-backup-${TODAY}.zip -P $LOCATION >/dev/null 2>/dev/null
fi
