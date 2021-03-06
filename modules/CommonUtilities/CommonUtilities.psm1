<#

MIT License
Copyright © 2016 by Gee Law
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Website: http://psguy.me/modules/CommonUtilities

#>

<#
.Synopsis
    Generates a cryptographically-safe password.

.Description
    The cmdlet generates strong passwords with cryptographically-safe random number generator.

    By default this cmdlets generates a password of length 16 with upper case, lower case, numeral and special characters.

    "newpwd" is the alias of this cmdlet.

.Parameter Length
    The length of the output. It must be at least 4 and at most 256. The default is 16.

.Parameter RNGImplementation
    The name of the implementation of cryptographically-safe random number generation algorithm.

    "RNGAlgorithm" and "RNG" are the aliases of this parameter.

.Parameter NoUpperCaseCharacters
    Suppresses upper case characters from the output. These include ABCDEFGHIJKLMNOPQRSTUVWXYZ.

    "NoUC" is the alias of this switch.

.Parameter NoLowerCaseCharacters
    Suppresses lower case characters from the output. These include abcdefghijklmnopqrstuvwxyz.

    "NoLC" is the alias of this switch.

.Parameter NoNumeralCharacters
    Suppresses numeral characters from the output. These include 0123456789.

    "NoNum" is the alias of this switch.

.Parameter NoSpecialCharacters
    Suppresses special characters from the output. These include `~!@#$%^&*()_+-={}[]|\;':"<>?,./ and space.

    "NoSpecial" is the alias of this switch.

.Parameter AllowSimilarCharacters
    Allowes similar characters in the output. These include 1, l and I, 0 and O and `, ' and ".

.Parameter AllowSpace
    Allowes the space character in the output.

.Parameter UseSecureString
    Pipes out a System.Security.SecureString instead of string.

.Parameter Elder
    Forces the output to end with "+1s". If this switch is set, -UseSecureString will be cleared even if set explicitly. However, NONE of -NoLowerCaseCharacters, -NoNumeralCharacters and -NoSpecialCharacters are required to be cleared.

    "ls" is the alias of this switch. Therefore you get one second subtracted if you extend the elder's life for one second.

.Example
    New-Password -Length 20 -AllowSimilarCharacters

    This creates a 20-character long password possibly with similar characters.

    Possible output: "X9kw5Bc2~W^16EzuU]jJ"

.Example
    New-Password -NoSpecialCharacters -UseSecureString

    This creates a 16-character long password without special characters as a SecureString.

    Possible output: A System.Security.SecureString object.

.Example
    New-Password -Elder

    This creates a 16-character long password that ends with "+1s".

    Possible output: ">nvaM!$HAAr;v+1s"

#>
Function New-Password
{
    [CmdletBinding(HelpUri = 'http://psguy.me/modules/CommonUtilities/New-Password.html')]
    [Alias('newpwd')]
    Param
    (
        [Parameter(ValueFromPipeline = $true)]
        [ValidateRange(4, 256)]
        [int]$Length = 16,
        [Alias("RNGAlgorithm", "RNG")]
        [string]$RNGImplementation,
        [Alias("NoUC")]
        [switch]$NoUpperCaseCharacters,
        [Alias("NoLC")]
        [switch]$NoLowerCaseCharacters,
        [Alias("NoNum")]
        [switch]$NoNumeralCharacters,
        [Alias("NoSpecial")]
        [switch]$NoSpecialCharacters,
        [switch]$AllowSimilarCharacters,
        [switch]$AllowSpace,
        [switch]$UseSecureString,
        [Alias("ls", "o-o")]
        [switch]$Elder
    )
    Process
    {
        $local:uc = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
        $local:lc = 'abcdefghijkmnopqrstuvwxyz';
        $local:nu = '234567892345678923456789';
        $local:sp = '~!@#$%^&*()_+{}|[]\-=:;<>?,./';
        If ($AllowSimilarCharacters)
        {
            $uc += 'IO'; $lc += 'l';
            $nu += '010101'; $sp += "'" + '`"';
        }
        If ($AllowSpace)
        {
            $sp += ' ';
        }
        $local:lib = '';
        If (-not $NoUpperCaseCharacters)
        {
            $lib += $uc;
        }
        If (-not $NoLowerCaseCharacters)
        {
            $lib += $lc;
        }
        If (-not $NoNumeralCharacters)
        {
            $lib += $nu;
        }
        If (-not $NoSpecialCharacters)
        {
            $lib += $sp;
        }
        If ($lib.Length -eq 0)
        {
            Write-Error 'At least one category of characters must be allowed.';
            Return;
        }
        If ($Elder)
        {
            If ($UseSecureString)
            {
                Write-Warning '-UseSecureString is cleared by -Elder.';
            }
            $UseSecureString = $false;
            <# Sets these switches so that the algorithm no longer checks them.
             # But $lib already contains the specified characters, therefore
             # the generation rule is still correct.
             #>
            $NoLowerCaseCharacters = $true;
            $NoNumeralCharacters = $true;
            $NoSpecialCharacters = $true;
            $Length -= 3;
        }
        $local:rnd = $null;
        If ([string]::IsNullOrEmpty($RNGImplementation))
        {
            $rnd = New-Object -TypeName 'System.Security.Cryptography.RNGCryptoServiceProvider';
        }
        Else
        {
            $rnd = New-Object -TypeName 'System.Security.Cryptography.RNGCryptoServiceProvider' -ArgumentList $RNGImplementation;
        }
        $local:result = $null;
        $local:byteHolder = New-Object -TypeName 'byte[]' -ArgumentList @(1);
        If ($UseSecureString)
        {
            <# This instance will be disposed immediately in the first round of the loop. #>
            $result = New-Object -TypeName 'System.Security.SecureString';
        }
        $local:hasUC = $false; $local:hasLC = $false; $local:hasNU = $false; $local:hasSP = $false;
        $local:trimming = $false;
        $local:i = 0;
        Do
        {
            $hasUC = $false; $hasLC = $false; $hasNU = $false; $hasSP = $false;
            $trimming = $false;
            If ($UseSecureString)
            {
                $result.Dispose();
                $result = New-Object -TypeName 'System.Security.SecureString';
                For ($i = 0; $i -lt $Length; ++$i)
                {
                    Do
                    {
                        $rnd.GetBytes($byteHolder);
                    }
                    Until ([int]($byteHolder[0] / $lib.Length) -ne [int](256 / $lib.Length));
                    $result.AppendChar($lib[$byteHolder[0] % $lib.Length]);
                    If ($uc.Contains($lib[$byteHolder[0] % $lib.Length]))
                    {
                        $hasUC = $true;
                    }
                    If ($lc.Contains($lib[$byteHolder[0] % $lib.Length]))
                    {
                        $hasLC = $true;
                    }
                    If ($nu.Contains($lib[$byteHolder[0] % $lib.Length]))
                    {
                        $hasNU = $true;
                    }
                    If ($sp.Contains($lib[$byteHolder[0] % $lib.Length]))
                    {
                        $hasSP = $true;
                    }
                    if ($lib[$byteHolder[0] % $lib.Length] -eq ' '[0] -and ($i -eq 0 -or $i -eq ($Length - 1)))
                    {
                        $trimming = $true;
                    }
                }
                $result.MakeReadOnly();
            }
            Else
            {
                $result = '';
                For ($i = 0; $i -lt $Length; ++$i)
                {
                    Do
                    {
                        $rnd.GetBytes($byteHolder);
                    }
                    Until ([int]($byteHolder[0] / $lib.Length) -ne [int](256 / $lib.Length));
                    $result += $lib[$byteHolder[0] % $lib.Length];
                    If ($uc.Contains($lib[$byteHolder[0] % $lib.Length]))
                    {
                        $hasUC = $true;
                    }
                    If ($lc.Contains($lib[$byteHolder[0] % $lib.Length]))
                    {
                        $hasLC = $true;
                    }
                    If ($nu.Contains($lib[$byteHolder[0] % $lib.Length]))
                    {
                        $hasNU = $true;
                    }
                    If ($sp.Contains($lib[$byteHolder[0] % $lib.Length]))
                    {
                        $hasSP = $true;
                    }
                }
                If ($Elder)
                {
                    $result += '+1s';
                }
                If ($result[0] -eq ' '[0] -or $result[$result.Length - 1] -eq ' '[0])
                {
                    $trimming = $true;
                }
            }
            $byteHolder[0] = 0;
        }
        Until (-not $trimming -and ($NoUpperCaseCharacters -or $hasUC) -and ($NoLowerCaseCharacters -or $hasLC) -and ($NoNumeralCharacters -or $hasNU) -and ($NoSpecialCharacters -or $hasSP));
        $rnd.Dispose();
        Return $result;
    }
}


<#
.Synopsis
    Switches to elevated PowerShell or PowerShell run as another user.

.Description
    When called from an usual PowerShell prompt, it tries to start the elevated PowerShell. If it succeeds, the calling window is hidden. When the elevated PowerShell exits (by invoking exit or any other means), the calling window reappears, providing a seamless experience of elevation.

    The same rule applies for switching to another user.

#>
Function Switch-User
{
    [CmdletBinding(HelpUri = 'http://psguy.me/modules/CommonUtilities/Switch-User.html')]
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
        If ($Host.Name -ne 'ConsoleHost')
        {
            Write-Error 'This cmdlet can only be invoked from PowerShell.';
            Return;
        }
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


Function Write-CertificateOnHost
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate
    )
    Process
    {
        Write-Host "           Subject: $($Certificate.Subject)";
        Write-Host "            Issuer: $($Certificate.Issuer)";
        Write-Host "         Issued on: $($Certificate.NotBefore)";
        Write-Host "     Serial Number: $($Certificate.SerialNumber)";
        Write-Host "        Thumbprint: $($Certificate.Thumbprint)";
        Write-Host "     Valid through: $($Certificate.NotAfter)";
        Write-Host;
    }
}


<#
.Synopsis
    A shortcut for Set-AuthenticodeSignature.

.Description
    Use this cmdlet to sign your code (PowerShell scripts, modules, manifests and so on). When no certificate is supplied, the cmdlet tries to use your code-signing certificate(s).

    "sign" is the alias of this cmdlet.

.Parameter Scripts
    The path of the scripts to sign. This parameter is mandatory.

.Parameter Certificate
    The certificate to use.

    If unspecified, the cmdlet enumerates all your personal code-signing certificates. If there is only one such certificate, the scripts are signed with this certificate; otherwise you interactively choose one certificate. If no such certificate is found, the cmdlet fails.

.Example
    sign -Scripts $profile

    This line signs your profile script with your personal code-signing certificate(s).

.Example
    Get-ChildItem -File -Recurse | ForEach-Object { sign -Scripts $_.FullName }

    This line signs all the files (including those in subfolders) with your personal code-signing certificate(s). This line works best if you have one and only one such certificate in your personal store.

#>
Function Sign-Scripts
{
    [CmdletBinding(HelpUri = 'http://psguy.me/modules/CommonUtilities/Sign-Scripts.html')]
    [Alias('sign')]
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string[]]$Scripts,
        [Parameter()]
        [Alias("cert", "with")]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate
    )
    Process
    {
        $local:ErrorActionPreference = 'Stop';
        If ($Certificate -eq $null)
        {
            $local:certs = Get-ChildItem -Path 'Cert:\CurrentUser\My' -CodeSigningCert;
            If ($certs.Length -eq 1)
            {
                Write-Host 'Signing code with the following certificate:';
                Write-CertificateOnHost -Certificate $certs[0];
                $Certificate = $certs[0];
            }
            ElseIf ($certs.Length -gt 1)
            {
                Write-Host 'Multiple certificates are available in your personal storage.';
                Write-Host;
                $local:i = 0;
                $certs | ForEach-Object `
                    -Process `
                    {
                        Write-Host "Certificate[$i]:";
                        Write-CertificateOnHost $_;
                        $i = $i + 1;
                    };
                $local:choice = Read-Host -Prompt 'Please specify the certificate';
                $local:choiceInt = 0;
                If ([int]::TryParse($choice, [ref] $choiceInt))
                {
                    If ($choiceInt -ge 0 -and $choiceInt -lt $certs.Length)
                    {
                        $Certificate = $certs;
                    }
                    Else
                    {
                        Throw [IndexOutOfRangeException];
                    }
                }
                Else
                {
                    Throw [FormatException] 'You must specifiy an index.';
                }
            }
            Else
            {
                throw [Exception] 'You do not have a certifcate in your personal storage. Please specify the certificate in the command.';
            }
        }
        if ($Certificate -ne $null)
        {
            Set-AuthenticodeSignature -FilePath $Scripts -Certificate $Certificate;
        }
    }
}

Export-ModuleMember -Function @('New-Password', 'Switch-User', 'Sign-Scripts') -Alias @('newpwd', 'su', 'sign') -Cmdlet @() -Variable @();
