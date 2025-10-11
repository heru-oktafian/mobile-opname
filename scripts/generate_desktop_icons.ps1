<#
PowerShell script to generate desktop icons from assets/img_icon_logo.png
Requirements:
- ImageMagick (magick) in PATH
- On macOS to create .icns, iconutil must be available (it's part of Xcode command line tools)

Usage (PowerShell):
    pwsh ./scripts/generate_desktop_icons.ps1

What it does:
- Generates Windows ICO at windows/runner/resources/app_icon.ico
- Generates macOS AppIcon.appiconset PNGs at macos/Runner/Assets.xcassets/AppIcon.appiconset/
  and optionally creates an ICNS file if iconutil is available (macOS only).
- Generates Linux PNG icons at linux/icons/ (512,256,128,64)
#>

param(
    [string]$Src = "assets/img_icon_logo.png",
    [string]$ProjectRoot = "$(Resolve-Path "..").Path"
)

Set-Location -Path $PSScriptRoot\..\
$root = Get-Location
Write-Host "Project root: $root"

$srcPath = Join-Path $root $Src
if (-not (Test-Path $srcPath)) {
    Write-Error "Source icon not found at $srcPath. Make sure assets/img_icon_logo.png exists."
    exit 1
}

# Ensure ImageMagick is available
$magick = Get-Command magick -ErrorAction SilentlyContinue
if (-not $magick) {
    Write-Error "ImageMagick 'magick' CLI not found. Install ImageMagick and ensure 'magick' is in PATH."
    exit 1
}

# Windows ICO
$winOutDir = Join-Path $root "windows/runner/resources"
New-Item -ItemType Directory -Force -Path $winOutDir | Out-Null
$winIco = Join-Path $winOutDir "app_icon.ico"
Write-Host "Generating Windows ICO -> $winIco"
# Use ImageMagick to auto-resize and create multi-resolution ICO
& magick convert $srcPath -define icon:auto-resize=16,24,32,48,64,128,256 $winIco
if ($LASTEXITCODE -ne 0) { Write-Warning "magick returned non-zero for ICO generation" }

# macOS AppIcon.appiconset
$macIconsetDir = Join-Path $root "macos/Runner/Assets.xcassets/AppIcon.appiconset"
New-Item -ItemType Directory -Force -Path $macIconsetDir | Out-Null

# Define macOS icon sizes required (name,width,height,scale)
$macSizes = @(
    @{name='icon_16'; size=16; scale=1},
    @{name='icon_16@2x'; size=16; scale=2},
    @{name='icon_32'; size=32; scale=1},
    @{name='icon_32@2x'; size=32; scale=2},
    @{name='icon_128'; size=128; scale=1},
    @{name='icon_128@2x'; size=128; scale=2},
    @{name='icon_256'; size=256; scale=1},
    @{name='icon_256@2x'; size=256; scale=2},
    @{name='icon_512'; size=512; scale=1},
    @{name='icon_512@2x'; size=512; scale=2}
)

$contents = @{images = @(); info = @{version=1; author = "xcode"}}
foreach ($entry in $macSizes) {
    $size = $entry.size
    $scale = $entry.scale
    $pixel = $size * $scale
    $filename = "${($entry.name)}.png"
    $outPath = Join-Path $macIconsetDir $filename
    Write-Host "Generating mac icon $filename (${pixel}x${pixel})"
    & magick convert $srcPath -resize ${pixel}x${pixel}^ -gravity center -extent ${pixel}x${pixel} $outPath
    $contents.images += @{"idiom"="universal"; "size"="${size}x${size}"; "scale"="${scale}x"; "filename"=$filename}
}
# Write Contents.json
$contentsJson = $macIconsetDir + '\Contents.json'
$contents | ConvertTo-Json -Depth 5 | Out-File -FilePath $contentsJson -Encoding utf8
Write-Host "Wrote $contentsJson"

# Optionally create .icns (macOS only, if iconutil exists)
$iconutil = Get-Command iconutil -ErrorAction SilentlyContinue
if ($iconutil) {
    $icnsOut = Join-Path $root "macos/Runner/Assets.xcassets/app_icon.icns"
    Write-Host "Creating ICNS -> $icnsOut"
    & iconutil -c icns $macIconsetDir -o $icnsOut
    if ($LASTEXITCODE -ne 0) { Write-Warning "iconutil returned non-zero" }
} else {
    Write-Warning "iconutil not found; on macOS install Xcode command line tools to create .icns automatically. The AppIcon.appiconset has been created with PNGs."
}

# Linux PNG icons
$linuxDir = Join-Path $root "linux/icons"
New-Item -ItemType Directory -Force -Path $linuxDir | Out-Null
$linuxSizes = @(512,256,128,64)
foreach ($s in $linuxSizes) {
    $out = Join-Path $linuxDir "icon_${s}.png"
    Write-Host "Generating Linux icon ${s}x${s} -> $out"
    & magick convert $srcPath -resize ${s}x${s}^ -gravity center -extent ${s}x${s} $out
}

Write-Host "Icon generation complete. Verify platform resources:
 - Windows: $winIco
 - macOS: $macIconsetDir (and optionally app_icon.icns)
 - Linux: $linuxDir"

Write-Host "Notes:
 - Ensure you commit the generated files if you want them in repo.
 - For Windows, the build uses windows/runner/resources/app_icon.ico referenced by Runner.rc.
 - For macOS, open Xcode and verify AppIcon.appiconset is included in Assets.
 - For Linux, ensure the packaging uses linux/icons/icon_512.png etc."