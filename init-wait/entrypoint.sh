#!/bin/sh

INTFS=${1:-1}
SLEEP=${2:-0}

int_calc () 
{
    index=0
    for i in $(ls -1v /sys/class/net/ | grep 'eth\|ens\|eno\|^e[0-9]'); do
      let index=index+1
    done
    MYINT=$index
}

int_calc

echo "Waiting for all $INTFS interfaces to be connected"
while [ "$MYINT" -lt "$INTFS" ]; do
  echo "Connected $MYINT interfaces out of $INTFS"
  sleep 1
  int_calc
done

echo "Sleeping $SLEEP seconds before boot"
sleep $SLEEP
