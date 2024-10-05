print_header() {
    echo -e "\n\033[1;36m==============================================\033[0m"
    echo -e "\033[1;36m        Node Height Monitor Script            \033[0m"
    echo -e "\033[1;36m==============================================\033[0m"
}

print_header

while true; do
    local_height=$(curl -s localhost:26657/status | jq -r '.result.sync_info.latest_block_height')
    
    network_height=$(curl -s https://snapshotstory.shablya.io/status | jq -r '.result.sync_info.latest_block_height')
  
    blocks_left=$((network_height - local_height))
    
    if [ "$local_height" -lt "$network_height" ]; then
        local_color="\033[1;31m" 
        status="Node is syncing..." 
    else
        local_color="\033[1;32m"
        status="Node is up to date!" 
    fi

    echo -ne "\033[1;35m----------------------------------------------\033[0m\r"
    echo -ne "\033[1;34mYour node height:\033[0m ${local_color}$local_height\033[0m | "
    echo -ne "\033[1;34mNetwork height:\033[0m \033[1;32m$network_height\033[0m | "
    echo -ne "\033[1;34mBlocks left to sync:\033[0m \033[1;31m$blocks_left\033[0m | "
    echo -ne "\033[1;33mStatus:\033[0m $status\r"
    
    sleep 2
done
