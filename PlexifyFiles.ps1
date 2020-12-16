
<#
    .SYNOPSIS

        Script for renaming Movie/TV show files ending in .mkv, .mp4, .m4v, .avi, or .srt.  
        See .EXAMPLE for formatting. Cross-plaform support for Windows, MacOS, and Linux.

    .DESCRIPTION

        Script for renaming movie/TV show files to a more Plex/Infuse friendly format to help with the   
        metadata fetch. Can (optionally) take a path to a specific directory as a cli argument. 
        
        If an unsupported file extension is found (for example, .mka) the file will not be renamed. This is 
        to prevent accidental renames. To add additional supoorted file extensions, add a switch clause to 
        the Get-FileExtension function. 
        
        Subtitle tracks ending in .srt will also be renamed so that Plex/Infuse can easily match sidecar 
        subtitles with their respective file. 

        All sub directories within the root directory will be renamed, and can contain a mix of movies and
        TV Shows. 
        
    .EXAMPLE

        **** MOVIES ****

        The root folder will be renamed in the following manner:

        <Movie_Name> (Movie_Year) [Resolution]   
        
        Example before renaming:

        |Ex.Machina.2014.2160p.HDR.AAC.5.1
        |....Ex.Machina.2014.2160p.HDR.AAC.5.1.mkv
        |....Ex.Machina.2014.2160p.HDR.AAC.5.1.srt
        
        After renaming, the folder structure will look like:
        
        |Ex Machina (2014) 1080p                        Top level directory
        |....Ex Machina (2014).mkv                      Video file
        |....Ex Machina (2014).en.srt                   Subtitle file

    .EXAMPLE

        **** TV SHOWS ****

        The root folder will be renamed in the following manner:

        <Show_Name> [Resolution]                                    
        Example: Game of Thrones 1080p                

        And the episode files will look like:

        Game of Thrones S01E01.mkv
        Game of Thrones S01E01.en.srt

        Season folders found within the parent directory will be renamed automatically.
        Regex is used to find matches for "Season <Number>" or "S<Number>" in the folder name.
        Each season *MUST* have its own folder (mini-series can be placed in a Season 1 folder):

        | Game.of.Thrones.1080p                             Top level directory
        |----Game.of.thrones.S01.1080p                      Folder name
        |--------S01E01.mkv....                             Episode files

        The new structure will look like:

        | Game of Thrones 1080p
        |----Season 1
        |--------Game of Thrones S01E01.mkv....

    .PARAMETER Path

        Choose a custom path to the directory where the files you want to rename are located. 

            WINDOWS - Pass the absolute path to the directory where your files are located. 

                .\PlexifyFiles -Path "C:\Users\User\Desktop\Movies"

            MAC / LINUX - Default path starts in the user's home directory, so the relative path is fine in most cases.
                          If you are having issues, try using the absolute path instead. 
                                  
                .\PlexifyFiles -Path '~/Movies'
                .\PlexifyFiles -Path '~/Desktop/Staging

    .PARAMETER Help

        Display help information from the command line.

    .NOTES
        Written by: Patrick Kelly
        Last Edited: 12/01/2020

        VERSION HISTORY:

        Version 1.0.0 - Initial Release
        Version 1.1.0 - Added support for renaming shows
        Version 1.1.1 - Fixed bug where regex match was sometimes ignored
        Version 1.2.1 - Added support for MacOS and Linux
        Version 1.2.2 - Fixed renaming issue when season number is 10 or greater
        Version 1.3.2 - Added -Help switch parameter and updated help info
        Version 1.4.2 - Split Confirm-Regex match into 2 separate functions
                        Improved console message descriptions with updated colors and formatting
        Version 1.4.3 - Fixed path bug where movie files were getting skipped over
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
$macDefaultPath = '~/Movies/Torrents'
$linuxDefaultPath = '~/Videos'
$windowsDefaultPath = "C:\Users\$env:USERNAME\Videos"

#Warning colors. Write-Warning acts strange on PS core
$warnColors = @{ForegroundColor = 'Yellow' ; BackgroundColor = 'Black' }
#Successful rename colors
$successColors = @{ ForegroundColor = "Green"; BackgroundColor = "Black" }
#Cool magenta color for starting script and path validation
$startColors = @{ ForegroundColor = "DarkMagenta"; BackgroundColor = "Black" }

##End Global Variables ##

#function that renames episode files. See .EXAMPLES for formatting
function Rename-SeasonFiles ($episodes, $seasonNum) {
    for ($i = 1; $i -le $episodes.length; $i++) {
        #Get the full extension. If an unsupported extension is used, returns $null
        $ext = Get-Extension $episodes[$i - 1].ToString()
        Write-Host "File name is:`t" $episodes[$i - 1]
        if ($ext) {
            if ($i -lt 10) { 
                if ([int]$seasonNum -lt 10) {
                    $episodeString = "$newFileName S0$seasonNum`E0$i.$ext"
                    Rename-Item -LiteralPath $episodes[$i - 1].FullName -NewName $episodeString
                }
                else {
                    $episodeString = "$newFileName S$seasonNum`E0$i.$ext"
                    Rename-Item -LiteralPath $episodes[$i - 1].FullName -NewName $episodeString
                }
            }
            #$i is greater than 10
            else {
                if ([int]$seasonNum -lt 10) {
                    $episodeString = "$newFileName S0$seasonNum`E$i.$ext"
                    Rename-Item -LiteralPath $episodes[$i - 1].FullName -NewName $episodeString
                }
                else {
                    $episodeString = "$newFileName S$seasonNum`E$i.$ext"
                    Rename-Item -LiteralPath $episodes[$i - 1].FullName -NewName $episodeString
                }
            }
            if ($?) {
                Write-Host $($episodes[$i - 1].Name) " renamed to: $episodeString" @successColors
                Write-Host ""
            }
        }
        else {
            Write-Host $episodes[$i - 1].Name " is using an unsupported file extension. Skipping...." `
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
            Throw "Could not resolve the default path for $OS. Check that the global variable path exists."
        }
    }
    #The user entered a specific path
    elseif (Test-Path -Path $path) {
        $rootDir = $path
        Write-Host "Path validation successful. Path is:`t$rootDir"`n @startColors
        return $rootDir
    }
    #the user supplied path could not be verified 
    else {
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

#Returns the new file name based on the matched expression
function Get-MediaFileName ($value, [switch]$RootFolder) {
    switch -Regex ($value) {
        #Matching movies
        "(?<title>.*)[\.\s\[\(]+(?<year>\d{4}).*[\.\s\[\(]+(?<res>\d{3,4}p)" {
            $name = ($Matches.title.Replace(".", " ")).Trim()
            $name = $name.Replace(":", " -")
            $year = "($($Matches.year))".Trim()
            $resolution = ($Matches.res).Trim()
            if ($RootFolder) {
                $title = "$name $year $resolution"
                return $title
            }
            else {
                $newFileName = "$name $year"
                return $newFileName
            }
        }
        #Matching tv shows
        "(?<title>.*)[\.\s\[\(]+(?<res>\d{3,4}p)" {
            if ($RootFolder) {
                $name = ($Matches.title.Replace(".", " ")).Trim()
                $name = $name.Replace(":", " -")
                $resolution = ($Matches.res).Trim()
                $title = "$name $resolution"
                return $title
            }
            else {
                $newFileName = "$($Matches.title)"
                return $newFileName
            }
        }
        default { return $null }
    }
}

#Returns the season number based on the matched expression
function Get-SeasonNumber ($value) {
    switch -Regex ($value) {
        "season (?<number>\d*)" {
            $seasonNum = "$($Matches.number)"
            return $seasonNum
        }
        "S(?<number>\d+)" {
            $seasonNum = $Matches.number
            if ($seasonNum -match "0(?<seasonNum>[1-9])") {
                Write-Host "Season number has a leading 0. Removing...`n" 
                $number = $Matches.seasonNum
                return $number
            }
            else { return $seasonNum }
        }
        default { return $null }
    }
}

#Renames the root directory for each movie/show. Returns the file name used in Rename-PlexFiles
function Rename-RootDirectory ([string]$path) {
    Get-ChildItem -Path $path -Directory | ForEach-Object {  
        $title = Get-MediaFileName $_.Name -RootFolder
        if ($title) {
            Rename-Item -LiteralPath $_.FullName -NewName $title
            if ($?) { Write-Host "Root directory $title renamed successfully" @successColors }
            else {
                $msg = "There was an issue renaming <$($_.Name)>. This usually happens when " + 
                "attempting to rename a folder with the same existing name, or if the folder " +
                "is using unsupported chracters.`n" +
                "Skipping folder rename..."
                Write-Host $msg @warnColors
            }
        } 
        else {
            $msg = "There was an issue renaming the root folder: $($_.Name). " +
            "This occurs when a reliable match cannot be made for movie/TV show " +
            "folder name in its current format.`nSkipping rename..."
            Write-Host $msg @warnColors
            continue
        }
    }
    Write-Host ""
}

#Main function
function Rename-PlexFiles ([string]$path) {
    #Recurse the root directories and subdirectories
    Get-ChildItem -Path $path -Directory | ForEach-Object {
        #match the new root folder name
        $newFileName = Get-MediaFileName $_.Name 
        if ($newFileName) { Write-host "Folder template name is:`t$newFileName" }
        else {
            $msg = "There was an issue getting the new file name for: $($_.Name). " +
            "This usually occurs when a reliable match cannot be made for movie/TV show " +
            "folder name in its current format.`nSkipping rename..."
            Write-Host $msg @warnColors
            continue
        }
        #Rename files inside parent folder
        Get-ChildItem -LiteralPath $_.FullName | ForEach-Object {
            #If the current object is a directory
            if (Test-Path -Path $_.FullName -PathType Container) {
                Write-host "Folder name is:`t`t`t$($_.Name)"
                #Skip rename for Featurettes/Extras folder if one is present
                if ($_.Name -match "Featurettes" -or $_.Name -match "Extras") {
                    Write-Host "Skipping Featurettes rename..."`n
                    continue
                }
                $seasonNumber = Get-SeasonNumber $_.Name
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
            elseif (Test-Path -LiteralPath $_.FullName -PathType Leaf) {
                Write-host "File name is:`t`t`t$($_.Name)"
                $ext = Get-Extension $_.Name
                if ($ext) {
                    Rename-Item -LiteralPath $_.FullName -NewName "$newFileName.$ext"
                    if ($?) { Write-Host "$($_.Name) renamed to: $newFileName.$ext"`n @successColors }
                    else {
                        $msg = "Failed to rename $($_.Name). This is usually caused by embedded special" +   
                        " characters in the file name, and are not always visible." 
                        Write-Host $msg @warnColors  
                    }
                }
                else {
                    Write-Host "$($_.Name) is using an unsupported file extension. Skipping...."`n @warnColors
                }  
            }
        }
    }
}

###################################### Main script logic ######################################

Write-Host "`nStarting script..." @startColors

$validatedPath = Set-Path $Path
Rename-RootDirectory $validatedPath
Rename-PlexFiles $validatedPath

Read-Host -Prompt "Press Enter to exit"
