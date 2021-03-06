# Build-Markdown
```bssex
Gee Law: image
{
    "source": "assets/icon.png",
    "caption": null,
    "click": false,
    "accessible": false,
    "zoom": 0.8,
    "placement": "right",
    "style": "margin: 0px;"
}
```

A static site builder based on PowerShell and GitHub Markdown API.

## License
This module is published under [MIT License](license.html).

## Get
This module is NOT available through

## Motive
I am personally not satisfied with any current static blogging tool therefore I decide to create my own, hoping it can be useful for others like any open-source software fanboy (开源软件拥趸), which is mostly false.

Since I mainly work on Microsoft Windows. The software is going to be implemented in PowerShell scripting language. For now it provides an extensible Markdown compiler based on GitHub API.

## Blogging system
A blog site can be built with this software with sources. The most important source is a database (in any form, JSON, XML or SQL Server) that provides metadata on blog entries. The database is mainly for query and RSS/homepage generation. Each time a new entry is added, or an entry is modified, the software should be run to update resulting static pages.

## Extension syntax
The only difference between Build-Markdown style Markdown and usual GitHub-style Markdown is that it supports extensions to be added over time without breaking any existing functionality.

The **extension syntax** provides extension functionality via code blocks.

For any blog entry, the metadata of it contains a special field/column `ExtensionLanguage`. This is a string field/column and if it is `null`, it defaults to `"bssex"` (**b**uild-**s**tatic.**s**ite **ex**tension). This language is used as the extension language. To make use of an extension, use a code block of language `ExtensionLanguage` to do so.

Different extensions have different syntaxes, but the first line of the code block must be the name of that extension and the following lines are sent to the extension for further analysis. For example:

    ```bssex
    Gee Law: image
    {
        "source": "<theme>/some-image.png",
        "zoom": 0.6,
        "caption": "Lorem ipsum",
        "click": true,
        "accessible": true,
        "placement": "left"
    }
    ```

The code above should produce an image zoomed to 60%, floating on the left, with caption “Lorem ipsum” (when clicked, the user gets to the source of image) and substituted to the appropriate version under high contrast themes on Windows.
