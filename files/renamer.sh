if [ -z $1 ];then
	echo '错误: 参数不存在,请使用 "renamer jpg:mp4:zip:..." 的格式来执行本程序'
	exit 1
fi

INPUT_FORMAT="$1"

INPUT_FORMAT_ARR=(`echo $INPUT_FORMAT | sed 's/ //g' | tr ':' ' '`)

rename 's/ /_/g' *

for format in ${INPUT_FORMAT_ARR[@]}
do
	COUNT=0
	for file in $(ls *.$format)
	do
		COUNT=$[COUNT+1]
		if [ "$file" = "${COUNT}.${format}" ];then
			echo "${COUNT}.${format}已存在, 自动跳过重命名"
		else
			mv "$file" "${COUNT}.${format}"
		fi
	done
done
