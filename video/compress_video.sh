base_bitrate="3000"
log_name="log.txt"
output_dir="out"

mkdir -p ${output_dir}
count=0

if [ -f "./${output_dir}/${log_name}" ];then
	rm "./${output_dir}/${log_name}"
fi
touch "./${output_dir}/${log_name}"

for filename in *.mp4
do
	count=$[$count+1]
	cut1=$(ffmpeg -i "$filename" 2>&1 | grep 'bitrate')
	cut2=${cut1#*bitrate: }
	cutres=${cut2% *}
	output="./${output_dir}/$filename"
	input="$filename"
	bitrate=${base_bitrate}
	if [ $cutres -gt $base_bitrate ];then
	        if [ $cutres -gt $[$base_bitrate*2] ];then
			if [ $cutres -gt $[$base_bitrate*2+1000] ];then
			bitrate="$[$base_bitrate+500]"
			else
			bitrate="$[$cutres/2]"
			fi
		fi
	fi

	echo
	echo "第$count个视频处理任务"
	echo "文件名: ${filename}"
	echo "码率: ${cutres}k"
	if [ $cutres -gt $base_bitrate ];then
	echo "大于${base_bitrate}k, 开始压缩视频..."
	echo "码率: ${cutres}k -> ${bitrate}k"
	echo "${filename}: ${cutres}k -> ${bitrate}k" >> "./${output_dir}/$log_name"
	ffpb -i "$input" -b:v ${bitrate}k "$output"
	echo
	else
	echo "低于${base_bitrate}k, 无需压缩, 默认跳过..."
	echo "${filename}: ${cutres}k (已跳过)" >> "./${output_dir}/$log_name"
	echo
	fi
done
