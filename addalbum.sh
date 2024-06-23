#!/bin/sh

tag() { echo $metadata | cut -d ';' -f $1; }
echoerr() { printf "%s\n" "$*" 1>&2; }

file=$2

# this line needs to be looked at the regex doesn't always do what it is supposed to do... (for songs downloaded from ITunes)
#metadata=$(exiftool -Album -AlbumArtist -ContentCreateDate -Genre -TrackNumber $file | sed 's/.*[:|of] //g; s/:.*$//g' | tr '\n' ';')

# this line gets the metadata from downloaded songs via yt-dlp/youtube-dl (see dl-audio.sh)
metadata=$(exiftool -Album -Artist -Date -Genre -Total $file | sed 's/.*: //g' | tr '\n' ';')

[ -z "$(tag 1)" ] && album='NULL' && echo 'album is set to NULL!' || album="$(tag 1)"
[ -z "$(tag 2)" ] && artist='NULL' && echo 'artist is set to NULL!' || artist="$(tag 2)"
[ -z "$(tag 3)" ] && date='NULL' && echo 'date is set to NULL!' || date="$(tag 3)"
[ -z "$(tag 4)" ] && genre='NULL' && echo 'genre is set to NULL!' || genre="$(tag 4)"
[ -z "$(tag 5)" ] && total='NULL' && echo 'total is set to NULL!' || total="$(tag 5)"

sql="INSERT INTO Album VALUES(NULL, '$album', '$artist', '$date', '$genre', '$total');"

echo "$sql" # test output remove in end product
sqlite3 "$1" "$sql" || echoerr "SQL Error when inserting the Album record."
