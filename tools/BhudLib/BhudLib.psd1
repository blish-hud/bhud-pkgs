@{
    RootModule        = 'BhudLib.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '41ff811f-bc29-4835-8daf-25c64aa5492f'
    Author            = 'Dade Lamkins'
    CompanyName       = 'Blish HUD'
    Copyright         = '© Dade Lamkins. All rights reserved.'
    Description       = 'Manage Blish HUD modules and packages with PowerShell.'
    PowerShellVersion = '6.0'

    FunctionsToExport = @('Get-BhudModule', 'Build-BhudPkgManifest', 'Save-BhudPackage')
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    PrivateData       = @{
        PSData = @{ }
    }
}