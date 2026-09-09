# BEGIN : Toolbox/_codex.sh 
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -- dependencies 

# -- description 
function tools {
    source "$_SCRIPT_DIR/_codex.sh"
    local width=4
    toolbox_title "Bashing With Bare Hands"
    info_echo "... interactive verbose bash aliases and functions"
    toolbox_item "tools" "print this ..." $width
    toolbox_item "bmenu" "bashing with bare hands terminal interactive menu" $width
    toolbox_item "bmenuFilesystem" "menu for filesystem tools" $width
    toolbox_item "bmenuSystem" "menu for system tools" $width
    toolbox_item "bmenuMiscellaneous" "menu for miscellaneous tools" $width
    toolbox_endl
    _codex_unset
}
tools

# -- implementation
__SELECTED_ITEM=0
function bmenu {
    source "$_SCRIPT_DIR/_codex.sh"
    local bmenu_title="Bashing With Bare Hands"
    trap 'tput cnorm; stty echo' RETURN INT TERM # cleanup on function return 
    stty -echo # disables echo 
    tput civis # hides cursor
    local selected=$__SELECTED_ITEM
    local items=(
        "Reload tools.sh"
        "Files / Filesystem"
        "Mounting Devices / Filesystem Integrity"
        "File Change Mode"
        "Filesharing (RSync)"
        "USB and Removable Storage Devices"
        "Errors"
        "Internet"
        "Processes"
        "Services"
        "Sockets"
        "Audio"
        "Sensors"
        "Git"
        "Date/Calendar"
        "Wine"
        "Python (Environment Management)"
        "Pacman Package Manager"
        "XOrg/X11 Display"
        "i3 Window Manager"
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
        "mounting_tools.sh"
        "change_mode_tools.sh"
        "filesharing_tools.sh"
        "usb_tools.sh"
        "errors_tools.sh"
        "net_tools.sh"
        "processes_tools.sh"
        "services_tools.sh"
        "socket_tools.sh"
        "audio_tools.sh"
        "sensor_tools.sh"
        "git_tools.sh"
        "date_tools.sh"
        "wine_tools.sh"
        "python_env_tools.sh"
        "pacman_tools.sh"
        "display_tools.sh"
        "i3_tools.sh"
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
                echo -e "\033[7m > ${items[$i]} \033[0m"
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
                    source "$_SCRIPT_DIR/$action"
                fi
                break # every action will break 
                ;;
        esac
    done
    __SELECTED_ITEM=$selected
    _codex_unset
}
__SELECTED_ITEM_FILESYSTEM=0
function bmenuFilesystem {
    source "$_SCRIPT_DIR/_codex.sh"
    # Define the menu items (indexed array)
    local items=(
        "Files / Filesystem"
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
    )
    # -- functions
    _files() {
        source "$_SCRIPT_DIR/filesystem_tools.sh"
    }
    _mount() {
        source "$_SCRIPT_DIR/mounting_tools.sh"
    }
    _modes() {
        source "$_SCRIPT_DIR/change_mode_tools.sh"
    }
    _share() {
        source "$_SCRIPT_DIR/filesharing_tools.sh"
    }
    _usb() {
        source "$_SCRIPT_DIR/usb_tools.sh"
    }
    # Call the menu — pass variable *names*, not values
    INTERACTIVE_MENU items actions "Filesystem Tools Menu" $__SELECTED_ITEM_FILESYSTEM
    __SELECTED_ITEM_FILESYSTEM=$?
    unset -f _files _mount _modes _share _usb
    _codex_unset
} 
__SELECTED_ITEM_SYSTEM=0
function bmenuSystem {
    source "$_SCRIPT_DIR/_codex.sh"
    # Define the menu items (indexed array)
    local items=(
        "Errors"
        "Internet"
        "Processes"
        "Services"
        "Sockets"
        "Audio"
        "Sensors"
        "Pacman Package Manager"
        "XOrg/X11 Display"
        "i3 Window Manager"
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
    )
    # -- functions
    _errors() {
        source "$_SCRIPT_DIR/errors_tools.sh"
    }
    _internet() {
        source "$_SCRIPT_DIR/net_tools.sh"
    }
    _processes() {
        source "$_SCRIPT_DIR/processes_tools.sh"
    }
    _services() {
        source "$_SCRIPT_DIR/services_tools.sh"
    }
    _sockets() {
        source "$_SCRIPT_DIR/socket_tools.sh"
    }
    _audio() {
        source "$_SCRIPT_DIR/audio_tools.sh"
    }
    _sensors() {
        source "$_SCRIPT_DIR/sensor_tools.sh"
    }
    _pacman() {
        source "$_SCRIPT_DIR/pacman_tools.sh"
    }
    _display_xorg() {
        source "$_SCRIPT_DIR/display_tools.sh"
    }
    _i3winmanager() {
        source "$_SCRIPT_DIR/i3_tools.sh"
    }
    # Call the menu — pass variable *names*, not values
    INTERACTIVE_MENU items actions "System Tools Menu" $__SELECTED_ITEM_SYSTEM
    __SELECTED_ITEM_SYSTEM=$?
    unset -f _errors _internet _processes _services _sockets _audio _sensors _pacman _display_xorg _i3winmanager
    _codex_unset
} 
__SELECTED_ITEM_MISC=0
function bmenuMiscellaneous {
    source "$_SCRIPT_DIR/_codex.sh"
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
    )
    # -- functions
    _git_tools() {
        source "$_SCRIPT_DIR/git_tools.sh"
    }
    _wine_tools() {
        source "$_SCRIPT_DIR/wine_tools.sh"
    }
    _python_env_tools() {
        source "$_SCRIPT_DIR/python_env_tools.sh"
    }
    _audiobook() {
        source "$_SCRIPT_DIR/audiobook_tools.sh"
    }
    _calendar() {
        source "$_SCRIPT_DIR/date_tools.sh"
    }
    _local_inf() {
        source "$_SCRIPT_DIR/llama_cpp_tools.sh"
    }
    _viddown() {
        source "$_SCRIPT_DIR/video_music_download_tools.sh"
    }
    _local_server() {
        source "$_SCRIPT_DIR/_server_tools.sh"
    }
    _screenshot() {
        source "$_SCRIPT_DIR/screenshot_tools.sh"
    }
    # Call the menu — pass variable *names*, not values
    INTERACTIVE_MENU items actions "Miscellaneous Tools Menu" $__SELECTED_ITEM_MISC
    __SELECTED_ITEM_MISC=$?
    unset -f _git_tools _wine_tools _python_env_tools _audiobook _calendar _local_inf _viddown _local_server _screenshot
    _codex_unset
}

# END 