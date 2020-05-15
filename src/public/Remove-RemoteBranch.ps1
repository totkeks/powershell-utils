Function Remove-RemoteBranch {
	[CmdletBinding(
		SupportsShouldProcess = $true,
		ConfirmImpact = "High"
	)]
	Param(
		[switch] $Force
	)

	DynamicParam {
		$IsCwdGitRepository = Test-GitRepository
		$DefaultBranches = @("master", "HEAD")
		$ParameterName = "Name"

		$RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
		$AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]

		$ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
		$ParameterAttribute.Mandatory = $true
		$ParameterAttribute.Position = 1
		$AttributeCollection.Add($ParameterAttribute)

		If ($IsCwdGitRepository) {
			$RemoteBranches = (git.exe branch --remote --format "%(refname:lstrip=3)")
			$RemoteBranches = $RemoteBranches.Where( { $_ -notin $DefaultBranches } )

			If ($RemoteBranches.Count -gt 0) {
				$ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($RemoteBranches)
				$AttributeCollection.Add($ValidateSetAttribute)
			}
		}

		$RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
		$RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
		Return $RuntimeParameterDictionary
	}

	Begin {
		If (-not $IsCwdGitRepository) {
			Write-Error "Not running inside a git repository. Aborting."
			Exit 1
		}

		$BranchName = $PsBoundParameters[$ParameterName]
		If ($BranchName -in $DefaultBranches -and -not $Force) {
			Write-Error "Not deleting default branch '$BranchName'. If you really want to do this, use the -Force flag."
			Exit 2
		}

		$RemoteName = git.exe remote
	}

	Process {
		If ($PSCmdlet.ShouldProcess("$RemoteName/$BranchName")) {
			Write-Output "Deleting branch $RemoteName/$BranchName"
			git.exe push --delete $RemoteName $BranchName
		}
	}
}
