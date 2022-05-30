# *****************************************************************************
# cleanVideo.sh
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
Usage: cleanVideo.sh -d directoryName
Usage: cleanVideo.sh -s sourceFile [ -t \"Title\" ] [ -y #### ]
"
    exit 2
}

processMKV()
{
	echo "ffmpeg -i $sourceFile -metadata title="$movieTitle" -metadata comment="$date" -map 0 -map_metadata -1 -c copy "$outputFilename""
  ffmpeg -i $sourceFile -metadata title="$movieTitle" -metadata comment="$date" -map 0 -map_metadata -1 -c copy "$outputFilename" -loglevel fatal
}

processMP4()
{
	echo "exiftool -all= -title="$movieTitle" -comment="$date" $sourceFile -o "$outputFilename""
	exiftool -all= -title="$movieTitle" -comment="$date" $sourceFile -o "$outputFilename"
}

VALID_ARGUMENTS=$# # Returns the count of arguments
if [ "$VALID_ARGUMENTS" -eq 0 ]; then
  help
fi

directoryMode=false;

while getopts "d:s:t:y:" opt; do
  case $opt in
     d)
     	 directoryPath=$OPTARG
     	 directoryMode=true;
       ;;
     s)
       sourceFile=$OPTARG
       ;;
     t)
       movieTitle=$OPTARG
       ;;
     y)
       movieYear=$OPTARG
       ;;
     *)
       echo "invalid command: no parameter included with argument $OPTARG"
       ;;
  esac
done

if ((OPTIND == 1))
then
		echo
		echo -e "\e[1;31m** Commandline options required **\e[1;m"
    help;
fi

date=$(date '+%Y.%m.%d');



if $directoryMode
then
	echo "DirectoryMode"
	
	for entry in "$directoryPath"/*
	do
		sourceFile=$entry;
		sourceExtension=${sourceFile: -4}
		sourceFileNoExt="${sourceFile%.*}";
		outputFilename="$sourceFileNoExt-CLEANING$sourceExtension";
		cleanedFilename="$sourceFileNoExt$sourceExtension";

		movieTitle="";


		if [ "${sourceFile: -4}" == ".mkv" ]
		then
			echo "Processing an MKV file"
			processMKV;
		elif [ "${sourceFile: -4}" == ".mp4" ]
		then
			echo "Processing an MP4 file"
			processMP4;
		else
			echo -e "ERROR - Unknown file extension: [ $sourceExtension ], \e[1;33mskipping $sourceFile\e[1;m"
		fi
	
		if [ $? -eq 0 ]; then
		  echo Processing complete...
		  rm $sourceFile
		  mv $outputFilename $cleanedFilename
		else
		  echo -e "\e[1;31m** PROCESSING FAILED **\e[1;m"
		fi

	
  	#echo "$entry"
	done

	
else

  echo "FileMode"
	echo "source filename: $sourceFile";
	sourceExtension=${sourceFile: -4}

	# Determine if a title and year was provided
	if [[ ! -z $movieTitle && ! -z $movieYear ]]
	then
		echo "Video title: $movieTitle";
		echo "Video Year: $movieYear";
		targetFileName="$movieTitle ($movieYear)";
	# Was only a title provided?
	elif [[ ! -z $movieTitle && -z $movieYear ]]
	then
		echo "Video title: $movieTitle";
		echo "No year was provided";
		targetFileName="$movieTitle";
	# No Title was provided
	else
		echo -e "\e[1;33m** Title was NOT provided - The metadata title will be BLANK **\e[1;m";
		sourceFileNoExt="${sourceFile%.*}";
		movieTitle="";
		targetFileName="$sourceFileNoExt";
	fi

	outputFilename="$targetFileName-CLEANING$sourceExtension";
	cleanedFilename="$targetFileName$sourceExtension";
	echo "Output file name: $cleanedFilename";

	if [ "${sourceFile: -4}" == ".mkv" ]
	then
		echo "Processing an MKV file"
		processMKV;
	elif [ "${sourceFile: -4}" == ".mp4" ]
	then
		echo "Processing an MP4 file"
		processMP4;
	else
		echo "ERROR - Unknown file extension: [ $sourceExtension ]"
	fi

	if [ $? -eq 0 ]; then
		 echo Processing complete...
		 rm $sourceFile
		 mv $outputFilename $cleanedFilename
	else
		 echo -e "\e[1;31m** PROCESSING FAILED **\e[1;m"
	fi

fi

exit 0


 


