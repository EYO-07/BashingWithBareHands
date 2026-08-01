# BEGIN Toolbox/audiobook_tools.sh
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -- dependencies
# 1. gtts-cli ; 2. vlc ; 3. pdftotext

# -- description 
function tools {
    source "$_SCRIPT_DIR/_codex.sh"
    local width=5
    toolbox_title "Audiobook Tools"
    info_echo "... requires gtts-cli, vlc and pdftotext (poppler)"
    toolbox_item "tools" "print this ..." $width
    #toolbox_item "inv" "print built-in commands ..." $width
    toolbox_item "textReader" "read text or text file using gtts-cli and vlc" $width
    toolbox_item "pdfAudiobookReader" "read pdf books using gtts-cli and vlc" $width
    toolbox_item "pdfAudiobookReaderSleep" "read a chunk of 25 pages and suspend the system at end" $width
    toolbox_item "webpageReader" "read a web page using gtts-cli, vlc. Requires lynx or w3m." $width
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
    _play_stream() {
        cvlc --play-and-exit --no-loop -
    }
    # Usage: pdfAudiobookReader <pdf> [start_page] [pause_chunk] [language]
    if [ $# -lt 1 ]; then
        echo "Usage: pdfAudiobookReader <pdf> [start_page] [pause_chunk] [language]"
        _codex_unset
        return 1
    fi
    local pdf_file="$1"
    local start_page="${2:-1}"
    local pause_chunk="${3:-1}" # Default pause every 1 page if not specified
    local language="${4:-en}"
    local total_pages=$(pdfinfo "$pdf_file" | grep Pages | awk '{print $2}')
    if [ ! -f "$pdf_file" ]; then
        echo "Error: File '$pdf_file' not found."
        _codex_unset
        return 1
    fi
    echo "Starting PDF Audiobook: $pdf_file"
    echo "Total Pages: $total_pages | Start: $start_page | Language: $language"
    local current_page=$start_page
    while [ $current_page -le $total_pages ]; do
        echo "Reading Page $current_page..."
        # 1. Extract single page to stdout using pdftotext
        # 2. Pipe directly to gtts-cli (reading from stdin via '-')
        # 3. Pipe MP3 stream to player
        pdftotext -f "$current_page" -l "$current_page" "$pdf_file" - | \
            gtts-cli -l "$language" -f - | \
            _play_stream
        # Pause Logic
        if [ "$pause_chunk" -gt 0 ] && [ $(( current_page % pause_chunk )) -eq 0 ] && [ $current_page -lt $total_pages ]; then
            echo -e "\n--- Paused after page $current_page ---"
            read -p "Press Enter to continue (or 'q' to quit): " user_input
            if [ "$user_input" = "q" ]; then
                echo "Quitting..."
                _codex_unset
                return 0
            fi
        fi
        ((current_page++))
    done
    echo "Finished reading."
    _codex_unset
    return 0
}
function pdfAudiobookReaderSleep {
    source "$_SCRIPT_DIR/_codex.sh"
    _play_stream() {
        cvlc --play-and-exit --no-loop -
    }
    if [ $# -ne 3 ]; then
        echo "Usage: pdfAudiobookReaderSleep <pdf> <chunk> <language>"
        _codex_unset
        return 1
    fi
    local pdf_file="$1"
    local chunk="$2"
    local language="$3"
    local total_pages=$(pdfinfo "$pdf_file" | grep Pages | awk '{print $2}')
    local spg=$(( 25 * (chunk - 1) + 1 ))
    local epg=$(( 25 * chunk ))
    # Cap end page at total pages
    if [ $epg -gt $total_pages ]; then
        epg=$total_pages
    fi
    echo "Reading chunk $chunk: pages $spg-$epg"
    # Loop through the specific range
    local current_page=$spg
    while [ $current_page -le $epg ]; do
        echo "Reading Page $current_page..."
        pdftotext -f "$current_page" -l "$current_page" "$pdf_file" - | \
            gtts-cli -l "$language" -f - | \
            cvlc --play-and-exit --no-loop -
        ((current_page++))
    done
    echo "Suspending system..."
    systemctl suspend
    _codex_unset
    return 0
}
function webpageReader {
    source "$_SCRIPT_DIR/_codex.sh"
    # Helper: Extract text from a single URL using w3m (preferred) or lynx
    # w3m -dump: Renders HTML to text and outputs to stdout
    # -T text/html: Ensures correct parsing if piped
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
    # Helper: Play the extracted text
    _play_text_stream() {
        # Reads text from stdin -> gtts-cli -> stdout (MP3) -> cvlc
        gtts-cli -f - | cvlc --play-and-exit --no-loop -
    }
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

# END