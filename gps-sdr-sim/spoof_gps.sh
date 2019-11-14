#!/bin/bash

################# Obtain Broadcast ephemeris (brdc) data #################
target_location=/home/pi/Desktop/Project/gps-sdr-sim/brdc
three_digit_date=$(date +%j -d "1 days ago")
four_digit_year=$(date +'%Y')
two_digit_year=$(date +'%y')
compressed_filename="brdc"$three_digit_date"0."$two_digit_year"n.Z"
compressed_filepath=$target_location/$compressed_filename
uncompressed_filepath=$target_location/"brdc"$three_digit_date"0."$two_digit_year"n"

if [ -f "$uncompressed_filepath" ]; then
    echo "Using existing brdc file at $uncompressed_filepath"
else
	# Obtain yesterday's brdc data from CDDIS NASA
    download_command="wget ftp://cddis.nasa.gov/gnss/data/daily/"$four_digit_year"/brdc/"$compressed_filename" -P "$target_location
    echo "Running command: $download_command"
    eval $download_command

    # Uncompress zipped brdc file
    echo "Uncompressing file: $compressed_filepath"
    uncompress $compressed_filepath
fi
####################################################################

################## Generating GPS simulated file ##################
gps_sim_sdr=/home/pi/Desktop/Project/gps-sdr-sim/gps-sdr-sim
location_path=/home/pi/Desktop/Project/gps-sdr-sim/location

read -p "Location name: " location_name
full_location=$location_path"/"$location_name".bin"
if [ -f "$full_location" ]; then
    echo "hi"
    echo "Using existing binary file at $full_location"
else
    read -p "Enter latitude value: " lat
    read -p "Enter longitude value: " lon
    gps_sim_command=$gps_sim_sdr" -e "$uncompressed_filepath" -l "$lat","$lon",100 -b 1 -o "$full_location
    echo "Running command: $gps_sim_command"
    eval $gps_sim_command
    echo "GPS simulation binary file is created."
fi
###################################################################

############### Play simulated binary on Limeplayer ###############
echo "Executing $location_name on Limeplayer..."
limeplayer_command="/home/pi/Desktop/Project/gps-sdr-sim/player/limeplayer -s 2600000 -b 1 -g 0.5 < "$full_location
echo "Running command: $limeplayer_command"
eval $limeplayer_command
###################################################################
