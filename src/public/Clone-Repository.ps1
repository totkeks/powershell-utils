Function Clone-Repository {
	Param(
		[parameter(Mandatory = $true)]
		[String]
		$Url
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
		Where-Object { -ne $null $_.Path } |
		Select-Object -First 1

	if ($Match) {
		Write-Host "Found match for provider: $($Match.Provider)"

		if ($Global:ProjectsDir) {
			$TargetDirectory = [io.path]::Combine($Global:ProjectsDir, $Match.Provider, $Match.Path)
		}
		else {
			Write-Error "No projects directory configured. Aborting."
		}

		git.exe clone $Url $TargetDirectory
	}
	else {
		Write-Error "No match found for repository url: $Url"
	}
}

Export-ModuleMember -Function Clone-Repository
