#!/usr/bin/pwsh
if ($PSVersionTable.PSVersion.Major -lt 7) {
    throw "This script requires PowerShell 7 or higher. Please install PowerShell Core: winget install --id Microsoft.PowerShell --source winget"
}

# initialize vars
$Global:Version = [PSCustomObject]@{
    Major = 26
    Minor = 10
    Patch = 0
}
$ErrorActionPreference = 'Stop'
$NotDryRun = $false


function Write-Version {
    Write-Output("${Version.Major}.${Version.Minor}.${Version.Patch}")
    return
}
function ConvertTo-Base64 {
    <#
        .DESCRIPTION
        Converts a string to Base64 using a character encoding compatible with web APIs.

        .PARAMETER DecodedString
        The unconverted string to encode.

        .EXAMPLE
        ConvertTo-Base64("Test")
    #>

    param (
        $DecodedString
    )

    Write-Debug("Converting ${DecodedString} to Base64")
    $Bytes = [System.Text.Encoding]::UTF8.GetBytes($DecodedString)
    $EncodedString = [Convert]::ToBase64String($Bytes)
    Write-Debug("Converted: ${EncodedString}")
    return $EncodedString
}

<#TODO - Split API call out of this function into its own, and have functions
         pass API endpoint to the API call function. Consider different
         functions for GET and POST.
#>
function Get-Clients {
    param (
        $SecureDattoApiKey
    )

    Write-Debug("Initializing headers for API call")
    $headers=@{}
    $headers.Add("Authorization", "Basic ${SecureDattoApiKey}")
    try {
        Write-Debug("Calling API")
        $clients = Invoke-RestMethod -Uri https://api.datto.com/v1/saas/domains -Method GET -Headers $headers -ErrorAction Stop
    }
    catch {
        if ($_.Exception.Response -and [int]$_.Exception.Response.StatusCode -eq 401) {
            throw "Datto API authentication failed (401). Check API_USERNAME and API_PASSWORD in .env."
        }
        throw "Datto API request failed: $($_.Exception.Message)"
    }
    Write-Debug("API call completed.")
    return $clients
}


# Parse arguments
foreach ($arg in $args) {
    switch ($arg) {
        "-d" {
            $DebugPreference = "Continue"
            Write-Debug("Debugging output is enabled")
            break
        }
        "--version" {
            Write-Version
            return
        }
        Default {
            Write-Output("${arg} is an invalid argument. Use --help to view help text."); return
        }
    }
}

if (Test-Path ".env") {
    Write-Debug(".env file found. Parsing...")
    Get-Content .env | Where-Object { $_ -match '=' -and $_ -notmatch '^#' } | ForEach-Object {
        $name, $value = $_.Split('=', 2)
        # $secureValue = ConvertTo-SecureString -String $value.Trim() -AsPlainText -Force
        # $secureValue = ConvertTo-Base64($value.Trim())
        Set-Variable -Name $name.Trim() -Value $value.Trim()
        Write-Debug("$($name.Trim()) == $($value.Trim())")
    }
} else {
    throw(".env file missing. Cannot continue.")
}

if (-not (Get-Variable -Name "API_PASSWORD" -ErrorAction SilentlyContinue)) {
    throw "API_PASSWORD is not defined"
} elseif (-not (Get-Variable -Name "API_USERNAME" -ErrorAction SilentlyContinue)) {
    throw "API_USER is not defined"
}

# $DattoBasicAuth = ConvertTo-Base64("${API_USERNAME}:${API_PASSWORD}")
# $clients = Get-Clients($DattoBasicAuth)
