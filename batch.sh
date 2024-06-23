#!/bin/sh

#TODO this file is very unsatisfactory
for url in "$(dejsonlz4 ~/.mozilla/firefox/"insert profile here"/sessionstore-backups/recovery.jsonlz4 | python ~/projects/firefox-session-scripts/get-urls-new.py | grep "youtube")"; do 
	echo "$url"
done
