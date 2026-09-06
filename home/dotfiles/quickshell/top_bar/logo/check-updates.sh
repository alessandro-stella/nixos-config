#!/usr/bin/env bash

THREAD_COUNT=4
FLAKE_DIR="$HOME/nixos-config"
FLAKE_CONFIG="$NIXOS_DEVICE_TYPE"
IGNORED_PACKAGES=("gum")

if [ -z "$FLAKE_CONFIG" ]; then
    echo "ERROR|NIXOS_DEVICE_TYPE environment variable is not set!" >&2
    exit 1
fi

USER_NAME=$USER 

trap "pkill -P $$; exit 0" SIGTERM SIGINT SIGHUP

SYS_PACKAGES=$(
    nix eval --json --impure "$FLAKE_DIR#nixosConfigurations.$FLAKE_CONFIG.config.environment.systemPackages" \
        --apply 'pkgs: map (p: { name = p.pname or p.name or "unknown"; version = p.version or "unknown"; }) pkgs' 2>/dev/null || echo "[]"
)

HM_PACKAGES=$(
    nix eval --json --impure "$FLAKE_DIR#nixosConfigurations.$FLAKE_CONFIG.config.home-manager.users.$USER_NAME.home.packages" \
        --apply 'pkgs: map (p: { name = p.pname or p.name or "unknown"; version = p.version or "unknown"; }) pkgs' 2>/dev/null || echo "[]"
)

LIST=$(jq -r -s 'add | unique_by(.name) | .[] | select(.name != "unknown") | "\(.name)|\(.version)"' <(echo "$SYS_PACKAGES") <(echo "$HM_PACKAGES"))
TOTAL=$(echo "$LIST" | grep -c '[^[:space:]]')

echo "TOTAL|$TOTAL"

export IGNORED_PACKAGES_STR="${IGNORED_PACKAGES[*]}"

echo "$LIST" | xargs -P $THREAD_COUNT -I {} bash -c '
    trap "exit 0" SIGTERM SIGINT
    IFS="|" read -r NAME CURRENT <<< "{}"

    for pkg in $IGNORED_PACKAGES_STR; do
        if [ "$NAME" = "$pkg" ]; then
            exit 0
        fi
    done

    REMOTE=$(nix eval --raw "github:nixos/nixpkgs/nixos-unstable#legacyPackages.x86_64-linux.$NAME.version" 2>/dev/null)
    
    if [ -n "$REMOTE" ] && [ "$CURRENT" != "$REMOTE" ]; then
        highest=$(printf "%s\n" "$CURRENT" "$REMOTE" | sort -V | tail -n1)
        if [ "$highest" = "$REMOTE" ]; then
            echo "UPDATE|$NAME|$CURRENT|$REMOTE"
        else
            echo "OK|$NAME"
        fi
    else
        echo "OK|$NAME"
    fi
' | awk -F'|' -v total="$TOTAL" '
    BEGIN { checked = 0; outdated = 0; updates = "[" }
    {
        checked++
        print "PROGRESS|" checked "|" total
        fflush()
        
        if ($1 == "UPDATE") {
            if (outdated > 0) updates = updates ","
            updates = updates "{\"name\":\"" $2 "\",\"oldVersion\":\"" $3 "\",\"newVersion\":\"" $4 "\"}"
            outdated++
        }
    }
    END {
        updates = updates "]"
        print "DONE|" outdated
        print "RESULT|" updates
    }
'
