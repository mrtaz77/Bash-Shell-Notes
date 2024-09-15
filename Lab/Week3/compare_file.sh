#!/bin/bash

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 -f file1 file2"
    exit 1
fi

if [ "$1" != "-f" ]; then
    echo "Invalid option: $1"
    echo "Usage: $0 -f file1 file2"
    exit 1
fi

file1="$2"
file2="$3"

if [ ! -f "$file1" ]; then
    echo "First File not found: $file1"
    exit 1
elif [ ! -f "$file2" ]; then
    echo "Second File not found: $file2"
    exit 1
fi

mapfile -t file1_lines < "$file1"

echo "Displaying contents of $file1 with hidden characters:"
for line in "${file1_lines[@]}"; do
    echo "$line" | cat -v
done

mapfile -t file2_lines < "$file2"

echo "Displaying contents of $file2 with hidden characters:"
for line in "${file2_lines[@]}"; do
    echo "$line" | cat -v
done

echo "Lines in $file1 that are missing in $file2:"
for line in "${file1_lines[@]}"; do
    if ! grep -Fxq "$line" "$file2"; then
        echo "$line"
    fi
done