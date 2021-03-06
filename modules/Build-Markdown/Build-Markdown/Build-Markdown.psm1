$script:BuildMarkdownExtensions = @{};

Function Get-NormalizedExtensionName
{
    [CmdletBinding()]
    [OutputType([string])]
    Param
    (
        [Parameter(Mandatory = $true)]
        [string]$InputObject
    )
    Process
    {
        Return [System.Text.RegularExpressions.Regex]::Replace([System.Text.RegularExpressions.Regex]::Replace($InputObject, '\b', ' '), '\s+', ' ').ToLowerInvariant();
    }
}

<#
.Synopsis
    Builds a Markdown file.

.Description
    The cmdlet first compiles the Markdown file with Compile-Markdown. Then it processes elements eligible for extensions. To intall an extension, use Install-BuildMarkdownExtension. To uninstall an extension, user Uninstall-BuildMarkdownExtension.

.Parameter FilePath
    The path of the Markdown file to be built.

.Parameter ConvertMarkdownToHtml
    The command to convert Markdown to HTML. Default is to use Convert-MarkdownToHtmlWithGitHubAPI cmdlet.

    The script block should accept one parameter:

    Param
    (
        [string]$FilePath
    )

.Parameter Template
    The URL of the template page. There must be exactly one occurence of placeholder in the template content, which will be replaced by generated HTML. If the template is about:blank, the compiled HTML is inserted into body element.

    Hint: the template page can contain extensions.

.Parameter TemplatePlaceholder
    The placeholder of the template, which should occur exactly once and will be replaced by the HTML compiled from the Markdown. The default value is "build-markdown-placeholder".

.Parameter ExtensionLanguage
    The language on which extensions are applied.

    Extension processes are run for and only for <pre lang="$ExtensionLanguage">...</pre> elements.

.Parameter PreBuildAction
    Specifies the action to be done to the DOM right after the HTML compiled from the Markdown file is populated.

    The script block should accept two parameters:

    Param
    (
        [HashTable]$Context,
        [System.ComObject__]$Document
    )

.Parameter PostBuildAction
    Specifies the action to be done to the DOM after all extensions have been processed (if successfully).

    The script block should accept two parameters:

    Param
    (
        [HashTable]$Context,
        [System.ComObject__]$Document
    )

.Parameter OutputTransformer
    Specifies the output transformer. Default is identity mapping.

    The script block should accept two parameters:

    Param
    (
        [HashTable]$Context,
        [string]$Output
    )

.Parameter Force
    If this switch is on, non-fatal errors are reported as warnings.

.Example
    Build-Markdown -FilePath README.md | Out-File README.html -Encoding UTF8

    This example builds README.md into README.html.

.Link
    Install-BuildMarkdownExtension
    Uninstall-BuildMarkdownExtension
    Convert-MarkdownToHtmlWithGitHubAPI

#>
Function Build-Markdown
{
    [CmdletBinding(HelpUri = '')]
    [OutputType([string])]
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Alias('File', 'Path')]
        [string]$FilePath,
        [Parameter()]
        [ScriptBlock]$ConvertMarkdownToHtml = { Param ($FilePath) Return Convert-MarkdownToHtmlWithGitHubAPI -FilePath $FilePath; },
        [Parameter()]
        [string]$Template = 'about:blank',
        [Parameter()]
        [Alias('Placeholder')]
        [string]$TemplatePlaceholder = 'build-markdown-placeholder',
        [Parameter()]
        [Alias('Extension', 'Language', 'ext', 'lang')]
        [string]$ExtensionLanguage = $null,
        [Parameter()]
        [Alias('before', 'first', 'pre')]
        [ScriptBlock]$PreBuildAction = { Param ($Context, $Document) },
        [Parameter()]
        [Alias('after', 'last', 'post')]
        [ScriptBlock]$PostBuildAction = { Param ($Context, $Document) },
        [Parameter()]
        [Alias('transform', 'output')]
        [ScriptBlock]$OutputTransformer = { Param ($Context, $Output) Return $Output; },
        [Parameter()]
        [Switch]$Force
    )
    Process
    {
        $local:ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop;
        If ([string]::IsNullOrWhiteSpace($ExtensionLanguage))
        {
            $ExtensionLanguage = 'bssex';
        }
        $local:WhitespaceRemoveRegex = [System.Text.RegularExpressions.Regex]::new('\s+');
        $local:ExtensionContext = @{};
        $local:ExtensionRegex = [System.Text.RegularExpressions.Regex]::new('^\s*(?<name>.+?)((\r|\n)+(?<source>.*))?$', `
            [System.Text.RegularExpressions.RegexOptions]::Singleline);
        $local:ShouldPopLocation = $false;
        $ExtensionLanguage = $local:WhitespaceRemoveRegex.Replace($ExtensionLanguage, '').ToLowerInvariant();
        Try
        {
            If ($Template.Trim().ToLowerInvariant().StartsWith("http:") `
                -or $Template.Trim().ToLowerInvariant().StartsWith("https:"))
            {
                $Template = (Invoke-WebRequest -Uri $Template).Content;
            }
            ElseIf ($Template.Trim().ToLowerInvariant() -ne 'about:blank')
            {
                $Template = Get-Content -LiteralPath $Template -Raw;
            }
            Else
            {
                $TemplatePlaceholder = 'build-markdown-placeholder';
                $Template = "<!DOCTYPE html><html><head><meta http-equiv=`"X-UA-Compatible`" content=`"IE=Edge`"></head><body>$TemplatePlaceholder</body></html>";
            }
            If ($Template.IndexOf($TemplatePlaceholder) -lt 0)
            {
                Write-Error 'Template does not contain the placeholder.';
                Return;
            }
            If ($Template.IndexOf($TemplatePlaceholder) -ne $Template.LastIndexOf($TemplatePlaceholder))
            {
                Write-Error 'Template contains more than one occurences of the placeholder.';
                Return;
            }
            $local:CompiledHtml = & $ConvertMarkdownToHtml -FilePath $FilePath;
            Write-Verbose 'Finished compiling Markdown to HTML.';
            Push-Location;
            $local:ShouldPopLocation = $true;
            Set-Location -LiteralPath (Get-Item $FilePath).Directory.FullName;
            <# We WANT mshtml.HTMLDocumentClass here, turn off Strict mode so that we have what we want. #>
            $local:Document = New-Object -ComObject 'HTMLFILE' -Strict:$false;
            If ($local:Document.GetType().FullName -ne 'mshtml.HTMLDocumentClass')
            {
                Write-Warning 'HTMLFILE Component Object Model is not wrapped as mshtml.HTMLDocumentClass. Behaviours can be unexpected.';
            }
            $local:Document.IHTMLDocument2_write($Template.Replace($TemplatePlaceholder, $local:CompiledHtml)) | Out-Null;
            Write-Verbose 'Running pre-build action.';
            & $PreBuildAction -Context $local:ExtensionContext -Document $local:Document | Out-Null;
            Write-Verbose 'Finished running pre-build action.';
            $local:ExtensionCount = 0;
            $local:PossibleRemainingExtensions = $true;
            While ($local:PossibleRemainingExtensions)
            {
                $local:PossibleRemainingExtensions = $false;
                $local:RemainingExtensions = $local:Document.getElementsByTagName('pre');
                $local:rLength = $local:RemainingExtensions.length;
                For ($local:i = 0; -not $local:PossibleRemainingExtensions -and $local:i -lt $local:rLength; ++$local:i)
                {
                    $local:CurrentExtension = $local:RemainingExtensions[$local:i];
                    $local:Language = $local:CurrentExtension.getAttribute('lang');
                    If ($local:Language -eq $null)
                    {
                        $local:Language = '';
                    }
                    If ($local:WhitespaceRemoveRegex.Replace($local:Language, '').ToLowerInvariant() -eq $ExtensionLanguage)
                    {
                        $local:PossibleRemainingExtensions = $true;
                        ++$local:ExtensionCount;
                        Write-Verbose "Processing extension $local:ExtensionCount.";
                        $local:ExtensionBody = $local:CurrentExtension.innerText;
                        $local:ExtensionMatch = $local:ExtensionRegex.Match($local:ExtensionBody);
                        $local:ExtensionName = Get-NormalizedExtensionName -InputObject $local:ExtensionMatch.Groups['name'].Value;
                        $local:ExtensionSource = $local:ExtensionMatch.Groups['source'].Value;
                        If ($local:ExtensionName -eq '')
                        {
                            If ($Force)
                            {
                                $local:CurrentExtension.parentElement.removeChild($local:CurrentExtension) | Out-Null;
                                Write-Warning "The extension body is empty. The extension element is removed.`nInside the following HTML:`n$($local:CurrentExtension.parentElement.outerHTML)";
                            }
                            Else
                            {
                                Write-Error "The extension body is empty.`nInside the following HTML:`n$($local:CurrentExtension.parentElement.outerHTML)";
                                Return;
                            }
                        }
                        If ($VerbosePreference -ne [System.Management.Automation.ActionPreference]::SilentlyContinue)
                        {
                            Write-Verbose "  Name: $local:ExtensionName";
                            Write-Verbose 'Source:';
                            $local:ExtensionSource.Split(@("`r`n", "`r", "`n"), [System.StringSplitOptions]::None) | ForEach { Write-Verbose "    $_"; };
                        }
                        $local:Extension = $script:BuildMarkdownExtensions[$extensionName];
                        If ($local:Extension -is [ScriptBlock])
                        {
                            Try
                            {
                                & $local:Extension `
                                    -Context $local:ExtensionContext `
                                    -Document $local:Document `
                                    -Element $local:CurrentExtension `
                                    -Source $local:ExtensionSource | Out-Null;
                                Write-Verbose "Finished processing extension $local:ExtensionCount.";
                            }
                            Catch
                            {
                                If ($Force)
                                {
                                    Write-Warning $Error[0];
                                }
                                Else
                                {
                                    Throw;
                                    Return;
                                }
                            }
                        }
                        ElseIf ($local:Extension -ne $null)
                        {
                            If ($Force)
                            {
                                $local:CurrentExtension.parentElement.removeChild($local:CurrentExtension) | Out-Null;
                                Write-Warning "Extension `"$local:ExtensionName`" is corrupted. The extension element is removed.";
                            }
                            Else
                            {
                                Write-Error "Extension `"$local:ExtensionName`" is corrupted.";
                                Return;
                            }
                        }
                        ElseIf ($Force)
                        {
                            $local:CurrentExtension.parentElement.removeChild($local:CurrentExtension) | Out-Null;
                            Write-Warning "Extension `"$local:ExtensionName`" does not exist. The extension element is removed.";
                        }
                        Else
                        {
                            Write-Error "Extension `"$local:ExtensionName`" does not exist.";
                            Return;
                        }
                    }
                }
            }
            Write-Verbose 'Running post-build action.';
            & $PostBuildAction -Context $local:ExtensionContext -Document $local:Document | Out-Null;
            Write-Verbose 'Finished running post-build action.';
            $local:result = $local:Document.documentElement.outerHTML;
            Write-Verbose 'Running output transformer.';
            $local:result = & $OutputTransformer -Context $local:ExtensionContext -Output $local:result;
            Write-Verbose 'Finished running output transformer.';
            Return $local:result;
        }
        Finally
        {
            If ($local:ShouldPopLocation)
            {
                Pop-Location;
            }
        }
    }
}


<#
.Synopsis
    Installs an extension to Build-Markdown.

.Description
    Use this cmdlet to install extensions for Build-Markdown tool chain.

.Parameter Name
    The name of the extension. Names are case-insensitive are consecutive whitespaces are treated as one. It is recommended that the name complies to the convention "Vendor: Extension Name" fashion.

.Parameter Process
    The script block to process the extension. The script block should receive four nameed parameters. They are:

    Param
    (
        [HashTable]$Context,
        [System.__ComObject]$Document,
        [System.__ComObject]$Element,
        [string]$Source
    )

    You can store contextual information in $Context, which is persistent through a build. The $Source parameter does NOT include the line indicating the name of the extension.

.Parameter Force
    If this switch is set, the cmdlet raises a warning instead of an error if an extension with the same name is already installed. It is recommended never to set this switch to prevent unexpected behaviour.

.Example
    Install-BuildMarkdownExtension -Name "Gee Law: Extension 1" -Process $Process

    The installed extension can be referred to as "  Gee    Law :exTension    1 ".

.Link
    Build-Markdown
    Uninstall-BuildMarkdownExtension

#>
Function Install-BuildMarkdownExtension
{
    [CmdletBinding(HelpUri = '')]
    Param
    (
        [parameter(Mandatory = $true)]
        [string]$Name,
        [parameter(Mandatory = $true)]
        [ScriptBlock]$Process,
        [parameter()]
        [switch]$Force
    )
    Process
    {
        $local:ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop;
        If ([string]::IsNullOrWhiteSpace($Name))
        {
            Write-Error 'Name must not be null or whitespace.';
            Return;
        }
        $Name = Get-NormalizedExtensionName -InputObject $Name;
        If ($script:BuildMarkdownExtensions[$Name] -ne $null)
        {
            If (-not $Force)
            {
                Write-Error 'An extension of the same name has been installed.';
                Return;
            }
            Else
            {
                Write-Warning 'An extension of the same name has been installed. The old extension is overridden.';
            }
        }
        $script:BuildMarkdownExtensions[$Name] = $Process;
        Write-Verbose "Installed extension `"$Name`" as { $Process }.";
    }
}

<#
.Synopsis
    Uninstalls an extension from Build-Markdown.

.Description
    This cmdlet is always silent. This cmdlet is rarely useful.

.Parameter Name
    The name of the extension. Names are case-insensitive are consecutive whitespaces are treated as one. It is recommended that the name complies to the convention "Vendor: Extension Name" fashion.

.Example
    Uninstall-BuildMarkdownExtension -Name "Gee Law: Extension 1"

.Link
    Build-Markdown
    Install-BuildMarkdownExtension

#>
Function Uninstall-BuildMarkdownExtension
{
    [CmdletBinding(HelpUri = '')]
    Param
    (
        [parameter(Mandatory = $true)]
        [string]$Name
    )
    Process
    {
        $local:ErrorActionPreference = [System.Management.Automation.ActionPreference]::SilentlyContinue;
        If (-not [string]::IsNullOrWhiteSpace($Name))
        {
            $script:BuildMarkdownExtensions[(Get-NormalizedExtensionName -InputObject $Name)] = $null;
        }
    }
}

<#
.Synopsis
    Compiles a Markdown file.

.Description
    This cmdlet uses GitHub Markdown API to compile the document. Other implementations are possible.

.Parameter FilePath
    The path of the Markdown file to be compiled.

.Example
    Convert-MarkdownToHtmlWithGitHubAPI -FilePath README.md | Out-File README.html -Encoding UTF8

    This outputs the HTML for README.md to README.html in UTF8 encoding (with BOM).

.Link
    Build-Markdown

#>
Function Convert-MarkdownToHtmlWithGitHubAPI
{
    [CmdletBinding(HelpUri = '')]
    [OutputType([string])]
    Param
    (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$FilePath
    )
    Process
    {
        $local:ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop;
        $local:Response = Invoke-WebRequest -Uri 'https://api.github.com/rate_limit';
        If ($local:Response.Headers['X-RateLimit-Remaining'] -eq '0')
        {
            $local:ResetTime = [System.DateTime]::new(1970, 1, 1, 0, 0, 0, 0, [System.DateTimeKind]::Utc);
            $local:ResetTime = $local:ResetTime.AddSeconds([System.Double]::Parse($local:Response.Headers['X-RateLimit-Reset']));
            $local:ResetTime = $local:ResetTime.ToLocalTime();
            Write-Error "You have exceeded anonymous API calling limit. Try again after $local:ResetTime.";
            Return;
        }
        Write-Verbose "You have $($local:Response.Headers['X-RateLimit-Remaining']) remaining calls to GitHub Markdown API.";
        $local:TempFileName = [System.IO.Path]::Combine($env:TEMP, [System.Guid]::NewGuid().ToString('n') + ".md");
        Try
        {
            [System.IO.File]::WriteAllText($local:TempFileName, (Get-Content -LiteralPath $FilePath -Raw));
            $local:Response = Invoke-WebRequest -Uri 'https://api.github.com/markdown/raw' `
                -Method Post -InFile $local:TempFileName -ContentType 'text/x-markdown' -UseBasicParsing;
            Return $local:Response.Content;
        }
        Finally
        {
            Remove-Item -LiteralPath $local:TempFileName -Force -ErrorAction ([System.Management.Automation.ActionPreference]::SilentlyContinue);
        }
    }
}


Export-ModuleMember -Function @('Build-Markdown', 'Install-BuildMarkdownExtension', 'Uninstall-BuildMarkdownExtension', 'Convert-MarkdownToHtmlWithGitHubAPI') -Alias @() -Cmdlet @() -Variable @();
