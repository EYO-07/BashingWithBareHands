# BEGIN Toolbox/audiobook_tools.sh
# {TextMarker|cyan:_play_stream|magenta:_play_text_stream}
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -- dependencies
# 1. gtts-cli ; 2. vlc ; 3. pdftotext

# -- description 
function tools {
    source "$_SCRIPT_DIR/_codex.sh"
    local width=5
    toolbox_title "Audiobook Tools"
    info_echo "... requires gtts-cli or flite to transform text to speech"
    toolbox_item "tools" "print this ..." $width
    
    toolbox_item "textReader" "read text or text file using gtts-cli and vlc" $width
    echo "... requires vlc"
    
    toolbox_item "pdfAudiobookReader" "read pdf books using gtts-cli and vlc" $width
    toolbox_item "pdfAudiobookReaderSleep" "read a chunk of 25 pages and suspend the system at end" $width
    echo "... requires vlc and pdftotext (poppler)"
    
    toolbox_item "webpageReader" "read a web page using gtts-cli, vlc. Requires lynx or w3m." $width
    echo "... requires vlc and lynx or w3m"
    
    toolbox_item "tgptReader" "reads a llm response using tgpt (default: koboldai)" $width
    #toolbox_item "saveSafe_LLM_READER" "optional, save variables to optional arguments for tgpt" $width
    #toolbox_item "loadSafe_LLM_READER" "load variables used for tgpt" $width
    echo "... requires vlc and tgpt"
    toolbox_endl
    _codex_unset
}
tools

# -- helper functions 
_play_stream() {
    cvlc --play-and-exit --no-loop -
}
_play_text_stream() {
    source "$_SCRIPT_DIR/_codex.sh"
    if is_command_valid "gtts-cli --version"; then 
        gtts-cli -f - | _play_stream
        _codex_unset
        return 0
    fi 
    if is_command_valid "flite -t ''"; then 
        local text=$(cat)
        flite -voice slt -t "$text"
        _codex_unset
        return 0
    fi 
    crit_echo "Error: no voice backend available"
    _codex_unset
    return 1
}
_extract_text() {
    local url="$1"
    # Try w3m first, fallback to lynx if not found
    if command -v w3m &> /dev/null; then
        w3m -dump "$url"
    elif command -v lynx &> /dev/null; then
        lynx -dump -nolist "$url"
    else
        crit_echo "Error: Neither w3m nor lynx is installed." >&2
        return 1
    fi
}

# -- implementation
function textReader {
    source "$_SCRIPT_DIR/_codex.sh"
    # Usage: textReader <text_or_file>
    # Usage: <text_or_file> | textReader
    # Check if input is piped (stdin is not a terminal)
    if [ -n "$1" ]; then
        # ARGUMENT MODE
        if [ -f "$1" ]; then
            # File argument: Stream file -> gtts-cli -> player
            echo "$1" | _play_text_stream
        else
            # Text argument: Echo text -> gtts-cli -> player
            # Using echo avoids variable storage limits for very long strings
            echo "$*" | _play_text_stream
        fi
    else
        crit_echo "Usage: textReader <text_or_file>" >&2
        _codex_unset
        return 1
    fi
    _codex_unset
    return 0
}
function pdfAudiobookReader {
    source "$_SCRIPT_DIR/_codex.sh"
    # Usage: pdfAudiobookReader <pdf> [start_page] [pause_chunk] [language]
    if [ $# -lt 1 ]; then
        ls -a | grep ".pdf"
        warn_echo "Usage: pdfAudiobookReader <pdf> [start_page] [pause_chunk] [language]"
        info_echo "... use 0 as start_page to resume the reading"
        _codex_unset
        return 1
    fi
    local pdf_file="$1"
    # If start_page is not provided, we will check the journal later
    local provided_start_page="$2"
    local pause_chunk="${3:-5}"
    local language="${4:-en}"
    if [ ! -f "$pdf_file" ]; then
        ls -a | grep ".pdf"
        crit_echo "Error: File '$pdf_file' not found."
        _codex_unset
        return 1
    fi
    # --- Journal Logic Start ---
    # Create a journal filename based on the PDF name (e.g., book.pdf -> book.pdf.journal)
    local journal_file="_${pdf_file}.journal"
    local start_page=1
    # If no start page was provided by the user, check for a resume point
    if [ -z "$provided_start_page" ] || [ $provided_start_page -eq 0 ]; then
        if [ -f "$journal_file" ]; then
            # Read the last saved page from the journal
            start_page=$(cat "$journal_file")
            info_echo "Resuming from page $start_page (found in journal)"
        fi
    else
        start_page="$provided_start_page"
        # If user manually specifies a start page, we can optionally clear the old journal
        # or just let it overwrite later. Here we just proceed.
    fi
    # --- Journal Logic End ---
    local total_pages=$(pdfinfo "$pdf_file" | grep Pages | awk '{print $2}')
    # Validate start page
    if [ "$start_page" -gt "$total_pages" ] || [ "$start_page" -lt 1 ]; then
        crit_echo "Error: Start page $start_page is invalid. Total pages: $total_pages"
        _codex_unset
        return 1
    fi
    info_echo "Starting PDF Audiobook: $pdf_file"
    echo "Total Pages: $total_pages | Start: $start_page | Language: $language"
    local current_page=$start_page
    while [ $current_page -le $total_pages ]; do
        echo "Reading Page $current_page..."
        # 1. Extract single page to stdout using pdftotext
        # 2. Pipe directly to gtts-cli
        # 3. Pipe MP3 stream to player
        if is_command_valid "gtts-cli --version"; then 
            if ! pdftotext -f "$current_page" -l "$current_page" "$pdf_file" - | \
                gtts-cli -l "$language" -f - | \
                _play_stream; then
                crit_echo "Error processing page $current_page. Stopping."
                break
            fi
        else
            if ! pdftotext -f "$current_page" -l "$current_page" "$pdf_file" - | \
                _play_text_stream ; then
                crit_echo "Error processing page $current_page. Stopping."
                break
            fi
        fi
        # Pause Logic
        if [ "$pause_chunk" -gt 0 ] && [ $(( current_page % pause_chunk )) -eq 0 ] && [ $current_page -lt $total_pages ]; then
            warn_echo -e "\n--- Paused after page $current_page ---"  
            # *** WRITE TO JOURNAL ***
            # Save the current page so we can resume here next time
            echo "$current_page" > "$journal_file"
            info_echo "Progress saved to journal: Page $current_page"
            read -p "Press Enter to continue (or 'q' to quit): " user_input
            if [ "$user_input" = "q" ]; then
                warn_echo "Quitting... Progress saved. Run the command again to resume."
                _codex_unset
                return 0
            fi
        fi
        ((current_page++))
    done
    good_echo "Finished reading."
    _codex_unset
    return 0
}   
function pdfAudiobookReaderSleep {
    source "$_SCRIPT_DIR/_codex.sh"
    # Define the player function locally (or source it if defined in _codex.sh)
    # Usage: pdfAudiobookReaderSleep <pdf> [start_page_or_chunk] [language]
    # If start_page is 0 or omitted, it attempts to resume from journal.
    # If a specific page is given, it starts there.
    if [ $# -lt 1 ]; then
        ls -a | grep ".pdf"
        warn_echo "Usage: pdfAudiobookReaderSleep <pdf> [start_page] [language]"
        info_echo "... use 0 as start_page to resume the reading"
        _codex_unset
        return 1
    fi
    local pdf_file="$1"
    local provided_start_page="$2"
    local language="${3:-en}"
    local chunk=25
    if [ ! -f "$pdf_file" ]; then
        ls -a | grep ".pdf"
        crit_echo "Error: File '$pdf_file' not found."
        _codex_unset
        return 1
    fi
    # --- Journal Logic Start ---
    local journal_file="_${pdf_file}.journal"
    local start_page=1
    # If no start page provided or explicitly 0, check journal
    if [ -z "$provided_start_page" ] || [ "$provided_start_page" -eq 0 ]; then
        if [ -f "$journal_file" ]; then
            start_page=$(cat "$journal_file")
            info_echo "Resuming from page $start_page (found in journal)"
        else
            info_echo "No journal found. Starting from page 1."
        fi
    else
        start_page="$provided_start_page"
    fi
    # --- Journal Logic End ---
    local total_pages=$(pdfinfo "$pdf_file" | grep Pages | awk '{print $2}')
    # Validate start page
    if [ "$start_page" -gt "$total_pages" ] || [ "$start_page" -lt 1 ]; then
        crit_echo "Error: Start page $start_page is invalid. Total pages: $total_pages"
        _codex_unset
        return 1
    fi
    info_echo "Starting Sleep Audiobook: $pdf_file"
    echo "Total Pages: $total_pages | Start: $start_page | Language: $language"
    local current_page=$start_page
    while [ $current_page -le $total_pages ]; do
        echo "Reading Page $current_page..."
        # Process the page
        if is_command_valid "gtts-cli --version"; then 
            if ! pdftotext -f "$current_page" -l "$current_page" "$pdf_file" - | \
                gtts-cli -l "$language" -f - | \
                _play_stream; then
                crit_echo "Error processing page $current_page. Skipping the page."
                # Save state on error too
                echo "$current_page" > "$journal_file"
                continue
            fi        
        else
            if ! pdftotext -f "$current_page" -l "$current_page" "$pdf_file" - | \
                _play_text_stream ; then
                crit_echo "Error processing page $current_page. Skipping the page."
                # Save state on error too
                echo "$current_page" > "$journal_file"
                continue
            fi
        fi
        # Save progress to journal BEFORE suspending
        # We save the NEXT page to read, so if we wake up, we don't repeat the current one
        local next_page=$((current_page + 1))
        if [ $((next_page-start_page)) -eq $chunk ]; then 
            echo "$next_page" > "$journal_file"
            info_echo "Progress saved to journal: Next page $next_page"
            warn_echo "--- Suspending system after page $current_page ---"
            break
        fi
        ((current_page++))
    done
    systemctl suspend
    _codex_unset
    return 0
}   
function webpageReader {
    source "$_SCRIPT_DIR/_codex.sh"
    # Helper: Extract text from a single URL using w3m (preferred) or lynx
    # w3m -dump: Renders HTML to text and outputs to stdout
    # -T text/html: Ensures correct parsing if piped
    if [ -z "$1" ]; then
        crit_echo "Usage: webpageReader <textfile_or_url>" >&2
        _codex_unset
        return 1
    fi
    local input="$1"
    if [ -f "$input" ]; then
        # FILE MODE: Read URLs line by line from the file
        echo "Reading URLs from file: $input"
        while IFS= read -r url || [ -n "$url" ]; do
            # Skip empty lines or comments
            [[ -z "$url" || "$url" =~ ^# ]] && continue
            
            echo "Processing: $url"
            _extract_text "$url" | _play_text_stream
        done < "$input"
    else
        # URL MODE: Direct URL argument
        local url="$1"
        echo "Processing URL: $url"
        _extract_text "$url" | _play_text_stream
    fi
    _codex_unset
    return 0
}   

# -- implementation | llm 
_LLM_READER_PROVIDER="koboldai" # default
_LLM_READER_MODEL=""
_LLM_READER_KEY=""
_LLM_READER_URL=""
function saveSafe_LLM_READER {
    # Usage: saveSafe_LLM_READER [ <filename> ]
    # Saves the variables used by tgptReader to a secure file.
    # Defaults to ~/.config/tgpt_reader_config if no filename is provided.
    # Sets permissions to 600 (Owner Read/Write only) for security.
    local config_file="${1:-$HOME/.config/tgpt_reader_config}"
    local config_dir
    config_dir=$(dirname "$config_file")
    # Ensure directory exists
    if [ ! -d "$config_dir" ]; then
        mkdir -p "$config_dir" || { crit_echo "Error: Cannot create directory $config_dir" >&2; return 1; }
    fi
    # Write variables to file
    cat > "$config_file" <<EOF
_LLM_READER_PROVIDER="$_LLM_READER_PROVIDER"
_LLM_READER_MODEL="$_LLM_READER_MODEL"
_LLM_READER_KEY="$_LLM_READER_KEY"
_LLM_READER_URL="$_LLM_READER_URL"
EOF
    # Restrict permissions: Owner can read/write, no one else can access.
    chmod 600 "$config_file" || { crit_echo "Error: Failed to set permissions on $config_file" >&2; return 1; }
    info_echo "Configuration saved securely to $config_file"
    _codex_unset
    return 0
}
function loadSafe_LLM_READER {
    # Usage: loadSafe_LLM_READER [ <filename> ]
    # Loads llm safe config by filename, sourcing the contents of variables.
    # Defaults to ~/.config/tgpt_reader_config if no filename is provided.
    local config_file="${1:-$HOME/.config/tgpt_reader_config}"
    if [ ! -f "$config_file" ]; then
        warn_echo "Config file not found: $config_file (Using defaults)" >&2
        _codex_unset
        return 0
    fi
    # Security Check: Ensure file is not world-readable before sourcing
    local perms
    perms=$(stat -c "%a" "$config_file" 2>/dev/null || stat -f "%Lp" "$config_file" 2>/dev/null)
    if [ "$perms" != "600" ] && [ "$perms" != "400" ]; then
        crit_echo "Security Warning: $config_file has insecure permissions ($perms). Expected 600." >&2
        crit_echo "Refusing to source insecure file. Run 'saveSafe_LLM_READER' to fix." >&2
        _codex_unset
        return 1
    fi
    source "$config_file"
    info_echo "Configuration loaded from $config_file"
    _codex_unset
    return 0
}
function tgptReader {
    source "$_SCRIPT_DIR/_codex.sh"
    # Default to koboldai if not overridden
    local llm_provider="${_LLM_READER_PROVIDER:-koboldai}"
    if [ "$#" -eq 0 ]; then
        warn_echo 'Usage: tgptReader <prompt>' >&2
        _codex_unset
        return 0
    fi 
    local prompt="$*"
    info_echo "... starting llm reader "
    info_echo "Provider : $llm_provider"
    warn_echo "... be patient, this could take time depending on provider."
    local cmd_args=("tgpt" "--provider" "$llm_provider" "-w" "-q")
    # Append optional arguments only if variables are set
    [ -n "$_LLM_READER_MODEL" ] && cmd_args+=("--model" "$_LLM_READER_MODEL")
    [ -n "$_LLM_READER_KEY" ] && cmd_args+=("--key" "$_LLM_READER_KEY")
    [ -n "$_LLM_READER_URL" ] && cmd_args+=("--url" "$_LLM_READER_URL")
    # Add the user prompt as the final argument
    local generated_text
    generated_text=$("${cmd_args[@]}" "$prompt")
    # 2. Echo the text to the terminal
    # Using 'echo' or 'printf'. printf is safer for preserving exact formatting.
    echo "$generated_text"
    # 3. Pipe the stored text to gtts-cli and then to the player
    echo "$generated_text" | _play_text_stream
    #"${cmd_args[@]}" "$prompt" | _play_text_stream
    _codex_unset
    return 0
}

# END