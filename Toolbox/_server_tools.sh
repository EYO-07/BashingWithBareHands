# BEGIN : EXPERIMENTAL, dont use it blindly 
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -- description
function tools {
    source "$_SCRIPT_DIR/_codex.sh"
    local width=4
    toolbox_title "Server Tools"
    toolbox_item "tools" "print this ..." $width
    toolbox_item "inv" "print built-in commands ..." $width
    toolbox_item "setTempLocalServer" "set temporary python local server on current directory" $width
    toolbox_endl
    _codex_unset
}
tools

# -- implementation 
function setTempLocalServer {
    source "${_SCRIPT_DIR}/_codex.sh"
    local port="${1:-8000}"
    local wait_status=0
    local -a py_cmd
    # Validate port argument (now the first argument).
    if ! [[ "$port" =~ ^[0-9]+$ ]] || (( port < 1 || port > 65535 )); then
        crit_echo "Error: Port must be a positive integer between 1 and 65535." >&2
        warn_echo "Usage: setTempLocalServer [ <port> ]" >&2
        _codex_unset
        return 1
    fi
    # Determine Python command.
    if command -v python3 &>/dev/null; then
        py_cmd=(python3 -m http.server --bind 127.0.0.1 "$port")
    elif command -v python &>/dev/null; then
        warn_echo "Warning: Python 2 binds to 0.0.0.0 and exposes the server to the local network." >&2
        py_cmd=(python -m SimpleHTTPServer "$port")
    else
        crit_echo "Error: Python is not installed." >&2
        _codex_unset
        return 1
    fi
    # Start the server
    info_echo "Server bound to http://127.0.0.1:$port"
    echo "Serving directory: $PWD"
    echo "Press Ctrl+C to stop the server."
    "${py_cmd[@]}"
    _codex_unset
}   

# END 