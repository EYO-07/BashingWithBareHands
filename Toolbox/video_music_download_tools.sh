# BEGIN : video_download_yt_dlp.sh

# -- dependencies
# 1. yt-dlp cli tool for download youtube videos 

# -- description 
function tools {
    source "$_SCRIPT_DIR/_codex.sh"
    local width=10
    toolbox_title "Video Download Tools"
    info_echo "... requires: yt-dlp"
    toolbox_item "tools" "print this ..." $width
    #toolbox_item "inv" "print built-in commands ..." $width
    toolbox_item "downloadVideo <url> <output_filename>" "use naming with no ext (auto to .webm)" $width
    toolbox_item "downloadVideo <url> <resolution> <output_filename>" "use naming with no ext (auto to .webm)" $width
    toolbox_endl
    _codex_unset
}
tools 
function inv {
    source "$_SCRIPT_DIR/_codex.sh"
    inventory_title "Video Download Tools"
    local width=3
    inventory_item 1 "..." "..." $width
    inventory_endl 
    _codex_unset
    return 0
}

# implementation 
function downloadVideo {
    if [ "$#" -lt 2 ]; then 
        echo "Usage: downloadVideo <url> <output_filename>"
        echo "Usage: downloadVideo <url> <resolution> <output_filename>"
        return 1
    fi
    if [ "$#" -eq 2 ]; then 
        yt-dlp --no-playlist --progress -S "res:360" --output "$2" "$1"
        return 0
    fi
    if [ "$#" -eq 3 ]; then 
        yt-dlp --no-playlist --progress -S "res:$2" --output "$3" "$1"
        return 0
    fi
    echo "Usage: downloadVideo <url> <output_filename>"
    echo "Usage: downloadVideo <url> <resolution> <output_filename>"
}

# END