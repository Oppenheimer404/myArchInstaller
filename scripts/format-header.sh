#!/usr/bin/env bash

source "$ROOT_DIR/scripts/format-msg.sh"

# ? Function for prompting user to select text file for use in updating compressed h.enc file
function update_header() {

    msg_check "Would you like to update the header?" "y"
	local response=$?
	case $response in
		0)
		mapfile -t txt_files < <(cd "$ROOT_DIR" && find . -name "*.txt" | sed 's|^\./||')
		local selected_file=$(msg_prompt "Select a text file" "${txt_files[@]}")
		msg_debug "Selected: $selected_file"
		generate_header "$ROOT_DIR/$selected_file" # ? Pass the selected text file to generate header for confirmation
        ;;
		1)
		msg_debug "Skipping..."
		return 0
        ;;
		2)
		msg_warn "Cancelling..."
		# TODO: Add soft cancel
		return 1
        ;;
		*)
		msg_error "Unknown response from msg_check"
		return 2
        ;;
	esac

}

function generate_header() {
    
    local input_file="$1"
    if [[ ! -f "$input_file" ]]; then
        msg_error "File not found!"
        return 1
    fi
    
    msg_check "Confirm header file: $input_file" "$input_file"
    local response=$?
    case $response in
        0)
        msg_debug "Compressing and saving: $input_file"
        local original_string=$(cat "$input_file")
        local original_length=${#original_string}
        msg_debug "Original:   $original_length chars"
        
        if [[ $original_length -eq 0 ]]; then
            msg_error "Input file is empty"
            return 1
        fi
        
        local compressed_string=$(set -o pipefail; cat "$input_file" | gzip | base64 -w0)
        local exit_code=$?

        if [[ $exit_code -ne 0 ]]; then
            msg_error "Compression pipeline failed"
            return 1
        fi

        if [[ -z "$compressed_string" ]]; then
            msg_error "Compression produced empty output"
            return 1
        fi

        local compressed_length=${#compressed_string}
        msg_debug "Compressed: $compressed_length chars"
        msg_debug "Ratio:      $(( (compressed_length * 100) / original_length ))%"
        
        printf '%s' "$compressed_string" > "$ROOT_DIR/header/h.enc"
        msg_success "Header updated!"
        msg_debug "Compressed header saved to $ROOT_DIR/header/h.enc"
        
        return 0
        ;;
        1)
        update_header
        ;;
        2)
        return 1
        ;;
        *)
        msg_error "unexpected return from msg_check in generate_header"
        return 1
        ;;
    esac

    msg_error "reached end of function in generate_header"
    return 1
}

function print_header() {

    local compressed_file="$1"

    if [[ ! -f "$compressed_file" ]]; then
        msg_error "Compressed header file not found: $compressed_file"
        return 1
    fi

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