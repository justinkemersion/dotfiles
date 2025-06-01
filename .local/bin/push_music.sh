#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
# Treat unset variables as an error when substituting.
# Pipeline return status is the value of the last command to exit with a non-zero status,
# or zero if all commands in the pipeline exit successfully.
set -euo pipefail

# --- Configuration ---
# Use trailing slash for consistency in path manipulation later
LOCAL_MUSIC_DIR="${HOME}/media/music/"
REMOTE_MUSIC_DIR="/sdcard/Music/" # Ensure this EXACTLY matches the case on your device
TEMP_LOCAL_LIST="/tmp/local_music_list_$$.txt"  # Use PID for uniqueness
TEMP_REMOTE_LIST="/tmp/remote_music_list_$$.txt"
LOG_FILE="/tmp/adb_music_sync.log"

# Supported audio file extensions (adjust as needed)
# Using an array makes the find command cleaner
SUPPORTED_EXTENSIONS=("*.mp3" "*.flac" "*.ogg" "*.m4a")

# --- Helper Functions ---
cleanup() {
    log "Cleaning up temporary files..." # Log cleanup start
    rm -f "$TEMP_LOCAL_LIST" "$TEMP_REMOTE_LIST"
    log "Temporary files removed." # Log cleanup end
}
# Register the cleanup function to run on script exit (normal or error)
trap cleanup EXIT

log() {
    # Log to both console and file
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

escape_sed_pattern() {
    # Escape characters special to sed's regex dialect (basic)
    # Properly handles /, &, \ and newline. Add others if needed.
    sed -e 's/[&/\\]/\\&/g' <<< "$1"
}

# --- Pre-flight Checks ---

log "Starting music sync script."

# Check if ~/media is mounted (Adjust grep pattern for more specificity if needed)
# Check for the mount point *directory* rather than the device name for flexibility
MOUNT_TARGET="${HOME}/media"
if ! mount | grep -q " on ${MOUNT_TARGET} type "; then
    log "Error: ${MOUNT_TARGET} does not appear to be mounted."
    exit 1
fi
log "${MOUNT_TARGET} appears mounted."

# Ensure adb is available
if ! command -v adb &>/dev/null; then
    log "Error: adb command not found. Install android-tools (e.g., sudo pacman -S android-tools)."
    exit 1
fi
log "adb command found."

# Ensure device is connected and authorized
ADB_DEVICES_OUTPUT=$(adb devices)
if ! echo "$ADB_DEVICES_OUTPUT" | grep -qw 'device'; then
    if echo "$ADB_DEVICES_OUTPUT" | grep -qw 'unauthorized'; then
        log "Error: Device found but is unauthorized. Please check your device screen to authorize USB debugging."
    elif echo "$ADB_DEVICES_OUTPUT" | grep -qw 'offline'; then
        log "Error: Device found but is offline. Try reconnecting or restarting adb server (adb kill-server && adb start-server)."
    else
        log "Error: No device connected or detected. Ensure USB debugging is enabled and the device is connected."
    fi
    exit 1
fi
log "ADB device detected and authorized."

# Ensure local music directory exists
if [ ! -d "$LOCAL_MUSIC_DIR" ]; then
    log "Error: Local music directory '$LOCAL_MUSIC_DIR' not found."
    exit 1
fi
log "Local music directory found: $LOCAL_MUSIC_DIR"

# Ensure remote base directory exists (or try to create it)
if ! adb shell "ls -d \"$REMOTE_MUSIC_DIR\"" >/dev/null 2>&1; then
    log "Remote directory '$REMOTE_MUSIC_DIR' not found. Attempting to create..."
    # Use mkdir -p for safety, quote the path
    if ! adb shell "mkdir -p \"$REMOTE_MUSIC_DIR\""; then
        log "Error: Failed to create remote directory '$REMOTE_MUSIC_DIR'. Check permissions on device."
        exit 1
    fi
    log "Remote directory created."
else
    log "Remote music directory found: $REMOTE_MUSIC_DIR"
fi

# --- Generate File Lists ---

log "Generating local file list..."
# Build the find command arguments for extensions
find_args=()
for ext in "${SUPPORTED_EXTENSIONS[@]}"; do
    find_args+=(-o -name "$ext")
done
# Remove the initial "-o"
find_args=("${find_args[@]:1}")

# Find files, print relative paths, sort. Handle potential errors.
if ! find "$LOCAL_MUSIC_DIR" -type f \( "${find_args[@]}" \) -printf "%P\n" | sort > "$TEMP_LOCAL_LIST"; then
    log "Error: Failed to generate local file list from '$LOCAL_MUSIC_DIR'."
    exit 1
fi
local_count=$(wc -l < "$TEMP_LOCAL_LIST")
log "Found $local_count local files."


log "Generating remote file list..."
# Escape the remote directory path for use in sed
REMOTE_MUSIC_DIR_SED_ESCAPED=$(escape_sed_pattern "$REMOTE_MUSIC_DIR")
# Use # as sed delimiter to avoid conflicts with / in paths
# The `adb shell` command might fail if the directory is huge or perms are wrong
# Capture potential errors from adb shell find itself
ADB_SHELL_FIND_OUTPUT=$(adb shell "find \"$REMOTE_MUSIC_DIR\" -type f -print" 2>&1)
ADB_SHELL_FIND_EC=$?

if [ $ADB_SHELL_FIND_EC -ne 0 ]; then
    # Find itself failed
    log "Error: adb shell find command failed (exit code $ADB_SHELL_FIND_EC) in '$REMOTE_MUSIC_DIR'. Check permissions or directory contents on device."
    log "ADB Find Error Output: $ADB_SHELL_FIND_OUTPUT"
    # Create an empty remote list file to allow comparison to proceed (showing all local files as new)
    # Or exit, depending on desired behavior. Let's create empty list and warn.
    > "$TEMP_REMOTE_LIST"
    log "Warning: Proceeding with an empty remote file list due to find error."
elif ! echo "$ADB_SHELL_FIND_OUTPUT" | sed "s#^${REMOTE_MUSIC_DIR_SED_ESCAPED}##" | sort > "$TEMP_REMOTE_LIST"; then
    # Sed or Sort failed, unlikely but possible
    log "Error: Failed to process or sort remote file list from '$REMOTE_MUSIC_DIR'."
     > "$TEMP_REMOTE_LIST"
    log "Warning: Proceeding with an empty remote file list due to processing error."
fi

remote_count=$(wc -l < "$TEMP_REMOTE_LIST")
log "Found $remote_count remote files (relative paths)."


# --- Compare Lists and Transfer ---

log "Comparing local and remote lists..."
# Calculate number of new files first
num_new_files=$(comm -23 "$TEMP_LOCAL_LIST" "$TEMP_REMOTE_LIST" | wc -l)
log "Found $num_new_files new files to transfer."

if [ "$num_new_files" -eq 0 ]; then
    log "No new files found to transfer. Music library is up-to-date."
    exit 0 # Exit successfully
fi

echo "Transferring new files..." # User feedback for the start of the transfer block
current_file=0 # Initialize counter outside the loop
skipped_count=0 # Count skipped files

# Use Process Substitution < <(...) to feed the loop
while IFS= read -r file; do
    # Trim leading/trailing whitespace just in case
    file=$(echo "$file" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    if [ -z "$file" ]; then continue; fi # Skip empty lines potentially introduced

    current_file=$((current_file + 1))
    local_file="${LOCAL_MUSIC_DIR}${file}" # Assumes trailing slash on LOCAL_MUSIC_DIR
    remote_file="${REMOTE_MUSIC_DIR}${file}" # Assumes trailing slash on REMOTE_MUSIC_DIR
    remote_dir=$(dirname "$remote_file")

    log_prefix="[$current_file/$num_new_files]"

    # --- Add Pre-Check for Local File ---
    if [ ! -f "$local_file" ]; then
        log "Error: ${log_prefix} Local source file not found: '$local_file'. Skipping."
        skipped_count=$((skipped_count + 1))
        continue # Skip to the next file
    fi
    # --- End Pre-Check ---

    # Ensure parent directory exists on device (crucial!)
    # Quote the directory path for adb shell
    if ! adb shell "mkdir -p \"$remote_dir\""; then
        log "Error: ${log_prefix} Failed to create remote directory '$remote_dir' for file '$file'. Skipping."
        skipped_count=$((skipped_count + 1))
        continue # Skip to the next file
    fi

    # Push the file, check for errors
    # Use echo for user feedback before the potentially long adb push
    echo "${log_prefix} Pushing ${file}..."
    if adb push --sync "$local_file" "$remote_file"; then
        log "${log_prefix} Successfully pushed '$file'" # Log success after push
    else
        adb_exit_code=$?
        log "${log_prefix} Error: Failed to push '$file' (adb exit code $adb_exit_code). Check adb output or device storage. Skipping."
        skipped_count=$((skipped_count + 1))
        # Continue to the next file automatically due to loop structure
    fi

done < <(comm -23 "$TEMP_LOCAL_LIST" "$TEMP_REMOTE_LIST") # Use process substitution here

# Add a counter check for debugging/confirmation
log "Loop finished. Processed $current_file files according to loop counter."
if [ "$skipped_count" -gt 0 ]; then
    log "Warning: Skipped $skipped_count files due to errors (see log for details)."
fi
log "Transfer process complete."
exit 0