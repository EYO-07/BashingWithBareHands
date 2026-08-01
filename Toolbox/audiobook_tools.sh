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
    toolbox_item "tools" "print this ..." $width
    #toolbox_item "inv" "print built-in commands ..." $width
    toolbox_item "textReader" "read text or text file using gtts-cli and vlc" $width
    toolbox_item "pdfAudiobookReader" "read pdf books" $width
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
    if [ $# -eq 1 ]; then 
        eval "$_SCRIPT_DIR/_readpdfaudio.py $1 --pausepages=1"
        _codex_unset
        return 0 
    fi
    if [ $# -eq 2 ]; then 
        eval "$_SCRIPT_DIR/_readpdfaudio.py $1 --pausepages=1 --startingpage=$2"
        _codex_unset
        return 0
    fi
    if [ $# -eq 3 ]; then 
        eval "$_SCRIPT_DIR/_readpdfaudio.py $1 --pausepages=1 --startingpage=$2 --language=$3"
        _codex_unset
        return 0
    fi
    if [ $# -eq 4 ]; then 
        eval "$_SCRIPT_DIR/_readpdfaudio.py $1 --pausepages=$3 --startingpage=$2 --language=$4"
        _codex_unset
        return 0
    fi
    echo "Usage: pdfAudiobookReader <pdf>"
    echo "Usage: pdfAudiobookReader <pdf> <startingpage>"
    echo "Usage: pdfAudiobookReader <pdf> <startingpage> <language>"
    echo "Usage: pdfAudiobookReader <pdf> <startingpage> <pages_chunk_to_pause> <language>"
    _codex_unset
    return 0
}

# END