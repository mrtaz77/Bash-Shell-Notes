#!/bin/bash

remove_spaces() {
    local input_string="$1"
    local result=$(echo "$input_string" | tr -d '[:space:]')
    echo "$result"
}

check_positive_number() {
    local number="$1"
	local type="$2"
    if ! [[ "$number" =~ ^[0-9][0-9]*$ ]]; then
        echo "Error: '$type' is not a valid positive whole number."
        return 1
    fi
    return 0
}

get_file_extension() {
	local filename="$1"
	file_extension=$(echo "$filename" | rev | cut -d. -f1 | rev)
	echo "$file_extension"
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
allowed_valid_archived_formats=()

if [[ "$use_archive" == "true" ]]; then
    allowed_archived_formats="${lines[1]}"

    IFS=' ' read -ra archive_formats <<< "$allowed_archived_formats"

    for format in "${archive_formats[@]}"; do
        format=$(remove_spaces "$format")
        
        if [[ " ${valid_archived_formats[*]} " =~ " ${format} " ]]; then
            allowed_valid_archived_formats+=("$format")
        else
            echo "Invalid Archive Format: $format"
            echo "Usage: Valid formats are zip, rar, tar"
            exit 1
        fi
    done
fi

valid_programming_languages=("c" "cpp" "python" "sh")

allowed_programming_languages="${lines[2]}"

allowed_valid_programming_languages=()

IFS=' ' read -ra programming_languages <<< "$allowed_programming_languages"

for language in "${programming_languages[@]}"; do
	language=$(remove_spaces "$language")
    if [[ " ${valid_programming_languages[*]} " =~ " ${language} " ]]; then
		allowed_valid_programming_languages+=("$language")
	else
		echo "Invalid Programming Language: $language"
		echo "Usage: Valid formats are c, cpp, python and sh"
		exit 1
    fi
done

full_score=$(remove_spaces "${lines[3]}")

if ! check_positive_number "$full_score" "Full Score" ; then
    exit 1
fi

unmatched_non_existent_penalty=$(remove_spaces "${lines[4]}")

if ! check_positive_number "$unmatched_non_existent_penalty" "Penalty for Unmatched/Non-existent Output" ; then
    exit 1
fi

working_dir=$(remove_spaces "${lines[5]}")

if ! find ".$working_dir" -maxdepth 0 -type d > /dev/null 2>&1; then
    echo "Error: Directory '$working_dir' does not exist."
    exit 1
fi

sid_range="${lines[6]}"

IFS=' ' read -r -a sid_s <<< "$sid_range"

sid_low=$(remove_spaces "${sid_s[0]}")
sid_high=$(remove_spaces "${sid_s[1]}")

if ! check_positive_number "$sid_low" "First Student ID" ; then
	exit 1
elif ! check_positive_number "$sid_high" "Last Student ID" ; then
	exit 1
elif [[ "$sid_low" -gt "$sid_high" ]]; then
	echo "Invalid Student ID range; first Student ID is greater than last Student ID"
fi

expected_output_file=$(remove_spaces "${lines[7]}")

if ! find ".$expected_output_file" -maxdepth 0 -type f > /dev/null 2>&1; then
    echo "Error: File '$expected_output_file' does not exist."
    exit 1
fi

violation_penalty=$(remove_spaces "${lines[8]}")

if ! check_positive_number "$violation_penalty" "Penalty for Submission Guidelines Violations" ; then
    exit 1
fi

plagiarism_analysis_file=$(remove_spaces "${lines[9]}")

plagiarism_penalty=$(remove_spaces "${lines[10]}")

if ! check_positive_number "$plagiarism_penalty" "Plagiarism Penalty" ; then
    exit 1
fi