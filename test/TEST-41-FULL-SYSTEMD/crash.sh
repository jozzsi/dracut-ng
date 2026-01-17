#!/bin/bash
# In POSIX sh, ulimit -c is undefined. [SC3045], so we use bash here

# crash inside the initramfs (before switch_root)

# unlimited coredump size
ulimit -c unlimited

# start a process, so that we can crash it
bash -c 'while true; do echo "Looping forever..."; sleep 5; done' > /dev/null 2>&1 &

# save the process PID
PID=$!

# send the SIGABRT (Abort) signal to crash the process
kill -6 "$PID"

# Loop waiting for that $PID to disappear
while ps -p "$PID" > /dev/null; do
    sleep 1
done
