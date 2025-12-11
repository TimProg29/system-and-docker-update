#!/bin/bash

CUSTOM_COMMANDS_FILE="/etc/lxc-auto-update-commands.conf"

# Create file if not exists
if [ ! -f "$CUSTOM_COMMANDS_FILE" ]; then
    touch "$CUSTOM_COMMANDS_FILE"
fi

show_help() {
    echo "Usage: update-custom {add|remove|list|run}"
    echo ""
    echo "Commands:"
    echo "  add \"<command>\" \"<description>\"  - Add a custom update command"
    echo "  remove <number>                    - Remove command by line number"
    echo "  list                               - List all custom commands"
    echo "  run                                - Run all custom commands"
    echo ""
    echo "Examples:"
    echo "  update-custom add \"pihole -up\" \"Update Pi-hole\""
    echo "  update-custom add \"ampinstmgr upgradeall\" \"Update AMP instances\""
    echo "  update-custom add \"snap refresh\" \"Update Snap packages\""
    echo "  update-custom remove 2"
    echo "  update-custom list"
}

add_command() {
    local cmd="$1"
    local desc="$2"
    
    if [ -z "$cmd" ]; then
        echo "ERROR: Command cannot be empty."
        echo "Usage: update-custom add \"<command>\" \"<description>\""
        exit 1
    fi
    
    if [ -z "$desc" ]; then
        desc="Custom command"
    fi
    
    # Check if command already exists
    if grep -qF "CMD:$cmd" "$CUSTOM_COMMANDS_FILE" 2>/dev/null; then
        echo "ERROR: Command already exists."
        exit 1
    fi
    
    echo "DESC:$desc|CMD:$cmd" >> "$CUSTOM_COMMANDS_FILE"
    echo "✓ Added: $desc"
    echo "  Command: $cmd"
}

remove_command() {
    local line_num="$1"
    
    if [ -z "$line_num" ]; then
        echo "ERROR: Please specify line number to remove."
        echo "Use 'update-custom list' to see line numbers."
        exit 1
    fi
    
    if ! [[ "$line_num" =~ ^[0-9]+$ ]]; then
        echo "ERROR: Invalid line number."
        exit 1
    fi
    
    local total_lines=$(wc -l < "$CUSTOM_COMMANDS_FILE")
    if [ "$line_num" -gt "$total_lines" ] || [ "$line_num" -lt 1 ]; then
        echo "ERROR: Line number out of range (1-$total_lines)."
        exit 1
    fi
    
    local removed=$(sed -n "${line_num}p" "$CUSTOM_COMMANDS_FILE")
    sed -i "${line_num}d" "$CUSTOM_COMMANDS_FILE"
    
    local desc=$(echo "$removed" | sed 's/DESC:\(.*\)|CMD:.*/\1/')
    echo "✓ Removed: $desc"
}

list_commands() {
    if [ ! -s "$CUSTOM_COMMANDS_FILE" ]; then
        echo "No custom commands configured."
        echo "Add commands with: update-custom add \"<command>\" \"<description>\""
        return
    fi
    
    echo "=== Custom Update Commands ==="
    local i=1
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            local desc=$(echo "$line" | sed 's/DESC:\(.*\)|CMD:.*/\1/')
            local cmd=$(echo "$line" | sed 's/.*|CMD://')
            echo "  $i. $desc"
            echo "     Command: $cmd"
            ((i++))
        fi
    done < "$CUSTOM_COMMANDS_FILE"
    echo "==============================="
}

run_commands() {
    if [ ! -s "$CUSTOM_COMMANDS_FILE" ]; then
        echo "No custom commands to run."
        return 0
    fi
    
    echo "=== Running Custom Update Commands ==="
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            local desc=$(echo "$line" | sed 's/DESC:\(.*\)|CMD:.*/\1/')
            local cmd=$(echo "$line" | sed 's/.*|CMD://')
            echo ""
            echo "$(date): Running: $desc"
            echo "$(date): Command: $cmd"
            if eval "$cmd" 2>&1; then
                echo "$(date): ✓ $desc completed successfully"
            else
                echo "$(date): ✗ $desc failed (exit code: $?)"
            fi
        fi
    done < "$CUSTOM_COMMANDS_FILE"
    echo ""
    echo "=== End Custom Commands ==="
}

case "$1" in
    add)
        add_command "$2" "$3"
        ;;
    remove)
        remove_command "$2"
        ;;
    list)
        list_commands
        ;;
    run)
        run_commands
        ;;
    *)
        show_help
        exit 1
        ;;
esac
