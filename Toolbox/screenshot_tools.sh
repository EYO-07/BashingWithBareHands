# BEGIN : ~/Toolbox/screenshot_tools.sh

# -- dependencies
# 1. scrot 
# 2. xrandr ~ x11 environment

# -- description
echo ""
echo "=== Screeshot Tools ==="
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