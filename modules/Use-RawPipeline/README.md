# Use-RawPipeline
This module provides better raw pipeline than PowerShell 5.

## License
This module is published under [MIT License](license.html).

## Get
To install this module for all users, use the following script:

```PowerShell
#Requires -RunAsAdministrator
Install-Module -Name Use-RawPipeline -Scope AllUsers;
```

To install this module for the current user, use the following script:
```PowerShell
Install-Module -Name Use-RawPipeline -Scope CurrentUser;
```

## Motive
PowerShell, up to version 5, does not work well with native utilities. This is in the OO nature of PowerShell. When invoking a native utility, for example:

```PowerShell
git format-patch HEAD~3
```

PowerShell converts the output of `git` command into a string (encoding guessed by PowerShell), then splits it by line and finally returns it as an `object[]`. This causes many problems, one of which is that the native utility pipe chain breaks because PowerShell uses UTF16LE as the default encoding and CRLF as the default line-ending character sequence. Since the output has been parsed as an object, PowerShell is unable to recover the encoding and the line-ending sequence, resulting in misformed content piped to the next command.

For example, the following command will create a text file with UTF16LE encoding and CRLF line-ending sequence, making the `patch.patch` unusable by `git apply`:

```PowerShell
PS > git format-patch HEAD~3 > patch.patch
```

However, a bash user expects the binary form of `stdout` of `git` to be written to `patch.patch`, as it is in the following scenario:

```bash
$ git format-patch HEAD~3 > patch.patch
```

This module resolves this issue.

## How does this work?
Easy. The raw pipeline uses temporary files to store intermediate streams.

## `PSGuy.UseRawPipeline.RawPipelineObject` class
This class is used to hold a file, temporary or permanent.

The class is not intended to be used by the user, instead, it is convertible from string (as a path), and generated and consumed by cmdlets in thie module.

## `Use-RawPipeline` cmdlet
The cmdlet invokes a native utility with raw pipeline enabled. It outputs a `RawPipelineObject` if the `stdout` of the utility should be piped down. The alias of this cmdlet is `$`, inspired by bash.

- `[string]$Command`
    - **Mandatory**;
    - Position 0;
    - The native utility to be invoked.
- `[string[]]$ArgumentList`
    - Optional, default to empty array;
    - Remaining parameters;
    - The command-line arguments for the native utility.
- `[switch]$AllowNewWindow`
    - Optional;
    - The negation of `NoNewWindow` for `Start-Process`;
- `[RawPipelineObject]$RedirectStandardInput`
    - Optional;
    - Value **from pipeline**;
    - Alias: `stdin`;
    - If omitted, the input comes from PowerShell host;
    - The `stdin` stream for the native utility.
- `[string]$RedirectStandardOutput`
    - Optional;
    - Alias: `stdout`;
    - If omitted, `stdout` of this utility goes down the pipe in its raw form;
    - If provided, the standard output will go to the file and will, by default, not be passed down the pipe;
- `[switch]$PassThru`
    - Optional;
    - If on, the standard output will always go down the pipe regardless of redirection;
    - You can tee the output by using `RedirectStandardOutput` and `PassThru`;
- `[ScriptBlock]$StandardErrorHandler`
    - Optional;
    - Alias: `stderr`;
    - If omitted and if there is content in `stderr`, the `stderr` is `Written-Error`;
    - For further documentation, see Appendix;
- `[switch]$ForceStandardErrorHandler`
    - Optional;
    - If off, the standard error handler (`StandardErrorHandler`) will not be called if the length of `stderr` stream is zero;
    - If on, the standard error handler is always called regardless of the length of `stderr`;
    - Default handler is silent when called with a zero-length `stderr`.

## `ConvertFrom-RawPipeline` cmdlet
The cmdlet converts `RawPipelineObject` obtained by, possibly a series of, invocations of `Use-RawPipeline`. It works like `Get-Content` and you can work with any encoding supported by `Get-Content`, which means `byte[]` included. The alias of this cmdlet is `~`.

- `[RawPipelineObject]$InputObject`
    - **Mandatory**;
    - Value **from pipeline**;
    - Aliases: `StandardInput`, `stdin`, `StandardOutput`, `stdout`;
    - The raw pipeline object to be `Got-Content`;
- `[string]$Delimiter`
    - Optional;
    - Equivalent to `Delimiter` parameter of `Get-Content`;
- `[string]$Encoding`
    - Optional;
    - Equivalent to `Encoding` parameter of `Get-Content`;
- `[switch]$Raw`
    - Optional;
    - Equivalent to `Raw` switch of `Get-Content`;
- `[switch]$Force`
    - Optional;
    - Equivalent to `Force` switch of `Get-Content`.

## Examples
To make the example in the motive work correctly, use the following commands:

```PowerShell
PS > $ git format-patch HEAD~3 -stdout patch.patch
PS > $ git format-patch HEAD~3 | ~ -Encoding Byte |
   >     sc patch.patch -Encoding Byte
```

Say your Node.js script is a Markdown compiler and output HTML with Chinese characters, if the encoding guessed by PowerShell is perfectly wrong (which is often the case), then you get a holy crap of output by invoking `node build-blog.js`. Now, with `Use-RawPipeline`, you can avoid this. For this example, I would like to use the full names since I really do this in my blog building script.

```PowerShell
PS > $result = Use-RawPipeline -Command 'node' `
   >     -ArgumentList @('build-page.js', 'entry.md') |
   >     ConvertFrom-RawPipeline -Encoding UTF8 -Raw;
PS > # Imaginary cmdlet to further compile the blog entry.
PS > $result = Replace-PlaceholdersInEntry -InputObject $result;
PS > # Save the entry in UTF8 without BOM.
PS > [System.IO.File]::WriteAllText($compiledEntryPath, $result);
PS >
```

## Appendix
### `StandardErrorHandler` script block
The script block will receive `$_` as the temporary file name of `stderr` stream. The file can be deleted after the invocation completes, therefore if you need the file, copy it to another place.

The current implementaton is:

```PowerShell
# Default StandardErrorHandler.
$local:stderrContent = Get-Content -LiteralPath $_ -Raw;
If ($local:stderrContent.Length -ne 0)
{
    Write-Error -Message $local:stderrContent `
        -Category ([System.Management.Automation.ErrorCategory]::FromStdErr);
}
```
