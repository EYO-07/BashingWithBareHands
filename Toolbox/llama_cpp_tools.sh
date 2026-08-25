# BEGIN : Toolbox/_llama_cpp.sh 
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -- description 
function tools {
    source "$_SCRIPT_DIR/_codex.sh"
    local width=5
    toolbox_title "Artificial Inteligence Inference Tools"
    info_echo "... requires llama-cpp package and their backends ggml-vulkan ggml-cpu"
    toolbox_item "tools" "print this ..." $width
    toolbox_item "inv" "print built-in commands ..." $width
    toolbox_item "lightInteractiveInference" "interactive inference for low vram (4GB)" $width
    toolbox_endl
    _codex_unset
}
tools

# -- implementation 
function lightInteractiveInference {
    local model=""
    local gpu_offload_int=15
    local device="none"
    local arg_count=$#
    local file_path="./llm_journal.txt"
    local temp_output=""
    local timestamp=""
    if [ "$arg_count" -gt 2 ]; then
        device="$3"
    fi 
    # --- Validation ---
    if [ "$arg_count" -lt 1 ]; then
        ls -a 2>/dev/null
        echo ""
        llama-cli --list-devices 2>/dev/null
        echo ""
        echo "Light Journal: Interactive Mode with Timestamps"
        echo "   Logs to: $file_path"
        echo ""
        echo "Usage: lightInteractiveInference <model_path> [gpu_layers] [device]"
        return 1
    fi
    model="$1"
    shift
    if [ "$#" -gt 0 ] && [[ "$1" =~ ^[0-9]+$ ]]; then
        gpu_offload_int="$1"
    fi
    # --- Pre-flight Checks ---
    if [ ! -f "$model" ]; then
        echo "Error: Model file not found: $model"
        return 1
    fi
    # --- Prepare Journal ---
    temp_output="./llm_session_output.txt"
    # Generate ISO 8601 style timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    # --- Execution ---
    echo "Starting journal session at $timestamp..."
    llama-cli -m "$model" \
        --device "$device" \
        -ngl "$gpu_offload_int" \
        -t 4 \
        -c 1024 \
        -b 512 \
        -ub 256 \
        -fa on \
        --cache-type-k q8_0 \
        --cache-type-v q8_0 \
        -cnv \
        -o "$temp_output"
    local exit_code=$?
    if [ $exit_code -eq 0 ] && [ -f "$temp_output" ] && [ -s "$temp_output" ]; then
        # Append timestamp header and content to journal
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
        echo "llama-cli exited with error code: $exit_code"
        echo "Tip: If OOM, try lowering GPU layers."
    else
        echo "Warning: No output generated."
    fi
    return $exit_code
}   

# END 