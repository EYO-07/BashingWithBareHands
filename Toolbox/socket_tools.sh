# BEGIN : Toolbox/socket_tools.sh 
# ... for sockets instead of services 

# -- dependencies
# 1. systemctl cli command {systemd}

# -- description 
function tools {
    source "$_SCRIPT_DIR/_codex.sh"
    local width=6
    toolbox_title "Service-Sockets Tools"
    info_echo "... sockets trigger services demanded by processes, requires: systemctl"
    toolbox_item "tools" "print this ..." $width
    #toolbox_item "inv" "print built-in commands ..." $width
    toolbox_item "serviceSocketEnable <unit>" "enable .socket unit (triggers service on traffic)" $width
    toolbox_item "serviceSocketDisable <unit>" "disable .socket unit immediately" $width
    toolbox_item "listServiceSockets" "list ALL registered socket units (active + inactive)" $width
    toolbox_item "listListeningSockets" "list sockets currently listening for connections" $width
    toolbox_item "listSocketsByService" "list sockets sorted by activated service" $width
    toolbox_item "listActiveSockets" "list sockets currently in memory (active)" $width
    toolbox_endl
    _codex_unset
}
tools 

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