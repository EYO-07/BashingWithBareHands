# BEGIN : ~/Toolbox/services_tools.sh 

# -- dependencies
# 1. systemctl cli tool 
# 2. sudo privileges

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
color_echo 33 "=== Services Tools ==="
color_echo 36 "--- Management ---"
echo "serviceStatus <unit>       : show detailed status and recent logs"
echo "serviceRestart <unit>      : stop and start service immediately"
echo "serviceReload <unit>       : reload config without dropping connections"
echo "serviceEnable <unit>       : enable service to start at next boot"
echo "serviceDisable <unit>      : ..."
echo "serviceActivate <unit>     : enable AND start service immediately (--now)"
echo "serviceDeactivate <unit>   : ..."
echo "daemonReload               : reload systemd manager config (after editing unit files)"
echo "resetFailed [unit]         : clear 'failed' state from one or all units"
echo ""
color_echo 36 "--- Socket Activation ---"
echo "serviceSocketEnable <unit> : enable .socket unit (triggers service on traffic)"
echo "serviceSocketDisable <unit>: disable .socket unit immediately"
echo "listServiceSockets         : list ALL registered socket units (active + inactive)"
echo "listListeningSockets       : list sockets currently listening for connections"
echo "listSocketsByService       : list sockets sorted by activated service"
echo "listActiveSockets          : list sockets currently in memory (active)"
echo ""
color_echo 36 "--- Inventory & Health ---"
echo "listServices               : list ALL registered service unit files on disk"
echo "listRunningServices        : list services currently in 'running' state"
echo "listActiveServices         : list services 'active' (includes running, exited, waiting)"
echo "listFailedServices         : list services currently in 'failed' state"
echo "showFailed                 : detailed view of failed units only"
echo "systemHealth               : check overall system state (running/degraded/maintenance)"
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

# -- services 
function listRunningServices {
    # Lists only services currently in the 'running' state.
    # Excludes services that are 'active' but 'exited' (one-off tasks).
    # --no-legend: Removes the header/footer lines for cleaner output.
    # --no-pager: Prevents opening 'less', allowing the output to scroll or be piped.
    systemctl list-units --type=service --state=running --no-legend --no-pager
}
function listActiveServices {
    # Lists services that are 'active' (includes running, waiting, and exited).
    # Useful for seeing services that are loaded and functioning, even if idle.
    systemctl list-units --type=service --state=active --no-legend --no-pager
}
function listFailedServices {
    # Lists services that have failed to start or crashed.
    # Critical for troubleshooting and system health checks.
    systemctl list-units --type=service --state=failed --no-legend --no-pager
}   
function listServices {
    # Lists ALL available registered service unit files on the system.
    # Includes enabled, disabled, static, and masked services.
    # Unlike 'list-units', this shows services not currently loaded in memory.
    # --no-pager: Prevents opening 'less' for script-friendly output.
    # --no-legend: Removes the summary line for cleaner parsing.
    systemctl list-unit-files --type=service --no-pager --no-legend
}
function serviceStatus {
    if [ $# -ne 1 ]; then 
        listServices
        echo "Usage: serviceStatus <unit_name>"
        return 1
    fi
    sudo systemctl status "$1"
}
function serviceRestart {
    if [ $# -ne 1 ]; then 
        listRunningServices
        echo "Usage: serviceRestart <unit_name>"
        return 1
    fi
    sudo systemctl restart "$1"
}
function serviceReload {
    if [ $# -ne 1 ]; then
        listRunningServices
        echo "Usage: serviceReload <unit_name>"
        return 1
    fi
    sudo systemctl reload "$1"
}
function serviceEnable {
    if [ $# -ne 1 ]; then 
        listActiveServices
        echo "Usage: serviceEnable <unit_name>"
        return 1
    fi
    sudo systemctl enable "$1"
}
function serviceDisable {
    if [ $# -ne 1 ]; then 
        listActiveServices
        echo "Usage: serviceDisable <unit_name>"
        return 1
    fi
    sudo systemctl disable "$1"
}
function serviceActivate {
    # Enables the service for boot AND starts it immediately
    if [ $# -ne 1 ]; then 
        listRunningServices
        echo "Usage: serviceActivate <unit_name>"
        return 1
    fi
    sudo systemctl enable --now "$1"
}
function serviceDeactivate {
    # Enables the service for boot AND starts it immediately
    if [ $# -ne 1 ]; then 
        listRunningServices
        echo "Usage: serviceDeactivate <unit_name>"
        return 1
    fi
    sudo systemctl disable --now "$1"
}

# -- system management (add to implementation section)
function daemonReload {
    # Reloads systemd manager configuration.
    # MUST be run after creating, deleting, or editing any .service or .socket file.
    # Does not restart services; only updates systemd's internal dependency tree.
    sudo systemctl daemon-reload
}
function resetFailed {
    # Clears the "failed" state from one or all units.
    # Usage: resetFailed [unit_name]
    # If no unit is provided, resets ALL failed units on the system.
    # Useful when a service hits its restart limit and systemd refuses to start it.
    if [ $# -eq 0 ]; then
        sudo systemctl reset-failed
    else
        sudo systemctl reset-failed "$1"
    fi
}
function systemHealth {
    # Checks the overall operational state of the system.
    # Returns: 
    #   'running'   : System fully up and healthy.
    #   'degraded'  : System up, but one or more units have failed.
    #   'initializing' : System still booting.
    #   'maintenance' : Rescue mode.
    # Exit code 0 only if 'running'.
    systemctl is-system-running --wait
}
function showFailed {
    # Detailed view of failed units only.
    # Shortcut for troubleshooting 'degraded' system state.
    systemctl --failed --no-pager --no-legend
}   

# END   