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

if [ "$#" -ne 2 ]; then
	echo "Usage: $0 -i <config-file-name>"
	exit 1
fi

if [ "$1" != "-i" ]; then
    echo "Invalid option: $1"
    echo "Usage: $0 -i filename"
    exit 1
fi

file="$2"

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

total_marks=$(remove_spaces "${lines[3]}")

if ! check_positive_number "$total_marks" "Total Marks" ; then
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

if ! find ".$plagiarism_analysis_file" -maxdepth 0 -type f > /dev/null 2>&1; then
    echo "Error: File '$plagiarism_analysis_file' does not exist."
    exit 1
fi

plagiarism_penalty_percentage=$(remove_spaces "${lines[10]}")

if ! check_positive_number "$plagiarism_penalty_percentage" "Plagiarism Penalty Percentage" ; then
    exit 1
fi

plagiarism_penalty=$((total_marks * plagiarism_penalty_percentage / 100))

make_marks_csv() {
	column_names="id,marks,marks_deducted,total_marks,remarks"
	echo "$column_names" > marks.csv
}

make_marks_csv
submission_rules_violations=0
remarks=""

add_to_submission_rules_violations () {
	submission_rules_violations=$((submission_rules_violations + violation_penalty))
}

clear_submission_rules_violations() {
	submission_rules_violations=0
}

add_to_remarks() {
    local input="$1"
    
    if [ -z "$remarks" ]; then
        remarks="$input"
    else
        remarks="$remarks $input"
    fi
}

clear_remarks() {
    remarks=""
}

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

marks_deducted_for_plagiarism() {
    local sid="$1"

    if grep -qw "$sid" ".$plagiarism_analysis_file"; then
        echo "$plagiarism_penalty"
    else
        echo 0
    fi
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
                run_submission_file "$extracted_dir/$(basename "$submission_file")" "$sid" "$file_extension"
				deductions=$(compare_output ".$working_dir/$sid/${sid}_output.txt")
				final_marks=$((total_marks - deductions))
				deduction_for_plagiarism=$(marks_deducted_for_plagiarism "$sid")
				total_deductions=$((deductions + deduction_for_plagiarism))
				echo -n "$final_marks,$total_deductions,$total_marks," >> marks.csv
				if [[ $deductions -ne 0 ]]; then
					add_to_remarks "'unmatched/non-existent output'"
				fi
				if [[ $deduction_for_plagiarism -ne 0 ]]; then
					add_to_remarks "'plagiarism detected'"
				fi
			else
                handle_not_allowed_programming_language
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
    local output_file="$sid_dir/${sid}_output.txt"
    
    gcc "$submission_file" -o "$sid_dir/$sid.out"
    if [ $? -eq 0 ]; then
        "$sid_dir/$sid.out" > "$output_file"
		rm "$sid_dir/$sid.out"
    else
        echo "Compilation error for C file $submission_file" > "$output_file"
    fi
}

compile_and_run_cpp() {
    local submission_file="$1"
    local sid_dir="$2"
    local sid="$3"
    local output_file="$sid_dir/${sid}_output.txt"
    
    g++ "$submission_file" -o "$sid_dir/$sid.out"
    if [ $? -eq 0 ]; then
        "$sid_dir/$sid.out" > "$output_file"
		rm "$sid_dir/$sid.out"
    else
        echo "Compilation error for C++ file $submission_file" > "$output_file"
    fi
}

run_python_file() {
    local submission_file="$1"
    local sid_dir="$2"
    local sid="$3"
    local output_file="$sid_dir/${sid}_output.txt"
    
    python3 "$submission_file" > "$output_file" 2>&1
}

run_shell_file() {
    local submission_file="$1"
    local sid_dir="$2"
    local sid="$3"
    local output_file="$sid_dir/${sid}_output.txt"
    
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
            echo "Unsupported programming language: $file_extension" > "$sid_dir/${sid}_output.txt"
            return 1
            ;;
    esac
    return 0
}

compare_output() {
    local generated_output_file="$1"
    local total_deductions=0

    if [ ! -f "$generated_output_file" ]; then
        echo "Generated output file '$generated_output_file' not found. Deducting full marks."
        echo "$total_marks"
        return 0
    fi

    process_file() {
        local file="$1"
        local result=""

        while IFS= read -r line; do
            result+="${line//[$'\r']/}"
            result+=$'\n'
        done < "$file"

        echo "$result"
    }

    local processed_expected
    local processed_generated

    processed_expected=$(process_file ".$expected_output_file")
    processed_generated=$(process_file "$generated_output_file")

    local diff_output
    diff_output=$(diff <(echo "$processed_expected") <(echo "$processed_generated"))

    local missing_lines
    missing_lines=$(echo "$diff_output" | grep '^<' | wc -l)

    total_deductions=$((missing_lines * unmatched_non_existent_penalty))

    echo "$total_deductions"
    return 0
}

add_new_line_to_marks_csv() {
	echo "" >> marks.csv
}

handle_missing_submission() {
	echo -n "0,0,$total_marks,'missing submission'" >> marks.csv
	add_new_line_to_marks_csv
}

handle_not_allowed_archive_format() {
	add_to_submission_rules_violations
	add_to_remarks "'issue case #2'"
	echo -n "-$submission_rules_violations,$submission_rules_violations,$total_marks,$remarks" >> marks.csv
	clear_remarks
	clear_submission_rules_violations
	add_new_line_to_marks_csv
}

handle_not_allowed_programming_language() {
	add_to_submission_rules_violations
	add_to_remarks "'issue case #3'"
	echo -n "-$submission_rules_violations,$submission_rules_violations,$total_marks" >> marks.csv
	clear_submission_rules_violations
}

is_valid_sid() {
    local basename="$1"
    local basename_no_ext="${basename%.*}"
    local expected_output_basename_no_ext="$(basename "${expected_output_file%.*}")"
    local plagiarism_analysis_basename_no_ext="$(basename "${plagiarism_analysis_file%.*}")"
    if [[ "$basename_no_ext" == "$expected_output_basename_no_ext" || "$basename_no_ext" == "$plagiarism_analysis_basename_no_ext" ]]; then
        return 0
    fi
    if [[ "$basename_no_ext" =~ ^[0-9]+$ ]] && (( basename_no_ext >= sid_low && basename_no_ext <= sid_high )); then
        return 0
    else
        return 1
    fi
}

handle_invalid_entries() {
    for entry in ".$working_dir"/*; do
        if [ -e "$entry" ]; then
            local basename=$(basename "$entry")
            local basename_no_ext="${basename%.*}"
            if ! is_valid_sid "$basename"; then
                echo "$basename_no_ext,-$violation_penalty,$violation_penalty,$total_marks,'issue case #5'" >> marks.csv
            fi
        fi
    done
}

handle_invalid_entries

for (( sid = sid_low; sid <= sid_high; sid++ )); do
	echo -n "$sid," >> marks.csv

	if [ -d ".$working_dir/$sid" ]; then
		add_to_submission_rules_violations
		add_to_remarks "'issue case #1'"
		handle_extracted_files "$sid" "$working_dir"
	elif [[ "$use_archive" == "true" ]]; then
		archive_file=$(find ".$working_dir" -maxdepth 1 -name "$sid.*" -print -quit)
		if [ -z "$archive_file" ]; then
            handle_missing_submission
            continue
        fi

        file_extension=$(get_file_extension "$archive_file")

        if ! check_archive_format "$file_extension"; then
            handle_not_allowed_archive_format
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
			handle_missing_submission "$sid"
			continue
		fi

		mv "$submission_file" "$sid_dir/"

		file_extension=$(get_file_extension "$submission_file")

		check_programming_language "$file_extension"
		if [ $? -eq 1 ]; then
			run_submission_file "$sid_dir/$(basename "$submission_file")" "$sid" "$file_extension"
			deductions=$(compare_output ".$working_dir/$sid/${sid}_output.txt")
			final_marks=$((total_marks - deductions))
			deduction_for_plagiarism=$(marks_deducted_for_plagiarism "$sid")
			total_deductions=$((deductions + deduction_for_plagiarism))
			echo -n "$final_marks,$total_deductions,$total_marks," >> marks.csv
			if [[ $deductions -ne 0 ]]; then
				add_to_remarks "'unmatched/non-existent output'"
			fi
			if [[ $deduction_for_plagiarism -ne 0 ]]; then
				add_to_remarks "'plagiarism detected'"
			fi
		else
			handle_not_allowed_programming_language
		fi
	fi
	echo -n "$remarks" >> marks.csv
	clear_remarks
	add_new_line_to_marks_csv
done