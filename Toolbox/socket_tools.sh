# BEGIN : Toolbox/socket_tools.sh 
# ... for sockets instead of services 

# -- dependencies
# 1. systemctl cli command {systemd}

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
    if [ "$#" -gt 0 ]; then
        echo -e "\e[${color}m$@\e[0m"
    else
        while IFS= read -r line; do
            echo -e "\e[${color}m${line}\e[0m"
        done
    fi
}
function warn_echo {
    color_echo 33 "$@"
}
function crit_echo {
    color_echo 31 "$@"
}

echo ""
color_echo 33 "=== Socket Tools ==="
echo "serviceSocketEnable <unit> : enable .socket unit (triggers service on traffic)"
echo "serviceSocketDisable <unit>: disable .socket unit immediately"
echo "listServiceSockets         : list ALL registered socket units (active + inactive)"
echo "listListeningSockets       : list sockets currently listening for connections"
echo "listSocketsByService       : list sockets sorted by activated service"
echo "listActiveSockets          : list sockets currently in memory (active)"
echo ""

# -- implementation 

# -- sockets
function listServiceSockets {
    # Lists all available socket units (both active and inactive).
    # Socket units allow services to start on-demand when traffic hits the port.
    # --all: Shows inactive sockets (not just currently listening ones).
    # --no-pager: Prevents opening 'less' for script-friendly output.
    # --no-legend: Removes the summary line for cleaner parsing.
    systemctl list-sockets --all --no-pager --no-legend
}
function listListeningSockets {
    # Lists only sockets currently actively listening for connections.
    # Excludes inactive or disabled sockets.
    systemctl list-sockets --no-pager --no-legend
}
function listSocketsByService {
    # Lists sockets sorted by the service they activate.
    # Useful to see which service triggers on which port/path.
    systemctl list-sockets --all --no-pager --no-legend | sort -k4
}
function listActiveSockets {
    # Lists sockets currently in memory (active)
    # Use 'systemctl list-sockets --all' to see inactive loaded sockets too
    systemctl list-sockets
}
function serviceSocketEnable {
    if [ $# -ne 1 ]; then 
        listActiveSockets
        echo "USAGE: serviceSocketEnable <unit_name>"
        return 1
    fi
    # Enables the socket unit; the associated service starts only when traffic arrives
    sudo systemctl enable --now "$1".socket
}
function serviceSocketDisable {
    if [ $# -ne 1 ]; then 
        listActiveSockets
        echo "USAGE: serviceSocketDisable <unit_name>"
        return 1
    fi
    # Disables and stops the socket listener
    sudo systemctl disable --now "$1".socket
}

# END 