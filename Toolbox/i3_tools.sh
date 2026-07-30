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
function listApplications {
    source "$_SCRIPT_DIR/_codex.sh"    
    local tree
    tree=$(i3-msg -t get_tree)
    info_echo "Active Workspaces & Windows:"
    # Optimized jq query:
    # 1. Traverse the tree to find workspaces.
    # 2. For each workspace, create an object with 'ws_name' and an array of 'windows'.
    # 3. Filter out empty workspaces.
    # 4. Format the output: print header only if windows exist.
    local query='
      [
        recurse(.nodes[]?) | 
        objects | 
        select(.type == "workspace") | 
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
    echo "$tree" | jq -r "$query"
    _codex_unset
}
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

# END