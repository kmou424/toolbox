function createConf(){
echo $'TARGET_BITRATE="3000"
TARGET_FRAMERATE="30"
INPUT_FORMAT="mp4|mov"
OUTPUT_FORMAT="mp4"
LOG_NAME="log_video.txt"
OUT_DIR="out"' >> "$1"
}

function loadConf(){
	TARGET_BITRATE="3000"
	TARGET_FRAMERATE="30"
	INPUT_FORMAT="mp4|mov"
	OUTPUT_FORMAT="mp4"
	LOG_NAME="log_video.txt"
	OUT_DIR="out"
	if [[ -f "$PWD/toolbox_video.conf" ]];then
			. "$PWD/toolbox_video.conf"
	else
			createConf "$PWD/toolbox_video.conf"
	fi
}

function compressVideo(){
	filename="$1"
	filedir="${filename%/*}"

	cd "$filedir"
	mkdir -p "$filedir/${OUT_DIR}"

	TASK_COUNT=$[$TASK_COUNT+1]
	cut1=$(ffmpeg -i "$filename" 2>&1 | grep 'bitrate')
	cut2=${cut1#*bitrate: }
	cutres=${cut2% *}
	cutfile="${filename##*/}"
	output="$filedir/$OUT_DIR/${cutfile%.*}.${OUTPUT_FORMAT}"
	input="${filename}"
	bitrate=${TARGET_BITRATE}
	if [[ $cutres -gt $TARGET_BITRATE ]];then
		if [[ $cutres -gt $[$TARGET_BITRATE*2] ]];then
			if [[ $cutres -gt $[$TARGET_BITRATE*2+1000] ]];then
			bitrate="$[$TARGET_BITRATE+500]"
			else
			bitrate="$[$cutres/2]"
			fi
		fi
	fi

	echo
	echo "当前工作路径: $filedir"
	echo "第$TASK_COUNT个视频处理任务"
	echo "输入文件名: ${filename##*/}"
	echo "输出文件名: ${cutfile%.*}.${OUTPUT_FORMAT}"
	echo "输出位置: ${filedir}/${OUT_DIR}"
	echo "视频码率: ${cutres}k"
	echo "视频帧率: ${TARGET_FRAMERATE}fps"
	if [[ $cutres -gt $TARGET_BITRATE ]];then
		echo "大于${TARGET_BITRATE}k, 开始压缩视频..."
		echo "码率: ${cutres}k -> ${bitrate}k"
		echo "${filename##*/}: ${cutres}k -> ${bitrate}k" >> "$filedir/${OUT_DIR}/$LOG_NAME"
		ffpb -i "$input" -b:v ${bitrate}k -r ${TARGET_FRAMERATE} "$output"
	else
		echo "低于${TARGET_BITRATE}k, 无需压缩, 默认跳过..."
		echo "${filename##*/}: ${cutres}k (已跳过)" >> "$filedir/${OUT_DIR}/$LOG_NAME"
	fi
	cd "$WORKDIR"
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
