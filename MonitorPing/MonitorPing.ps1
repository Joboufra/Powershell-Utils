$fecha = Get-Date -Format yyyyMMdd
$LogPath = "$PSScriptRoot\$fecha\MonitorPing-$fecha.csv"
$DirectorioFecha= "$PSScriptRoot\$fecha"
$dirConfig = $PSScriptRoot + "\config.xml"

#Archivo config
if (!(Test-Path $dirConfig)) {
    write-host "Creando archivo config base..." -ForegroundColor Yellow
    $xmlObjectsettings = New-Object System.Xml.XmlWriterSettings
    $xmlObjectsettings.Indent = $true
    $xmlObjectsettings.IndentChars = "    "
#Establece directorio y crea el .xml de config base si no existe
    $XmlDir = $PSScriptRoot + "\config.xml"
    $XmlObjectWriter = [System.XML.XmlWriter]::Create($XmlDir, $xmlObjectsettings)
#Escribe en XML, iniciamos el .xml
    $XmlObjectWriter.WriteStartDocument()
    $XmlObjectWriter.WriteStartElement("config")
    $XmlObjectWriter.WriteComment("Tiempo en horas de ejecucion de la app")
    $XmlObjectWriter.WriteElementString("Tiempo", "24")
    $XmlObjectWriter.WriteComment("Tiempo de espera (segundos) entre cada peticion")
    $XmlObjectWriter.WriteElementString("Sleep", "5")
    $XmlObjectWriter.WriteComment("IP a monitorizar")
    $XmlObjectWriter.WriteElementString("Dispositivo", "127.0.0.1")
    $XmlObjectWriter.WriteEndElement()
    $XmlObjectWriter.WriteEndDocument()
    $XmlObjectWriter.Flush()
    $XmlObjectWriter.Close()
Write-Host "Archivo de config base creado, configuralo correctamente y reinicia el programa" -ForegroundColor Yellow
Write-Host ""
start-sleep 3
exit
}
#Cargamos Config
[xml]$xml= Get-Content $PSScriptRoot\config.xml
[int]$TiempoCfg = $xml.config.Tiempo
$Ticks = (($TiempoCfg * 60) * 60)/$Sleep #Desde el valor de horas de cfg, lo llevamos a ticks (Tiempo en s / tiempo de Sleep) para el loop
$Sleep = $xml.config.Sleep
$Dispositivo = $xml.config.Dispositivo

#Crear directorio intermedio
if (-not(Test-Path $DirectorioFecha)) {
    try {
    Write-Host [Check de directorio de resultados] -ForegroundColor "Yellow"
    Write-Host "El directorio de resultados no existe, lo creamos" -Foreground "Red"
    Write-Host ""
    New-Item -ItemType directory -Path $DirectorioFecha -Force -ErrorAction Stop | Out-Null
    }
    catch {
        Write-Log "ERROR: Fallo en la creacion del directorio"
        throw $_.Exception.Message
     }
    }
$Ping = @()
#Establecemos cabecera log
if (-not (Test-Path $LogPath)){   
    try {
    Write-Host "[Creando archivo de resultados]" -ForegroundColor Yellow
    Write-Host "El archivo de log no existe, lo creamos" -ForegroundColor Red
    Write-Host ""
    Add-Content -Value '"Hora","Direccion IP","Estado","Tiempo de Respuesta (ms)"' -Path $LogPath
    }
    catch {
        Write-Log "ERROR: Fallo en la creacion del archivo de log"
        throw $_.Exception.Message
    }
}
#Escritura en log
Write-Host "Tiempo de recogida de datos establecido: $TiempoCfg horas" -ForegroundColor Cyan
Write-Host "Sleep establecido: $Sleep" -ForegroundColor Cyan
Write-Host "Monitorizando $Dispositivo" -ForegroundColor Green
Write-Host "POR FAVOR, NO CIERRES LA VENTANA. USA CTRL+C PARA PARAR" -BackgroundColor Red -ForegroundColor Black
while ($Ticks -gt 0) {   
    $Ping = Get-WmiObject Win32_PingStatus -Filter "Address = '$Dispositivo'" | Select-Object @{Label="Hora";Expression={Get-Date}},@{Label="IP";Expression={ $_.Address }},@{Label="Estado";Expression={ If ($_.StatusCode -ne 0) {"Error"} Else {"OK"}}},ResponseTime
    $Result = $Ping | Select-Object Hora,IP,Estado,ResponseTime | ConvertTo-Csv -NoTypeInformation
    $Result[1] | Add-Content -Path $LogPath
    Write-Verbose ($Ping | Select-Object Hora,IP,Estado,ResponseTime | Format-Table -AutoSize | Out-String)
    $Ticks --
    Start-Sleep -Seconds $Sleep
}