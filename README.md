# PlexifyFiles

.SYNOPSIS
        Script for renaming Movie/TV show files that end in .mkv, .mp4, or .srt. See .EXAMPLES for formatting. 
        Cross-plaform support for Windows, MacOS, and Linux
    .DESCRIPTION
        Script for renaming movie/TV show files to a more Plex/Infuse friendly format to help with the   
        metadata fetch. Can (optionally) take a path to a directory as a cli argument. If an unsupported
        file extension is found (for example, .avi) the file will not be renamed. This is my own personal
        bias toward the mkv/mp4 containers as I believe they are superior. Subtitle tracks ending in .srt
        will also be renamed so that Plex/Infuse can easily match sidecar subtitles with their respective
        file. 
        
    .EXAMPLE
        **** MOVIES ****
        The parent folder must be named with a certain consistency for the script to work. Examples of names:
        <Movie_Name> (Movie_Year) [...Whatever else here...]       such as:
        Ex Machina (2014) 2160p.HDR.AAC.5.1                        and the file names looks like:
        
        Ex Machina (2014).mkv
        Ex Machina (2014).en.srt
        
    .EXAMPLE
        **** TV SHOWS ****
        The parent folder must be named with a certain consistency for the script to work. Examples of names:
        <Show_Name> [...Whatever else here...]                      such as:
        |Game of Thrones| OR |Game of Thrones 1080p|                And the file names will look like:
        Game of Thrones S01E01.mkv
        Game of Thrones S01E01.en.srt
        Season folders found within the parent directory will be renamed automatically.
        Regex is used to find matches for "Season <Number>" or "S<Number>" in the folder name.
        Each season *MUST* have its own folder (mini-series can use a Season 1 folder only):
        | Game of Thrones 1080p                                     Top level directory
        |----Game.of.thrones.S01.1080p                              Folder name
        |--------S01E01.mkv....                                     Episode files
        The new structure will look like:
        | Game of Thrones 1080p
        |----Season 1
        |--------Game of Thrones S01E01.mkv....
        
    .PARAMETER RenamePath
        **** USAGE ****
        To use this parameter, call the script name from PowerShell/PowerShell core:
        ## Syntax ##
            .\PlexifyMovies.ps1 |Optional| [-RenamePath] <string>
        ## Using a custom path ##
            WINDOWS - Pass the absolute path to the directory
                .\PlexifyMovies -RenamePath "C:\Users\User\Desktop\Movies"
            MAC / LINUX - Default path starts in user's home directory, so the relative path is fine
                                  
                .\PlexifyMovies -RenamePath Movies
                .\PlexifyMovies -RenamePath "Desktop/Staging"
        
    .NOTES
        Written by: pkelly
        Last Edited: 11/01/2020
        Version 1.0.0 - Initial Release
        Version 1.1.0 - Added support for renaming shows
        Version 1.1.1 - Fixed bug where regex match was sometimes ignored
        Version 1.2.1 - Added support for MacOS and Linux
