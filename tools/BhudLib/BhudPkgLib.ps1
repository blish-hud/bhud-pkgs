#requires -Version 6.0

class BhudPkgManifest {

    [String] $manifest_version = 1

    [String] $name
    [String] $namespace
    [String] $version
    [Object] $contributors
    [string] $description
    [Object] $dependencies
    [String] $url

    [String] $location
    [String] $hash

    BhudPkgManifest([BhudModule] $module, [String] $downloadUrl) {
        $isValid = $module.Validate()

        if ($isValid) {
            $this.PopulateFromModule($module)
            $this.location = $downloadUrl;
        } else {
            Write-Host "Failed to build package manifest.  Provided module is not valid." -ForegroundColor Red
        }
    }

    [Void] PopulateFromModule([BhudModule] $module) {
        $manifest = $module.GetManifest()

        $this.name = $manifest.name
        $this.namespace = $manifest.namespace
        $this.version = $manifest.version
        $this.contributors = $manifest.contributors
        $this.description = $manifest.description
        $this.dependencies = $manifest.dependencies
        $this.url = $manifest.url
        $this.hash = $module.Checksum
    }

    [String] Get() {
        $cleanManifest = $this.Properties | Where-Object {$null -ne $_.Value} | Select-Object -ExpandProperty Name

        return $this | Select-Object -Property $cleanManifest | ConvertTo-Json
    }

}

function Build-BhudPkgManifest {
    [OutputType([BhudPkgManifest])]
    param(
        [String] $Url = ""
    )

    $module = $null

    While (!$Url.Length -gt 0) {
        $Url = Read-Host -Prompt "Enter the URL to the module (.bhm)"
    }

    $module = Get-BhudModule -Url $Url

    if ($module) {
        return [BhudPkgManifest]::new($module, $Url)
    }

    Write-Host "Failed to build package manifest.  Provided module or module URL is not valid." -ForegroundColor Red
    return $null
}

function Save-BhudPackage {
    param(
        [BhudPkgManifest] $Pkg,
        [String] $RepoRoot
    )

    $pkgDir = Join-Path -Path $RepoRoot -ChildPath "$($pkg.namespace -replace '\.','\')"

    $pkgFile = Join-Path -Path $pkgDir -ChildPath "$($pkg.version).json"

    New-Item -ItemType Directory -Force -Path $pkgDir

    Set-Content -Path $pkgFile -Value $($Pkg.Get())

    Write-Host "Wrote manifest to $($pkgFile)"
}