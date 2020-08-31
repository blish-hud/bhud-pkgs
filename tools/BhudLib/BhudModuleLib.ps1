#Requires -Version 7.0

Add-Type -AssemblyName System.IO.Compression

enum TestResult {
    na
    ok
    warn
    fail
}

class BhudUtil {
    static [void] WriteTestStart([String] $test) {
        Write-Host $test.PadRight(32, '.') -NoNewLine
    }

    static [void] WriteTestOk([string] $value) {
        [BhudUtil]::WriteTestResult("OK [$($value)]", [TestResult]::ok)
    }

    static [void] WriteTestResult([String] $details, [TestResult] $result) {
        $foregroundLookup = @{
            [TestResult]::na   = "Blue";
            [TestResult]::ok   = "Green";
            [TestResult]::warn = "Yellow";
            [TestResult]::fail = "Red"
        }

        Write-Host $details -ForegroundColor $foregroundLookup[$result]
    }
}

class BhudModule {
    [int]    $MANIFEST_VERSION = 1
    [String] $MANIFEST_NAME    = "manifest.json"

    [System.IO.Compression.ZipArchive] $Archive

    [string] $Checksum
    
    BhudModule([System.IO.Compression.ZipArchive] $ModuleArchive) {
        $this.MANIFEST_VERSION = 1
        $this.MANIFEST_NAME    = "manifest.json"

        $this.Archive = $ModuleArchive
    }

    [Object] GetManifest() {
        $manifestEntry = $this.Archive.GetEntry($this.MANIFEST_NAME)
        $manifestReader = New-Object System.IO.StreamReader($manifestEntry.Open())

        return ($manifestReader.ReadToEnd() | ConvertFrom-Json -AsHashtable)
    }

    [bool] Validate() {
        $isValid = $true

        # check manifest exists
        [BhudUtil]::WriteTestStart("Checking $($this.MANIFEST_NAME) exists")
        if (!$this.Archive.GetEntry($this.MANIFEST_NAME)) {
            [BhudUtil]::WriteTestResult("$($this.MANIFEST_NAME) is missing from archive!", [TestResult]::fail)
            Write-Host "Unable to continue validation!" -ForegroundColor Red
            return $false; # can't continue validating
        } else {
            [BhudUtil]::WriteTestResult("OK", [TestResult]::ok)
        }

        $manifest = $this.GetManifest();

        # check module name
        [BhudUtil]::WriteTestStart("Checking name")
        if (!$manifest.name) {
            [BhudUtil]::WriteTestResult("Mandatory field 'name' missing from manifest!", [TestResult]::fail)
            $isValid = $false
        } else {
            [BhudUtil]::WriteTestOk($manifest.name)
        }

        # check manifest version
        [BhudUtil]::WriteTestStart("Checking manifest version")
        if (!$manifest.manifest_version) {
            [BhudUtil]::WriteTestResult("Mandatory field 'manifest_version' missing from manifest!", [TestResult]::fail)
            $isValid = $false
        } elseif ($manifest.manifest_version -ne $this.MANIFEST_VERSION) {
            [BhudUtil]::WriteTestResult("Provided version '$($manifest.manifest_version)' is invalid (must be '$($this.MANIFEST_VERSION)').", [TestResult]::fail)
            $isValid = $false
        } else {
            [BhudUtil]::WriteTestOk($manifest.manifest_version)
        }

        # check primary assembly name
        [BhudUtil]::WriteTestStart("Checking package reference")
        if (!$manifest.package) {
            [BhudUtil]::WriteTestResult("Mandatory field 'package' missing from manifest!", [TestResult]::fail)
            $isValid = $false
        } elseif (!$this.Archive.GetEntry($manifest.package)) { 
            [BhudUtil]::WriteTestResult("Provided '$($manifest.package)' does not reference a valid module DLL!", [TestResult]::fail)
            $isValid = $false
        } else {
            [BhudUtil]::WriteTestOk($manifest.package)
        }

        # check module version
        [BhudUtil]::WriteTestStart("Checking version")
        if (!$manifest.version) {
            [BhudUtil]::WriteTestResult("Mandatory field 'version' missing from manifest!", [TestResult]::fail)
            $isValid = $false
        } elseif ($manifest.version -notmatch "^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$") {
            # https://semver.org/#is-there-a-suggested-regular-expression-regex-to-check-a-semver-string
            [BhudUtil]::WriteTestResult("Provided '$($manifest.version)' is invalid (must be SemVer).", [TestResult]::fail)
            $isValid = $false
        } else {
            [BhudUtil]::WriteTestOk($manifest.version)
        }

        # check namespace
        [BhudUtil]::WriteTestStart("Checking namespace")
        if (!$manifest.namespace) {
            [BhudUtil]::WriteTestResult("Mandatory field 'namespace' missing from manifest!", [TestResult]::fail)
            $isValid = $false
        } elseif ($manifest.namespace -notmatch "^([a-zA-Z_][\w_]*\.)*[a-zA-Z_][\w_]*$") {
            # https://stackoverflow.com/a/5205467
            [BhudUtil]::WriteTestResult("Provided '$($manifest.namespace)' is invalid.", [TestResult]::fail)
            $isValid = $false
        } else {
            [BhudUtil]::WriteTestOk($manifest.namespace)
        }

        ### optional fields

        # api permission check
        [BhudUtil]::WriteTestStart("Checking API permissions")
        if (!$manifest.api_permissions) {
            [BhudUtil]::WriteTestResult("NA", [TestResult]::na)
        } else {
            $refPermissions = @("account", "inventories", "characters", "tradingpost", "wallet", "unlocks", "pvp", "builds", "progression", "guilds")

            $reqPermissions = $($manifest.api_permissions.Keys)
            
            $badPermissions = ((Compare-Object -ReferenceObject $refPermissions -DifferenceObject $reqPermissions) | Where-Object {$_.SideIndicator -eq '=>'}) | Select-Object -ExpandProperty InputObject

            if ($badPermissions.Length -gt 0) {
                [BhudUtil]::WriteTestResult("Invalid permissions [$($badPermissions -join ', ')]", [TestResult]::fail)
                $isValid = $false;
            } else {
                [BhudUtil]::WriteTestOk($reqPermissions -join ', ')
            }
        }

        # directory check
        [BhudUtil]::WriteTestStart("Checking directories")
        if (!$manifest.directories) {
            [BhudUtil]::WriteTestResult("NA", [TestResult]::na)
        } else {
            $badDirs = $manifest.directories -notmatch "^[^<>:""\/\\|\?\*\r\n]+$"

            if ($badDirs.Length -gt 0) {
                [BhudUtil]::WriteTestResult("Invalid dirs [$($badDirs -join ', ')]", [TestResult]::fail)
                $isValid = $false;
            } else {
                [BhudUtil]::WriteTestOk($manifest.directories -join ', ')
            }
        }

        # checking enabled with without Blish HUD
        [BhudUtil]::WriteTestStart("Checking enabled without game")
        if (!$manifest.enable_without_gw2) {
            [BhudUtil]::WriteTestResult("FALSE", [TestResult]::na)
        } else {
            if ($manifest.enable_without_gw2 -eq $true) {
                [BhudUtil]::WriteTestResult("TRUE", [TestResult]::warn)
            } else {
                [BhudUtil]::WriteTestResult("FALSE", [TestResult]::ok)
            }
        }

        return $isValid;
    }
}

function Get-BhudModule {
    [OutputType([BhudModule])]
    param(
        [System.IO.MemoryStream] $InputStream = $null,
        [String] $Path = "",
        [String] $Url = ""
    )

    $moduleStream = New-Object System.IO.MemoryStream

    if ($InputStream) {
        $moduleStream = $InputStream
    }

    if ($Path.Length -gt 0) {
        (Get-Item -Path $Path).OpenRead().CopyTo($moduleStream)
    } elseif ($Url.Length -gt 0) {
        write-host "Downloading module from URL.  This could take a while..." -ForeGroundColor Blue -NoNewline
        $webClient = New-Object System.Net.WebClient

        try {
            $webClient.OpenRead($URL).CopyTo($moduleStream)
            Write-Host "OK" -ForegroundColor Green
        } catch {
            write-host "Error downloading module." -ForeGroundColor red
            Write-Host "FAILED" -ForegroundColor Red
            return $null
        }
    }

    $module = [BhudModule]::new($moduleStream)

    # Consider moving to the ctor
    $moduleStream.Position = 0
    $module.Checksum = (Get-FileHash -InputStream $moduleStream).Hash

    return $module
}