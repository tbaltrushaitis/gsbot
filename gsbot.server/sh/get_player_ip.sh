#!/bin/bash

player_nick=$1
player_nick=`echo $player_nick | sed -e 's/\[/\\\[/g' | sed -e  's/\^/\\\^/g'`
ip=`grep -w $player_nick ./logs/*.log | tail -1 | cut -f 3`
echo "$ip" > ./sh/player_last_ip.txt
