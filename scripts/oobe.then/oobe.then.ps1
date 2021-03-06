<#

MIT License
Copyright © 2016 by Gee Law
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Website: http://psguy.me/scripts/oobe.then

Updates the PowerShell help content, disable logon background image, remove useless appx (provisioned) packages and edit hosts.

#>

#Requires -RunAsAdministrator

$script:ErrorActionPreference = 'Inquire';

If ($doNotUpdateHelp -ne $true)
{
    Update-Help -Force;
    Write-Host 'Updated help content for PowerShell.';
}

If ($doNotDisableLogonBackground -ne $true)
{
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'DisableLogonBackgroundImage' -Type DWord -Value 1;
    Write-Host 'Disabled logon background image of Welcome Screen.';
}

If ($doNotRemovePackages -ne $true)
{
    $script:packagesToRemove = Get-Content useless-packages.txt;
    Get-AppxPackage -AllUsers | ForEach-Object `
        {
            If ($packagesToRemove.Contains($_.Name))
            {
                Remove-AppxPackage -Package $_.PackageFullName;
                Write-Host "Removed $($_.PackageFullName) from the user.";
            }
        };
    Get-AppxProvisionedPackage -Online | ForEach-Object `
        {
            If ($packagesToRemove.Contains($_.DisplayName))
            {
                Remove-AppxProvisionedPackage -PackageName $_.PackageName -Online | Out-Null;
                Write-Host "Removed (provisioned) $($_.PackageName) from the machine.";
            }
        }
}

If ($doNotEditHosts -ne $true)
{
    $script:hostsPath = [System.IO.Path]::Combine($env:windir, 'System32\drivers\etc\hosts');
    $script:hostsBackup = "$hostsPath.old.$([Guid]::NewGuid().ToString('n')).utc-ts-$([DateTime]::UtcNow.ToString('yyyy-MM-dd-HH-mm-ss'))";
    Copy-Item -Path $hostsPath -Destination $hostsBackup;
    $script:hostsAppendedContent = [Environment]::NewLine;
    $hostsAppendedContent += '# Begin: Hosts added by automatic configuration PowerShell script';
    $hostsAppendedContent += [Environment]::NewLine;
    $hostsAppendedContent += '# To revert the hosts file to what it was before this update, use the following file:';
    $hostsAppendedContent += [Environment]::NewLine;
    $hostsAppendedContent += '# ' + [System.IO.Path]::GetFileName($hostsBackup);
    $hostsAppendedContent += [Environment]::NewLine;
    $hostsAppendedContent += [Environment]::NewLine;
    $hostsAppendedContent += Get-Content -Path 'add-hosts.txt' -Raw;
    $hostsAppendedContent += [Environment]::NewLine;
    $hostsAppendedContent += '#   End: Hosts added by automatic configuration PowerShell script';
    $hostsAppendedContent | Add-Content -Path $hostsPath -Encoding ASCII;
    Write-Host 'Appended specified content to hosts.';
}
