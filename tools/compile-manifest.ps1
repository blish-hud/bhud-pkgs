$PSDefaultParameterValues = @{ '*:Encoding' = 'utf8' }

$manifest = @{}

Get-ChildItem -Path .\ -Recurse -Filter *.json | ForEach-Object {
    $packageManifest = (Get-Content -Path $_.FullName | ConvertFrom-Json)

    $namespace = $packageManifest.namespace
    $version = $_.BaseName

    if (!$manifest.ContainsKey($namespace)) {
        $manifest.Add($namespace, @{})
    }

    $manifest[$namespace][$version] = $packageManifest
}

(ConvertTo-Json $manifest -Depth 8 -Compress) | Write-Host