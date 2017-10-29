#!/bin/bash

player_nick=$1
player_nick=`echo $player_nick | sed -e 's/\[/\\\[/g' | sed -e  's/\^/\\\^/g'`

current_log_file=./logs/`date "+%Y-%m-%d"`.log
previous_log_file=./logs/`date -d '1 day ago' +'%Y-%m-%d'`.log

if [ -e $current_log_file ]
  then
    id=`grep -i $player_nick $current_log_file | tail -1 | cut -f 4 | cut -d @ -f 2`
fi

if [ "$id" == "" ]
  then
    if [ -e $previous_log_file ]
      then
        id=`grep -i $player_nick $previous_log_file | tail -1 | cut -f 4 | cut -d @ -f 2`
    fi
fi

echo "$id" > ./sh/player_last_id.txt
