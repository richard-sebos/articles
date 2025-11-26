# PowerShell Syntax Cheat Sheet
## For Linux Admins Transitioning to Windows

---

## Discovery & Help

```powershell
# Get help (man page equivalent)
Get-Help Get-Process
Get-Help Get-Process -Examples
Get-Help Get-Process -Full
Get-Help about_*                    # List conceptual help topics

# Find commands
Get-Command                         # List all commands
Get-Command *Service*               # Find service-related commands
Get-Command -Verb Get               # All Get- commands
Get-Command -Noun Process           # All *-Process commands

# Explore object members (properties & methods)
Get-Process | Get-Member
Get-Process | Get-Member -MemberType Property
Get-Process | Get-Member -MemberType Method
Get-Service | Get-Member -Name "*status*"

# See actual values
Get-Process | Select-Object -First 1 | Format-List *
```

---

## Variables & Data Types

```powershell
# Variables (always use $ prefix)
$name = "server01"
$count = 42
$enabled = $true                    # Boolean: $true or $false
$empty = $null

# Type declaration (optional but useful)
[string]$server = "web01"
[int]$port = 443
[datetime]$date = Get-Date

# Arrays
$servers = @("web01", "web02", "db01")
$servers = 1..10                    # Range operator
$servers[0]                         # Access by index
$servers.Count                      # Array length
$servers += "web03"                 # Add element

# Hashtables (key-value pairs)
$config = @{
    Server = "web01"
    Port = 443
    Enabled = $true
}
$config.Server                      # Access by key
$config["Server"]                   # Alternative syntax
$config.Keys                        # Get all keys
$config.Values                      # Get all values

# ArrayList (more efficient for large collections)
$list = [System.Collections.ArrayList]@()
$list.Add("item1")
```

---

## Operators

### Comparison Operators (NOT ==, !=, etc.!)
```powershell
-eq         # Equal
-ne         # Not equal
-gt         # Greater than
-ge         # Greater than or equal
-lt         # Less than
-le         # Less than or equal
-like       # Wildcard matching
-notlike    # Wildcard not matching
-match      # Regex matching
-notmatch   # Regex not matching
-contains   # Collection contains value
-in         # Value in collection

# Case-sensitive versions (add 'c' prefix)
-ceq, -cne, -clike, -cmatch

# Examples
if ($count -eq 10) { }
if ($name -like "web*") { }
if ($email -match ".*@domain\.com$") { }
if ($servers -contains "web01") { }
if ("web01" -in $servers) { }
```

### Logical Operators
```powershell
-and        # Logical AND (not &&)
-or         # Logical OR (not ||)
-not        # Logical NOT (can also use !)
-xor        # Exclusive OR

# Examples
if ($count -gt 5 -and $enabled) { }
if (-not $error -or $force) { }
```

### Arithmetic Operators
```powershell
+           # Addition (also string concatenation)
-           # Subtraction
*           # Multiplication
/           # Division
%           # Modulus

$total = $count * 2 + 5
```

---

## String Handling

```powershell
# Double quotes - variable expansion
$name = "server01"
"Server: $name"                     # Output: Server: server01

# Single quotes - literal
'Server: $name'                     # Output: Server: $name

# Subexpressions for complex expressions
"Total: $($servers.Count) servers"
"CPU: $($process.CPU * 100)%"

# Multi-line strings (here-strings)
$text = @"
Line 1
Line 2: $variable
Line 3
"@

# String methods
$name.ToUpper()
$name.ToLower()
$name.Replace("01", "02")
$name.Substring(0, 6)
$name.Split("-")
$name.Trim()
"web01,web02,web03".Split(",")

# String formatting
"Server: {0}, Port: {1}" -f $server, $port
```

---

## Conditionals

```powershell
# If/ElseIf/Else
if ($count -gt 10) {
    Write-Host "Large"
} elseif ($count -gt 5) {
    Write-Host "Medium"
} else {
    Write-Host "Small"
}

# Switch statement
switch ($status) {
    "Running" { Write-Host "Active" }
    "Stopped" { Write-Host "Inactive" }
    default { Write-Host "Unknown" }
}

# Switch with wildcard matching
switch -Wildcard ($name) {
    "web*" { Write-Host "Web server" }
    "db*" { Write-Host "Database server" }
}

# Ternary operator (PowerShell 7+)
$result = $count -gt 5 ? "High" : "Low"
```

---

## Loops

```powershell
# ForEach loop
foreach ($server in $servers) {
    Test-Connection $server -Count 1
}

# For loop (traditional)
for ($i = 0; $i -lt 10; $i++) {
    Write-Host "Number: $i"
}

# While loop
while ($count -lt 10) {
    $count++
}

# Do-While loop
do {
    $count++
} while ($count -lt 10)

# Do-Until loop
do {
    $count++
} until ($count -eq 10)

# Break and Continue
foreach ($server in $servers) {
    if ($server -eq "skip") { continue }
    if ($server -eq "stop") { break }
    Write-Host $server
}
```

---

## Pipeline Operations

```powershell
# The pipeline passes objects, not text!
Get-Process | Where-Object {$_.CPU -gt 100}

# Where-Object (filtering)
Get-Service | Where-Object {$_.Status -eq "Running"}
Get-Process | Where-Object Name -Like "chrome*"      # Simplified syntax
Get-Process | ? {$_.CPU -gt 10}                      # ? is alias

# Select-Object (choose properties/limit results)
Get-Process | Select-Object Name, CPU, Id
Get-Process | Select-Object -First 10
Get-Process | Select-Object -Last 5
Get-Process | Select-Object -Unique
Get-Process | Select-Object Name, @{Name="MemoryMB"; Expression={$_.WS / 1MB}}

# ForEach-Object (process each object)
Get-Service | ForEach-Object { $_.Name.ToUpper() }
Get-Service | % { $_.Stop() }                        # % is alias

# Sort-Object
Get-Process | Sort-Object CPU -Descending
Get-Process | Sort-Object Name, CPU

# Group-Object
Get-Process | Group-Object ProcessName
Get-Service | Group-Object Status

# Measure-Object (statistics)
Get-Process | Measure-Object CPU -Sum -Average -Maximum
Get-ChildItem | Measure-Object Length -Sum

# $_ represents current pipeline object
Get-Process | Where-Object {$_.CPU -gt 100} | ForEach-Object {
    Write-Host "$($_.Name) using $($_.CPU) CPU"
}
```

---

## Functions

```powershell
# Basic function
function Get-ServerInfo {
    param(
        [string]$ServerName
    )
    Test-Connection $ServerName -Count 1
}

# Function with parameters and validation
function Get-ServiceInfo {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("Running", "Stopped")]
        [string]$Status = "Running"
    )
    
    Get-Service -Name $Name | Where-Object Status -eq $Status
}

# Function with pipeline input
function Stop-MyService {
    param(
        [Parameter(ValueFromPipeline=$true)]
        [string]$ServiceName
    )
    
    process {
        Stop-Service -Name $ServiceName -WhatIf
    }
}

# Usage
Get-ServerInfo -ServerName "web01"
"spooler", "w32time" | Stop-MyService

# Return values (implicit or explicit)
function Get-Double {
    param([int]$Number)
    return $Number * 2
    # Or just: $Number * 2
}
```

---

## Error Handling

```powershell
# Try-Catch-Finally
try {
    Get-Content "C:\nonexistent.txt" -ErrorAction Stop
    # Note: -ErrorAction Stop makes non-terminating errors terminating
} catch {
    Write-Warning "Error occurred: $($_.Exception.Message)"
    Write-Host "Error details: $($_.ErrorDetails)"
} finally {
    Write-Host "Cleanup code here"
}

# Catch specific exception types
try {
    [int]"not a number"
} catch [System.InvalidCastException] {
    Write-Host "Invalid cast"
} catch {
    Write-Host "Other error"
}

# Error action preferences
Get-Service -Name "NoSuchService" -ErrorAction SilentlyContinue
Get-Service -Name "NoSuchService" -ErrorAction Stop
Get-Service -Name "NoSuchService" -ErrorAction Ignore

# Global error preference
$ErrorActionPreference = "Stop"         # All errors are terminating

# Check last error
$Error[0]                               # Most recent error
$Error.Clear()                          # Clear error history
```

---

## Working with Files & Paths

```powershell
# Navigation
Get-Location                            # pwd
Set-Location C:\Windows                 # cd
Push-Location C:\Temp                   # pushd
Pop-Location                            # popd

# File operations
Get-ChildItem                           # ls
Get-ChildItem -Recurse                  # ls -R
Get-ChildItem -Filter "*.log"
Get-ChildItem -Path C:\ -Include *.txt -Recurse

Test-Path "C:\file.txt"                 # Check if exists
New-Item "C:\file.txt" -ItemType File
New-Item "C:\folder" -ItemType Directory
Copy-Item "source.txt" "dest.txt"
Move-Item "old.txt" "new.txt"
Remove-Item "file.txt"
Remove-Item "folder" -Recurse -Force

# File content
Get-Content "file.txt"                  # cat
Get-Content "file.txt" -Tail 10         # tail
Get-Content "file.txt" -Wait            # tail -f
Set-Content "file.txt" "New content"
Add-Content "file.txt" "Append this"
"Text" | Out-File "file.txt"

# Path manipulation
Join-Path "C:\folder" "file.txt"
Split-Path "C:\folder\file.txt" -Parent
Split-Path "C:\folder\file.txt" -Leaf
[System.IO.Path]::GetExtension("file.txt")
```

---

## Common System Administration Tasks

```powershell
# Processes
Get-Process
Get-Process -Name "chrome"
Stop-Process -Name "notepad"
Stop-Process -Id 1234
Start-Process "notepad.exe"

# Services
Get-Service
Get-Service -Name "spooler"
Start-Service -Name "spooler"
Stop-Service -Name "spooler"
Restart-Service -Name "spooler"
Set-Service -Name "spooler" -StartupType Automatic

# Event logs
Get-EventLog -LogName System -Newest 10
Get-EventLog -LogName Application -EntryType Error -Newest 20
Get-WinEvent -LogName System -MaxEvents 10

# Registry
Get-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion"
Set-ItemProperty -Path "HKLM:\..." -Name "Setting" -Value "Value"

# Network
Test-Connection "server01" -Count 4         # ping
Test-NetConnection "server01" -Port 443
Get-NetIPAddress
Get-NetAdapter

# Computer info
Get-ComputerInfo
Get-WmiObject Win32_OperatingSystem
Get-CimInstance Win32_ComputerSystem
```

---

## Remoting

```powershell
# Enable remoting (run on target)
Enable-PSRemoting -Force

# Execute command on remote system
Invoke-Command -ComputerName "server01" -ScriptBlock {
    Get-Service
}

# With credentials
$cred = Get-Credential
Invoke-Command -ComputerName "server01" -Credential $cred -ScriptBlock {
    Get-Process
}

# Interactive session
Enter-PSSession -ComputerName "server01"
Exit-PSSession

# Persistent session
$session = New-PSSession -ComputerName "server01"
Invoke-Command -Session $session -ScriptBlock { Get-Service }
Remove-PSSession $session
```

---

## Parameter Splatting

```powershell
# Instead of this:
Get-Service -Name "spooler" -ComputerName "server01" -ErrorAction Stop

# Use splatting (note @ instead of $):
$params = @{
    Name = "spooler"
    ComputerName = "server01"
    ErrorAction = "Stop"
}
Get-Service @params

# Useful for complex commands
$mailboxParams = @{
    Identity = "user@domain.com"
    Archive = $true
    RetentionPolicy = "Default"
    ErrorAction = "Stop"
}
Set-Mailbox @mailboxParams
```

---

## Output & Formatting

```powershell
# Write output
Write-Host "User message"               # Console only (avoid in scripts)
Write-Output "Object to pipeline"       # Standard output
Write-Verbose "Verbose info" -Verbose
Write-Warning "Warning message"
Write-Error "Error message"

# Formatting
Get-Process | Format-Table              # ft alias
Get-Process | Format-List               # fl alias
Get-Process | Format-Wide
Get-Process | Format-Table Name, CPU, Id -AutoSize

# Export
Get-Process | Export-Csv "processes.csv" -NoTypeInformation
Get-Process | Export-Clixml "processes.xml"
Get-Process | ConvertTo-Json | Out-File "processes.json"

# Import
Import-Csv "file.csv"
Import-Clixml "file.xml"
Get-Content "file.json" | ConvertFrom-Json
```

---

## Common Aliases (Bash-like)

```powershell
# Directory operations
ls          # Get-ChildItem
dir         # Get-ChildItem
cd          # Set-Location
pwd         # Get-Location
mkdir       # New-Item -ItemType Directory
rm          # Remove-Item
cp          # Copy-Item
mv          # Move-Item

# File content
cat         # Get-Content
type        # Get-Content

# Process/Service
ps          # Get-Process
kill        # Stop-Process

# Other
man         # Get-Help
cls         # Clear-Host
history     # Get-History

# See all aliases
Get-Alias
Get-Alias -Definition Get-ChildItem
```

---

## Execution Policy

```powershell
# Check current policy
Get-ExecutionPolicy

# Set policy (run as Administrator)
Set-ExecutionPolicy RemoteSigned        # Allow local scripts
Set-ExecutionPolicy Unrestricted        # Allow all scripts
Set-ExecutionPolicy Restricted          # Block all scripts

# Bypass for single session
powershell.exe -ExecutionPolicy Bypass -File "script.ps1"
```

---

## Script Structure

```powershell
# Save as .ps1 file

# Parameters at top
param(
    [Parameter(Mandatory=$true)]
    [string]$ServerName,
    
    [Parameter(Mandatory=$false)]
    [int]$Count = 5
)

# Functions
function Get-Status {
    param([string]$Name)
    # Function code
}

# Main script logic
try {
    $result = Get-Status -Name $ServerName
    Write-Output "Result: $result"
} catch {
    Write-Error "Script failed: $_"
    exit 1
}
```

---

## Quick Tips

1. **Tab completion** works for commands, parameters, and file paths - use it!
2. **`$_`** is the current pipeline object (like Perl)
3. **Case insensitive** by default (files, strings, operators)
4. **Semicolons optional** at line end (but can use for multiple commands on one line)
5. **Backtick `` ` ``** is line continuation character (like `\` in bash)
6. **Comments**: `#` for single line, `<# ... #>` for multi-line
7. **PowerShell 7+** (Core) is cross-platform and recommended for new work
8. **Use `Get-Command`, `Get-Help`, and `Get-Member`** constantly!

---

## Useful for Exchange/M365 Work

```powershell
# Connect to Exchange Online
Connect-ExchangeOnline

# Get mailboxes
Get-Mailbox -ResultSize Unlimited
Get-Mailbox -Filter {RecipientTypeDetails -eq "UserMailbox"}

# Get mailbox details
Get-Mailbox -Identity "user@domain.com" | Select-Object *

# Mailbox permissions
Get-MailboxPermission -Identity "shared@domain.com"
Add-MailboxPermission -Identity "shared@domain.com" -User "user@domain.com" -AccessRights FullAccess

# Distribution groups
Get-DistributionGroup
Get-DistributionGroupMember -Identity "group@domain.com"

# Export results
Get-Mailbox | Select-Object Name, PrimarySmtpAddress, WhenCreated | 
    Export-Csv "mailboxes.csv" -NoTypeInformation

# Disconnect
Disconnect-ExchangeOnline -Confirm:$false
```

---

## Resources

- `Get-Help about_*` - Built-in conceptual help topics
- `https://docs.microsoft.com/powershell` - Official documentation
- `$PSVersionTable` - Check your PowerShell version
