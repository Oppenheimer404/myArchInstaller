#! /usr/bin/env bash

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export ROOT_DIR

source "$ROOT_DIR/scripts/format-msg.sh"

TIMESHIFT_SOURCE="/timeshift"

function backup_prerequisites() {
    if [ "$EUID" -ne 0 ]; then 
        msg_error "Please run as root (use sudo)"
        return 1
    fi

    local response
    msg_info "Default timeshift source: $TIMESHIFT_SOURCE"
    msg_check "Would you like to select a different source?" "$TIMESHIFT_SOURCE"
    response=$?
    case $response in
        0)
        # ? y|yes
        msg_info "Please select a new source directory"
        printf "New Source Location > "
        read -r TIMESHIFT_SOURCE
        msg_info "Selected: $TIMESHIFT_SOURCE"
        ;;
        1)
        # ? n|no
        msg_info "Continuing with default source: $TIMESHIFT_SOURCE"
        ;;
        2)
        # ? c|cancel
        return 1
        ;;
        *)
        # ? unknown response
        msg_error "Unexpected response from msg_check"
        return 2
        ;;
    esac

    if [ ! -d "$TIMESHIFT_SOURCE/snapshots" ]; then
        msg_warn "Please check your Timeshift installation and snapshot location"
        msg_error "Timeshift directory not found at $TIMESHIFT_SOURCE"
        return 1
    fi

    msg_debug "Calculating size of Timeshift snapshots..."

    # * Delay message for user if calculation takes too long
    local delay=10 # ? Seconds
    ( sleep "$delay" && msg_info "This might take a while. Please be patient...") &
    local wait_msg_pid=$!

    # * Calculate size of timeshift directory
    local timeshift_size_b=$(du -sb "$TIMESHIFT_SOURCE" | awk '{print $1}')
    local timeshift_size_h=$(du -sh "$TIMESHIFT_SOURCE" | awk '{print $1}')
    msg_debug "Timeshift directory size: $timeshift_size_h"
    
    # * Check if the wait message has displayed & kill it if it has not
    if kill -0 "$wait_msg_pid" 2>/dev/null; then
        kill "$wait_msg_pid" 2>/dev/null
        wait "$wait_msg_pid" 2>/dev/null
    fi
    
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
        msg_debug "Process interrupted in backup_prerequisites"
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