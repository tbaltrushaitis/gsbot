#!/bin/bash

player_nick=$1
player_nick_sed=`echo $player_nick | sed -e 's/\[/\\\[/g' | sed -e  's/\^/\\\^/g'`
grep -i $player_nick_sed ./logs/*.log | awk -F"@" '{ print $2 }' | sort | uniq > ./nicks_id/$player_nick.txt
