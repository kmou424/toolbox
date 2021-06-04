function createConf(){
echo $'TARGET_BITRATE="3000"
INPUT_FORMAT="mp4|mov"
OUTPUT_FORMAT="mp4"
LOG_NAME="log.txt"
OUT_DIR="out"' >> "$1"
}

function loadConf(){
	TARGET_BITRATE="3000"
	INPUT_FORMAT="mp4|mov"
	OUTPUT_FORMAT="mp4"
	LOG_NAME="log.txt"
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
	if [[ $cutres -gt $TARGET_BITRATE ]];then
		echo "大于${TARGET_BITRATE}k, 开始压缩视频..."
		echo "码率: ${cutres}k -> ${bitrate}k"
		echo "${filename##*/}: ${cutres}k -> ${bitrate}k" >> "$filedir/${OUT_DIR}/$LOG_NAME"
		ffpb -i "$input" -b:v ${bitrate}k "$output"
	else
		echo "低于${TARGET_BITRATE}k, 无需压缩, 默认跳过..."
		echo "${filename##*/}: ${cutres}k (已跳过)" >> "$filedir/${OUT_DIR}/$LOG_NAME"
	fi
	cd "$WORKDIR"
}

### exec function ###
loadConf

WORKDIR=$PWD
TASK_COUNT=0

INPUT_FORMAT_LIST="*.$(echo $INPUT_FORMAT | sed 's/|/|*./g')"
INPUT_FORMAT_ARR=(`echo $INPUT_FORMAT_LIST | sed 's/ //g' | tr '|' ' '`)

### find target video path ###
for format in ${INPUT_FORMAT_ARR[@]}
do
	if [[ "$(find $PWD -name "$format")" ]];then
		if [[ -n $FILE_LIST ]];then
			FILE_LIST="$FILE_LIST|$(find $PWD -name "$format")"
		else
			FILE_LIST="$(find $PWD -name "$format")"
		fi
	fi
done

### begin compress video ###
OLDIFS=$IFS
IFS="|"
for filename in $FILE_LIST
do
	compressVideo "$filename"
done
echo

IFS=$OLDIFS
