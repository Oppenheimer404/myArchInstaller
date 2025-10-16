#! /usr/bin/env bash

source "$(dirname "$0")/format-msg.sh"

function header() {
    declare -A d
    local x=0 y=0 p=0 x1=0 x2=0 y1=0 y2=4
    
    for ((i=0; i<${#1}; i++)); do
        c="${1:$i:1}"
        case "$c" in
            D) p=1; d["$y,$x"]=1 ;;
            U) p=0 ;;
            N|E|S|W)
                n="${1:$((i+1)):1}"
                [[ "$n" =~ [0-9] ]] && { r=$n; ((i++)); } || r=1
                for ((j=0; j<r; j++)); do
                    case "$c" in
                        N) ((y--,y<y1)) && y1=$y ;;
                        S) ((y++,y>y2)) && y2=$y ;;
                        E) ((x++,x>x2)) && x2=$x ;;
                        W) ((x--,x<x1)) && x1=$x ;;
                    esac
                    ((p)) && d["$y,$x"]=1
                    
                    # Only animate when pen is down
                    if ((p)); then
                        clear
                        for ((py=y1; py<=y2; py++)); do
                            for ((px=x1; px<=x2; px++)); do
                                [[ ${d["$py,$px"]} ]] && printf "█" || printf " "
                            done
                            printf "\n"
                        done
                        sleep 0.05
                    fi
                done
                ;;
        esac
    done
    
    # Final display
    clear
    for ((py=y1; py<=y2; py++)); do
        for ((px=x1; px<=x2; px++)); do
            [[ ${d["$py,$px"]} ]] && printf "█" || printf " "
        done
        printf "\n"
    done
    printf "\n"
}

function pre_installation() {

	if msg_check "Configure keyboard layout?"; then
		configure_keyboard_layout
	else
		msg_info "Skipping..."
	fi
	
	printf "Verifing boot mode (64=64, 32=32, BIOS=No such file or directory)...\n"
	# cat /sys/firmware/efi/fw_platform_size 

	printf "Connectng to the internet...\n"
	connecting_to_the_internet() {
		
		printf "Ensuring network interface is listed and enabled...\n"
		# ip link
		
		printf "Selecting connection method...\n"
		# do things here

		connect_via_ethernet() {
		
			printf "Connecting to ethernet network...\n"
		
		}
		connect_via_ethernet
		
		connect_via_wifi() {
		
			printf "Ensuring wireless interface is not blocked...\n"
			# rfkill
		
			printf "Unblocking wireless interface if desired (soft-block only)...\n"
			# rfkill unblock {selected-interface}
		
			printf "Connecting to wireless network...\n"
			# iwctl
		
		}
		connect_via_wifi

		connect_via_broadband() {

			printf "Connecting to broadband network...\n"
			# mmcli
		
		}
		connect_via_broadband
	}
	connecting_to_the_internet
	
	printf "Verifying connection...\n"
	# ping 1.1.1.1
	
	printf "Updating system clock,,,\n"
	# timeanddatectl
	
	printf "Partitioning disks...\n"
	partitioning_disks() {

		printf "Starting UEFI partitioning...\n"
		uefi_gpt_partitioning() {
		
			printf "Creating boot partition...\n"
			# /dev/efi_system_partition (1GiB)
		
			printf "Creating swap partition...\n"
			# /dev/swap_partition (4GiB min, Match to RAM Ideal)
		
			printf "Creating root partition...\n"
			# /dev/root_partition (Remainder, 32GiB min)
	
		}
		uefi_gpt_partitioning

		printf "Starting BIOS partitioning...\n"
		bios_mbr_partitioning() {

			printf "Creating swap partition...\n"
			# /dev/swap_partition (4GiB min, Match to RAM Ideal)
		
			printf "Creating root partition...\n"
			# /dev/root_partition (Remainder, 32GiB min)
		
		}
		bios_mbr_partitioning
	
	}
	partitioning_disks

	printf "Formatting disks...\n"
	formatting_disks() {
		
		printf "Starting UEFI formatting...\n"
		uefi_partition_formatting() {
			
			printf "Formatting boot partition..."
			# mkfs.fat -F 32 /dev/efi_system_partition
			
			printf "Formatting swap partition..."
			# mkswap /dev/swap_partition
			
			printf "Formatting root partition..."
			# FILESYSTEM STUFF

		}
		uefi_partition_formatting
		
		printf "Starting BIOS formatting...\n"
		bios_partition_formatting() {
			
			printf "Formatting swap partition...\n"
			# mkswap /dev/swap_partition
			
			printf "Formatting root partition..\n"
			# FILESYSTEM STUFF

		}
		bios_partition_formatting

	}
	formatting_disks

	printf "Mounting UEFI partitions...\n"
	mount_uefi_partitions() {
	
		printf "Mounting root partition...\n"
		# mount /dev/root_partition /mnt
		
		printf "Mounting boot partition...\n"
		# mount --mkdir /dev/boot_partition /mnt/boot
	
		printf "Enabling swap...\n"
		# swapon /dev/swap_partition
	
	}
	mount_uefi_partitions	

	printf "Mounting BIOS partitions...\n"
	mount_bios_partitions() {
	
		printf "Mounting root partition...\n"
		# mount /dev/root_partition /mnt
		
		printf "Enabling swap...\n"
		# swapon /dev/swap_partition
	
	}
	mount_bios_partitions	

}

function configure_keyboard_layout() {
	
	# function to create an array of installed keymaps
	check_keymaps() {
		msg_debug "Checking avaliable keymaps..."

		common_keymaps=("us" "uk" "test" "de" "fr" "dvorak" "colemak")
		available_keymaps=() # create an empty array to fill with avaliable keymaps
		for keymap in ${common_keymaps[@]}; do # for all specified keymaps
			if localectl list-keymaps | grep -q "^${keymap}$"; then # list all keymaps and pipe into grep
				msg_debug "[$keymap] Keymap Installed" # inform user keymap is installed
				available_keymaps+=("$keymap") # add installed keymap(s) to array
			else
				msg_warn "[$keymap] Keymap Not Installed" # warn user keymap is not installed
			fi
		done

		if [[ ${#available_keymaps[@]} -gt 0 ]]; then
			msg_success "Found ${#available_keymaps[@]} keymaps"
			return
		else
			msg_error "No keymaps found. Exiting..."
			exit 1
		fi
	}
	check_keymaps # run function

	select_keymap() {
		# display the array of avaliable keymaps
		msg_info "Available keymaps: [${available_keymaps[*]}]" # list
		
		# prompt user to select from avaliable keymaps
		selected_keymap=$(msg_prompt "Select a keymap" ${available_keymaps[@]}) # select
		if msg_check "Selected: [$selected_keymap] keymap" "$selected_keymap"; then
			msg_debug "A"
			return
		else
			select_keymap
		fi
	}
	select_keymap # run function

	# loadkeys {selected-keymap}
	
	printf "Setting Console Font...\n"
	# ls /usr/share/kbd/consolefonts/
	# setfont {selected-font}
	
}

function main() {

	header "UESEEDEUESDUENDEEEEUESDUENDEUSEDUSEDSSSWUNWDUNWDSSSSUSWDUSWDWWWWUNWDUNWDNNNNUSWDUSWDWNNNUENDUESEESEESESSSSDNWUEEDUWWWNNNSDNUEEEESDNU"

	pre_installation


}

main
