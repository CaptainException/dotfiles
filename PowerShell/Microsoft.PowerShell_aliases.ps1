# This Powershell-Alias-File is originally made by CaptainException (github.com/CaptainException/dotfiles)
# Licensed under the MIT License (https://github.com/MeroFuruya/dotfiles/blob/main/LICENSE)

########################
## Command Shorthands ##
########################

# exit with q
Function Exit-Shell { exit }
New-Alias -Name q -Value Exit-Shell

# clear screen
New-Alias -Name c -Value Clear-Host

# where
Remove-Alias where -Force
New-Alias -Name where -Value where.exe

# cd into home directory
Function Set-LocationToHome { Set-Location ~ }
New-Alias -Name cdh -Value Set-LocationToHome

# git
New-Alias -Name g -Value git

# ntop -> top
New-Alias -Name top -Value ntop

# ConvertFrom-Json -> json
New-Alias -Name json -Value ConvertFrom-Json

# ForEach-Object -> fe
New-Alias -Name fe -Value ForEach-Object

###################################################
## Run commands for applications outside of PATH ##
###################################################

# open notepad++
New-Alias -Name npp -Value "C:\Program Files\Notepad++\notepad++.exe"

# open sublime text
$sublime = "C:\Program Files\Sublime Text\sublime_text.exe"
New-Alias -Name sublime -Value $sublime
New-Alias -Name subl -Value $sublime

########################
## Functional Aliases ##
########################

# print working directory
Function Get-WorkingDirectory { (Get-Location).Path }
Set-Alias -Name pwd -Value Get-WorkingDirectory

# copy working directory
Function Get-WorkingDirectory {
    param( [switch]$cd )
    # prepend cd command if the param is used
    $CommandString = if ($cd) { "cd " } + (Get-Location).Path
    $CommandString | Set-Clipboard
}
New-Alias -Name cwd -Value Get-WorkingDirectory
New-Alias -Name ccwd -Value "Get-WorkingDirectory -cd"

# open directory from clipboard in explorer 
# TODO add support for reading from stdout
Function Enter-DirectoryFromClipboardInExplorer { explorer (Get-Clipboard) }
New-Alias -Name explore -Value Enter-DirectoryFromClipboardInExplorer

# cd into GitHub folder
Function Set-WorkingDirectoryToGithub { Set-Location "~\Documents\GitHub\" }
New-Alias -Name cdgh -Value Set-WorkingDirectoryToGithub

# Reload profile by spawning new shell
Function Restart-Session { try { pwsh -NoLogo } catch {} finally { exit } }
New-Alias -Name reload -Value Restart-Session
New-Alias -Name rs -Value Restart-Session

# open aliases in VS Code to edit them
Function Show-AliasesInVSCode { code $ALIASES }
New-Alias -Name aliases -Value Show-AliasesInVSCode

# open aliases in sublime to edit them #TODO merge with Show-AliasesInVSCode function
Function Show-AliasesInSublime { Invoke-Expression -Command "$SUBLIME $ALIASES" }
New-Alias -Name subl_aliases -Value Show-AliasesInSublime

# winget search
Function Invoke-WingetSearch { winget search $args }
New-Alias -Name ws -Value Invoke-WingetSearch

# winget install
Function Invoke-WingetInstall { winget install $args }
New-Alias -Name wi -Value Invoke-WingetInstall

# winget upgrade
Function Invoke-WingetUpgrade { winget upgrade $args }
New-Alias -Name wu -Value Invoke-WingetUpgrade

# winget uninstall (remove)
Function Invoke-WingetRemove { winget uninstall $args }
New-Alias -Name wr -Value Invoke-WingetRemove

# sudo
New-Alias -Name su -Value gsudo
New-Alias -Name sudo -Value gsudo
Function Invoke-SudoWithUserProfile{ gsudo --loadProfile $args }
New-Alias -Name sudolp -Value Invoke-SudoWithUserProfile

function Invoke-LastCommandAsAdmin { gsudo (Get-History -Count 1).CommandLine }
New-Alias -Name resudo -Value Invoke-LastCommandAsAdmin

# open profile in VS Code
function Enter-PSProfile{ code $PROFILE }
New-Alias -Name profile -Value Enter-PSProfile
