
[CmdletBinding()]
param (
    [Parameter(Mandatory = $False)]
    [String]$Build = '0.0.1',

    [Parameter(Mandatory = $False)]
    [String]$Configuration = 'Debug',

    [Parameter(Mandatory = $False)]
    [String]$Registry,

    [Parameter(Mandatory = $False)]
    [String]$ArtifactPath = (Join-Path -Path $PWD -ChildPath out/modules)
)

Write-Host -Object "[Pipeline] -- PWD: $PWD" -ForegroundColor Green;
Write-Host -Object "[Pipeline] -- ArtifactPath: $ArtifactPath" -ForegroundColor Green;
Write-Host -Object "[Pipeline] -- BuildNumber: $($Env:BUILD_BUILDNUMBER)" -ForegroundColor Green;
Write-Host -Object "[Pipeline] -- SourceBranch: $($Env:BUILD_SOURCEBRANCH)" -ForegroundColor Green;
Write-Host -Object "[Pipeline] -- SourceBranchName: $($Env:BUILD_SOURCEBRANCHNAME)" -ForegroundColor Green;
Write-Host -Object "[Pipeline] -- Commit: $($Env:BUILD_SOURCEVERSION)" -ForegroundColor Green;

if ($Env:SYSTEM_DEBUG -eq 'true') {
    $VerbosePreference = 'Continue';
}

if ($Env:BUILD_SOURCEBRANCH -like '*/tags/*' -and $Env:BUILD_SOURCEBRANCHNAME -like 'v0.*') {
    $Build = $Env:BUILD_SOURCEBRANCHNAME.Substring(1);
}

$version = $Build;
$versionSuffix = [String]::Empty;

if ($version -like '*-*') {
    [String[]]$versionParts = $version.Split('-', [System.StringSplitOptions]::RemoveEmptyEntries);
    $version = $versionParts[0];

    if ($versionParts.Length -eq 2) {
        $versionSuffix = $versionParts[1];
    }
}

Write-Host -Object "[Pipeline] -- Using version: $version" -ForegroundColor Green;
Write-Host -Object "[Pipeline] -- Using versionSuffix: $versionSuffix" -ForegroundColor Green;

$containerRegistry = $Registry;

Write-Host -Object "[Pipeline] -- Using registry: $containerRegistry" -ForegroundColor Green;

task BuildImage {
    if ($Env:IMAGENAME -eq 'ubuntu-16.04') {
        exec {
            docker build -f docker/stable/alpine/docker/Dockerfile -t $containerRegistry/ps-rule:latest-alpine --build-arg VCS_REF=$Env:BUILD_SOURCEVERSION .
        }
    }
    elseif ($Env:IMAGENAME -eq 'windows-2019') {
        exec {
            docker build -f docker/stable/windowsservercore/docker/Dockerfile -t $containerRegistry/ps-rule:latest-windowsservercore --build-arg VCS_REF=$Env:BUILD_SOURCEVERSION .
        }
    }
}

task ReleaseImage {
    if ($Env:IMAGENAME -eq 'ubuntu-16.04') {
        exec {
            docker push $containerRegistry/ps-rule:latest-alpine
        }
    }
    elseif ($Env:IMAGENAME -eq 'windows-2019') {
        exec {
            docker push $containerRegistry/ps-rule:latest-windowsservercore
        }
    }
}

task . Build

task Build BuildImage, {

}
