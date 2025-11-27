#!/bin/bash

# ==============================================================================
# Script Name: flatten_files.sh
# Description: Recursively finds all files in a source directory and copies them
#              into a single destination directory.
#              - Handles filename collisions by appending a counter.
#              - Ignores hidden files (optional configuration).
# Usage:       ./flatten_files.sh <source_directory> <destination_directory>
# ==============================================================================

# Function to display usage information
usage() {
    echo "Usage: $0 <source_directory> <destination_directory>"
    echo "Example: $0 ./my_complex_folder ./all_files_here"
    exit 1
}

# Check if correct number of arguments is provided
if [ "$#" -ne 2 ]; then
    usage
fi

SOURCE_DIR="${1%/}" # Remove trailing slash if present
DEST_DIR="${2%/}"   # Remove trailing slash if present

# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Source directory '$SOURCE_DIR' does not exist."
    exit 1
fi

# Create destination directory if it doesn't exist
if [ ! -d "$DEST_DIR" ]; then
    echo "Creating destination directory: '$DEST_DIR'"
    mkdir -p "$DEST_DIR"
fi

echo "Starting copy process..."
echo "Source: $SOURCE_DIR"
echo "Destination: $DEST_DIR"

# Initialize counters
count_success=0
count_skipped=0

# Find all files in source directory and loop through them
# -type f: looks for files only (ignores directories)
# -print0: handles filenames with spaces or special characters safely
find "$SOURCE_DIR" -type f -print0 | while IFS= read -r -d '' file; do
    
    # Extract the base filename (e.g., "image.jpg")
    filename=$(basename "$file")
    
    # Define the target path
    target="$DEST_DIR/$filename"

    # Handle collisions: If file exists in destination, append a number
    if [ -e "$target" ]; then
        base="${filename%.*}"
        ext="${filename##*.}"
        
        # Handle case where file has no extension
        if [ "$base" == "$ext" ]; then
            ext=""
        else
            ext=".$ext"
        fi
        
        counter=1
        new_target="${DEST_DIR}/${base}_${counter}${ext}"
        
        while [ -e "$new_target" ]; do
            ((counter++))
            new_target="${DEST_DIR}/${base}_${counter}${ext}"
        done
        target="$new_target"
    fi

    # Perform the copy
    cp "$file" "$target"
    
    if [ $? -eq 0 ]; then
        # echo "Copied: $file -> $target" # Uncomment for verbose output
        ((count_success++))
    else
        echo "Failed to copy: $file"
        ((count_skipped++))
    fi

done

echo "------------------------------------------------"
echo "Operation complete."
# Note: Variables inside the pipe loop (count_success) won't persist outside 
# in standard bash without process substitution, checking files in dest is easier method for final count.
final_count=$(find "$DEST_DIR" -maxdepth 1 -type f | wc -l)
echo "Total files now in destination: $final_count"
