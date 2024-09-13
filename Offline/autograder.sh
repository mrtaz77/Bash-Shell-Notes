#!/bin/bash

remove_spaces() {
    local input_string="$1"
    local result=$(echo "$input_string" | tr -d '[:space:]')
    echo "$result"
}

check_positive_number() {
    local number="$1"

    if ! [[ "$number" =~ ^[0-9][0-9]*$ ]]; then
        echo "Error: Total Marks '$number' is not a valid positive whole number."
        return 1
    fi

    return 0
}


# Check for correct number of arguments
if [ "$#" -ne 2 ]; then
	echo "Usage: $0 -i <config-file-name>"
	exit 1
fi

# Check for correct first argument
if [ "$1" != "-i" ]; then
    echo "Invalid option: $1"
    echo "Usage: $0 -i filename"
    exit 1
fi

file="$2"

# Check for file
if [ ! -f "$file" ]; then
	echo "File not found: $file"
	exit 1
fi

IFS=$'\n' read -d '' -r -a lines < $file

use_archive=$(remove_spaces "${lines[0]}")

if [[ "$use_archive" != "true" && "$use_archive" != "false" ]]; then
	echo "Invalid Use Archive setting: $use_archive"
	echo "Usage: 'true' or 'false'"
	exit 1
fi

valid_archived_formats=("zip" "rar" "tar")

allowed_archived_formats="${lines[1]}"

IFS=' ' read -r -a archive_formats <<< "$allowed_archived_formats"

for i in "${!archive_formats[@]}"; do
    archive_formats[$i]=$(remove_spaces "${archive_formats[$i]}")
done

for format in "${archive_formats[@]}"; do
    if [[ ! " ${valid_archived_formats[*]} " =~ " ${format} " ]]; then
        echo "Invalid Archive Format: $format"
        echo "Usage: Valid formats are zip, rar, tar"
        exit 1
    fi
done

valid_programming_languages=("c" "cpp" "python" "sh")

allowed_programming_languages="${lines[2]}"

IFS=' ' read -r -a programming_languages <<< "$allowed_programming_languages"

for i in "${!programming_languages[@]}"; do
    programming_languages[$i]=$(remove_spaces "${programming_languages[$i]}")
done

for language in "${programming_languages[@]}"; do
    if [[ ! " ${valid_programming_languages[*]} " =~ " ${language} " ]]; then
        echo "Invalid Programming Language: $language"
        echo "Usage: Valid programming languages are c, cpp, python, sh"
        exit 1
    fi
done

full_score=$(remove_spaces "${lines[3]}")

if ! check_positive_number "$full_score"; then
    exit 1
fi

unmatched_penalty=$(remove_spaces "${lines[4]}")

if ! check_positive_number "$unmatched_penalty"; then
    exit 1
fi

working_dir=$(remove_spaces "${lines[5]}")

if ! find ".$working_dir" -maxdepth 0 -type d > /dev/null 2>&1; then
    echo "Error: Directory '.$working_dir' does not exist."
    exit 1
fi

