# CommonUtilities
```bssex
Gee Law: image
{
    "source": "assets/<theme>/icon.png",
    "caption": null,
    "click": false,
    "accessible": true,
    "zoom": 0.8,
    "placement": "right",
    "style": "margin: 0px;"
}
```

## License
This module is published under [MIT License](license.html).

## Get
To install this module for all users, use the following script:
```PowerShell
#Requires -RunAsAdministrator
Install-Module -Name CommonUtilities -Scope AllUsers;
```

To install this module for the current user, use the following script:
```PowerShell
Install-Module -Name CommonUtilities -Scope CurrentUser;
```

## Functions
| Name | Alias(es) | Synopsis |
| --- | --- | --- |
| [New-Password](New-Password.html) | newpwd | Generates a cryptographically-safe password. |
| [Sign-Scripts](Sign-Scripts.html) | sign | Signs your PowerShell scripts with your certificate. |
| [Switch-User](Switch-User.html) | su | A better ‘Run PowerShell as Administrator’ and ‘Run PowerShell as another user’. |
