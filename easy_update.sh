#!/bin/bash
# Source: https://github.com/nanonettr/small-scripts
# Version: 20160229

# Based on https://help.ubuntu.com/community/AutoWeeklyUpdateHowTo

MYCOMMANDS=( pidof basename aptitude grep apt-get mail at reboot )
for i in "${MYCOMMANDS[@]}"; do
    command -v ${i} >/dev/null 2>&1
    CNF=$?
    if [[ "$CNF" -eq "1" ]]; then
        >&2 echo "!! ${i} not installed. Aborting!...";
        exit 1;
    fi
done

if [[ $(pidof -s -o '%PPID' -x $(basename $0)) ]]; then
    >&2 echo "!! Another copy of this script is already running!..."
    exit 1
fi

# REPORT SETTINGS
always_report="0" # 0) Send mail only if something happened, 1) Always send output
admin_mail="<CHANGE_ME>" # Email address

# Create a temporary file
tmpfile=$(mktemp)

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export DEBIAN_FRONTEND=noninteractive

echo "" > ${tmpfile}
echo "Server: $(hostname -f)" >> ${tmpfile}
echo "Time: $(date +"%Y-%m-%d %H:%M")" >> ${tmpfile}
echo "" >> ${tmpfile}

# Run the commands to update the system
echo "Updating repos..." >> ${tmpfile}
aptitude update | grep -vP "^Hit |^Ign " >> ${tmpfile} 2>&1
echo "" >> ${tmpfile}
echo "Updating packages..." >> ${tmpfile}
aptitude -y upgrade >> ${tmpfile} 2>&1
echo "" >> ${tmpfile}
echo "Cleanup..." >> ${tmpfile}
apt-get autoremove >> ${tmpfile} 2>&1
aptitude clean >> ${tmpfile} 2>&1
apt-get autoclean >> ${tmpfile} 2>&1
echo "" >> ${tmpfile}

if [ -f /var/run/reboot-required ]; then
    echo "" >> ${tmpfile}
    cat /var/run/reboot-required >> ${tmpfile} 2>&1
fi

if [ -n "${1}" ]; then # If any arg ALWAYS display log
    cat ${tmpfile}
elif grep -q 'E: \|W: ' ${tmpfile}; then # ERROR, Send log via mail
    mail -s "[$(hostname -f)] Upgrade failed" ${admin_mail} < ${tmpfile}
else
    if [ -f /var/run/reboot-required ]; then # OK, NEED REBOOT
        echo "Auto reboot @$(date -d "15 minutes" +"%Y-%m-%d %H:%M")..." >> ${tmpfile}
        mail -s "[$(hostname -f)] Reboot scheduled" ${admin_mail} < ${tmpfile}
        at now +15 minutes <<< "reboot" >/dev/null 2>&1
    else # OK
        if [[ "$always_report" -eq "1" ]]; then # ALWAYS REPORT
            mail -s "[$(hostname -f)] Update success" ${admin_mail} < ${tmpfile}
        fi
    fi
fi

# Remove log
rm -f ${tmpfile}

