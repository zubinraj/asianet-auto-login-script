Asianet Auto Login Script
=========================
Copyright (c) 2009 Anoop John, Prasad S. R. (www.zyxware.com)

Modified by: Zubin Raj

The script will automatically connect to Asianet Dataline without having to sign in via the browser creating an always connected connection as in an unlimited connection.

I use this from a Raspberry Pi box.

Usage
=====

Add an entry to the crontab. For example, the below entry in crontab will run the script every 4 minutes.

eg: */4 * * * * ~/.config/asianet-auto-login-cron.sh


Features
========
- Automatically connect to Asianet Dataline without having to sign in via the browser.
- The script will keep the connection alive.
- The script will automatically reconnect if connection breaks because of a power failure or a line problem.
