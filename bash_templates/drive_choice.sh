#!/bin/bash

set -e

#-------------------------------------------------------------------------------
# This is a template script for choosing one of the connected storage devices.
#-------------------------------------------------------------------------------

# Highlight the output.
YELLOW="\e[1;33m" && RED="\e[1;31m" && GREEN="\e[1;32m" && COLOR_OFF="\e[0m"
cprint() { echo -ne "${1}${2}${COLOR_OFF}"; }
msg() { cprint ${YELLOW} "${1}\n"; }
success() { cprint ${GREEN} "${1}\n"; }

# Prompt the user to choose one of the options.
# Adapted from: https://unix.stackexchange.com/a/415155
function single_choice {

	# Parse arguments. Set line shift dependent on the number of lines.
    local return_value=$1
    local -n options_value=$2
    local title_value=$3

	# Print out title and instructions.
    msg "$title_value\n"
    echo -e "[ Navigate (Up/Down) | Confirm (Enter) ]"

    # Print upper table border.
    max_len=$(printf '%s\n' "${options[@]}" | wc -L)
    printf -v hr '%*s'  "$((max_len+7))" '' && hr=${hr// /—}
    echo "$hr"

    # Helper functions for terminal print control and key input.
    ESC=$( printf "\033")
    cursor_blink_on()  { printf "$ESC[?25h"; }
    cursor_blink_off() { printf "$ESC[?25l"; }
    cursor_to()        { printf "$ESC[$1;${2:-1}H"; }
    print_option()     { printf "[ ]   $1 "; }
    print_selected()   { printf "[+]  $ESC[7m $1 $ESC[27m"; }
    get_cursor_row()   { IFS=';' read -sdR -p $'\E[6n' ROW COL; echo ${ROW#*[}; }
    key_input()        { read -s -n3 key 2>/dev/null >&2
                         if [[ $key = $ESC[A ]]; then echo up;    fi
                         if [[ $key = $ESC[B ]]; then echo down;  fi
                         if [[ $key = ""     ]]; then echo enter; fi; }

    # Initially print empty new lines (scroll down if at bottom of screen).
    for option in "${options[@]}"; do printf "\n"; done
    # Print lower table border.
    echo -e "$hr"

    # Determine current screen position for overwriting the options.
    local lastrow=`get_cursor_row`
    local startrow=$(($lastrow - ${#options_value[@]}-1))

    # Ensure cursor and input echoing back on upon a ctrl+c during read -s.
    trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
    cursor_blink_off

    # Main loop: wait for user response.
    local selected=0
    while true; do
        # Print options by overwriting lines.
        local idx=0
        for option in "${options[@]}"; do
            cursor_to $(($startrow + $idx))
            if [ $idx -eq $selected ]; then
                print_selected "$option"
            else
                print_option "$option"
            fi
            ((idx++)) || true
        done
        # User key control.
        case `key_input` in
            enter) break;;
            up)    ((selected--)) || true;
				if [ $selected -lt 0 ]; then selected=$((${#options_value[@]}-1)); fi;;
            down)  ((selected++)) || true;
                if [ $selected -ge "${#options_value[@]}" ]; then selected=0; fi;;
        esac
    done

    # Return cursor position back to normal.
    cursor_to $lastrow
    printf "\n"
    cursor_blink_on

    # Return user's choice.
    eval $return_value="$selected"
}

title="Choose a drive (entire block device, not partition):"

# Obtain information about disk drives.
raw=$(lsblk -dno NAME,SIZE,TRAN,MODEL | awk -v OFS='|' '{
    model = substr($0, index($0, $4),20); print "/dev/" $1, $3, $2, model}')
mapfile -t options < <(printf '%s\n' "$raw" | column -t  -s "|" -o " | ")

# Display options and wait for user response.
single_choice result options "$title"

# Display user's choice.
msg "You've chosen - Option #$((result+1)): ${options[$result]%% *}"