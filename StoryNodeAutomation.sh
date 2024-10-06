#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'

function show_image() {
  curl -s https://raw.githubusercontent.com/nodesshablya/nibiru_shablya_testnet/refs/heads/main/shablya.sh | bash
}

function install_node() {
  echo -e "${CYAN}\n--- Installing Node ---${RESET}\n"
  
  read -p "Enter your moniker: " moniker

  echo -e "${YELLOW}\n[1/6] Updating system and installing dependencies...${RESET}"
  sudo apt update
  sudo apt-get update
  sudo apt install curl git make jq build-essential gcc unzip wget lz4 aria2 -y

  echo -e "${YELLOW}\n[2/6] Downloading and installing Story-Geth...${RESET}"
  wget https://story-geth-binaries.s3.us-west-1.amazonaws.com/geth-public/geth-linux-amd64-0.9.3-b224fdf.tar.gz
  tar -xzvf geth-linux-amd64-0.9.3-b224fdf.tar.gz
  [ ! -d "$HOME/go/bin" ] && mkdir -p $HOME/go/bin
  if ! grep -q "$HOME/go/bin" $HOME/.bash_profile; then
    echo "export PATH=$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
  fi
  sudo cp geth-linux-amd64-0.9.3-b224fdf/geth $HOME/go/bin/story-geth
  source $HOME/.bash_profile
  story-geth version

  echo -e "${YELLOW}\n[3/6] Downloading and installing Story...${RESET}"
  wget https://story-geth-binaries.s3.us-west-1.amazonaws.com/story-public/story-linux-amd64-0.10.1-57567e5.tar.gz
  tar -xzvf story-linux-amd64-0.10.1-57567e5.tar.gz
  [ ! -d "$HOME/go/bin" ] && mkdir -p $HOME/go/bin
  if ! grep -q "$HOME/go/bin" $HOME/.bash_profile; then
    echo "export PATH=$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
  fi
  cp $HOME/story-linux-amd64-0.10.1-57567e5/story $HOME/go/bin
  source $HOME/.bash_profile
  story version

  echo -e "${YELLOW}\n[4/6] Initializing node with moniker ${WHITE}$moniker${RESET}..."
  story init --network iliad --moniker "$moniker"

  sudo tee /etc/systemd/system/story-geth.service > /dev/null <<EOF
[Unit]
Description=Story Geth Client
After=network.target

[Service]
User=root
ExecStart=/root/go/bin/story-geth --iliad --syncmode full
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

  sudo tee /etc/systemd/system/story.service > /dev/null <<EOF
[Unit]
Description=Story Consensus Client
After=network.target

[Service]
User=root
ExecStart=/root/go/bin/story run
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

  sudo systemctl daemon-reload
  sudo systemctl start story-geth
  sudo systemctl enable story-geth
  sudo systemctl start story
  sudo systemctl enable story

  echo -e "${GREEN}\nNode successfully installed and started!${RESET}"
}

function update_snapshot() {
  echo -e "${CYAN}\n--- Updating Snapshot ---${RESET}\n"
  wget -q -O update_snapshot.sh https://snapshotstory.shablya.io/update_snapshot.sh
  sudo chmod +x update_snapshot.sh
  ./update_snapshot.sh
  echo -e "${GREEN}\nSnapshot successfully updated!${RESET}"
}

function update_addrbook() {
  echo -e "${CYAN}\n--- Updating addrbook.json ---${RESET}\n"
  wget -q -O /root/.story/story/config/addrbook.json https://snapshotstory.shablya.io/addrbook.json
  sudo systemctl restart story-geth && sudo systemctl restart story 
  echo -e "${GREEN}\naddrbook.json successfully updated!${RESET}"
}

function update_peers() {
  echo -e "${CYAN}\n--- Updating Peers ---${RESET}\n"
  
  PEERS=$(curl -sS https://snapshotstory.shablya.io/net_info | 
  jq -r '.result.peers[] | select(.node_info.id != null and .remote_ip != null and .node_info.listen_addr != null) | 
  "\(.node_info.id)@\(if .node_info.listen_addr | contains("0.0.0.0") then .remote_ip + ":" + (.node_info.listen_addr | sub("tcp://0.0.0.0:"; "")) else (.node_info.listen_addr | sub("tcp://"; "")) end)"' | 
  paste -sd ',')

  PEERS="\"$PEERS\""

  if [ -n "$PEERS" ]; then
      sed -i "s/^persistent_peers *=.*/persistent_peers = $PEERS/" "$HOME/.story/story/config/config.toml"
      if [ $? -eq 0 ]; then
          echo -e "Configuration file updated successfully with new peers"
      else
          echo "Failed to update configuration file."
      fi
  else
      echo "No peers found to update."
  fi
}

function check_sync() {
  echo -e "${CYAN}\n--- Checking Sync ---${RESET}\n"
  wget -q -O node_height_monitor.sh https://snapshotstory.shablya.io/node_height_monitor.sh
  sudo chmod +x node_height_monitor.sh
  ./node_height_monitor.sh
}

function remove_node() {
  read -p "Are you sure you want to remove the node? Type 'Yes' to confirm or 'No' to cancel: " confirmation
  if [[ "$confirmation" == "Yes" ]]; then
    echo -e "${CYAN}\n--- Removing Node ---${RESET}\n"
    sudo systemctl stop story-geth
    sudo systemctl stop story
    sudo systemctl disable story-geth
    sudo systemctl disable story
    sudo rm /etc/systemd/system/story-geth.service
    sudo rm /etc/systemd/system/story.service
    sudo systemctl daemon-reload
    sudo rm -rf $HOME/.story
    sudo rm $HOME/go/bin/story-geth
    sudo rm $HOME/go/bin/story
    echo -e "${GREEN}\nNode successfully removed!${RESET}"
  else
    echo -e "${RED}\nNode removal canceled.${RESET}"
  fi
}

function show_menu() {
  show_image
  
  echo -e "${BOLD}${WHITE}----------------------------------"
  echo -e "|          ${CYAN}Story Installer${WHITE}          |"
  echo -e "----------------------------------${RESET}"
  echo -e " ${YELLOW}1)${WHITE} Install Node"
  echo -e " ${YELLOW}2)${WHITE} Update Snapshot"
  echo -e " ${YELLOW}3)${WHITE} Update addrbook.json"
  echo -e " ${YELLOW}4)${WHITE} Check Sync"
  echo -e " ${YELLOW}5)${WHITE} Update Peers"
  echo -e " ${YELLOW}6)${WHITE} Remove Node"
  echo -e " ${YELLOW}7)${WHITE} Exit"
  echo -e "${BOLD}${WHITE}----------------------------------${RESET}"
  
  read -p "Enter your choice [1-7]: " choice
  case $choice in
    1)
      install_node
      ;;
    2)
      update_snapshot
      ;;
    3)
      update_addrbook
      ;;
    4)
      check_sync
      ;;
    5)
      update_peers
      ;;
    6)
      remove_node
      ;;
    7)
      echo -e "${GREEN}\nExiting...${RESET}"
      exit 0
      ;;
    *)
      echo -e "${RED}Invalid choice. Please try again.${RESET}"
      show_menu
      ;;
  esac
}

show_menu
