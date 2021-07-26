VIDEO=$(find -name "*.mp4")
if [ -n "$VIDEO" ];then
	echo "错误: 请在无视频目录下执行"
	exit 1
fi
find -name "out" | while read line
do
	NEM=${line#*./}
	NAME=${NEM%out*}
	rm -rf *.png *.jpg *.webp *.gif
	mv -f "${NEM}"/* ./"$NAME"
	rm -rf "$line"
	echo "整理完成: ${line}"
done
