$progressPreference = 'silentlyContinue'
$url = "https://api.adoptium.net/v3/binary/latest/17/ga/windows/x64/jdk/hotspot/normal/eclipse"
$zipPath = "C:\flutter_windows_3.47.7-stable\flutter\jdk17.zip"
$extractPath = "C:\flutter_windows_3.47.7-stable\flutter\jdk_temp"
$finalPath = "C:\flutter_windows_3.47.7-stable\flutter\jdk17"

Write-Host "Downloading JDK 17..."
Invoke-WebRequest -Uri $url -OutFile $zipPath

Write-Host "Extracting JDK 17..."
if (Test-Path $extractPath) { Remove-Item $extractPath -Recurse -Force }
Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force

$extractedDir = Get-ChildItem $extractPath | Select-Object -First 1
if (Test-Path $finalPath) { Remove-Item $finalPath -Recurse -Force }
Move-Item -Path $extractedDir.FullName -Destination $finalPath -Force

Remove-Item $zipPath -Force
Remove-Item $extractPath -Recurse -Force

if (Test-Path "$finalPath\bin\javac.exe") {
    Write-Host "JDK 17 installed successfully at $finalPath"
} else {
    Write-Host "Installation failed!"
}
