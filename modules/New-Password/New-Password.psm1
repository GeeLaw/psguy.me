<#

MIT License
Copyright © 2016 by Gee Law
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Website: http://psguy.me/modules/New-Password

Generates a cryptographically-safe password.

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
    [CmdletBinding(HelpUri = 'http://psguy.me/modules/New-Password')]
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

Export-ModuleMember -Function @('New-Password') -Alias @('newpwd') -Cmdlet @() -Variable @();
