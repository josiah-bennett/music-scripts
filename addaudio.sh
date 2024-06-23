#!/bin/sh

tag() { echo "$metadata" | cut -d ';' -f $1; }
echoerr() { printf "%s\n" "$*" 1>&2; }

albumid() {
	echo "$(sqlite3 "$2" "SELECT albumid FROM Album WHERE album='$1';")"
}

file=$2

# for ITunes downloads
#metadata=$(exiftool -TrackNumber -Title -Album $file | sed 's/.*: //g' | tr '\n' ';')
#track="$(tag 1 | sed "s/ of.*//g")"

# for downloads via yt-dlp/youtube-dl
metadata="$(exiftool -Track -Title -Album $file | sed 's/.*: //g' | tr '\n' ';')"

[ -z "$(tag 1)" ] && track='NULL' && echo 'track is set to NULL!' || track="$(tag 1)"
[ -z "$(tag 2)" ] && title='NULL' && echo 'title is set to NULL!' || title="$(tag 2 | sed "s/'/''/g")"
albumid="$(albumid "$(tag 3)" "$1")"
[ -z "$albumid" ] && album='NULL' && echo 'album is set to NULL!' || album="$albumid"
[ -z "$3" ] && youtubeurl='NULL' && echo 'youtubeurl is set to NULL' || youtubeurl="$3"

sql="INSERT INTO Audio VALUES(NULL, '$track', '$title', '$album', '$file', '$youtubeurl');"

echo "$sql" # test output remove in end product
sqlite3 "$1" "$sql" || echoerr "SQL Error when inserting the Audio record."
