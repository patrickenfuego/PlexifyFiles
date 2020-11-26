<#
    .SYNOPSIS

        Script for renaming Movie/TV show files ending in .mkv, .mp4, .m4v, .avi, or .srt. See .EXAMPLE for formatting. 
        Cross-plaform support for Windows, MacOS, and Linux

    .DESCRIPTION

        Script for renaming movie/TV show files to a more Plex/Infuse friendly format to help with the   
        metadata fetch. Can (optionally) take a path to a specific directory as a cli argument. 
        
        If an unsupported file extension is found (for example, .mka) the file will not be renamed. This is 
        to prevent accidental renames. To add additional supoorted file extensions, add a switch clause to 
        the Get-FileExtension function. 
        
        Subtitle tracks ending in .srt will also be renamed so that Plex/Infuse can easily match sidecar s
        ubtitles with their respective file. 

        All sub directories within the root directory will be renamed, and can contain a mix of movies and
        TV Shows. 
        
    .EXAMPLE

        **** MOVIES ****

        The parent folder must be named with a certain consistency for the script to work:
        
        Examples of names:

        <Movie_Name> (Movie_Year) [...Whatever else here...]       such as:
        Ex Machina (2014) 2160p.HDR.AAC.5.1                        and the file names looks like:
        
        Ex Machina (2014).mkv
        Ex Machina (2014).en.srt

    .EXAMPLE

        **** TV SHOWS ****

        The parent folder must be named with a certain consistency for the script to work:

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

    .PARAMETER Path

        Choose a custom path to the directory where the files you want to rename are located. 

            WINDOWS - Pass the absolute path to the directory where your files are located. 

                .\PlexifyMovies -Path "C:\Users\User\Desktop\Movies"

            MAC / LINUX - Default path starts in the user's home directory, so the relative path is fine in most cases.
                          If you are having issues, try using the absolute path instead. 
                                  
                .\PlexifyMovies -Path '~/Movies'
                .\PlexifyMovies -Path '~/Desktop/Staging

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

        TODO - Stop removing the leading 0 on season numbers, and instead add a 0 to files in the form of "season #"

#>

param (
    [Parameter(Mandatory = $false, Position = 0)]
    [string]$Path,
    
    [Parameter(Mandatory = $false, Position = 1)]
    [switch]$Help
)
#If the user passes the -Help parameter, show help and exit
if ($Help) {
    Get-Help ".\PlexifyFiles.ps1" -Detailed
    exit
}

### Global Variables ###

#Change these to modify the default folder to recurse for each operating system type
$macDefaultPath = '~/Movies'
$linuxDefaultPath = '~/movies'
$windowsDefaultPath = "C:\Users\$env:USERNAME\Videos"

#Warning colors. Write-Warning acts strange on PS core
$warnColors = @{ForegroundColor = 'Yellow' ; BackgroundColor = 'Black' }
#Successful rename colors
$successColors = @{ ForegroundColor = "Green"; BackgroundColor = "Black" }

##End Global Variables ##

#function that renames episode files. See .EXAMPLES for formatting
function Rename-SeasonFiles ($episodes, $seasonNum) {
    Write-Debug "Season number in Rename-SeasonFiles is: <$seasonNum>"
    for ($i = 1; $i -le $episodes.Length; $i++) {
        #Get the full extension. If an unsupported extension is used, returns $null
        $ext = Get-Extension $episodes[$i - 1].ToString()
        Write-Host "Full path to rename is $($episodes[$i - 1].FullName)"
        if ($ext) {
            if ($i -lt 10) { 
                if ([int]$seasonNum -lt 10) {
                    $episodeString = "$newFileName S0$seasonNum`E0$i.$ext"
                    Rename-Item $episodes[$i - 1].FullName -NewName $episodeString
                }
                else {
                    $episodeString = "$newFileName S$seasonNum`E0$i.$ext"
                    Rename-Item $episodes[$i - 1].FullName -NewName $episodeString
                }
            }
            #$i is greater than 10
            else {
                if ([int]$seasonNum -lt 10) {
                    $episodeString = "$newFileName S0$seasonNum`E$i.$ext"
                    Rename-Item $episodes[$i - 1].FullName -NewName $episodeString
                }
                else {
                    $episodeString = "$newFileName S$seasonNum`E$i.$ext"
                    Rename-Item $episodes[$i - 1].FullName -NewName $episodeString
                }
            }
            if ($?) {
                Write-Host "$($episodes[$i - 1].Name) renamed to: $episodeString" @successColors
                Write-Host ""
            }
        }
        else {
            Write-Host "$($episodes[$i - 1].Name) is using an unsupported file extension. Skipping...." `
                @warnColors
            Write-Host ""
        }
    }
}
#Validates and returns the root path to recurse based on operating system. Also validates custom paths.
#Any error that occurs in this function is, by design, a terminating one to prevent accidental renames
function Set-Path ([string]$path) {
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
        { $_.EndsWith(".m4v") } { return $ext = "m4v" }
        { $_.EndsWith(".avi") } { return $ext = "avi" }
        { $_.EndsWith(".srt") } { return $ext = "en.srt" } #Change 'en' to modify the metadata language
        #return null to skip file rename. This is to catch unsupported extensions
        Default { return $null }
    }
}

function Confirm-RegexMatch ([string]$value, [int]$mode) {
    switch ($mode) {
        #matching the title
        0 {
            if ($value -match "(?<title>.*)\s(?<year>\(\d\d\d\d\))\s(?<res>\d*\w)(?<extras>.*)") {
                $newFileName = "$($Matches.title) $($Matches.year)"
                return $newFileName
            }
            elseif ($value -match "(?<title>.*)\s(?<res>\d*\w).*") {
                $newFileName = "$($Matches.title)"
                return $newFileName
            }
            else { return $value }
        }
        #matching the season number
        1 {
            if ($value -match "season (?<number>\d*)") {
                $seasonNum = "$($Matches.number)"
                return $seasonNum
            }
            elseif ($value -match "S(?<number>\d+)") {
                $seasonNum = $Matches.number
                if ($seasonNum -match "0(?<seasonNum>[1-9])") {
                    Write-Host "Season number has a leading 0. Removing..." `n
                    $number = $Matches.seasonNum
                    return $number
                }
                else { return $seasonNum }
            }
            else { return $null }
        }
    }
}

#Renames the root directory for each movie/show
function Rename-RootDirectory ([string]$path) {
    #Validates the root path for rename. If path check fails, the programmer defined OS path is used instead
    $root = Set-Path $path
    Get-ChildItem -Path $root -Directory | ForEach-Object {  
        #Checks for a movie title match   
        if ($_.Name -match "(?<title>.*)[\.\s\[\(]+(?<year>\d{4}).*[\.\s\[\(]+(?<res>\d{3,4}p)") {
            $name = ($Matches.title.Replace(".", " ")).Trim()
            $name = $name.Replace(":", " -")
            $year = "($($Matches.year))"
            $resolution = ($Matches.res).Trim()
            $title = "$name $year $resolution"
            #$_.Name.Replace($_.Name, $title)
            Rename-Item $_.FullName -NewName ($_.Name.Replace($_.Name, $title)) -Force
            if ($?) { Write-Host "Root directory $title renamed successfully" @successColors }
            else {
                $msg = "There was an issue renaming  $($_.Name). This usually happens when " + 
                "attempting to rename a folder with the same existing name."
                Write-Host $msg @warnColors 
            }
        }
        #Checks for a TV show match
        elseif ($_.Name -match "(?<title>.*)[\.\s\(]+(?<res>\d{3,4}p)") {
            $name = ($Matches.title.Replace(".", " ")).Trim()
            $name = $name.Replace(":", " -")
            $resolution = ($Matches.res).Trim()
            $title = "$name $resolution"

            Rename-Item $_.FullName -NewName ($_.Name.Replace($_.Name, $title))
            if ($?) { Write-Host "Root directory $title renamed successfully" @successColors }
            else {
                $msg = "There was an issue renaming  $($_.Name). This usually happens when " + 
                "attempting to rename a folder with the same existing name."
                Write-Host $msg @warnColors  
            }
        }
        else {
            Write-Host "There was an issue renaming the root directory: " $_.Name @warnColors
        }   
    }
    
}

#Main function
function Rename-PlexFiles ([string]$path) {
    #Validates the root path for rename. If path check fails, the programmer defined OS path is used instead
    $root = Set-Path $path
    #Recurse the root directories and subdirectories
    Get-ChildItem -Path $root -Directory | ForEach-Object {
        #match the new root folder name
        $newFileName = Confirm-RegexMatch $_.Name 0
        Write-host "<$newFileName> is the new file name"`n
        #Rename files inside parent folder
        Get-ChildItem -LiteralPath $_.FullName | ForEach-Object {
            Write-host "Top Level Name Is: <$($_.Name)>"
            #If the current object is a directory
            if (Test-Path -Path $_.FullName -PathType Container) {
                #Skip rename for Featurettes/Extras folder if one is present
                if ($_.Name -match "Featurettes" -or $_.Name -match "Extras") {
                    Write-Host "Skipping Featurettes rename..."`n
                    continue
                }
                Write-Debug "Inside pathtype Container"
                $seasonNumber = Confirm-RegexMatch $_.Name 1
                $episodeFiles = Get-ChildItem -LiteralPath $_.FullName
                if ($seasonNumber -and $episodeFiles) {
                    Rename-SeasonFiles $episodeFiles $seasonNumber
                }
                else {
                    Write-Host "$($_.Name) was either a bad match or the folder has no episodes. 
                                Skipping Rename..." @warnColors
                    continue 
                }
                #If substring contains "S#+", rename to "Season #"  
                if ($_.Name -match "S{1}[0-9]+") {
                    Write-Host "Renaming season folder to the proper format..."
                    Rename-Item $_.FullName -NewName ($_.Name.Replace($_.Name, "Season $seasonNumber"))
                    if ($?) { Write-Host "Folder rename Successful"`n }
                    else { Write-Host "Folder rename unsucessful"`n @warnColors } 
                }  
            }
            #If the current object is a file
            elseif (Test-Path -Path $_.FullName -PathType Leaf) {
                Write-Debug "Inside pathtype leaf"
                $ext = Get-Extension $_.Name
                if ($ext) {
                    Rename-Item $_.FullName -NewName "$newFileName.$ext"
                    Write-Host "$($_.Name) renamed to: $newFileName.$ext"`n @successColors
                    Write-Host ""
                }
                else {
                    Write-Host "$($_.Name) is using an unsupported file extension. Skipping...."`n @warnColors
                }  
            }
        }
    }
}

###################################### Main script logic ######################################

Write-Host "`n`nStarting script...`n" @successColors

if ($Path) {
    Rename-RootDirectory $Path
    Rename-PlexFiles $Path
}
else {
    Rename-RootDirectory
    Rename-PlexFiles
}

