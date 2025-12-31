# Prompt for the username and password
$serverName = Read-Host "Servername eingeben";
$username = Read-Host "SFTP Benutzername eingeben";
$password = Read-Host "SFTP Passwort eingeben" -AsSecureString;
$loginID = Read-Host "Login ID eingeben";
$xmlRpcHash = Read-Host "XML-RPC Hash eingeben" -AsSecureString;

# Convert password to a secure string
$encryptedPassword = ConvertFrom-SecureString -SecureString $password;
$encryptedXmlRpcHash = ConvertFrom-SecureString -SecureString $xmlRpcHash;

# Create a PSCustomObject
$credentialObject = New-Object -TypeName PSObject
$credentialObject | Add-Member -MemberType NoteProperty -Name Username -Value $username
$credentialObject | Add-Member -MemberType NoteProperty -Name Password -Value $encryptedPassword

$credentialObject | Add-Member -MemberType NoteProperty -Name LoginID -Value $loginID
$credentialObject | Add-Member -MemberType NoteProperty -Name XmlRpcHash -Value $encryptedXmlRpcHash

$credentialObject | Add-Member -MemberType NoteProperty -Name SshHostKeyFingerprint -Value $encryptedsshHostKeyFingerprint

# Export the PSCustomObject to a CSV file
$credentialObject | Export-Csv -Path "$PWD\$serverName-credentials.pwd" -NoTypeInformation