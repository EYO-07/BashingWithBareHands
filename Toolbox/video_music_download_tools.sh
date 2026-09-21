# BEGIN : video_download_yt_dlp.sh
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -- dependencies
# 1. yt-dlp cli tool for download youtube videos 


# -- variables
__YTDLP_RESOLUTION=360
__YTDLP_FORMAT="webm"

__BWBH_SAVE_CONFIG_ytdlp_video() {
    source "$_SCRIPT_DIR/_codex.sh"
    local config_path="$HOME/.config/BashingWithBareHands/video_music_download_tools.conf"
    if [[ ! -f "$config_path" ]]; then 
        crit_echo "... config file not found"
        good_echo "... creating config file"
        create_intermediate_dirs "$config_path"
    fi 
    save_variables "$config_path" "__YTDLP_RESOLUTION" "__YTDLP_FORMAT"
}

# -- description 
function tools {
    source "$_SCRIPT_DIR/_codex.sh"
    local config_path="$HOME/.config/BashingWithBareHands/video_music_download_tools.conf"
    [[ -f "$config_path" ]] && source "$config_path"
    local width=4
    toolbox_title "Video Download Tools"
    toolbox_item "tools" "print this ..." $width
    #toolbox_item "inv" "print built-in commands ..." $width
    if is_command_valid "yt-dlp"; then 
        toolbox_item "setVideoResolution" "set yt-dlp video quality (Current: $__YTDLP_RESOLUTION)" $width
        toolbox_item "setVideoFormat" "set yt-dlp output format (Current: $__YTDLP_FORMAT)" $width
        toolbox_item "downloadVideos" "download videos from a list with yt-dlp" $width
    else 
        crit_echo "... requires: yt-dlp"
    fi
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

# -- implementation 
function downloadVideos {
    source "$_SCRIPT_DIR/_codex.sh"
    local config_path="$HOME/.config/BashingWithBareHands/video_music_download_tools.conf"
    [[ -f "$config_path" ]] && source "$config_path"
    local video_url_list="$1"
    if [[ -z "$video_url_list" ]]; then 
        warn_echo "Usage: downloadVideos <file>"
        echo "... <file> should be a text file with a list of urls to download"
        _codex_unset
        return 1
    fi 
    [[ -f "$video_url_list" ]] || { _codex_unset; return 1; }
    local -a urls=()
    parse_file_to_string_array urls "$video_url_list"
    echo ""
    info_echo "-- urls to download --"
    for i in "${urls[@]}"; do
        echo "$i"
    done
    echo ""
    echo "Preferred Quality : $__YTDLP_RESOLUTION"
    echo "Preferred Format : $__YTDLP_FORMAT"
    if ! token_prompt "Confirmation" "proceed to download?"; then 
        _codex_unset 
        return 1
    fi
    yt-dlp \
        --part --continue --no-playlist --progress \
        --format "bv*+ba/b" \
        --format-sort "res:${__YTDLP_RESOLUTION},ext:${__YTDLP_FORMAT}" \
        --batch-file "$video_url_list"
    _codex_unset
}
function setVideoResolution {
    source "$_SCRIPT_DIR/_codex.sh"
    local res="$1"
    if [[ -z "$res" ]]; then 
        echo "Current Resolution: $__YTDLP_RESOLUTION"
        echo "... could be: 360 480 720 1080 ..."
        warn_echo "Usage: setVideoResolution <resolution>"
        _codex_unset
        return 1
    fi 
    __YTDLP_RESOLUTION="$res"
    __BWBH_SAVE_CONFIG_ytdlp_video
    _codex_unset
}
function setVideoFormat {
    source "$_SCRIPT_DIR/_codex.sh"
    local video_format="$1"
    if [[ -z "$video_format" ]]; then 
        echo "Current Format: $__YTDLP_FORMAT"
        echo "... could be: webm mp4 mp3 ogg wav ..."
        warn_echo "Usage: setVideoFormat <format>"
        _codex_unset
        return 1
    fi 
    __YTDLP_FORMAT="$video_format"
    __BWBH_SAVE_CONFIG_ytdlp_video
    _codex_unset
}

# END