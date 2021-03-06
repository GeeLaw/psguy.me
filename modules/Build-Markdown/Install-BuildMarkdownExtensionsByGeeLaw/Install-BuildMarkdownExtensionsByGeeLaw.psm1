<#
Adds a CSS to the <head>...</head> element.
```bssex
Gee Law: CSS
{
    "embed": false,
    "css": "github-markdown.css"
}
```
#>
$script:AddCss = `
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [HashTable]$Context,
        [Parameter(Mandatory = $true)]
        [System.__ComObject]$Document,
        [Parameter(Mandatory = $true)]
        [System.__ComObject]$Element,
        [Parameter(Mandatory = $true)]
        [string]$Source
    )
    Process
    {
        $local:ErrorActionPreference = 'Stop';
        $Element.parentElement.removeChild($Element) | Out-Null;
        $local:SourceObject = ConvertFrom-Json -InputObject $Source;
        $local:CssPath = $local:SourceObject.css;
        If ($CssPath -isnot [string])
        {
            Write-Error 'Source.css must be a string.';
            Return;
        }
        $local:embed = $local:SourceObject.embed;
        If ($local:embed -isnot [bool])
        {
            Write-Error 'Source.embed must be a boolean.';
            Return;
        }
        $local:head = $Document.getElementsByTagName("head")[0];
        If ($local:embed)
        {
            $local:CssContent = $null;
            If ($local:CssPath.ToLowerInvariant().StartsWith('http:') -or $local:CssPath.ToLowerInvariant().StartsWith('https:'))
            {
                $local:CssContent = (Invoke-WebRequest -Uri $local:CssPath).Content;
            }
            Else
            {
                $local:CssContent = Get-Content -Path $local:CssPath -Raw;
            }
            $local:style = $Document.createElement('style');
            $local:style.setAttribute('type', 'text/css');
            $local:style.innerHTML = $local:CssContent;
            $local:head.appendChild($local:style) | Out-Null;
        }
        Else
        {
            $local:link = $Document.createElement('link');
            $local:link.setAttribute('href', $local:CssPath);
            $local:link.setAttribute('rel', 'stylesheet');
            $local:link.setAttribute('type', 'text/css');
            $local:head.appendChild($local:link) | Out-Null;
        }
    }
};

<#
Replace the current extension element with the HTML content.
```bssex
Gee Law: HTML
<p>This is my custom HTML.</p>
```
#>
$script:AddPlainHtml = `
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [HashTable]$Context,
        [Parameter(Mandatory = $true)]
        [System.__ComObject]$Document,
        [Parameter(Mandatory = $true)]
        [System.__ComObject]$Element,
        [Parameter(Mandatory = $true)]
        [string]$Source
    )
    Process
    {
        $Element.outerHTML = $Source;
    }
}

<#
Infer title from the only <h1>...</h1> element.
```bssex
Gee Law: title
null
```bssex

Set an explicit title.
```bssex
Gee Law: title
"My blog"
```
#>
$script:SetTitle = `
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [HashTable]$Context,
        [Parameter(Mandatory = $true)]
        [System.__ComObject]$Document,
        [Parameter(Mandatory = $true)]
        [System.__ComObject]$Element,
        [Parameter(Mandatory = $true)]
        [string]$Source
    )
    Process
    {
        $local:ErrorActionPreference = 'Stop';
        $Element.parentElement.removeChild($Element) | Out-Null;
        $local:title = $Document.createElement('title');
        $local:titleText = ConvertFrom-Json -InputObject $Source;
        If ($titleText -eq $null)
        {
            $local:h1 = $Document.getElementsByTagName('h1');
            $local:h1Len = $h1.length;
            If ($local:h1Len -ne 1)
            {
                Write-Error "There is/are $local:h1Len h1 element(s) in the document now. Expecting 1 h1 element.";
                Return;
            }
            $local:titleText = $h1[0].innerText;
            Write-Verbose "Heuristically found the title: $local:titleText";
        }
        ElseIf (-not ($local:titleText -is [string]))
        {
            Write-Error 'The extension source is neither null nor a proper string encoded in JSON.';
            Return;
        }
        $local:title.innerText = $local:titleText;
        $local:head = $Document.getElementsByTagName('head')[0];
        $local:head.appendChild($title) | Out-Null;
    }
}

<#
Gee Law: image
{
    "source": "<theme>/path/to/image.png",
    "caption": "Lorem ipsum",
    "click": true,
    "accessible": true,
    "zoom": 0.6,
    "margin": "0",
    "placement": "left",
    "style": "margin: 0px;", // or use an object.
    "class": "some-class-name"
}
#>
$script:AddImage = `
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [HashTable]$Context,
        [Parameter(Mandatory = $true)]
        [System.__ComObject]$Document,
        [Parameter(Mandatory = $true)]
        [System.__ComObject]$Element,
        [Parameter(Mandatory = $true)]
        [string]$Source
    )
    Process
    {
        $local:ErrorActionPreference = 'Stop';
        If ($Context['GeeLaw.AddImage.StyleTrick'] -eq $null)
        {
            $Context['GeeLaw.AddImage.StyleTrick'] = "style_$([System.Guid]::NewGuid().ToString('n'))";
        }
        $local:SourceObject = ConvertFrom-Json -InputObject $Source;
        If ($local:SourceObject -eq $null)
        {
            Write-Error 'Source is not well-formed.';
            Return;
        }
        <# Make sure properties exist. #>
        Add-Member -InputObject $local:SourceObject -Name 'source' -Value $local:SourceObject.source -MemberType NoteProperty -Force;
        Add-Member -InputObject $local:SourceObject -Name 'caption' -Value $local:SourceObject.caption -MemberType NoteProperty -Force;
        Add-Member -InputObject $local:SourceObject -Name 'click' -Value $local:SourceObject.click -MemberType NoteProperty -Force;
        Add-Member -InputObject $local:SourceObject -Name 'accessible' -Value $local:SourceObject.accessible -MemberType NoteProperty -Force;
        Add-Member -InputObject $local:SourceObject -Name 'zoom' -Value $local:SourceObject.zoom -MemberType NoteProperty -Force;
        Add-Member -InputObject $local:SourceObject -Name 'style' -Value $local:SourceObject.style -MemberType NoteProperty -Force;
        Add-Member -InputObject $local:SourceObject -Name 'class' -Value $local:SourceObject.class -MemberType NoteProperty -Force;
        Add-Member -InputObject $local:SourceObject -Name 'caption' -Value $local:SourceObject.caption -MemberType NoteProperty -Force;
        Add-Member -InputObject $local:SourceObject -Name 'placement' -Value $local:SourceObject.placement -MemberType NoteProperty -Force;
        If ($local:SourceObject.source -isnot [string])
        {
            Write-Error 'Source.source must be a string.';
            Return;
        }
        If ($local:SourceObject.zoom -eq $null)
        {
            $local:SourceObject.zoom = 1;
        }
        Try
        {
            $local:SourceObject.zoom = [System.Convert]::ToDouble($local:SourceObject.zoom);
        }
        Catch { }
        If ($local:SourceObject.zoom -isnot [double])
        {
            Write-Error 'Source.zoom must be null (default to 1), a number or convertible to a number.';
            Return;
        }
        If ([double]::IsNan($local:SourceObject.zoom))
        {
            Write-Error 'Source.zoom must not be NaN.';
            Return;
        }
        If ($local:SourceObject.zoom -lt 0.00005)
        {
            Write-Error 'Source.zoom is at least 0.01%.';
            Return;
        }
        If ($local:SourceObject.zoom -ge 50.00005)
        {
            Write-Error 'Source.zoom is at most 5000.00%.';
            Return;
        }
        $local:SourceObject.zoom = ([int]($local:SourceObject.zoom * 10000 + 0.5) / 100.0).ToString() + '%';
        If ($local:SourceObject.style -is [PSObject])
        {
            $local:styleObject = $local:SourceObject.style;
            $local:SourceObject.style = '';
            $local:styleObject | Get-Member -MemberType NoteProperty | `
                ForEach-Object { $_.Name } | ForEach-Object `
                {
                    $local:SourceObject.style += $_ + ': ' + $local:styleObject.$_ + '; ';
                };
            If ($local:SourceObject.style -eq '')
            {
                $local:SourceObject.style = $null;
            }
        }
        If ($local:SourceObject.style -ne $null -and $local:SourceObject.style -isnot [string])
        {
            Write-Error 'Source.style must be null or convertible to string.';
            Return;
        }
        If ($local:SourceObject.caption -ne $null -and $local:SourceObject.caption -isnot [string])
        {
            Write-Error 'Source.caption must be null or a string.';
            Return;
        }
        If ($local:SourceObject.click -isnot [bool])
        {
            Write-Error 'Source.click must be a boolean.';
            Return;
        }
        If ($local:SourceObject.accessible -eq $null)
        {
            $local:SourceObject.accessible = $false;
        }
        If ($local:SourceObject.accessible -isnot [bool])
        {
            Write-Error 'Source.accessible must be null (default to false) or a boolean.';
            Return;
        }
        If ($local:SourceObject.placement -eq $null)
        {
            $local:SourceObject.placement = 'none';
        }
        If ($local:SourceObject.placement -ne 'left' `
            -and $local:SourceObject.placement -ne 'right' `
            -and $local:SourceObject.placement -ne 'always-left' `
            -and $local:SourceObject.placement -ne 'always-right' `
            -and $local:SourceObject.placement -ne 'none')
        {
            Write-Error 'Source.placement must be null (default to none), left, always-left, right, always-right or none.';
            Return;
        }
        $local:figure = $Document.createElement('figure');
        $local:figure.className = "gl-float-$($local:SourceObject.placement) $($local:SourceObject.class)";
        If ($local:SourceObject.style -ne $null)
        {
            $local:figure.setAttribute($Context['GeeLaw.AddImage.StyleTrick'], $local:SourceObject.style);
        }
        If ($local:SourceObject.accessible)
        {
            @('high-contrast-forbidden', 'high-contrast-fallback', 'high-contrast-black-on-white', 'high-contrast-white-on-black') | `
                ForEach-Object -Process `
                {
                    $local:img = $Document.createElement('img');
                    $local:img.setAttribute('src', $local:SourceObject.source.Replace('<theme>', $_));
                    If ($local:SourceObject.caption -ne $null)
                    {
                        $local:img.setAttribute('alt', $local:SourceObject.caption);
                    }
                    $local:img.className = "gl-accessible-$_";
                    $local:img.setAttribute($Context['GeeLaw.AddImage.StyleTrick'], "zoom: $($local:SourceObject.zoom); max-width: 100%;");
                    $local:figure.appendChild($local:img) | Out-Null;
                };
        }
        Else
        {
            $local:img = $Document.createElement('img');
            $local:img.setAttribute('src', $local:SourceObject.source);
            If ($local:SourceObject.caption -ne $null)
            {
                $local:img.setAttribute('alt', $local:SourceObject.caption);
            }
            $local:img.setAttribute($Context['GeeLaw.AddImage.StyleTrick'], "zoom: $($local:SourceObject.zoom); max-width: 100%;");
            $local:figure.appendChild($local:img) | Out-Null;
        }
        If ($local:SourceObject.caption -ne $null)
        {
            $local:figcaption = $Document.createElement('figcaption');
            If ($local:SourceObject.click)
            {
                $local:anchor = $Document.createElement('a');
                $local:anchor.innerText = $local:SourceObject.caption;
                If ($local:SourceObject.accessible)
                {
                    $local:anchor.setAttribute('href', $local:SourceObject.source.Replace('<theme>', 'high-contrast-forbidden'));
                }
                Else
                {
                    $local:anchor.setAttribute('href', $local:SourceObject.source);
                }
                $local:anchor.setAttribute('target', '_blank');
                $local:figcaption.appendChild($local:anchor) | Out-Null;
            }
            Else
            {
                $local:figcaption.innerText = $local:SourceObject.caption;
            }
            $local:figure.appendChild($local:figcaption) | Out-Null;
        }
        $Element.parentElement.replaceChild($local:figure, $Element) | Out-Null;
    }
};

Function Install-BuildMarkdownExtensionsByGeeLaw
{
    [CmdletBinding()]
    Param
    (
        [Parameter()]
        [switch]$Force
    )
    Process
    {
        Install-BuildMarkdownExtension -Name 'Gee Law: CSS' -Process $script:AddCss -Force:$Force;
        Install-BuildMarkdownExtension -Name 'Gee Law: HTML' -Process $script:AddPlainHtml -Force:$Force;
        Install-BuildMarkdownExtension -Name 'Gee Law: title' -Process $script:SetTitle -Force:$Force;
        Install-BuildMarkdownExtension -Name 'Gee Law: image' -Process $script:AddImage -Force:$Force;
    }
}

Function BeforeBuildMarkdown-RemoveHeadingAnchors
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [HashTable]$Context,
        [Parameter(Mandatory = $true)]
        [System.__ComObject]$Document
    )
    Process
    {
        $local:ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop;
        $local:anchors = $Document.getElementsByClassName('anchor');
        $local:currentAnchor = $null;
        $local:totAnchors = 0;
        While ($local:anchors.length -gt 0)
        {
            ++$local:totAnchors;
            $local:currentAnchor = $local:anchors[0];
            $local:anchors = $null;
            $local:currentAnchor.parentElement.removeChild($local:currentAnchor) | Out-Null;
            $local:anchors = $Document.getElementsByClassName('anchor');
        }
        Write-Verbose "    Removed $local:totAnchors heading anchor(s) from the compiled Markdown.";
    }
}

Function AfterBuildMarkdown-SetTitle
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [HashTable]$Context,
        [Parameter(Mandatory = $true)]
        [System.__ComObject]$Document,
        [Parameter()]
        [switch]$Infer,
        [Parameter()]
        [string]$Title = 'Untitled'
    )
    Process
    {
        $local:ErrorActionPreference = 'Stop';
        If ($Infer)
        {
            $local:h1 = $Document.getElementsByTagName('h1');
            $local:h1Len = $h1.length;
            If ($h1Len -ne 1)
            {
                Write-Error "There is/are $h1Len h1 element(s) in the document now. Expecting 1 h1 element.";
                Return;
            }
            $Title = $h1[0].innerText;
            Write-Verbose "    Heuristically found the title: $Title";
        }
        $local:titleElem = $Document.createElement('title');
        $titleElem.innerText = $Title;
        $head = $Document.getElementsByTagName('head')[0];
        $head.appendChild($titleElem) | Out-Null;
    }
}

<# Each extension module should have a cmdlet called TransformBuiltMarkdown-<Vendor>
so that the user can get their Markdown cleaned up
by calling these cmdlets once each extension he has installed. #>
Function TransformBuiltMarkdown-GeeLaw
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [HashTable]$Context,
        [Parameter(Mandatory = $true)]
        [string]$Output
    )
    Process
    {
        $local:ErrorActionPreference = 'Stop';
        If ($Context['GeeLaw.AddImage.StyleTrick'] -eq $null)
        {
            Return $Output;
        }
        Return $Output.Replace($Context['GeeLaw.AddImage.StyleTrick'], 'style');
    }
}

Export-ModuleMember -Function @('Install-BuildMarkdownExtensionsByGeeLaw', 'BeforeBuildMarkdown-RemoveHeadingAnchors', 'AfterBuildMarkdown-SetTitle', 'TransformBuiltMarkdown-GeeLaw') -Alias @() -Cmdlet @() -Variable @();
