#!/bin/bash

# Source: https://github.com/nanonettr/small-scripts
# Version: 20151202

MYCOMMANDS=( pidof basename renice ionice fail2ban-server ps grep awk cat nocache service )
for i in "${MYCOMMANDS[@]}"; do
    command -v ${i} >/dev/null 2>&1
    CNF=$?
    if [[ "$CNF" -eq "1" ]]; then
        echo "---- ${i} komutu bulunamadı!.."
        exit 1
    fi
done

if [[ $(pidof -s -o '%PPID' -x $(basename $0)) ]]; then
    echo "---- Programın bir kopyası zaten çalısıyor!.."
    exit 1
fi

MYPID=$$
ionice -c 2 -n 5 -p "${MYPID}" >/dev/null 2>&1
renice -n 10 -p "${MYPID}" >/dev/null 2>&1

function mainfunc() {
    local PSPID=0
    local FPID=0

    local PSPID=$(ps x | grep "/fail2ban-server" | grep -v "grep" | grep "/fail2ban.sock" | awk '{print $1}')

    if [ -f "/var/run/fail2ban/fail2ban.pid" ]; then
	local FPID=$(cat /var/run/fail2ban/fail2ban.pid)
    fi

    if [ "${PSPID}" == "${FPID}" ]; then
	nocache ionice -c 3 -p "${FPID}" > /dev/null 2>&1
	nocache renice -n 19 -p "${FPID}" > /dev/null 2>&1
	echo "0";
    else
	nocache ionice -c 3 nice -n 19 service fail2ban --full-restart > /dev/null 2>&1
	echo "1";
    fi
}

while [ ! $(mainfunc) == 0 ]; do
    if [ -n "${1}" ]; then
	echo "fail2ban Reloaded..."
    fi
    sleep 1
done;

if [ -n "${1}" ]; then
    FPID=$(ps alx | grep -v grep | grep fail2ban-server | awk '{print $3}')
    FNICE=$(ps alx | grep -v grep | grep fail2ban-server | awk '{print $6}')
    FION=$(ionice -p "${FPID}")

    echo "Fail2ban pid ${FPID}, nice ${FNICE}, ionice ${FION}"
fi

exit 0
