# BEGIN : Toolbox/display_tools.sh 
# ... functions and aliases to manage displays in X(xorg)
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -- dependencies
# 1. xorg, it's a xorg tool.

# -- description 

function tools {
    source "$_SCRIPT_DIR/_codex.sh"
    local width=10
    toolbox_title "Display/Monitors Tools"
    toolbox_item "tools" "print this ..." $width
    toolbox_item "inv" "print built-in commands ..." $width
    toolbox_item "listDisplays" "short list of display monitor names and connection state" $width
    toolbox_item "listConnectedDisplays" "show only connected displays" $width
    toolbox_item "mirrorDisplay <main> <target>" "set secondary display to mirror the main display" $width
    toolbox_item "setProviders <source_provider> <sink_provider>" "set multi-card setup, the source_provider does the hard computing and sink_provider shows the result." $width
    toolbox_item "extendDisplayRight <main> <right>" "dual extended displays mode" $width
    toolbox_item "extendDisplayLeft <main> <left>" "..." $width
    toolbox_item "extendDisplayAbove <main> <above>" "..." $width
    toolbox_item "extendDisplayBelow <main> <below>" "..." $width
    toolbox_endl
    _codex_unset
}
tools 
function inv {
    source "$_SCRIPT_DIR/_codex.sh"
    inventory_title "Display/Monitors Tools"
    local width=5
    inventory_item 1 "xrandr -q" "information about displays from xorg tools" $width
    inventory_item 2 "xrandr --dpi <number>" "set dpi for current monitor (96,120,144,196)" $width
    inventory_endl 
    _codex_unset
    return 0
}

# -- implementation 
function listDisplays {
    source "$_SCRIPT_DIR/_codex.sh"
    # Short list of display monitor names and connection state
    # Dependencies: xrandr (part of x11-xserver-utils)
    if ! command -v xrandr &> /dev/null; then
        color_echo 31 "Error: xrandr command not found. Please install x11-xserver-utils."
        _codex_unset
        return 1
    fi
    # Query xrandr, grep for connection status, and format output
    # Format: "MonitorName: Status"
    echo ""
    xrandr --query | grep -E "connected|disconnected" | awk '{print $1 ": " $2}'
    _codex_unset
    return 0
}
function listConnectedDisplays { 
    source "$_SCRIPT_DIR/_codex.sh"
    # Short list of display monitor names and connection state
    # Dependencies: xrandr (part of x11-xserver-utils)
    if ! command -v xrandr &> /dev/null; then
        color_echo 31 "Error: xrandr command not found. Please install x11-xserver-utils."
        _codex_unset
        return 1
    fi
    # Query xrandr, grep for connection status, and format output
    # Format: "MonitorName: Status"
    echo ""
    xrandr --query | grep " connected" | awk '{print $1 ": " $2}'
    _codex_unset
    return 0
}
function extendDisplayRight {
    source "$_SCRIPT_DIR/_codex.sh"
    if [ "$#" -ne 2 ]; then 
        listConnectedDisplays 
        color_echo 33 "Usage: extendDisplayRight <main_display> <right_display>"
        _codex_unset
        return 1
    fi
    # Capture xrandr output ONCE to avoid multiple slow calls
    local xrandr_output
    xrandr_output=$(xrandr --query)
    # Validate that both monitors are connected
    if ! echo "$xrandr_output" | grep -q "^$1 connected"; then
        color_echo 31 "Error: '$1' is not connected."
        _codex_unset
        return 1
    fi
    if ! echo "$xrandr_output" | grep -q "^$2 connected"; then
        color_echo 31 "Error: '$2' is not connected."
        _codex_unset
        return 1
    fi
    # Apply configuration and check for success
    if xrandr --output "$1" --primary --auto --output "$2" --auto --right-of "$1"; then
        color_echo 32 "Success: Extended '$2' to the right of '$1'."
        _codex_unset
        return 0
    else
        color_echo 31 "Error: Failed to configure displays."
        _codex_unset
        return 1
    fi
}
function extendDisplayLeft {
    source "$_SCRIPT_DIR/_codex.sh"
    if [ "$#" -ne 2 ]; then 
        listConnectedDisplays 
        color_echo 33 "Usage: extendDisplayLeft <main_display> <left_display>"
        _codex_unset
        return 1
    fi
    # Capture xrandr output ONCE to avoid multiple slow calls
    local xrandr_output
    xrandr_output=$(xrandr --query)
    # Validate connections
    if ! echo "$xrandr_output" | grep -q "^$1 connected"; then
        color_echo 31 "Error: '$1' is not connected."
        _codex_unset
        return 1
    fi
    if ! echo "$xrandr_output" | grep -q "^$2 connected"; then
        color_echo 31 "Error: '$2' is not connected."
        _codex_unset
        return 1
    fi
    xrandr --output "$1" --primary --auto --output "$2" --auto --left-of "$1"
    _codex_unset
}
function mirrorDisplay {
    source "$_SCRIPT_DIR/_codex.sh"
    if [ "$#" -ne 2 ]; then 
        listConnectedDisplays 
        color_echo 33 "Usage: mirrorDisplay <source_display> <target_display>"
        _codex_unset
        return 1
    fi
    # Validate connections
    local xrandr_output
    xrandr_output=$(xrandr --query)
    if ! echo "$xrandr_output" | grep -q "^$1 connected"; then
        color_echo 31 "Error: '$1' is not connected."
        _codex_unset
        return 1
    fi
    if ! echo "$xrandr_output" | grep -q "^$2 connected"; then
        color_echo 31 "Error: '$2' is not connected."
        _codex_unset
        return 1
    fi
    xrandr --output "$1" --primary --auto --output "$2" --auto --same-as "$1"
    _codex_unset
}
function extendDisplayAbove {
    source "$_SCRIPT_DIR/_codex.sh"
    if [ "$#" -ne 2 ]; then 
        listConnectedDisplays 
        color_echo 33 "Usage: extendDisplayAbove <main_display> <above_display>"
        _codex_unset
        return 1
    fi
    # Validate connections
    local xrandr_output
    xrandr_output=$(xrandr --query)
    if ! echo "$xrandr_output" | grep -q "^$1 connected"; then
        color_echo 31 "Error: '$1' is not connected."
        _codex_unset
        return 1
    fi
    if ! echo "$xrandr_output" | grep -q "^$2 connected"; then
        color_echo 31 "Error: '$2' is not connected."
        _codex_unset
        return 1
    fi
    xrandr --output "$1" --primary --auto --output "$2" --auto --above "$1"
    _codex_unset
}   
function extendDisplayBelow {
    source "$_SCRIPT_DIR/_codex.sh"
    if [ "$#" -ne 2 ]; then 
        listConnectedDisplays 
        color_echo 33 "Usage: extendDisplayBelow <main_display> <below_display>"
        _codex_unset
        return 1
    fi
    # Validate connections
    local xrandr_output
    xrandr_output=$(xrandr --query)
    if ! echo "$xrandr_output" | grep -q "^$1 connected"; then
        color_echo 31 "Error: '$1' is not connected."
        _codex_unset
        return 1
    fi
    if ! echo "$xrandr_output" | grep -q "^$2 connected"; then
        color_echo 31 "Error: '$2' is not connected."
        _codex_unset
        return 1
    fi
    xrandr --output "$1" --primary --auto --output "$2" --auto --below "$1"
    _codex_unset
}   
function setProviders {
    source "$_SCRIPT_DIR/_codex.sh"
    # Sets the provider output source to enable multi-GPU output
    # Usage: setProviders <source_name> <sink_name>
    # Example: setProviders NVIDIA-0 modesetting    
    if [ "$#" -ne 2 ]; then 
        color_echo 33 "--- Available Providers ---"
        xrandr --listproviders
        echo ""
        color_echo 33 "USAGE: setProviders <source_provider> <sink_provider>"
        color_echo 36 "TIP: Use the 'name' field from the list above (e.g., NVIDIA-0, modesetting)"
        color_echo 36 "     Common setup: setProviders NVIDIA-0 modesetting"
        _codex_unset
        return 1
    fi
    # Attempt to set the provider source using names
    # If this fails, xrandr will output an error automatically
    if xrandr --setprovideroutputsource "$1" "$2"; then
        color_echo 32 "Success: Providers linked ($1 -> $2)."
        color_echo 33 "Applying automatic configuration..."
        xrandr --auto
        _codex_unset
        return 0
    else
        color_echo 31 "Error: Failed to link providers."
        color_echo 33 "Hint: Ensure nvidia-drm.modeset=1 is set in kernel parameters."
        _codex_unset
        return 1
    fi
}

# END