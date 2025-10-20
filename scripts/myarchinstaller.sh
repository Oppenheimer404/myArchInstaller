#! /usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
export ROOT_DIR

source "$ROOT_DIR/scripts/format-msg.sh"
source "$ROOT_DIR/scripts/format-header.sh"

# COMMENT STYLES
# * Highlight
# ! Warning
# ? Question
# TODO: Task
#// CODE

function configure_keyboard_layout() {
	
	check_keymaps() {
		msg_debug "Checking available keymaps..."
		# ? Check for common keymaps first to save time and display nicely
		local common_keymaps=("us" "uk" "de" "fr" "dvorak" "colemak")
		# local common_keymaps=("us" "uk" "test" "de" "fr" "dvorak" "colemak") # ! (TEST) Variable for missing [test] keymap
		# local common_keymaps=("test") # ! (TEST) Variable for missing common keymaps
		
		# ? Loop through common keymaps to determine which are available (installed)
		local keymap
		available_keymaps=()
		for keymap in ${common_keymaps[@]}; do
			if localectl list-keymaps | grep -q "^${keymap}$"; then
				msg_debug "[$keymap] Keymap installed"
				available_keymaps+=("$keymap") # * Add installed keymaps to available keymaps
			else
				msg_warn "[$keymap] Keymap not installed" # ! (WARNING) Missing common keymap file
			fi
		done

		if [[ ${#available_keymaps[@]} -gt 0 ]]; then
			msg_success "Found ${#available_keymaps[@]} keymaps"
			return
		else
			msg_error "Common keymap files not found!" # ! (ERROR) Missing all common keymap files
			exit 1
		fi
	}
	check_keymaps

	select_keymap() {
		msg_info "Available keymaps: [${available_keymaps[*]}]" # list
		
		selected_keymap=$(msg_prompt "Select a keymap" ${available_keymaps[@]}) # select
		msg_check "Selected: [$selected_keymap] keymap" "$selected_keymap"
		local response=$?
		case $response in
			0)
			# * Yes
			# TODO: Load the user's selected keymap
			# ? loadkeys $selected_keymap
			msg_debug "Continue"
			return
			;;
			1)
			# ! No
			select_keymap
			;;
			2)
			# ! Cancel
			msg_warn "Cancelling..."
			# TODO: Add soft cancel
			;;
			*)
			# ! Return value unknown
			msg_error "unexpected response from msg_check in select_keymap"
			;;
		esac
	}
	select_keymap # run function
	
	
}

function pre_installation() {
	
	printf "Setting console font...\n"
	# TODO: Set console font
		# TODO: List available console fonts
		# ? ls /usr/share/kbd/consolefonts/
		# TODO: Allow user to select console font
		# TODO: Set the user's selected console font
		# ? setfont $selected_font

	printf "Verifying boot mode (64=64, 32=32, BIOS=No such file or directory)...\n"
	# cat /sys/firmware/efi/fw_platform_size 

	printf "Connecting to the internet...\n"
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

function main() {

	# * These are external functions from format-header.sh 
	print_header "$ROOT_DIR/header/h.enc"
	update_header # ? This function allows a user to provide their own header animation file
	# *
	
	msg_check "Configure keyboard layout?" "y"
	local r=$?
	case $r in
		0)
		configure_keyboard_layout
		;;
		1)
		msg_debug "Skipping..."
		;;
		2)
		exit 0
		;;
		*)
		msg_error "unexpected return from msg_check in pre_installation"
		;;
	esac
	
	#//pre_installation
}

main
