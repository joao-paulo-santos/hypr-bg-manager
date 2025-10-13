#!/bin/sh

# Default background directory
BG_DIR="$HOME/wallpapers"
# Default image source type (pw = per workspace, global = shared folder)
IMG_SOURCE="pw"
# Default trigger type (socket = workspace change, timer = time interval)
TRIGGER_TYPE="socket"
TIMER_INTERVAL=30
# Default wallpaper service
SERVICE="swww"
# Extra flags for the service
EXTRA_FLAGS=""

# Parse command line arguments
while [ $# -gt 0 ]; do
  case $1 in
    -d|--dir)
      BG_DIR="$2"
      shift 2
      ;;
    -i|--img)
      IMG_SOURCE="$2"
      if [ "$IMG_SOURCE" != "pw" ] && [ "$IMG_SOURCE" != "global" ]; then
        echo "Error: Image source must be 'pw' (per workspace) or 'global'" >&2
        exit 1
      fi
      shift 2
      ;;
    -t|--trigger)
      TRIGGER_TYPE="$2"
      if [ "$TRIGGER_TYPE" != "socket" ] && [ "$TRIGGER_TYPE" != "timer" ] && [ "$TRIGGER_TYPE" != "both" ]; then
        echo "Error: Trigger type must be 'socket' (workspace change), 'timer' (time interval), or 'both'" >&2
        exit 1
      fi
      shift 2
      ;;
    -s|--service)
      SERVICE="$2"
      if [ "$SERVICE" != "swww" ] && [ "$SERVICE" != "hyprpaper" ] && [ "$SERVICE" != "swaybg" ] && [ "$SERVICE" != "mpvpaper" ]; then
        echo "Error: Service must be 'swww', 'hyprpaper', 'swaybg', or 'mpvpaper'" >&2
        exit 1
      fi
      shift 2
      ;;
    -e|--extra-flags)
      EXTRA_FLAGS="$2"
      shift 2
      ;;
    --interval)
      TIMER_INTERVAL="$2"
      if ! echo "$TIMER_INTERVAL" | grep -qE '^[0-9]+$' || [ "$TIMER_INTERVAL" -lt 1 ]; then
        echo "Error: Timer interval must be a positive integer (seconds)" >&2
        exit 1
      fi
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [OPTIONS]"
      echo "Options:"
      echo "  -d, --dir DIR        Set wallpaper directory (default: $HOME/.config/hypr/bg)"
      echo "  -i, --img TYPE       Set image source type:"
      echo "                       'pw' = random per workspace (default)"
      echo "                       'global' = random from shared folder"
      echo "  -t, --trigger TYPE   Set trigger type:"
      echo "                       'socket' = on workspace change (default)"
      echo "                       'timer' = on time interval"
      echo "                       'both' = workspace change + timer"
      echo "  -s, --service SVC    Set wallpaper service:"
      echo "                       'swww' = swww (default)"
      echo "                       'hyprpaper' = hyprpaper"
      echo "                       'swaybg' = swaybg"
      echo "                       'mpvpaper' = mpvpaper"
      echo "  -e, --extra-flags    Extra flags to pass to the service"
      echo "  --interval SECS      Timer interval in seconds (default: 30, only for timer/both mode)"
      echo "  -h, --help           Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Use -h or --help for usage information" >&2
      exit 1
      ;;
  esac
done

# Get supported file formats based on service
get_supported_formats() {
  case "$SERVICE" in
    swww)
      echo "\( -iname \"*.png\" -o -iname \"*.jpg\" -o -iname \"*.jpeg\" -o -iname \"*.webp\" -o -iname \"*.bmp\" -o -iname \"*.gif\" \)"
      ;;
    hyprpaper)
      echo "\( -iname \"*.png\" -o -iname \"*.jpg\" -o -iname \"*.jpeg\" -o -iname \"*.webp\" -o -iname \"*.bmp\" \)"
      ;;
    swaybg)
      echo "\( -iname \"*.png\" -o -iname \"*.jpg\" -o -iname \"*.jpeg\" -o -iname \"*.webp\" -o -iname \"*.bmp\" \)"
      ;;
    mpvpaper)
      echo "\( -iname \"*.mp4\" -o -iname \"*.mkv\" -o -iname \"*.webm\" -o -iname \"*.gif\" -o -iname \"*.png\" -o -iname \"*.jpg\" -o -iname \"*.jpeg\" \)"
      ;;
  esac
}

# Set wallpaper using the specified service
set_wallpaper_with_service() {
  wallpaper_path="$1"
  output_name="$2"
  
  case "$SERVICE" in
    swww)
      if [ -n "$EXTRA_FLAGS" ]; then
        swww img -o "$output_name" $EXTRA_FLAGS "$wallpaper_path"
      else
        swww img -o "$output_name" -t none --transition-duration 0.1 --transition-fps 120 "$wallpaper_path"
      fi
      ;;
    hyprpaper)
      # Hyprpaper requires preloading and then setting
      hyprctl hyprpaper preload "$wallpaper_path"
      hyprctl hyprpaper wallpaper "$output_name,$wallpaper_path"
      if [ -n "$EXTRA_FLAGS" ]; then
        hyprctl hyprpaper $EXTRA_FLAGS
      fi
      ;;
    swaybg)
      # Kill existing swaybg instances for this output
      pkill -f "swaybg.*$output_name" 2>/dev/null
      if [ -n "$EXTRA_FLAGS" ]; then
        swaybg -o "$output_name" -i "$wallpaper_path" $EXTRA_FLAGS &
      else
        swaybg -o "$output_name" -i "$wallpaper_path" -m fill &
      fi
      ;;
    mpvpaper)
      # Kill existing mpvpaper instances for this output
      pkill -f "mpvpaper.*$output_name" 2>/dev/null
      if [ -n "$EXTRA_FLAGS" ]; then
        mpvpaper -o "$output_name" $EXTRA_FLAGS "$wallpaper_path" &
      else
        mpvpaper -o "$output_name" "$wallpaper_path" &
      fi
      ;;
  esac
}

# Get the current monitor for the active workspace
get_current_monitor() {
  # Get current monitor from hyprctl (fast)
  monitor_name=$(hyprctl activeworkspace | grep -o 'on monitor [^:]*' | cut -d' ' -f3)
  echo "$monitor_name"
}

# Get current workspace name
get_current_workspace() {
  workspace_name=$(hyprctl activeworkspace | grep -o 'workspace [^ ]*' | cut -d' ' -f2)
  echo "$workspace_name"
}

# Set wallpaper for current workspace and monitor
set_current_wallpaper() {
  if [ "$IMG_SOURCE" = "global" ]; then
    workspace_name="shared"
  else
    workspace_name=$(get_current_workspace)
  fi
  
  wallpaper=$(get_random_wallpaper "$workspace_name")
  
  if [ $? -eq 0 ] && [ -n "$wallpaper" ]; then
    output_name=$(get_current_monitor)
    set_wallpaper_with_service "$wallpaper" "$output_name"
    echo "Set wallpaper for workspace '$workspace_name' using $SERVICE: $wallpaper"
  else
    echo "Failed to set wallpaper for workspace '$workspace_name'" >&2
  fi
}

get_random_wallpaper() {
  workspace_name=$1
  
  if [ "$IMG_SOURCE" = "global" ]; then
    # Global mode: always use shared folder
    workspace_bg_dir="$BG_DIR/shared"
  else
    # Per workspace mode (default)
    workspace_bg_dir="$BG_DIR/$workspace_name"
    
    # Check if directory exists
    if [ ! -d "$workspace_bg_dir" ]; then
      # Try fallback to shared if workspace-specific folder doesn't exist
      workspace_bg_dir="$BG_DIR/shared"
      if [ ! -d "$workspace_bg_dir" ]; then
        echo "Warning: No wallpaper directory found for workspace '$workspace_name' or shared fallback" >&2
        return 1
      fi
    fi
  fi
  
  # Check if the selected directory exists
  if [ ! -d "$workspace_bg_dir" ]; then
    echo "Warning: Directory '$workspace_bg_dir' does not exist" >&2
    return 1
  fi
  
  # Get all image files (formats based on service)
  format_filter=$(get_supported_formats)
  wallpapers=$(eval "find \"$workspace_bg_dir\" -type f $format_filter" 2>/dev/null)
  
  if [ -z "$wallpapers" ]; then
    echo "Warning: No wallpapers found in $workspace_bg_dir" >&2
    return 1
  fi
  
  # Select random wallpaper
  wallpaper_count=$(echo "$wallpapers" | wc -l)
  random_index=$(($(od -An -N2 -tu2 /dev/urandom) % wallpaper_count + 1))
  selected_wallpaper=$(echo "$wallpapers" | sed -n "${random_index}p")
  
  echo "$selected_wallpaper"
}

handle() {
  case $1 in
    workspacev2*)
      # Only handle workspacev2 events to avoid duplicates
      # Extract workspace name from workspacev2>>1,1 format - extract first number after >>
      workspace_name=$(echo "$1" | sed 's/workspacev2>>//' | cut -d',' -f1)
      
      # Skip if workspace name is empty
      if [ -z "$workspace_name" ]; then
        return
      fi
      
      # Get random wallpaper for this workspace
      wallpaper=$(get_random_wallpaper "$workspace_name")
      
      if [ $? -eq 0 ] && [ -n "$wallpaper" ]; then
        # Get the correct output name
        output_name=$(get_current_monitor)
        set_wallpaper_with_service "$wallpaper" "$output_name"
        echo "Set wallpaper for workspace '$workspace_name' using $SERVICE: $wallpaper"
      else
        echo "Failed to set wallpaper for workspace '$workspace_name'" >&2
      fi
      ;;
  esac
}

# Main execution logic
if [ "$TRIGGER_TYPE" = "timer" ]; then
  echo "Starting timer-based wallpaper changes (interval: ${TIMER_INTERVAL}s)"
  while true; do
    set_current_wallpaper
    sleep "$TIMER_INTERVAL"
  done
elif [ "$TRIGGER_TYPE" = "both" ]; then
  echo "Starting both workspace change and timer-based wallpaper changes (interval: ${TIMER_INTERVAL}s)"
  
  # Start timer in background
  (
    while true; do
      sleep "$TIMER_INTERVAL"
      set_current_wallpaper
    done
  ) &
  TIMER_PID=$!
  
  # Handle cleanup on exit
  trap 'kill $TIMER_PID 2>/dev/null; exit' INT TERM EXIT
  
  # Listen to workspace changes in foreground
  socat -U - UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | while read -r line; do handle "$line"; done
else
  echo "Starting socket-based wallpaper changes (on workspace change)"
  socat -U - UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | while read -r line; do handle "$line"; done
fi