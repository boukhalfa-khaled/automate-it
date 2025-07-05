#!/bin/bash

# ========================================================================
#  Prayer Time Notifier for Linux Terminals
# ------------------------------------------------------------------------
#   Author: Boukhalfa Khaled Islam
#   Description:
#   This script calculates the time remaining until the next Islamic prayer
#   based on pre-downloaded prayer schedules stored in tab-separated `.txt`
#   files for each month.
#
#   $ ./prayer_time.sh
#   Asr 04:39 PM  -01h 24m
#
# Useful For:
#   - Displaying next prayer in status bars like:
#       - `dwmblocks`  (for dwm)
#       - `i3blocks` (for i3wm)
#       - `waybar` (for sway/Wayland)
#       - `polybar` (for bspwm or others)
#
#  Dependencies:
#   - Bash
#   - `awk`, `date` (standard in most Linux systems)
#
#  Tested on:
#   - Arch Linux (dwm setup)
#   - Should work on most POSIX-compliant systems
#
# ========================================================================



PRAYER_DIR="/home/khaled/github/automate-it/prayer_time/Dates"
time_to_minutes() {
 local time_str="$1" 
 local hour minute period
  hour="${time_str:0:2}"
  minute="${time_str:3:2}"
  period="${time_str:6:2}"
  # 10# convert to decimal because 0x is octal
  hour=$((10#$hour))
  minute=$((10#$minute))

  if [ "$period" = "AM" ]; then
      [ "$hour" -eq 12 ] && hour=0
  else
      [ "$hour" -ne 12 ] && hour=$((hour + 12))
  fi
    echo $((hour * 60 + minute))
}

current_date=$(date +%F)
current_day=$(date +%-d) 
current_month=$(date +%B)
current_year=$(date +%Y)
filename="$PRAYER_DIR/${current_month}${current_year}.txt"

if [ ! -f "$filename" ]; then
    echo "Error: Prayer time file '$filename' not found" >&2
    exit 1
fi


line=$(awk -v d="$current_day" '$1 == d { print; exit }' "$filename")
if [ -z "$line" ]; then
    echo "Error: Could not find prayer times for today (day $current_day) in $filename" >&2
    exit 1
fi

IFS=$'\t' read -r -a cols <<< "$line"
prayer_times=("${cols[1]}" "${cols[2]}" "${cols[3]}" "${cols[4]}" "${cols[5]}" "${cols[6]}")
prayer_names=("Fajr" "Sunrise" "Dhuhr" "Asr" "Maghrib" "Isha")
current_time_str=$(date +'%I:%M %p')
current_minutes=$(time_to_minutes "$current_time_str")
next_prayer=""
next_time=""
found=0

for i in {0..5}; do
    prayer_minutes=$(time_to_minutes "${prayer_times[$i]}")
    if [ "$prayer_minutes" -gt "$current_minutes" ]; then
        next_prayer=${prayer_names[$i]}
        next_time=${prayer_times[$i]}
        found=1
        break
    fi
done

# For Fajr
if [ "$found" -eq 0 ]; then
    tomorrow_date=$(date -d tomorrow +%F)
    tomorrow_day=$(date -d tomorrow +%-d)
    tomorrow_month=$(date -d tomorrow +%B)
    tomorrow_year=$(date -d tomorrow +%Y)
    tomorrow_file="$PRAYER_DIR/${tomorrow_month}${tomorrow_year}.txt"
    
    if [ ! -f "$tomorrow_file" ]; then
        echo "Error: Prayer time file '$tomorrow_file' not found" >&2
        exit 1
    fi
    
    tomorrow_line=$(awk -v day="$tomorrow_day" '$1 == day { print; exit }' "$tomorrow_file")
    if [ -z "$tomorrow_line" ]; then
        echo "Error: Could not find prayer times for tomorrow (day $tomorrow_day) in $tomorrow_file" >&2
        exit 1
    fi
    
    IFS=$'\t' read -r -a tomorrow_cols <<< "$tomorrow_line"
    next_prayer="Fajr (tomorrow)"
    next_time=${tomorrow_cols[1]}
    target_string="${tomorrow_date} ${next_time}"
else
    target_string="${current_date} ${next_time}"
fi

current_seconds=$(date +%s)
target_seconds=$(date -d "$target_string" +%s)
time_diff=$((target_seconds - current_seconds))
if [ $time_diff -lt 0 ]; then
    echo "Error: Negative time difference" >&2
    exit 1
fi

hours=$((time_diff / 3600))
minutes=$((((time_diff % 3600) / 60) + 1))

# Output 
printf "$next_prayer $next_time-%02dh %02dm\n" $hours $minutes

