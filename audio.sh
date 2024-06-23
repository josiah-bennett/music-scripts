#!/bin/sh

# This file (should be called dl-audio.sh) and should only do the following things.
# 1. download the json metadata alongside the file to be able to tag the file for convenience.
# 2. download the audio file by given video ID (parameter) with the best audio encoding, preferably opus/ogg before m4a (require user input or a flag as an option)
# 3. rename the file to fit the standards set by me (see the README) should probably call an outside script...
# 4. move the file from .working/ to .working/do_sql/album-name/ using the correctly formatted album name, creating the directory if needed.
# 5. tag the file with the right and necessary metadata using opustags/tag from Luke Smiths Github...
# 6. Cleanup...
#
# from here You should be able to run addalbum.sh and addaudio.sh in that order to have a fully tagged and stored (in the database) audio file... Now just move it to the correct place in ~/Music. done

log() {
	if [ "$1" -le "$log_level" ]; then
		shift
		local IFS=' ' # local is not POSIX complient!!!
		printf '%s\n' "$*"
	fi
}

# handle all of the fun options
codec=-1
log_level=1

while [ -n "$1" ]; do
	case "$1" in
		-b) codec=1 ;;
		-o) codec=0 ;;
		-n) track="$2"; shift ;;
		-N) total="$2"; shift ;;
		-g) genre="$2"; shift ;;
		-v) log 3 'increasing log level'; log_level=$((log_level + 1)) ;;
		-q) log 3 'decreasing log level'; log_level=$((log_level - 1)) ;;
		--) shift; break ;;
		*) echo "$1 is not an option!" ;;
	esac
	shift
done

# 1. download the json metadata
for link in "$@"; do :; done
[ -z "$1" ] && log 1 'there should be at least one argument!' && exit
log 2 "$link"

log 2 'Downloading temporary JSON data...'
#cmd='youtube-dl --no-playlist -j'
cmd='yt-dlp --no-playlist -j'
[ "$log_level" -lt 2 ] && eval "$cmd '$link' > tmp.json" || eval "$cmd -q '$link' > tmp.json" && log 2 'download successful.'

# 2. download the audio file with preferred audio format.
numcodecs="$(jq '.formats[].vcodec' tmp.json | grep 'none' | wc -l)" # number of available codecs
opuscodecs="$(jq '.formats[].acodec' tmp.json | head -n $numcodecs | awk '{print NR $0}' | grep 'opus' | tail -n 1)"
opuscodec="$(echo ${opuscodecs%%\"*})"
log 3 "$numcodecs"; log 3 "$opuscodec"

checkuser() {
	opusabr="$(jq ".formats[$(dlopus)].abr" tmp.json)"
	bestabr="$(jq ".formats[$(dlbest)].abr" tmp.json)"
	[ $opuscodec -lt $numcodecs ] && read -p 'Do you want to use opus, instead of m4a [Y/n]' input || input=''
	#printf '%s - %s\n' $opusabr $bestabr
	[ "$input" = 'n' ] && dlbest || dlopus
}

dlbest() { echo "$((numcodecs-1))"; }
dlopus() { echo "$((opuscodec-1))"; }

case "$codec" in
	0) index="$(dlopus)" ;;
	1) index="$(dlbest)" ;;
	*) index="$(checkuser)" ;;
esac
log 3 "$index"

abr="$(jq ".formats[$index].abr" tmp.json)"
format="$(jq ".formats[$index].format_id" tmp.json | cut -d '"' -f 2)"
codec="$(jq ".formats[$index].acodec" tmp.json)"

log 2 "Downloading audio using "$codec" (id: "$format", abr: "$abr")" # url format: "https://www.youtube.com/watch?v=…&list=…&index=…"
#cmd="youtube-dl --no-playlist -i -x -f "$format" -o '.working/%(track)s.%(ext)s'"
cmd="yt-dlp --no-playlist -i -x -f "$format" -o '.working/%(track)s.%(ext)s'"
[ "$log_level" -lt 2 ] && eval "$cmd -q '$link'" || eval "$cmd '$link'" && log 2 'download successful.'

# 3. rename file to fit standards (README) / 4. move the file to do_sql/album_name/
ftitle="$(jq '.track' tmp.json | cut -d '"' -f 2)"
title="$ftitle"
album="$(jq '.album' tmp.json | cut -d '"' -f 2)"
[ "$ftitle" = 'null' ] && ftitle='NA' && printf 'Enter the title: ' && read -r title
[ "$album" = 'null' ] && printf 'Enter the album: ' && read -r album

ext="$(jq ".formats[$index].ext" tmp.json | cut -d '"' -f 2)"
[ "$ext" = 'webm' ] && ext='opus'

file=".working/$ftitle.$ext"
log 3 "$file"

# format a given string to match the conventions from the README (should be the basepath)
fmtstr() {
	echo "$1" | iconv -cf UTF-8 -t ASCII//TRANSLIT | sed 's/[^[:alnum:]]\+/_/g; s/^_\|_$//g' | tr '[:upper:]' '[:lower:]'
}

base="${file##*/}"; dir="${file%$base}do_sql/$(fmtstr "$album")/"

newfile="$dir$(fmtstr "${title}").${base##*.}"
log 3 "$newfile"
altfile=".working/NA.${base##*.}"

log 2 'Renaming and Moving the audio file'
log 2 "from: $file, to: $newfile"
mkdir -p "$dir"
! mv "$file" "$newfile" > /dev/null && log 1 'are you allowed to move this file?' && log 1 'trying filename "NA" ...' && ! mv "$altfile" "$newfile" > /dev/null && log 1 'are you allowed to move this file?'
file="$newfile"

# 5. tag the file with the necessary metadata
# title, album and file see above...
artist="$(jq '.artist' tmp.json | cut -d '"' -f 2)"
date="$(jq '.upload_date' tmp.json | cut -d '"' -f 2 | head -c 4)"
# try to get this out of some json files they are definitly not in all...
[ "$artist" = 'null' ] && printf 'Enter the artist: ' && read -r artist
[ -z "$track" ] && printf 'Enter the track number: ' && read -r track
[ -z "$total" ] && printf 'Enter the total number of tracks in this album: ' && read -r total
[ -z "$genre" ] && printf 'Enter the song genre: ' && read -r genre

log 2 "Tagging the audio"
tag -a "$artist" -A "$album" -t "$title" -n "$track" -N "$total" -d "$date" -g "$genre" "$file"

# 6. Cleanup...
log 2 "Removing temporary files"
rm tmp.json
