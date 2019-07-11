Function Clone-Repository {
	Param(
		[parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string] $Url,

		[parameter(Mandatory = $false)]
		[ValidateScript( {
				If (-Not ($_ | Test-Path)) {
				throw "Target path does not exist."
			}
			If (-Not ($_ | Test-Path -PathType Container)) {
			throw "Target path must be a folder."
		}
		return $true;
	})]
[string] $ProjectsBaseDirectory,

[switch] $Force
)

#------------------------------------------------------------------------------
# Configuration of available providers
#------------------------------------------------------------------------------
$GitProviders = @{
	"Azure"     = {
		if ($args[0] -Match "https://(?:\w+@)?dev.azure.com/(?<Organization>\w+)/(?<Project>\w+)/_git/(?<Repository>[\w-_]+)") {
			return [io.path]::Combine($Matches.Organization, $Matches.Project, $Matches.Repository)
		}
	}

	"GitHub"    = {
		if ($args[0] -Match "https://github\.com/(?<UserOrOrganization>\w+)/(?<Repository>[\w-_]+)\.git") {
			return [io.path]::Combine($Matches.UserOrOrganization, $Matches.Repository)
		}
	}

	"Bitbucket" = {
		if ($args[0] -Match "https://(?:\w+@)?bitbucket.org/(?<User>\w+)/(?<Repository>[\w-_]+)\.git") {
			return [io.path]::Combine($Matches.User, $Matches.Repository)
		}

	}
}


#------------------------------------------------------------------------------
# Find the right provider and clone the repository
#------------------------------------------------------------------------------
$Match = $GitProviders.GetEnumerator() |
	Select-Object @{n = "Provider"; e = { $_.Key } }, @{n = "Path"; e = { $_.Value.invoke($Url) } } |
	Where-Object { $_.Path -ne $null } |
	Select-Object -First 1

if ($Match) {
	Write-Host "Found match for provider: $($Match.Provider)"

	if ($ProjectsBaseDirectory) {
		$TargetDirectory = [io.path]::Combine($ProjectsBaseDirectory, $Match.Provider, $Match.Path)
	}
	elseif ($Global:ProjectsDir) {
		$TargetDirectory = [io.path]::Combine($Global:ProjectsDir, $Match.Provider, $Match.Path)
	}
	else {
		Write-Error "Neither parameter ProjectsBaseDirectory nor global ProjectsDir are set. Aborting."
	}

	if (Test-Path -PathType Container $TargetDirectory) {
		if ($Force) {
			Write-Host "Removing existing target directory."
			Remove-Item -Recurse -Force $TargetDirectory
		}
		else {
			Write-Error "Target directory already exists. Use -Force to overwrite. Aborting."
		}
	}

	git.exe clone $Url $TargetDirectory

	if ($LASTEXITCODE -eq 0) {
		Set-Location $TargetDirectory
	}
}
else {
	Write-Error "No match found for repository url: $Url"
}
}

Export-ModuleMember -Function Clone-Repository
