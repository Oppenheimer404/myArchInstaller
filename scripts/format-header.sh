#!/usr/bin/env bash

# TODO: Handle ROOT_DIR if ran as standalone script

# * Source message formatting script
source "$ROOT_DIR/scripts/format-msg.sh"

# * Prompts user to select a text file to send to generate_header()
    # * :update_header() < [0x06]
        # * [0x00]      (SUCCESS)   return 0    if user selects n or no to skip updating the header
        # ! [0x01]      (EXIT)      return 1    if user selects c or cancel to cancel the operation
        # ! [0x02]      (ERROR)     return 2    if an unknown response is thrown from msg_check in update_header
        # ! [0x03]      (EXIT)      return 1    if no text files are found for header generation
        # ? [0x04]      (CASE)      return ?    pass users selected file to generate_header()
            # * :generate_header()
            # ! [0x05]  (EXIT)      return 1        if the file passed to generate_header doesn't exist
            # * [0x06]  (RETRY)     return 0        if the user selects n or no to confirming the header file > :update_header()
            # ! [0x07]  (EXIT)      return 1        if user selects c or cancel to cancel the operation
            # ! [0x08]  (ERROR)     return 2        if an unknown response is thrown from msg_check in generate_header
            # ! [0x09]  (EXIT)      return 1        if the file passed to generate_header is empty
            # ! [0x10]  (ERROR)     return 2        if compression issues occur
            # ! [0x11]  (ERROR)     return 2        if compression results in an empty string
            # * [0x12]  (SUCCESS)   return 0        if the compressed file is properly saved to h.enc
# *

function update_header() {
    msg_check "Would you like to update the header?" "y"
	local response=$?
	case $response in
		0)
        # ? Y|Yes
        : # * User has confirmed they would like to update header
        ;;
		1)
        # ? N|No
		msg_debug "Skipping..."
		return 0 # * [0x00] User has skipped operation
        ;;
        2)
        # ? C|Cancel
		return 1 # ! [0x01] User has cancelled operation
        ;;
        *)
        # ? Unknown Value
		msg_error "Unknown response from msg_check in update_header: $response"
		return 2 # ! [0x02] Broken function in format-msg.sh
        ;;
	esac

    # * Search for text files in chosen directory
    mapfile -t txt_files < <(cd "$ROOT_DIR" && find . -name "*.txt" | sed 's|^\./||')

    # * Validate the list of existing text files includes at least one file  
    if [[ ${#txt_files[@]} -lt 1 ]]; then
        msg_warn "No text files found within [$ROOT_DIR]!"
        msg_warn "Cancelling..."
        return 1 # ! [0x03] No text files exist
    fi
    
    # * Prompt user to select from available text files
    msg_success "Found ${#txt_files[@]} text files"
    local selected_file=$(msg_prompt "Select a text file" "${txt_files[@]}")
    msg_debug "Selected: $selected_file"
    
    # * Attempt to generate header from text file
    generate_header "$ROOT_DIR/$selected_file"
    return $? # ? [0x04] generate_header()
        
}

function generate_header() {
    
    # * Set input file and ensure it exists
    local input_file="$1"
    if [[ ! -f "$input_file" ]]; then
        msg_warn "File not found: $input_file"
        return 1 # ! [0x05] File does not exist
    fi
    
    # * Double check the selected header file
    msg_check "Confirm header file: $input_file" "$input_file"
    local response=$?
    case $response in
        0)
        : # * Secondary confirmation has been passed
        ;;
        1)
        # ? N|No
        update_header
        return 0 # * [0x06] User has selected no to confirming header file
        ;;
        2)
        # ? C|Cancel
        return 1 # ! [0x07] User has cancelled operation
        ;;
        *)
        # ? Unknown Value
        msg_error "Unexpected response from msg_check in generate_header: $response"
        return 2 # ! [0x08] Broken function in format-msg.sh
        ;;
    esac

    # * Check file length and inform user
    msg_debug "Checking file contents: $input_file"
    local original_string=$(cat "$input_file")
    local original_length=${#original_string}
    msg_debug "Original: $original_length chars"
    
    # * Validate that input file contains text to generate header from
    if [[ $original_length -eq 0 ]]; then
        msg_warn "Input file is empty"
        return 1 # ! [0x09] Input file is empty
    fi
    
    # * Attempt to compress header file and check for any pipeline errors
    msg_debug "Compressing: $input_file"
    local compressed_string=$(set -o pipefail; cat "$input_file" | gzip | base64 -w0)
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        msg_error "Compression pipeline failed: $exit_code"
        return 2 # ! [0x10] Compression issues in `cat "$input_file" | gzip | base64 -w0`
    fi

    # * Check compressed length and ensure compression string exists
    local compressed_length=${#compressed_string}
    msg_debug "Compressed: $compressed_length chars"
    msg_debug "Ratio: $(( (compressed_length * 100) / original_length ))%"
    if [[ -z "$compressed_string" ]]; then
        msg_error "Compression produced empty output: $input_file >> $compressed_string"
        return 2 # ! [0x11] Compression pipeline lead to an empty string output
    fi

    # * Save compressed file as `h.enc`
    msg_debug "Saving compressed file: $input_file >> h.enc"
    printf '%s' "$compressed_string" > "$ROOT_DIR/header/h.enc"
    msg_debug "Compressed header saved to $ROOT_DIR/header/h.enc"
    msg_success "Header updated!"
    return 0 # * [0x12] Successfully saved header file to h.enc

}

function print_header() {

    local compressed_file="$1"

    if [[ ! -f "$compressed_file" ]]; then
        msg_error "Compressed header file not found: $compressed_file"
        return 1
    fi

    local header_string=$(cat "$compressed_file" | base64 -d | gunzip)
    
    # * Hide users cursor for the duration of the animation
    tput civis
    trap 'tput cnorm' RETURN

    # ? Only replace @ when it's:
    # *     Alone on a line (@\n) && Followed by whitespace and a digit (@ 0.5 or @0.5)
    # !     Everything else stays as literal @
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