$ErrorActionPreference = "Stop"

Write-Host "--- Starting Unity 6 CoreCLR Build ---" -ForegroundColor Cyan

# 1. 編譯 UniverseLib
Write-Host "Building UniverseLib..." -ForegroundColor Gray
Set-Location UniverseLib
.\build.ps1
Set-Location ..

# 2. 編譯 CUE (CoreCLR Target)
Write-Host "Building CUE CoreCLR..." -ForegroundColor Gray
dotnet build src/CinematicUnityExplorer.sln -c Release_BIE_Unity_Cpp

$Path = "Release/CinematicUnityExplorer.BepInEx.Unity.IL2CPP.CoreCLR"
$LibDir = "lib"

# 3. 合併 DLL (ILRepack)
Write-Host "Merging DLLs..." -ForegroundColor Gray
& "$LibDir/ILRepack.exe" /target:library /lib:"$LibDir/net472/BepInEx/build647+" /lib:"$LibDir/net6" /lib:"$LibDir/interop" /lib:"$Path" /internalize /out:"$Path/CinematicUnityExplorer.BIE.Unity.IL2CPP.CoreCLR.dll" "$Path/CinematicUnityExplorer.BIE.Unity.IL2CPP.CoreCLR.dll" "$Path/mcs.dll" "$Path/Tomlet.dll"

# 4. 清理
Write-Host "Cleaning temporary files..." -ForegroundColor Gray
"Tomlet.dll", "mcs.dll", "Iced.dll", "Il2CppInterop.Common.dll", "Il2CppInterop.Runtime.dll", "Microsoft.Extensions.Logging.Abstractions.dll", "CinematicUnityExplorer.BIE.Unity.IL2CPP.CoreCLR.deps.json" | ForEach-Object {
    $file = Join-Path $Path $_
    if (Test-Path $file) { Remove-Item $file -Force }
}

# 5. 建立發布目錄結構
$PluginsDir = Join-Path $Path "plugins/CinematicUnityExplorer"
New-Item -Path $PluginsDir -ItemType Directory -Force | Out-Null

Move-Item -Path "$Path/CinematicUnityExplorer.BIE.Unity.IL2CPP.CoreCLR.dll" -Destination $PluginsDir -Force
Move-Item -Path "$Path/UniverseLib.BIE.IL2CPP.Interop.dll" -Destination $PluginsDir -Force

# 6. 打包 Zip
$ZipFile = "Release/CinematicUnityExplorer.BepInEx.Unity.IL2CPP.CoreCLR.zip"
if (Test-Path $ZipFile) { Remove-Item $ZipFile }
Compress-Archive -Path "$Path/plugins" -DestinationPath $ZipFile

Write-Host "SUCCESS: $ZipFile is ready!" -ForegroundColor Green