#!/bin/bash

# 10 seconds ago timestamp
ten_seconds_ago=$(date --date='10 seconds ago' '+%d/%b/%Y:%H:%M:%S')

# Output JSON file
output_file="/var/www/user_online/user_data.json"

# Arrays for counting IPs and requests per path
declare -A ip_counts
declare -A path_counts

# Process logs and count users
while IFS= read -r line; do
    ip=$(echo "$line" | awk '{print $1}')
    # Extract and limit the path to one level after /hls/
    path=$(echo "$line" | awk '{print $7}' | grep -o '^/hls/[^/]*')  # Limit to /hls/* level

    if [[ $path == /hls/* ]]; then  # Only consider /hls/ paths
        # Count unique IPs
        if [[ -n "${ip_counts[$ip]}" ]]; then
            ((ip_counts[$ip]++))
        else
            ip_counts[$ip]=1
        fi
        
        # Count requests per simplified path
        if [[ -n "${path_counts[$path]}" ]]; then
            ((path_counts[$path]++))
        else
            path_counts[$path]=1
        fi
    fi
done < <(cat /var/log/nginx/access.log | grep -a "/hls/" | grep "GET" | grep -v "127.0.0.1" | grep -v "::1" | awk -v date="$ten_seconds_ago" '$4 >= "["date')

# Calculate total unique users
total_users=${#ip_counts[@]}

# Get the current timestamp
current_time=$(date '+%Y-%m-%d %H:%M:%S')

# Write the JSON output
echo "{" > $output_file
echo "  \"total_users\": $total_users," >> $output_file
echo "  \"last_update\": \"$current_time\"," >> $output_file
echo "  \"paths\": {" >> $output_file

# Add the user counts per simplified path
for path in "${!path_counts[@]}"; do
    echo "    \"$path\": ${path_counts[$path]}," >> $output_file
done

# Remove trailing comma from the last path entry
sed -i '$ s/,$//' $output_file

echo "  }" >> $output_file
echo "}" >> $output_file

# Display total users
echo "Total Unique Users: $total_users"
