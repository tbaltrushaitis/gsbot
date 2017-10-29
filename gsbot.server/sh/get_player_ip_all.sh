#!/bin/bash

player_nick=$1
player_nick_sed=`echo $player_nick | sed -e 's/\[/\\\[/g' | sed -e  's/\^/\\\^/g'`
grep $player_nick_sed ./logs/*.log | awk -F"\t" '{ print $3 }' | sort | uniq > ./nicks/$player_nick.txt
