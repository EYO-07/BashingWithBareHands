# BEGIN : Toolbox/date_tools.sh
# ==============================================================================
# DEPENDENCIES: date, stat, notify-send (libnotify), coreutils, awk
# ==============================================================================

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if ! declare -F "__SCRIPT_SAFE_SOURCE" >/dev/null; then
    __SCRIPT_SAFE_SOURCE() {
        local script_path="${1:-}"
        if [[ -z "$script_path" || ! -f "$script_path" ]]; then
            printf '\033[1;31m✗ Error: Invalid or missing script path for sourcing.\033[0m\n' >&2
            return 1
        fi
        printf '\033[1;33m⚠ Warning: Security core absent. Sourcing without integrity check\033[0m\n' >&2
        # Proceed with standard sourcing
        source "$script_path"
    }
fi

# -- dependencies

# -- description
function tools {
    __SCRIPT_SAFE_SOURCE "$_SCRIPT_DIR/_codex.sh"
    local width=7
    toolbox_title "Date and Time Tools"
    toolbox_item "tools" "print this ..." $width
    toolbox_item "inv" "print built-in commands ..." $width
    toolbox_item "getCurrentDate" "display current day and time" $width
    toolbox_item "calculateTime <file_or_folder>" "time since last mod or creation" $width
    toolbox_item "setTimer" "set a timer in minutes which sends notification" $width
    toolbox_endl
    _codex_unset
}
tools 
function inv {
    __SCRIPT_SAFE_SOURCE "$_SCRIPT_DIR/_codex.sh"
    inventory_title "Date and Time Tools"
    local width=2
    inventory_item 1 "cal" "display a small calendar" $width
    inventory_item 2 "cal -3" "calendar for previous, current and next month" $width
    inventory_endl 
    _codex_unset
    return 0
}

# -- implementation
function getCurrentDate {
    __SCRIPT_SAFE_SOURCE "$_SCRIPT_DIR/_codex.sh"
    # Get system date and time in format: "Weekday, YYYY-MM-DD HH:MM:SS"
    date +"%A, %Y-%m-%d %H:%M:%S" | good_echo
    _codex_unset
}   
function calculateTime {
    __SCRIPT_SAFE_SOURCE "$_SCRIPT_DIR/_codex.sh"    
    # USAGE : calculateTime <file_or_folder>
    if [ -z "$1" ]; then
        ls -a
        warn_echo "Usage: calculateTime <file_or_folder>"
        _codex_unset
        return 0
    fi
    local target="$1"
    if [ ! -e "$target" ]; then
        crit_echo "Error: '$target' not found."
        _codex_unset
        return 1
    fi
    # 1. Get Last Modification Time (mtime)
    local mod_time=$(stat -c '%Y' "$target" 2>/dev/null)
    # 2. Get Creation Time (Birth time)
    # Try to get Birth time (%W). If unavailable (returns 0 or -), fall back to Change time (%Z)
    local birth_time=$(stat -c '%W' "$target" 2>/dev/null)
    if [ "$birth_time" == "0" ] || [ -z "$birth_time" ]; then
        # Fallback to ctime if birth time is not supported by the filesystem/kernel
        birth_time=$(stat -c '%Z' "$target" 2>/dev/null)
        local birth_label="Change Time (Birth unavailable)"
    else
        local birth_label="Creation Time"
    fi
    # Helper to calculate human readable difference
    _human_diff() {
        local start=$1
        local now=$(date +%s)
        local diff=$((now - start))  
        local days=$((diff / 86400))
        local hours=$(((diff % 86400) / 3600))
        local minutes=$(((diff % 3600) / 60))
        local seconds=$((diff % 60))
        local res=""
        [ $days -gt 0 ] && res="${days}d "
        [ $hours -gt 0 ] && res="${res}${hours}h "
        [ $minutes -gt 0 ] && res="${res}${minutes}m "
        res="${res}${seconds}s"
        echo "$res"
    }
    # Output Results
    info_echo "Target: $target"
    local mod_diff=$(_human_diff "$mod_time")
    echo "Last Modified: $mod_diff ago"
    local birth_diff=$(_human_diff "$birth_time")
    echo "$birth_label: $birth_diff ago"
    _codex_unset
    return 0
}   

# alias update_clock_time='timedatectl set-ntp true'

function setTimer {
    local minutes="$1"
    local name="${2:-...}"
    if [[ -z "$minutes" || ! "$minutes" =~ ^[0-9]+$ ]]; then
        echo "Usage: setTimer <minutes> [ <name> ]"
        return 1
    fi
    (
        sleep $((minutes * 60))
        notify-send -u critical -t 0 "Timer" "Timer $name expired! ($minutes min)"
    ) &
    echo "Timer $name set for $minutes minute(s) (PID: $!)"
    return 0
}   

# END