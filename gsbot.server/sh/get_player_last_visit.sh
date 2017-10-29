#!/bin/bash

player_nick=$1
player_nick=`echo $player_nick | sed -e 's/\[/\\\[/g' | sed -e  's/\^/\\\^/g'`
grep -i $player_nick ./logs/*.log | awk '{print $1 " " $2 ", from " $4}' | tail -1 | cut -d: -f2-5 > ./sh/player_last_visit.txt
