$currentPath = 'C:\ZAGORCHEV\Feather Distributions\1.6.500.0';

$widgetsFolderName = "sitefinity-mvc";
$commonBinFolderName = "common-bin";

$msbuild = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe";
$projectCsproj = "C:\ZAGORCHEV\Sitefinity 9.1\Projects\Project91\SitefinityWebApp.csproj";
$logsFolder = "C:\ZAGORCHEV\Feather Distributions\Logs";

# get the folder
$newLocation = Get-ChildItem -Path $currentPath | where {$_.name -match (‘^’ + $widgetsFolderName)} |
select -First 1 | select -ExpandProperty FullName;

# navigate to folder
Set-Location -Path $newLocation
# create the folder
New-Item $commonBinFolderName -ItemType directory

# get project files
$files = Get-ChildItem -Path $newLocation -Recurse | where {$_.name -match ‘^Telerik.Sitefinity.Mvc.*\.csproj$’} |
 where {$_.name -match ‘^((?!test).)*$’};

ForEach ($file In $files)
{
    $fileName = $file.FullName;
    # change the output folder to the common one
    $content = ([System.IO.File]::ReadAllText($fileName)).Replace("<OutputPath>bin\Debug\</OutputPath>","<OutputPath>..\common-bin</OutputPath>");
    [System.IO.File]::WriteAllText($fileName, $content);
}

#Write-Host("Press Enter to continue");
#$x = $host.UI.RawUI.ReadKey(“NoEcho,IncludeKeyDown”);
#if($x.VirtualKeyCode -ne 13)
#{
# exit;
#}

# build only Feather projects, not the entire solution (There might be problems building the Tests)
ForEach ($file In $files)
{
    $fileName = $file.FullName;
    $name = $file.Name.Replace(".csproj","");
    $c = '/flp:logfile=' + $logsFolder + '\' + $name +'.log;errorsonly';
    & $msbuild $fileName $c;
}

#Write-Host("Press Enter to continue");
#$x = $host.UI.RawUI.ReadKey(“NoEcho,IncludeKeyDown”);
#if($x.VirtualKeyCode -ne 13)
#{
# exit;
#}

# fix references
$newReferenceFolder = $newLocation + "\" + $commonBinFolderName;
$xml = New-Object xml;
$xml.load($projectCsproj);
$references = $xml.Project.ItemGroup.Reference;
ForEach ($file In $files)
{
    $name = $file.Name.Replace(".csproj","");
    $reference = $references | where { $_.Include -match $name } | Select -First 1;
    if($reference -eq $null)
    {
    continue;
    }
    $reference.HintPath = $newReferenceFolder + "\" + $name + ".dll";
}
$xml.save([string]$projectCsproj);