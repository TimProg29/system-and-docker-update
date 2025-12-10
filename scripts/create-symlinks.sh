#!/bin/bash

# Create symlinks for short commands
echo "Creating symlinks for short commands..."

if ln -sf /usr/local/sbin/system-and-docker-update.sh /usr/local/bin/update-system; then
    echo "✓ Created: update-system"
else
    echo "✗ Failed to create: update-system"
fi

if ln -sf /usr/local/sbin/auto-update-toggle.sh /usr/local/bin/update-toggle; then
    echo "✓ Created: update-toggle"
else
    echo "✗ Failed to create: update-toggle"
fi

# Create log viewing scripts
cat > /usr/local/bin/update-log << 'EOF'
#!/bin/bash
LOGFILE="/var/log/system-and-docker-update.log"
if [ -f "$LOGFILE" ]; then
    cat "$LOGFILE"
else
    echo "No log file found. Run 'update-system' first to generate logs."
fi
EOF
chmod +x /usr/local/bin/update-log
echo "✓ Created: update-log"

cat > /usr/local/bin/update-log-live << 'EOF'
#!/bin/bash
LOGFILE="/var/log/system-and-docker-update.log"
if [ -f "$LOGFILE" ]; then
    tail -f "$LOGFILE"
else
    echo "No log file found. Run 'update-system' first to generate logs."
    echo "Waiting for log file to be created..."
    while [ ! -f "$LOGFILE" ]; do sleep 1; done
    tail -f "$LOGFILE"
fi
EOF
chmod +x /usr/local/bin/update-log-live
echo "✓ Created: update-log-live"

echo ""
echo "Short commands available:"
echo "  - update-system    (runs system and docker updates)"
echo "  - update-toggle    (manage automatic updates)"
echo "  - update-log       (view full log)"
echo "  - update-log-live  (view real-time log)"
