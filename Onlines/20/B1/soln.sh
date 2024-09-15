#!/bin/sh

input=""
led_path="./sys/class/leds/input24__capslock/brightness"

while true
do 
	read -p "Enter a command: " input
	if [ "$input" = "exit" ]; then
		echo "Exiting command monitor"
		break
	fi
	eval "$input"
	status=$?
	if [ $status -ne 0 ]; then
		echo "Failed: Command exited with status "$status"."
		echo 1 > "$led_path"
		sleep 3s
		echo 0 > "$led_path"
	else
		echo "Success: Command executed successfully."
	fi
done