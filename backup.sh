#! /usr/bin/env bash

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export ROOT_DIR

source "$ROOT_DIR/scripts/format-msg.sh"

TIMESHIFT_SOURCE="/timeshift"

function backup_prerequisites() {
    # * Verify that user script was executed with root permissions
    if [ "$EUID" -ne 0 ]; then 
        msg_error "Please run as root (use sudo)"
        return 1 # ! [0x00] this script requires sudo to work
    fi    

    # * Verify default timeshift location is ok with user
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
        return 1 # ! [0x01] user has cancelled script
        ;;
        *)
        # ? unknown response
        msg_error "Unexpected response from msg_check while selecting timeshift source"
        return 2 # ! [0x02] unknown response thrown from msg_check
        ;;
    esac

    # * Ensure selected source directory is a timeshift directory by looking for /snapshots subdirectory
    if [ ! -d "$TIMESHIFT_SOURCE/snapshots" ]; then
        msg_warn "Please check your Timeshift installation and snapshot location"
        msg_error "Timeshift directory not found at $TIMESHIFT_SOURCE"
        return 1 # ! [0x03] timeshift directory not found
    fi

    # * Delay message for user if calculation takes too long
    local delay=10 # ? Seconds
    ( sleep "$delay" && msg_info "This might take a while. Please be patient...") &
    local wait_msg_pid=$!

    # * Calculate size of timeshift directory
    msg_debug "Calculating size of Timeshift snapshots..."
    local timeshift_size_b=$(du -sb "$TIMESHIFT_SOURCE" | awk '{print $1}')
    local timeshift_size_h=$(du -sh "$TIMESHIFT_SOURCE" | awk '{print $1}')
    msg_debug "Timeshift directory size: $timeshift_size_h"

    # * Check if the wait message has displayed & kill it if it has not
    if kill -0 "$wait_msg_pid" 2>/dev/null; then
        kill "$wait_msg_pid" 2>/dev/null
        wait "$wait_msg_pid" 2>/dev/null
    fi

    # * Search for all mounted devices with compatible filesystems
    local mount_points
    mapfile -t mount_points < <(findmnt -r -n -t ext4,ext3,xfs,btrfs -o TARGET | grep -E "/media|/mnt")
    if [ ${#mount_points[@]} -eq 0 ]; then
        msg_warn "Please mount your external drive and try again."
        msg_error "No suitable mounted drives found."
        return 1 # ! [0x04] no mount points found
    fi

    # * List all mounted drives
    msg_info "Available destination drives:"
    findmnt -t ext4,ext3,xfs,btrfs -o TARGET,SOURCE,FSTYPE,SIZE | head -n 1
    findmnt -t ext4,ext3,xfs,btrfs -o TARGET,SOURCE,FSTYPE,SIZE | grep -E "/media|/mnt"

    # * Swap order of list to match findmnt
    local reversed=()
    for ((i=${#mount_points[@]}-1; i>=0; i--)); do
        reversed+=("${mount_points[i]}")
    done
    local mount_points=("${reversed[@]}")
    
    # * Allow user to select drive and subdirectory from drive
    local selected_drive=$(msg_prompt "Select a destination drive" "${mount_points[@]}")

    # TODO: select subdirectory

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
        msg_warn "Process interrupted in backup_prerequisites"
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