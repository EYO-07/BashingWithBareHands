# BEGIN : ~/Toolbox/screenshot_tools.sh

# -- dependencies
# 1. scrot 
# 2. xrandr ~ x11 environment

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
color_echo 33 "=== Screeshot Tools ==="
echo "takeScreenshot <MONITOR_NUMBER> : ..."
echo ""

# -- implementation
function takeScreenshot {
    if [ "$#" -eq 0 ]; then 
        xrandr --listmonitors
        echo "Usage: takeScreenshot <MONITOR_NUMBER>"
        return 1
    fi
    if [ "$#" -eq 1 ]; then 
        scrot --monitor "$1" --format "png" --file "$HOME/Pictures/Screenshots/ss_$1_$(date +%s).png"
        return 0
    fi
    echo "Usage: takeScreenshot <MONITOR_NUMBER>"
}

# END 