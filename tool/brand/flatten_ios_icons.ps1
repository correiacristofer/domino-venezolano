# Strips the alpha channel from the iOS app icons: App Store Connect rejects
# an App Store icon that contains one, even when every pixel is opaque.
# Run after render_brand_assets_test.dart. Needs ffmpeg on PATH.
$dir = Join-Path $PSScriptRoot '..\..\ios\Runner\Assets.xcassets\AppIcon.appiconset'
Get-ChildItem $dir -Filter *.png | ForEach-Object {
    $tmp = "$($_.FullName).tmp.png"
    ffmpeg -hide_banner -loglevel error -y -i $_.FullName -pix_fmt rgb24 $tmp
    if ($LASTEXITCODE -ne 0) { throw "ffmpeg failed on $($_.Name)" }
    Move-Item -Force $tmp $_.FullName
}
