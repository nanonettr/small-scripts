#!/bin/bash
# Source: https://github.com/nanonettr/small-scripts
# Version: 20160123

# Based on https://help.ubuntu.com/community/AutoWeeklyUpdateHowTo

MYCOMMANDS=( pidof basename aptitude grep apt-get mail at reboot )
for i in "${MYCOMMANDS[@]}"; do
    command -v ${i} >/dev/null 2>&1
    CNF=$?
    if [[ "$CNF" -eq "1" ]]; then
        echo "!! ${i} not installed. Aborting!...";
        echo >&2;
        exit 1;
    fi
done

if [[ $(pidof -s -o '%PPID' -x $(basename $0)) ]]; then
    echo "!! Another copy of this script is already running!..."
    echo >&2;
    exit 1
fi

# Your email address.
admin_mail="<CHANGE_ME>"

# Create a temporary file
tmpfile=$(mktemp)

# Run the commands to update the system
echo "Updating repos..." >> ${tmpfile}
aptitude update | grep -vP "^Hit |^Ign " >> ${tmpfile} 2>&1
echo "" >> ${tmpfile}
echo "Updating packages..." >> ${tmpfile}
aptitude -y upgrade >> ${tmpfile} 2>&1
echo "" >> ${tmpfile}
echo "Cleanup..." >> ${tmpfile}
aptitude clean >> ${tmpfile} 2>&1
apt-get autoclean >> ${tmpfile} 2>&1
aptitude autoclean >> ${tmpfile} 2>&1
apt-get autoremove >> ${tmpfile} 2>&1

if [ -f /var/run/reboot-required ]; then
    echo ""
    cat /var/run/reboot-required >> ${tmpfile} 2>&1
fi

# Send log via mail
if grep -q 'E: \|W: ' ${tmpfile} ; then
    mail -s "[$(hostname -f)] Upgrade failed" ${admin_mail} < ${tmpfile}
else
    if [ -f /var/run/reboot-required ]; then
        echo "Auto reboot @$(date -d "15 minutes" +"%Y-%m-%d %H:%M")..." >> ${tmpfile}
        mail -s "[$(hostname -f)] " ${admin_mail} < ${tmpfile}
        at now +15 minutes >/dev/null 2>&1 <<< "reboot"
    fi
fi

# Remove log
rm -f ${tmpfile}

