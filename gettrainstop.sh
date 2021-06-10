#!/bin/bash

#NAME:CLARIZA LOOK
#Created using: Windows 10 Home WSL 
#Task: Determine if your location is within one kilometre of a train station, and then 
#......determine the sequence of times and train stations required to get you to the ferry terminal.
# 	Input Location: 93 Hume Road, Thornlie (-32.062231 115.953581) in Google Maps
# 	Other test input location: 420 Joondalup Dr, (-31.745001, 115.769476; 54 Blackadder Rd Swan View (-31.879957, 116.035971)
# 	Destination: Rottness Island (-31.996790, 115.540240)


#####Set timezone to Australia Perth Time #####
export TZ=Australia/Perth
currenttime=`date +"%T"`

####Function that stores the global input from the user (latitude, longitude of user location) #####
function get_input() {

	start_loc_lat=$1 
	start_loc_lon=$2
	
	echo "START LOCATION LATITUDE: $start_loc_lat "
	echo "START LOCATION LONGITUDE: $start_loc_lon "
}

#####Function that generates the necessary information based from all railway stations in the "stops.txt" file #####
function generate_railway_list_data() {
	
	grep Rail stops.txt
}

#####Function that converts the meters to kilometers from the Haversine Awk function #####
function covert_to_km () {
    
	distance_in_meters=$1
	divisor=1000
   
	distance_in_kilometers=`echo $distance_in_meters/$divisor|bc -l`
	echo $distance_in_kilometers
	
}

#####Function that compare's two numbers and returns yes or no #####
numCompare() {
	if (( $(awk 'BEGIN {print ("'$1'" >= "'$2'")}') )); then
		echo "yes"
	else 
		echo "no"
	fi
}

#####Function that gets the schedule of the nearest rail station #####
function get_stn_schedule () {

	nearest_station_input=$1
	nearest_railway_stop_id=`cat $nearest_station_input | cut -d, -f4`

	#####Extracting data from "stop_times.txt" 
	grep $nearest_railway_stop_id stop_times.txt
	
}


#####Function that compares user's current time and get the latest schedule of the nearest station #####
function get_latest_stn_departure_schedule () {

	input_file=$1
	

	#####Extract data from 'new_stn_schedule' file then get difference of time to get the nearest departure time of that station
	while IFS= read -r input_line
	do
	  
	  trip_id=`echo $input_line | cut -d, -f1`
	  arrival_time=`echo $input_line | cut -d, -f2`
	  departure_time=`echo $input_line | cut -d, -f3`
	  stop_id=`echo $input_line | cut -d, -f4`
	  stop_sequence=`echo $input_line | cut -d, -f5`
	  pickup_type=`echo $input_line | cut -d, -f6`
	  drop_off_type=`echo $input_line | cut -d, -f7`
	  timepoint=`echo $input_line | cut -d, -f8`
	  fare=`echo $input_line | cut -d, -f9`
	  zone=`echo $input_line | cut -d, -f10`
	  section=`echo $input_line | cut -d, -f11`
	  
	  #####$currenttime is a global variable
	  time1="$currenttime"
	  time2="$departure_time"
	  

	  
	  #####Get the difference in time in 'seconds' between user's time and "nearest station departure time"
	  time_diff=`countTimeDiff $time1 $time2`
	  echo $time_diff,$trip_id,$arrival_time,$departure_time,$stop_id,$stop_sequence,$pickup_type,$drop_off_type,$timepoint,$fare,$zone,$section
	 
	done < "$input_file"
	
    
}

#####Function that calculate the difference in time in SECONDS between the user's time and the departure time of the nearest rail stn #####
function countTimeDiff() {
    timeA=$1 
    timeB=$2 

    # feeding variables by using read and splitting with IFS
    IFS=: read ah am as <<< "$timeA"
    IFS=: read bh bm bs <<< "$timeB"

    # Convert hours to minutes.
    # The 10# is there to avoid errors with leading zeros
    # by telling bash that we use base 10
    secondsA=$((10#$ah*60*60 + 10#$am*60 + 10#$as))
    secondsB=$((10#$bh*60*60 + 10#$bm*60 + 10#$bs))
    DIFF_SEC=$((secondsB - secondsA))
    #echo "The difference is $DIFF_SEC seconds."
	echo $DIFF_SEC;

    SEC=$(($DIFF_SEC%60))
    MIN=$((($DIFF_SEC-$SEC)%3600/60))
    HRS=$((($DIFF_SEC-$MIN*60)/3600))
    #TIME_DIFF="in Hours===$HRS:$MIN:$SEC";
    #echo $TIME_DIFF;
}

#####Function that extracts the time of the station
function get_time_of_stn (){
    file=$1 
	
	while IFS= read -r file_line
	do
	  difference_time=`echo $file_line | cut -d, -f1`
	  trip_id_time=`echo $file_line | cut -d, -f2`
	  arrival_time_time=`echo $file_line | cut -d, -f3`
	  departure_time_time=`echo $file_line | cut -d, -f4`
	  stop_id_time=`echo $file_line | cut -d, -f5`
	  stop_sequence_time=`echo $file_line | cut -d, -f6`
	  pickup_type_time=`echo $file_line | cut -d, -f7`
	  drop_off_type_time=`echo $file_line | cut -d, -f8`
	  timepoint_time=`echo $file_line | cut -d, -f9`
	  fare_time=`echo $file_line | cut -d, -f10`
	  zone_time=`echo $file_line | cut -d, -f11`
	  section_time=`echo $file_line | cut -d, -f12`
	  

	  ####Get numbers that are positive to sort later
	  if [ $difference_time -gt 0 ]
	  then
		echo $file_line
	  fi 
	 
	done < "$file"
	
}

#####Function the only extracts the railway stations and remove non-railways supported modes but has "railway" word in their Stop Name #####
function remove_non_rail (){

	input=$1
	
	#####Extract data that has railway station from 'stops.txt' file
	while IFS= read -r line
	do
	  
	  supported_modes=`echo $line | cut -d, -f10`
	  
	  #####Get Only The RAILWAY STATIONS Data
	  if [[ "$supported_modes" == *"Rail"* ]]; then               
		echo $line
	
	  fi 	
	done < "$input"
}

#####Function that extracts all nearest railway stations to the user (within 5 kilometers) #####
function get_nearest_railway_stn () {
	
	railway_list_input=$1
	user_lat_input=$2
	user_long_input=$3

	while IFS= read -r lines
	do
	
		#####Extract data from 'new_raw_railway_stn_list' file that will be used throughout the calculations####
		location_type_rail=`echo $lines | cut -d, -f1`
		parent_station_rail=`echo $lines | cut -d, -f2`
		stop_id_rail=`echo $lines | cut -d, -f3`
		stop_code_rail=`echo $lines | cut -d, -f4`
		stop_name_rail=`echo $lines | cut -d, -f5`
		stop_desc_rail=`echo $lines | cut -d, -f6`
		stop_lat_rail=`echo $lines | cut -d, -f7`
		stop_lon_rail=`echo $lines | cut -d, -f8`
		zone_id_rail=`echo $lines | cut -d, -f9`
		supported_modes_rail=`echo $lines | cut -d, -f10`

	  
	  #####Call the function that calculates to get the nearest_train
	  distance_mtrs=`compute_distance $user_lat_input $user_long_input $stop_lat_rail $stop_lon_rail`
	  
	  #####Convert 'distance_mtrs' into kilometers
	  distance_kms=`covert_to_km $distance_mtrs`
	  
	  
	  ######BELOW IS TO CHECK DISTANCE UP TO 5KMS TO GET THE NEAREST STATION#######
	  
	  #Assign first element as a minimum distance. 
	  rail_stn_dis=$distance_kms
	  
	  within5kms=`echo $rail_stn_dis'>'5|bc -l`
	  #echo "within5kms?: $within5kms"
	  
	  ##### Check if distance is within 5kms,if $within1kms is [0], means yes 
	  if [[ "$within5kms" == "0" ]]; then  
		#echo "NEAREST STATION TO YOUR LOC: Stop Name: $stop_name_rail, Distance: $rail_stn_dis "
		
		#####Output all necessary information of that rail stn with "$rail_stn_dis" as the first element to be sorted later to get the nearest railway
		echo $rail_stn_dis,$location_type_rail,$parent_station_rail,$stop_id_rail,$stop_code_rail,$stop_name_rail,$stop_desc_rail,$stop_lat_rail,$stop_lon_rail,$zone_id_rail,$supported_modes_rail
		
	  fi 
      
	done < "$railway_list_input"
   
}

#####Function that checks if the railway station is parent or not
#####Cos parent raiway stations does not have stop_ids and we need the stop_id data to get schedule
function get_nearest_non_parent_station () {
	
	station_lists=$1
	
	while IFS= read -r y_lines
	do
		
		parent_stn=`echo $y_lines | cut -d, -f2`
		
		
		if [[ "$parent_stn" != 1 ]]; then 
		    echo "$y_lines"

		fi 
	
	done < "$station_lists"
}

#####Function to remove the first field #####
function remove_firstfield () {
	inp=$1
	while IFS= read -r y_lines
	do
		var1=`echo $y_lines | cut -d, -f1`
		var2=`echo $y_lines | cut -d, -f2`
		var3=`echo $y_lines | cut -d, -f3`
		var4=`echo $y_lines | cut -d, -f4`
		var5=`echo $y_lines | cut -d, -f5`
		var6=`echo $y_lines | cut -d, -f6`
		var7=`echo $y_lines | cut -d, -f7`
		var8=`echo $y_lines | cut -d, -f8`
		var9=`echo $y_lines | cut -d, -f9`
		var10=`echo $y_lines | cut -d, -f10`
		var11=`echo $y_lines | cut -d, -f11`
		
		echo "$var2,$var3,$var4,$var5,$var6,$var7,$var8,$var9,$var10,$var11"
	
	done < "$inp"
}

#####The Haversine awk function that computes the distance between 2 latitudes and 2 longitudes
function compute_distance() {
	lat1=$1
	lon1=$2
	lat2=$3
	lon2=$4
	
	awk '
		function degrees_to_radians(degrees) {
			pi = 3.141592653589793
			return (degrees * pi / 180.0);
		}

		function asin(x) {
			return atan2(x, sqrt(1-x*x));
		}

		function haversine(lat1, lon1, lat2, lon2) {
			EARTH_RADIUS_IN_METRES = 6372797;

			deltalat = (lat2 - lat1) / 2.0;
			deltalon = (lon2 - lon1) / 2.0;

			sin1     = sin( degrees_to_radians(deltalat) );
			cos1     = cos( degrees_to_radians(lat1) );
			cos2     = cos( degrees_to_radians(lat2) );
			sin2     = sin( degrees_to_radians(deltalon) );

			x        = sin1*sin1 + cos1*cos2 * sin2*sin2;
			metres   = 2 * EARTH_RADIUS_IN_METRES * asin( sqrt(x) );

			return metres;
		}

	BEGIN   {
				if(ARGC == 5) {
					printf("%f\n", haversine(ARGV[1],ARGV[2],ARGV[3],ARGV[4]));

				}
				else {
					printf("Usage: %s lat1 lon1 lat2 lon2\n", ARGV[0]);
					exit(1);
				}
			}
	' $*
   
}


####FIRST, it stores the input from the users which are the latitude and longiture of the user location
get_input $1 $2

#####SECOND, Generate the railway list data from 'stops.txt'
generate_railway_list_data > raw_railway_stn_list

#####To Remove '\r' in the file caused by WSL
tr -d '\r' < raw_railway_stn_list > new_raw_railway_stn_list

#####THIRD, REMOVE NON-RAIL SUPPORTED MODES
remove_non_rail new_raw_railway_stn_list>final_railway_list

#####To Remove '\r' in the file caused by WSL
tr -d '\r' < final_railway_list > new_final_railway_list

#####FOURTH, compute of the nearest railway station from the user location 
get_nearest_railway_stn final_railway_list $start_loc_lat $start_loc_lon > nearest_railway_stations


#####To Remove '\r' in the file caused by WSL
tr -d '\r' < nearest_railway_stations > new_nearest_railway_stations

#####FIFTH, After storing all "nearest railway stations", sort them from the least distance, then take the first line, then store it in "nearest_of_all" file
cat new_nearest_railway_stations | sort > within5kms_railway_list


#####To Remove '\r' in the file caused by WSL
tr -d '\r' < within5kms_railway_list > new_within5kms_railway_list

#####SIXTH, Then get the nearest NON PARENT STATION because it has all data like "stop_id"
get_nearest_non_parent_station new_within5kms_railway_list | head -1 > nearest_of_all

#####To Remove '\r' in the file caused by WSL
tr -d '\r' < nearest_of_all > new_nearest_of_all

#####SEVENTH, clean the data as normal without the distance field
remove_firstfield new_nearest_of_all > cleaned_nearest_of_all


#####To Remove '\r' in the file caused by WSL
tr -d '\r' < cleaned_nearest_of_all > new_cleaned_nearest_of_all
echo "-------------- Nearest Train Stn --------------"
cat new_cleaned_nearest_of_all


#####EIGHT, Then get the schedule of that particular station	
get_stn_schedule new_cleaned_nearest_of_all > stn_schedule

#####To Remove '\r' in the file caused by WSL
tr -d '\r' < stn_schedule > new_stn_schedule

#####NINETH, Get the time difference of user's current time vs. the nearest station time
get_latest_stn_departure_schedule new_stn_schedule > time_difference_file

#####To Remove '\r' in the file caused by WSL
tr -d '\r' < time_difference_file > new_time_difference_file
cat new_time_difference_file | sort -n > sorted_time_difference_file

#####TENTH, sort time difference to get the nearest station's departure time to the user
get_time_of_stn sorted_time_difference_file > sorted_time_difference_file_positive_times

echo "-------------- Departure Time if you depart now --------------"
head -n 1 sorted_time_difference_file_positive_times







 









