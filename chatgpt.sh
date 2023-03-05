#!/bin/bash
# Author: Ayad Hammoudi
# Version: 1.0
# Date: March/02/2023
# Name: Chat-GPT shell chat.
##############################################################################################
# Script required jq to parse json response, script will atepmt to install it if user agree. #
# Script require Token, you can get it from https://platform.openai.com/account/api-keys     #
# Set Token in line 20                                                                       #                                                                                            #
#                                                                                            #
##############################################################################################
clear
echo " "
echo "Welcome to Chat-GPT in Bash"
echo " "

#Chat GPT API End point URL
API_URL="https://api.openai.com/v1/engine/davinci-codex/completions"
#API Key
API_KEY='API KEY HERE'

#Script Path
ScriptPath=$(readlink -f $0)

#Check Add alias to .bashrc 
if [[ -f ~/.bashrc ]]; then
    ALIAS=$(grep "GPT" ~/.bashrc)
    if [[ -z $ALIAS ]]; then
        echo "Would you like to add aliases to bashrc?"
        echo "You can use any of these aliases below to run the script"
        echo "gpt, GPT, chat, AI, ai"
        read -p "y/n: " REPLY
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo 'alias gpt="'$ScriptPath'"' >> ~/.bashrc
            echo 'alias GPT="'$ScriptPath'"' >> ~/.bashrc
            echo 'alias chat="'$ScriptPath'"' >> ~/.bashrc
            echo 'alias AI="'$ScriptPath'"' >> ~/.bashrc
            echo 'alias ai="'$ScriptPath'"' >> ~/.bashrc
            source ~/.bashrc
        else
            echo "Aliases has been ignored."
        fi
    fi
fi

#Install jq based on the os version, its should cover Ubuntu, CentOS, RedHat, Fedora, and OpenSuse/Suse
InstallJQ () {
package="jq"
declare -A osInfo;
osInfo[/etc/debian_version]="apt-get install -y"
osInfo[/etc/centos-release]="yum install -y"
osInfo[/etc/redhat-release]="yum install -y"
osInfo[/etc/fedora-release]="dnf install -y"
osInfo[/etc/SuSE-release]="zypper install -y"

for f in ${!osInfo[@]}
do
    if [[ -f $f ]];then
        package_manager=${osInfo[$f]}
    fi
done

echo "jq package is required to parse chat-GPT response."
echo "Please type 'y/Y' to install the package, or 'n/N' to cancle and exit"
#Confirm with user before install package.
read -p "y/n: " REPLY
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [[ "$EUID" -ne 0 ]]; then
        sudo ${package_manager} ${package}
    else
        ${package_manager} ${package}
    fi
else
    echo " "
    echo "Exiting the script."
    exit 0
fi

}

#Check inf jq installed 
checkJQ () {
    if [[ ! -f /usr/bin/jq ]]; then #if jq does not exit in the 
    InstallJQ #call InstallJQ function.
    fi
}

checkJQ

#This function making API Calls and return the result, its alos till check if there is no input and return to prompt.
#Its also exit if the the input equal to q, bye, exit or quit.
callAPI () {
    #Check if the input is empty and return to prompt if its.
    if [[ -z $prompt ]]; then
        questions;
    fi
    #Check if the input is meant for exit.
    if [[ $prompt == "q" ]] || [[ $prompt == "bye" ]] || [[ $prompt == "exit" ]] || [[ $prompt == "quit" ]]; then
        echo "GoodBye"
        exit 0
    fi

    response=$(curl -sS https://api.openai.com/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $API_KEY" \
        -d '{"model": "gpt-3.5-turbo", "messages": [{"role": "user", "content": "'"$prompt"'"}]}')
    echo " "
    echo "$response" | /usr/bin/jq -r '.choices[].message.content'
    echo " "
    questions;
}

questions() {
    echo " "
    read -p 'Ask me a question: ' prompt
    callAPI
}

questions
