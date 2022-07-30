#!/usr/bin/env pwsh

#requires -version 6.2

# initialize
$root = New-Item (Join-Path (Get-Location) ('AviUtl_' + (Get-Date -f 'yyyyMMddHHmmss'))) -ItemType Directory -Force
$plugins = New-Item (Join-Path $root plugins) -ItemType Directory -Force
$script = New-Item (Join-Path $root script) -ItemType Directory -Force
$licenses = New-Item (Join-Path $root LICENSES) -ItemType Directory -Force

Add-Type -AssemblyName 'System.IO.Compression.FileSystem'

function Install-Plugin {
    [CmdletBinding()]
    param (
        [string]$Repo, # author/name の形で定義する
        [string]$Url, # プラグインのURL ないし ファイルパス
        [string]$Target, # ワイルドカード
        [string]$Exclude, # カンマ区切り、ワイルドカード使用可
        [string]$Prefix,
        [string]$License, # 正規表現
        [string]$Path
    )

    $param = @{
        Uri     = $Url
        OutFile = [System.IO.Path]::GetFileName($Url)
    }
    if (($param.Uri -as [System.Uri]).Scheme -ne 'file') {
        Invoke-WebRequest @param
    }
    $archiveFile = [System.IO.FileInfo](Convert-Path $param.OutFile)

    $destinationPath = New-Item ([System.IO.Path]::GetFileNameWithoutExtension($archiveFile)) -ItemType Directory -Force
    [System.IO.Compression.ZipFile]::ExtractToDirectory($archiveFile, $destinationPath.FullName, [System.Text.Encoding]::GetEncoding('shift_jis'), $true)
    $archiveItems = Get-ChildItem $destinationPath -Exclude $Exclude -Force

    # 中身が単一のフォルダである場合はその中身を取得
    if (@($archiveItems).Count -eq 1 -and $archiveItems.PSIsContainer) {
        $archiveItems = Get-ChildItem $archiveItems.FullName
    }

    $targetItems = $archiveItems | Where-Object { $_.Name -like $Target }

    if (![string]::IsNullOrEmpty($License)) {
        $licenseItems = $archiveItems | Where-Object { $_.Name -match $License }
    }
    else {
        $licenseItems = $null
        # 以降の除外処理で空文字を使用できないため、全てに当てはまらない正規表現を定義
        $License = '(?!.*)'
    }

    if (![string]::IsNullOrEmpty($Prefix)) {
        $otherItems = $archiveItems | Where-Object { ($_.Name -notlike $Target) -and ($_.Name -notmatch $License) }
    }
    else {
        $otherItems = $null
    }

    if ($null -ne $targetItems) {
        Move-Item $targetItems -Destination $Path -Force
    }
    else {
        Write-Host 'No target item found.'
    }

    if ($null -ne $licenseItems) {
        Move-Item $licenseItems -Destination (New-Item (Join-Path $licenses $Repo) -ItemType Directory -Force) -Force
    }

    if ($null -ne $otherItems) {
        $otherItems | ForEach-Object { Move-Item $_ -Destination (Join-Path $Path ($Prefix + $_.Name)) -Force }
    }

    Remove-Item $archiveFile -Recurse -Force
    Remove-Item $destinationPath -Recurse -Force
}

Set-Location $root

# install core
$coreFiles = @(
    'http://spring-fragrance.mints.ne.jp/aviutl/aviutl110.zip',
    'http://spring-fragrance.mints.ne.jp/aviutl/exedit92.zip'
)
foreach ($coreFile in $coreFiles) {
    $param = @{
        Uri     = $coreFile
        OutFile = [System.IO.Path]::GetFileName($coreFile)
    }
    Invoke-WebRequest @param
    Expand-Archive $param.OutFile -DestinationPath $root -Force
    Remove-Item $param.OutFile -Force
}

# install plugins
$pluginFiles = @(
    @{
        Name    = 'easymp4'
        Author  = 'aoytsk'
        Url     = 'https://aoytsk.blog.jp/aviutl/easymp4.zip'
        Target  = 'easymp4*'
        Prefix  = 'easymp4_'
        License = 'license.txt'
        Path    = 'plugins'
    },
    @{
        Name    = 'auls_memref'
        Author  = 'aoytsk'
        Url     = 'https://scrapbox.io/files/60a97027a8a637001c326378.zip'
        Target  = 'auls_memref.auf'
        Exclude = 'src'
        Prefix  = 'auls_memref_'
        Path    = 'plugins'
    }
)
foreach ($pluginFile in $pluginFiles) {
    $param = @{
        Repo    = $pluginFile.Author + '/' + $pluginFile.Name
        Url     = $pluginFile.Url
        Target  = $pluginFile.Target
        Exclude = $pluginFile.Exclude
        Prefix  = $pluginFile.Prefix
        License = $pluginFile.License
        Path    = Get-Variable $pluginFile.Path -ValueOnly
    }
    Install-Plugin @param
}

# install plugins on GitHub
$githubFiles = @(
    @{
        Repo    = 'Mr-Ojii/L-SMASH-Works-Auto-Builds'
        File    = 'L-SMASH-Works_*_Mr-Ojii_Mr-Ojii_AviUtl.zip'
        Target  = 'lw*'
        Prefix  = 'lw_'
        License = 'Licenses|LICENSE'
        Path    = 'plugins'
    },
    @{
        Repo    = 'amate/InputPipePlugin'
        File    = 'InputPipePlugin_*.zip'
        Target  = 'InputPipe*'
        Prefix  = 'InputPipePlugin_'
        License = 'LICENSE'
        Path    = 'plugins'
    },
    @{
        Repo    = 'ePi5131/patch.aul'
        File    = 'patch_*.zip'
        Target  = 'patch.aul*'
        Prefix  = 'patch_'
        License = 'LICENSE|COPYING.*|credits.md'
        Path    = 'root'
    },
    @{
        Repo    = 'Per-Terra/LuaJIT-Auto-Builds'
        File    = 'LuaJIT-2.1.0-beta3_Win_x86.zip'
        Target  = 'lua51.dll'
        License = 'COPYRIGHT'
        Path    = 'root'
    }
)
foreach ($githubFile in $githubFiles) {
    $repo = $githubFile.Repo
    $file = $githubFile.File
    $json = Invoke-WebRequest "https://api.github.com/repos/$repo/releases/latest" | ConvertFrom-Json
    $urls = $json.assets.browser_download_url | Where-Object { $_ -like "*/$file" }
    foreach ($url in $urls) {
        $param = @{
            Repo    = $githubFile.Repo
            Url     = $url
            Target  = $githubFile.Target
            Exclude = $githubFile.Exclude
            Prefix  = $githubFile.Prefix
            License = $githubFile.License
            Path    = Get-Variable $githubFile.Path -ValueOnly
        }
        Install-Plugin @param
    }
}

# install plugins on アマゾンっぽい
$amazonFiles = @(
    @{
        Name    = 'rikkymodule'
        Author  = 'rikky'
        Id      = 'rikkymodulea2Z'
        Target  = 'rikky_*'
        License = 'license'
        Path    = 'root'
    }
)
foreach ($amazonFile in $amazonFiles) {
    $id = $amazonFile.Id
    $param = @{
        Uri     = "https://hazumurhythm.com/php/amazon_download.php?name=$id"
        Headers = @{"Referer" = "https://hazumurhythm.com/wev/amazon/?script=$id" }
    }
    $response = Invoke-WebRequest @param
    [string]$response.Headers."Content-Disposition" -match 'filename="(?<filename>.*?)"'  > $null
    $outFile = Join-Path $root $Matches.filename
    [System.IO.File]::WriteAllBytes($outFile, $response.Content)

    $param = @{
        Repo    = $amazonFile.Author + '/' + $amazonFile.Name
        Url     = $outFile
        Target  = $amazonFile.Target
        Exclude = $amazonFile.Exclude
        Prefix  = $amazonFile.Prefix
        License = $amazonFile.License
        Path    = Get-Variable $amazonFile.Path -ValueOnly
    }
    Install-Plugin @param
}

# generate aviutl.ini with recommended settings
$aviutlIni = @'
[system]
width=4864
height=4864
moveC=600
moveD=6000
saveunitsize=2048
compprofile=0
startframe=0
movieplaymain=1
vfplugin=0
editresume=1
dragdropdialog=1
resizelist=3860x2160,2560x1440,1920x1080,1280x720,640x480,352x240,320x240
[拡張編集]
auto_save=1
auto_save_num=100
auto_save_time=1
small_layer=2
disp=1
[AVI/AVI2 File Reader]
priority=2
[Wave File Reader]
priority=6
[BMP File Reader]
priority=0
[JPEG/PNG File Reader]
priority=1
[AVI File Reader ( Video For Windows )]
priority=7
[拡張編集 File Reader]
priority=5
[InputPipePlugin]
priority=3
[L-SMASH Works File Reader]
priority=4
'@
$aviutlIni | Out-File (Join-Path $root 'aviutl.ini') -Encoding 'shift_jis'

# generate lsmash.ini with recommended settings
$lsmashIni = @'
preferred_decoders=libvpx,libvpx-vp9
handle_cache=1
'@
$lsmashIni | Out-File (Join-Path $plugins 'lsmash.ini') -Encoding 'shift_jis'