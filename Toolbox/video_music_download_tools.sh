# BEGIN : video_download_yt_dlp.sh

# -- dependencies
# 1. yt-dlp cli tool for download youtube videos 

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