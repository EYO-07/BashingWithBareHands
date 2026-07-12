# BEGIN : ~/Toolbox/net_tools.sh
# {TextMarker|red:_get_gateway}

# -- dependencies
# 1. nmcli NetworkManager 

# -- description

# RED = 31 - 41
# GREEN = 32 - 42
# YELLOW = 33 - 43
# BLUE = 34 - 44
# MAGENTA = 35 - 45
# CYAN = 36 - 46
# WHITE = 37 - 47
function color_echo {
    local color=$1
    shift
    echo -e "\e[${color}m$@\e[0m"
}

echo ""
color_echo 33 "=== Networking Tools ==="
echo "showNetworkDevices           : Display status of all network devices"
echo "    showConnections          : List all saved connection profiles"
echo "turnNetworkOn                : Enable all networking"
echo "    turnNetworkOff           : Disable all networking"
echo "wifiList                     : Scan and list available WiFi networks"
echo "wifiConnect <SSID>           : Connect to a WiFi network by SSID"
echo "turnWifiOn                   : Enable WiFi radio only"
echo "    turnWifiOff              : Disable WiFi radio only"
echo "turnConnectionUp <NAME>      : Activate a specific connection"
echo "    turnConnectionDown <NAME>: Deactivate a specific connection"
echo "deleteConnection <NAME>      : Delete a connection profile"
echo "enable_ipv6 <NAME>           : Enable IPv6 (auto) for a specific connection"
echo "    disable_ipv6 <NAME>      : Disable IPv6 for a specific connection"
echo "listConnectionPreferences    : List the Connections Metric (lower~preferred)"
echo "setConnectionMetric <interface_name> <metric_value> : ..."
echo ""

# -- implementation

# Aliases for quick status checks and global toggles
alias showNetworkDevices='nmcli device status'
alias showConnections='nmcli connection show'
alias turnNetworkOn='nmcli networking on'
alias turnNetworkOff='nmcli networking off'

# WiFi Management
# Ensures radio is on before listing, then lists available APs
alias wifiList='nmcli radio wifi on && nmcli device wifi list'
alias turnWifiOff='nmcli radio wifi off'
alias turnWifiOn='nmcli radio wifi on'

# Connect to WiFi by SSID
function wifiConnect {
    if [[ -z "$1" ]]; then
        echo "Error: SSID required."
        wifiList
        echo "Usage: wifiConnect <SSID>"
        return 1
    fi
    # Quotes handle SSIDs with spaces
    nmcli device wifi connect "$1"
}

# Delete a connection profile permanently
function deleteConnection {
    if [[ -z "$1" ]]; then
        echo "Error: Connection name required."
        showConnections
        echo "Usage: deleteConnection <CONNECTION_NAME>"
        return 1
    fi
    # "$*" combines all arguments into a single string separated by spaces
    nmcli connection delete "$*"
}
function turnConnectionDown {
    if [[ -z "$1" ]]; then
        echo "Error: Connection name required."
        showConnections
        echo "Usage: turnConnectionDown <CONNECTION_NAME>"
        return 1
    fi
    nmcli connection down "$1"
}
function turnConnectionUp {
    if [[ -z "$1" ]]; then
        echo "Error: Connection name required."
        showConnections
        echo "Usage: turnConnectionUp <CONNECTION_NAME>"
        return 1
    fi
    nmcli connection up "$1"
}
function disable_ipv6 {
    if [[ -z "$1" ]]; then
        echo "Error: Connection name required."
        nmcli connection show
        echo "Usage: disable_ipv6 <CONNECTION_NAME>"
        return 1
    fi 
    
    nmcli connection down "$1"
    nmcli connection modify "$1" ipv6.method "disabled"
    nmcli connection up "$1"
    
    echo "Verification for '$1':"
    nmcli connection show "$1" | grep ipv6.method
}
function enable_ipv6 {
    if [[ -z "$1" ]]; then
        echo "Error: Connection name required."
        nmcli connection show
        echo "Usage: enable_ipv6 <CONNECTION_NAME>"
        return 1
    fi 
    
    nmcli connection down "$1"
    nmcli connection modify "$1" ipv6.method "auto"
    nmcli connection up "$1"
    
    echo "Verification for '$1':"
    nmcli connection show "$1" | grep ipv6.method
}

# Helper: Get the connection name associated with a device (e.g., eth0 -> "Wired conn 1")
_get_conn_name() {
    nmcli -g GENERAL.CONNECTION device show "$1" 2>/dev/null
}
function listConnectionPreferences {
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
}   
function setConnectionMetric {
    # setConnectionMetric <interface_name> <metric_value>
    local dev="$1"
    local metric="$2"
    if [ -z "$dev" ] || [ -z "$metric" ]; then
        listConnectionPreferences 
        color_echo 33 "Usage: setConnectionMetric <interface_name> <metric_value>"
        return 1
    fi
    local conn=$(_get_conn_name "$dev")
    if [ -z "$conn" ]; then
        color_echo 31 "Error: No active connection found for device $dev"
        return 1
    fi
    color_echo 36 "Setting metric $metric for $conn ($dev) ..."
    # Apply metric 
    # saved to /etc/NetworkManager/system-connections/
    if ! nmcli connection modify "$conn" ipv4.route-metric "$metric"; then
        color_echo 31 "Error: Failed to modify connection profile."
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
            return 1
        fi
    fi
    listConnectionPreferences
    color_echo 33 "Done."
}

# END   
















