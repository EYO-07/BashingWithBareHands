# BEGIN : ~/Toolbox/net_tools.sh
# {TextMarker|magenta:turnNetworkOff|cyan:turnOffNetwork}
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -- dependencies
# 1. nmcli NetworkManager 

# -- description
function tools {
    source "$_SCRIPT_DIR/_codex.sh"
    local width=7
    toolbox_title "Networking Tools"
    info_echo "... terminal user interface wrapper for nmcli (NetworkManager)"
    toolbox_item "tools" "print this ..." $width
    toolbox_item "inv" "print built-in commands ..." $width
    toolbox_item "showNetworkDevices" "Display status of all network devices" $width
    #toolbox_item "showConnections" "List all saved connection profiles" $width
    toolbox_item "turnNetworkOn / turnOffNetwork" "enable / disable all networking" $width
    toolbox_item "wifiList" "Scan and list available WiFi networks" $width
    toolbox_item "wifiConnect <SSID>" "Connect to a WiFi network by SSID" $width
    toolbox_item "turnWifiOn / turnWifiOff" "Enable / Disable WiFi radio only" $width
    toolbox_item "turnConnectionUp" "Activate a specific connection by connection or device name" $width
    toolbox_item "turnDownConnection" "Deactivate a specific connection" $width
    toolbox_item "turnDeviceDown" "turn down an internet interface device" $width
    toolbox_item "renameConnection" "rename an existing connection" $width
    toolbox_item "deleteConnection" "Delete a connection profile" $width
    toolbox_item "enable_ipv6 <NAME>" "Enable IPv6 (auto) for a specific connection" $width
    toolbox_item "disable_ipv6 <NAME>" "Disable IPv6 for a specific connection" $width
    toolbox_item "setConnectionMetric" "set connection metric, the lower the metric, higher the connection preference." $width
    toolbox_item "shareConnection" "creates an access point for other devices to access internet" $width
    toolbox_item "connectionInfo" "short connection information" $width
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

# Aliases for quick status checks and global toggles
alias showNetworkDevices='nmcli device status'
alias showConnections='nmcli connection show'
alias turnNetworkOn='nmcli networking on'
alias turnOffNetwork='nmcli networking off'

# WiFi Management
# Ensures radio is on before listing, then lists available APs
alias wifiList='nmcli radio wifi on && nmcli device wifi list'
alias turnWifiOff='nmcli radio wifi off'
alias turnWifiOn='nmcli radio wifi on'
function wifiConnect {
    source "$_SCRIPT_DIR/_codex.sh"
    if [[ -z "$1" ]]; then
        echo "Error: SSID required."
        wifiList
        echo "Usage: wifiConnect <SSID>"
        _codex_unset
        return 1
    fi
    # Quotes handle SSIDs with spaces
    nmcli device wifi connect "$1"
    _codex_unset
}

# Delete a connection profile permanently
function deleteConnection {
    source "$_SCRIPT_DIR/_codex.sh"
    if [[ -z "$1" ]]; then
        crit_echo "Error: Connection name required."
        showConnections
        echo "Usage: deleteConnection <CONNECTION_NAME>"
        _codex_unset
        return 1
    fi
    if ! token_prompt "Confirmation" "delete this connection $* ?" ; then 
        return 0
    fi
    # "$*" combines all arguments into a single string separated by spaces
    if ! nmcli connection delete "$*"; then 
        crit_echo "Failed to Delete"
        _codex_unset
        return 1
    fi
    _codex_unset
    return 0
}
function turnDownConnection {
    source "$_SCRIPT_DIR/_codex.sh"
    if [[ -z "$1" ]]; then
        crit_echo "Error: Connection name required."
        warn_echo "Usage: turnDownConnection <CONNECTION_NAME>"
        showConnections
        _codex_unset
        return 1
    fi
    nmcli connection down "$1"
    _codex_unset
}
function turnConnectionUp {
    source "$_SCRIPT_DIR/_codex.sh"
    if [[ -z "$1" ]]; then
        crit_echo "Error: Connection name required."
        warn_echo "Usage: turnConnectionUp <CONNECTION_NAME>"
        showConnections
        _codex_unset
        return 1
    fi
    nmcli connection up "$1"
    _codex_unset
}
function turnDeviceDown {
    source "$_SCRIPT_DIR/_codex.sh"
    if [[ -z "$1" ]]; then
        crit_echo "Error: internet interface device name required."
        warn_echo "Usage: turnDeviceDown <CONNECTION_NAME>"
        showConnections
        _codex_unset
        return 1
    fi
    nmcli device disconnect "$1"
    _codex_unset
}
#function turnDeviceUp {
    #source "$_SCRIPT_DIR/_codex.sh"
    #if [[ -z "$1" ]]; then
        #crit_echo "Error: internet interface device name required."
        #warn_echo "Usage: turnConnectionUp <CONNECTION_NAME>"
        #showConnections
        #_codex_unset
        #return 1
    #fi
    #nmcli device connect "$1"
    #_codex_unset
#}
function disable_ipv6 {
    source "$_SCRIPT_DIR/_codex.sh"
    if [[ -z "$1" ]]; then
        echo "Error: Connection name required."
        nmcli connection show
        echo "Usage: disable_ipv6 <CONNECTION_NAME>"
        _codex_unset
        return 1
    fi     
    nmcli connection down "$*"
    nmcli connection modify "$*" ipv6.method "disabled"
    nmcli connection up "$*"
    echo "Verification for '$*':"
    nmcli connection show "$*" | grep ipv6.method
    _codex_unset
}
function enable_ipv6 {
    source "$_SCRIPT_DIR/_codex.sh"
    if [[ -z "$1" ]]; then
        echo "Error: Connection name required."
        nmcli connection show
        echo "Usage: enable_ipv6 <CONNECTION_NAME>"
        _codex_unset
        return 1
    fi 
    nmcli connection down "$*"
    nmcli connection modify "$*" ipv6.method "auto"
    nmcli connection up "$*"
    echo "Verification for '$*':"
    nmcli connection show "$*" | grep ipv6.method
    _codex_unset
}

# Helper: Get the connection name associated with a device (e.g., eth0 -> "Wired conn 1")
_get_conn_name() {
    nmcli -g GENERAL.CONNECTION device show "$1" 2>/dev/null
}
function listConnectionPreferences {
    source "$_SCRIPT_DIR/_codex.sh"
    echo "Current Routing Preference (Lowest Metric = Preferred):"
    # Parse 'ip route' correctly:
    # Format: default via <GW> dev <DEV> ... metric <METRIC>
    # We extract the device ($4), gateway ($3), and search for the metric value at the end
    ip route | grep "^default" | while read -r line; do
        dev=$(echo "$line" | awk '{for(i=1;i<=NF;i++) if($i=="dev") print $(i+1)}')
        gw=$(echo "$line" | awk '{for(i=1;i<=NF;i++) if($i=="via") print $(i+1)}')
        metric=$(echo "$line" | awk '{for(i=1;i<=NF;i++) if($i=="metric") print $(i+1)}')
        # Fallback if no metric is specified (kernel default is usually 0 or 100)
        metric=${metric:-0}
        conn=$(_get_conn_name "$dev")
        echo "Metric: $metric | Device: $dev | Gateway: $gw | Connection: ${conn:-N/A}"
    done | sort -t: -k2 -n
    _codex_unset
}   
function setConnectionMetric {
    source "$_SCRIPT_DIR/_codex.sh"
    # setConnectionMetric <interface_name> <metric_value>
    local dev="$1"
    local metric="$2"
    if [ -z "$dev" ] || [ -z "$metric" ]; then
        warn_echo "Usage: setConnectionMetric <interface_name> <metric_value>"
        echo "... this function only works for multiple device sources."
        echo "... is not intended to manage multiple connections on same device."
        listConnectionPreferences 
        _codex_unset
        return 1
    fi
    local conn=$(_get_conn_name "$dev")
    if [ -z "$conn" ]; then
        color_echo 31 "Error: No active connection found for device $dev"
        _codex_unset
        return 1
    fi
    color_echo 36 "Setting metric $metric for $conn ($dev) ..."
    # Apply metric 
    # saved to /etc/NetworkManager/system-connections/
    if ! nmcli connection modify "$conn" ipv4.route-metric "$metric"; then
        color_echo 31 "Error: Failed to modify connection profile."
        _codex_unset
        return 1
    fi
    # Attempt smooth reapply first (least disruptive)
    # Note: Route metrics often require a full bounce, so we expect this might fail.
    if nmcli device reapply "$dev" 2>/dev/null; then
        color_echo 32 "Changes applied smoothly via reapply."
    else
        # Fallback: Full bounce (required for routing changes)
        color_echo 33 "Reapply not supported for metrics; bouncing connection..."
        nmcli connection down "$conn" >/dev/null 2>&1
        sleep 1
        nmcli connection up "$conn" >/dev/null 2>&1
        # Verify it came back up
        if ! nmcli device status | grep -q "$dev.*connected"; then
            color_echo 31 "Warning: Device $dev did not reconnect automatically."
            _codex_unset
            return 1
        fi
    fi
    color_echo 33 "Done."
    listConnectionPreferences
    _codex_unset
}

# --
function shareConnection {
    source "$_SCRIPT_DIR/_codex.sh"
    # Validate argument count
    if [ $# -lt 2 ] || [ $# -gt 3 ]; then
        warn_echo "USAGE: shareConnection <interface_type> <interface_name> [ <connection_name> ]"
        echo "... the interface_name is the interface where other devices access the shared internet."
        echo "... Example: shareConnection ethernet enp4s0 shared-lan"
        _codex_unset
        return 1 # Return error code on failure
    fi
    local type="$1"
    local ifname="$2"
    # Use provided name or default to 'shared-lan'
    local con_name="${3:-shared-lan}"
    # Create the shared connection
    # ipv4.method shared enables IP forwarding, masquerading, and dnsmasq automatically
    if ! nmcli connection add type "$type" con-name "$con_name" ifname "$ifname" ipv4.method shared ipv6.method shared; then
        warn_echo "Failed to create connection '$con_name'"
        _codex_unset
        return 1
    fi
    # Activate the connection
    if ! nmcli connection up "$con_name"; then
        warn_echo "Failed to activate connection '$con_name'"
        _codex_unset
        return 1
    fi
    _codex_unset
    return 0
}
function connectionInfo {
    # Source the helper script for utility functions like showConnections and _codex_unset
    source "$_SCRIPT_DIR/_codex.sh"
    # Check if a connection name was provided
    if [[ -z "$1" ]]; then
        warn_echo "Usage: connectionInfo <CONNECTION_NAME>"
        showConnections
        _codex_unset
        return 1
    fi
    local conn_name="$*"
    # Verify if the connection exists before attempting to show details
    if ! nmcli connection show "$conn_name" &>/dev/null; then
        crit_echo "Error: Connection '$conn_name' not found."
        showConnections
        _codex_unset
        return 1
    fi
    warn_echo "=== Connection Details: $conn_name ==="
    # Show general connection info (UUID, type, device)
    info_echo "[General Information]"
    nmcli connection show "$conn_name" | grep --color=never -E "^(connection.id|connection.type|connection.interface-name|general.state)"
    # Show IPv4 settings
    info_echo "[IPv4 Settings]"
    # Extract address, gateway, and DNS. 
    # Note: 'connection show' displays stored profile config, not necessarily runtime state.
    nmcli connection show "$conn_name" | grep --color=never -E "^(ipv4.addresses|ipv4.gateway|ipv4.dns|ipv4.method|IP4.ADDRESS|IP4.GATEWAY)"
    # Show IPv6 settings
    info_echo "[IPv6 Settings]"
    nmcli connection show "$conn_name" | grep --color=never -E "^(ipv6.addresses|ipv6.gateway|ipv6.dns|ipv6.method|IP6.ADDRESS|IP6.GATEWAY)"
    _codex_unset
    return 0
}   

# NEW FUNCTIONS >>>
# REFACTORED FUNCTIONS >>> 
function turnConnectionUp {
    # 1. this function is designed to be direct user interface
    source "$_SCRIPT_DIR/_codex.sh"
    if [[ -z "$1" ]]; then
        crit_echo "Error: Connection name required."
        warn_echo "Usage: turnConnectionUp <CONNECTION_NAME>"
        warn_echo "Usage: turnConnectionUp <DEVICE_NAME>"
        showConnections
        _codex_unset
        return 0
    fi
    info_echo "Assuming the name is a connection ..."
    if nmcli connection up "$1"; then 
        good_echo "Connection Established"
        _codex_unset
        return 0
    fi 
    warn_echo "Failed to connect, assuming the name is a device ..."
    if nmcli device connect "$1"; then 
        good_echo "Connection Established"
        _codex_unset
        return 0
    fi 
    _codex_unset
    return 1
}
function renameConnection {
    source "$_SCRIPT_DIR/_codex.sh"
    # 1. Validate arguments (still need at least 2)
    if [[ -z "$1" || -z "$2" ]]; then
        crit_echo "Error: Current name and new name required."
        warn_echo "Usage: renameConnection <CURRENT_NAME> <NEW_NAME>"
        showConnections
        _codex_unset
        return 1
    fi
    local current_name="$1"
    shift
    local new_name="$*"
    if ! nmcli connection show "$current_name" &> /dev/null; then
        crit_echo "Error: Connection '$current_name' not found."
        _codex_unset
        return 1
    fi
    if nmcli connection modify "$current_name" connection.id "$new_name"; then
        good_echo "Connection renamed from '$current_name' to '$new_name'."
        _codex_unset
        return 0
    else
        crit_echo "Error: Failed to rename connection."
        _codex_unset
        return 1
    fi
}   

# END   
















