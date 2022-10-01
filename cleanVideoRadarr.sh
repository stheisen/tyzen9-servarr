#!/bin/bash
# *****************************************************************************
# cleanVideoARR.sh
#
# Author: Steve Theisen (Tyzen9)
# License: GNU GENERAL PUBLIC LICENSE
#
# Prerequisites: ffmpeg and exiftool must be installed and in the PATH
#
# *****************************************************************************
help()
{
    echo "
Usage: cleanVideoArr.sh
This script will only function if called by the radarr application.  For more info see http://radarr.video

Prerequisites: ffmpeg and exiftool must be installed and in the PATH
"
    exit 2
}

processMKV()
{
	echo "ffmpeg -i $sourceFilePath -metadata title="$videoTitle" -metadata comment="$date" -map 0 -map_metadata -1 -c copy "$outputFilePath""
  	ffmpeg -i "$sourceFilePath" -metadata title="$videoTitle" -metadata comment="$date" -map 0 -map_metadata -1 -c copy "$outputFilePath" -loglevel fatal
	#ffmpeg -i "$sourceFilePath" -metadata title="$videoTitle" -metadata comment="$date" -map 0 -map_metadata -1 -c copy "$outputFilePath" 
}

processMP4()
{
	echo "exiftool -all= -title="$videoTitle" -comment="$date" $sourceFilePath -o "$outputFilePath""
	exiftool -all= -title="$videoTitle" -comment="$date" "$sourceFilePath" -o "$outputFilePath"
}

fileCleanup()
{
	sourcePath=$1
	outputFilePath=$2
	finalFilePath=$3
	echo [cleanVideoARR] Cleaning up.... 1>&2
	rm "$sourceFilePath"
	mv "$outputFilePath" "$finalFilePath"
}

VALID_ARGUMENTS=$# # Returns the count of arguments
if [ -z "$radarr_eventtype" ]; then
  help
fi

date=$(date '+%Y.%m.%d');

if [ "$radarr_eventtype" == "Test" ]; then
  echo [cleanVideoARR] Success test of the cleanVideoARR script >&2
  exit 0
elif [ "$radarr_eventtype" == "Download" ]; then
  echo [cleanVideoARR] Download functionality initiated for [${radarr_movie_path}] 1>&2

  echo [cleanVideoARR] radarr_movie_path = ${radarr_movie_path} 1>&2
  echo [cleanVideoARR] radarr_moviefile_path = ${radarr_moviefile_path} 1>&2
  echo [cleanVideoARR] radarr_movie_title = ${radarr_movie_title} 1>&2
  echo [cleanVideoARR] radarr_movie_year = ${radarr_movie_year} 1>&2

  # Set path parameters from Radarr for the cleaning
  sourceFilePath=${radarr_moviefile_path}
  sourceFileName=${sourceFilePath##*/}
  sourceExtension=${sourceFilePath: -4}
  sourceFilePathNoExt="${sourceFilePath%.*}";
  outputFilePath="$sourceFilePathNoExt-CLEANING$sourceExtension";
  finalFilePath="$sourceFilePath";
  # Get the movie title and year from Radarr
  videoTitle=${radarr_movie_title}
  videoYear=${radarr_movie_year}

  successfulProcessing=false;

  if [ "${sourceFilePath: -4}" == ".mkv" ]
    then
		echo "[cleanVideoARR] Processing MKV file: $sourceFileName" 1>&2
		processMKV;
		if [ $? -eq 0 ]; then successfulProcessing=true; fi
  elif [ "${sourceFilePath: -4}" == ".mp4" ]
	then
		echo "[cleanVideoARR] Processing MP4 file: $sourceFileName" 1>&2
		processMP4;
		if [ $? -eq 0 ]; then successfulProcessing=true; fi
  else
	echo -e "[cleanVideoARR] ERROR - Unknown file extension: [ $sourceExtension ], \e[1;33mskipping $sourceFilePath\e[1;m" 1>&2;
	successfulProcessing=true;
  fi
	
  if $successfulProcessing 
	then
		fileCleanup "$sourceFilePath" "$outputFilePath" "$finalFilePath"
	else
		echo -e "\[cleanVideoARR] e[1;31m** PROCESSING FAILED **\e[1;m" 1>&2;
	fi

else
  help
fi
  
exit 0


 


