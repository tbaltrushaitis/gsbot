#!/bin/bash

player_nick=$1
./sh/gsplayers -s n $player_nick | grep profile_id: | awk -F" " '{print $2}' | sort > ./nicks_id/$player_nick.gs.txt
