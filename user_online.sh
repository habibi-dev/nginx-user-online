#!/bin/bash

# 10 seconds ago timestamp
ten_seconds_ago=$(date --date='10 seconds ago' '+%d/%b/%Y:%H:%M:%S')

# Output JSON file
output_file="/var/www/user_online/user_data.json"

# Arrays for counting unique users per path
declare -A ip_path_counts

# Process logs and count unique users per path
while IFS= read -r line; do
    ip=$(echo "$line" | awk '{print $1}')
    path=$(echo "$line" | awk '{print $7}' | grep -o '^/hls/[^/]*')  # Limit to /hls/* level
    
    if [[ $path == /hls/* ]]; then  # Only consider /hls/ paths
        key="$ip|$path"  # Create a unique key combining IP and path
        
        if [[ -z "${ip_path_counts[$key]}" ]]; then  # Count only if this IP hasn't been counted for this path
            ip_path_counts[$key]=1
        fi
    fi
done < <(cat /var/log/nginx/access.log | grep -a "/hls/" | grep "GET" | grep -v "127.0.0.1" | grep -v "::1" | awk -v date="$ten_seconds_ago" '$4 >= "["date')

# Count unique users per path
declare -A path_counts
for key in "${!ip_path_counts[@]}"; do
    path=$(echo "$key" | cut -d '|' -f 2)  # Extract the path from the key
    if [[ -n "${path_counts[$path]}" ]]; then
        ((path_counts[$path]++))
    else
        path_counts[$path]=1
    fi
done

# Calculate total unique users
total_users=$(echo "${!ip_path_counts[@]}" | wc -w)

# Get the current timestamp
current_time=$(date '+%Y-%m-%d %H:%M:%S')

# Write the JSON output
echo "{" > $output_file
echo "  \"total_users\": $total_users," >> $output_file
echo "  \"last_update\": \"$current_time\"," >> $output_file
echo "  \"paths\": {" >> $output_file

# Add the unique user counts per path
for path in "${!path_counts[@]}"; do
    echo "    \"$path\": ${path_counts[$path]}," >> $output_file
done

# Remove trailing comma from the last path entry
sed -i '$ s/,$//' $output_file

echo "  }" >> $output_file
echo "}" >> $output_file

# Display total users
echo "Total Unique Users: $total_users"
