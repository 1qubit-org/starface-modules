# Powershell STARFACE Module Deploy Script

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## Description
Deploys a module to a starface server and reloads the module via `moduleReloader` module (found in this repo in [`src/module-reloader`](/src/module-reloader) and [`bin/module-reloader`](/bin/module-reloader) folders).

## Table of Contents
- [Powershell STARFACE Module Deploy Script](#powershell-starface-module-deploy-script)
  - [Description](#description)
  - [Table of Contents](#table-of-contents)
  - [Installation](#installation)
  - [Usage](#usage)
    - [Example:](#example)
    - [Setup External Tool in IntelliJ IDEA](#setup-external-tool-in-intellij-idea)
  - [License](#license)

## Installation
Create a folder, e.g. _deploy and place the two powershell files in it.  
Download WinSCP .NET assembly / COM library from https://winscp.net/eng/downloads.php (6.3.1 as the time of writing) and extract it to _deploy\winscp.  
Copy WinSCPnet.dll from subfolder netstandard2.0 to _deploy\winscp\ns2WinSCPnet.dll.  
  
Open deploy.ps1 and edit the following variables:  
- `$sourceDir` - the path where you IDE generates the java class files of your module project
- `$sfHost`- Hostname or IP address of the STARFACE server
- `$reloaderModuleInstanceName` - Name of the `moduleReloader` module instance
- `$winSCPDllPath` - Path to the `netstandard2.0` `WinSCPnet.dll`  
- `$skipCertificateCheck` - $true if the server uses a self-signed SSL certificate

Manually import the `1QBmoduleReloader_v...sfm` module (see bin folder in this repo) to your STARFACE server

## Usage
First call the `createCredentials.ps1` script (without any arguments) from a powershell terminal to generate a credentials file.  
Then call the `deploy.ps1` script from powershell terminal or as an external tool in your IDE with the following arguments:  

`moduleName`  
Name of the module, used for the folder name in the _build\production folder by default and for log output  

`moduleID`  
ID of the module, found in the module-descriptor.xml  

`moduleVersion`  
Version (`integer`) the module shall be set to  
Default value is `-1`, which means the module version will be incremented by 1  
Value `-2` calculates the version number from the current date (yyyyMMdd)  
Value `-3` calculates the version number from the current date (yyMMddHH)  

### Example:  
```
C:\PS>.\deploy.ps1 -ModuleName "moduleReloader" -ModuleID "1f617052-8864-0874-a4bc-d495b4fe02bd" -ModuleVersion -2
```

### Setup External Tool in IntelliJ IDEA
Go to Settings > Tools in IntelliJ IDEA and add an external tool, name it `deploy-script` or whatever you like and set the description (e.g. to the same value).  

Enter the value `powershell` to the `Program` field and `-ExecutionPolicy Bypass -file "C:\path\to\_deploy\deploy.ps1" -ModuleName "module-reloader" -ModuleID "1f617052-8864-0874-a4bc-d495b4fe02bd" -ModuleVersion -2` to the `Arguments` field (change the argument values to your own settings).  

Set the `Working directory` field to `C:\path\to\_deploy`.  

At last you can bind a keymap to this new external tool, e.g. `CTRL+SHIFT+ALT+F9`, than you can build and deploy with the two hotkeys `CTRL+SHIFT+F9` and `CTRL+SHIFT+ALT+F9`.

## License
This project is licensed under the [MIT License](LICENSE).