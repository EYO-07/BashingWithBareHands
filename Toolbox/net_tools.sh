# BEGIN : ~/Toolbox/net_tools.sh

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
echo "showNetworkDevices      : Display status of all network devices"
echo "showConnections         : List all saved connection profiles"
echo "turnNetworkOn           : Enable all networking"
echo "turnNetworkOff          : Disable all networking"
echo "wifiList                : Scan and list available WiFi networks"
echo "turnWifiOff             : Disable WiFi radio only"
echo "turnWifiOn              : Enable WiFi radio only"
echo "wifiConnect <SSID>      : Connect to a WiFi network by SSID"
echo "deleteConnection <NAME> : Delete a connection profile"
echo "turnConnectionDown <NAME>: Deactivate a specific connection"
echo "disable_ipv6 <NAME>     : Disable IPv6 for a specific connection"
echo "enable_ipv6 <NAME>      : Enable IPv6 (auto) for a specific connection"
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
    nmcli connection delete "$1"
}

# Deactivate a connection (disconnect)
function turnConnectionDown {
    if [[ -z "$1" ]]; then
        echo "Error: Connection name required."
        showConnections
        echo "Usage: turnConnectionDown <CONNECTION_NAME>"
        return 1
    fi
    # FIXED: Added missing "$1" argument
    nmcli connection down "$1"
}

# Disable IPv6 for a specific connection profile
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

# Enable IPv6 (Auto) for a specific connection profile
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

# END   