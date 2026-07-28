# BEGIN : ~/Toolbox/screenshot_tools.sh
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -- dependencies
# 1. scrot 
# 2. xrandr ~ x11 environment

# -- description
function tools {
    source "$_SCRIPT_DIR/_codex.sh"
    local width=7
    toolbox_title "Screeshot Tools"
    info_echo "... there is a delay of 5 seconds before taking the shot."
    toolbox_item "tools" "print this ..." $width
    toolbox_item "takeScreenshot <MONITOR_NUMBER>" "run without arguments to see the monitor number" $width
    toolbox_item "takeAppshot" "take screenshot of focused application" $width
    toolbox_endl
    _codex_unset
}
tools

# -- implementation
function takeScreenshot {
    source "$_SCRIPT_DIR/_codex.sh"
    if [ "$#" -eq 0 ]; then 
        xrandr --listmonitors
        echo "Usage: takeScreenshot <MONITOR_NUMBER>"
        _codex_unset
        return 0
    fi
    if [ "$#" -eq 1 ]; then 
        mkdir -p "$HOME/Pictures/Screenshots"
        scrot -d 5 --monitor "$1" --format "png" --file "$HOME/Pictures/Screenshots/ss_$1_$(date +%s).png"
        _codex_unset
        return 0
    fi
    echo "Usage: takeScreenshot <MONITOR_NUMBER>"
    _codex_unset
}
function takeAppshot {
    source "$_SCRIPT_DIR/_codex.sh"
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