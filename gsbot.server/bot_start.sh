#!/bin/bash

FULL_RESTART=$1

echo ""
echo "================"`date`"================"

d=" "
CMD_START="screen -A -m -d -S bot_askme /usr/bin/perl /home/ubuntu/gsbot/gsbot.server/bot_askme.pl 2>/home/ubuntu/gsbot/gsbot.server/bot_askme.error.log"
PID=`ps ax | grep gsbot.server/bot_askme.pl | grep SCREEN | cut -b 1-5`
echo "CURRENT PID=$PID"

if [ ! -z $PID ]
  then
    if [ ! -z $FULL_RESTART ]
      then
        echo -n "Killing process id "$PID" ... "
        kill -9 $PID
        echo "done"
        sleep 2

        echo "Clear all screens ... "
        screen -wipe
        echo "Clearing of all screens DONE"
        sleep 2
        echo ""
        echo -n "Now starting new screen session ... "
        screen -A -m -d -S bot_askme `which perl` /home/ubuntu/gsbot/gsbot.server/bot_askme.pl
        sleep 2
        PID=`ps ax | grep gsbot.server/bot_askme.pl | grep SCREEN | cut -b 1-5`
        echo "done with PID="$PID
      else
        echo "Process $PID is running. Restart NOT needed."
      fi
else
  echo -n "Empty, so start the session ... "
  screen -A -m -d -S bot_askme `which perl` /home/ubuntu/gsbot/gsbot.server/bot_askme.pl
  sleep 2
  PID=`ps ax | grep gsbot.server/bot_askme.pl | grep SCREEN | cut -b 1-5`
  echo "done with PID="$PID
fi

echo "================================================================================"
echo ""
