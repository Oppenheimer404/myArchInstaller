#!/usr/bin/env bash

source "$ROOT_DIR/scripts/format-msg.sh"

function generate_header() {
    local input_file="$1"
    if [[ ! -f "$input_file" ]]; then
        msg_error "File not found!"
        return 1
    fi
    
    local original_string=$(cat "$input_file")
    local original_length=${#original_string}
    
    local compressed_string=$(cat "$input_file" | gzip | base64 -w0)
    local compressed_length=${#compressed_string}
    
    msg_debug "Original:   $original_length chars"
    msg_debug "Compressed: $compressed_length chars"
    msg_debug "Ratio:      $(( (compressed_length * 100) / original_length ))%"
    
    printf "$compressed_string"
}

function print_header() {
    local compressed_file="$1"
    local header_string=$(cat "$compressed_file" | base64 -d | gunzip)
    
    tput civis
    trap 'tput cnorm' RETURN

    # Only replace @ when it's:
    # 1. Alone on a line (@\n)
    # 2. Followed by whitespace and a digit (@ 0.5 or @0.5)
    # Everything else stays as literal @
    local processed=$(printf '%s' "$header_string" | \
        sed ':a;N;$!ba;s/\n@\n/\x1E\n/g;s/\n@\([[:space:]]*[0-9]\)/\x1E\1/g')
    
    local parts
    mapfile -td $'\x1E' parts < <(printf '%s' "$processed")
    
    local last_delay=""
    for part in "${parts[@]}"; do
        [[ -z "$part" ]] && continue
        
        local first_line="${part%%$'\n'*}"
        
        if [[ "$first_line" =~ ^[[:space:]]*([0-9.]+)[[:space:]]*$ ]]; then
            last_delay="${BASH_REMATCH[1]}"
            sleep "$last_delay"
            clear
            local rest="${part#*$'\n'}"
            [[ -n "$rest" ]] && printf '%s\n\n' "$rest"
        else
            [[ -n "$last_delay" ]] && sleep "$last_delay"
            clear
            printf '%s\n\n' "${part#$'\n'}"
        fi
    done
}