#!/usr/bin/env bash

PREV_TOTAL=0
PREV_IDLE=0

while true; do
  # Calculate CPU Usage
  read -r cpu user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat
  total=$((user+nice+system+idle+iowait+irq+softirq+steal))
  idl=$((idle+iowait))
  diff_total=$((total-PREV_TOTAL))
  diff_idle=$((idl-PREV_IDLE))
  if [ $diff_total -eq 0 ]; then diff_total=1; fi
  cpu_usage=$((100*(diff_total-diff_idle)/diff_total))
  PREV_TOTAL=$total
  PREV_IDLE=$idl

  # Calculate RAM Usage
  while read -r name value unit; do
    if [ "$name" = "MemTotal:" ]; then mem_total=$value; fi
    if [ "$name" = "MemAvailable:" ]; then mem_avail=$value; fi
  done < /proc/meminfo
  mem_usage=$((100*(mem_total-mem_avail)/mem_total))

  # Calculate GPU Usage
  gpu_usage=0
  for f in /sys/class/drm/card*/device/gpu_busy_percent; do
    if [ -f "$f" ]; then
      read -r gpu_usage < "$f"
      break
    fi
  done

  echo "$cpu_usage $mem_usage $gpu_usage"
  
  # Sleep for 2 seconds to reduce background CPU overhead
  sleep 2
done
