#!/bin/bash
# ----------------------------------------------------------------------
# Auto login to asianet connection
# Copyright (c) 2009-12 Anoop John, Zyxware Technologies (www.zyxware.com)
# Copyright (c) 2009 Prasad S. R., Zyxware Technologies (www.zyxware.com)
# http://github.com/anoopjohn/Asianet-Auto-Login-Script
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# ----------------------------------------------------------------------
# Debug settings
#
# set to 1|0, 0 will not record curl outputs
debug=0 
# verbose 1|0, 0 will not output to screen
verbose=1

pathtotestfile="http://www.google.co.in"

# Initialize the scirpt settings
#
# A bit unsecure because you have to store passwords here.
# If you can see the script then probably you should be able to see 
# the password as well 
username=<username>
password=<password>

user_agent="Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9.1.5) Gecko/20091102 Firefox/3.5.5"
program_folder=~/logfiles
# Default connection time out interval - connection timeout from asianet is 5 minutes, ping slightly before
ping_interval=290

# Initialize file paths

lock_file=$program_folder/conn_url
log_file=$program_folder/conn.log
debug_log_file=$program_folder/debug.log

# This program requires curl. Test for that
which curl > /dev/null
if [ $? = 1 ];
then
  echo "Please install curl to run this application"
  exit;
fi

# If debug is enabled log all output from the commands 
# else throw to null
if [ $debug -eq 1 ];
then 
  debug_log=$debug_log_file
else
  debug_log=/dev/null
fi

# Create log file folder if not exist

if [ ! -d $program_folder ]; 
then
  mkdir $program_folder
fi
if [ ! -d $program_folder ]; 
then
  echo "Could not create program folder"
  exit
fi

#
#-BEGIN-FUNCTIONS-------------------------------------------------------
#
# Log the actions
log() {
  if [ $verbose -eq 1 ];
  then
    echo $1
  fi
  log_to_file "$1" 
}
 log_to_file() {
  echo `date +"%D %H:%M:%S"` $1 >> $log_file
}
#
#
# Check if the user is already connected to the net
#
is_connected() {
  #if true we should get the content of the file as return value
  curl --connect-timeout 30 --silent --insecure -A "$user_agent" $pathtotestfile | grep google.co.in > /dev/null
  test=`echo $?`
  if [ $test = 0 ];
  then
    return 0
  else
    return 1
  fi
}

#
# Get the connection URL. Asianet cycles this URL. Don't know whether it matters
# So getting it from the html page itself
#
get_asianet_conn_url() {
  # If not connected then try any URL and get the redirection URL
  if ! is_connected;
  then
    # The curl strategy will work only if user is not already connected to the net
    asianet_conn_url=`curl --silent --insecure -L -A "$user_agent" $pathtotestfile|grep 'action='|sed 's/\(.*action="\)\(.*\)">/\2/g'`
    # Save the URL so that we can use the same URL to log out
    log $asianet_conn_url | tee $lock_file
  else
    # Use the saved URL from the file
    if [ -f $lock_file ];
    then
      cat $lock_file
    else
      log_to_file "Using fallback URL: https://mwcp-spg-02.adlkerala.com:8001/"   
      echo https://mwcp-spg-02.adlkerala.com:8001/
    fi
  fi
}

#
# Connect to asianet by posting the username and password
#
connect() {
  # Get URL to post data to
  asianet_conn_url=$(get_asianet_conn_url)
  log "Connecting to $asianet_conn_url"
  # Post data
  curl --silent --insecure -F "auth_user=$username" -F "auth_pass=$password" -F "accept=Login" -A "$user_agent" $asianet_conn_url >> $debug_log
}

#
# Connect to asianet by posting the username and logout command
#
disconnect() {
  # Get URL to post data to
  asianet_conn_url=$(get_asianet_conn_url)
  log "Disconnecting from $asianet_conn_url"
  # Post data
  curl --silent --insecure -F "logout_id=$username" -F "logout=Logout" -A "$user_agent" $asianet_conn_url >> $debug_log
  rm $lock_file 2>/dev/null
}

#
# Keep the connection alive by posting the keep alive command
#
keep_alive() {
  # Get URL to post data to
  asianet_conn_url=$(get_asianet_conn_url)
  log "Pinging $asianet_conn_url"
  # Post data
  curl --silent --insecure -F "alive=y" -F "auth_user=$username" -A "$user_agent" $asianet_conn_url >> $debug_log
}

#
#-END-FUNCTIONS---------------------------------------------------------

log "System started."

# If disconnect, try connecting. If connected, keep alive.
while [ 1 ];
do
	if is_connected;
	then
	  # If connected then proceed
	  keep_alive
	else
	  connect
	  if ! is_connected;
	  then
		log "Could not connect."
	  else
		log "Successfully re-connected."
	  fi  
	fi
  # Sleep ping_interval and ping again
  sleep $ping_interval
done
;;
esac

