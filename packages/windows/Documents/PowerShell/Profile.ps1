<#
.NOTES
    ===========================================================================
    Created on:   August 2021
    Created by:   Joel Van Eenwyk
    Filename:     Profile.ps1
    ===========================================================================
.DESCRIPTION
    Set the font and theme. This file should have been been linked to the
    following paths:

        - C:\Users\jovaneen\Documents\PowerShell\Profile.ps1
        - C:\Users\jovaneen\OneDrive - Microsoft\Documents\PowerShell\Profile.ps1
#>

Function Get-CurrentEnvironment {
    <#
    .SYNOPSIS
        Split $env:Path into an array.
    .DESCRIPTION
        Handles the following stretch cases:

            1) Folders ending in a backslash
            2) Double-quoted folders
            3) Folders with semicolons
            4) Folders with spaces
            5) Double-semicolons I.e. blanks
    .EXAMPLE
        PATH=C:WINDOWS;"C:Path with semicolon; in the middle";"E:Path with semicolon at the end;";;C:Program Files;'

        Will be converted to an array:

            - C:\Windows
            - C:\Path with semicolon; in the middle
            - C:\C:Program Files
    .NOTES
        Originally created on 2018/01/30 by Chad.Simmons@CatapultSystems.com
    #>

    $PathArray = @()
    $PathString = ""

    if ($null -ne $env:Path) {
        $PathString = $env:Path.ToString().TrimEnd(';')
    }

    # Remove a trailing semicolon from the path then split it into an array using a double-quote
    # as the delimiter keeping the delimiter
    $PathString -split '(?=["])' | ForEach-Object {
        If ($_ -eq '";') {
            # throw away a blank line
        }
        ElseIf ($_.ToString().StartsWith('";')) {
            # if line starts with "; remove the "; and any trailing backslash
            $PathArray += ($_.ToString().TrimStart('";')).TrimEnd('')
        }
        ElseIf ($_.ToString().StartsWith('"')) {
            # if line starts with " remove the " and any trailing backslash
            $PathArray += ($_.ToString().TrimStart('"')).TrimEnd('') #$_ + '"'
        }
        Else {
            # split by semicolon and remove any trailing backslash
            $_.ToString().Split(';') | ForEach-Object {
                If ($_.Length -gt 0) {
                    $PathArray += $_.TrimEnd('')
                }
            }
        }
    }

    Return $PathArray
}

Function Get-RealScriptPath() {
    param(
        [string] $ScriptPath
    )

    # Attempt to extract link target from script pathname
    $Root = (Get-Item $ScriptPath).Directory.FullName
    $LinkTarget = Get-Item $ScriptPath | Select-Object -ExpandProperty Target

    # If the script is not a link just return the script path as is
    If (-Not($LinkTarget)) {
        return $ScriptPath
    }

    # Check if the path is rooted / absolute. If so return that.
    $IsAbsolute = [System.IO.Path]::IsPathRooted($LinkTarget)
    if ($IsAbsolute) {
        return $LinkTarget
    }

    # We now know that the script was launched from a link and the link target is
    # probably relative depending on how accurate IsPathRooted() is. Try to make an
    # absolute path by merging the script directory and the link target and then
    # normalize it through Resolve-Path.
    $joined = Join-Path $Root $LinkTarget
    $resolved = Resolve-Path -Path $joined
    $resolved = Get-RealScriptPath $resolved

    return $resolved
}

Function Get-ScriptDirectory() {
    $ScriptPath = Get-RealScriptPath $PSCommandPath
    $ScriptDir = Split-Path -Parent $ScriptPath
    return $ScriptDir
}

Function global:init() {
    param(
        [string] $ArgumentList
    )

    $ScriptPath = Get-ScriptDirectory
    $Path = Resolve-Path "$ScriptPath\Invoke-Init.ps1"
    Write-Host "##[cmd] $Path $ArgumentList"
    & $Path $ArgumentList
}

function Get-NormalizedPath($file) {
    $resolvedPath = Resolve-Path -ErrorAction SilentlyContinue -Path "$file"
    $path = $null

    if ($null -ne $resolvedPath) {
        $path = $resolvedPath.Path
        $path = $path.TrimEnd("\\")
        $path = $path.TrimEnd("/")

        $item = Get-Item $path
        if ($null -ne $item) {
            $path = $item.FullName
        }
    }

    return $path;
}

Function Update-Environment() {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    $ScriptPath = Get-ScriptDirectory
    $root = Resolve-Path -Path "$ScriptPath\..\.."

    Write-Host "Root: $root"

    $environmentVariables = @()
    $environmentVariables += "$root"
    $environmentVariables += "$root\source\windows"
    $environmentVariables += "$Env:UserProfile\.local\bin"
    $environmentVariables += "$Env:UserProfile\.local\go\bin"
    $environmentVariables += "C:\Program Files (x86)\GnuPG\bin"
    $environmentVariables += "C:\Program Files\Git\bin"
    #$environmentVariables += "$Env:UserProfile\scoop\apps\msys2\current\mingw64"
    $environmentVariables += $(Get-CurrentEnvironment)
    $environmentVariables += "$Env:UserProfile\scoop\shims"

    $environmentPaths = @()
    $environmentVariables | ForEach-Object {
        $environmentPath = "$_"
        try {
            $resolvedPath = Get-NormalizedPath "$_"

            if (($resolvePath -Contains "msys2") -and ($resolvePath -Contains "usr\bin")) {
                $resolvedPath = $null
            }

            if ($null -ne $resolvedPath) {
                $environmentPaths += $resolvedPath
            }
        }
        catch {
            Write-Host "Skipped invalid path: '$environmentPath'"
        }
    }

    try {
        $environmentPaths = $environmentPaths | Select-Object -Unique
        New-Item -Path "$ENV:UserProfile\.local\bin" -type directory -ErrorAction SilentlyContinue | Out-Null
        $Env:Path = $($environmentPaths -join ";")
        $Env:MYCELIO_ROOT = $root
        $Env:PATHEXT=".COM;.EXE;.BAT;.CMD;.VBS;.VBE;.JS;.JSE;.WSF;.WSH;.MSC"
        $Env:HOME = $ENV:UserProfile
    }
    catch [Exception] {
        Write-Host "Failed to setup environment.", $_.Exception.Message
    }
}

Function Update-Terminal() {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    # WARNING: You appear to have an unsupported Git distribution; setting
    # $GitPromptSettings.AnsiConsole = $false. posh-git recommends Git for Windows.
    #
    # See https://github.com/dahlbyk/posh-git/issues/860
    $Env:POSHGIT_CYGWIN_WARNING = 'off'

    try {
        Import-Module posh-git -ErrorAction SilentlyContinue >$null
    }
    catch {
        Write-Host "Failed to import 'posh-git' module."
    }

    try {
        Import-Module oh-my-posh -ErrorAction SilentlyContinue >$null
        if ($PSCmdlet.ShouldProcess('Terminal')) {
            Set-PoshPrompt -ErrorAction SilentlyContinue -Theme "stelbent.minimal"
        }
    }
    catch {
        Write-Host "Failed to set 'oh-my-posh' prompt."
    }

    try {
        $fontName = "JetBrainsMono NF"
        Import-Module WindowsConsoleFonts -ErrorAction SilentlyContinue >$null
        if ($?) {
            $currentFont = Get-ConsoleFont -ErrorAction SilentlyContinue
            if (($null -ne $currentFont) -and ($currentFont.Name -ne $fontName) -and $PSCmdlet.ShouldProcess('Terminal')) {
                Set-ConsoleFont "$fontName" >$null
                Write-Host "Previous font: '$currentFont.Name'"
                Write-Host "Updated font: '$fontName'"
            }
        }

        Import-Module Terminal-Icons -ErrorAction SilentlyContinue >$null
        if ($? -and $PSCmdlet.ShouldProcess('Terminal')) {
            Set-TerminalIconsTheme -ColorTheme DevBlackOps -ErrorAction SilentlyContinue -IconTheme DevBlackOps
        }
    }
    catch [Exception] {
        Write-Host "Failed to set console font and theme.", $_.Exception.Message
    }
}

Update-Environment
Update-Terminal
Write-Host "Initialized Mycelio environment."

#
# NOTE: This script is called in each sub-shell as well so reduce noise by not calling anything
# that may write to the console host.
#
