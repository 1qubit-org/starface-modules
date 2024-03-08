<#
.SYNOPSIS
    Deploys a module to a starface server and reloads the module.
.DESCRIPTION
    Connects to the starface server via SFTP and uploads the builded files to the module folder.
    Then it sends a POST request to the moduleReloader module to update and reload the module.
.PARAMETER moduleName
    Name of the module, used for the folder name in the _build\production folder by default and for log output
.PARAMETER moduleID
    ID of the module, found in the module-descriptor.xml
.PARAMETER moduleVersion
    Version (integer) the module shall be set to
    Default value is -1, which means the module version will be incremented by 1
    Value -2 calculates the version number from the current date (yyyyMMdd)
    Value -3 calculates the version number from the current date (yyMMddHH)
.EXAMPLE
    C:\PS>.\deploy.ps1 -ModuleName "moduleReloader" -ModuleID "1f617052-8864-0874-a4bc-d495b4fe02bd" -ModuleVersion -2
.NOTES
    Author: Jens Suing | 1 Qubit
    Date:   2024-03-06
#>
param(    
    [Parameter(mandatory=$true)]
    [String]$moduleName,
    [Parameter(mandatory=$true)]
    [String]$moduleID,
    [int]$moduleVersion = -1
    );

# ------------- Change to your own settings -------------

# Path to the builded files
$sourceDir = "$PWD\..\_build\production\$($moduleName)";

# Hostname of the starface server
$sfHost = "starface.domain.tld";

# Instance name of the reloader module
$reloaderModuleInstanceName = "1qb.moduleReloader.reload";

 # Path to the WinSCP .NET assembly
 # Check which version you need, depending on your powershell version (netstandard2.0 for powershell core 6/7)
 # dll has to be in the same folder as the winSCP executable
$winSCPDllPath = "$PWD\winscp\ns2WinSCPnet.dll";

# Set to $true to skip certificate check (expiration, revocation, trusted root authority, etc.)
# Set $true for self-signed certificates
$skipCertificateCheck = $true;


# ------------- In most cases no need to change -------------
$xmlRpcBaseUrl = "https://$($sfHost)/xml-rpc?de.vertico.starface.auth="; # Base URL for the xml-rpc requests
$destDir = "/var/starface/module/modules/repo/$($moduleID)";
$fileMask = "*.class | META-INF/, *.xml";
$logging = $false;


# ------------- Logic starts here -------------

# Check if moduleVersion is set to -1, -2 or -3
if ($moduleVersion -eq -2) {
    $moduleVersion = [int](Get-Date).ToString("yyyyMMdd");
} elseif ($moduleVersion -eq -3) {
    $moduleVersion = [int](Get-Date).ToString("yyMMddHH");
}

Write-Host ">>> Deploying module: $($moduleName) to starface server: $($sfHost)";

# Load WinSCP .NET assembly
Add-Type -Path $winSCPDllPath;

# Load credentials
$credentialObject = Import-Csv -Path "$PWD\$($sfHost)-credentials.pwd";
$username = $credentialObject.Username;
$password = ConvertTo-SecureString -String $credentialObject.Password;
$unsecurePassword = (New-Object PSCredential 0, $password).GetNetworkCredential().Password;

$loginID = $credentialObject.LoginID;
$xmlRpcHash = ConvertTo-SecureString -String $credentialObject.XmlRpcHash;
$unsecureXmlRpcHash = (New-Object PSCredential 0, $xmlRpcHash).GetNetworkCredential().Password;

# Setup session options
$sessionOptions = New-Object WinSCP.SessionOptions -Property @{
    Protocol = [WinSCP.Protocol]::Sftp
    HostName = $sfHost
    UserName = $username
    Password = $unsecurePassword
    GiveUpSecurityAndAcceptAnySshHostKey = $true
}

$session = New-Object WinSCP.Session

try {
    # Connect to starface
    if ($logging) {
        $session.SessionLogPath = "$PWD\winscp.log"
    }
    
    $session.Open($sessionOptions)
    [WinSCP.SynchronizationCriteria] $synchronizationCriteria = New-Object WinSCP.SynchronizationCriteria
    $synchronizationCriteria = [WinSCP.SynchronizationCriteria]::Time
    [WinSCP.TransferOptions] $transferOptions = New-Object WinSCP.TransferOptions
    $transferOptions.FileMask = $fileMask
    $transferOptions.OverwriteMode = [WinSCP.OverwriteMode]::Overwrite

    # Upload files to module folder
    Write-Host ">>> Upload builded files to module folder";
    $session.SynchronizeDirectories([WinSCP.SynchronizationMode]::Remote, $sourceDir, $destDir, $False, $False, $synchronizationCriteria, $transferOptions).Check()

    # run module-reloader to update module
    Write-Host ">>> Reload module via module-reloader module";
    $xmlRpcUrl = "$($xmlRPCBaseUrl)$($loginID):$unsecureXmlRpcHash";

    # Body data
    $body = "<?xml version='1.0' encoding='UTF-8'?>
    <methodCall>
    <methodName>$($reloaderModuleInstanceName)</methodName>
        <params>
            <param>
            <value>
                <struct>
                <member>
                    <name>paramModuleID</name>
                    <value>
                        <string>$($moduleID)</string>
                    </value>
                    <name>paramModuleVersion</name>
                    <value>
                        <string>$($moduleVersion)</string>
                    </value>
                </member>          
                </struct>
            </value>
            </param>
        </params>    
    </methodCall>"

    # Additional headers
    $headers = @{
        "Content-Type" = "application/xml"
    }

    # Send the POST request
    if ($skipCertificateCheck) {
        if ($PSVersionTable.PSVersion.Major -gt 5) {
            Write-Host ">>> Skipping certificate check (PSVersion $($PSVersionTable.PSVersion.Major))"
            $response = Invoke-WebRequest -Uri $xmlRpcUrl -Method POST -Body $body -Headers $headers -SkipCertificateCheck
        }
        else {
            [Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
            Write-Host ">>> Skipping certificate check (PSVersion $($PSVersionTable.PSVersion.Major))"
            $response = Invoke-WebRequest -Uri $xmlRpcUrl -Method POST -Body $body -Headers $headers
        }
    } else {
        $response = Invoke-WebRequest -Uri $xmlRpcUrl -Method POST -Body $body -Headers $headers
    }

    if ($response.Content -match '<string>(.*?)</string>') {
        $responseContent = $matches[1]
    }
    
    Write-Host;
    Write-Host "Response: $($responseContent)";
    Write-Host;
    
}
finally {
    # Disconnect, clean up
    $session.Dispose()
}