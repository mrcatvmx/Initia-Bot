#!/bin/bash

# Function to check if tmux is installed
check_tmux() {
    if ! command -v tmux &> /dev/null; then
        echo "tmux is not installed. Installing tmux..."
        sudo apt update
        sudo apt install -y tmux
    fi
}

# Function to setup and run Initia node
setup_initia_node() {
    # Print information and ask for confirmation
    echo "$(tput setaf 6)════════════════════════════════════════════════════════════"
    echo "$(tput setaf 6)║       Welcome to INITIA NODE Script!                       ║"
    echo "$(tput setaf 6)║                                                              ║"
    echo "$(tput setaf 6)║     Follow us on Twitter:                                   ║"
    echo "$(tput setaf 6)║     https://twitter.com/cipher_airdrop                      ║"
    echo "$(tput setaf 6)║                                                              ║"
    echo "$(tput setaf 6)║     Join us on Telegram:                                    ║"
    echo "$(tput setaf 6)║     - https://t.me/+tFmYJSANTD81MzE1                       ║"
    echo "$(tput setaf 6)╚════════════════════════════════════════════════════════════$(tput sgr0)"

    read -p "Do you want to continue with the installation? (Y/N): " answer
    if [[ $answer != "Y" && $answer != "y" ]]; then
        echo "Aborting installation."
        exit 1
    fi

    # Install dependencies
    sudo apt update
    sudo apt install -y curl git jq lz4 build-essential

    # Install Go
    sudo rm -rf /usr/local/go
    curl -L https://go.dev/dl/go1.21.6.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
    echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile
    source .bash_profile

    # Clone project repository
    cd && rm -rf initia
    git clone https://github.com/initia-labs/initia
    cd initia
    git checkout v0.2.14

    # Build binary
    make install

    # Set node CLI configuration
    initiad config chain-id initiation-1
    initiad config keyring-backend test
    initiad config node tcp://localhost:25757

    # Ask for moniker
    read -p "Enter your node moniker: " moniker

    # Initialize the node
    initiad init "$moniker" --chain-id initiation-1

    # Download genesis and addrbook files
    curl -L https://snapshots-testnet.nodejumper.io/initia-testnet/genesis.json > $HOME/.initia/config/genesis.json
    curl -L https://snapshots-testnet.nodejumper.io/initia-testnet/addrbook.json > $HOME/.initia/config/addrbook.json

    # Set seeds
    sed -i -e 's|^seeds *=.*|seeds = "2eaa272622d1ba6796100ab39f58c75d458b9dbc@34.142.181.82:26656,c28827cb96c14c905b127b92065a3fb4cd77d7f6@testnet-seeds.whispernode.com:25756,cd69bcb00a6ecc1ba2b4a3465de4d4dd3e0a3db1@initia-testnet-seed.itrocket.net:51656,093e1b89a498b6a8760ad2188fbda30a05e4f300@35.240.207.217:26656,2c729d33d22d8cdae6658bed97b3097241ca586c@195.14.6.129:26019"|' $HOME/.initia/config/config.toml

    # Set minimum gas price
    sed -i -e 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.15uinit,0.01uusdc"|' $HOME/.initia/config/app.toml

    # Set pruning
    sed -i \
      -e 's|^pruning *=.*|pruning = "custom"|' \
      -e 's|^pruning-keep-recent *=.*|pruning-keep-recent = "100"|' \
      -e 's|^pruning-interval *=.*|pruning-interval = "17"|' \
      $HOME/.initia/config/app.toml

    # Change ports
    sed -i -e "s%:1317%:25717%; s%:8080%:25780%; s%:9090%:25790%; s%:9091%:25791%; s%:8545%:25745%; s%:8546%:25746%; s%:6065%:25765%" $HOME/.initia/config/app.toml
    sed -i -e "s%:26658%:25758%; s%:26657%:25757%; s%:6060%:25760%; s%:26656%:25756%; s%:26660%:25761%" $HOME/.initia/config/config.toml

    # Download latest chain data snapshot
    curl "https://snapshots-testnet.nodejumper.io/initia-testnet/initia-testnet_latest.tar.lz4" | lz4 -dc - | tar -xf - -C "$HOME/.initia"

    # Create a service
    sudo tee /etc/systemd/system/initiad.service > /dev/null << EOF
[Unit]
Description=Initia node service
After=network-online.target
[Service]
User=$USER
ExecStart=$(which initiad) start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF
    sudo systemctl daemon-reload
    sudo systemctl enable initiad.service

    # Start the service and check the logs
    sudo systemctl start initiad.service
    sudo journalctl -u initiad.service -f --no-hostname -o cat
}

# Main script

# Check and install tmux if not installed
check_tmux

# Setup and run Initia node
setup_initia_node
