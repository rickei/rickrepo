#!/bin/bash


### this script is similiar to jirabackup.sh
### just target confluence (diff on taget directory)

USERNAME=[username/admin]
PASSWORD=[password]
INSTANCE=[jira_domain].atlassian.net
LOCATION=~/jirabackup


# Grabs cookies and generates the backup on the UI.
TODAY=`date +%Y%m%d`
COOKIE_FILE_LOCATION=confluencecookie
echo "Getting cookie and triggering backup."
curl -u $USERNAME:$PASSWORD --cookie-jar $COOKIE_FILE_LOCATION https://${INSTANCE}/Dashboard.jspa --output /dev/null
BKPMSG=`curl -s --cookie $COOKIE_FILE_LOCATION --header "X-Atlassian-Token: no-check" -H "X-Requested-With: XMLHttpRequest" -H "Content-Type: application/json" -X POST https://${INSTANCE}/wiki/rest/obm/1.0/runbackup -d '{"cbAttachments":"true" }' `
echo "Result: ${BKPMSG}"
rm $COOKIE_FILE_LOCATION

#Checks if the backup procedure has failed
echo "Checking if operation failed..."
if [ `echo $BKPMSG | grep -i backup | wc -l` -ne 0 ]; then
echo "Failed to trigger backup. Trying to get file."
#The $BKPMSG variable will print the error message, you can use it if you're planning on sending an email
fi

echo "Backup successfully triggered. Waiting for file on server..."
#Checks if the backup exists in WebDAV every 10 seconds, 20 times. If you have a bigger instance with a larger backup file you'll probably want to increase that.
for (( c=1; c<=100; c++ ))
do
wget --user=$USERNAME --password=$PASSWORD --spider https://${INSTANCE}/webdav/backupmanager/Confluence-backup-${TODAY}.zip >/dev/null 2>/dev/null
OK=$?
if [ $OK -eq 0 ]; then
echo "Backup found on server."
break
fi
sleep 60
done

#If after 20 attempts it still fails it ends the script.
if [ $OK -ne 0 ];
then
echo "Could not find backup on server."
exit
else

#If it's confirmed that the backup exists on WebDAV the file get's copied to the $LOCATION directory.
echo "Saving backup to ${LOCATION}."
wget --user=$USERNAME --password=$PASSWORD -t 0 --retry-connrefused https://${INSTANCE}/webdav/backupmanager/Confluence-backup-${TODAY}.zip -P $LOCATION
fi
