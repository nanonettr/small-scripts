#!/bin/bash

# Config
# Tune this based on apache2 config
apacheThreadLimit="400"; # max thread count
outOnlyOnError="1"; # Do not print anything on success (exit status 0), print only if; apache restarted (exit status 11), apache restart failed (exit status 12) or any other error (exit status 1)

# These are sane values. No need to touch.
apacheMaxThreshold="75"; # if active thread count greater than this then apache will be restarted (percent)
apacheWaitThreshold="50"; # if active thread count greater than this script will check WaitRatio
apacheWaitRatio="75"; # if WaitThreshold reached and (active thread count / wait count) greater than this then apache will be restarted (percent)
serviceWait="30"; # After service restart seconds to wait for check if successful
restartCountMax="7"; # Max service restart tries

# Functions
restartCount="0";
lynxOut="";
myOutput="";
myStatus="";

MYCOMMANDS=( pidof basename w3m bc service netstat grep wc date sleep apache2ctl )
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

function apacheStatus() {
    service apache2 status >/dev/null 2>&1;
    apache2Status=$?;
    if [ "$apache2Status" == "0" ]; then
	myOutput="$myOutput""== Apache2 was running."$'\n';
    else
	myOutput="$myOutput""!! APACHE2 CHECK STATUS FAILED (not running?) !!"$'\n';
	if (( $restartCount <= $restartCountMax )); then
	    myOutput="$myOutput""++ Tryed again. ";
	apacheRestart;
	else
	    myStatus="12";
	    myOutput="$myOutput""== Failed to start apache2 after $restartCount tries :("$'\n';
	fi
    fi
}

function apacheRestart() {
    myStatus="11";
    myOutput="$myOutput""Restarted apache2 daemon..."$'\n';

    if (( $restartCount == 0 )); then
	lynxOut=$(w3m -no-proxy -4 -M -dump http://127.0.0.1/server-status 2>&1);
    fi

    restartCount=$(echo "scale=0; $restartCount + 1 " | bc);
    service apache2 restart >/dev/null 2>&1;
    apacheRestartStatus=$?;
    if [ "$apacheRestartStatus" == "0" ]; then
	sleep "$serviceWait";
	apacheStatus;
    else
	myOutput="$myOutput""!! APACHE2 RESTART COMMAND FAILED !!"$'\n';
	if (( $restartCount <= $restartCountMax )); then
	    myOutput="$myOutput""++ Tryed again. ";
	    apacheRestart;
	else
	    apacheStatus;
	fi
    fi
}

function getConfig() {
    myOutput="$myOutput""-- Config was: Limit($apacheThreadLimit) Max($calculatedMaxThreads) Threshold($calculatedMaxWaitThreshold) WaitCount($calculatedMinWaitThreads)"$'\n';
    myOutput="$myOutput""-- $apacheWaitCount of $apacheCount threads were in CLOSE_WAIT state."$'\n';
    myOutput="$myOutput""** Decision made: ";
}

# Calculations
calculatedMaxThreads=$(echo "scale=0; $apacheThreadLimit / 100 * $apacheMaxThreshold " | bc);
calculatedMaxWaitThreshold=$(echo "scale=0; $apacheThreadLimit / 100 * $apacheWaitThreshold " | bc);
calculatedMinWaitThreads=$(echo "scale=0; $calculatedMaxWaitThreshold / 100 * $apacheWaitRatio " | bc);

# System Variables
apacheCount=$(netstat -ntopua  | grep apache2 | wc -l);
apacheWaitCount=$(netstat -ntopua  | grep apache2 | grep CLOSE_WAIT | wc -l);

# Main
dateOut=$(date +"%F %T %z");
myOutput="$myOutput"""$'\n';
myOutput="$myOutput""Started @";
myOutput="$myOutput""$dateOut"$'\n';

if (( $apacheCount == 0 )); then
    getConfig;
    myOutput="$myOutput""There was not any threads running. ";
    apacheRestart;
elif (( $apacheCount >= $calculatedMaxThreads )); then
    getConfig;
    myOutput="$myOutput""Too many threads were running. ";
    apacheRestart;
elif (( $apacheCount >= $calculatedMaxWaitThreshold )); then
    getConfig;
    myOutput="$myOutput""Active threads threshold reached. ";
    if (( $apacheWaitCount >= $calculatedMinWaitThreads )); then
	myOutput="$myOutput""Too many waiting sockets (CLOSE_WAIT) found. ";
	apacheRestart;
    else
	myStatus="0";
	myOutput="$myOutput""But waiting socket (CLOSE_WAIT) count is in limits. Apache2 was running safely..."$'\n';
    fi
else
    myStatus="0";
    getConfig;
    myOutput="$myOutput""Apache2 was running good..."$'\n';
fi

dateOut=$(date +"%F %T %z");
myOutput="$myOutput""Ended @";
myOutput="$myOutput""$dateOut"$'\n';
myOutput="$myOutput"""$'\n';

if [ "$myStatus" -ne "0" ]; then
    myOutput="$myOutput""...............Apache2 server-status just before first restart..............."$'\n';
    myOutput="$myOutput""$lynxOut"$'\n';
    myOutput="$myOutput"""$'\n';

    echo -n "$myOutput";
elif [ "$outOnlyOnError" -ne "1" ]; then
    echo -n "$myOutput";
fi

exit $myStatus;
