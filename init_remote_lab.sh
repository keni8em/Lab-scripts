#!/bin/bash

# **************************************************************************** #
# ****************************   DECLARATIONS   ****************************** #
# **************************************************************************** #

script="init_remote_lab.sh"

# Declare the number of mandatory args
echo
while getopts :i:u:h option; do
  case "${option}" in
    i) IP=$OPTARG ;;     # remote server IP address
    u) RUSR=$OPTARG ;;   # remote server remote username
    h) HLPARG=true ;;
    \?) echo "$script: error : invalid argument option -$OPTARG"
        INVARG=true ;;
  esac
done

# script variables
now=$(date +"%y%m%d")
log_dir="$HOME/logs"
mnt_dir="$HOME/remote_sites/$IP"

# *****   END DECLARATIONS   ************************************************* #
# ############################################################################ #


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #


# **************************************************************************** #
# ********************************   HELP   ********************************** #
# **************************************************************************** #

function example {
  echo "--- example: $script -i 192.168.0.1 -u admin"
}

# usage
function usage {
  echo "usage [default]: $script [-i <ip>] [-u <username>] [OPTIONAL ARGS] <none>"
  echo "usage [help]:    $script [-h]"
}

function help {
  echo
  echo $script : HELP && echo
  usage
    echo
    echo "MANDATORY ARGUMENTS:"
    echo "  -i,   The IP address of the remote server for ssh connection"
    echo "  -u,   The admin username login credentials of the remote server"
    echo
    echo "OPTIONAL ARGUMENTS:"
    echo "  -h,   Prints this help"
    echo
  example
  echo
}

# *****   END HELP   ********************************************************* #
# ############################################################################ #


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #


# **************************************************************************** #
# *************************   ARGUMENT VALIDATION   ************************** #
# **************************************************************************** #

# end script if wrong number of arguments passed in
if [ $OPTIND -ne 2 ] && [ $OPTIND -ne 5 ]; then
  echo "$script: error : incorrect # of arguements:parameters passed in"
  echo "--- $script requires 2 arguements with 1 parameter each" && echo
  usage
  example && echo
  exit 128
fi

# display help context and end script
if [ $HLPARG ]; then
  help
  exit 0
fi

# end script if invalid arguements passed in
if [ $INVARG ]; then
  usage
  example && echo
  exit 128
fi

# end script if incorrectly formatted ip address passed in
if ! [[ $IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
  echo "$script: error : invalid ip address [$IP]"
  usage
  example && echo
  exit 128
fi

# *****   END ARGUMENT VALIDATION   ****************************************** #
# ############################################################################ #


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #


# **************************************************************************** #
# ********************************   MAIN   ********************************** #
# **************************************************************************** #

#####! server connection : begin !#####

# system check --- create a log file folder if not already exsits
if [ ! -d "$log_dir" ]; then mkdir "$log_dir"; fi

# start capturing the entire session to a log file
exec &> >(tee $log_dir/.$IP.tmp)

# start banner
clear
echo
echo
echo "#########################################################################"
echo "# ********************************************************************* #"
echo
echo "     STARTING lab session with server : [$RUSR@$IP]                      "
echo "     <use 'exit' or 'logout' to end the session and save a logfile>      "
echo "     start timestamp : $(date)                                           "
echo
echo "# ********************************************************************* #"
echo "#########################################################################"
echo
echo

# establish remote server sshfs and ssh connections
NAME="Connecting to $RUSR@$IP ..."; echo -en "\033]0;$NAME\a"  # provide point of reference for regaining window focus after launching pcmanfm-qt
echo mounting remote server file system ...
mkdir $mnt_dir                            # create a mount folder in local $HOME
( set -x; sshfs $RUSR@$IP:/ $mnt_dir )    # mount remote server filesystem for easy file editing
pcmanfm-qt -n $mnt_dir &> /dev/null       # launch remote filesystem in window manager for quick access
wmctrl -a "Connecting to $RUSR@$IP ..."   # refocus terminal
echo "remote server $RUSR@$IP:/ mounted to $mnt_dir" && echo
echo "connecting to remote server terminal interface ..."
( set -x ; ssh $RUSR@$IP )                # connect to the remote server terminal using ssh

#####! server connection : end !#####



# ############################################################################ #
#                                                                              #
#                ----- MANUAL COMMANDS ON REMOTE SERVER -----                  #
#                ---- LAB WORK IS EXECUTED IN THIS SPACE ----                  #
#                                                                              #
# ############################################################################ #



#####! server disconnect : begin !#####

# Execute after <exit> or <logout> has been entered in to the terminal

# disconnect (unmount) remote server file system and remove all traces from local filesystem
echo "disconnecting remote server filesystem ..."
fusermount -u $mnt_dir && rmdir $mnt_dir

# end banner
echo
echo
echo
echo "#########################################################################"
echo "# ********************************************************************* #"
echo
echo "     ENDING lab session with server : [$RUSR@$IP]                        "
echo "     Log File Saved: $log_dir/$IP.log                                    "
echo "     end timestamp : $(date)                                             "
echo
echo "# ********************************************************************* #"
echo "#########################################################################"
echo
echo

# remove esc charaters and make temp logfile permanent
cat $log_dir/.$IP.tmp | perl -pe 's/\e([^\[\]]|\[.*?[a-zA-Z]|\].*?\a)//g' | col -b >> $log_dir/$IP-$now.log
rm $log_dir/.$IP.tmp    # delete temp log file
pcmanfm-qt -n $log_dir &> /dev/null       # launch log folder in window manager for quick access
#####! server disconnect : end !#####

exit 0
# *****   END MAIN   ********************************************************* #
# ############################################################################ #


# >>>>>---==========---<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #
# :::::   END SCRIPT   ::::::::::::::::::::::::::::::::::::::::::::::::::::::: #
# >>>>>---==========---<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #
