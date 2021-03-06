<#

MIT License
Copyright © 2016 by Gee Law
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Website: http://psguy.me/modules/Use-RawPipeline

#>


<#
.Synopsis
    Uses raw pipeline to invoke a native utility.

.Description
    The cmdlet invokes a native utility with raw pipeline enabled.

    It outputs a RawPipelineObject if the stdout of the utility should be piped down.

.Parameter Command
    Mandatory. The native utility to be invoked.

    Position 0.

.Parameter ArgumentList
    Optional. The list of arguments to be supplied to the native utility.

    Value from remaining parameters.

.Parameter AllowNewWindow
    The negation of NoNewWindow.

.Parameter RedirectStandardInput
    Optional, value from pipeline. The standard input for the native utility.

    If omitted, the standard input is PowerShell host.

    Piping a string into this parameter will give file redirection.

    This argument is intended to be piped from a prior invocation of Use-RawPipeline.

.Parameter RedirectStandardOutput
    Optional. Redirect the output (binarily) into the specified file.

    If supplied, the standard output will not be piped down unless PassThru is on.

.Parameter PassThru
    Instructs the cmdlet to pipe the standard output down even RedirectStandardOutput is supplied.

.Parameter StandardErrorHandler
    Optional. A script block to handle stderr output.

    If omitted, stderr output will be Written-Error.

.Parameter ForceStandardErrorHandler
    By default, StandardErrorHandler will not be invoked if the length of stderr is zero. If this switch is on, the handler will always be invoked.

.Example
    Use-RawPipeline -Command 'git' -ArgumentList @('format-patch', 'HEAD~3') -RedirectStandardOutput 'patch.patch' -PassThru;

    This gives the correct output of git to patch.patch and pipes the standard output down.

    Note that using "git format-patch HEAD~3 > patch.patch" gives corrupted patch file.

.Example
    $ git format-patch HEAD~3 -stdout patch.patch

    A succinct version of the prior example.

#>
Function Use-RawPipeline
{
    [CmdletBinding(DefaultParameterSetName = 'NoStdinNoArgsPipe', HelpUri = 'https://psguy.me/modules/Use-RawPipeline')]
    [OutputType([PSGuy.UseRawPipeline.RawPipelineObject])]
    [Alias('$')]
    Param
    (
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'NoStdinPipe')]
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'HasStdinPipe')]
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'NoStdinRedirect')]
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'HasStdinRedirect')]
        [string]$Command,
        [Parameter(ValueFromRemainingArguments = $true, ParameterSetName = 'NoStdinPipe')]
        [Parameter(ValueFromRemainingArguments = $true, ParameterSetName = 'HasStdinPipe')]
        [Parameter(ValueFromRemainingArguments = $true, ParameterSetName = 'NoStdinRedirect')]
        [Parameter(ValueFromRemainingArguments = $true, ParameterSetName = 'HasStdinRedirect')]
        [Alias('args')]
        [AllowNull()]
        [AllowEmptyCollection()]
        [string[]]$ArgumentList = @(),
        [Parameter(ParameterSetName = 'NoStdinPipe')]
        [Parameter(ParameterSetName = 'HasStdinPipe')]
        [Parameter(ParameterSetName = 'NoStdinRedirect')]
        [Parameter(ParameterSetName = 'HasStdinRedirect')]
        [switch]$AllowNewWindow,
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'HasStdinPipe')]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'HasStdinRedirect')]
        [Alias('stdin')]
        [PSGuy.UseRawPipeline.RawPipelineObject]$RedirectStandardInput,
        [Parameter(Mandatory = $true, ParameterSetName = 'NoStdinRedirect')]
        [Parameter(Mandatory = $true, ParameterSetName = 'HasStdinRedirect')]
        [Alias('stdout')]
        [string]$RedirectStandardOutput,
        <# This parameter is not respected if the parameter set is Pipe -- it's always thought to be true. #>
        [Parameter(ParameterSetName = 'NoStdinPipe')]
        [Parameter(ParameterSetName = 'HasStdinPipe')]
        [Parameter(ParameterSetName = 'NoStdinRedirect')]
        [Parameter(ParameterSetName = 'HasStdinRedirect')]
        [switch]$PassThru,
        [Alias('stderr')]
        [ScriptBlock]$StandardErrorHandler =
        {
            $local:stderrContent = Get-Content -LiteralPath $_ -Raw;
            If ($local:stderrContent.Length -ne 0)
            {
                Write-Error -Message $local:stderrContent `
                    -Category ([System.Management.Automation.ErrorCategory]::FromStdErr);
            }
        },
        [Parameter(ParameterSetName = 'NoStdinPipe')]
        [Parameter(ParameterSetName = 'HasStdinPipe')]
        [Parameter(ParameterSetName = 'NoStdinRedirect')]
        [Parameter(ParameterSetName = 'HasStdinRedirect')]
        [switch]$ForceStandardErrorHandler
    )
    Process
    {
        [PSGuy.UseRawPipeline.RawPipelineObject]$local:Stdout = [PSGuy.UseRawPipeline.RawPipelineObject]::new();
        [PSGuy.UseRawPipeline.RawPipelineObject]$local:Stderr = [PSGuy.UseRawPipeline.RawPipelineObject]::new();
        If ($PSCmdlet.ParameterSetName.StartsWith('HasStdin'))
        {
            If ([object]::ReferenceEquals($ArgumentList, $null) -or $ArgumentList.Length -eq 0)
            {
                Start-Process -FilePath $Command `
                    -NoNewWindow:(-not $AllowNewWindow) `
                    -RedirectStandardInput ($RedirectStandardInput.GetFileName()) `
                    -RedirectStandardOutput ($local:Stdout.GetFileName()) `
                    -RedirectStandardError ($local:Stderr.GetFileName()) `
                    -Wait | Out-Null;
            }
            Else
            {
                Start-Process -FilePath $Command -ArgumentList $ArgumentList `
                    -NoNewWindow:(-not $AllowNewWindow) `
                    -RedirectStandardInput ($RedirectStandardInput.GetFileName()) `
                    -RedirectStandardOutput ($local:Stdout.GetFileName()) `
                    -RedirectStandardError ($local:Stderr.GetFileName()) `
                    -Wait | Out-Null;
            }
        }
        Else
        {
            If ([object]::ReferenceEquals($ArgumentList, $null) -or $ArgumentList.Length -eq 0)
            {
                Start-Process -FilePath $Command `
                    -NoNewWindow:(-not $AllowNewWindow) `
                    -RedirectStandardOutput ($local:Stdout.GetFileName()) `
                    -RedirectStandardError ($local:Stderr.GetFileName()) `
                    -Wait | Out-Null;
            }
            Else
            {
                Start-Process -FilePath $Command -ArgumentList $ArgumentList `
                    -NoNewWindow:(-not $AllowNewWindow) `
                    -RedirectStandardOutput ($local:Stdout.GetFileName()) `
                    -RedirectStandardError ($local:Stderr.GetFileName()) `
                    -Wait | Out-Null;
            }
        }
        If ($PSCmdlet.ParameterSetName.EndsWith('Redirect'))
        {
            Copy-Item -LiteralPath ($local:Stdout.GetFileName()) -Destination $RedirectStandardOutput | Out-Null;
        }
        If ($PSCmdlet.ParameterSetName.EndsWith('Pipe') -or $PassThru)
        {
            $local:Stdout;
        }
        If ($ForceStandardErrorHandler -or (Get-Item -LiteralPath ($local:Stderr.GetFileName())).Length -ne 0)
        {
            @($local:Stderr.GetFileName()) | ForEach-Object -Process $StandardErrorHandler | Out-Null;
        }
    }
}

<#
.Synopsis
    Converts the raw pipeline result like Getting-Content from a file.

.Description
    The cmdlet converts `RawPipelineObject` obtained by, possibly a series of, invocations of `Use-RawPipeline`. It works like `Get-Content` and you can work with any encoding supported by `Get-Content`, which means `byte[]` included.

.Parameter InputObject
    Mandatory, value from pipeline. The raw pipeline result to be converted.

.Parameter Delimiter
    Optional. Equivalent to `Delimiter` parameter of `Get-Content`.

.Parameter Encoding
    Equivalent to `Encoding` parameter of `Get-Content`.

.Parameter Raw
    Equivalent to `Raw` switch of `Get-Content`.

.Parameter Force
    Equivalent to `Force` switch of `Get-Content`.

.Example
    $result = Use-RawPipeline -Command 'git' `
        -ArgumentList @('format-patch', 'HEAD~3') |
        ConvertFrom-RawPipeline -Encoding Byte;

    This stores the raw output of git command into $result (as a byte array).

.Example
    $result = $ git format-patch HEAD~3 | ~ -e byte

    A succinct version of the prior example.

#>
Function ConvertFrom-RawPipeline
{
    [CmdletBinding(DefaultParameterSetName = 'Raw', HelpUri = 'https://psguy.me/modules/Use-RawPipeline')]
    [Alias('~')]
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'Raw')]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'Delimiter')]
        [Alias('StandardInput', 'stdin', 'StandardOutput', 'stdout')]
        [PSGuy.UseRawPipeline.RawPipelineObject]$InputObject,
        [Parameter(Mandatory = $true, ParameterSetName = 'Delimiter')]
        [AllowNull()]
        [string]$Delimiter = $null,
        [Parameter(ParameterSetName = 'Raw')]
        [Parameter(ParameterSetName = 'Delimiter')]
        [Alias('form')]
        [string]$Encoding = 'Default',
        [Parameter(ParameterSetName = 'Raw')]
        [switch]$Raw,
        [Parameter(ParameterSetName = 'Raw')]
        [Parameter(ParameterSetName = 'Delimiter')]
        [switch]$Force
    )
    Process
    {
        If ($PSCmdlet.ParameterSetName -eq 'Raw')
        {
            Get-Content -LiteralPath ($InputObject.GetFileName()) -Encoding $Encoding -Raw:$Raw -Force:$Force;
        }
        Else
        {
            Get-Content -LiteralPath ($InputObject.GetFileName()) -Delimiter $Delimiter -Encoding $Encoding -Force:$Force;
        }
    }
}

Export-ModuleMember -Function @('Use-RawPipeline', 'ConvertFrom-RawPipeline') -Cmdlet @() -Variable @() -Alias @('$', '~');
