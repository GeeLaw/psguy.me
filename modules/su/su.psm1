<#

MIT License
Copyright © 2016 by Gee Law
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Website: http://psguy.me/modules/su

Switch-User (su).

#>

<#
.Synopsis
    Switches to elevated PowerShell or PowerShell run as another user.

.Description
    When called from an usual PowerShell prompt, it tries to start the elevated PowerShell. If it succeeds, the calling window is hidden. When the elevated PowerShell exits (by invoking exit or any other means), the calling window reappears, providing a seamless experience of elevation.

    The same rule applies for switching to another user.

#>
Function Switch-User
{
    [CmdletBinding(HelpUri = 'http://psguy.me/modules/su')]
    [Alias('su')]
    Param
    (
        [Parameter()]
        [Alias('user', 'as', 'to')]
        [System.Management.Automation.PSCredential]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )
    Process
    {
        $local:ErrorActionPreference = 'Stop';
        $local:IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator');
        $local:currentPathUnicodeBase64 = [System.Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes((Get-Location).Path));
        $local:suProcessInitCmd = '& { ';
        $suProcessInitCmd += 'Set-Location -Path ([System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String(';
        $suProcessInitCmd += "'";
        $suProcessInitCmd += $currentPathUnicodeBase64;
        $suProcessInitCmd += "'";
        $suProcessInitCmd += '))); ';
        $suProcessInitCmd += '}';
        $local:suProcess = $null;
        $local:currentProcess = $null;
        $local:wasVisible = $true;
        If ($IsAdmin -and [object]::ReferenceEquals($Credential, [System.Management.Automation.PSCredential]::Empty))
        {
            $Credential = Get-Credential -Message 'Please specify the credential to run PowerShell.';
            If ($Credential -eq $null)
            {
                Write-Error 'Action cancelled by user.';
                Return;
            }
        }
        If ([object]::ReferenceEquals($Credential, $null) -or [object]::ReferenceEquals($Credential, [System.Management.Automation.PSCredential]::Empty))
        {
            $suProcess = Start-Process -PassThru -FilePath 'PowerShell.exe' -Verb 'runas' `
                -ArgumentList '-NoExit', '-Command', $suProcessInitCmd;
            If ($suProcess -eq $null)
            {
                Return;
            }
            Write-Verbose "Another process started on $($suProcess.StartTime), ProcessId = $($suProcess.Id).";
            $currentProcess = Get-Process -Id $pid;
            $wasVisible = [__3b043047842e4cfa94dbcb39a5ccf3e5.SwitchUser]::ShowWindow($currentProcess.MainWindowHandle, 0);
            $suProcess.WaitForExit();
            Write-Verbose "The process exited on $($suProcess.ExitTime).";
            If ($suProcess.ExitCode -eq 0)
            {
                Write-Verbose 'The process exited with code 0.';
            }
            Else
            {
                Write-Host "The process exited with code $($suProcess.ExitCode).";
            }
        }
        Else
        {
            $suProcess = Start-Process -PassThru -FilePath 'PowerShell.exe' `
                -ArgumentList '-NoExit', '-Command', $suProcessInitCmd -Credential $Credential;
            If ($suProcess -eq $null)
            {
                Return;
            }
            Write-Verbose "Another process started on $($suProcess.StartTime), ProcessId = $($suProcess.Id).";
            $currentProcess = Get-Process -Id $pid;
            $wasVisible = [__3b043047842e4cfa94dbcb39a5ccf3e5.SwitchUser]::ShowWindow($currentProcess.MainWindowHandle, 0);
            $suProcess.WaitForExit();
            <# Running as another user will not give ExitTime and ExitCode. #>
        }
        If ($wasVisible)
        {
            [__3b043047842e4cfa94dbcb39a5ccf3e5.SwitchUser]::ShowWindow($currentProcess.MainWindowHandle, 5) | Out-Null;
            [__3b043047842e4cfa94dbcb39a5ccf3e5.SwitchUser]::SwitchToThisWindow($currentProcess.MainWindowHandle, $True);
            [__3b043047842e4cfa94dbcb39a5ccf3e5.SwitchUser]::BringWindowToTop($currentProcess.MainWindowHandle) | Out-Null;
            If (-not [__3b043047842e4cfa94dbcb39a5ccf3e5.SwitchUser]::SetForegroundWindow($currentProcess.MainWindowHandle))
            {
                Write-Error 'Failed to recover the hidden window.';
            }
        }
        Return;
    }
}

Export-ModuleMember -Function @('Switch-User') -Alias @('su') -Cmdlet @() -Variable @();
