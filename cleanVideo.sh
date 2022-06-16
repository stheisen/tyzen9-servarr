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
Usage: cleanVideo.sh -f sourceFilePath [ -t \"Title\" ] [ -y #### ]
"
    exit 2
}

processMKV()
{
	#echo "ffmpeg -i $sourceFilePath -metadata title="$videoTitle" -metadata comment="$date" -map 0 -map_metadata -1 -c copy "$outputFilePath""
  	ffmpeg -i "$sourceFilePath" -metadata title="$videoTitle" -metadata comment="$date" -map 0 -map_metadata -1 -c copy "$outputFilePath" -loglevel fatal
}

processMP4()
{
	#echo "exiftool -all= -title="$videoTitle" -comment="$date" $sourceFilePath -o "$outputFilePath""
	exiftool -all= -title="$videoTitle" -comment="$date" "$sourceFilePath" -o "$outputFilePath"
}

# $sourceFilePath $outputFilePath $finalFilePath
fileCleanup()
{
	sourcePath=$1
	outputFilePath=$2
	finalFilePath=$3
	echo Cleaning up....
	echo rm "$sourceFilePath"
	echo mv "$outputFilePath" "$finalFilePath"
}

VALID_ARGUMENTS=$# # Returns the count of arguments
if [ "$VALID_ARGUMENTS" -eq 0 ]; then
  help
fi

directoryMode=false;

while getopts "d:f:t:y:" opt; do
  case $opt in
     d)
     	 directoryPath=$OPTARG
     	 directoryMode=true;
       ;;
     f)
       sourceFilePath=$OPTARG
       ;;
     t)
       videoTitle=$OPTARG
       ;;
     y)
       videoYear=$OPTARG
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


# In directory mode, all files are scrubbed resulting in NO title in the MetaData
if $directoryMode
then
	echo -e "Processing videos in the directory: \e[1;32m$directoryPath\e[1;m"
	
	for entry in "$directoryPath"/*
	do
		echo "-----------------------------------------------------------------";
		sourceFilePath=$entry;
		sourceFileName=${sourceFilePath##*/}
		sourceExtension=${sourceFilePath: -4}
		sourceFilePathNoExt="${sourceFilePath%.*}";
		outputFilePath="$sourceFilePathNoExt-CLEANING$sourceExtension";
		finalFilePath="$sourceFilePathNoExt$sourceExtension";

		videoTitle="";
		successfulProcessing=false;

		if [ "${sourceFilePath: -4}" == ".mkv" ]
		then
			echo "Processing MKV file: $sourceFileName"
			processMKV;
			if [ $? -eq 0 ]; then successfulProcessing=true; fi
		elif [ "${sourceFilePath: -4}" == ".mp4" ]
		then
			echo "Processing MP4 file: $sourceFileName"
			processMP4;
			if [ $? -eq 0 ]; then successfulProcessing=true; fi
		else
			echo -e "ERROR - Unknown file extension: [ $sourceExtension ], \e[1;33mskipping $sourceFilePath\e[1;m";
			successfulProcessing=true;
		fi
	
		if $successfulProcessing 
		then
		  fileCleanup "$sourceFilePath" "$outputFilePath" "$finalFilePath"
		else
		  echo -e "\e[1;31m** PROCESSING FAILED **\e[1;m"
		fi
	done

# In file mode, only on file is processed using the command line arguments to construct metadata included
else
	echo -e "Processing one file: \e[1;32m$sourceFilePath\e[1;m"

	sourceExtension=${sourceFilePath: -4}
	sourceFileName=${sourceFilePath##*/}
	successfulProcessing=false;
	sourceFilePathNoExt="${sourceFilePath%.*}";

	# Determine if a title and year was provided
	if [[ ! -z $videoTitle && ! -z $videoYear ]]
	then
		echo "Video title: $videoTitle";
		echo "Video Year: $videoYear";
		targetFileName="$videoTitle ($videoYear)";
	# Was only a title provided?
	elif [[ ! -z $videoTitle && -z $videoYear ]]
	then
		echo -e "Video Title: \e[1;32m$videoTitle \e[1;33m(No year was provided)\e[1;m";
		targetFileName="$videoTitle";
	# No Title was provided
	else
		echo -e "\e[1;33m** Title was NOT provided - The metadata title will be BLANK **\e[1;m";
		videoTitle="";
		targetFileName="$sourceFilePathNoExt";
	fi

	outputFilePath="$targetFileName-CLEANING$sourceExtension";
	finalFilePath="$sourceFilePathNoExt$sourceExtension";

	if [ "${sourceFilePath: -4}" == ".mkv" ]
	then
		echo "Processing MKV file: $sourceFileName"
		processMKV;
		if [ $? -eq 0 ]; then successfulProcessing=true; fi
	elif [ "${sourceFilePath: -4}" == ".mp4" ]
	then
		echo "Processing an MP4 file $sourceFileName"
		processMP4;
		if [ $? -eq 0 ]; then successfulProcessing=true; fi
	else
		echo "ERROR - Unknown file extension: [ $sourceExtension ]"
	fi

	if $successfulProcessing 
	then
		fileCleanup "$sourceFilePath" "$outputFilePath" "$finalFilePath"
	else
		echo -e "\e[1;31m** PROCESSING FAILED **\e[1;m"
	fi

fi

exit 0


 


