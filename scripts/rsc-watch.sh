#!/data/data/com.termux/files/usr/bin/bash
# rsc-watch.sh - idle watchdog (install to ~/rsc-watch.sh)
# After a 4-minute startup grace period, checks once a minute for online
# players. After 15 straight minutes with nobody online, sends Ctrl+C to the
# server (clean shutdown and save), closes its screen, and releases the wake lock.
DB=$HOME/Core-Framework/server/inc/sqlite/preservation.db
GRACE=240
IDLE_LIMIT=15
sleep $GRACE
idle=0
while screen -ls | grep -q '\.rsc[[:space:]]'; do
  n=$(sqlite3 "$DB" "select count(*) from players where online=1;" 2>/dev/null)
  if [ "$n" = "0" ]; then idle=$((idle+1)); else idle=0; fi
  if [ "$idle" -ge "$IDLE_LIMIT" ]; then
    screen -S rsc -X stuff $'\003'
    sleep 20
    screen -S rsc -X quit
    break
  fi
  sleep 60
done
termux-wake-unlock
