function createConf(){
echo $'TARGET_CODEC="libx264"
INPUT_FORMAT="mp4|mov"
OUTPUT_FORMAT="mp4"
OUT_DIR="out"' >> "$1"
}

function loadConf(){
	TARGET_CODEC="libx264"
	INPUT_FORMAT="mp4|mov"
	OUTPUT_FORMAT="mp4"
	OUT_DIR="out"
	if [[ -f "$PWD/toolbox_video_recode.conf" ]];then
			. "$PWD/toolbox_video_recode.conf"
	else
			createConf "$PWD/toolbox_video_recode.conf"
	fi
}

function compressVideo(){
	file="$1"
	filedir="${file%/*}"
	filename="${file##*/}"
	filename_noext="${filename%.*}"

	cd "$filedir"
	mkdir -p "$filedir/${OUT_DIR}"

	TASK_COUNT=$[$TASK_COUNT+1]	cutfile="${file##*/}"
	output="$filedir/$OUT_DIR/${cutfile%.*}.${OUTPUT_FORMAT}"
	input="${file}"

	echo
	echo "当前工作路径: $filedir"
	echo "第$TASK_COUNT个视频处理任务"
	echo "输入文件名: ${filename}"
	echo "输出文件名: ${cutfile%.*}.${OUTPUT_FORMAT}"
	echo "输出位置: ${filedir}/${OUT_DIR}"
	ffpb -i "$input" -vcodec $TARGET_CODEC -pix_fmt yuv420p -acodec copy "$output"
	echo

	cd "$WORKDIR"
}

function secondToTime(){
	seconds=$1
	hour=$(echo "${seconds}/3600" | bc)
	minute=$(echo "${seconds}/60%60" | bc)
	sec=$(echo "${seconds}%60" | bc)
	printf "%02d:%02d:%02d" $hour $minute $sec
}

function tmpInit(){
	if [ ! -f $TMP1 ];then
		touch $TMP1
	fi
}

function tmpClean(){
	if [ -f $TMP1 ];then
		rm $TMP1
	fi
}

### exec function ###
loadConf

if [ ! -z $1 ];then
	if [ $1 = "genconf" ];then
		echo "compress_video_enhanced: 仅生成配置文件(genconf)"
		exit 0
	fi
fi

WORKDIR=$PWD
TASK_COUNT=0
TMP1="toolbox_image_tmp1"

tmpClean
tmpInit

INPUT_FORMAT_ARR=(`echo $INPUT_FORMAT | sed 's/ //g' | tr '|' ' '`)

### find target video path ###
OLDIFS=$IFS
IFS="|"
for format in ${INPUT_FORMAT_ARR[@]}
do
	if [[ "$(find $PWD -name "*.$format")" ]];then
		find $PWD -name "*.$format" | while read -r line
		do
			echo -n "${line}|" >> $TMP1
		done
	fi
done

FILE_LIST="$(cat $TMP1)"
FILE_LIST="${FILE_LIST%|*}"

### begin compress video ###
for filename in $FILE_LIST
do
	compressVideo "$filename"
done
echo

tmpClean

IFS=$OLDIFS
