#!/bin/bash

basedir="$(dirname "$(cat $HOME/.bashrc | grep ccontrol | awk -F"=" '{print $2}')")"
execdir="$(dirname "$0")"

if [[ "$basedir" != "." && "$execdir" != "." ]]; then
  cd $basedir
elif [[ "$basedir" = "." && "$execdir" != "." ]]; then
  cd $PWD/$execdir
fi

basedir="$PWD"

. "project.conf"
. "functions.sh"
. "misc.sh"

main () {

  if [[ ( "$1" = "install" ) && ( "$2" = "core" || -z "$2" ) && ( -z "$3" ) ]]; then

    if [[ -d $data || -d $core ]]; then
      echo -e "\n${red}Core already installed. Please remove first.${nc}\n"
      exit 1
    fi

    sudo apt update > /dev/null 2>&1
    sysinfo
    install_deps &

    echo -ne "${cyan}Installing Dependencies...  ${red}"

    while [ -d /proc/$! ]; do
      printf "\b${sp:i++%${#sp}:1}" && sleep .1
    done

    echo -e "\b${green}Done${nc}"

    secure &

    echo -ne "${cyan}Securing System...  ${red}"

    while [ -d /proc/$! ]; do
      printf "\b${sp:i++%${#sp}:1}" && sleep .1
    done

    echo -e "\b${green}Done${nc}"

    install_db &

    echo -ne "${cyan}Installing Database...  ${red}"

    while [ -d /proc/$! ]; do
      printf "\b${sp:i++%${#sp}:1}" && sleep .1
    done

    echo -e "\b${green}Done${nc}"

    install_core &

    echo -ne "${cyan}Setting up Core...  ${red}"

    while [ -d /proc/$! ]; do
      printf "\b${sp:i++%${#sp}:1}" && sleep .1
    done

    echo -e "\b${green}Done${nc}\n"

  elif [[ ( "$1" = "update" ) && ( "$2" = "core" ) && ( -z "$3" ) ]]; then

    if [[ ! -d $data || ! -d $core ]]; then
      echo -e "\n${red}Core not installed. Please install first.${nc}\n"
      exit 1
    fi

    cd $core > /dev/null 2>&1
    git_check

    if [ "$up2date" = "yes" ]; then
      echo -e "Already up-to-date."
      exit 1
    fi

    git pull > /dev/null 2>&1

    if [ "$?" != "0" ]; then
      echo -e "\n${red}git pull failed - check for conflicts${nc}\n"
      exit 1
    fi

    sysinfo
    update &

    echo -ne "${cyan}Updating Core...  ${red}"

    while [ -d /proc/$! ]; do
      printf "\b${sp:i++%${#sp}:1}" && sleep .1
    done

    echo -e "\b${green}Done${nc}\n"

  elif [[ ( "$1" = "remove" ) && ( "$2" = "core" || -z "$2" ) && ( -z "$3" ) ]]; then

    if [[ ! -d $data && ! -d $core ]]; then
      echo -e "\n${red}Core not installed.${nc}\n"
      exit 1
    fi

    sudo apt update > /dev/null 2>&1
    sysinfo
    remove &

    echo -ne "${cyan}Removing Core...  ${red}"

    while [ -d /proc/$! ]; do
      printf "\b${sp:i++%${#sp}:1}" && sleep .1
    done

    echo -e "\b${green}Done${nc}\n"

  elif [[ ( "$1" = "config" ) && ( "$2" = "reset"  ) && ( -z "$3" ) ]]; then

    if [[ ! -d $data || ! -d $core ]]; then
      echo -e "\n${red}Core not installed. Please install first.${nc}\n"
      exit 1
    fi

    config_reset &

    sleep 1
    echo -e "\n${cyan}Processes Stopped...${nc}"
    sleep 1
    echo -e "${cyan}Configs Replaced with Defaults...${nc}"
    echo -e "${green}All Done!${nc}\n"

  elif [[ ( "$1" = "start" ) && ( "$2" = "relay" || "$2" = "forger" || "$2" = "all" || -z "$2" ) && ( -z "$3" ) ]]; then

    if [[ ! -d $data || ! -d $core ]]; then
      echo -e "\n${red}Core not installed. Please install first.${nc}\n"
      exit 1
    fi

    if [ -z "$2" ]; then
      set -- "$1" "all"
    fi

    start $2

    echo -e "\n${green}All Done!${nc}\n"

  elif [[ ( "$1" = "restart" ) && ( "$2" = "relay" || "$2" = "forger" || "$2" = "all" || -z "$2" ) && ( -z "$3" ) ]]; then

    if [[ ! -d $data || ! -d $core ]]; then
      echo -e "\n${red}Core not installed. Please install first.${nc}\n"
      exit 1
    fi

    if [ -z "$2" ]; then
      set -- "$1" "all"
    fi

    restart $2

    echo -e "\n${green}All Done!${nc}\n"

  elif [[ ( "$1" = "stop" ) && ( "$2" = "relay" || "$2" = "forger" || "$2" = "all" || -z "$2" ) && ( -z "$3" ) ]]; then

    if [[ ! -d $data || ! -d $core ]]; then
      echo -e "\n${red}Core not installed. Please install first.${nc}\n"
      exit 1
    fi

    if [ -z "$2" ]; then
      set -- "$1" "all"
    fi

    stop $2

    echo -e "\n${green}All Done!${nc}\n"

  elif [[ ( "$1" = "status" ) && ( "$2" = "relay" || "$2" = "forger" || "$2" = "all" || -z "$2" ) && ( -z "$3" ) ]]; then

    if [[ ! -d $data || ! -d $core ]]; then
      echo -e "\n${red}Core not installed. Please install first.${nc}\n"
      exit 1
    fi

    if [ -z "$2" ]; then
      set -- "$1" "all"
    fi

    status $2

  elif [[ ( "$1" = "system" ) && ( "$2" = "info" || -z "$2" ) && ( -z "$3" ) ]]; then

    sysinfo

  elif [[ ( "$1" = "system" ) && ( "$2" = "update" ) && ( -z "$3" ) ]]; then

    sysinfo
    sudo apt update > /dev/null 2>&1
    sysupdate

  elif [[ ( "$1" = "logs" ) && ( "$2" = "relay" || "$2" = "forger" || "$2" = "all" || -z "$2" ) && ( -z "$3" ) ]]; then

    if [ -z "$2" ]; then
      set -- "$1" "all"
    fi

    logs $2

  elif [[ ( "$1" = "secret" ) && ( ( "$2" = "set" && ! -z "${14}" && -z "${15}" ) || ( "$2" = "clear" && -z "$3" ) ) ]]; then

    if [[ ! -d $data || ! -d $core ]]; then
      echo -e "\n${red}Core not installed. Please install first.${nc}\n"
      exit 1
    fi

    secret $2 $3 $4 $5 $6 $7 $8 $9 ${10} ${11} ${12} ${13} ${14}

    echo -e "\n${green}All Done!${nc}\n"

  elif [[ ( "$1" = "snapshot" ) && ( "$2" = "create" || "$2" = "restore" ) && ( -z "$3" ) ]]; then

    if [[ ! -d $data || ! -d $core ]]; then
      echo -e "\n${red}Core not installed. Please install first.${nc}\n"
      exit 1
    fi

    if [[ "$2" = "restore" && ! -f $HOME/snapshots/${name}_$network ]]; then
      echo -e "\n${red}File $HOME/snapshots/${name}_$network Not Found!${nc}\n"
      exit 1
    fi

    sysinfo
    snapshot $2 &

    echo -ne "${cyan}Processing Snapshot...  ${red}"

    while [ -d /proc/$! ]; do
      printf "\b${sp:i++%${#sp}:1}" && sleep .1
    done

    echo -e "\b${green}Done${nc}\n"

  elif [[ ( "$1" = "update" ) && ( "$2" = "self" ) && ( -z "$3" ) ]]; then

    git pull

  elif [[ ( "$1" = "remove" ) && ( "$2" = "self" ) && ( -z "$3" ) ]]; then

    selfremove

    echo -e "\n${green}All Done!${nc}\n"

  elif [[ ( "$1" = "update" ) && ( "$2" = "check" || -z "$2" ) && ( -z "$3" ) ]]; then

    update_info

  else

    wrong_arguments

  fi

  trap cleanup SIGINT SIGTERM SIGKILL

}

main "$@"
