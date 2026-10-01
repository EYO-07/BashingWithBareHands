# BEGIN : Toolbox/_i3blocks_tools.sh

# ... intended to be used with i3blocks scripts 

# -- Color helpers 
__i3blocks_echo() {
    printf '%s\n' "$1"
    printf '\n'
    printf '#FFFFFF\n'
}
__i3blocks_echo_green() {
    printf '%s\n' "$1"
    printf '\n'
    printf '#00FF00\n'
}
__i3blocks_echo_yellow() {
    printf '%s\n' "$1"
    printf '\n'
    printf '#ffdc00\n'
}
__i3blocks_echo_red() {
    printf '%s\n' "$1"
    printf '\n'
    printf '#ff4136\n'
}
# -- GPU (NVIDIA) 
function __i3blocks_get_nvidia_gpu {
    local warn="${1:-70}" crit="${2:-90}"
    local temp usage fan
    read -r temp usage fan <<< "$(
        nvidia-smi --query-gpu=temperature.gpu,utilization.gpu,fan.speed \
                   --format=csv,noheader,nounits 2>/dev/null | tr ',' ' '
    )"
    [[ -z "$temp" ]] && { __i3blocks_echo_yellow "GPU: N/A"; return 0; }
    local text="GPU ${temp}°C ${usage}% fan:${fan}%"
    if   (( temp >= crit )); then __i3blocks_echo_red    "$text"
    elif (( temp >= warn )); then __i3blocks_echo_yellow "$text"
    else                          __i3blocks_echo        "$text"
    fi
}
# -- CPU
function __i3blocks_get_cpu {
    local warn="${1:-70}" crit="${2:-90}"
    # 1. Fast Temperature Check (Uses coretemp or Tctl via sensors)
    local temp
    temp=$(sensors 2>/dev/null | grep -E 'Core 0|Tctl' | head -n1 | awk -F'+' '{print $2}' | cut -d'.' -f1)
    # Fallback if cut fails on certain sensor outputs
    [[ -z "$temp" ]] && temp=$(sensors 2>/dev/null | grep -E 'Core 0|Tctl' | head -n1 | awk -F'+' '{print $2}' | cut -d' ' -f1)
    # 2. Fast Instant CPU Usage using /proc/stat (No sleep! Relies on i3blocks interval)
    # We use awk to grab a quick instant metric or load average alternative.
    local usage=0
    if [[ -r /proc/stat ]]; then
        # Read current CPU ticks and calculate overall idle vs total
        usage=$(awk '/^cpu / {
            idle = $5 + $6;
            total = $2 + $3 + $4 + $5 + $6 + $7 + $8;
            print total, idle;
        }' /proc/stat)
        # To avoid sleep, a common trick for status bars is using 1-minute load average 
        # or scaling from top, but if you want exact instant usage:
        read -r total1 idle1 <<< "$usage"
        # Quick micro-sleep or read from a cached file if absolute delta is needed, 
        # OR fallback to uptime/loadavg which is instantaneous:
        local load
        load=$(awk '{print $1}' /proc/loadavg) # 1-min load average
        # Alternatively, use top batch mode instant query:
        usage=$(top -b -n1 2>/dev/null | awk '/^%Cpu\(s\):/ {print int(100 - $8)}')
    fi
    [[ -z "$usage" ]] && usage=0

    # 3. Fan speed check
    local fan
    fan=$(sensors 2>/dev/null | grep 'fan1' | head -n1 | awk '{print $3}')
    [[ -z "$fan" ]] && fan="?"
    local text="CPU ${temp:-?}°C ${usage}% fan:${fan}"
    # Color coding logic
    if   (( ${temp:-0} >= crit )); then __i3blocks_echo_red    "$text"
    elif (( ${temp:-0} >= warn )); then __i3blocks_echo_yellow "$text"
    else                                __i3blocks_echo        "$text"
    fi
}
# -- Memory 
function __i3blocks_get_memory {
    local warn="${1:-80}" crit="${2:-95}"
    local pct
    pct=$(free | awk '/^Mem:/{printf "%d", ($3/$2)*100}')
    local text="RAM ${pct}%"
    if   (( pct >= crit )); then __i3blocks_echo_red    "$text"
    elif (( pct >= warn )); then __i3blocks_echo_yellow "$text"
    else                          __i3blocks_echo       "$text"
    fi
}
# -- Root disk 
function __i3blocks_get_root_disk {
    local warn="${1:-80}" crit="${2:-95}"
    local pct
    pct=$(df --output=pcent / 2>/dev/null | tail -1 | tr -dc '0-9')
    local text="DISK ${pct}%"
    if   (( pct >= crit )); then __i3blocks_echo_red    "$text"
    elif (( pct >= warn )); then __i3blocks_echo_yellow "$text"
    else                          __i3blocks_echo       "$text"
    fi
}
# -- Universal Connection Checker (using nmcli)
# Usage: __i3blocks_get_connection <type_or_name> [icon_on] [icon_off]
# Categories: wifi, ether (or ethernet), vpn, or exact connection/interface name
function __i3blocks_get_connection {
    local target="${1:-}"
    local icon_on="${2:-🔗}"
    local icon_off="${3:-off}"
    [[ -z "$target" ]] && { __i3blocks_echo_yellow "$icon_off"; return 0; }
    # Ensure nmcli is available
    if ! command -v nmcli &>/dev/null; then
        __i3blocks_echo_yellow "$icon_off (no nmcli)"
        return 1
    fi
    local active_conn=""
    local active_type=""
    local active_device=""
    # Get active connections: format is TYPE:NAME:DEVICE
    while IFS=':' read -r type name device; do
        [[ -z "$type" ]] && continue
        # Match based on target category or specific name
        case "$target" in
            wifi|wlan|wireless)
                if [[ "$type" =~ ^(wifi|wireless) ]]; then
                    active_conn="$name"
                    active_device="$device"
                    break
                fi
                ;;
            ether|eth|wired)
                if [[ "$type" =~ ^(ethernet|wired) ]]; then
                    active_conn="$name"
                    active_device="$device"
                    break
                fi
                ;;
            vpn)
                if [[ "$type" =~ ^(vpn|wireguard) ]]; then
                    active_conn="$name"
                    active_device="$device"
                    break
                fi
                ;;
            *)
                # Match by exact connection name or device name
                if [[ "$name" == "$target" ]] || [[ "$device" == "$target" ]]; then
                    active_conn="$name"
                    active_device="$device"
                    break
                fi
                ;;
        esac
    done < <(nmcli -t -f TYPE,NAME,DEVICE connection show --active 2>/dev/null)
    if [[ -n "$active_conn" ]]; then
        # Optional: you can show the connection name ($active_conn) or device ($active_device)
        __i3blocks_echo "$icon_on $active_conn"
        return 0
    fi
    __i3blocks_echo_yellow "$icon_off"
}
# -- Audio Volume (supports pamixer or amixer)
function __i3blocks_get_audio {
    local vol="?" mute="false"
    if command -v pamixer &>/dev/null; then
        vol=$(pamixer --get-volume 2>/dev/null)
        mute=$(pamixer --get-mute 2>/dev/null)
        [[ "$mute" == "true" ]] && { __i3blocks_echo_yellow "Muted"; return 0; }
    elif command -v amixer &>/dev/null; then
        vol=$(amixer get Master 2>/dev/null | grep -oE '[0-9]+%' | head -1 | tr -d '%')
        local stat=$(amixer get Master 2>/dev/null | grep -oE '\[(off|on)\]' | head -1)
        [[ "$stat" == "[off]" ]] && { __i3blocks_echo_yellow "Muted"; return 0; }
    fi
    __i3blocks_echo "Vol. ${vol}%"
}
# -- Keyboard Layout
function __i3blocks_get_kb_layout {
    local layout="?"
    if command -v setxkbmap &>/dev/null; then
        layout=$(setxkbmap -query 2>/dev/null | awk '/layout:/ {print $2}')
    elif command -v localectl &>/dev/null; then
        layout=$(localectl status 2>/dev/null | awk '/X11 Layout/ {print $3}')
    fi
    __i3blocks_echo "${layout^^}"
}
# -- Date & Time
function __i3blocks_get_datetime {
    local fmt="${1:-%Y-%m-%d %H:%M}"
    local dt
    dt=$(date +"$fmt")
    __i3blocks_echo "$dt"
}
# -- Mounted Extra Partitions (Using findmnt concept)
# -- Mounted Extra Partitions with Optional Exclusions
# Usage: __i3blocks_get_mounted_partitions "ESP" "OS" "Recovery"
function __i3blocks_get_mounted_partitions {
    local -a exclusions=("$@")
    # Extract raw, unique labels from mounted filesystems, ignoring empty ones
    local labels
    labels=$(findmnt -n -r -o LABEL 2>/dev/null | grep -v '^$' | sort -u)
    [[ -z "$labels" ]] && { printf ""; return 0; }
    # Filter out any labels matching the optional arguments passed to the function
    if (( ${#exclusions[@]} > 0 )); then
        local exclude_pattern
        exclude_pattern=$(printf '^%s$\n' "${exclusions[@]}" | paste -sd '|' -)
        labels=$(echo "$labels" | grep -vE "$exclude_pattern")
    fi
    # If everything was excluded, return empty (hides block)
    [[ -z "$labels" ]] && { printf ""; return 0; }
    # Clean up and join multiple labels with commas for a single-line status bar item
    local formatted_labels
    formatted_labels=$(echo "$labels" | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g')    
    __i3blocks_echo_green "[ $formatted_labels ]"
}

# === guides 

#!/bin/bash
#source _i3blocks_tools.sh 
# example :
#__i3blocks_get_nvidia_gpu 75 90

### BEGIN ~/.config/i3blocks/config 
# Global properties
# If no command is specified in a block, it looks here (optional)
# command=~/.config/i3blocks/scripts/%s
#markup=pango
#separator=true
#separator_block_width=15

#markup=pango
#separator=true
#separator_block_width=15

#[cpu]
#command=~/.config/i3blocks/cpu.sh
#interval=10

#[gpu]
#command=~/.config/i3blocks/gpu.sh
#interval=10

#[memory]
#command=~/.config/i3blocks/mem.sh
#interval=15

#[disk]
#command=~/.config/i3blocks/disk.sh
#interval=30

#[partitions]
#command=~/.config/i3blocks/mounted_part.sh
#interval=10

#[keyboard]
#command=~/.config/i3blocks/kb.sh
#interval=10

#[time]
#command=~/.config/i3blocks/time.sh
#interval=5

#[volume]
#command=~/.config/i3blocks/volume.sh
#interval=5
#signal=1

### END 

# END 