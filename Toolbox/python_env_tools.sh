# BEGIN : Toolbox/python_env_tools.sh 
# ==============================================================================
# DEPENDENCIES: python3, venv, rm, mkdir, coreutils
# ==============================================================================

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if ! declare -F "__SCRIPT_SAFE_SOURCE" >/dev/null; then
    __SCRIPT_SAFE_SOURCE() {
        local script_path="${1:-}"
        if [[ -z "$script_path" || ! -f "$script_path" ]]; then
            printf '\033[1;31m✗ Error: Invalid or missing script path for sourcing.\033[0m\n' >&2
            return 1
        fi
        printf '\033[1;33m⚠ Warning: Security core absent. Sourcing without integrity check\033[0m\n' >&2
        # Proceed with standard sourcing
        source "$script_path"
    }
fi

VENV_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/python-envs"

# -- dependencies 
# ... python3

# -- description 
function tools {
    __SCRIPT_SAFE_SOURCE "$_SCRIPT_DIR/_codex.sh"
    local width=6
    toolbox_title "Python Environment Management Tools"
    toolbox_item "tools" "print this ..." $width
    #toolbox_item "" "" $width
    toolbox_item "listPythonEnvironments" "list all environment available on $VENV_DIR" $width
    toolbox_item "createPythonEnvironment" "creates a python environment" $width
    toolbox_item "activatePythonEnvironment" "activate a python environment" $width
    toolbox_item "deactivatePythonEnvironment" "deactivate a python environment" $width
    toolbox_item "deletePythonEnvironment" "delete a python environment" $width
    toolbox_endl
    _codex_unset
}
tools

# -- implementation  
function listPythonEnvironments {
    local name
    echo "--- Available Python Environments ---"
    for d in "$VENV_DIR"/*/; do
        [[ -d "$d" ]] || continue
        name="$(basename "$d")"
        local active=" "
        [[ "$name" == "$(basename "$VIRTUAL_ENV" 2>/dev/null)" ]] && active="*"
        printf "%s %s\n" "$active" "$name"
    done
}   
function createPythonEnvironment {
    __SCRIPT_SAFE_SOURCE "$_SCRIPT_DIR/_codex.sh"
    if [[ "$#" -eq 0 ]]; then 
        warn_echo "Usage: createPythonEnvironment <name> [python-version]"
        listPythonEnvironments 
        _codex_unset
        return 1
    fi
    local name="${1}"
    local pyver="${2:-python3}"
    local path="$VENV_DIR/$name"
    if [[ -d "$path" ]]; then
        crit_echo "Environment '$name' already exists at $path"
        _codex_unset
        return 1
    fi
    # Find the right python binary
    local python_bin
    if [[ "$pyver" == "python3" ]]; then
        python_bin="$(command -v python3)"
    else
        python_bin="$(command -v "${pyver}")" || {
            crit_echo "Python binary '$pyver' not found"
            _codex_unset
            return 1
        }
    fi
    info_echo "Python Environment : $name"
    echo "Version : $pyver"
    echo "Path : $path"
    if ! token_prompt "Confirmation" "are you sure to create this python environment"; then 
        _codex_unset
        return 0
    fi
    mkdir -p "$VENV_DIR"
    "$python_bin" -m venv "$path"
    good_echo "Created environment '$name' -> $path"
    _codex_unset
}
function activatePythonEnvironment {
    __SCRIPT_SAFE_SOURCE "$_SCRIPT_DIR/_codex.sh"
    if [[ "$#" -eq 0 ]]; then 
        warn_echo "Usage: activatePythonEnvironment <name>"
        listPythonEnvironments
        _codex_unset
        return 1
    fi 
    local name="${1}"
    local path="$VENV_DIR/$name"
    if [[ ! -f "$path/bin/activate" ]]; then
        crit_echo "Environment '$name' not found at $path"
        _codex_unset
        return 1
    fi
    source "$path/bin/activate"
    _codex_unset
}
function deactivatePythonEnvironment {
    __SCRIPT_SAFE_SOURCE "$_SCRIPT_DIR/_codex.sh"
    if [[ -n "$VIRTUAL_ENV" ]]; then
        deactivate
    else
        crit_echo "No active Python environment"
        _codex_unset
        return 1
    fi
    _codex_unset
}
function deletePythonEnvironment {
    __SCRIPT_SAFE_SOURCE "$_SCRIPT_DIR/_codex.sh"
    if [[ "$#" -eq 0 ]]; then 
        warn_echo "Usage: deletePythonEnvironment <name>"
        listPythonEnvironments
        _codex_unset
        return 1
    fi 
    local name="${1}"
    local path="$VENV_DIR/$name"
    if [[ ! -d "$path" ]]; then
        crit_echo "Environment '$name' not found at $path"
        _codex_unset
        return 1
    fi
    # Deactivate if this env is currently active
    if [[ "$VIRTUAL_ENV" == "$path" ]]; then
        deactivate
    fi
    info_echo "Python Virtual Environment: $name"
    if ! token_prompt "Confirmation" "are you sure to delete the virtual environment?"; then 
        _codex_unset
        return 0
    fi
    rm -rf "$path"
    crit_echo "Deleted environment '$name'"
    _codex_unset
}   

# END 