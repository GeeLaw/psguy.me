# example script using Build-Markdown
$global:VerbosePreference = 'Continue';
$global:ErrorActionPreference = 'Stop';

Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force;

Import-Module .\Build-Markdown\Build-Markdown.psd1;
Import-Module .\Install-BuildMarkdownExtensionsByGeeLaw\Install-BuildMarkdownExtensionsByGeeLaw.psd1;

Install-BuildMarkdownExtensionsByGeeLaw;

$script:marked = (Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/chjj/marked/b5781fd488a933d6989a03453c3de0484892b3e0/marked.min.js' -UseBasicParsing).Content;

Function Convert-MarkdownToHtmlWithMarked035
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    Process
    {
        $local:text = Get-Content $FilePath -Raw;
        $local:html = New-Object -ComObject HTMLFILE -Strict:$false;
        $local:html.IHTMLDocument2_write("<!DOCTYPE html><html><head><meta http-equiv=`"X-UA-Compatible`" content=`"IE=Edge`"><meta charset=`"utf-8`"><script type=`"text/javascript`">$script:marked</script></head><body><div id=`"surrogate`"></div></body></html>") | Out-Null;
        $local:html.getElementById('surrogate').innerText = $local:text;
        $local:script = $local:html.createElement('script');
        $local:script.type = 'text/javascript';
        $local:script.innerHTML = 'document.body.innerText = marked(document.getElementById("surrogate").innerText);';
        $local:html.documentElement.children[0].appendChild($local:script) | Out-Null;
        Return $local:html.body.innerText;
    }
}

$script:tempDir = [System.IO.Path]::Combine($env:TEMP, [System.Guid]::NewGuid().ToString('n'));
New-Item -Path $script:tempDir -ItemType Directory | Out-Null;
$script:tempFileName = [System.IO.Path]::Combine($script:tempDir, 'readme.html');
$script:templateFileName = [System.IO.Path]::Combine($script:tempDir, 'template.html');

'<!DOCTYPE html><html><head><meta http-equiv="X-UA-Compatible" content="IE=Edge"><meta charset="utf-8"></head><body>build-markdown-placeholder</body></html>' | Out-File -LiteralPath $script:templateFileName;

$script:built = Build-Markdown -FilePath 'README.md' `
    -Template $script:templateFileName `
    -ConvertMarkdownToHtml { Param ($FilePath) Return Convert-MarkdownToHtmlWithMarked035 -FilePath $FilePath; }`
    -PreBuildAction `
    {
        Param ($Context, $Document)
        BeforeBuildMarkdown-RemoveHeadingAnchors -Context $Context -Document $Document;
        $Document.getElementsByClassName('lang-bssex') | ForEach-Object `
        {
            $_.parentElement.setAttribute('lang', 'bssex');
        } | Out-Null;
    } `
    -PostBuildAction `
    {
        Param ($Context, $Document)
        AfterBuildMarkdown-SetTitle -Context $Context -Document $Document -Infer;
        $local:css = $Document.createElement('style');
        $local:css.type = 'text/css';
        $local:css.innerHTML = (Get-Content -LiteralPath '.\Install-BuildMarkdownExtensionsByGeeLaw\gl-float.css' -Raw -Encoding UTF8);
        $Document.documentElement.children[0].appendChild($local:css) | Out-Null;
    } `
    -OutputTransformer `
    {
        Param ($Context, $Output)
        Return TransformBuiltMarkdown-GeeLaw -Context $Context -Output $Output;
    };

[System.IO.File]::WriteAllText($script:tempFileName, $script:built);
Copy-Item -LiteralPath '.\assets' -Destination $script:tempDir -Recurse;
Invoke-Item -LiteralPath $script:tempFileName;
