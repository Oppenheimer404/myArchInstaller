#! /usr/bin/env bash

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export ROOT_DIR

source "$ROOT_DIR/scripts/format-msg.sh"

function timeshift_prerequisites() {

    # * Verify default timeshift location is ok with user
    TIMESHIFT_SOURCE="/timeshift"
    msg_info "Default timeshift source: $TIMESHIFT_SOURCE"
    msg_check "Would you like to use the default source?" "$TIMESHIFT_SOURCE"
    local response=$?
    case $response in
        0)
        # ? y|yes
        msg_info "Continuing with default source: $TIMESHIFT_SOURCE"
        # * Continue with default timeshift source
        ;;
        1)
        # ? n|no
        msg_info "Please select a new source directory"
        printf "New Source Location > "
        read -r TIMESHIFT_SOURCE
        msg_info "Selected: $TIMESHIFT_SOURCE"
        # * Continue with users selected timeshift source
        ;;
        2)
        # ? c|cancel
        return 1 # ! user has cancelled script
        ;;
        *)
        # ? unknown response
        msg_error "Unexpected response from msg_check while selecting timeshift source"
        return 2 # ! unknown response thrown from msg_check
        ;;
    esac

    # * Ensure selected source directory is a timeshift directory by looking for /snapshots subdirectory
    if [ ! -d "$TIMESHIFT_SOURCE/snapshots" ]; then
        msg_warn "Please check your Timeshift installation and snapshot location"
        msg_error "Timeshift directory not found at $TIMESHIFT_SOURCE"
        return 1 # ! timeshift directory not found
    fi

    # * Delay message for user if calculation takes too long
    local delay=10 # ? Seconds
    ( sleep "$delay" && msg_info "This might take a while. Please be patient...") &
    local wait_msg_pid=$!

    # * Calculate size of timeshift directory
    msg_debug "Calculating size of Timeshift snapshots..."
    TIMESHIFT_SIZE=$(du -sb "$TIMESHIFT_SOURCE" | awk '{print $1}')
    TIMESHIFT_SIZE_H=$(du -sh "$TIMESHIFT_SOURCE" | awk '{print $1}')
    msg_debug "Timeshift directory size: $TIMESHIFT_SIZE_H"

    # * Check if the wait message has displayed & kill it if it has not
    if kill -0 "$wait_msg_pid" 2>/dev/null; then
        kill "$wait_msg_pid" 2>/dev/null
        wait "$wait_msg_pid" 2>/dev/null
    fi

    return 0 # * TIMESHIFT_SOURCE & TIMESHIFT_SIZE are now set

}

function storage_prerequisites() {

    # * Search for all mounted devices with compatible filesystems
    local mount_points
    mapfile -t mount_points < <(findmnt -r -n -t ext4,ext3,xfs,btrfs -o TARGET | grep -E "/media|/mnt")
    if [ ${#mount_points[@]} -eq 0 ]; then
        msg_warn "Please mount your external drive and try again."
        msg_error "No suitable mounted drives found."
        return 1 # ! no mount points found
    fi

    # * List all mounted drives
    msg_info "Available destination drives:"
    findmnt -t ext4,ext3,xfs,btrfs -o TARGET,SOURCE,FSTYPE,SIZE,AVAIL | head -n 1
    findmnt -t ext4,ext3,xfs,btrfs -o TARGET,SOURCE,FSTYPE,SIZE,AVAIL | grep -E "/media|/mnt"
    
    # * Allow user to select drive and subdirectory from drive
    local selected_drive=$(msg_prompt "Select a destination drive" "${mount_points[@]}")

    local depth=1
    while true; do
        if [ $depth -lt 1 ]; then
            depth=1
        fi
        msg_debug "Depth: $depth"
        local directories
        mapfile -t directories < <(find "$selected_drive" -maxdepth $depth -mindepth $depth -type d -printf '/%P\n')
        local directories=("[>] Go deeper" "[<] Go back" "." "${directories[@]}")
        local selected_directory=$(msg_prompt "Select a directory" "${directories[@]}")
        if [ "$selected_directory" = "[>] Go deeper" ]; then
            ((depth++))
        elif [ "$selected_directory" = "[<] Go back" ]; then
            ((depth--))
        elif [ "$selected_directory" = "." ]; then
            SELECTED_DIRECTORY="$selected_drive"
            break
        else
            SELECTED_DIRECTORY="$selected_drive$selected_directory"
            break
        fi
    done

    # * Validate there is enough room within selected directory to continue    
    msg_debug "Checking available space in: $SELECTED_DIRECTORY"
    local available_space=$(df --output=avail -B1 "$SELECTED_DIRECTORY" | tail -1)
    local available_space_h=$(df --output=avail -h "$SELECTED_DIRECTORY" | tail -1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    if [ "$TIMESHIFT_SIZE" -gt "$available_space" ]; then
        msg_warn "Required space: $TIMESHIFT_SIZE_H"
        msg_warn "Available space: $available_space_h"
        msg_error "Not enough space in selected drive"
        return 1 # ! storage requirements not met
    fi
    
    msg_info "Required space: $TIMESHIFT_SIZE_H"
    msg_info "Available space: $available_space_h"
    
    return 0
}

function backup_prerequisites() {

    # * Verify that user script was executed with root permissions
    if [ "$EUID" -ne 0 ]; then 
        msg_error "Please run as root (use sudo)"
        return 1 # ! this script requires sudo to work
    fi    

    timeshift_prerequisites
    local response=$?
    case $response in
        0)
        : # * Continuing
        ;;
        1)
        return 1
        ;;
        2)
        # ! Error message thrown from timeshift_prerequisites
        return 2
        ;;
        *)
        msg_error "Unexpected response from timeshift_prerequisites"
        return 2
        ;;
    esac

    storage_prerequisites
    local response=$?
    case $response in
        0)
        : # * Continuing
        ;;
        1)
        return 1
        ;;
        2)
        # ! Error message thrown from storage_prerequisites
        return 2
        ;;
        *)
        msg_error "Unexpected response from storage_prerequisites"
        return 2
        ;;
    esac

    return 0

}

function main() {

    backup_prerequisites
    local response=$?
    case $response in
        0)
        # * Continuing
        msg_debug "All prerequisites have been met"
        msg_info "Continuing..."
        ;;
        1)
        msg_warn "Exiting..."
        return 1
        ;;
        *)
        msg_error "Unexpected response from backup_prerequisites"
        return 2
        ;;
    esac
    
}

main