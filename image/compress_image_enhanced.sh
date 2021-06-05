function createConf(){
echo $'TARGET_QUALITY="2"
INPUT_FORMAT="jpg|png"
OUTPUT_FORMAT="jpg"
LOG_NAME="log.txt"
OUT_DIR="out"' >> "$1"
}

function loadConf(){
	TARGET_QUALITY="2"
	INPUT_FORMAT="jpg|png"
	OUTPUT_FORMAT="jpg"
	LOG_NAME="log.txt"
	OUT_DIR="out"
	if [[ -f "$PWD/toolbox_image.conf" ]];then
			. "$PWD/toolbox_image.conf"
	else
			createConf "$PWD/toolbox_image.conf"
	fi
}

function getSize(){
	str=$(du -h "$1")
	echo ${str%%"	$1"*}
}

function compressImage(){
	filepath="$1"
	filedir="${filepath%/*}"
	filename="${filepath##*/}"

	cd "$filedir"
	mkdir -p "$filedir/${OUT_DIR}"

	TASK_COUNT=$[$TASK_COUNT+1]
	cutfile="${filepath##*/}"
	output="$filedir/$OUT_DIR/${cutfile%.*}.${OUTPUT_FORMAT}"
	input="${filename}"
	quality=${TARGET_QUALITY}

	echo
	echo "当前工作路径: $filedir"
	echo "第$TASK_COUNT个视频处理任务"
	echo "输入文件名: ${filename}"
	echo "输出文件名: ${cutfile%.*}.${OUTPUT_FORMAT}"
	echo "输出位置: ${filedir}/${OUT_DIR}"
	echo "输入文件大小: $(getSize "${filename}")"
	ffmpeg -i "$input" -q:v ${quality} "$output" -loglevel quiet -stats
	echo "输出文件大小: $(getSize "${OUT_DIR}/${filename}")"
	echo "${filename}: $(getSize "${filename}") -> $(getSize "${OUT_DIR}/${filename}")" >> "$filedir/${OUT_DIR}/$LOG_NAME"

	cd "$WORKDIR"
}

### exec function ###
loadConf

WORKDIR=$PWD
TASK_COUNT=0

INPUT_FORMAT_LIST="*.$(echo $INPUT_FORMAT | sed 's/|/|*./g')"
INPUT_FORMAT_ARR=(`echo $INPUT_FORMAT_LIST | sed 's/ //g' | tr '|' ' '`)

### find target image path ###
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

### begin compress image ###
OLDIFS=$IFS
IFS="|"
for filepath in $FILE_LIST
do
	compressImage "$filepath"
done
echo

IFS=$OLDIFS
