#!/usr/bin/env bash


/usr/lib64/nagios/plugins/check_disk -w 20% -c 10% -p $1 |awk '{ if ($2 == "WARNING") { $10="LESS THAN 20% FREE );|"; print $0; exit 1 } else if ($2 == "CRITICAL") { $10="LESS THAN 10% FREE );|"; print $0; exit 2 }; print $0  }'
