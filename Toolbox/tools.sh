# BEGIN : Toolbox/tools.sh 
# ==============================================================================
# DEPENDENCIES: history, grep, tput, stty, coreutils
# ==============================================================================

# -- variables
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if ! declare -F "__SCRIPT_SAFE_SOURCE" >/dev/null; then
    __SCRIPT_SAFE_SOURCE() {
        local script_path="${1:-}"
        if [[ -z "$script_path" || ! -f "$script_path" ]]; then
            printf '\033[1;31m✗ Error: Invalid or missing script path for sourcing.\033[0m\n' >&2
            return 1
        fi
        printf '\033[1;33m⚠ Warning: Security core absent. Sourcing without integrity check\033[0m\n' >&2
        # Proceed with standard sourcing
        source "$script_path"
    }
fi
# local config_path="$HOME/.config/BashingWithBareHands/tools.conf"
__SELECTED_ITEM=0 # ~ bmenu 
__SELECTED_ITEM_FILESYSTEM=0 # ~ bmenuFilesystem
__SELECTED_ITEM_SYSTEM=0 # ~ bmenuSystem
__SELECTED_ITEM_MISC=0 # ~ bmenuMiscellaneous

# -- load/save config
__BWBH_SAVE_CONFIG_tools() {
    __SCRIPT_SAFE_SOURCE "$_SCRIPT_DIR/_codex.sh"
    local config_path="$HOME/.config/BashingWithBareHands/tools.conf"
    if [[ ! -f "$config_path" ]]; then 
        crit_echo "... config file not found"
        good_echo "... creating config file"
        create_intermediate_dirs "$config_path"
        echo "$config_path"
    fi 
    save_variables "$config_path" \
        "__SELECTED_ITEM" "__SELECTED_ITEM_FILESYSTEM" "__SELECTED_ITEM_SYSTEM" "__SELECTED_ITEM_MISC"
}

# -- description 
function tools {
    __SCRIPT_SAFE_SOURCE "$_SCRIPT_DIR/_codex.sh"
    local config_path="$HOME/.config/BashingWithBareHands/tools.conf"
    load_variables "$config_path"
    # -- tool print
    local width=4
    toolbox_title "Bashing With Bare Hands"
    info_echo "... interactive verbose bash aliases and functions"
    toolbox_item "tools" "print this ..." $width
    toolbox_item "hsearch" "search command history by keyword" $width
    toolbox_item "bmenu" "bashing with bare hands terminal interactive menu" $width
    toolbox_item "bmenuFilesystem" "menu for filesystem tools" $width
    toolbox_item "bmenuSystem" "menu for system tools" $width
    toolbox_item "bmenuMiscellaneous" "menu for miscellaneous tools" $width
    toolbox_endl
    # --    
    _codex_unset
}
tools

# -- implementation
function bmenu {
    __SCRIPT_SAFE_SOURCE "$_SCRIPT_DIR/_codex.sh"
    local config_path="$HOME/.config/BashingWithBareHands/tools.conf"
    load_variables "$config_path"
    # --
    local bmenu_title="Bashing With Bare Hands"
    trap 'tput cnorm; stty echo' RETURN INT TERM # cleanup on function return 
    stty -echo # disables echo 
    tput civis # hides cursor
    local selected=$__SELECTED_ITEM
    local items=(
        "Reload tools.sh"
        "Files / Filesystem"
        "Move/Copy/Delete Multiple Files"
        "File Compression / Backup"
        "Mounting Devices / Filesystem Integrity"
        "File Change Mode"
        "Filesharing (RSync)"
        "USB and Removable Storage Devices"
        "Errors"
        "Internet"
        "Firewall"
        "Processes"
        "Services"
        "Sockets"
        "Audio"
        "Sensors"
        "Virus/Malware Scan"
        "Git"
        "Date/Calendar"
        "Wine"
        "Python (Environment Management)"
        "Pacman Package Manager"
        "XOrg/X11 Display"
        "i3 Window Manager"
        "Grub"
        "Grep"
        "Misc Audiobook"
        "Misc LLAMA Cpp"
        "Misc Screenshot"
        "Misc Video/Music Downloads"
        "Misc Local Python Server"
        "Exit"
    )
    # Parallel array of actions (function names or commands)
    local actions=(
        "tools.sh"
        "filesystem_tools.sh"
        "move_copy_delete_tools.sh"
        "filecompressing_tools.sh"
        "mounting_tools.sh"
        "change_mode_tools.sh"
        "filesharing_tools.sh"
        "usb_tools.sh"
        "errors_tools.sh"
        "net_tools.sh"
        "firewall_tools.sh"
        "processes_tools.sh"
        "services_tools.sh"
        "socket_tools.sh"
        "audio_tools.sh"
        "sensor_tools.sh"
        "scan_tools.sh"
        "git_tools.sh"
        "date_tools.sh"
        "wine_tools.sh"
        "python_env_tools.sh"
        "pacman_tools.sh"
        "display_tools.sh"
        "i3_tools.sh"
        "grub_tools.sh"
        "grep_tools.sh"
        "audiobook_tools.sh"
        "llama_cpp_tools.sh"
        "screenshot_tools.sh"
        "video_music_download_tools.sh"
        "_server_tools.sh"
        "return"
    )
    local total=${#items[@]}
    while true; do
        (( selected >= total )) && selected=$(( total - 1 ))
        (( selected < 0 )) && selected=0
        # --- Render ---
        clear
        warn_echo "$bmenu_title"
        for (( i = 0; i < total; i++ )); do
            if [[ $i -eq $selected ]]; then
                echo -e "\033[1;32m > ${items[$i]} \033[0m"
            else
                echo "   ${items[$i]}"
            fi
        done
        # --- Input ---
        read -rsn1 key
        if [[ $key == $'\x1b' ]]; then
            read -rsn2 -t 0.2 key
            case "$key" in
                '[A') ((selected--)) || true ;;
                '[B') ((selected++)) || true ;;
                '[5') read -rsn1 -t 0.2; ((selected-=7)) || true ;;   # PageUp
                '[6') read -rsn1 -t 0.2; ((selected+=7)) || true ;;   # PageDown
                *)    key=$'\x1b' ;;
            esac
        fi
        case "$key" in
            q|Q) break ;;
            "")
                # Execute the selected action
                local action="${actions[$selected]}"
                if [[ "$action" != "return" ]]; then 
                    trap - RETURN INT TERM
                    tput cnorm
                    stty echo
                    __SCRIPT_SAFE_SOURCE "$_SCRIPT_DIR/$action"
                fi
                break # every action will break 
                ;;
        esac
    done
    __SELECTED_ITEM=$selected
    __BWBH_SAVE_CONFIG_tools
    _codex_unset
}
function bmenuFilesystem {
    __SCRIPT_SAFE_SOURCE "$_SCRIPT_DIR/_codex.sh"
    local config_path="$HOME/.config/BashingWithBareHands/tools.conf"
    load_variables "$config_path"
    # Define the menu items (indexed array)
    local items=(
        "Files / Filesystem"
        "Move/Copy/Delete Multiple Files"
        "File Compression / Backup"
        "Mounting Devices / Filesystem Integrity"
        "File Change Mode"
        "Filesharing (RSync)"
        "USB and Removable Storage Devices"
        "Exit"
    )
    # Define the actions (associative array: item label -> command to run)
    declare -A actions=(
        ["Exit"]="return"
        ["Files / Filesystem"]="_files"
        ["Mounting Devices / Filesystem Integrity"]="_mount"
        ["File Change Mode"]="_modes"
        ["Filesharing (RSync)"]="_share"
        ["USB and Removable Storage Devices"]="_usb"
        ["File Compression / Backup"]="_file_comp_back"
        ["Move/Copy/Delete Multiple Files"]="_file_mult"
    )
    # -- functions
    _file_mult() {
        __SCRIPT_SAFE_SOURCE "$_SCRIPT_DIR/move_copy_delete_tools.sh"
    }
    _file_comp_back() {
        __SCRIPT_SAFE_SOURCE "$_SCRIPT_DIR/filecompressing_tools.sh"
    }
    _files() {
        __SCRIPT_SAFE_SOURCE "$_SCRIPT_DIR/filesystem_tools.sh"
    }
    _mount() {
        __SCRIPT_SAFE_SOURCE "$_SCRIPT_DIR/mounting_tools.sh"
    }
    _modes() {
        __SCRIPT_SAFE_SOURCE "$_SCRIPT_DIR/change_mode_tools.sh"
    }
    _share() {
        __SCRIPT_SAFE_SOURCE "$_SCRIPT_DIR/filesharing_tools.sh"
    }
    _usb() {
        __SCRIPT_SAFE_SOURCE "$_SCRIPT_DIR/usb_tools.sh"
    }
    # Call the menu — pass variable *names*, not values
    INTERACTIVE_MENU items actions "Filesystem Tools Menu" $__SELECTED_ITEM_FILESYSTEM
    __SELECTED_ITEM_FILESYSTEM=$?
    unset -f _files _mount _modes _share _usb _file_mult
    __BWBH_SAVE_CONFIG_tools
    _codex_unset
} 
function bmenuSystem {
    __SCRIPT_SAFE_SOURCE "$_SCRIPT_DIR/_codex.sh"
    local config_path="$HOME/.config/BashingWithBareHands/tools.conf"
    load_variables "$config_path"
    # Define the menu items (indexed array)
    local items=(
        "Errors"
        "Internet"
        "Firewall"
        "Processes"
        "Services"
        "Sockets"
        "Audio"
        "Sensors"
        "Virus/Malware Scan"
        "Pacman Package Manager"
        "XOrg/X11 Display"
        "i3 Window Manager"
        "Grub"
        "Exit"
    )
    # Define the actions (associative array: item label -> command to run)
    declare -A actions=(
        ["Exit"]="return"
        ["Errors"]="_errors"
        ["Internet"]="_internet"
        ["Processes"]="_processes"
        ["Services"]="_services"
        ["Sockets"]="_sockets"
        ["Audio"]="_audio"
        ["Sensors"]="_sensors"
        ["Pacman Package Manager"]="_pacman"
        ["XOrg/X11 Display"]="_display_xorg"
        ["i3 Window Manager"]="_i3winmanager"
        ["Virus/Malware Scan"]="_virus_mal"
        ["Firewall"]="_firewall"
        ["Grub"]="_grub_tools"
    )
    # -- functions
    _grub_tools() {
        __SCRIPT_SAFE_SOURCE "$_SCRIPT_DIR/grub_tools.sh"
    }
    _firewall() {
        __SCRIPT_SAFE_SOURCE "$_SCRIPT_DIR/firewall_tools.sh"
    }
    _virus_mal() {
        __SCRIPT_SAFE_SOURCE "$_SCRIPT_DIR/scan_tools.sh"
    }
    _errors() {
        __SCRIPT_SAFE_SOURCE "$_SCRIPT_DIR/errors_tools.sh"
    }
    _internet() {
        __SCRIPT_SAFE_SOURCE "$_SCRIPT_DIR/net_tools.sh"
    }
    _processes() {
        __SCRIPT_SAFE_SOURCE "$_SCRIPT_DIR/processes_tools.sh"
    }
    _services() {
        __SCRIPT_SAFE_SOURCE "$_SCRIPT_DIR/services_tools.sh"
    }
    _sockets() {
        __SCRIPT_SAFE_SOURCE "$_SCRIPT_DIR/socket_tools.sh"
    }
    _audio() {
        __SCRIPT_SAFE_SOURCE "$_SCRIPT_DIR/audio_tools.sh"
    }
    _sensors() {
        __SCRIPT_SAFE_SOURCE "$_SCRIPT_DIR/sensor_tools.sh"
    }
    _pacman() {
        __SCRIPT_SAFE_SOURCE "$_SCRIPT_DIR/pacman_tools.sh"
    }
    _display_xorg() {
        __SCRIPT_SAFE_SOURCE "$_SCRIPT_DIR/display_tools.sh"
    }
    _i3winmanager() {
        __SCRIPT_SAFE_SOURCE "$_SCRIPT_DIR/i3_tools.sh"
    }
    # Call the menu — pass variable *names*, not values
    INTERACTIVE_MENU items actions "System Tools Menu" $__SELECTED_ITEM_SYSTEM
    __SELECTED_ITEM_SYSTEM=$?
    unset -f _errors _internet _processes _services _sockets _audio _sensors _pacman _display_xorg _i3winmanager _firewall
    __BWBH_SAVE_CONFIG_tools
    _codex_unset
} 
function bmenuMiscellaneous {
    __SCRIPT_SAFE_SOURCE "$_SCRIPT_DIR/_codex.sh"
    local config_path="$HOME/.config/BashingWithBareHands/tools.conf"
    load_variables "$config_path"
    # Define the menu items (indexed array)
    local items=(
        "Git"
        "Wine"
        "Python (Environment Management)"
        "Audiobook"
        "Date/Calendar"
        "LLM Local Inference (llama.cpp)"
        "Video/Music Downloads"
        "Local Python Server"
        "Screenshot"
        "Grep"
        "Exit"
    )
    # Define the actions (associative array: item label -> command to run)
    declare -A actions=(
        ["Exit"]="return"
        ["Git"]="_git_tools"
        ["Wine"]="_wine_tools"
        ["Python (Environment Management)"]="_python_env_tools"
        ["Audiobook"]="_audiobook"
        ["Date/Calendar"]="_calendar"
        ["LLM Local Inference (llama.cpp)"]="_local_inf"
        ["Video/Music Downloads"]="_viddown"
        ["Local Python Server"]="_local_server"
        ["Screenshot"]="_screenshot"
        ["Grep"]="_grep_tools"
    )
    # -- functions
    _grep_tools() {
        __SCRIPT_SAFE_SOURCE "$_SCRIPT_DIR/grep_tools.sh"
    }
    _git_tools() {
        __SCRIPT_SAFE_SOURCE "$_SCRIPT_DIR/git_tools.sh"
    }
    _wine_tools() {
        __SCRIPT_SAFE_SOURCE "$_SCRIPT_DIR/wine_tools.sh"
    }
    _python_env_tools() {
        __SCRIPT_SAFE_SOURCE "$_SCRIPT_DIR/python_env_tools.sh"
    }
    _audiobook() {
        __SCRIPT_SAFE_SOURCE "$_SCRIPT_DIR/audiobook_tools.sh"
    }
    _calendar() {
        __SCRIPT_SAFE_SOURCE "$_SCRIPT_DIR/date_tools.sh"
    }
    _local_inf() {
        __SCRIPT_SAFE_SOURCE "$_SCRIPT_DIR/llama_cpp_tools.sh"
    }
    _viddown() {
        __SCRIPT_SAFE_SOURCE "$_SCRIPT_DIR/video_music_download_tools.sh"
    }
    _local_server() {
        __SCRIPT_SAFE_SOURCE "$_SCRIPT_DIR/_server_tools.sh"
    }
    _screenshot() {
        __SCRIPT_SAFE_SOURCE "$_SCRIPT_DIR/screenshot_tools.sh"
    }
    # Call the menu — pass variable *names*, not values
    INTERACTIVE_MENU items actions "Miscellaneous Tools Menu" $__SELECTED_ITEM_MISC
    __SELECTED_ITEM_MISC=$?
    unset -f _git_tools _wine_tools _python_env_tools _audiobook _calendar _local_inf _viddown _local_server _screenshot
    __BWBH_SAVE_CONFIG_tools
    _codex_unset
}
function hsearch {
    if [[ "$#" -eq 0 ]]; then
        history 25
        return 0
    fi
    history | grep -v "hsearch" | grep --color=auto -i "$*"
}   

# END 