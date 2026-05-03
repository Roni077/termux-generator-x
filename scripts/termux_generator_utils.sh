portable_sed_i() {
    if sed v </dev/null 2> /dev/null; then
        sed -i "$@"
    else
        sed -i '' "$@"
    fi
}

apply_patches() {
    local srcdir=$(realpath "$1")
    local targetdir=$(realpath "$2")

    if [ ! -d "$srcdir" ]; then
        echo "[*] No patches directory found at $srcdir. Skipping."
        return
    fi

    pushd "$targetdir" > /dev/null

    # Find and sort patch files
    local patches=$(find "$srcdir" -maxdepth 1 -name "*.patch" | sort)

    if [ -z "$patches" ]; then
        echo "[*] No .patch files found in $srcdir. Skipping."
    else
        for patch in $patches; do
            # Peek at the patch to see which file it targets
            # We look for the first line starting with --- a/ and extract the path
            local target_in_patch=$(grep -m 1 "^--- a/" "$patch" | sed 's|^--- a/||')
            
            if [ -n "$target_in_patch" ]; then
                # If the target file doesn't exist, this might be a patch for a disabled app
                if [ ! -e "$target_in_patch" ]; then
                    # Check if the parent directory exists
                    local parent_dir=$(dirname "$target_in_patch")
                    if [ "$parent_dir" != "." ] && [ ! -d "$parent_dir" ]; then
                        echo "[*] Skipping patch $(basename "$patch") because target directory $parent_dir is missing."
                        continue
                    fi
                fi
            fi

            echo "[*] Applying patch: $(basename "$patch")"
            # Using -N/--forward to ignore already applied or reversed patches
            if ! patch -N -p1 < "$patch"; then
                echo "[!] Failed to apply patch: $(basename "$patch")"
                exit 1
            fi
        done
    fi

    popd > /dev/null
}

replace_termux_name() {
    if [[ "$TERMUX_APP__PACKAGE_NAME" == "com.termux" ]]; then
        return
    fi
    local targetdir="$1"
    local replacement_name="$2"
    local replacement_name_underscore="$(echo "$replacement_name" | tr . _)"
    local replacement_name_slash="$(echo "$replacement_name" | tr . /)"

    if [ ! -d "$targetdir" ]; then
        echo "[*] Target directory $targetdir not found. Skipping name replacement."
        return
    fi

    pushd "$targetdir" > /dev/null
    
    echo "[*] Replacing 'com.termux' with '$replacement_name' in $targetdir..."
    
    # Process only text files to avoid errors with binaries
    # Using a more robust way to find text files and avoiding permission denied errors
    # We use a subshell to avoid exit-on-error if find finds nothing or has minor issues
    find . -type f -not -path '*/.*' 2>/dev/null | while read -r file; do
        # Only process if file exists (safety)
        [ -f "$file" ] || continue
        
        if file "$file" 2>/dev/null | grep -q "text"; then
            portable_sed_i -e "s|>Termux<|>$replacement_name<|g" \
                           -e "s|\"Termux\"|\"$replacement_name\"|g" \
                           -e "s|Termux:|$replacement_name:|g" \
                           -e "s|com\.termux|$replacement_name|g" \
                           -e "s|com_termux|$replacement_name_underscore|g" \
                           -e '/https\?:\/\//!s|com/termux|'$replacement_name_slash'|g' "$file"
        fi
    done

    popd > /dev/null
}

# Funktion, um Ordner zu migrieren
migrate_termux_folder() {
    if [[ "$TERMUX_APP__PACKAGE_NAME" == "com.termux" ]]; then
        return
    fi
    local parentdir="$(dirname "$(dirname "$1")")"
    local replacement_name="$2"
    local destination="${parentdir}/$(echo "$replacement_name" | tr . /)/"

    echo "Migrating folder:"
    echo "- ${parentdir}/com/termux/"
    echo "to"
    echo "+ ${destination}"
    mkdir -p "${destination}"
    mv "${parentdir}/com/termux/"* "${destination}"
    rm -r "${parentdir}/com/termux/"
}

migrate_termux_folder_tree() {
    if [[ "$TERMUX_APP__PACKAGE_NAME" == "com.termux" ]]; then
        return
    fi
    local targetdir="$1"
    local replacement_name="$2"

    pushd "$targetdir"

    # Vollständig macOS-kompatible Variante für Verzeichnismigration
    local dir
    find "$(pwd)" -type d -name termux | grep -v -e 'shared/termux' -e 'settings/termux' | while read -r dir; do
        migrate_termux_folder "$dir" "$replacement_name"
    done

    popd
}
