$plugin = Get-ChildItem dgplugin.smx

[xml]$credentialFile = Get-Content .\secrets\credentials.xml
$server = "ftp://" + $credentialFile.Credentials.Server
$webClient = New-Object System.Net.WebClient
$webClient.Credentials = New-Object System.Net.NetworkCredential($credentialFile.Credentials.UserName, $credentialFile.Credentials.Password)

[xml]$deployFile = Get-Content .\secrets\deployLocations.xml

foreach($location in $deployFile.Locations.Location) {
    $uri = $server + $location.Plugins + $plugin.Name
    $webClient.UploadFile($uri, $plugin.FullName)
}