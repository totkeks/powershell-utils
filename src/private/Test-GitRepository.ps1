Function Test-GitRepository {
	If ($null -eq (Get-Command "git.exe" -ErrorAction SilentlyContinue)) {
		Write-Error "Unable to find git.exe in your PATH"
		Return $false
	}

	Return (git.exe rev-parse --is-inside-work-tree 2>$null)
}
