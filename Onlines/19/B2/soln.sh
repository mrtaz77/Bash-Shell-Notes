#!/bin/bash

if [ "$#" -ne 3 ]; then
	echo "Usage: $0 input_dir virus_list.txt output_dir"
	exit 1
fi

input_dir="./$1"
virus_file="./$2"
output_dir="./$3"

if [ ! -d "$input_dir" ]; then 
	echo "Input dir not found: $input_dir"
	exit 1 
fi

if [ ! -f "$virus_file" ]; then 
	echo "Input dir not found: $virus_file"
	exit 1 
fi

if [ -d "$output_dir" ]; then
	rm -rf "$output_dir"/*
else
	mkdir -p "$output_dir"
fi

ls_files=$(find "$input_dir"/* -type f -exec stat --format="%Y %n" {} \; | sort -n)

IFS=$'\n' read -rd '' -a lss <<< "$ls_files"

viruses=()
while IFS= read -r line || [ -n "$line" ]; do
    clean_line=$(echo "$line" | sed 's/\r$//;s/\n$//')
    viruses+=("$clean_line")
done < "$virus_file"

count=0
for file in "${lss[@]}"; do
	file_path=$(echo "$file" | cut -d' ' -f2)
	basename=$(basename "$file_path")
	flag=0
	for virus in "${viruses[@]}"; do
		if grep -q "$virus" "$file_path"; then
			cp "$file_path" "$output_dir"/"$count"_"$basename"
			flag=1
			break
		fi
	done
	if [[ $flag -eq 1 ]]; then
		for virus in "${viruses[@]}"; do
			sed -i "s/$virus/***/g" "$output_dir"/"$count"_"$basename"
		done
	fi
	count=$((count+1))
done