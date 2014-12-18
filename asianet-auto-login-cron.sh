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
# Modified by: Zubin Raj
# 18-Dec-2014 : Removed the loop so this can be run from a cron on Raspberry Pi
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
username='<username>'
password='<password>'

user_agent="Mozilla/5.0 (Windows NT 6.1; WOW64; rv:34.0) Gecko/20100101 Firefox/34.0"
log_folder=~/logfiles
# Default connection time out interval - connection timeout from asianet is 5 minutes, ping slightly before
#ping_interval=290

# Initialize file paths

lock_file=$log_folder/conn_url
log_file=$log_folder/conn.log
debug_log_file=$log_folder/conn.debug.log

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

if [ ! -d $log_folder ]; 
then
  mkdir $log_folder
fi
if [ ! -d $log_folder ]; 
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
	log "Extracting login url by issuing a http request."
    asianet_conn_url=`curl --silent --insecure -L -A "$user_agent" $pathtotestfile|grep 'action='|sed 's/\(.*action="\)\(.*\)">/\2/g'`
    # Save the URL so that we can use the same URL to log out
    log $asianet_conn_url | tee $lock_file
  else
    # Use the saved URL from the file
	log "Using saved URL from the file."
    if [ -f $lock_file ];
    then
      asianet_conn_url=`cat $lock_file`
    else
      log "Using fallback URL: https://mwcp-spg-02.adlkerala.com:8003/index.php"   
      asianet_conn_url='https://mwcp-spg-02.adlkerala.com:8003/index.php'
    fi
  fi
}

#
# Connect to asianet by posting the username and password
#
connect() {
  # Get URL to post data to
  get_asianet_conn_url
  #log "Connecting to $asianet_conn_url"
  # Post data
  curl --silent --insecure -F "auth_user=$username" -F "auth_pass=$password" -F "accept=Login" -A "$user_agent" $asianet_conn_url >> $debug_log
}

#
# Keep the connection alive by posting the keep alive command
#
keep_alive() {
  # Get URL to post data to
  get_asianet_conn_url
  log "Pinging $asianet_conn_url"
  # Post data
  curl --silent --insecure -F "alive=y" -F "auth_user=$username" -A "$user_agent" $asianet_conn_url >> $debug_log
}

#
#-END-FUNCTIONS---------------------------------------------------------

log "Starting.."

# If disconnect, try connecting. If connected, keep alive.
if is_connected;
then
  # If connected then proceed
  log "Already connected."
  keep_alive
else
  log "Not connected, attempting to connect.."
  connect
  if is_connected;
  then
	log "Successfully re-connected."
  else
	log "Could not connect."
  fi
fi




