# Music - Folder

This is the manual for arranging the ~/Music folder on my system and also for 
formatting the audio files contained within.

## Folder Structure

> + ~/Music
> |
> |- audio.db  ! *the sqlite database containing all of the information for 
> |               categorisation needs*
> |- (audio.json) ! *I don't know if I want to convert the sql database to json yet*
> |- dl-audio.sh
> |- addalbum.sh
> |- addaudio.sh
> |
> |- README.md ! *this file*
> |
> |-+ .working
> |
> |-+ .lyrics
> |
> |-+ red_river_valley
> | |
> | |- amazing_grace.opus
> | |- aura_lee.opus
> | |  …
> |
> |-+ stack_of_records
> | |
> | |- a_life_worth_living.opus
> | |- church_parking_lot.opus
> | |  …
> |
> |  … ! *all of the different albums/audio directories go here*

## Database files

A sql database (for the time being) to store and categorize the audio files.

> **Database**-Structure:
>
> TABLE *Album*
>
> - albumid	INTEGER PRIMARY KEY
> - artist	TEXT
> - album	TEXT
> - releaseyear	INTEGER
> - genre	TEXT
> - total	INTEGER
>
> Table *Audio*
>
> - audioid	INTEGER PRIMARY KEY
> - track	INTEGER
> - title	TEXT
> - album	INTEGER (FOREIGN KEY *Album*)
> - localurl	TEXT
> - youtubelink	TEXT

## Scripts

Other interesting scripts/dependencies
 - tag
 - bookplit

[LukeSmith's Github](https://github.com/LukeSmithxyz/voidrice/tree/master/.local/bin) : tag, booksplit

### addalbum.sh

This script takes metadata from the audio file provided and adds a new Album record to the database file passed.

 - $1 : database file (audio.db)
 - $2 : audio file

The metadata tags required by the script are:

 - Album :: the album name
 - Artist :: the artist for the album
 - ReleaseYear :: the year the album was released
 - Genre :: the album genre (doesn't need to be really exact)
 - Total :: the total number of tracks on the album

If the tags aren't found they will be added as NULL values for future adding.
That will also be logged in stdout.
If sqlite3 can't create a new record for some reason it will throw an error in stderr.

### addaudio.sh

This script takes metadata from the audio file provided and adds an apropriate Audio record to the database.

 - $1 : database file (audio.db)
 - $2 : audio file
 - $3 : youtube link

The metadata tags required by the script are:

 - Track :: the track number must not exceed the limit of Total see above
 - Title :: the track title
 - Album :: the album name for the given track. used to determine the albumid for the foreign key (*see above*)

the other data required (localurl, youtubelink) are provided via parameters.
Again if the values aren't found the program will use NULL values and will log that fact in stdout.
If sqlite3 can't create the record it will throw an error in stderr.

### dl-audio.sh

This script takes a link from a video, downloads the audio and tags the audio file.

Options:
 - -o : download opus codec only
 - -b : always download the best audio codec available
 - -v : verbose output (for debugging purposes...)
 - -n : the track number
 - -N : the total number of tracks in the album
 - -g : the song genre

This file does the following things:
1. download the json metadata alongside the actual file to be able to tag the file automagiacally
2. download the audio file by the given video link with the encoding specified by options or the user in runtime.
3. rename the file to fit the standards set here...
4. move the file from .working/ to .working/do_sql/album-name/using the correctly formatted album name, creating the directory if needed.
5. tag the file with the correct metadata using opustags/tag from Luke Smith's Github (or ffmpeg)
6. Cleanup ...

From here you should be able to run addalbum.sh and addaudio.sh to finish the process of adding a new album/song to your system.

## File Naming Conventions

**Name** : amazing_grace.opus

For some example song 'Amazing Grace.opus'

The following steps are required:
 - only lowercase letters
 - replace spaces with underscores
 - no special characters
 - remove most of the text in parentheses ()
   + (feat. Some Artist)
   + (other random text)
   + (Live) -> _live at the end of the filename
 - …

Make sure to mostly have .opus files and only some circumstances allow .m4a files...

## Album Naming Conventions

**Name** : red_river_valley

For some example album 'Red River Valley'

with (almost) exclusively .opus files
maybe some .m4a files (to be converted)

see above with file naming conventions.

## Podcasts/Talks/Audiobooks

Make sure to split the Audiobooks into sections/chapters.
Somehow find another/good/ingenious way to integrate the genre tag for podcasts/audiobooks...
(topics???)

see above with file naming conventions.

## TODO: idea for "great" workflow to add a whole batch of files at a time.

 - use the youtube profile and exclusively open the tabs of windows that are
   going to be downloaded.
 - have a script read all of the tabs using `dejsonlz4`
 - then go through the 3 existing scripts to tag the files and add them to the database
 - implement a check that the album is only ever added once
 - make sure the audio file is correctly tagged before messing with the database
 - go through all the tabs in the browser profile. exit

That should work, and I don't think I've missed anything.
