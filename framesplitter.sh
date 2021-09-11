#!/bin/bash

### Menu Constants
menu_title='Available Operations'
menu_prompt='Select Operation'
menu_invalid_operation='Invalid Operation Selected'
menu_options=(
  'Get Frame Count' #1
  'Get Frames per Second' #2
  'Split Frames' #3
)

### File Processing Constants
processing_read_prompt='Video File Path'
processing_bad_file_path='Invalid File Path'

### Global Variables
file_path=''

### Read File Name
file_path_read()
{
  read -p "${processing_read_prompt}: " -r file_path
}

file_path_prompt()
{
  first_attempt=true
  while [ ! -f "$file_path" ]; do
    if ! $first_attempt ; then
      echo "$processing_bad_file_path"
    fi
    file_path_read
    first_attempt=false
  done
}

### Video Processing
get_frame_count()
{
  frame_count=$(ffprobe -v error -select_streams v:0 -count_packets -show_entries stream=nb_read_packets -of csv=p=0 "$file_path")
  echo "Frame Count: $frame_count"
}

get_frames_per_second()
{
  frames_per_second=$(get_frames_per_second_raw)
  echo "Frame Rate: $frames_per_second Frames per Second"
}

get_frames_per_second_raw()
{
  ffmpeg -i "$file_path" 2>&1 | sed -n "s/.*, \(.*\) fp.*/\1/p"
}

split_frames()
{
  file_directory=$(dirname "$file_path")
  file_name=$(basename -- "$file_path")
  file_name="${file_name%.*}"

  read -p "Frames per Second: " -r frames_per_second_requested

  frames_per_second=$(get_frames_per_second_raw)
  collect_frequency=$((frames_per_second / frames_per_second_requested))

  original_directory=$(pwd)
  cd "$file_directory" || exit
  ffmpeg -i "$file_path" -vf "select=not(mod(n\,$collect_frequency))"  "$file_name%03d.jpg" -vsync vfr -hide_banner -loglevel error
  # shellcheck disable=SC2164
  cd "$original_directory"

  echo "Saved Files to: $file_directory"
}

### Select Menu
show_menu() {
  echo "$menu_title"

  PS3="$menu_prompt: "
  # shellcheck disable=SC2034
  select operation in "${menu_options[@]}" 'Quit'; do
      case "$REPLY" in

          1)
            get_frame_count
            ;;
          2)
            get_frames_per_second
            ;;
          3)
            split_frames
            ;;
          $((${#menu_options[@]}+1)))
            exit
            ;;
          *)
            echo "$menu_invalid_operation"
            continue
            ;;

      esac
  done
}

### Run Service
file_path_prompt
show_menu
