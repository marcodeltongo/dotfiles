# Function to see the datetime in different timezones
# Usage: when [date] time [timezone]
function when() {
    local args=()
    local timezone

    # Add -when flag if any arguments are provided
    [[ $# -gt 0 ]] && args+=(-when)

    case $# in
        0) ;;  # No arguments, just use tz -m -q
        1) args+=($(date -j -f "%H:%M:%S" "$1:00" +"%s")) ;; # One argument (time)
        2)
            if [[ $1 =~ ^[0-9]{1,2}:[0-9]{2}$ ]]; then
                args+=($(TZ="$2" date -j -f "%H:%M:%S" "$1:00" +"%s")) # Two arguments (time and timezone)
            else
                args+=($(date -j -f "%Y%m%d %H:%M:%S" "$1 $2:00" +"%s")) # Two arguments (date and time)
            fi
            ;;
        *)
            args+=($(TZ="$3" date -j -f "%Y%m%d %H:%M:%S" "$1 $2:00" +"%s")) # Three arguments (date, time, and timezone)
            ;;
    esac

    TZ_LIST="Europe/London,Audiencerate Ltd" tz -m -q "${args[@]}"
}
