[CMDLetBinding()]
param
(
  [Parameter(mandatory=$true, valuefrompipeline=$true)][String] $URL,
  [String] $Filename,
  [String] $Directory,
  [System.Net.ICredentials] $Credentials,
  [System.Net.IWebProxy] $WebProxy,
  [System.Net.WebHeaderCollection] $Headers,
  [switch] $Clobber
)

Begin
{
	#make a webclient object
	$webclient = New-Object Net.WebClient
	
	#set the pass through variables if they are not null
	if ($Credentials) 
	{
		$webclient.credentials = $Credentials
	}
	if ($WebProxy) 
	{
		$webclient.proxy = $WebProxy
	}
	if ($Headers) 
	{
		$webclient.headers.add($Headers)
	}
}

Process 
{
	#destination to download file to
	$Destination = ""
	
	<#
		This is a very complicated bit of code, but it handles all of the possibilities for the filename and directory parameters
		
		1) If both are specified -> join the two together
		2) If no filename or destination directory is specified -> the destination is the current directory (converted from .) joined with the "leaf" part of the url
		3) If no filename is specified, but a directory is -> the destination is the specified directory joined with the "leaf" part of the url
		4) If filename is specified but a directory is not -> The destination  is the current directory (converted from .) joined with the specified filename
	#>
	if (($Filename -ne "") -and ($Directory -ne "")) 
	{
		$Destination = Join-Path $Directory $Filename
	} 
 	elseif ((($Filename -eq $null) -or ($Filename -eq "")) -and (($Directory -eq $null) -or ($Directory -eq ""))) 
	{
		$Destination = Join-Path (Convert-Path ".") (Split-Path $URL -leaf)
	} 
	elseif ((($Filename -eq $null) -or ($Filename -eq "")) -and ($Directory -ne "")) 
	{
		$Destination = Join-Path $Directory (Split-Path $URL -leaf)
	} 
	elseif (($Filename -ne "") -and (($Directory -eq $null) -or ($Directory -eq ""))) 
	{
		$Destination = Join-Path (Convert-Path ".") $Filename
	}
		
	<#
		If the destination already exists and if clobber parameter is not specified then throw an error as we don't want to overwrite files, 
		else generate a warning and continue
	#>
	if (Test-Path $Destination) 
	{
		if ($Clobber) 
		{
			Write-Warning "Overwritting file"
		} 
		else 
		{
			throw "File already exists at destination: $destination, specify -Clobber to overwrite"
		}
	}
		
	#try downloading the file, throw any exceptions
	try 
	{
		Write-Verbose "Downloading $URL to $Destination"
		$webclient.DownloadFile($URL, $Destination)
	} 
	catch 
	{
		throw $_
	}
}

}
