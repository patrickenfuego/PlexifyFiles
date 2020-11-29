# PlexifyFiles

A script for renaming movie/TV show files and folders to a more Plex friendly format, which helps with the metadata fetch. Renaming files manually take a very long time, so I decided to write this script.



The script has cross platform support with MacOS and Linux using PowerShell Core. For more information on installing PowerShell core, please see [here](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell?view=powershell-7.1).

## Structure

### Movies

Movie folders will look like this after running the script:

>Ex Machina (2014) 2160p

And the files will look like this:

>Ex Machina (2014).mkv

>Ex Machina (2014).srt

### TV Shows

TV show folders will look like this after running the script:

>Game of Thrones 1080p

Each season must have its own folder. The script will look for "S01" in the folder name, and rename folders to:

>Season 1

Episode files will look like:

>Game of Thrones S01E01.mkv

>Game of Thrones S01E02.mkv  

etc.

## Path

the script will recursively rename all directories (and their respective files) within a specified path. By default, the script uses the following default locations:

- Linux:   `/home/user/Videos`
- MacOS:   `/Users/user/Movies`
- Windows: `C:\Users\user\Videos`

The script can also receive an optional user defined path as a command line argument. To use a different path:

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
