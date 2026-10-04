# ============================================================
#  Mediciones para la Tabla 5: Nativo (cv_app) vs Embebido
#  Uso (PowerShell, con el emulador encendido y ambas apps instaladas):
#    powershell -ExecutionPolicy Bypass -File .\medir.ps1
# ============================================================

$adb   = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
$base  = "D:\hoja_de_vida_App"
$apps  = @(
  @{ Nombre = "Nativo (cv_app)";       Pkg = "com.jeyempar.cv_app";
     Apk = "$base\cv_app\build\app\outputs\flutter-apk\app-release.apk" },
  @{ Nombre = "Embebido (WebView)";    Pkg = "com.jeyempar.cv_flutter_wrapper";
     Apk = "$base\cv-hibrido\cv_flutter_wrapper\build\app\outputs\flutter-apk\app-release.apk" }
)
$repeticiones = 3

if (-not (Test-Path $adb)) { Write-Host "No se encontro adb en $adb" -ForegroundColor Red; exit 1 }
$dev = (& $adb devices) | Select-String "\tdevice$"
if (-not $dev) { Write-Host "No hay emulador conectado. Enciendelo desde Device Manager." -ForegroundColor Red; exit 1 }

$resultados = @()

foreach ($a in $apps) {
  Write-Host "`n=== $($a.Nombre) ===" -ForegroundColor Cyan

  # --- 1. Tamano del APK ---
  if (Test-Path $a.Apk) {
    $mb = [math]::Round((Get-Item $a.Apk).Length / 1MB, 1)
  } else {
    Write-Host "  No existe $($a.Apk). Compila con: flutter build apk --release" -ForegroundColor Yellow
    $mb = "N/D"
  }
  Write-Host "  Tamano APK: $mb MB"

  # Instalar la version release para medir lo mismo que se compara
  if (Test-Path $a.Apk) { & $adb install -r $a.Apk | Out-Null }

  # --- 2. Arranque en frio (promedio) ---
  $tiempos = @()
  for ($i = 1; $i -le $repeticiones; $i++) {
    & $adb shell am force-stop $a.Pkg
    Start-Sleep -Seconds 2
    $salida = & $adb shell am start -W -n "$($a.Pkg)/.MainActivity"
    $m = $salida | Select-String "TotalTime:\s*(\d+)"
    if ($m) {
      $t = [int]$m.Matches[0].Groups[1].Value
      $tiempos += $t
      Write-Host "  Arranque $i : $t ms"
    } else {
      Write-Host "  Arranque $i : no se pudo leer (esta instalada la app?)" -ForegroundColor Yellow
    }
  }
  $promedio = if ($tiempos.Count) { [math]::Round(($tiempos | Measure-Object -Average).Average) } else { "N/D" }

  # --- 3. Memoria (PSS) con la app abierta ---
  Start-Sleep -Seconds 6
  $mem = & $adb shell dumpsys meminfo $a.Pkg
  $pss = $mem | Select-String "TOTAL PSS:\s*(\d+)"
  if (-not $pss) { $pss = $mem | Select-String "^\s*TOTAL\s+(\d+)" }
  $ramMb = if ($pss) { [math]::Round([int]$pss.Matches[0].Groups[1].Value / 1024, 1) } else { "N/D" }
  Write-Host "  Memoria PSS: $ramMb MB"

  $resultados += [pscustomobject]@{
    "App"               = $a.Nombre
    "Tamano APK (MB)"   = $mb
    "Arranque (ms)"     = $promedio
    "Memoria PSS (MB)"  = $ramMb
  }
}

Write-Host "`n================ RESULTADOS PARA LA TABLA 5 ================" -ForegroundColor Green
$resultados | Format-Table -AutoSize
$resultados | Format-Table -AutoSize | Out-String | Out-File -Encoding utf8 "$PSScriptRoot\resultados_medicion.txt"
Write-Host "Guardado en $PSScriptRoot\resultados_medicion.txt"
