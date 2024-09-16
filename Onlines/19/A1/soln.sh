#!/bin/bash

if [ "$#" -ne 2 ]; then
	echo "Usage: $0 input_dir output_dir"
	exit 1
fi

input_dir="./$1"
output_dir="./$2"

if [ ! -d "$input_dir" ]; then 
	echo "Input dir not found: $input_dir"
	exit 1 
fi

if [ -d "$output_dir" ]; then
	rm -rf "$output_dir"/*
else
	mkdir -p "$output_dir"
fi

input_dir_files=$(find "$input_dir"/* -type f  | xargs wc -l | sort -n | head -n -1 | sed "s| ".*$input_dir"/||")

IFS=$'\n' read -r -d '' -a input_dir_file_list <<< "$input_dir_files"

count=0
for file in "${input_dir_file_list[@]}"; do
    if file "$input_dir/$file" | grep -q "ASCII text"; then
        basename=$(basename "$file")
        cp "$input_dir/$file" "$output_dir"/"$count"_"$basename"
        count=$((count + 1))
    fi
done