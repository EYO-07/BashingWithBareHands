# BEGIN : Toolbox/_codex.sh 
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -- dependencies 

# -- description 
function tools {
    source "$_SCRIPT_DIR/_codex.sh"
    local width=2
    toolbox_title "Bashing With Bare Hands"
    info_echo "... interactive verbose bash aliases and functions"
    toolbox_item "tools" "print this ..." $width
    toolbox_item "bmenu" "bashing with bare hands terminal interactive menu" $width
    toolbox_endl
    _codex_unset
}
tools

__SELECTED_ITEM=0
# -- implementation
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
function _MENU_EXAMPLE {
    source "$_SCRIPT_DIR/_codex.sh"
    # Define the menu items (indexed array)
    my_items=("Create User" "Delete User" "List Users" "View Logs" "Exit")
    # Define the actions (associative array: item label -> command to run)
    declare -A my_actions=(
        ["Create User"]="create_user"
        ["Delete User"]="delete_user"
        ["View Logs"]="view_logs"
        ["Exit"]="return"
        ["List Users"]="list_users"
    )
    # Define the functions that each action calls
    create_user() { echo "Creating a new user..."; }
    delete_user() { echo "Deleting a user..."; }
    list_users()  { echo "Listing all users..."; return 1; }
    view_logs()   { echo "Showing recent logs..."; }
    # Call the menu — pass variable *names*, not values
    INTERACTIVE_MENU my_items my_actions "User Management"
    _codex_unset
}

# END 