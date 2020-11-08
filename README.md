# PlexifyFiles

.SYNOPSIS

        Script for renaming Movie/TV show files ending in .mkv, .mp4, .m4v, .avi, or .srt. See .EXAMPLE for formatting. 
        Cross-plaform support for Windows, MacOS, and Linux

    .DESCRIPTION

        Script for renaming movie/TV show files to a more Plex/Infuse friendly format to help with the metadata fetch. Can (optionally) take a path to a specific directory as a cli argument. 
        
        If an unsupported file extension is found (for example, .mka) the file will not be renamed. This is to prevent accidental renames. To add additional supoorted file extensions, add a switch clause to the Get-FileExtension function. 
        
        Subtitle tracks ending in .srt will also be renamed so that Plex/Infuse can easily match sidecar subtitles with their respective file. 

        All sub directories within the root directory will be renamed, and can contain a mix of movies and TV Shows. 
        
    .EXAMPLE

        **** MOVIES ****

        The parent folder must be named with a certain consistency for the script to work. I am currently
        working on a solution for renaming the root folder as well, but it has been difficult due to the
        number of potential naming schemes. 
        
        Examples of names:

        <Movie_Name> (Movie_Year) [...Whatever else here...]       such as:
        Ex Machina (2014) 2160p.HDR.AAC.5.1                        and the file names looks like:
        
        Ex Machina (2014).mkv
        Ex Machina (2014).en.srt

    .EXAMPLE

        **** TV SHOWS ****

        The parent folder must be named with a certain consistency for the script to work. I am currently
        working on a solution for renaming the root folder as well, but it has been difficult due to the
        number of potential naming schemes. 

        <Show_Name> [...Whatever else here...]                      such as:
        |Game of Thrones| OR |Game of Thrones 1080p|                Files will look like:

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

        Choose a custom path to the directory where the files you want to rename are located. 

            WINDOWS - Pass the absolute path to the directory where your files are located. 

                .\PlexifyMovies -RenamePath "C:\Users\User\Desktop\Movies"

            MAC / LINUX - Default path starts in the user's home directory, so the relative path is fine in most cases. If you are having issues, try using the absolute path instead. 
                                  
                .\PlexifyMovies -RenamePath '~/Movies'
                .\PlexifyMovies -RenamePath '~/Desktop/Staging

    .PARAMETER Help

        Display help information from the command line.

    .NOTES
        Written by: Patrick Kelly
        Last Edited: 11/08/2020

        VERSION HISTORY:

        Version 1.0.0 - Initial Release
        Version 1.1.0 - Added support for renaming shows
        Version 1.1.1 - Fixed bug where regex match was sometimes ignored
        Version 1.2.1 - Added support for MacOS and Linux
        Version 1.2.2 - Fixed renaming issue when season number is 10 or greater
        Version 1.3.2 - Added -Help switch parameter and updated help info