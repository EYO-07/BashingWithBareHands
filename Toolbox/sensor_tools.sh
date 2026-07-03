# BEGIN : sensor_tools.sh
# ... script to list sensor files 

# -- dependencies

# -- description
echo ""
echo "=== Sensor Tools ==="
echo "... search sensor files"
echo "searchGeneralSensorFiles : ..."
echo "searchCPUSensorFiles : ..."
echo "searchGPUSensorFiles : ..."
echo ""

# -- implementation
function searchGeneralSensorFiles {
    echo '-- /sys/class/hwmon'
    if [ -d '/sys/class/hwmon' ]; then
        for hwmon_link in /sys/class/hwmon/hwmon*; do
            if [ -d "$hwmon_link" ]; then
                sensor_name=$(cat "$hwmon_link/name" 2>/dev/null || echo "unknown")
                stable_path=$(readlink -f "$hwmon_link")
                echo "  [Dispositivo: $sensor_name]"
                echo "    -> Link: $hwmon_link"
                echo "    -> Caminho Estável: $stable_path"
                for file in "$hwmon_link"/*; do
                    if [ -f "$file" ]; then
                        echo "       $file"
                    fi
                done
            fi
        done
    else
        echo "  Diretório /sys/class/hwmon não encontrado."
    fi
}    
function searchCPUSensorFiles {
    # 2. Uso da CPU
    echo '-- /proc/stat'
    if [ -f '/proc/stat' ]; then
        echo "  Arquivo: /proc/stat"
        echo "  (Contém linhas iniciadas com 'cpu' para cálculo de uso)"
    else
        echo "  Arquivo não encontrado."
    fi
}
function searchGPUSensorFiles {
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
                    echo "    -> Arquivos de Controle/Frequência:"
                    echo "$files" | sed 's|^|       |'
                fi
                # Verifica diretório do dispositivo (vendor specific)
                device_dir="$card_dir/device"
                if [ -d "$device_dir" ]; then
                    echo "    -- $device_dir --"  
                    # Arquivos específicos AMD/Intel (gpu_busy_percent, etc)
                    gpu_files=$(ls "$device_dir" 2>/dev/null | grep -E 'gpu_busy|power|freq')
                    if [ -n "$gpu_files" ]; then
                        echo "    -> Arquivos de Uso/Energia:"
                        echo "$gpu_files" | sed 's|^|       |'
                    fi
                    # Sensores hwmon específicos da GPU (comum em AMD)
                    hwmon_gpu_dir="$device_dir/hwmon"
                    if [ -d "$hwmon_gpu_dir" ]; then
                        for gpu_hwmon in "$hwmon_gpu_dir"/hwmon*; do
                            if [ -d "$gpu_hwmon" ]; then
                                echo "    -- Sensores GPU em: $gpu_hwmon --"
                                ls -1 "$gpu_hwmon" | sed 's|^|       |'
                            fi
                        done
                    fi
                fi
            fi
        done
    else
        echo "  Diretório não encontrado."
    fi
}


# END