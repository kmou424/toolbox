function createConf(){
echo $'SPLIT_LENGTH="60"
INPUT_FORMAT="mp4|mov"
OUTPUT_FORMAT="mp4"
OUT_DIR="out"' >> "$1"
}

function loadConf(){
	SPLIT_LENGTH="60"
	INPUT_FORMAT="mp4|mov"
	OUTPUT_FORMAT="mp4"
	OUT_DIR="out"
	if [[ -f "$PWD/toolbox_video_repack.conf" ]];then
			. "$PWD/toolbox_video_repack.conf"
	else
			createConf "$PWD/toolbox_video_repack.conf"
	fi
}

function compressVideo(){
	file="$1"
	filedir="${file%/*}"
	filename="${file##*/}"
	filename_noext="${filename%.*}"

	cd "$filedir"
	mkdir -p "$filedir/${OUT_DIR}"
	mkdir -p "$filedir/temp_${filename_noext}"

	TASK_COUNT=$[$TASK_COUNT+1]	cutfile="${file##*/}"
	output="$filedir/$OUT_DIR/${cutfile%.*}.${OUTPUT_FORMAT}"
	input="${file}"

	ORI_FRAMWRATE=$(mediainfo --Output="Video;%FrameRate%" ${filename})
	ORI_LENGTH=$(ffprobe -i "$input" -show_format -v quiet | sed -n 's/duration=//p')
	START_TIME=0
	TMP_FOR_NUMBER=$(echo "scale=0; $ORI_LENGTH/$SPLIT_LENGTH" | bc)
	TMP_FOR_NUMBER_FLOAT=$(echo "scale=0; $ORI_LENGTH/$SPLIT_LENGTH" | bc)
	if [ $TMP_FOR_NUMBER_FLOAT == "0" ];then
		FOR_NUMBER=$TMP_FOR_NUMBER
	else
		FOR_NUMBER=$[$TMP_FOR_NUMBER+1]
	fi
	
	echo
	echo "当前工作路径: $filedir"
	echo "第$TASK_COUNT个视频处理任务"
	echo "输入文件名: ${filename}"
	echo "输出文件名: ${cutfile%.*}.${OUTPUT_FORMAT}"
	echo "输出位置: ${filedir}/${OUT_DIR}"
	echo
	echo "正在开始提取音频..."
	ffpb -i "$input" -vn -acodec copy $filedir/temp_${filename_noext}/audio.m4a
	echo
	for((i=1;i<=$FOR_NUMBER;i++))
	do
		echo "正在分割视频, 每$SPLIT_LENGTH秒一段, 第$i段"
		ffpb -i "$input" -ss $(secondToTime $START_TIME) -t $(secondToTime $SPLIT_LENGTH) -vcodec copy -acodec copy $filedir/temp_${filename_noext}/$i.mp4
		START_TIME=$[$START_TIME+$SPLIT_LENGTH]
	done

	echo
	for((i=1;i<=$FOR_NUMBER;i++))
	do
		echo "开始处理第$i段视频"
		echo "逐帧分解中..."
		mkdir "$filedir/temp_${filename_noext}/${i}_frames"
		ffpb -i $filedir/temp_${filename_noext}/$i.mp4 $filedir/temp_${filename_noext}/${i}_frames/frame_%08d.png
		rm -rf $filedir/temp_${filename_noext}/$i.mp4
		echo "重新合成中..."
		ffpb -framerate $ORI_FRAMWRATE -i $filedir/temp_${filename_noext}/${i}_frames/frame_%08d.png -vcodec libx264 $filedir/temp_${filename_noext}/${i}_output.mp4
		echo "file $filedir/temp_${filename_noext}/${i}_output.mp4" >> $filedir/temp_${filename_noext}/list.txt
		rm -rf $filedir/temp_${filename_noext}/${i}_frames
		echo "第$i段视频处理完成"
		echo
	done
	
	echo
	echo "正在合并所有视频片段..."
	ffpb -f concat -safe 0 -i $filedir/temp_${filename_noext}/list.txt -c copy $filedir/temp_${filename_noext}/output_no_audio.mp4
	echo
	echo "正在合并音频..."
	ffpb -y -i $filedir/temp_${filename_noext}/output_no_audio.mp4 -i audio.m4a –vcodec copy –acodec copy $filedir/temp_${filename_noext}/output.mp4
	echo
	echo "输出处理完成的视频..."
	mv "$filedir/temp_${filename_noext}/output.mp4" "$filedir/$OUT_DIR/$filename"
	echo "清除缓存中..."
	rm -rf $filedir/temp_${filename_noext}
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
		echo "repack_video: 仅生成配置文件(genconf)"
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
