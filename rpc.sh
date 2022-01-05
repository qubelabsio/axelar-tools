#!/bin/bash

red='\033[0;31m'
pink='\033[35m'
green='\033[0;32m'
orange='\033[01;33m'
blue='\033[0;34m'
cyan='\033[0;36m'
cyan1='\033[0;34m'
nocolor='\033[0m'

function send_telegram_notification {
  service="$1"
  url="$2"
  tg_msg="RPC $service failed check: $url"
  if [[ ${TG_TOKEN} != "" || ${TG_CHAT_ID} != "" ]]; then
    curl -s -H 'Content-Type: application/json' --request 'POST' -d "{\"chat_id\":\"${TG_CHAT_ID}\",\"text\":\"${tg_msg}\"}" "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" -so /dev/null
  fi
}

function check_status() {
  service="$1"
  url="$2"
  if [[ -z "$url" ]]; then
    return
  fi

  status="FAIL"
  if [[ "$service" == "Polygon" ]]; then
    response=$(curl -s -H "Content-Type: application/json" -d '{"id":1, "jsonrpc":"2.0", "method": "eth_syncing","params":[]}' "$url")
    if [[ "$response" == *":false"* ]]; then
      status="OK"
    fi

  elif [[ "$service" == "Avalanche" ]]; then
    response=$(curl -s -X POST --data '{"jsonrpc": "2.0","method":"info.isBootstrapped","params":{"chain":"C"},"id":1}' -H 'content-type:application/json;' $url/ext/info )
    if [[ "$response" == *":true"* ]]; then
      status="OK"
    fi

  elif [[ "$service" == "Fantom" ]]; then
    response=$(curl -s -H "Content-Type: application/json" -d '{"id":1, "jsonrpc":"2.0", "method": "eth_syncing","params":[]}' "$url")
    if [[ "$response" == *":false"* ]]; then
      status="OK"
    fi

  elif [[ "$service" == "Moonbeam" ]]; then
    response=$(curl -s -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":64}' "$url")
    if [[ "$response" == *":false"* ]]; then
      status="OK"
    fi

  elif [[ "$service" == "Ethereum" ]]; then
    response=$(curl -s -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":64}' "$url")
    if [[ "$response" == *":false"* ]]; then
      status="OK"
    fi

  fi

  echo -e "${nocolor}$service: $url"
  if [[ "$status" == "OK" ]]; then
    echo -e "\t${green}CHECK OK!"
  else
    echo -e "\t${red}CHECK FAILED!"
    send_telegram_notification "$service" "$url"
  fi


}

function welcome() {
  echo -e "${green}#######################################################"
  echo             "#         Axelar External Chains Uptime Check         #"
  echo -e          "#######################################################\n${blue}"

echo -e "${cyan}Please enter your RPC addresses below in IP:PORT or URL format. If you are not running all chains, you can skip a field by pressing enter. \n${blue}"

  read -p "Enter your Polygon RPC: " polygon
  read -p "Enter your Avalanche RPC: " avalanche
  read -p "Enter your Fantom RPC: " fantom
  read -p "Enter your Moonbeam RPC: " moonbeam
  read -p "Enter your Ethereum RPC: " ethereum

  all_strings="$polygon$avalanche$fantom$moonbeam$ethereum"

  if [[ -z "$all_strings" ]]; then
    echo -e "${red}No servers to scan, exit script${nocolor}"
    exit
  fi

  echo -e "${cyan}--------------------------------------"

  read -p "How often would you like to check? (minutes) " minutes_wait
  # minutes to rescan, default 5 if empty
  if [[ -z $minutes_wait ]]; then
    minutes_wait=5
    echo -e "${red}No input, using default: $minutes_wait${nocolor}"
  fi

  echo -e "${cyan1}--------------------------------------"
  read -p "Enter Telegram Token: " TG_TOKEN
  read -p "Enter Telegram Chat ID: " TG_CHAT_ID
  if [[ -z $TG_TOKEN ]]; then
    echo -e "${red}No telegram Token, notifications disabled${nocolor}"
  fi
  echo -e "${blue}--------------------------------------"
}

function main() {

  welcome

  echo -e "${green}Start checking...$(date +"%d/%m/%Y %H:%M")"
  echo -e "Checking every $minutes_wait minutes"
  echo -e "${cyan1}--------------------------------------\n"


  while :;do
    check_status "Polygon" "$polygon"
    check_status "Avalanche" "$avalanche"
    check_status "Fantom" "$fantom"
    check_status "Moonbeam" "$moonbeam"
    check_status "Ethereum" "$ethereum"

    echo -e "${cyan}--------------------------------------"
    next_time=$(date +"%d/%m/%Y %H:%M" --date="+$minutes_wait minutes")
    echo "Next check: $next_time"
    echo "Scanning again in $minutes_wait minutes"
    echo -e "${cyan1}--------------------------------------"
    sleep "$minutes_wait"m
  done
}


main
