# oobe.then
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
This script is published under [MIT License](license.html).

## Naming
This name comes from the popular continuation passing style of asynchronous programming. The first setup step of Windows is called OOBE (Out-Of-Box Experience) and this script is usually run right after OOBE is done.

## Notice
You should configure the script especially if any of the following is true:

- You are not in China;
- You like Windows Store version (universal Windows app) of OneNote;
- You use Xbox app or Bing News / Sports / Finance;
- You play the game Microsoft Solitare Collection.

## Function
The script:

1. Updates the help content for PowerShell;
2. Disbles the background image (Windows 10 hero image) on Welcome Screen;
3. Removes the appx packages (provisioned and installed) defined in `useless-packages.txt`;
4. Appends the `hosts` file with effective content defined in `add-hosts.txt`.

## Configurability
The four functions are all configurable.

### Updating the help content
To prevent this from running, set `$doNotUpdateHelp` to `$True`. You can do this either by adding the following code at the beginning of the script or running the line before invoking the script:
```PowerShell
$doNotUpdateHelp = $True
```

### Disabling logon background image
To prevent this from running, set `$doNotDisableLogonBackground` to `$True`. You can do this either by adding the following code at the beginning of the script or running the line before invoking the script:
```PowerShell
$doNotDisableLogonBackground = $True
```

### Removing selected appx packages
**WARNING** Once removed, the packages will be hard to recover, since they're completely removed from the online image (i.e., your running copy of Windows). Some packages cannot be installed from Windows Store, e.g., `Microsoft.WindowsStore` package (Windows Store itself). Be careful when removing packages. The preset file configures the script to remove packages that are usually useless and most of them either provide no actual functionality or are reinstallable from Windows Store.

To prevent this from running, set `$doNotRemovePackages` to `$True`. You can do this either by adding the following code at the beginning of the script or running the line before invoking the script:
```PowerShell
$doNotRemovePackages = $True
```

To change the list of appx packages to remove, edit `useless-packages.txt`. The text file should contain the names of all packages you want to remove. See the preset file for an example.

### Appending hosts
**WARNING** You should configure this if you are not in China.

To prevent this from running, set `$doNotEditHosts` to `$True`. You can do this either by adding the following code at the beginning of the script or running the line before invoking the script:
```PowerShell
$doNotEditHosts = $True
```

To change the content appended to the `hosts` file, edit `add-hosts.txt`. The preset file defines the DNS resolution for OneDrive, which is useful in China to workaround the Great Fire Wall.

The script will backup the hosts file before this change. The backup file name is `hosts.old.[some GUID].utc-ts-yyyy-MM-dd-HH-mm-ss`, where `[some GUID]` is a globally unique identifier and `yyyy-MM-dd-HH-mm-ss` is the universal coordinate time when the backup happened. You can find the backup in the `[Windows folder]\System32\drivers\etc` folder and its name in the comments of the edited `hosts` file.
