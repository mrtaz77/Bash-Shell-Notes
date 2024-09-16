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

temp="temp.txt"

: > $temp

input_dir_files=$(find "$input_dir"/* -type f)
IFS=$'\n' read -r -d '' -a input_dir_file_list <<< "$input_dir_files"

for file in "${input_dir_file_list[@]}"; do
    basename=$(basename "$file")
	basename_no_ext="${basename%.*}"
	length=$(expr length "$basename_no_ext")
	line_count=$(wc -l "$file" | cut -d' ' -f1)
	echo "$length|$line_count|$file" >> "$temp"
done

temp2="temp2.txt"
: > $temp2

sort -n $temp >> $temp2

IFS=$'\n' read -d '' -r -a lines < $temp2

count=0
curr_dir="$output_dir"
for line in "${lines[@]}"; do
	length=$(echo "$line" | cut -d'|' -f1)
	for ((i=1;i<=length;i++)); do
		curr_dir="$curr_dir"/"$i"
		if [ ! -d "$curr_dir" ]; then
			mkdir -p "$curr_dir"
			count=0
		fi
	done
	file=$(echo "$line" | cut -d'|' -f3)
	basename=$(basename $file)
	cp "$file" "$curr_dir"/"$count"_"$basename"
	count=$((count + 1))
	curr_dir="$output_dir"
done

rm $temp $temp2