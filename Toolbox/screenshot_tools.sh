# BEGIN : ~/Toolbox/screenshot_tools.sh
# ==============================================================================
# DEPENDENCIES: scrot, xrandr, mkdir, date, coreutils
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

# -- description
function tools {
    __SCRIPT_SAFE_SOURCE "$_SCRIPT_DIR/_codex.sh"
    local width=7
    toolbox_title "Screeshot Tools"
    toolbox_item "tools" "print this ..." $width
    if all_commands_valid "xrandr" "scrot"; then 
        toolbox_item "takeScreenshot <MONITOR_NUMBER>" "run without arguments to see the monitor number" $width
        toolbox_item "takeAppshot" "take screenshot of focused application" $width
    else 
        crit_echo "... those tools require scrot and xorg environment"
    fi
    toolbox_endl
    _codex_unset
}
tools

# -- implementation
function takeScreenshot {
    __SCRIPT_SAFE_SOURCE "$_SCRIPT_DIR/_codex.sh"
    if [ "$#" -eq 0 ]; then 
        xrandr --listmonitors
        echo "Usage: takeScreenshot <MONITOR_NUMBER> [ <delay_seconds> ]"
        _codex_unset
        return 0
    fi
    local monitor_number="$1"
    local seconds="${2:-5}"
    if ! [[ "$seconds" =~ ^[0-9]+$ ]]; then
        echo "Error: delay must be a positive integer (got '$seconds')" >&2
        _codex_unset
        return 1
    fi
    mkdir -p "$HOME/Pictures/Screenshots"
    scrot -d "$seconds" --monitor "$monitor_number" --format "png" \
        --file "$HOME/Pictures/Screenshots/ss_$1_$(date +%s).png"
    _codex_unset
}
function takeAppshot {
    __SCRIPT_SAFE_SOURCE "$_SCRIPT_DIR/_codex.sh"
    # Ensure output directory exists
    mkdir -p "$HOME/Pictures/Screenshots"
    local filename="$HOME/Pictures/Screenshots/app_$(date +%s).png"
    # Inform the user
    echo "Select the application window to capture..."
    # Use scrot with:
    # -u : Capture the currently focused window
    # -d 2 : Delay 2 seconds to allow user to focus the target window
    # -e : Execute command after capture (optional, here we just move it)
    if scrot -u -d 5 "$filename"; then
        echo "Application screenshot saved to: $filename"
    else
        echo "Error: Failed to capture screenshot. Is scrot installed and running in X11?"
        _codex_unset
        return 1
    fi
    _codex_unset
    return 0
}   

# END 