#!/bin/bash

file="query_last_visit.txt"

# most asked nicks
printf "\nTOP asked players list:\n"
cat $file | awk '{print $3}' | sort | uniq -c | awk '$1 > 20' | sort > top_asked_list.txt

# most asking nicks
printf "\nTOP askers players list:\n"
cat $file | awk '{print $9}' | sort | uniq -c | awk '$1 > 20' | awk '$2 != ""' | sort > top_askers_list.txt

printf "\n"
tail $file
