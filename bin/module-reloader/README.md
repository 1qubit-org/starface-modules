# STARFACE moduleReloader module

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## Description
Updates a STARFACE module and triggers a reload to memory.  
You can use this standalone with your own scripts or with the `powershell-module-deploy` script of this repo (see `src` folder).

## Table of Contents
- [STARFACE moduleReloader module](#starface-modulereloader-module)
  - [Description](#description)
  - [Table of Contents](#table-of-contents)
  - [Installation](#installation)
  - [Usage](#usage)
    - [Generating the auth hash](#generating-the-auth-hash)
    - [XML-RPC Url](#xml-rpc-url)
    - [XML-RPC Payload](#xml-rpc-payload)
    - [XML-RPC Response](#xml-rpc-response)
  - [License](#license)


## Installation
Manually import the `1QBmoduleReloader_v...sfm` file to your STARFACE server and create a module instance (configuration) of it. Name it as you like but note the instance name, we need it later.

## Usage
As the module uses the xml-rpc interface of the STARFACE server you have to generate the auth string first. Therefore, you need the loginID and the password of a STARFACE user and a hashing tool, e.g. https://gchq.github.io/CyberChef/#recipe=SHA2('512',64,160).  

### Generating the auth hash
First you hash the password, then you take the hash of the password and prefix it with the loginID and an asterisk and hash this string again.

1. SHA512(password)
2. SHA512(loginID*passwordHash)

Finally you prefix this hash with the loginID and a colon
- loginID:SHA512(loginID*SHA512(passwort))

### XML-RPC Url
To use the module you need to send a `POST` request to the xml-rpc interface url of your STARFACE server. The url is `http(s)://starface.domain.tld/xml-rpc?de.vertico.starface.auth=` followed by the auth string generated above.

### XML-RPC Payload
The body / payload of the request has to have the xml structure below.  

The `methodName` tag is the RPC entrypoint name, which is the name of the moduleReloader instance you created before followed by `.reload`, e.g. `1qb.moduleReloader.reload`.  

There are two parameters to be set. The first is `paramModuleID` which has to be set to the id value of the module which should be reloaded by the moduleReloader module (this module).  
The second parameter `paramModuleVersion` is optional. By default (`-1`) it increments the module version to the next higher number (e.g. from 10 to 11). You can pass any `integer` you like to set your own version number.


```
<?xml version='1.0' encoding='UTF-8'?>
<methodCall>
<methodName>1qb.moduleReloader.reload</methodName>
    <params>
        <param>
        <value>
            <struct>
            <member>
                <name>paramModuleID</name>
                <value>
                    <string>1f617052-8864-0874-a4bc-d495b4fe02bd</string>
                </value>
                <name>paramModuleVersion</name>
                <value>
                    <string>1234</string>
                </value>
            </member>          
            </struct>
        </value>
        </param>
    </params>    
</methodCall>
```

### XML-RPC Response
The xml rpc interface sends a xml as response in the `<member>` tag with the `<name>` tag = `retOutput` and a message in the `<value><string>` tag, e.g. _Module 1QB.moduleReloader updated; Version changed from 24030721 to version 24030722._

## License
This project is licensed under the [MIT License](LICENSE).
