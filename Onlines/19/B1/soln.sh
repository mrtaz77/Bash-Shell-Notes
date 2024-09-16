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

ls_files=$(find "$input_dir"/* -type f -exec stat --format="%Y %n" {} \; | sort -n)

IFS=$'\n' read -rd '' -a lss <<< "$ls_files"

count=0
for file in "${lss[@]}"; do
	file_path=$(echo "$file" | cut -d' ' -f2)
	permissions=$(ls -l "$file_path" | cut -d' ' -f1)
	ux=${permissions:3:1}
	gx=${permissions:6:1}
	ox=${permissions:9:1}
	basename=$(basename "$file_path")
	if [ "$ux" = "x" ]; then
		user=$(ls -l "$file_path" | cut -d' ' -f3)
		if [ ! -d "$output_dir/$user" ]; then
			mkdir -p "$output_dir/$user"
		fi
		cp "$file_path" "$output_dir"/"$user"/"$count"_"$basename"
		chmod u-x "$output_dir"/"$user"/"$count"_"$basename"
	fi
	if [ "$gx" = "x" ]; then
		grp=$(ls -l "$file_path" | cut -d' ' -f4)
		if [ ! -d "$output_dir/$grp" ]; then
			mkdir -p "$output_dir/$grp"
		fi
		cp "$file_path" "$output_dir"/"$grp"/"$count"_"$basename"
		chmod g-x "$output_dir"/"$grp"/"$count"_"$basename"
	fi
	if [ "$ox" = "x" ]; then
		other="other"
		if [ ! -d "$output_dir/$other" ]; then
			mkdir -p "$output_dir/$other"
		fi
		cp "$file_path" "$output_dir"/"$other"/"$count"_"$basename"
		chmod o-x "$output_dir"/"$other"/"$count"_"$basename"
	fi
	count=$((count + 1))
done