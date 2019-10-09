
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

$baseImage = $Env:BASEIMAGE;

Write-Host -Object "[Pipeline] -- Using base image: $baseImage" -ForegroundColor Green;

# Synopsis: Install NuGet provider
task NuGet {
    if ($Null -eq (Get-PackageProvider -Name NuGet -ErrorAction Ignore)) {
        Install-PackageProvider -Name NuGet -Force -Scope CurrentUser;
    }
}

task PSRuleStable NuGet, {
    Install-Module -Name PSRule -Repository PSGallery -MinimumVersion 0.9.0 -Scope CurrentUser -Force;
}

task PSRuleLatest NuGet, {
    Install-Module -Name PSRule -Repository PSGallery -MinimumVersion 0.9.0 -AllowPrerelease -Scope CurrentUser -Force;
}

task BuildImage PSRuleStable, PSRuleLatest, {
    $versions = (Get-InstalledModule -Name PSRule -AllVersions -ErrorAction Ignore);
    $stableVersion = @($versions | Where-Object -FilterScript {
        $_.Version -notlike "*-*"
    })[0].Version;
    $latestVersion = @($versions | Where-Object -FilterScript {
        $_.Version -like "*-*"
    })[0].Version;

    exec {
        docker build -f docker/latest/$baseImage/docker/Dockerfile -t $containerRegistry/ps-rule:latest-$baseimage --build-arg VCS_REF=$Env:BUILD_SOURCEVERSION --build-arg MODULE_VERSION=$latestVersion .
        docker build -f docker/stable/$baseImage/docker/Dockerfile -t $containerRegistry/ps-rule:stable-$baseimage --build-arg VCS_REF=$Env:BUILD_SOURCEVERSION --build-arg MODULE_VERSION=$stableVersion .
    }
}

task ReleaseImage {
    exec {
        docker push $containerRegistry/ps-rule:latest-$baseImage
        docker push $containerRegistry/ps-rule:stable-$baseImage
    }
}

task . Build

task Build BuildImage, {

}
