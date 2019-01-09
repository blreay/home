#!/bin/bash

#for chuchu

ffmpeg -i clip20180122150914.mp4 -vcodec copy  -an clip20180122150914.mp4.v.mp4
cp clip20180122150914.aac ffmpeg.aac
ffmpeg -i ffmpeg.aac -af 'volume=8' out.aac
cp out.aac vol8.aac
ffmpeg -i clip20180122150914.mp4.v.mp4 -i out_nopeople.mp3 -vcodec copy -acodec copy output_v1.mp4
ffmpeg -i clip20180122150914.mp4.v.mp4 -i out.aac  -vcodec copy -bsf:a aac_adtstoasc output_orig.mp4

