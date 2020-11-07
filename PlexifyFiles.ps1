<#
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

#>

param (
    [Parameter(Mandatory = $false, Position = 0)]
    [string]$RenamePath
)

### Global Variables ###
#Change these to modify the default folder to recurse for each operating system type
$macDefaultPath = '~/Movies/Test'
$linuxDefaultPath = '~/movies'
$windowsDefaultPath = 'F:\Media Files\Torrents Staging'

#Warning colors. Write-Warning acts strange on PS core
$warnColors = @{ForegroundColor = 'yellow' ; BackgroundColor = 'black' }

#function that renames episode files. See .EXAMPLES for formatting
function Rename-SeasonFiles ($episodes) {
    for ($i = 1; $i -le $episodes.Length; $i++) {
        #Get the full extension. If an unsupported extension is used, returns $null
        $ext = Get-Extension $episodes[$i - 1].ToString() 
        if ($ext) {
            Write-Host "Full path to rename is $($episodes[$i].FullName)"
            if ($i -lt 10) { 
                $seasonNameString = "$newFileName S0$seasonNum`E0$i.$ext"
                Rename-Item $episodes[$i - 1].FullName -NewName $seasonNameString
            }
            else {
                $seasonNameString = "$newFileName S0$seasonNum`E$i.$ext"
                Rename-Item $episodes[$i - 1].FullName -NewName $seasonNameString
            }

            Write-Host "$($episodes[$i - 1].Name) renamed to: $seasonNameString" @colors `n
        }
        else {
            Write-Host "$($episodes[$i - 1].Name) is using an unsupported file extension. Skipping...." `
                @warnColors
        }
    }
}
#Validates and returns the root path to recurse based on operating system. Also validates custom paths
#Any error that occurs in this function is, by design, a terminating one
function Set-RenamePath ([string]$path) {
    #if the user does not enter a path
    if (!$path) {
        if ($isMacOS) {
            Set-Location '~/'
            $OS = "MacOS"
            $colors = @{ ForegroundColor = 'White' ; BackgroundColor = 'Black' }
            $rootDir = $macDefaultPath
        }
        elseif ($isLinux) {
            Set-Location '~/'
            $OS = "Linux"
            $colors = @{ ForegroundColor = 'Green' ; BackgroundColor = 'Black' }
            $rootDir = $linuxDefaultPath 
        }
        elseif ($env:OS -match "Windows") {
            $OS = "Windows"
            $colors = @{ ForegroundColor = 'Blue' ; BackgroundColor = 'Black' }
            $rootDir = $windowsDefaultPath
        }
        #Test the default OS path to make sure it exists. If not found, throw terminating error
        if (Test-Path -Path $rootDir) {
            Write-Host "$OS system detected. Default path is:`t$rootDir"`n @colors
            return $rootDir
        }
        else {
            Write-Host "There was an issue resolving the path on $OS. Exiting..." @warnColors
            Throw "Could not resolve the default path for $OS. Check that the global variable path exists."
        }
    }
    #The user entered a specific path
    elseif (Test-Path -Path $path) {
        $rootDir = $path
        Write-Host "Path validation successful. Path is: $rootDir"`n
        return $rootDir
    }
    #the user supplied path could not be verified 
    else {
        Write-Host "Could not find a supported directory for $path. Exiting..." @warnColors
        Throw "Could not resolve the user supplied path: <$path>. Check that the path exists and try again."
    }
}
#Validates and returns the file extension. To add additional supported file extensions, create a new switch clause
function Get-Extension ($file) {
    switch ($file) {
        { $_.EndsWith(".mkv") } { return $ext = "mkv" }
        { $_.EndsWith(".mp4") } { return $ext = "mp4" }
        { $_.EndsWith(".srt") } { return $ext = "en.srt" } #Change 'en' to modify the metadata language
        #return null to skip file rename. This is to catch unsupported extensions
        Default { return $null }
    }
}
function Plexify-Files ([string]$path) {
    #Validates the root path for rename. If path check fails, the programmer defined OS path is used instead
    $root = Set-RenamePath $path
    #Recurse directories and subdirectories
    Get-ChildItem -Path $root -Directory | ForEach-Object {
        #for matching movie root$rootDirs
        if ($_.Name -match "(?<title>.*)\s(?<year>\(\d\d\d\d\))\s(?<res>\d*\w)(?<extras>.*)") {
            $newFileName = "$($Matches.title) $($Matches.year)"
        }
        #for matching TV show root$rootDirs
        elseif ($_.Name -match "(?<title>.*)\s(?<res>\d*\w).*") {
            $newFileName = "$($Matches.title)"
        }
        #For anything that doesn't have extra information
        else {
            $newFileName = $_.Name
        }
        Write-host "<$newFileName> is the new file name"`n
        #Rename files inside parent folder
        Get-ChildItem -LiteralPath $_.FullName | ForEach-Object {
            $colors = @{ ForegroundColor = "Green"; BackgroundColor = "Black" }
            Write-host "Top Level Name Is: <$($_.Name)>"
            #Skip rename for Featurettes folder if one is present
            if ($_.Name -match "Featurettes") {
                Write-Host "Skipping Featurettes rename..."`n
                continue
            }
            #If the current object is a directory, need to walk deeper to rename files
            if (Test-Path -Path $_.FullName -PathType Container) {
                Write-Debug "Inside pathtype Container"
                #Get the season number as a regex property
                if ($_.Name -match "season (?<number>\d)") {
                    $seasonNum = $Matches.number
                    $episodeFiles = Get-ChildItem -LiteralPath $_.FullName
                    #empty check for returned episode files
                    if (!$episodeFiles) {
                        Write-Host "$($_.Name) does not have any files. Skipping..." @warnColors
                        continue
                    } 
                    else {
                        Rename-SeasonFiles $episodeFiles
                    }
                }
                elseif ($_.Name -match "S(?<number>\d*)") {
                    $seasonNum = $Matches.number
                    if ($seasonNum -match "0(?<seasonNum>[1-9])") {
                        Write-Host "Season number has a leading 0. Removing..." `n
                        $seasonNum = $Matches.seasonNum
                    }
                    $episodeFiles = Get-ChildItem -LiteralPath $_.FullName
                    #empty check for returned episode files
                    if (!$episodeFiles) {
                        Write-Host "$($_.Name) does not have any files. Skipping..." @warnColors
                        continue
                    } 
                    else {
                        Rename-SeasonFiles $episodeFiles
                    }
                    Write-Host "Renaming season root folder to the proper format..."`n
                    Rename-Item $_.FullName -NewName "Season $seasonNum"
                }
                #If no regex match is found, skip rename
                else {
                    Write-Host "Skipping rename for $($_.Name)"
                    continue
                }   
            }
            #If the current object is a file
            elseif (Test-Path -Path $_.FullName -PathType Leaf) {
                Write-Debug "Inside pathtype leaf"
                $ext = Get-Extension $_.Name
                if ($ext) {
                    Rename-Item $_.FullName -NewName "$newFileName.$ext"
                    Write-Host "$($_.Name) renamed to: $newFileName.$ext"`n @colors 
                }
                else {
                    Write-Host "$($_.Name) is using an unsupported file extension. Skipping...."`n @warnColors
                }  
            }
        }
    }
}

###################################### Main script logic ######################################

Write-Host "Starting script`n`n"

if ($RenamePath) {
    Plexify-Files $RenamePath
}
else {
    Plexify-Files
}

