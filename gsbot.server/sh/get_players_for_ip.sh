#!/bin/bash

#check_ip=8.8.8.8
check_ip=$1
grep $check_ip ./logs/*.log | awk -F"\t" '{ print $2 }' | sort | uniq > ./ip/$check_ip.txt
