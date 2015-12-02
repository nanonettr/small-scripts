# Small scripts
This scripts could be used in cron, rc.local or run manually.
All scripts for Ubuntu 14 LTS. They did not tested on other distributions.

## Disk Benchmark script
Usage:
```
./benchmark_disk.sh <FULL_PATH>
```

## Apache2 Status Checker
First edit file and change apacheThreadLimit based on your settings.
Also if you want to see some output change outOnlyOnError to 0.
Usage:
```
./check_apache2.sh
```

## fail2ban I/O reduce script
Usage:
```
./easy_fail2ban.sh
```
If need to see some output:
```
./easy_fail2ban.sh 1
```

## Apache Logger I/O reduce script
Usage:
```
./easy_vlogger.sh
```
If need to see some output:
```
./easy_vlogger.sh 1
```
