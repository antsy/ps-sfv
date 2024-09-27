param (
    [Parameter(Position = 0, Mandatory = $true)]
    [string]$sfvFilePath
)

$crc32 = add-type '
[DllImport("ntdll.dll")]
public static extern uint RtlComputeCrc32(uint dwInitial, byte[] pData, int iLen);
' -Name crc32 -PassThru

# Resolve the .sfv file path to an absolute path relative to the script's execution folder
$sfvFilePath = Join-Path -Path $PSScriptRoot -ChildPath $sfvFilePath

# Check if the .sfv file exists
if (-not (Test-Path -Path $sfvFilePath)) {
    Write-Host "The file '$sfvFilePath' does not exist."
    exit 2
}

# Initialize an array to hold the file paths and checksums
$fileChecksums = @()

# Read the .sfv file line by line
Get-Content -Path $sfvFilePath | ForEach-Object {
    $line = $_.Trim()
    Write-Debug "Processing line: '$line'"

    # Skip comment lines
    if ($line -notlike ';*') {
        # Use regex to split the line into file path and checksum
        if ($line -match '^(.*)\s+([A-Fa-f0-9]{8})$') {
            $filePath = $matches[1]
            $checksum = $matches[2]

            $fileChecksums += [PSCustomObject]@{
                FilePath = $filePath
                Checksum = $checksum
            }
            Write-Debug "Added: FilePath = '$filePath', Checksum = '$checksum'"
        } else {
            Write-Debug "Skipping line: '$line' (unexpected format)"
        }
    } else {
        Write-Debug "Skipping comment line: '$line'"
    }
}

# Debug print the contents of $fileChecksums
Write-Debug "Debug: File Checksums from .sfv file:"
$fileChecksums | ForEach-Object { Write-Debug "File: '$($_.FilePath)', Checksum: '$($_.Checksum)'" }

$okEmoji = [char]::ConvertFromUtf32(0x2705)  # Checkmark emoji
$failEmoji = [char]::ConvertFromUtf32(0x274C)  # Crossmark emoji
$missingEmoji = [char]::ConvertFromUtf32(0x2753)  # No entry emoji

# Initialize counters for summary
$totalFiles = $fileChecksums.Count
$validFiles = 0
$invalidFiles = 0
$missingFiles = 0

# Compare the computed CRC32 checksum with the expected checksum
foreach ($file in $fileChecksums) {
    $filePath = Join-Path -Path (Split-Path -Parent $sfvFilePath) -ChildPath $file.FilePath

    # Check if the file exists
    if (-not (Test-Path -Path $filePath)) {
        Write-Host "$missingEmoji File '$filePath' does not exist."
        $missingFiles++
        continue
    }

    # Read the contents of the file as raw bytes
    $fileContent = [System.IO.File]::ReadAllBytes($filePath)

    # Compute the CRC32 checksum
    $computedCrc = $crc32::RtlComputeCrc32(0, $fileContent, $fileContent.Length).ToString("X8")

    # Compare the computed checksum with the expected checksum
    if ($computedCrc -eq $file.Checksum) {
        Write-Host "$okEmoji File '$filePath' is valid. Checksum: $computedCrc"
        $validFiles++
    } else {
        Write-Host "$failEmoji File '$filePath' is INVALID. Expected: $($file.Checksum), Computed: $computedCrc"
        $invalidFiles++
    }
}

# Print summary
Write-Host ""
Write-Host "Summary:"
Write-Host "Total files checked: $totalFiles"
Write-Host "Valid files: $validFiles"
Write-Host "Invalid files: $invalidFiles"
Write-Host "Missing files: $missingFiles"

if ($invalidFiles -eq 0 -and $missingFiles -eq 0) {
    Write-Host "$okEmoji All files are valid."
    exit 0
} else {
    Write-Host "$failEmoji Some files are invalid or missing."
    exit 1
}
