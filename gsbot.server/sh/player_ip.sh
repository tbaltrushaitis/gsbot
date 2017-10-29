#!/bin/bash

ip_encoded=$1
tmp_file=`mktemp`
echo $ip_encoded | ./sh/peerchat_ip >> $tmp_file
ip_decoded=`tail -1 $tmp_file | cut -d ":" -f 2 | cut -d " " -f 3`
rm -f $tmp_file
echo $ip_decoded > ./sh/player_ip.txt
