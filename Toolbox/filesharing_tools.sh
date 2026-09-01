# BEGIN : Toolbox/filesharing_tools.sh
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -- dependencies
# 1. avahi
# 2. openssh 
# 3. nss-mdns
# 4. rsync

# -- description 
function tools {
    if [[ "$#" -eq 1 ]]; then
        local import_tool="$1"
        if [[ "$import_tool" == "mount" ]]; then
            source "$_SCRIPT_DIR/mounting_tools.sh"
            return 0
        fi 
        if [[ "$import_tool" == "files" ]]; then
            source "$_SCRIPT_DIR/filesystem_tools.sh"
            return 0
        fi 
    fi 
    source "$_SCRIPT_DIR/_codex.sh"
    local width=15
    toolbox_title "File Sharing Tools"
    toolbox_item "tools" "show this ..." $width
    toolbox_item "tools files" "import filesystem tools" $width
    toolbox_item "tools mount" "import mounting tools" $width
    toolbox_item "inv" "show helpful built-in commands" $width
    toolbox_item "checkLocalFileSharingBridge" "check the connection between local network machines" $width
    toolbox_item "remoteShell <remoteusername> <remotehostname>" "open a remote terminal" $width
    toolbox_item "leftload <remoteusername> <remotehostname> <remotepath> [ <localpath> ]" "download from local network machines" $width
    toolbox_item "1. leftload <remoteusername> <remotehostname> <remotepath>" "Lists remote files (Dry Run / Preview)" $width
    toolbox_item "2. leftload <remoteusername> <remotehostname> <remotepath> ." "Starts the download to current directory" $width
    toolbox_item "3. leftload <remoteusername> <remotehostname> <remotepath> /some/path" "Starts the download to specific path" $width
    toolbox_item "activateFileSharingServices" "activate related services for filesharing" $width
    toolbox_item "deactivateFileSharingServices" "deactivate related services for filesharing" $width
    toolbox_endl
    _codex_unset
}
tools
function inv {
    source "$_SCRIPT_DIR/_codex.sh"
    local width=3
    inventory_title "todo"
    inventory_item 1 "..." "..." $width
    inventory_endl
    _codex_unset
}

# -- implementation 
function checkLocalFileSharingBridge {
    source "$_SCRIPT_DIR/_codex.sh"
    # USAGE: checkLocalFileSharingBridge <remotehostname> [ <username> ]
    # 1. check the name resolution
    # 2. prompt for username if not provided
    # 3. check the connection used
    local remote_host="${1:-}"
    local input_user="${2:-}"
    local clean_host
    local target_host
    local ssh_user
    local resolved_ip
    local interface_name
    local gateway_ip
    if [ -z "$remote_host" ]; then
        crit_echo "Error: No remote hostname provided."
        echo "Usage: checkLocalFileSharingBridge <remotehostname> [ <username> ]"
        _codex_unset
        return 1
    fi
    # Strip .local suffix if present for consistency
    clean_host="${remote_host%.local}"
    target_host="${clean_host}.local"
    color_echo 36 "--- Checking Local File Sharing Bridge for: ${target_host} ---"
    # 1. Check if avahi-daemon is running locally
    if ! avahi-daemon --check >/dev/null 2>&1; then
        crit_echo "CRITICAL: avahi-daemon is NOT running on this machine."
        warn_echo "Please start it with: sudo systemctl start avahi-daemon"
        _codex_unset
        return 1
    fi
    color_echo 32 "[OK] avahi-daemon is running locally."
    # 2. Check Name Resolution (Forward Lookup)
    color_echo 33 "Resolving hostname: ${target_host}..."
    resolved_ip=$(avahi-resolve -n -4 "$target_host" 2>/dev/null | awk '{print $2}')
    if [ -z "$resolved_ip" ]; then
        crit_echo "FAILED: Could not resolve ${target_host} to an IP address."
        warn_echo "Ensure the remote machine is on the same network and running avahi-daemon."
        _codex_unset
        return 1
    fi
    color_echo 32 "[OK] Resolved ${target_host} to ${resolved_ip}"
    # 3. Determine Username
    if [ -n "$input_user" ]; then
        ssh_user="$input_user"
        color_echo 33 "Using provided username: ${ssh_user}"
    else
        # Prompt for username if not provided
        # Default suggestion is the current local user or the clean hostname
        local default_suggest="${USER:-$(whoami)}"
        warn_echo "Username not provided."
        read -p "Enter remote username [${default_suggest}]: " -r ssh_user
        # Use default if user just presses enter
        if [ -z "$ssh_user" ]; then
            ssh_user="$default_suggest"
        fi
        color_echo 33 "Using username: ${ssh_user}"
    fi    
    # 3.5 Check Connection Interface (NEW)
    color_echo 33 "Checking network route to ${resolved_ip}..."
    # 'ip route get' returns the interface (dev) and gateway (via) used for the IP
    local route_info
    route_info=$(ip route get "$resolved_ip" 2>/dev/null)
    if [ -n "$route_info" ]; then
        # Extract interface name (after 'dev')
        interface_name=$(echo "$route_info" | grep -oP 'dev \K\S+')
        # Extract gateway if present (after 'via')
        gateway_ip=$(echo "$route_info" | grep -oP 'via \K\S+')
        
        color_echo 32 "[OK] Interface: ${interface_name}"
        if [ -n "$gateway_ip" ]; then
            color_echo 33 "      Gateway: ${gateway_ip}"
        else
            color_echo 33 "      Network: Direct (Local Subnet)"
        fi
    else
        warn_echo "WARNING: Could not determine route interface."
    fi
    # 4. Check SSH Connectivity (Auth Prompt Enabled)
    color_echo 33 "Testing SSH connectivity to ${resolved_ip} as ${ssh_user}..."
    # Removed '-o BatchMode=yes' to allow password prompts
    if ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new "${ssh_user}@${resolved_ip}" "exit" 2>/dev/null; then
        color_echo 32 "[OK] SSH connection successful to ${ssh_user}@${resolved_ip}"
    else
        local exit_code=$?
        if [ $exit_code -eq 130 ]; then
             warn_echo "INFO: SSH connection interrupted by user (Ctrl+C)."
        else
             warn_echo "WARNING: SSH connection test failed."
             warn_echo "If authentication failed, ensure credentials are correct."
             warn_echo "Try manually connecting first: ssh ${ssh_user}@${target_host}"
        fi
    fi
    # 5. Check Rsync availability (Auth Prompt Enabled)
    color_echo 33 "Verifying rsync availability..."
    if ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new "${ssh_user}@${resolved_ip}" "command -v rsync" >/dev/null 2>&1; then
        color_echo 32 "[OK] rsync is available on remote machine."
    else
        crit_echo "FAILED: rsync not found on remote machine or connection failed."
        _codex_unset
        return 1
    fi
    color_echo 32 "=== Bridge Check Complete: ${target_host} is reachable as ${ssh_user} ==="
    _codex_unset
    return 0
}
function remoteShell {
    source "$_SCRIPT_DIR/_codex.sh"
    # USAGE: remoteShell <remoteusername> <remotehostname>
    # Opens an interactive remote terminal session
    local ssh_user="${1:-}"
    local remote_host="${2:-}"
    local clean_host
    local target_host
    local resolved_ip
    if [ -z "$ssh_user" ] || [ -z "$remote_host" ]; then
        crit_echo "Error: Missing arguments."
        echo "Usage: remoteshell <remoteusername> <remotehostname>"
        _codex_unset
        return 1
    fi
    clean_host="${remote_host%.local}"
    target_host="${clean_host}.local"
    color_echo 36 "--- Opening Remote Shell to ${target_host} ---"
    # Resolve hostname
    resolved_ip=$(avahi-resolve -n -4 "$target_host" 2>/dev/null | awk '{print $2}')
    if [ -z "$resolved_ip" ]; then
        resolved_ip="${target_host}" # Fallback to nss-mdns
    fi
    color_echo 33 "Connecting to ${ssh_user}@${resolved_ip}..."
    # Start interactive SSH session
    # -t forces pseudo-terminal allocation (needed for interactive shells)
    ssh -t "${ssh_user}@${resolved_ip}"
    _codex_unset
    return $?
}   
function leftload { 
    source "$_SCRIPT_DIR/_codex.sh"
    # USAGE: leftload <remoteusername> <remotehostname> <remotepath> [ <localpath> ] 
    # 1. leftload <remoteusername> <remotehostname> <remotepath> 
    #    -> Lists remote files (Dry Run / Preview)
    # 2. leftload <remoteusername> <remotehostname> <remotepath> . 
    #    -> Starts the download to current directory
    # 3. leftload <remoteusername> <remotehostname> <remotepath> /some/path 
    #    -> Starts the download to specific path
    local ssh_user="${1:-}"
    local remote_host="${2:-}"
    local remote_path="${3:-}"
    local local_dest="${4:-}"  # Empty by default to trigger "List Mode"
    local clean_host
    local target_host
    local resolved_ip
    local rsync_cmd
    # Validate Required Arguments
    if [ -z "$ssh_user" ] || [ -z "$remote_host" ] || [ -z "$remote_path" ]; then
        crit_echo "Error: Missing required arguments."
        echo "Usage: leftload <remoteusername> <remotehostname> <remotepath> [ <localpath> ]"
        echo ""
        echo "Examples:"
        echo "  leftload alice server.local /home/alice/docs       # List files only"
        echo "  leftload alice server.local /home/alice/docs .     # Download to current dir"
        echo "  leftload alice server.local /home/alice/docs ./bak # Download to ./bak"
        _codex_unset
        return 1
    fi
    # Normalize Hostname
    clean_host="${remote_host%.local}"
    target_host="${clean_host}.local"
    # Resolve Hostname via Avahi
    color_echo 35 "Resolving hostname..."
    resolved_ip=$(avahi-resolve -n -4 "$target_host" 2>/dev/null | awk '{print $2}')
    if [ -z "$resolved_ip" ]; then
        resolved_ip="${target_host}" # Fallback to nss-mdns
    fi
    # MODE 1: LIST ONLY (No destination provided)
    if [ -z "$local_dest" ]; then
        color_echo 36 "--- Remote File List (Preview) ---"
        color_echo 33 "Host: ${ssh_user}@${resolved_ip}"
        color_echo 33 "Path: ${remote_path}"
        echo ""
        # Use remote 'ls' for a clean, familiar output
        # -A: list all except . and ..
        # -F: append indicator (e.g., / for dirs) to entries
        # -C: force column output (auto-detected usually, but ensures formatting)
        ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new \
            "${ssh_user}@${resolved_ip}" "ls -ACF '${remote_path}'"
        
        local exit_code=$?
        echo ""
        
        if [ $exit_code -eq 0 ]; then
            warn_echo "Tip: Add '.' or a path as the 4th argument to download."
            echo "Example: leftload ${ssh_user} ${remote_host} ${remote_path} ."
        else
            crit_echo "Failed to list remote directory (check path or permissions)."
        fi
        _codex_unset
        return $exit_code
    fi   
    # MODE 2: DOWNLOAD (Destination provided)
    color_echo 36 "--- Initiating Leftload (Download) ---"
    color_echo 33 "User: ${ssh_user}"
    color_echo 33 "Host: ${target_host}"
    color_echo 33 "Remote Path: ${remote_path}"
    color_echo 33 "Local Dest: ${local_dest}"
    color_echo 35 "Starting transfer (Ctrl+C to cancel)..."
    # Standard rsync download
    #rsync -avzP -e "ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new" \
    #    "${ssh_user}@${resolved_ip}:${remote_path}" "${local_dest}"
    # Modified rsync command for maximum local usability
    rsync -avzP --no-owner --no-group --no-perms -e "ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new" \
        "${ssh_user}@${resolved_ip}:${remote_path}" "${local_dest}"       
    local exit_code=$?
    if [ $exit_code -eq 0 ]; then
        color_echo 32 "=== Leftload Complete ==="
    elif [ $exit_code -eq 130 ]; then
        warn_echo "=== Leftload Interrupted by User ==="
    else
        crit_echo "=== Leftload Failed with exit code ${exit_code} ==="
    fi
    _codex_unset
    return $exit_code
}   
function activateFileSharingServices {
    source "$_SCRIPT_DIR/_codex.sh"
    warn_echo "--- filesharing services ---"
    color_echo 36 "... note those units are not exclusive for filesharing"
    systemctl list-unit-files --type=service --no-legend --no-pager | grep -iE "avahi-daemon.service|sshd.service" | grep -iE "enabled|disabled"
    # -- Generate Random Token (6 characters, alphanumeric)
    local confirm_token user_input
    confirm_token=$(tr -dc 'A-Z0-9' < /dev/urandom | head -c 6)
    # -- Prompt User
    color_echo 35 "To confirm activation of filesharing units : avahi-daemon, sshd"
    color_echo 32 ">>> $confirm_token <<<"
    read -p "Enter token: " user_input
    if [ "$user_input" == "$confirm_token" ]; then
        color_echo 35 "Token matched ..."
        sudo systemctl enable --now avahi-daemon.service 
        sudo systemctl enable --now sshd.service 
        if [ $? -eq 0 ]; then
            color_echo 32 "=== Activation Successful ==="
            echo "... could be necessary to reboot the system"
            _codex_unset
            return 0
        else
            crit_echo "=== Activation Failed (Permission error?) ==="
            _codex_unset
            return 1
        fi
    else
        crit_echo "=== Cancelled: Token mismatch ==="
        _codex_unset
        return 1
    fi
}
function deactivateFileSharingServices {
    source "$_SCRIPT_DIR/_codex.sh"
    warn_echo "--- filesharing services ---"
    color_echo 36 "... note those units are not exclusive for filesharing"
    systemctl list-unit-files --type=service --no-legend --no-pager | grep -iE "avahi-daemon.service|sshd.service" | grep -iE "enabled|disabled"
    # -- Generate Random Token (6 characters, alphanumeric)
    local confirm_token user_input
    confirm_token=$(tr -dc 'A-Z0-9' < /dev/urandom | head -c 6)
    # -- Prompt User
    color_echo 35 "To confirm deactivation of filesharing units : avahi-daemon, sshd"
    color_echo 32 ">>> $confirm_token <<<"
    read -p "Enter token: " user_input
    if [ "$user_input" == "$confirm_token" ]; then
        color_echo 35 "Token matched ..."
        sudo systemctl disable --now avahi-daemon.service 
        sudo systemctl disable --now sshd.service 
        if [ $? -eq 0 ]; then
            color_echo 32 "=== Deactivation Successful ==="
            echo "... could be necessary to reboot the system"
            _codex_unset
            return 0
        else
            crit_echo "=== Deactivation Failed (Permission error?) ==="
            _codex_unset
            return 1
        fi
    else
        crit_echo "=== Cancelled: Token mismatch ==="
        _codex_unset
        return 1
    fi    
}

# END   