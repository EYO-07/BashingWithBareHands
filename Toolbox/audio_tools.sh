# BEGIN : Toolbox/audio_tools.sh

# -- dependencies 
# 1. wpctl cli command

# -- description 
# A toolbox for managing audio devices with colored output.

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
    if [ "$#" -gt 0 ]; then
        echo -e "\e[${color}m$@\e[0m"
    else
        while IFS= read -r line; do
            echo -e "\e[${color}m${line}\e[0m"
        done
    fi
}
function warn_echo {
    color_echo 33 "$@"
}
function crit_echo {
    color_echo 31 "$@"
}

echo ""
color_echo 33 "=== Audio Tools ==="
echo "showAudioDevices : show audio devices"
echo "showVolume : volume percentage of current default audio sink"
echo "setAudioSink : set default sink"
echo "setVolumePercentage : set absolute volume percentage (1-100)"
echo "increaseVolume : increase volume by optional step (default 5%)"
echo "decreaseVolume : decrease volume by optional step (default 5%)"
echo ""

# -- implementation
function showAudioDevices {
    clear
    wpctl status
}
function showVolume {
    local vol_str
    vol_str=$(wpctl get-volume @DEFAULT_SINK@)
    local vol_float
    vol_float=$(echo "$vol_str" | grep -oE '[0-9]+(\.[0-9]+)?' | head -1)
    if [ -z "$vol_float" ]; then
        crit_echo "Failed to get volume"
        return 1
    fi
    local vol_pct
    vol_pct=$(awk "BEGIN {printf \"%.0f\", $vol_float * 100}")   
    # Check if muted and append notice
    if [[ "$vol_str" == *"[MUTED]"* ]]; then
        echo "${vol_pct}% [MUTED]"
    else
        echo "${vol_pct}%"
    fi
}
function setAudioSink {
    if [ "$#" -ne 1 ]; then
        showAudioDevices
        echo "USAGE : setAudioSink <number>"
        return 1
    fi
    local sink_id=$1
    # Validate input is a number
    if ! [[ "$sink_id" =~ ^[0-9]+$ ]]; then
        crit_echo "Error: Sink ID must be a number"
        return 1
    fi
    wpctl set-default "$sink_id"
    if [ $? -eq 0 ]; then
        color_echo 32 "Default sink set to ID: $sink_id"
    else
        crit_echo "Failed to set default sink"
        return 1
    fi
}
function setVolumePercentage {
    if [ "$#" -ne 1 ]; then
        showVolume
        echo "USAGE : setVolumePercentage <number>"
        echo "... 1-100"
        return 1
    fi
    local pct=$1
    # Validate range
    if ! [[ "$pct" =~ ^[0-9]+$ ]] || [ "$pct" -lt 0 ] || [ "$pct" -gt 100 ]; then
        crit_echo "Error: Volume must be between 0 and 100"
        return 1
    fi
    wpctl set-volume @DEFAULT_SINK@ "${pct}%"
    if [ $? -eq 0 ]; then
        color_echo 32 "Volume set to ${pct}%"
    else
        crit_echo "Failed to set volume"
        return 1
    fi
}
function increaseVolume {
    local step=5
    if [ "$#" -eq 1 ]; then
        step=$1
        if ! [[ "$step" =~ ^[0-9]+$ ]] || [ "$step" -lt 1 ] || [ "$step" -gt 100 ]; then
            crit_echo "Error: Step must be between 1 and 100"
            return 1
        fi
    elif [ "$#" -gt 1 ]; then
        echo "USAGE : increaseVolume"
        echo "USAGE : increaseVolume <number>"
        echo "... 1-100"
        return 1
    fi
    wpctl set-volume @DEFAULT_SINK@ "${step}%+"
    if [ $? -eq 0 ]; then
        local new_vol
        new_vol=$(showVolume)
        color_echo 32 "Volume increased by ${step}% (Current: ${new_vol})"
    else
        crit_echo "Failed to increase volume"
        return 1
    fi
}
function decreaseVolume {
    local step=5
    if [ "$#" -eq 1 ]; then
        step=$1
        if ! [[ "$step" =~ ^[0-9]+$ ]] || [ "$step" -lt 1 ] || [ "$step" -gt 100 ]; then
            crit_echo "Error: Step must be between 1 and 100"
            return 1
        fi
    elif [ "$#" -gt 1 ]; then
        echo "USAGE : decreaseVolume"
        echo "USAGE : decreaseVolume <number>"
        echo "... 1-100"
        return 1
    fi
    wpctl set-volume @DEFAULT_SINK@ "${step}%-"
    if [ $? -eq 0 ]; then
        local new_vol
        new_vol=$(showVolume)
        color_echo 32 "Volume decreased by ${step}% (Current: ${new_vol})"
    else
        crit_echo "Failed to decrease volume"
        return 1
    fi
}

# END   