# BEGIN : Toolbox/_llama_cpp.sh 
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -- variables
_CONTEXT_SIZE_LLM=1024
_DEVICE_LLM="none"
_GPU_OFFLOAD_LLM=15

# -- load and save config 
__BWBH_SAVE_CONFIG_llama() {
    source "$_SCRIPT_DIR/_codex.sh"
    local config_path="$HOME/.config/BashingWithBareHands/llama_cpp_tools.conf"
    if [[ ! -f "$config_path" ]]; then 
        crit_echo "... config file not found"
        good_echo "... creating config file"
        create_intermediate_dirs "$config_path"
        echo "$config_path"
    fi 
    save_variables "$config_path" \
        "_CONTEXT_SIZE_LLM" "_DEVICE_LLM" "_GPU_OFFLOAD_LLM" \
        "__SELECTED_ITEM_LLM" "__LLM_MODEL_LIST"
}

# -- description 
function tools {
    source "$_SCRIPT_DIR/_codex.sh"
    local config_path="$HOME/.config/BashingWithBareHands/llama_cpp_tools.conf"
    [[ -f "$config_path" ]] && source "$config_path"
    local width=7
    toolbox_title "Artificial Inteligence Local Inference Tools"
    toolbox_item "tools" "print this ..." $width
    if is_command_valid llama-cli; then 
        toolbox_item "lightInteractiveInference" "interactive inference for low vram (4GB)" $width
        toolbox_item "lightFileInference" "llm inference over a file (backup the file to avoid data loss)" $width
        toolbox_item "setContextSize" "set context size in tokens (Default: 1024 Current: $_CONTEXT_SIZE_LLM)" $width
        toolbox_item "setDeviceLLM" "set the device for processing (Default: none Current: $_DEVICE_LLM)" $width
        toolbox_item "setGpuOffloadLayers" "numbers of layers processed by gpu (Default: 15 Current: $_GPU_OFFLOAD_LLM)" $width
        toolbox_item "modelList / addModel" "show/add the/to model list for interactive selection" $width
        toolbox_item "modelListDelete / modelListReset" "delete / reset model list" $width
    else 
        crit_echo "... requires llama-cpp package and their backends ggml-vulkan ggml-cpu"
    fi 
    toolbox_endl
    _codex_unset
}
tools

# -- implementation 
function lightInteractiveInference {
    source "${_SCRIPT_DIR}/_codex.sh"
    local config_path="$HOME/.config/BashingWithBareHands/llama_cpp_tools.conf"
    [[ -f "$config_path" ]] && source "$config_path"
    local model=""
    local gpu_offload_int="$_GPU_OFFLOAD_LLM"
    local device="$_DEVICE_LLM"
    local arg_count=$#
    local file_path="./llm_journal.txt"
    local temp_output=""
    local timestamp=""
    if [ "$arg_count" -gt 2 ]; then
        device="$3"
    fi 
    # --- Validation ---
    if [ "$arg_count" -lt 1 ]; then
        ls -a
        echo ""
        llama-cli --list-devices 2>/dev/null
        echo ""
        info_echo "Light Interactive Mode"
        echo "   Logs to: $file_path"
        echo ""
        warn_echo "Usage: lightInteractiveInference <model_path> [gpu_layers] [device]"
        echo ""
        if ! yn_prompt "Select" "select model from a list?"; then
            _codex_unset
            return 1
        fi
    fi
    model="$1"
    shift
    if [ "$#" -gt 0 ] && [[ "$1" =~ ^[0-9]+$ ]]; then
        gpu_offload_int="$1"
    fi
    # --- Pre-flight Checks ---
    if [ ! -f "$model" ]; then
        __SET_LLM_MODEL 
        model="$__CURRENT_MODEL_PATH"
    fi 
    if [ ! -f "$model" ]; then
        crit_echo "Error: Model file not found: $model"
        _codex_unset
        return 1
    fi
    # --- Prepare Journal ---
    temp_output="./llm_session_output.txt"
    # Generate ISO 8601 style timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    # --- Execution ---
    info_echo "Starting Interactive Session Inference"
    echo "Model : $model"
    echo "Context : $_CONTEXT_SIZE_LLM tokens"
    echo "GPU Layers : $gpu_offload_int"
    echo "Device : $device"
    echo "... temporary session output $temp_output"
    if ! yn_prompt "Confirmation" "initiate the interactive session?"; then
        _codex_unset
        return 0
    fi 
    llama-cli -m "$model" \
        --device "$device" \
        -ngl "$gpu_offload_int" \
        -t 4 \
        -c "$_CONTEXT_SIZE_LLM" \
        -b 512 \
        -ub 256 \
        -fa on \
        --cache-type-k q8_0 \
        --cache-type-v q8_0 \
        -o "$temp_output"
    local exit_code=$?
    if [ $exit_code -eq 0 ] && [ -f "$temp_output" ] && [ -s "$temp_output" ]; then
        # Append timestamp header and content to journal
        {
            echo ""
            echo "# === LLM : $timestamp ==="
            echo "1. model : $model"
            echo "2. device : $device"
            echo "3. gpu offload : $gpu_offload_int"
            echo "4. context : $_CONTEXT_SIZE_LLM tokens"
        } >> "./_llm_history"
        {
            echo ""
            echo ""
            echo "# === LLM Journal Entry: $timestamp ==="
            echo "1. model : $model"
            echo "2. device : $device"
            echo "3. gpu offload : $gpu_offload_int"
            echo ""
            cat "$temp_output"
        } >> "$file_path"
        echo "Session saved to $file_path"
    elif [ $exit_code -ne 0 ]; then
        echo ""
        crit_echo "llama-cli exited with error code: $exit_code"
        echo "Tip: If OOM, try lowering GPU layers."
    else
        echo "Warning: No output generated."
    fi
    _codex_unset
    return $exit_code
}   
function setContextSize {
    source "${_SCRIPT_DIR}/_codex.sh"
    if [ "$#" -gt 0 ] && [[ "$1" =~ ^[0-9]+$ ]]; then
        _CONTEXT_SIZE_LLM="$1"
        warn_echo "Current LLM Context Size : $_CONTEXT_SIZE_LLM tokens"
        __BWBH_SAVE_CONFIG_llama
        _codex_unset
        return 0
    fi
    info_echo "Current LLM Context Size : $_CONTEXT_SIZE_LLM tokens"
    _codex_unset
    return 1
}
function setGpuOffloadLayers {
    source "${_SCRIPT_DIR}/_codex.sh"
    if [ "$#" -gt 0 ] && [[ "$1" =~ ^[0-9]+$ ]]; then
        _GPU_OFFLOAD_LLM="$1"
        warn_echo "Current LLM GPU Offload : $_GPU_OFFLOAD_LLM layers"
        __BWBH_SAVE_CONFIG_llama
        _codex_unset
        return 0
    fi
    info_echo "Current LLM GPU Offload : $_GPU_OFFLOAD_LLM layers"
    _codex_unset
    return 1
}
function lightFileInference {
    source "${_SCRIPT_DIR}/_codex.sh"
    local config_path="$HOME/.config/BashingWithBareHands/llama_cpp_tools.conf"
    [[ -f "$config_path" ]] && source "$config_path"
    local arg_count=$#
    local file_path="$1"
    local model="$2"
    local gpu_offload_int="$_GPU_OFFLOAD_LLM"
    local temp_output=""
    local timestamp=""
    local device="$_DEVICE_LLM"
    if [ "$arg_count" -gt 3 ]; then
        device="$4"
    fi 
    # --- Validation ---
    if [ "$arg_count" -lt 2 ]; then
        ls -a
        echo ""
        llama-cli --list-devices 2>/dev/null
        echo ""
        info_echo "Light File Inference"
        echo ""
        warn_echo "Usage: lightFileInference <file_path> <model_path> [gpu_layers] [device]"
        echo ""
        if ! yn_prompt "Select" "select model from a list?"; then
            _codex_unset
            return 1
        fi
    fi
    # -- 
    shift
    shift
    if [ "$#" -gt 0 ] && [[ "$1" =~ ^[0-9]+$ ]]; then
        gpu_offload_int="$1"
    fi
    # --- Pre-flight Checks ---
    if [ ! -f "$model" ]; then
        __SET_LLM_MODEL 
        model="$__CURRENT_MODEL_PATH"
    fi 
    if [ ! -f "$model" ]; then
        crit_echo "Error: Model file not found: $model"
        _codex_unset
        return 1
    fi
    # --- Prepare Journal ---
    temp_output="$(mktemp)"
    # Generate ISO 8601 style timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    # --- Execution ---
    info_echo "Starting Inference"
    echo "Model : $model"
    echo "Context : $_CONTEXT_SIZE_LLM tokens"
    echo "GPU Layers : $gpu_offload_int"
    echo "Device : $device"
    if ! yn_prompt "Confirmation" "perform the inference?"; then
        _codex_unset
        return 0
    fi 
    llama-cli -m "$model" \
        --device "$device" \
        -ngl "$gpu_offload_int" \
        -t 4 \
        -c "$_CONTEXT_SIZE_LLM" \
        -b 512 \
        -ub 256 \
        -fa on \
        --cache-type-k q8_0 \
        --cache-type-v q8_0 \
        --single-turn \
        --file "$file_path" \
        -o "$temp_output"
    local exit_code=$?
    if [ $exit_code -eq 0 ] && [ -f "$temp_output" ] && [ -s "$temp_output" ]; then
        {
            echo ""
            echo "# === LLM : $timestamp ==="
            echo "1. model : $model"
            echo "2. device : $device"
            echo "3. gpu offload : $gpu_offload_int"
            echo "4. context : $_CONTEXT_SIZE_LLM tokens"
            echo ""
            cat "$temp_output"
        } > "$file_path"
        echo "Session saved to $file_path"
    elif [ $exit_code -ne 0 ]; then
        echo ""
        crit_echo "llama-cli exited with error code: $exit_code"
        echo "Tip: If OOM, try lowering GPU layers."
    else
        echo "Warning: No output generated."
    fi
    _codex_unset
    return $exit_code
}
function setDeviceLLM {
    source "${_SCRIPT_DIR}/_codex.sh"
    if [ "$#" -gt 0 ]; then
        _DEVICE_LLM="$1"
        warn_echo "Current LLM Device : $_DEVICE_LLM"
        __BWBH_SAVE_CONFIG_llama
        _codex_unset
        return 0
    fi
    info_echo "Current LLM Device : $_DEVICE_LLM"
    llama-cli --list-devices 2>/dev/null
    _codex_unset
    return 1
}

# -- 
__SELECTED_ITEM_LLM=0
__LLM_MODEL_LIST=("Exit")
__CURRENT_MODEL_PATH=""
function __SET_LLM_MODEL {
    source "$_SCRIPT_DIR/_codex.sh"
    local config_path="$HOME/.config/BashingWithBareHands/llama_cpp_tools.conf"
    [[ -f "$config_path" ]] && source "$config_path"
    INTERACTIVE_MENU_SINGLE __LLM_MODEL_LIST "Select LLM Local Model Path" $__SELECTED_ITEM_LLM
    local rs=$?
    if [[ "$rs" -ne 0 ]]; then 
        __SELECTED_ITEM_LLM=$(($rs-1))
        __CURRENT_MODEL_PATH="${__LLM_MODEL_LIST[$__SELECTED_ITEM_LLM]}"
    fi
    __BWBH_SAVE_CONFIG_llama    
}
function addModel {
    source "$_SCRIPT_DIR/_codex.sh"
    local config_path="$HOME/.config/BashingWithBareHands/llama_cpp_tools.conf"
    [[ -f "$config_path" ]] && source "$config_path"
    local _path="$*"
    if [[ -z "$_path" ]]; then 
        ls -a
        warn_echo "Usage: addModel <path>"
        _codex_unset
        return 0
    fi
    if [[ -f "$_path" ]]; then
        _path="$(get_abs_path "$_path")"
        __LLM_MODEL_LIST+=("$_path")
        __BWBH_SAVE_CONFIG_llama
        _codex_unset
        return 0
    else 
        crit_echo "Invalid Path"
        _codex_unset
        return 1
    fi 
    return 0
}
function modelListDelete {
    source "$_SCRIPT_DIR/_codex.sh"
    local config_path="$HOME/.config/BashingWithBareHands/llama_cpp_tools.conf"
    [[ -f "$config_path" ]] && source "$config_path"
    INTERACTIVE_MENU_DEL() {
        [[ -t 0 && -t 1 ]] || return 0
        (( $# >= 2 )) || return 0
        [[ "$1" == "_ref_items_in" ]] && return 0
        # Expects nameref names: _INTERACTIVE_MENU items_var actions_var "Title"
        local -n _ref_items_in="$1" 2>/dev/null
        local title="${2:-Menu}"
        # Use distinct internal variable names to prevent nameref collision loops
        local -a _menu_items=()
        # Populate items
        if (( ${#_ref_items_in[@]} > 0 )); then
            _menu_items=("${_ref_items_in[@]}")
        else
            _menu_items=("Option 1" "Option 2" "Option 3" "Exit")
        fi
        # Terminal cleanup helper
        _menu_cleanup() {
            tput cnorm 2>/dev/null
            stty echo 2>/dev/null
        }
        trap '_menu_cleanup' RETURN INT TERM
        stty -echo
        tput civis 2>/dev/null
        local selected="${3:-0}"
        local start=0 end=0
        local filerange=15
        local total=${#_menu_items[@]}
        local key
        local _path
        local b_clear="true"
        (( total > 0 )) || return 0
        while true; do
            # Boundary constraints
            (( selected >= total )) && selected=$((total - 1))
            (( selected < 0 )) && selected=0
            # Compute visible window
            start=$((selected - filerange))
            (( start < 0 )) && start=0
            end=$((selected + filerange))
            (( end >= total )) && end=$((total - 1))
            # Render
            if [[ "$b_clear" == "true" ]]; then 
                clear
                warn_echo "$title"
                (( start > 0 )) && echo "   ..."
                for ((i = start; i <= end; i++)); do
                    if (( i == selected )); then
                        printf '\033[1;32m > %s \033[0m\n' "${_menu_items[$i]}"
                    else
                        printf '   %s\n' "${_menu_items[$i]}"
                    fi
                done
                (( end < total - 1 )) && echo "   ..."
            else 
                b_clear="true"
            fi        
            # Read key input
            read -rsn1 key
            if [[ "$key" == $'\x1b' ]]; then
                read -rsn2 -t 0.2 key
                case "$key" in
                    '[A') ((selected--)) || true ;;
                    '[B') ((selected++)) || true ;;
                    '[5') read -rsn1 -t 0.2; ((selected-=7)) || true ;;   # PageUp
                    '[6') read -rsn1 -t 0.2; ((selected+=7)) || true ;;   # PageDown
                    *)    key=$'\x1b' ;;
                esac
            fi
            case "$key" in
                q|Q)
                    break
                    ;;
                "") # Enter
                    local var_name="${_menu_items[$selected]}"
                    [[ "$var_name" == "Exit" ]] && continue
                    _path="${var_name:-}"
                    if [[ -n "$_path" ]]; then
                        unset "_ref_items_in[$selected]"
                        _ref_items_in=("${_ref_items_in[@]}")
                        _menu_items=("${_ref_items_in[@]}")
                        total=${#_menu_items[@]}
                        (( total == 0 )) && break
                        (( selected >= total )) && selected=$((total - 1))
                        b_clear="true"
                    fi
                    ;;   
            esac
        done
        return $selected
    }
    # Call the menu — pass variable *names*, not values
    INTERACTIVE_MENU_DEL __LLM_MODEL_LIST "Delete Model Path [ Q | Enter ]" $__SELECTED_ITEM_LLM
    __SELECTED_ITEM_LLM=$?
    unset -f INTERACTIVE_MENU_DEL
    __BWBH_SAVE_CONFIG_llama
    _codex_unset
}
function modelListReset {
    source "$_SCRIPT_DIR/_codex.sh"
    __SELECTED_ITEM_LLM=0
    __LLM_MODEL_LIST=("Exit")
    good_echo "model list reseted"
    __BWBH_SAVE_CONFIG_llama
    _codex_unset
}
function modelList {
    __SET_LLM_MODEL
}

# END 