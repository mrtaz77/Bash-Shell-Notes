#!/bin/bash

strlen() {
    local str="$1"
    echo "${#str}"
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

char_at() {
    local str="$1"
    local index="$2"
    
    if [ "$index" -lt 0 ] || [ "$index" -ge "${#str}" ]; then
        echo ""
    else
        echo "${str:$index:1}"
    fi
}

get_file_extension() {
    local file_path="$1"
    echo "${file_path##*.}"
}

get_basename() {
    local file_path="$1"
    echo "$(basename "$file_path")"
}

get_basename_no_ext() {
    local file_path="$1"
    local basename=$(basename "$file_path")
    echo "${basename%.*}"
}

get_list_from_cmd() {
    local cmd_output="$1"
    local -n array_ref="$2"
    IFS=$'\n' read -rd '' -a array_ref <<< "$cmd_output"
}

get_list_of_lines_from_file() {
    local file_path="$1"
    local -n list_of_lines="$2" 
    list_of_lines=()            
    while IFS= read -r line || [ -n "$line" ]; do
        list_of_lines+=("$line")
    done < "$file_path"
}

get_line_count() {
    local file_path="$1"
    if [ -f "$file_path" ]; then
        wc -l < "$file_path"
    else
        echo "File not found: $file_path"
        return 1
    fi
}

get_file_size() {
    local file_path="$1"
    if [ -f "$file_path" ]; then
        stat --format="%s" "$file_path"
    else
        echo "File not found: $file_path"
        return 1
    fi
}

get_words_from_line() {
    local line="$1"
	local -n word_arr="$2" 
    IFS=' ' read -ra word_arr <<< "$line"
}

args=3

if [ "$#" -ne "$args" ]; then
	echo "Invalid number of arguments"
	exit 1
fi

t1="temp1.txt"
t2="temp2.txt"
t3="temp3.txt"
:> "$t1"
:> "$t2"
:> "$t3"

# code here

logfile="./$1"
type="$2"
range="$3"

low=$(echo "$range" | cut -d'-' -f1)
high=$(echo "$range" | cut -d'-' -f2)

cat "$logfile" | grep "$type"> "$t1"

declare file_line_list

get_list_of_lines_from_file "$t1" file_line_list

for line in "${file_line_list[@]}"; do
    times=$(echo "$line" | cut -d' ' -f2)
    hour=$(echo "$times" | cut -d':' -f1)
    # echo "$hour" "$times"
    if [ "$hour" -ge "$low" ] && [ "$hour" -le "$high" ]; then
        user=$(echo "$line"| cut -d' ' -f3)
        echo "$user" >> "$t2"
    fi
done

user=""
count=0
sort -nr "$t2" | uniq -c | while read -r line;
do
    echo "$line" >> "$t3"
done

sort -nr "$t3" | while read -r line;
do
    echo "$line"
done

rm "$t1" "$t2" "$t3"

# Character at index 2 of 'hello': l
# echo "Character at index 2 of 'hello': $(char_at "hello" 2)"

# Declare an array to hold the results
# declare -a file_list
# Call the function to convert the command output into an array
# get_list_from_cmd "$ls_files" file_list

# Declare an array to store lines
# declare -a lines
# Call the function to populate the array
# get_list_of_lines_from_file "$file_path" lines

# declare -a words
# get_words_from_line "$line" words

# multi number output
# echo "Enter n numbers (space-separated):"
# read -a numbers  # -a flag reads input into an array
# echo "You entered: ${numbers[@]}"