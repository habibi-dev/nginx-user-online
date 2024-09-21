#!/bin/bash

ten_seconds_ago=$(date --date='10 seconds ago' '+%d/%b/%Y:%H:%M:%S')

output_file="/var/www/user_online/user_data.json"

declare -A ip_counts

while IFS= read -r line; do
    ip=$(echo "$line" | awk '{print $1}')
    if [[ -n "${ip_counts[$ip]}" ]]; then
        ((ip_counts[$ip]++))
    else
        ip_counts[$ip]=1
    fi
done < <(cat /var/log/nginx/access.log | grep "/hls/" | grep "GET" | grep -v "127.0.0.1" | grep -v "::1" | awk -v date="$ten_seconds_ago" '$4 >= "["date')

total_users=${#ip_counts[@]}

current_time=$(date '+%Y-%m-%d %H:%M:%S')

echo "{" > $output_file
echo "  \"total_users\": $total_users," >> $output_file
echo "  \"last_update\": \"$current_time\"" >> $output_file
echo "}" >> $output_file

echo "Total Unique Users: $total_users"
