# BEGIN : Toolbox/i3_tools.sh
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -- dependencies
# i3 window manager
# jq for json manipulation

# -- description
function tools {
    source "$_SCRIPT_DIR/_codex.sh"
    local width=6
    toolbox_title "i3 Window Manager Tools"
    toolbox_item "tools" "print this ..." $width
    toolbox_item "inv" "print built-in commands ..." $width
    toolbox_item "listApplications" "list applications on active workspaces" $width
    toolbox_item "toggleAllWindowsFloatMode" "toggle float mode for all windows in current workspace" $width
    toolbox_item "transferApplications" "transfers all tiling applications from the current workspace to the specified one" $width
    toolbox_item "closeApplications" "sends a safe closing message (SIGTERM) to all applications in the specified workspace" $width
    #toolbox_item "..." "..." $width
    toolbox_endl
    _codex_unset
}
tools 
function inv {
    source "$_SCRIPT_DIR/_codex.sh"
    inventory_title "i3 Window Manager Tools"
    local width=3
    inventory_item 1 "..." "..." $width
    inventory_endl 
    _codex_unset
    return 0
}

# -- implementation 
function toggleAllWindowsFloatMode {
    source "$_SCRIPT_DIR/_codex.sh"
    # 1. Identify the currently focused workspace name
    local current_ws
    current_ws=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused == true) | .name')
    if [[ -z "$current_ws" ]]; then
        error_echo "Could not determine the current workspace."
        _codex_unset
        return 1
    fi
    info_echo "toggling mode on workspace: $current_ws"
    # 2. Extract window IDs (container IDs) from the focused workspace
    # We look for nodes within the specific workspace that have a 'window' property (actual apps)
    # or are standard containers 'con' inside that workspace.
    local ids
    ids=$(i3-msg -t get_tree | jq -r --arg ws "$current_ws" '
        .. | objects | 
        select(.type == "workspace" and .name == $ws) | 
        .. | objects | 
        select(.type == "con" and .window != null) | 
        .id
    ')
    if [[ -z "$ids" ]]; then
        info_echo "No tiling windows found on this workspace."
        _codex_unset
        return 0
    fi
    # 3. Iterate and apply floating + resize
    # Using a while loop to handle potential multi-line output from jq safely
    echo "$ids" | while read -r win_id; do
        if [[ -n "$win_id" ]]; then
            # Toggle floating (if already floating, this might un-float, usually we want 'floating enable')
            # Using 'floating toggle' as per request context, but 'floating enable' is safer for "make float"
            i3-msg "[con_id=$win_id] floating toggle"
        fi
    done
    _codex_unset
    return 0
}   
function transferApplications {
    # Usage: transferApplications <workspace_label>
    # Transfers all tiling applications from the current workspace to the specified one.
    source "$_SCRIPT_DIR/_codex.sh"
    if [[ -z "$1" ]]; then
        warn_echo "Usage: transferApplications <workspace_label>"
        _codex_unset
        return 1
    fi
    local target_ws="$1"
    local current_ws
    local ids
    # 1. Identify current workspace
    current_ws=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused == true) | .name')
    if [[ "$current_ws" == "$target_ws" ]]; then
        info_echo "Source and target workspaces are the same."
        _codex_unset
        return 0
    fi
    info_echo "Transferring windows from '$current_ws' to '$target_ws'..."
    # 2. Get container IDs of tiling windows in current workspace
    # We select 'con' with a '.window' property to ignore empty containers or the workspace itself
    ids=$(i3-msg -t get_tree | jq -r --arg ws "$current_ws" '
        .. | objects | 
        select(.type == "workspace" and .name == $ws) | 
        .. | objects | 
        select(.type == "con" and .window != null) | 
        .id
    ')
    if [[ -z "$ids" ]]; then
        info_echo "No tiling windows found to transfer."
        _codex_unset
        return 0
    fi
    # 3. Move each window to the target workspace
    echo "$ids" | while read -r win_id; do
        if [[ -n "$win_id" ]]; then
            i3-msg "[con_id=$win_id] move container to workspace $target_ws" > /dev/null
        fi
    done
    info_echo "Transfer complete."
    _codex_unset
    return 0
}   
function closeApplications {
    # Usage: closeApplications <workspace_label>
    # Sends a safe closing message (SIGTERM) to all applications in the specified workspace.
    source "$_SCRIPT_DIR/_codex.sh"
    local target_ws="$1"
    # Fallback to current workspace if argument is missing but user called it
    if [[ -z "$target_ws" ]]; then
        target_ws=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused == true) | .name')
        if [[ -z "$target_ws" ]]; then
            crit_echo "Could not determine target workspace."
            listApplications
            _codex_unset
            return 1
        fi
        info_echo "No workspace specified, targeting current: $target_ws"
    fi
    info_echo "Closing applications on workspace: $target_ws"
    # Get window IDs
    local ids
    ids=$(i3-msg -t get_tree | jq -r --arg ws "$target_ws" '
        .. | objects | 
        select(.type == "workspace" and .name == $ws) | 
        .. | objects | 
        select(.type == "con" and .window != null) | 
        .id
    ')
    if [[ -z "$ids" ]]; then
        info_echo "No windows found to close."
        _codex_unset
        return 0
    fi
    # Kill windows
    echo ""
    listApplications $target_ws ; source "$_SCRIPT_DIR/_codex.sh"
    if token_prompt "Confirmation" "closing windows on $target_ws"; then 
        echo "$ids" | while read -r win_id; do
            if [[ -n "$win_id" ]]; then
                # 'kill' in i3-msg sends the standard close request to the window
                i3-msg "[con_id=$win_id] kill" > /dev/null
            fi
        done
    fi
    _codex_unset
    return 0
}
function listApplications {
    source "$_SCRIPT_DIR/_codex.sh"    
    local target_ws="$1"
    local tree
    tree=$(i3-msg -t get_tree)

    # Determine output header based on argument
    if [[ -n "$target_ws" ]]; then
        info_echo "Applications on Workspace '$target_ws':"
    else
        info_echo "Active Workspaces & Windows:"
    fi
    # Optimized jq query:
    # 1. If $target_ws is provided, filter workspaces by name immediately.
    # 2. Traverse to find containers with window properties.
    # 3. Format output.
    local query='
      [
        recurse(.nodes[]?) | 
        objects | 
        select(.type == "workspace") | 
        '
    # Add workspace filter if argument exists
    if [[ -n "$target_ws" ]]; then
        query+="select(.name == \"$target_ws\") | "
    fi
    query+='
        {
          ws_name: .name,
          windows: [
            .. | objects | 
            select(.type == "con" or .type == "floating_con") | 
            select(.window_properties != null) | 
            "\(.window_properties.class) - \(.window_properties.title)"
          ]
        } | 
        select(.windows | length > 0)
      ] | 
      .[] | 
      "Workspace: \(.ws_name)\n" + (.windows | map("  -> " + .) | join("\n"))
    '
    # Execute query
    local result
    result=$(echo "$tree" | jq -r "$query")
    if [[ -z "$result" ]]; then
        if [[ -n "$target_ws" ]]; then
            info_echo "No windows found on workspace '$target_ws'."
        else
            info_echo "No windows found on any workspace."
        fi
    else
        echo "$result"
    fi
    _codex_unset
}   

# END