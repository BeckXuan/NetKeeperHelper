#!/usr/bin/sh
_kill(){
  local PID=$(ps -ef|grep $1|grep -v grep|awk '{print $2}')
  if [ -n "$PID" ]
  then
    echo "$1 is running. Try killing it!"
    for pid in $PID
    do
      pstree -p $pid| awk -F "[()]" '{print $2}'| xargs kill -15 2>/dev/null
    done
    sleep 1s
    if [ -n "$(ps -ef|grep $1|grep -v grep)" ]
    then
      echo "Failed to kill $1!"
    else
      echo "Succeeded to kiil $1!"
    fi
  else
    echo "$1 is not running!"
  fi
}
_kill "NetKeeperHelper.sh"
