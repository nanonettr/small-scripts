#!/bin/bash

# Source: https://github.com/nanonettr/small-scripts
# Version: 20151202

MYCOMMANDS=( pidof basename renice ionice ps grep awk nocache )
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

MYPID=$$
ionice -c 2 -n 5 -p "${MYPID}" >/dev/null 2>&1
renice -n 10 -p "${MYPID}" >/dev/null 2>&1

PSPID=-1
PSPID=$(ps x | grep -v 'grep' | grep ' vlogger (access log)' | awk '{print $1}');
nocache ionice -c 2 -n 7 -p "${PSPID}" >/dev/null 2>&1
nocache renice -n 19 -p "${PSPID}" >/dev/null 2>&1

if [ -n "${1}" ]; then
    FPID=$(ps alx | grep -v 'grep' | grep ' vlogger (access log)' | awk '{print $3}')
    FNICE=$(ps alx | grep -v 'grep' | grep ' vlogger (access log)' | awk '{print $6}')
    FION=$(ionice -p "${FPID}")

    echo "Vlogger pid ${FPID}, nice ${FNICE}, ionice ${FION}"
fi

exit 0
