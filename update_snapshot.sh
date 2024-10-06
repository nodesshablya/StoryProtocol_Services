#!/bin/bash

print_header() {
    echo -e "\n\033[1;36m==============================================\033[0m"
    echo -e "\033[1;36m          Snapshot Update Script              \033[0m"
    echo -e "\033[1;36m==============================================\033[0m"
}

print_separator() {
    echo -e "\033[1;35m----------------------------------------------\033[0m"
}

# Check if jq is installed
print_header
if ! command -v jq &> /dev/null; then
    echo -e "\033[1;31mjq is not installed. Installing...\033[0m"
    sudo apt-get install jq -y
fi

# Install required dependencies
print_separator
echo -e "\033[1;36mInstalling required dependencies...\033[0m"
sudo apt-get install wget lz4 -y

# Stop the story and story-geth nodes
print_separator
echo -e "\033[1;36mStopping story and story-geth nodes...\033[0m"
sudo systemctl stop story-geth && sudo systemctl stop story

# Check if the priv_validator_state.json file exists
if [ -f "$HOME/.story/story/data/priv_validator_state.json" ]; then
    # Create a backup of priv_validator_state.json
    print_separator
    echo -e "\033[1;36mCreating a backup of priv_validator_state.json...\033[0m"
    sudo cp $HOME/.story/story/data/priv_validator_state.json $HOME/.story/priv_validator_state.json.backup
else
    echo -e "\033[1;31mpriv_validator_state.json file not found. Exiting...\033[0m"
    exit 1
fi

# Delete previous chaindata and story data folders
print_separator
echo -e "\033[1;36mDeleting previous data...\033[0m"
sudo rm -rf $HOME/.story/geth/iliad/geth/chaindata
sudo rm -rf $HOME/.story/story/data

# Download story and story(geth) snapshots
print_separator
echo -e "\033[1;36mDownloading snapshots...\033[0m"
wget -O geth_latest.tar.lz4 https://snapshotstory.shablya.io/geth_latest.tar.lz4
wget -O story_latest.tar.lz4 https://snapshotstory.shablya.io/story_latest.tar.lz4

# Decompress the snapshots
print_separator
echo -e "\033[1;36mDecompressing snapshots...\033[0m"
lz4 -c -d geth_latest.tar.lz4 | tar -xv -C $HOME/.story/geth/iliad/geth
lz4 -c -d story_latest.tar.lz4 | tar -xv -C $HOME/.story/story

# Delete the downloaded snapshots
print_separator
echo -e "\033[1;36mDeleting downloaded snapshots...\033[0m"
sudo rm -v geth_latest.tar.lz4
sudo rm -v story_latest.tar.lz4

# Restore the priv_validator_state.json
print_separator
echo -e "\033[1;36mRestoring priv_validator_state.json...\033[0m"
sudo cp $HOME/.story/priv_validator_state.json.backup $HOME/.story/story/data/priv_validator_state.json

# Start the story and story-geth nodes
print_separator
echo -e "\033[1;36mStarting story and story-geth nodes...\033[0m"
sudo systemctl start story-geth && sudo systemctl start story

print_separator
echo -e "\033[1;32mScript completed successfully.\033[0m"
