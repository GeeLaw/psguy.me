<#

MIT License
Copyright © 2016 by Gee Law
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Website: http://psguy.me/modules/sign

Signs your PowerShell scripts with your certificate.

#>

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
    [CmdletBinding(HelpUri = 'http://psguy.me/modules/sign')]
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

Export-ModuleMember -Function @('sign') -Alias @('sign') -Cmdlet @() -Variable @();
