# BEGIN : Toolbox/display_tools.sh 
# ... functions and aliases to manage displays in X(xorg)

# -- dependencies
# 1. xorg, it's a xorg tool.

# -- description 

# RED = 31 - 41
# GREEN = 32 - 42
# YELLOW = 33 - 43
# BLUE = 34 - 44
# MAGENTA = 35 - 45
# CYAN = 36 - 46
# WHITE = 37 - 47
function color_echo {
    local color=$1
    shift
    echo -e "\e[${color}m$@\e[0m"
}

echo ""
color_echo 33 "=== Display Tools ==="
color_echo 36 "-- General --"
echo "listDisplays : Short list of display monitor names and connection state"
echo "listConnectedDisplays : ..."
echo "mirrorDisplay <main> <target> : ..."
echo ""
color_echo 36 "-- Extended Displays --"
color_echo 31 "... to extend displays in nvidia the nvidia-drm.modeset parameter must be active"
color_echo 32 "... use 'cat /sys/module/nvidia_drm/parameters/modeset' to check"
color_echo 31 "... to extend displays you must set provider source and provider output"
echo "setProviders : ..."
echo "extendDisplayRight <main> <right> : ..."
echo "extendDisplayLeft <main> <left> : ..."
echo "extendDisplayAbove <main> <above> : ..."
echo "extendDisplayBelow <main> <below> : ..."
echo ""

# -- implementation 
function listDisplays { 
    # Short list of display monitor names and connection state
    # Dependencies: xrandr (part of x11-xserver-utils)
    if ! command -v xrandr &> /dev/null; then
        color_echo 31 "Error: xrandr command not found. Please install x11-xserver-utils."
        return 1
    fi
    # Query xrandr, grep for connection status, and format output
    # Format: "MonitorName: Status"
    echo ""
    xrandr --query | grep -E "connected|disconnected" | awk '{print $1 ": " $2}'
    return 0
}
function listConnectedDisplays { 
    # Short list of display monitor names and connection state
    # Dependencies: xrandr (part of x11-xserver-utils)
    if ! command -v xrandr &> /dev/null; then
        color_echo 31 "Error: xrandr command not found. Please install x11-xserver-utils."
        return 1
    fi
    # Query xrandr, grep for connection status, and format output
    # Format: "MonitorName: Status"
    echo ""
    xrandr --query | grep " connected" | awk '{print $1 ": " $2}'
    return 0
}
function extendDisplayRight {
    if [ "$#" -ne 2 ]; then 
        listConnectedDisplays 
        color_echo 33 "Usage: extendDisplayRight <main_display> <right_display>"
        return 1
    fi
    # Capture xrandr output ONCE to avoid multiple slow calls
    local xrandr_output
    xrandr_output=$(xrandr --query)
    # Validate that both monitors are connected
    if ! echo "$xrandr_output" | grep -q "^$1 connected"; then
        color_echo 31 "Error: '$1' is not connected."
        return 1
    fi
    if ! echo "$xrandr_output" | grep -q "^$2 connected"; then
        color_echo 31 "Error: '$2' is not connected."
        return 1
    fi
    # Apply configuration and check for success
    if xrandr --output "$1" --primary --auto --output "$2" --auto --right-of "$1"; then
        color_echo 32 "Success: Extended '$2' to the right of '$1'."
        return 0
    else
        color_echo 31 "Error: Failed to configure displays."
        return 1
    fi
}
function extendDisplayLeft {
    if [ "$#" -ne 2 ]; then 
        listConnectedDisplays 
        color_echo 33 "Usage: extendDisplayLeft <main_display> <left_display>"
        return 1
    fi
    # Capture xrandr output ONCE to avoid multiple slow calls
    local xrandr_output
    xrandr_output=$(xrandr --query)
    # Validate connections
    if ! echo "$xrandr_output" | grep -q "^$1 connected"; then
        color_echo 31 "Error: '$1' is not connected."
        return 1
    fi
    if ! echo "$xrandr_output" | grep -q "^$2 connected"; then
        color_echo 31 "Error: '$2' is not connected."
        return 1
    fi
    xrandr --output "$1" --primary --auto --output "$2" --auto --left-of "$1"
}
function mirrorDisplay {
    if [ "$#" -ne 2 ]; then 
        listConnectedDisplays 
        color_echo 33 "Usage: mirrorDisplay <source_display> <target_display>"
        return 1
    fi
    # Validate connections
    local xrandr_output
    xrandr_output=$(xrandr --query)
    if ! echo "$xrandr_output" | grep -q "^$1 connected"; then
        color_echo 31 "Error: '$1' is not connected."
        return 1
    fi
    if ! echo "$xrandr_output" | grep -q "^$2 connected"; then
        color_echo 31 "Error: '$2' is not connected."
        return 1
    fi
    xrandr --output "$1" --primary --auto --output "$2" --auto --same-as "$1"
}
function extendDisplayAbove {
    if [ "$#" -ne 2 ]; then 
        listConnectedDisplays 
        color_echo 33 "Usage: extendDisplayAbove <main_display> <above_display>"
        return 1
    fi
    # Validate connections
    local xrandr_output
    xrandr_output=$(xrandr --query)
    if ! echo "$xrandr_output" | grep -q "^$1 connected"; then
        color_echo 31 "Error: '$1' is not connected."
        return 1
    fi
    if ! echo "$xrandr_output" | grep -q "^$2 connected"; then
        color_echo 31 "Error: '$2' is not connected."
        return 1
    fi
    xrandr --output "$1" --primary --auto --output "$2" --auto --above "$1"
}   
function extendDisplayBelow {
    if [ "$#" -ne 2 ]; then 
        listConnectedDisplays 
        color_echo 33 "Usage: extendDisplayBelow <main_display> <below_display>"
        return 1
    fi
    # Validate connections
    local xrandr_output
    xrandr_output=$(xrandr --query)
    if ! echo "$xrandr_output" | grep -q "^$1 connected"; then
        color_echo 31 "Error: '$1' is not connected."
        return 1
    fi
    if ! echo "$xrandr_output" | grep -q "^$2 connected"; then
        color_echo 31 "Error: '$2' is not connected."
        return 1
    fi
    xrandr --output "$1" --primary --auto --output "$2" --auto --below "$1"
}   
function setProviders {
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
        return 1
    fi
    # Attempt to set the provider source using names
    # If this fails, xrandr will output an error automatically
    if xrandr --setprovideroutputsource "$1" "$2"; then
        color_echo 32 "Success: Providers linked ($1 -> $2)."
        color_echo 33 "Applying automatic configuration..."
        xrandr --auto
        return 0
    else
        color_echo 31 "Error: Failed to link providers."
        color_echo 33 "Hint: Ensure nvidia-drm.modeset=1 is set in kernel parameters."
        return 1
    fi
}

# END