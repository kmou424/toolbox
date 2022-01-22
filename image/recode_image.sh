function createConf(){
echo $'TARGET_COLORSPACE="rgb"
INPUT_FORMAT="jpg|png"
OUTPUT_FORMAT="jpg"
LOG_NAME="log_image.txt"
OUT_DIR="out"' >> "$1"
}

function loadConf(){
	TARGET_COLORSPACE="rgb"
	INPUT_FORMAT="jpg|png"
	OUTPUT_FORMAT="jpg"
	LOG_NAME="log_image.txt"
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
	colorspace=${TARGET_COLORSPACE}

	echo
	echo "当前工作路径: $filedir"
	echo "第$TASK_COUNT个图片转码任务"
	echo "输入文件名: ${filename}"
	echo "输出文件名: ${cutfile%.*}.${OUTPUT_FORMAT}"
	echo "输出位置: ${filedir}/${OUT_DIR}"
	echo "输入文件大小: $(getSize "${input}")"
	convert "$input" -colorspace ${colorspace} "$output"
	echo "输出文件大小: $(getSize "${output}")"
	echo "${filename}: $(getSize "${input}") -> $(getSize "${output}")" >> "$filedir/${OUT_DIR}/$LOG_NAME"

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
		echo "recode_image: 仅生成配置文件(genconf)"
		exit 0
	elif [ $1 = "cleanup" ];then
		rm -rf $filedir/${OUT_DIR} *.txt *.conf
		exit 0
	fi
fi

WORKDIR=$PWD
TASK_COUNT=0
TMP1="toolbox_image_tmp1"

tmpClean
tmpInit

INPUT_FORMAT_ARR=(`echo $INPUT_FORMAT | sed 's/ //g' | tr '|' ' '`)

### find target image path ###
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

### begin compress image ###
for filepath in $FILE_LIST
do
	compressImage "$filepath"
done
echo

tmpClean

IFS=$OLDIFS
