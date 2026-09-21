# BEGIN : Toolbox/services_tools.sh 
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -- dependencies
# 1. systemctl cli tool 
# 2. sudo privileges

# -- description
function tools {
    source "$_SCRIPT_DIR/_codex.sh"
    local width=9
    toolbox_title "Services Management Tools"
    toolbox_item "tools" "print this ..." $width
    if all_commands_valid "systemctl" "grep"; then 
        toolbox_item "serviceStatus <unit>" "show detailed status and recent logs" $width
        toolbox_item "serviceRestart <unit>" "stop and start service immediately" $width
        toolbox_item "serviceReload <unit>" "reload config without dropping connections" $width
        toolbox_item "serviceEnable <unit>" "enable service to start at next boot" $width
        toolbox_item "serviceDisable <unit>" "..." $width
        toolbox_item "serviceActivate <unit>" "enable and start service immediately" $width
        toolbox_item "serviceDeactivate <unit>" "..." $width
        toolbox_item "daemonReload" "reload systemd manager config (after editing unit files)" $width
        toolbox_item "resetFailed [unit]" "clear 'failed' state from one or all units" $width
        toolbox_item "listServices [ <keyword1> <keyword2> ... ]" "list ALL registered service unit files on disk" $width
        toolbox_item "listRunningServices" "list services currently in 'running' state" $width
        toolbox_item "listActiveServices" "list services 'active' (includes running, exited, waiting)" $width
        toolbox_item "listFailedServices" "list services currently in 'failed' state" $width
        toolbox_item "showFailed" "detailed view of failed units only" $width
        toolbox_item "systemHealth" "check overall system state (running/degraded/maintenance)" $width
    else 
        info_echo "... requires: systemctl (systemd), grep"
    fi 
    toolbox_endl
    _codex_unset
}
tools 

# -- helpers
function _list_services_by_state {
    local state="$1"
    shift
    local -a cmd=(systemctl list-units --type=service --state="$state" --no-legend --no-pager)
    if [ $# -eq 0 ]; then
        "${cmd[@]}"
    else
        local output
        output="$("${cmd[@]}")"
        for keyword in "$@"; do
            output=$(printf '%s\n' "$output" | grep -- "$keyword")
        done
        [[ -n "$output" ]] && printf '%s\n' "$output"
    fi
}

# -- implementation 
function serviceStatus {
    if [ $# -ne 1 ]; then 
        listServices
        echo "Usage: serviceStatus <unit_name>"
        return 1
    fi
    sudo systemctl status "$1"
}
function serviceRestart {
    source "$_SCRIPT_DIR/_codex.sh"
    if [ $# -ne 1 ]; then 
        warn_echo "Usage: serviceRestart <unit_name>"
        listRunningServices
        _codex_unset
        return 1
    fi
    sudo systemctl restart "$1"
    _codex_unset
}
function serviceReload {
    source "$_SCRIPT_DIR/_codex.sh"
    if [ $# -ne 1 ]; then
        warn_echo "Usage: serviceReload <unit_name>"
        listRunningServices
        _codex_unset
        return 1
    fi
    sudo systemctl reload "$1"
    _codex_unset
}
function serviceEnable {
    source "$_SCRIPT_DIR/_codex.sh"
    if [ $# -ne 1 ]; then 
        warn_echo "Usage: serviceEnable <unit_name>"
        listActiveServices
        _codex_unset
        return 1
    fi
    sudo systemctl enable "$1"
    _codex_unset
}
function serviceDisable {
    source "$_SCRIPT_DIR/_codex.sh"
    if [ $# -ne 1 ]; then 
        warn_echo "Usage: serviceDisable <unit_name>"
        listActiveServices
        _codex_unset
        return 1
    fi
    sudo systemctl disable "$1"
    _codex_unset
}
function serviceActivate {
    source "$_SCRIPT_DIR/_codex.sh"
    # Enables the service for boot AND starts it immediately
    if [ $# -ne 1 ]; then 
        warn_echo "Usage: serviceActivate <unit_name>"
        listRunningServices
        _codex_unset
        return 1
    fi
    sudo systemctl enable --now "$1"
    _codex_unset
}
function serviceDeactivate {
    source "$_SCRIPT_DIR/_codex.sh"
    # Enables the service for boot AND starts it immediately
    if [ $# -ne 1 ]; then 
        warn_echo "Usage: serviceDeactivate <unit_name>"
        listRunningServices
        _codex_unset
        return 1
    fi
    sudo systemctl disable --now "$1"
    _codex_unset
}
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
function listRunningServices {
    source "$_SCRIPT_DIR/_codex.sh"
    _list_services_by_state "running" "$@"
    _codex_unset
}
function listActiveServices {
    # Lists services that are 'active' (includes running, waiting, and exited).
    source "$_SCRIPT_DIR/_codex.sh"
    _list_services_by_state "active" "$@"
    _codex_unset
}
function listFailedServices {
    # Lists services that have failed to start or crashed.
    source "$_SCRIPT_DIR/_codex.sh"
    _list_services_by_state "failed" "$@"
    _codex_unset
}
function listServices {
    source "$_SCRIPT_DIR/_codex.sh"
    local -a cmd=(systemctl list-unit-files --type=service --no-pager --no-legend)
    if [ $# -eq 0 ]; then
        if yn_prompt "This will show all units" "are you sure to display all unit files?"; then 
            "${cmd[@]}"
        else 
            warn_echo "please, insert keywords to filter the list"
        fi
    else
        local output
        output="$("${cmd[@]}")"
        for keyword in "$@"; do
            output=$(printf '%s\n' "$output" | grep -- "$keyword")
        done
        [[ -n "$output" ]] && printf '%s\n' "$output"
    fi
    _codex_unset
}

# END   