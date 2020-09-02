$PSDefaultParameterValues = @{ '*:Encoding' = 'utf8' }

$manifest = [System.Collections.ArrayList]@()

Get-ChildItem -Path .\ -Recurse -Filter *.json | ForEach-Object {
    $packageManifest = (Get-Content -Path $_.FullName | ConvertFrom-Json)

    [void]$manifest.Add($packageManifest)
}

(ConvertTo-Json $manifest -Depth 8 -Compress) | Write-Host