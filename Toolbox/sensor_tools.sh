# BEGIN : sensor_tools.sh
# ... script to list sensor files 
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -- dependencies

# -- description
function tools {
    source "$_SCRIPT_DIR/_codex.sh"
    local width=5
    toolbox_title "Sensor Virtual File Tools"
    info_echo "... script to find information about sensor virtual files"
    toolbox_item "tools" "print this ..." $width
    toolbox_item "inv" "print built-in commands ..." $width
    toolbox_item "searchGeneralSensorFiles" "..." $width
    toolbox_item "searchGPUSensorFiles" "..." $width
    #toolbox_item "..." "..." $width
    toolbox_endl
    _codex_unset
}
tools 
function inv {
    source "$_SCRIPT_DIR/_codex.sh"
    inventory_title "Sensor Virtual File Tools"
    local width=2
    inventory_item 1 "cat" "display the contents of regular file on terminal output. Similar commands: head, tail." $width
    inventory_item 2 "nvidia-smi" "general information about sensors for nvidia graphic cards."
    inventory_endl 
    _codex_unset
    return 0
}

# -- implementation
function searchGeneralSensorFiles {
    source "$_SCRIPT_DIR/_codex.sh"
    echo '-- /sys/class/hwmon'
    if [ -d '/sys/class/hwmon' ]; then
        for hwmon_link in /sys/class/hwmon/hwmon*; do
            if [ -d "$hwmon_link" ]; then
                sensor_name=$(cat "$hwmon_link/name" 2>/dev/null || echo "unknown")
                stable_path=$(readlink -f "$hwmon_link")
                echo "  [Device: $sensor_name]"
                echo "    -> Link: $hwmon_link"
                echo "    -> Stable Path: $stable_path"
                for file in "$hwmon_link"/*; do
                    if [ -f "$file" ]; then
                        echo "       $file"
                    fi
                done
            fi
        done
    else
        echo "  cant find the folder /sys/class/hwmon"
    fi
    _codex_unset
}    
function searchGPUSensorFiles {
    source "$_SCRIPT_DIR/_codex.sh"
    # 3. Sensores e Uso da GPU (DRM)
    echo '-- /sys/class/drm'
    if [ -d '/sys/class/drm' ]; then
        # Itera sobre cada card gráfico (card0, card1, ...)
        for card_dir in /sys/class/drm/card*; do
            if [ -d "$card_dir" ]; then
                card_name=$(basename "$card_dir")
                echo "  [$card_name]"
                # Lista conteúdo direto do card (frequências, status)
                files=$(ls "$card_dir" 2>/dev/null | grep -E 'freq|status|util')
                if [ -n "$files" ]; then
                    echo "    -> Control/Frequency Files:"
                    echo "$files" | sed 's|^|       |'
                fi
                # Verifica diretório do dispositivo (vendor specific)
                device_dir="$card_dir/device"
                if [ -d "$device_dir" ]; then
                    echo "    -- $device_dir --"  
                    # Arquivos específicos AMD/Intel (gpu_busy_percent, etc)
                    gpu_files=$(ls "$device_dir" 2>/dev/null | grep -E 'gpu_busy|power|freq')
                    if [ -n "$gpu_files" ]; then
                        echo "    -> Power/Usage Files:"
                        echo "$gpu_files" | sed 's|^|       |'
                    fi
                    # Sensores hwmon específicos da GPU (comum em AMD)
                    hwmon_gpu_dir="$device_dir/hwmon"
                    if [ -d "$hwmon_gpu_dir" ]; then
                        for gpu_hwmon in "$hwmon_gpu_dir"/hwmon*; do
                            if [ -d "$gpu_hwmon" ]; then
                                echo "    -- GPU Sensors in: $gpu_hwmon --"
                                ls -1 "$gpu_hwmon" | sed 's|^|       |'
                            fi
                        done
                    fi
                fi
            fi
        done
    else
        echo "  Directory not found."
    fi
    _codex_unset
}

# END