# BEGIN : video_download_yt_dlp.sh

# -- dependencies
# 1. yt-dlp cli tool for download youtube videos 

# -- description 

# RED = 31 - 41
# GREEN = 32 - 42
# YELLOW = 33 - 43
# BLUE = 34 - 44
# MAGENTA = 35 - 45
# CYAN = 36 - 46
# WHITE = 37 - 47
function color_echo {
    local color=$1
    shift
    echo -e "\e[${color}m$@\e[0m"
}

echo ""
color_echo 33 "=== Video/Music Download ==="
echo "downloadVideo <url> <output_filename> : use naming with no ext (auto to .webm)"
echo "downloadVideo <url> <resolution> <output_filename> : use naming with no ext (auto to .webm)"
echo ""

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