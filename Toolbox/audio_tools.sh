# BEGIN : Toolbox/audio_tools.sh
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -- dependencies 
# 1. wpctl cli command

# -- description 
# A toolbox for managing audio devices with colored output.

function tools {
    source "$_SCRIPT_DIR/_codex.sh"
    local width=4
    toolbox_title "Audio Tools"
    toolbox_item "tools" "print this ..." $width
    toolbox_item "inv" "print built-in commands ..." $width
    toolbox_item "showAudioDevices" "show audio devices" $width
    toolbox_item "showVolume" "volume percentage of current default audio sink" $width
    toolbox_item "setAudioSink" "set default sink" $width
    toolbox_item "setVolumePercentage" "set absolute volume percentage (1-100)" $width
    toolbox_item "increaseVolume" "increase volume by optional step (default 5%)" $width
    toolbox_item "decreaseVolume" "decrease volume by optional step (default 5%)" $width
    toolbox_endl
    _codex_unset
}
tools
function inv {
    source "$_SCRIPT_DIR/_codex.sh"
    inventory_title "todo"
    local width=9
    inventory_item 1 "..." "..." $width
    inventory_endl 
    _codex_unset
}

# -- implementation
function showAudioDevices {
    source "$_SCRIPT_DIR/_codex.sh"
    wpctl status
}
function showVolume {
    source "$_SCRIPT_DIR/_codex.sh"
    local vol_str
    vol_str=$(wpctl get-volume @DEFAULT_SINK@)
    local vol_float
    vol_float=$(echo "$vol_str" | grep -oE '[0-9]+(\.[0-9]+)?' | head -1)
    if [ -z "$vol_float" ]; then
        crit_echo "Failed to get volume"
        _codex_unset
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
    _codex_unset
}
function setAudioSink {
    source "$_SCRIPT_DIR/_codex.sh"
    if [ "$#" -ne 1 ]; then
        showAudioDevices
        echo "USAGE : setAudioSink <number>"
        _codex_unset
        return 1
    fi
    local sink_id=$1
    # Validate input is a number
    if ! [[ "$sink_id" =~ ^[0-9]+$ ]]; then
        crit_echo "Error: Sink ID must be a number"
        _codex_unset
        return 1
    fi
    wpctl set-default "$sink_id"
    if [ $? -eq 0 ]; then
        color_echo 32 "Default sink set to ID: $sink_id"
    else
        crit_echo "Failed to set default sink"
        _codex_unset
        return 1
    fi
    _codex_unset
}
function setVolumePercentage {
    source "$_SCRIPT_DIR/_codex.sh"
    if [ "$#" -ne 1 ]; then
        showVolume
        echo "USAGE : setVolumePercentage <number>"
        echo "... 1-100"
        _codex_unset
        return 1
    fi
    local pct=$1
    # Validate range
    if ! [[ "$pct" =~ ^[0-9]+$ ]] || [ "$pct" -lt 0 ] || [ "$pct" -gt 100 ]; then
        crit_echo "Error: Volume must be between 0 and 100"
        _codex_unset
        return 1
    fi
    wpctl set-volume @DEFAULT_SINK@ "${pct}%"
    if [ $? -eq 0 ]; then
        color_echo 32 "Volume set to ${pct}%"
    else
        crit_echo "Failed to set volume"
        _codex_unset
        return 1
    fi
    _codex_unset
}
function increaseVolume {
    source "$_SCRIPT_DIR/_codex.sh"
    local step=5
    if [ "$#" -eq 1 ]; then
        step=$1
        if ! [[ "$step" =~ ^[0-9]+$ ]] || [ "$step" -lt 1 ] || [ "$step" -gt 100 ]; then
            crit_echo "Error: Step must be between 1 and 100"
            _codex_unset
            return 1
        fi
    elif [ "$#" -gt 1 ]; then
        echo "USAGE : increaseVolume"
        echo "USAGE : increaseVolume <number>"
        echo "... 1-100"
        _codex_unset
        return 1
    fi
    wpctl set-volume @DEFAULT_SINK@ "${step}%+"
    if [ $? -eq 0 ]; then
        local new_vol
        new_vol=$(showVolume)
        color_echo 32 "Volume increased by ${step}% (Current: ${new_vol})"
    else
        crit_echo "Failed to increase volume"
        _codex_unset
        return 1
    fi
    _codex_unset
}
function decreaseVolume {
    source "$_SCRIPT_DIR/_codex.sh"
    local step=5
    if [ "$#" -eq 1 ]; then
        step=$1
        if ! [[ "$step" =~ ^[0-9]+$ ]] || [ "$step" -lt 1 ] || [ "$step" -gt 100 ]; then
            crit_echo "Error: Step must be between 1 and 100"
            _codex_unset
            return 1
        fi
    elif [ "$#" -gt 1 ]; then
        echo "USAGE : decreaseVolume"
        echo "USAGE : decreaseVolume <number>"
        echo "... 1-100"
        _codex_unset
        return 1
    fi
    wpctl set-volume @DEFAULT_SINK@ "${step}%-"
    if [ $? -eq 0 ]; then
        local new_vol
        new_vol=$(showVolume)
        color_echo 32 "Volume decreased by ${step}% (Current: ${new_vol})"
    else
        crit_echo "Failed to decrease volume"
        _codex_unset
        return 1
    fi
    _codex_unset
}

# END   