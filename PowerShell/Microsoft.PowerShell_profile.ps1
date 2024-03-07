# This Powershell-Profile is originally made by Marius Kehl (github.com/MeroFuruya/dotfiles)
# Licensed under the MIT License (https://github.com/MeroFuruya/dotfiles/blob/main/LICENSE)

# tools used:
# - git -> winget install Git-Git
# - npm
# - GitHub-CLI -> winget install GitHub.cli
# - notepad++
# - oh-my-posh -> Install-Module oh-my-posh
# - wsl2 (lsd-rs, Midnight Commander, jq)
# - ntop
# - Microsoft Powertoys

# Powershell-Modules used:
# - posh-git -> Install-Module posh-git
# - npm-completion -> Install-Module npm-completion
# - updated PSReadline -> "Install-Module -Force PSReadLine"

## PowerToys CommandNotFound module
Import-Module "C:\Program Files\PowerToys\WinUI3Apps\..\WinGetCommandNotFound.psd1"

## fnm config
fnm env --use-on-cd | Out-String | Invoke-Expression

## THEME

# oh-my-posh
Invoke-Expression -Command $(oh-my-posh completion powershell | Out-String)
# oh-my-posh --init --shell pwsh --config "$env:POSH_THEMES_PATH/catppuccin_frappe.omp.json" | Invoke-Expression
oh-my-posh --init --shell pwsh | Invoke-Expression
Set-PSReadlineOption -ExtraPromptLineCount 1 # count of lines for oh-my-posh

## PSReadline
Import-Module PSReadline

# Autocompletion
Remove-PSReadlineKeyHandler -Key Tab
Set-PSReadlineKeyHandler -Key Tab -Function Complete
Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward

# PSReadline
Set-PSReadlineOption -PredictionSource History
Set-PSReadlineOption -PredictionViewStyle Inline
Set-PSReadlineOption -WordDelimiters " /\()`"'-.,:;<>~!@#$%^&*|+=[]{}~?│"
Set-PSReadlineOption -BellStyle None
Set-PSReadlineOption -CommandValidationHandler { $true }
Set-PSReadlineOption -ShowToolTips
Set-PSReadlineOption -HistorySaveStyle SaveIncrementally

## AUTOCOMPLETION

# Github autocomplete
Invoke-Expression -Command $(gh completion -s powershell | Out-String)

# git autocomplete
$global:GitPromptSettings = $false
Import-Module posh-git

# npm autocomplete
Import-Module npm-completion

# AWS autocomplete
if (Get-Command aws_completer.exe -ErrorAction SilentlyContinue) {
  Register-ArgumentCompleter -Native -CommandName aws -ScriptBlock {
    param($commandName, $wordToComplete, $cursorPosition)
    $env:COMP_LINE=$wordToComplete
    if ($env:COMP_LINE.Length -lt $cursorPosition){
      $env:COMP_LINE=$env:COMP_LINE + " "
    }
    $env:COMP_POINT=$cursorPosition
    aws_completer.exe | ForEach-Object {
      [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
    Remove-Item Env:\COMP_LINE
    Remove-Item Env:\COMP_POINT
  }
}

## ALIASES
$ALIASES = "$PSScriptRoot\Microsoft.PowerShell_aliases.ps1"

# load aliases from the alias file(s)
. $ALIASES

# create new alias and save it to the alias file(s)
function New-PersistentAlias {
  # TODO: Add -Force parameter to overwrite existing aliases using Set-Alias
  param(
    [Parameter(Mandatory = $true)]
    [string]$aliasName,
    [Parameter(Mandatory = $true)]
    [string]$aliasCommand,
    [Parameter(Mandatory = $false)]
    [string]$aliasDescription
  )
  # Create a function name based on the alias name
  $functionName = "_$aliasName"
  # Define the function and alias lines
  $functionLine = "function $functionName { $aliasCommand }"
  $aliasLine = "New-Alias -Name $aliasName -Value '$functionName'"
  
  # Add the alias to the alias file
  Add-Content -Path $ALIASES -Value ""
  if ($aliasDescription) {
    Add-Content -Path $ALIASES -Value "# $aliasDescription"
  }
  Add-Content -Path $ALIASES -Value $functionLine
  Add-Content -Path $ALIASES -Value $aliasLine
    
  # also create the alias for the current session
  $functionLine = "function global:$functionName { $aliasCommand }" 
  Invoke-Expression -Command $functionLine
  Invoke-Expression -Command "$aliasLine -Scope Global"
}
Set-Alias -Name alias -Value New-PersistentAlias

## WSL ALIASES

# The commands to import.
$wslCommands = @(
  "awk", "grep", "head", "man",
  "sed", "seq", "ssh", "tail",
  "vim", "lsd", "mc", #"nano",
  "cat", "sh", "bat", #"sudo",
  "less", "bash", "jq"
)

# Register a function for each command.
$wslCommands | ForEach-Object { Invoke-Expression @"
Remove-Item Alias:$_ -Force -ErrorAction Ignore
function global:$_() {
    for (`$i = 0; `$i -lt `$args.Count; `$i++) {
        # If a path is absolute with a qualifier (e.g. C:), run it through wslpath to map it to the appropriate mount point.
        if (Split-Path `$args[`$i] -IsAbsolute -ErrorAction SilentlyContinue) {
            `$args[`$i] = Format-WslArgument (wsl.exe wslpath (`$args[`$i] -replace "\\", "/"))
        # If a path is relative, the current working directory will be translated to an appropriate mount point, so just format it.
        } elseif (Test-Path `$args[`$i] -ErrorAction SilentlyContinue) {
            `$args[`$i] = Format-WslArgument (`$args[`$i] -replace "\\", "/")
        }
    }

    if (`$input.MoveNext()) {
        `$input.Reset()
        `$inputFile = "/tmp/wslPipe.`$(New-Guid)"
        `$input | Out-String -Stream | wsl -e bash -c "cat > `$inputFile"
        wsl.exe -e bash -c "cat `$inputFile | $_ `$(`$args -split ' ') && rm `$inputFile"
    } else {
        wsl.exe $_ (`$args -split ' ')
    }
}
"@
}

# Helper function to escape characters in arguments passed to WSL that would otherwise be misinterpreted.
function global:Format-WslArgument([string]$arg, [bool]$interactive) {
  if ($interactive -and $arg.Contains(" ")) {
    return "'$arg'"
  }
  else {
    return ($arg -replace " ", "\ ") -replace "([()|])", ('\$1', '`$1')[$interactive]
  }
}

## FUNCTIONS

# update profile
Function Update-Profile {
  Invoke-WebRequest -Uri https://raw.githubusercontent.com/MeroFuruya/dotfiles/main/powershell/Microsoft.PowerShell_profile.ps1 -OutFile $PROFILE
  Write-Host "New Profile is Downloaded. Will be available on next restart of PowerShell :)"
}

# convert encoding
Function Convert-Encoding {
  param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateSet("UTF8", "UTF7", "UTF32", "ASCII", "Unicode", "BigEndianUnicode", "Default", "OEM", "UTF8NoBOM", "UTF8BOM", "UTF7NoBOM", "UTF7BOM", "UTF32NoBOM", "UTF32BOM")]
    [string]$Encoding,
    [Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [string]$Path
  )
  $files = Get-ChildItem -Path $Path -Recurse -File
  foreach ($file in $files) {
    $text = Get-Content $file
    Set-Content -Encoding $Encoding -Force -Path $file -Value $text
  }
}

Function Update-wslLsd {
  if (-not(Get-Command aws_completer.exe -ErrorAction SilentlyContinue)) {
    throw "You dont have GitHub-cli installed. This is necessary for this Action"
  }
  gh auth status -h github.com -t > Out-Null
  if ($LASTEXITCODE -ne 0) {
    throw "make sure you are logged into GitHub, use ""gh auth login"" to do so!"
  }
  (gh api $($urls = @();$page=1;while($urls.Length -eq 0){(gh api repos/lsd-rs/lsd/actions/artifacts?page=$page|ConvertFrom-Json).artifacts|ForEach-Object{if($_.name -eq "lsd-x86_64-unknown-linux-gnu"){$urls=$urls+,$_.archive_download_url}};$page++};$urls[0]))|wsl -e bash -c "cat > /bin/lsd"
}
