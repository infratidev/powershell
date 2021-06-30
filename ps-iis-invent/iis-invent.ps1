Function Get-WebApplicationReport() {
	Import-Module WebAdministration
    $counter = 0
    $Time = Get-Date
    $dbRegex = "((Initial\sCatalog)|((AttachDBFilename))|(database))\s*=\s*'?(?<ic>.+?)('|;|\Z)" 
    $dbsrvrRegex="((Data\sSource)|((server)))\s*=\s*'?(?<ic>.+?)('|;|\Z)"
    $ipRegEx = "(((IPV4Address)))\s*=\s*'?(?<ic>.+?)('|;|}|\Z)"
    $UserIDRegex="((User\sId)|((uid)))\s*=\s*'?(?<ic>.+?)('|;|\Z)"

	Get-WebApplication | ForEach-Object {
		$webApp = $_
		$(
			If (Test-Path -Path "$($webApp.PhysicalPath)\Web.config") {
				$webConfig = [xml](Get-Content "$($webApp.PhysicalPath)\Web.config") | Set-Content "$($webApp.PhysicalPath)\$((++$counter)).config"
					[PsCustomObject][ordered]@{
						'web.config File' =		'YES'
					}                       
			} Else {
				[PsCustomObject][ordered]@{'web.config File' = 'NO'}
			}
		) | Select-Object -Property `
                                @{n='Time-UTC';    e={$Time.ToUniversalTime()}},                                                         
                                @{n='ComputerName';   e={$ENV:ComputerName}},
                                @{n='OS Name';             e={ (Get-CimInstance -Class Win32_OperatingSystem).Caption}},                                
                                @{n='IIS Version';          e={ [System.Diagnostics.FileVersionInfo]::GetVersionInfo("$env:SystemRoot\system32\inetsrv\InetMgr.exe").ProductVersion}},
                                @{n='IP';                   e={If ((Test-Connection $env:COMPUTERNAME -Count 1 | Select-Object IPV4Address) -match $ipRegEx) {$Matches['ic']} Else {'<UNKNOWN>'}}},
                                @{n='Web Application';  e={$webApp.path}},
                                @{n='Site Name';   e={If ($webApp.ItemXPath -match "@name\s*=\s*'(?<Name>.*?)'") {$Matches['Name']} Else {'<UNKNOWN>'}}},
                                @{n='Physical Path';  e={$webApp.PhysicalPath}},
                                @{n='Application Pool';  e={$webApp.ApplicationPool}},
                                'web.config File' 
	} 
    return $counter+1
}

#Get Computers Hostname   
$Hostname = get-content env:computername
#File path to save local csv file
$filePath = "C:\Path output"
#Timestamp to use in File Name
$timestamp =  (get-date).toString("r")
# Creation of file name
$fileName =  $Hostname + "_"+"IISApp" +".html"
#Merging File Path and File name
$filePathfull = Join-Path $filePath $fileName

$Report = Get-WebApplicationReport
#$Report | Export-Csv -NoTypeInformation -Path $filePathfull
$Report | ConvertTo-Html -Title $hostname  -PreContent "<h1>Inventário - Total WebApp: $Report - $timestamp </h1>" -CSSUri "iis.css" | Set-Content $filePathfull
#Comment Gridview line below , only used for testing.
#$Report | Out-GridView

