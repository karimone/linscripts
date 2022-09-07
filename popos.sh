#!/bin/sh

alias ai="sudo apt install -y"
alias au="sudo apt update"
alias ag="sudo apt upgrade -y"


is_installed() {
    dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed"
}

install_if_not_installed() {
    if [ $(is_installed "$1") -eq 0 ];
    then
        ai "$1"
    else
        echo "$1 gia' installato"
    fi
}


# install zsh and make it default
install_if_not_installed zsh
install_if_not_installed detox

# install brave
if [ $(is_installed brave-browser) -eq 0 ];
then
    au && ai curl software-properties-common apt-transport-https 
    curl -s https://brave-browser-apt-release.s3.brave.com/brave-core.asc | sudo apt-key --keyring /etc/apt/trusted.gpg.d/brave-browser-release.gpg add -
    echo "deb [arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list
    au && ai brave-browser
else
    echo "brave-browser gia' installato"
fi


# install google-chrome

if [ $(is_installed google-chrome-stable) -eq 0 ];
then
    au && ai wget
    cd /tmp && wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    sudo dpkg -i /tmp/google-chrome-stable_current_amd64.deb
fi

# install python3

if [ $(is_installed python3) -eq 0 ];
then
    au && ai python3-dev python3-virtualenvwrapper python3-distutils python3-lib2to3 python3-gdbm python3-tk python3-venv
else
    echo "python3 gia' installato"
fi

# install python3.8 (for kraken)
if [ $(is_installed python3.8) -eq 0 ];
then
    sudo add-apt-repository ppa:deadsnakes/ppa -y
    au && ai python3.8 python3.8-dev python3.8-venv python3.8-distutils python3.8-lib2to3 python3.8-gdbm python3.8-tk
else 
    echo "python3.8 gia' installato"
fi

# install postgresql
if [ $(is_installed postgresql) -eq 0 ];
then
    ai postgresql postgresql-contrib
    echo "starting postgresql service"
    sudo systemctl start postgresql.service
else
    echo "postgresql gia' installato"
fi

# install docker and docker compose
if [ $(is_installed docker-ce) -eq 0 ];
then
    ai lsb-release ca-certificates apt-transport-https software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    au
    ai docker-ce docker-compose
else
    echo "Docker gia' installato"
fi

# install starship
# curl -sS https://starship.rs/install.sh | sh
# check /usr/local/bin/starship

# some useful stuff
sudo apt install ubuntu-restricted-extras p7zip-full p7zip-rar \
    fonts-crosextra-caladea fonts-crosextra-carlito transmission

sudo apt install calibre


# bw cli
# install and copy in ~/bin
