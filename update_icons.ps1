$logo = "smartiptv_source/app/src/main/res/drawable/app_logo.png"
$folders = @("mipmap-mdpi", "mipmap-hdpi", "mipmap-xhdpi", "mipmap-xxhdpi", "mipmap-xxxhdpi")

foreach ($f in $folders) {
    $dir = "android/app/src/main/res/$f"
    if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force }
    Copy-Item $logo -Destination "$dir/ic_launcher.png" -Force
    Copy-Item $logo -Destination "$dir/ic_launcher_round.png" -Force
}

$dir2 = "C:\Users\hossa\AndroidStudioProjects\jokartv\android\app\src\main\res"
foreach ($f in $folders) {
    $d = "$dir2\$f"
    if (!(Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force }
    Copy-Item $logo -Destination "$d/ic_launcher.png" -Force
    Copy-Item $logo -Destination "$d/ic_launcher_round.png" -Force
}

Write-Host "App launcher icons updated successfully!"
