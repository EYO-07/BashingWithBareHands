# BEGIN : Toolbox/_llama_cpp.sh 
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -- description 
function tools {
    source "$_SCRIPT_DIR/_codex.sh"
    local width=5
    toolbox_title "Artificial Inteligence Inference Tools (v2026-08-25_00)"
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
    local gpu_offload_int=15  # Default to 15 layers for safety (e.g., GTX 1650)
    local device="none"
    local arg_count=$#
    if [ "$arg_count" -gt 2 ]; then
        device="$3"
    fi 
    # --- Validation ---
    # Need at least the model path
    if [ "$arg_count" -lt 1 ]; then
        ls -a
        echo ""
        llama-cli --list-devices
        echo ""
        echo "Light Inference: Interactive Mode (Low-VRAM Optimized)"
        echo "   Config: 4 Threads | 1024 Context | 512 Batch | Flash Attention"
        echo ""
        echo "Usage: lightInference <model_path> [gpu_layers] [device]"
        echo "Example: lightInference ~/models/llama-3-8b.Q4_K_M.gguf 30"
        return 1
    fi
    model="$1"
    shift
    # Check if the next argument is a number (GPU layers)
    if [ "$#" -gt 0 ] && [[ "$1" =~ ^[0-9]+$ ]]; then
        gpu_offload_int="$1"
    fi
    # --- Pre-flight Checks ---
    if [ ! -f "$model" ]; then
        echo "Error: Model file not found: $model"
        return 1
    fi
    # Create a temporary file for the new output
    temp_output=$(mktemp)
    file_path="./llm_journal"
    # --- Execution ---
    # Run in interactive conversation mode
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
    # Capture exit code
    local exit_code=$?
    if [ $exit_code -eq 0 ] && [ -f "$temp_output" ] && [ -s "$temp_output" ]; then
        # Append the generated content to the original file
        # We add a newline before appending to ensure separation if the file didn't end with one
        echo "" >> "$file_path"
        cat "$temp_output" >> "$file_path"
        echo "Output appended to $file_path"
    elif [ $exit_code -ne 0 ]; then
        echo ""
        echo "llama-cli exited with error code: $exit_code"
        echo "Tip: If OOM, try lowering GPU layers."
    else
        echo "Warning: Generation produced no output."
    fi
    return $exit_code
}

# END 