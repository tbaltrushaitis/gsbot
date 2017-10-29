#!/bin/bash

player_id=$1
grep -i $player_id ./logs/*.log | awk -F"\t" '{ print $3 }' | sort | uniq > ./id/$player_id.txt
