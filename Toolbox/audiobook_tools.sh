# BEGIN Toolbox/audiobook_tools.sh
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -- dependencies
# 1. gtts-cli ; 2. vlc 

# -- description 
function tools {
    source "$_SCRIPT_DIR/_codex.sh"
    local width=4
    toolbox_title "Audiobook Tools"
    info_echo "... requires gtts-cli, vlc and python-pdftotext"
    info_echo "... it takes a bit of time to start, be patient"
    toolbox_item "tools" "print this ..." $width
    #toolbox_item "inv" "print built-in commands ..." $width
    toolbox_item "textReader" "read text or text file using gtts-cli and vlc" $width
    toolbox_item "pdfAudiobookReader" "read pdf books (needs to activate with chmod +x the _readpdfaudio.py script)" $width
    toolbox_item "pdfAudiobookReaderSleep" "read a chunk of 50 pages and suspend the system" $width
    toolbox_endl
    _codex_unset
}
tools

# -- implementation
function textReader {
    source "$_SCRIPT_DIR/_codex.sh"
    # Usage: textReader <text_or_file>
    # Usage: <text_or_file> | textReader
    # Helper to play audio stream
    _play_stream() {
        # cvlc needs --play-and-exit and often benefits from --no-loop
        # If cvlc hangs, try: mpg123 -  OR  play -t mp3 -
        cvlc --play-and-exit --no-loop -
    }
    # Check if input is piped (stdin is not a terminal)
    if [ -n "$1" ]; then
        # ARGUMENT MODE
        if [ -f "$1" ]; then
            # File argument: Stream file -> gtts-cli -> player
            gtts-cli -f "$1" | _play_stream
        else
            # Text argument: Echo text -> gtts-cli -> player
            # Using echo avoids variable storage limits for very long strings
            echo "$*" | gtts-cli -f - | _play_stream
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
    # Validate minimum arguments
    if [ $# -lt 1 ] || [ $# -gt 4 ]; then
        echo "Usage: pdfAudiobookReader <pdf>"
        echo "       pdfAudiobookReader <pdf> <startingpage>"
        echo "       pdfAudiobookReader <pdf> <startingpage> <language>"
        echo "       pdfAudiobookReader <pdf> <startingpage> <pages_chunk_to_pause> <language>"
        _codex_unset
        return 1
    fi
    local pdf_file="$1"
    local start_page="${2:-}"
    local pause_pages="${3:-}"
    local language="${4:-}"
    # Validate file exists
    if [ ! -f "$pdf_file" ]; then
        echo "Error: File '$pdf_file' not found."
        _codex_unset
        return 1
    fi
    # Build command array safely (NO eval needed)
    local cmd=("$_SCRIPT_DIR/_readpdfaudio.py" "$pdf_file")
    # Always add pausepages if we have 4 args (special case in your original logic)
    # Or default to 1 if not specified in the 4-arg case
    if [ $# -eq 4 ]; then
        cmd+=("--pausepages=$pause_pages")
        cmd+=("--startingpage=$start_page")
        cmd+=("--language=$language")
    elif [ $# -eq 3 ]; then
        # Case: <pdf> <start> <language> -> pausepages defaults to 1 in your original
        cmd+=("--pausepages=1")
        cmd+=("--startingpage=$start_page")
        cmd+=("--language=$language")
    elif [ $# -eq 2 ]; then
        # Case: <pdf> <start> -> pausepages defaults to 1
        cmd+=("--pausepages=1")
        cmd+=("--startingpage=$start_page")
    else
        # Case: <pdf> only -> pausepages defaults to 1
        cmd+=("--pausepages=1")
    fi
    # Execute command directly from array
    "${cmd[@]}"
    _codex_unset
    return $?
}
function pdfAudiobookReaderSleep {
    source "$_SCRIPT_DIR/_codex.sh"
    # Validate arguments
    if [ $# -ne 3 ]; then
        echo "Usage: pdfAudiobookReaderSleep <pdf> <chunk> <language>"
        echo "  chunk: chapter number (1-based, each chunk = 50 pages)"
        echo "  language: gTTS language code (e.g., en, es, fr)"
        _codex_unset
        return 1
    fi
    local pdf_file="$1"
    local chunk="$2"
    local language="$3"
    # Validate file exists
    if [ ! -f "$pdf_file" ]; then
        echo "Error: File '$pdf_file' not found."
        _codex_unset
        return 1
    fi
    # Validate chunk is numeric
    if ! [[ "$chunk" =~ ^[0-9]+$ ]]; then
        echo "Error: chunk must be a positive integer."
        _codex_unset
        return 1
    fi
    # Calculate page range (50 pages per chunk)
    local spg=$(( 50 * (chunk - 1) + 1 ))  # Start page (1-based)
    local epg=$(( 50 * chunk ))            # End page
    echo "Reading chunk $chunk: pages $spg-$epg"
    # Run Python script (NO eval needed)
    "$_SCRIPT_DIR/_readpdfaudio.py" "$pdf_file" \
        --pausepages=70 \
        --startingpage="$spg" \
        --language="$language" \
        --endpage="$epg"
    # Suspend requires sudo or polkit configuration
    echo "Suspending system..."
    systemctl suspend  # Or configure passwordless sudo
    _codex_unset
    return 0
}   

# END