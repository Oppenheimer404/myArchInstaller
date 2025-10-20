#!/usr/bin/env bash

# * Source message formatting script
source "$ROOT_DIR/scripts/format-msg.sh"

# * Prompts user to select a text file to send to generate_header()
    # ? return 2 (ERROR)
    # ! if an unknown response is thrown from msg_check in update_header
    # ! if an unknown response is thrown from msg_check in generate_header
    # ! if compression issues occur
    # ! if compression results in an empty string
    # ? return 1 (WARNING)
    # ! if no text files are found
    # ! if user selects c or cancel
    # ! if the file passed to generate_header doesn't exist
    # ! if the file passed to generate_header is empty
    # ? return 0 (SUCCESS)
    # * if user selects n or no to skip updating the header
    # ? return generate_header
        # ? return 2
        # ? return 1
        # ? return 0

function update_header() {
    msg_check "Would you like to update the header?" "y"
	local response=$?
	case $response in
		0)
        # ? Y|Yes
        :
        ;;
		1)
        # ? N|No
        # * Skipping header update prompt returns 0
		msg_debug "Skipping..."
		return 0
        ;;
        2)
        # ? C|Cancel
        # ! Cancelling returns 1
		return 1
        ;;
        *)
        # ? Unknown Value
        # ! (ERROR) Broken function in format-msg.sh
		msg_error "Unknown response from msg_check in update_header: $response"
		return 2
        ;;
	esac

    # * Search for text files in chosen directory
    mapfile -t txt_files < <(cd "$ROOT_DIR" && find . -name "*.txt" | sed 's|^\./||')

    # ! Inform the user and return error code if no text files exist 
    if [[ ${#txt_files[@]} -lt 1 ]]; then
        msg_warn "No text files found within [$ROOT_DIR]!"
        msg_warn "Cancelling..."
        return 1
    fi
    
    # * Prompt user to select from available text files
    msg_success "Found ${#txt_files[@]} text files"
    local selected_file=$(msg_prompt "Select a text file" "${txt_files[@]}")
    msg_debug "Selected: $selected_file"
    
    # * Attempt to generate header from text file
    generate_header "$ROOT_DIR/$selected_file"
    return $?
        
}

function generate_header() {
    
    # ! Inform user and return error code if file does not exist
    local input_file="$1"
    if [[ ! -f "$input_file" ]]; then
        msg_warn "File not found: $input_file"
        return 1
    fi
    
    # * Double check the selected header file
    msg_check "Confirm header file: $input_file" "$input_file"
    local response=$?
    case $response in
        0)
        :
        ;;
        1)
        # ? N|No
        update_header
        return 0
        ;;
        2)
        # ? C|Cancel
        return 1
        ;;
        *)
        # ? Unknown Value
        # ! (ERROR) Broken function in format-msg.sh 
        msg_error "Unexpected response from msg_check in generate_header: $response"
        return 2
        ;;
    esac

    # * Check file length and inform user
    msg_debug "Checking file contents: $input_file"
    local original_string=$(cat "$input_file")
    local original_length=${#original_string}
    msg_debug "Original: $original_length chars"
    
    # ! Inform user and return error code if input file is empty
    if [[ $original_length -eq 0 ]]; then
        msg_warn "Input file is empty"
        return 1
    fi
    
    # * Attempt to compress header file
    msg_debug "Compressing: $input_file"
    local compressed_string=$(set -o pipefail; cat "$input_file" | gzip | base64 -w0)
    local exit_code=$?

    # ! Checking for direct compression
    if [[ $exit_code -ne 0 ]]; then
        # ! (ERROR) Compression issues in `cat "$input_file" | gzip | base64 -w0`
        msg_error "Compression pipeline failed: $exit_code"
        return 2
    fi

    # * Check compressed length and inform user
    local compressed_length=${#compressed_string}
    msg_debug "Compressed: $compressed_length chars"
    msg_debug "Ratio: $(( (compressed_length * 100) / original_length ))%"

    # ! Checking for empty compression output        
    if [[ -z "$compressed_string" ]]; then
        # ! (ERROR) Compression issues in `cat "$input_file" | gzip | base64 -w0`
        msg_error "Compression produced empty output: $input_file >> $compressed_string"
        return 2
    fi

    # * Save compressed file as `h.enc`
    msg_debug "Saving compressed file: $input_file >> h.enc"
    printf '%s' "$compressed_string" > "$ROOT_DIR/header/h.enc"
    msg_debug "Compressed header saved to $ROOT_DIR/header/h.enc"
    msg_success "Header updated!"
    return 0

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