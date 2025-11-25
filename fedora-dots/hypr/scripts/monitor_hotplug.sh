#!/bin/bash

# Adjust this to your laptop's internal monitor name
INTERNAL_MONITOR="eDP-1"

check_monitors() {
    # Get list of connected monitors (names only) from 'hyprctl monitors all'
    # This lists all connected outputs, even if disabled in config
    EXTERNAL_COUNT=$(hyprctl monitors all | grep "Monitor" | grep -v "$INTERNAL_MONITOR" | wc -l)

    if [ "$EXTERNAL_COUNT" -gt 0 ]; then
        # External monitor connected, disable internal
        echo "External monitor detected. Disabling $INTERNAL_MONITOR."
        hyprctl keyword monitor "$INTERNAL_MONITOR, disable"
    else
        # No external monitor, enable internal
        echo "No external monitor. Enabling $INTERNAL_MONITOR."
        # Adjust resolution/scale if needed (preferred, auto, 1 is standard)
        hyprctl keyword monitor "$INTERNAL_MONITOR, preferred, auto, 1"
    fi
}

# Run check immediately on startup to set correct state
check_monitors

# Listen for monitor hotplug events
# We use nc (netcat) to listen to the socket since socat might not be installed
# The socket path depends on Hyprland instance signature
SOCKET_PATH="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

if [ ! -S "$SOCKET_PATH" ]; then
    echo "Error: Hyprland socket not found at $SOCKET_PATH"
    exit 1
fi

nc -U "$SOCKET_PATH" | while read -r line; do
    case "$line" in
        monitoradded*|monitorremoved*)
            # Give Hyprland a moment to update its state before checking
            sleep 1
            check_monitors
            ;;
    esac
done
