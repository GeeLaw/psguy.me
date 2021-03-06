<#

IMPORTANT: SEE LICENSE.md FOR LICENSING DETAILS!

THIS SCRIPT IS NOT LICENSED UNDER MIT LICENSE.

#>
$script:ModulePath = (Resolve-Path -LiteralPath '..\modules\Build-Markdown').Path;
$script:SourcePath = (Resolve-Path -LiteralPath '..').Path;
$script:TargetPath = (Resolve-Path -LiteralPath '..\..\psguy.me.site').Path;
$script:BuilderPath = (Resolve-Path -LiteralPath '.').Path;
$script:TempPath = [System.IO.Path]::Combine($env:TEMP, 'Build-Markdown-psguy-me', [System.Guid]::NewGuid().ToString('n'));

$script:OldHashPath = [System.IO.Path]::Combine($script:TempPath, 'raw-compile');
$script:NewHashPath = [System.IO.Path]::Combine($script:TargetPath, 'raw-compile');

$script:TemplatePath = [System.IO.Path]::Combine($script:BuilderPath, 'template.html');

$global:ErrorActionPreference = 'Stop';

Import-Module ([System.IO.Path]::Combine($script:ModulePath, 'Build-Markdown\Build-Markdown.psd1'));
Import-Module ([System.IO.Path]::Combine($script:ModulePath, 'Install-BuildMarkdownExtensionsByGeeLaw\Install-BuildMarkdownExtensionsByGeeLaw.psd1'));

Install-BuildMarkdownExtensionsByGeeLaw -Force;

<# Do not set this prior here, otherwise there will be a lot of verbosive message about importing the modules. #>
$global:VerbosePreference = 'Continue';

$global:WarningPreference = 'Inquire';
Write-Warning "`n`n`n`n`nReady to build the site. Back up the current setting first.";

<# Move the current site to the temporary folder. #>
Copy-Item -Path $script:TargetPath -Destination $script:TempPath -Recurse;
Get-ChildItem -LiteralPath $script:TargetPath | ForEach-Object -Process `
    {
        If (-not $_.Name.StartsWith('.'))
        {
            Remove-Item -LiteralPath $_.FullName -Recurse -Force;
        }
    };

$script:OldHashes = @{};
$script:NewHashes = @{};

$global:ErrorActionPreference = 'SilentlyContinue';
(Get-Content -LiteralPath $script:OldHashPath -Raw -Encoding Unicode | `
    ConvertFrom-Json) | `
    ForEach-Object -Process `
    {
        $script:OldHashes[$_.Key] = $_.Value;
    };
$global:ErrorActionPreference = 'Stop';

Function Build-MarkdownForPSGuyMe
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        [Parameter()]
        [ScriptBlock]$NavLinkGen = { Param ($Context, $Document) }
    )
    Process
    {
        Return Build-Markdown -FilePath $FilePath `
            -ConvertMarkdownToHtml { Param($FilePath) Return Convert-MarkdownToHtmlIfNecessary -FilePath $FilePath; } `
            -Template $script:TemplatePath `
            -PreBuildAction `
            {
                Param ($Context, $Document)
                BeforeBuildMarkdown-RemoveHeadingAnchors -Context $Context -Document $Document;
            } `
            -PostBuildAction `
            {
                Param ($Context, $Document)
                AfterBuildMarkdown-SetTitle -Context $Context -Document $Document -Infer;
                & $NavLinkGen -Context $Context -Document $Document;
            } `
            -OutputTransformer `
            {
                Param ($Context, $Output)
                $local:output2 = TransformBuiltMarkdown-GeeLaw -Context $Context -Output $Output;
                Return "<!DOCTYPE html>`n" + $local:output2.Replace("`r`n", "`n").Replace("`r", "`n") + "`n";
            };
    }
}

Function Create-NavLink
{
    [CmdletBinding()]
    Param
    (
        [Parameter()]
        [string]$Text,
        [Parameter()]
        [string]$URL,
        [Parameter()]
        [string]$Target = '!',
        [Parameter()]
        [HashTable]$Context,
        [Parameter()]
        [System.__ComObject]$Document
    )
    Process
    {
        $local:aElement = $Document.createElement('a');
        $local:aElement.innerText = $Text;
        $local:aElement.setAttribute('href', $URL);
        If ($Target -ne '!')
        {
            $local:aElement.setAttribute('target', $Target);
        }
        $Document.documentElement.getElementsByClassName('gl-navbar')[0].appendChild($local:aElement) | Out-Null;
    }
}

Function Create-RepoLink
{
    [CmdletBinding()]
    Param
    (
        [Parameter()]
        [string]$Path,
        [Parameter()]
        [HashTable]$Context,
        [Parameter()]
        [System.__ComObject]$Document
    )
    Process
    {
        $local:finalPath = 'https://github.com/GeeLaw/psguy.me';
        $Path.Split(@('/', '\'), 'RemoveEmptyEntries') | ForEach-Object -Process `
            {
                $local:finalPath += '/' + $_;
            };
        Create-NavLink -Text 'Repository' -URL $local:finalPath -Target '_blank' -Context $Context -Document $Document;
    }
}

Function Convert-MarkdownToHtmlIfNecessary
{
    [CmdletBinding()]
    [OutputType([string])]
    Param
    (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$FilePath
    )
    Process
    {
        Try
        {
            Write-Verbose "Convert to HTML: $FilePath";
            $local:srcHash = (Get-FileHash -LiteralPath $FilePath -Algorithm 'SHA512').Hash.ToLowerInvariant();
            If ($script:OldHashes[$local:srcHash] -is [string])
            {
                Write-Verbose '    Hash matches, use the old compile result.';
                $script:NewHashes[$local:srcHash] = $script:OldHashes[$local:srcHash];
            }
            Else
            {
                $script:NewHashes[$local:srcHash] = Convert-MarkdownToHtmlWithGitHubAPI -FilePath $FilePath;
            }
            Return $script:NewHashes[$local:srcHash];
        }
        Finally
        {
            $script:HashJson = $script:NewHashes.GetEnumerator() | `
                ForEach-Object -Process { Return New-Object PSObject -Property @{ Key = $_.Key; Value = $_.Value }; } | `
                ConvertTo-Json;
            Out-File -LiteralPath $script:NewHashPath -Encoding Unicode -Force -InputObject $script:HashJson;
        }
    }
}

Function Build-IfNecessary
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [string]$SourceRelativePath,
        [Parameter(Mandatory = $true)]
        [string]$TargetRelativePath,
        [Parameter()]
        [ScriptBlock]$NavLinkGen = { Param ($Context, $Document) }
    )
    Process
    {
        Write-Verbose "START: $SourceRelativePath => $TargetRelativePath";
        $local:built = Build-MarkdownForPSGuyMe -FilePath ([System.IO.Path]::Combine($script:SourcePath, $SourceRelativePath)) -NavLinkGen $NavLinkGen;
        [System.IO.File]::WriteAllText(([System.IO.Path]::Combine($script:TargetPath, $TargetRelativePath)), $local:built);
        Write-Verbose "FINISH: $SourceRelativePath => $TargetRelativePath";
        Write-Verbose '----------------------------------------------';
    }
}

Write-Verbose 'Start building.';

<# Build index.html #>
Build-IfNecessary -SourceRelativePath 'README.md' -TargetRelativePath 'index.html' -NavLinkGen `
    {
        Param ($Context, $Document)
        Create-NavLink -Text 'Modules' -URL '/modules' -Context $Context -Document $Document;
        Create-NavLink -Text 'Scripts' -URL '/scripts' -Context $Context -Document $Document;
        Create-RepoLink -Path '' -Context $Context -Document $Document;
    };

<# build modules/* and scripts/* #>
@('modules', 'scripts') | ForEach-Object -Process `
{
    $local:resourceType = $_;
    New-Item -Path ([System.IO.Path]::Combine($script:TargetPath, $resourceType)) -ItemType 'Directory' | Out-Null;
    Build-IfNecessary -SourceRelativePath "$resourceType\README.md" -TargetRelativePath "$resourceType\index.html" `
        -NavLinkGen `
        {
            Param ($Context, $Document)
            Create-NavLink -Text 'psguy.me' -URL '/' -Context $Context -Document $Document;
            If ($resourceType -eq 'modules')
            {
                Create-NavLink -Text 'Scripts' -URL '/scripts' -Context $Context -Document $Document;
            }
            Else
            {
                Create-NavLink -Text 'Modules' -URL '/modules' -Context $Context -Document $Document;
            }
            Create-RepoLink -Path "tree/master/$resourceType" -Context $Context -Document $Document;
        };
    Get-ChildItem -Path ([System.IO.Path]::Combine($script:SourcePath, $resourceType, '*.md')) -File | `
        ForEach-Object -Process `
        {
            If ($_.Name.ToLowerInvariant() -eq 'readme.md')
            {
                Return;
            }
            Build-IfNecessary -SourceRelativePath "$resourceType\$($_.Name)" `
                -TargetRelativePath "$resourceType\$($_.Name.Substring(0, $_.Name.Length - 3) + '.html')" `
                -NavLinkGen `
                {
                    Param ($Context, $Document)
                    Create-NavLink -Text ([char]::ToUpper($resourceType[0]).ToString() + $resourceType.Substring(1)) `
                        -URL "/$resourceType" -Context $Context -Document $Document;
                    Create-RepoLink -Path "tree/master/$resourceType/$($_.Name)" -Context $Context -Document $Document;
                };
        };
    Get-ChildItem -Path ([System.IO.Path]::Combine($script:SourcePath, $resourceType)) -Directory | `
        ForEach-Object -Process `
        {
            $local:partName = $_.Name;
            New-Item -Path ([System.IO.Path]::Combine($script:TargetPath, $resourceType, $local:partName)) -ItemType 'Directory' | Out-Null;
            Get-ChildItem -Path ([System.IO.Path]::Combine($script:SourcePath, $resourceType, $local:partName, '*.md')) -File | `
                ForEach-Object -Process `
                {
                    $local:targetName = $_.Name.Substring(0, $_.Name.Length - 3) + '.html';
                    If ($_.Name.ToLowerInvariant() -eq 'readme.md')
                    {
                        $local:targetName = 'index.html';
                    }
                    ElseIf ($_.Name.ToLowerInvariant() -eq 'license.md')
                    {
                        $local:targetName = 'license.html';
                    }
                    Build-IfNecessary -SourceRelativePath "$resourceType\$local:partName\$($_.Name)" `
                        -TargetRelativePath "$resourceType\$local:partName\$local:targetName" `
                        -NavLinkGen `
                        {
                            Param ($Context, $Document)
                            If ($targetName -ne 'index.html')
                            {
                                Create-NavLink -Text $partName -URL '.' -Context $Context -Document $Document;
                            }
                            Else
                            {
                                Create-NavLink -Text ([char]::ToUpper($resourceType[0]).ToString() + $resourceType.Substring(1)) `
                                    -URL "/$resourceType" -Context $Context -Document $Document;
                            }
                            Create-RepoLink -Path "tree/master/$resourceType/$partName/$($_.Name)" -Context $Context -Document $Document;
                        };
                };
            Copy-Item -Path ([System.IO.Path]::Combine($script:SourcePath, $resourceType, $local:partName, '*.html')) `
                -Destination ([System.IO.Path]::Combine($script:TargetPath, $resourceType, $local:partName));`
            If ((Test-Path ([System.IO.Path]::Combine($script:SourcePath, $resourceType, $local:partName, 'assets'))))
            {
                Copy-Item -Path ([System.IO.Path]::Combine($script:SourcePath, $resourceType, $local:partName, 'assets')) `
                    -Destination ([System.IO.Path]::Combine($script:TargetPath, $resourceType, $local:partName) + '\') -Recurse;
            }
        };
};


<# Copy static content. #>
Write-Verbose 'Start copying static content.';
Get-ChildItem -LiteralPath ([System.IO.Path]::Combine($script:BuilderPath, 'static')) | `
    ForEach-Object -Process `
    {
        Copy-Item -LiteralPath $_.FullName -Destination ($script:TargetPath + '\') -Recurse;
    };
Write-Verbose 'Finish copying static content.';

<# Clean-up. #>

Remove-Item -LiteralPath $script:TempPath -Recurse -Force;

[System.IO.File]::WriteAllText([System.IO.Path]::Combine($script:TargetPath, 'CNAME'), "psguy.me`n");

Write-Verbose 'Finish building.';

