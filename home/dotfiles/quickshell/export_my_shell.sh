#!/usr/bin/env bash
output="my_shell_code.txt"
echo "=== MY QUICKSHELL SETUP ===" > "$output"

# File principali
for f in shell.qml Theme.qml Accents.qml StateManager.qml GenericPopup.qml; do
    if [[ -f "$f" ]]; then
        echo -e "\n\n--- $f ---" >> "$output"
        cat "$f" >> "$output"
    fi
done

# Widget Audio e Network
find top_bar/audio top_bar/network -type f -name "*.qml" | while read -r f; do
    echo -e "\n\n--- $f ---" >> "$output"
    cat "$f" >> "$output"
done

echo "Tutto salvato in: $output"
