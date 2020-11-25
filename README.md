# PlexifyFiles

A script for renaming movie/TV show files to a more Plex friendly format, which helps with the metadata fetch. 

## Structure

### Movies

Movie folders will look like this after running the script:

>Ex Machina (2014) 2160p

And the files will look like this:

>Ex Machina (2014).mkv

>Ex Machina (2014).srt

### TV Shows

TV show folder will look like this after running the script:

Game of Thrones 1080p

Each season must have its own folder. The script will look for "S01" in the folder name, and rename folders to:

>Season1

Episode files will look like:

>Game of Thrones S01E01.mkv

>Game of Thrones S01E02.mkv  etc.

## Path

By default, the script uses the following default locations:

- Linux:   /home/user
- MacOS:   /Users/user/Movies
- Windows: C:\Users\user\Videos

The script can also receive a user defined path as a command line argument. To use a different path:

        PS> .\PlexifyFiles.ps1 -RenamePath 'C:\Users\user\some\directory'
        
For additional information, use the -`Help` parameter:

        PS> .\PlexifyFiles -Help
        
## Supported File Extensions

To prevent the accidental renaming of files, the script only supports the most common media file extensions. These include:

- mkv (Matroska)
- mp4 / m4v (MPEG-4)
- avi (Audio Video Interleave / Microsoft)
- srt (text based subtitle file)

Additional extensions can be added by modifying the script. 

## Development Notes

Currently, renaming of the root directory is still in testing. It seems to be working well so far, but additional testing against different string permutations is needed. To use this version, see the qa branch.

Otherwise, you will need to manually rename the root folders using the aformentioned structure in order for the rest of the script to work; this is because the script relies on the root folder for file renaming.
To use this feature,
