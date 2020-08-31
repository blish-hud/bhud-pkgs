# bhud-pkgs

This repository contains the manifest files for **Blish HUD modules**.  You are highly encouraged to submit manifests for your modules so that they can be listed in the Blish HUD module viewer.  This also for users to easily discover your modules and automatically update their copies when you submit changes.

# Submitting a Package

To submit a package to the repository, you should follow these steps:

1. Fork this repository
2. Author a manifest and place it in the appropriate directory
3. Submit your PR
5. Respond to any feedback

# Authoring a Manifest

The minimal manifest syntax is below.  Please only submit one manifest per PR.

Be sure that the manifest filename matches the `Version` and the manifest is located in the folder path matching `manifests\name\sp\ace\<version>.json` (where `name.sp.ace` is your module's `namespace`).

```json
{
    "manifest_version": "1",
    "name": "<module-name>",
    "namespace": "<module-namespace>",
    "version": "<module-version>",
    "contributors": [
        {
            "name":     "<contributor-name>",
            "username": "<contributor-username>",
            "url":      "<contributor-url>"
        }
    ],
    "description": "<module-description>",
    "dependencies": {
        "module1.name": "> 0.5.0",
        "module2.name": "~ 1.0.0"
    },
    "url": "<module-project-url>",
    "location": "https://<module-download-path>.bhm",
    "hash": "<module-checksum>"
}
```

The majority of these fields should directly mirror their corresponding values found in your [module's manifest.json](https://github.com/blish-hud/manifest.json/blob/master/manifest-v1.md).

# Using BhudLib

To help authors create module package manifests, we have provided BhudLib — a PowerShell library.  The library can be used to check that your module (.bhm) is valid, create a package manifest, and automatically save it in the proper manifests path.

From start to finish, in PowerShell:

```ps
# Clone your fork of this repository and create a new branch to work in.
git clone https://github.com/<your-username>/bhud-pkgs.git
git checkout -b yourmodule_version

# Install the BhudLib PowerShell library and import it.
Install-Module BhudLib # (you can ensure it is up to date with `Update-Module BhudLib` if you have installed it previously).
Import-Module BhudLib

# Pass a Url that points directly to your hosted bhm file (which will be used by Blish HUD to later download the module).
$module = Get-BhudModule -Url "https://<url-to-download-your-bhm>.bhm"

# Ensure your module passes validation.
$module.Validate()

# Build the module package manifest.
$pkg = Build-BhudPkgManifest -Url "https://<url-to-download-your-bhm>.bhm"

# See what the package manifest will look like.
$pkg.Get()

# Automatically generate the new manifest file.
Save-BhudPackage -Pkg $pkg -RepoRoot "<path-to-bhud-pkgs-repo>\manifests"

# Stage, commit, and push your changes in preperation for the PR.
git add -A
git commit -S -m "<your-module> <version>" # The message is not strict, it can be what you would like.
git push -u origin yourmodule_version # "yourmodule_version" should match the name of the branch you chose.
```

Once you have pushed your changes, navigate to [the repository on GitHub](https://github.com/blish-hud/bhud-pkgs) and it should prompt you to PR the changes.

# Submit your PR

With the manifest ready, you will need to submit a PR.

### Validation Process

The PR request will go through a validation process.  This process may contain both automated validation and manual review by maintainers.  In the event of validation or review issues, replies will be made in the PR and it assigned back to you to make the appropriate changes.

# Credit

Our repo format and process for Blish HUD packages heavily mirrors that of [winget-pkgs](https://github.com/microsoft/winget-pkgs), the package repository for [winget](https://docs.microsoft.com/en-us/windows/package-manager/winget/).