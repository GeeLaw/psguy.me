New-Alias -Name 'new' -Value 'New-Object';
New-Alias -Name 'clip' -Value 'Set-Clipboard';
New-Alias -Name 'paste' -Value 'Get-Clipboard';
New-Alias -Name 'poke' -Value 'Invoke-WebRequest';
New-Alias -Name '2json' -Value 'ConvertTo-Json';
New-Alias -Name 'json2' -Value 'ConvertFrom-Json';
New-Alias -Name '2csv' -Value 'ConvertTo-Csv';
New-Alias -Name 'csv2' -Value 'ConvertFrom-Csv';
New-Alias -Name '2html' -Value 'ConvertTo-Html';
New-Alias -Name 'ping' -Value 'Test-Connection';
New-Alias -Name 'find' -Value 'Select-String';
New-Alias -Name 'grep' -Value 'Select-String';
New-Alias -Name 'tasklist' -Value 'Get-Process';
New-Alias -Name 'taskkill' -Value 'Stop-Process';

Export-ModuleMember -Function @() -Alias @('*') -Cmdlet @() -Variable @();
