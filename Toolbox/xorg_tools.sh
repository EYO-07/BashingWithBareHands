# BEGIN : Toolbox/xorg_tools.sh 
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# -- dependencies
# 1. using xorg as graphical server 

# -- description 
function tools {
    source "$_SCRIPT_DIR/_codex.sh"
    toolbox_title "X11/XOrg Tools"
    toolbox_item "tools" "show this ..."
    toolbox_item "inv" "show helpful built-in commands"
    toolbox_item "disableScreenSaver" "disable the screen saver"
    toolbox_item "enableScreenSaver" "enable(resets) the screen saver"
    toolbox_endl
    _codex_unset
}
tools
function inv {
    source "$_SCRIPT_DIR/_codex.sh"
    inventory_title "X11/XOrg {Linux Graphical Server}"
    inventory_item "xset -q" "query power mgmt, DPMS, and blanking status"
    inventory_item "xrandr -q" "list connected monitors and resolutions"
    inventory_item "xwininfo" "click a window to see geometry/ID"
    inventory_item "xprop" "click a window to see properties (PID, Class)"
    inventory_item "xlsclients -l" "list all running X11 clients"   
    inventory_endl
    _codex_unset
}

# -- implementation 
function disableScreenSaver {
    source "$_SCRIPT_DIR/_codex.sh"
    # Check if X11 is available
    if [[ -z "$DISPLAY" ]]; then
        crit_echo "Error: DISPLAY variable is not set. Are you running in X11?"
        return 1
    fi
    # 1. Disable software screen blanking (timeout = 0)
    xset s off
    # 2. Disable hardware DPMS (Energy Star) features
    xset -dpms
    # 3. Ensure video device is not blanked even if screensaver triggers
    xset s noblank
    if [[ $? -eq 0 ]]; then
        warn_echo "Screen saver and DPMS disabled successfully."
        return 0
    else
        crit_echo "Failed to disable screen saver settings."
        return 1
    fi
    _codex_unset
}
function enableScreenSaver {
    source "$_SCRIPT_DIR/_codex.sh"
    # Check if X11 is available
    if [[ -z "$DISPLAY" ]]; then
        crit_echo "Error: DISPLAY variable is not set. Are you running in X11?"
        return 1
    fi
    # 1. Reset screen saver to server defaults (usually timeout=600, cycle=600)
    xset s default
    # 2. Re-enable DPMS features (restores default timeouts)
    xset +dpms
    # 3. Restore default blanking preference
    xset s blank
    if [[ $? -eq 0 ]]; then
        info_echo "Screen saver and DPMS reset to defaults."
        return 0
    else
        crit_echo "Failed to enable screen saver settings."
        return 1
    fi
    _codex_unset
}

# END   