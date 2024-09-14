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

if ! find "$working_dir" -maxdepth 0 -type d > /dev/null 2>&1; then
    echo "Error: Directory '$working_dir' does not exist."
    exit 1
fi

echo "$working_dir"

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

check_programming_language() {
    local file_extension="$1"
    if [[ "$file_extension" == "py" ]]; then
        if [[ " ${allowed_valid_programming_languages[*]} " =~ " python " ]]; then
            return 1
        else
            return 0
        fi
    fi

    for language in "${allowed_valid_programming_languages[@]}"; do
        if [[ "$file_extension" == "$language" ]]; then
            return 1
        fi
    done
    
    return 0 
}

check_archive_format() {
    local file_extension="$1"
	for format in "${allowed_valid_archived_formats[@]}"; do
        if [[ "$file_extension" == "$format" ]]; then
            return 0
        fi
    done
    
    return 1
}

handle_extracted_files() {
	local sid="$1"
    local working_dir="$2"
    local extracted_dir=".$working_dir/$sid"

    if [ -d "$extracted_dir" ]; then
        local submission_file=$(find "$extracted_dir" -maxdepth 1 -name "$sid.*" -print -quit)
        if [ -n "$submission_file" ]; then
            file_extension=$(get_file_extension "$submission_file")
            check_programming_language "$file_extension"
            if [ $? -eq 1 ]; then
                echo "Valid submission for Student ID: $sid with language: $file_extension"
				run_submission_file "$extracted_dir/$(basename "$submission_file")" "$sid" "$file_extension"
			else
                echo "Invalid programming language for Student ID: $sid. Expected one of: ${allowed_valid_programming_languages[*]}."
            fi
        else
            echo "No valid submission file found in the extracted directory for Student ID: $sid."
        fi
    else
        echo "No directory created for Student ID: $sid after extraction."
    fi
}

compile_and_run_c() {
    local submission_file="$1"
    local sid_dir="$2"
    local sid="$3"
    local output_file="$sid_dir/${sid}__output.txt"
    
    gcc "$submission_file" -o "$sid_dir/$sid.out"
    if [ $? -eq 0 ]; then
        "$sid_dir/$sid.out" > "$output_file"
    else
        echo "Compilation error for C file $submission_file" > "$output_file"
    fi
}

compile_and_run_cpp() {
    local submission_file="$1"
    local sid_dir="$2"
    local sid="$3"
    local output_file="$sid_dir/${sid}__output.txt"
    
    g++ "$submission_file" -o "$sid_dir/$sid.out"
    if [ $? -eq 0 ]; then
        "$sid_dir/$sid.out" > "$output_file"
    else
        echo "Compilation error for C++ file $submission_file" > "$output_file"
    fi
}

run_python_file() {
    local submission_file="$1"
    local sid_dir="$2"
    local sid="$3"
    local output_file="$sid_dir/${sid}__output.txt"
    
    python3 "$submission_file" > "$output_file" 2>&1
}

run_shell_file() {
    local submission_file="$1"
    local sid_dir="$2"
    local sid="$3"
    local output_file="$sid_dir/${sid}__output.txt"
    
    bash "$submission_file" > "$output_file" 2>&1
}

run_submission_file() {
    local submission_file="$1"
    local sid="$2"
    local file_extension="$3"
    local sid_dir=".$working_dir/$sid"
    
    case "$file_extension" in
        "c")
            compile_and_run_c "$submission_file" "$sid_dir" "$sid"
            ;;
        "cpp")
            compile_and_run_cpp "$submission_file" "$sid_dir" "$sid"
            ;;
        "py")
            run_python_file "$submission_file" "$sid_dir" "$sid"
            ;;
        "sh")
            run_shell_file "$submission_file" "$sid_dir" "$sid"
            ;;
        *)
            echo "Unsupported programming language: $file_extension" > "$sid_dir/${sid}__output.txt"
            return 1
            ;;
    esac
    return 0
}


for (( sid = sid_low; sid <= sid_high; sid++ )); do
	if [[ "$use_archive" == "true" ]]; then
		archive_file=$(find ".$working_dir" -maxdepth 1 -name "$sid.*" -print -quit)
		if [ -z "$archive_file" ]; then
            echo "No archive file found for Student ID: $sid"
            continue
        fi

        file_extension=$(get_file_extension "$archive_file")

        if ! check_archive_format "$file_extension"; then
            echo "Invalid archive format for Student ID: $sid. Expected one of: ${allowed_valid_archived_formats[*]}."
            continue
        fi

        case "$file_extension" in
            zip)
                unzip "$archive_file" -d ".$working_dir" > /dev/null
                ;;
            rar)
                unrar x "$archive_file" ".$working_dir" > /dev/null
                ;;
            tar)
                tar -xvf "$archive_file" -C ".$working_dir" > /dev/null
                ;;
        esac

        handle_extracted_files "$sid" "$working_dir"
	else
		sid_dir=".$working_dir/$sid"
		if [ ! -d "$sid_dir" ]; then
			mkdir -p "$sid_dir"
		fi

		submission_file=$(find ".$working_dir" -maxdepth 1 -name "$sid.*" -print -quit)

		if [ -z "$submission_file" ]; then
			echo "No submission file found for Student ID: $sid"
			continue
		fi

		mv "$submission_file" "$sid_dir/" 2>/dev/null

		if [ $? -ne 0 ]; then
			echo "Error moving submission file for Student ID: $sid"
			continue
		fi

		file_extension=$(get_file_extension "$submission_file")

		check_programming_language "$file_extension"
		if [ $? -eq 1 ]; then
			echo "Valid submission for Student ID: $sid with language: $file_extension"
			run_submission_file "$sid_dir/$(basename "$submission_file")" "$sid" "$file_extension"
		else
			echo "Invalid programming language for Student ID: $sid. Expected one of: ${allowed_valid_programming_languages[*]}."
			continue
		fi
	fi
done