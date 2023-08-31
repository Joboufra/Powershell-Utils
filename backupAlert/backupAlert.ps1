 #Parámetros
param (
    [string]$RutaBackup = 'C:\', #Valores default
    [string]$Dias = '3', #Valores default
    [string]$Correo = 'joboufra@gmail.com' #Valores default
)

#Functions
 Function Get-DirectorioActual {
    if (!$PSScriptRoot) { 
        Split-Path -Parent (Convert-Path ([environment]::GetCommandLineArgs()[0])) 
    } 
    else { 
        $PSScriptRoot 
    }
}   
function Write-Header {
    $nombreApp= 'Do-Check backups // Jose Boullosa '
    $linea = '=' * ($nombreApp.Length + 10)
    Write-Host $linea
    Write-Host "==   $nombreApp   =="
    Write-Host $linea
}
function Get-Credenciales {
    if (!(Test-Path $directorioActual"\.data")) {
        New-Item -Path $directorioActual"\.data" -ItemType Directory -Force
    }
    Get-Credential | Export-Clixml $directorioActual"\.data\data.crd"
    Clear-Host
    Write-Host "Credenciales generados, reinicio requerido para aplicar los cambios" -ForegroundColor "Red"
    exit
}
function Send-Email {
    $dataCreds = Import-CliXml -Path $directorioActual"\.data\data.crd"
    $correoDestino = $Correo
    $servidorSMTP = 'smtp-mail.outlook.com'
    $correoParams = @{
        From       = $dataCreds.Username
        To         = $correoDestino
        Subject    = "Alerta de Espacio en Disco en $hostname"
        Body       = "La unidad $unidad tiene espacio en disco por debajo del umbral ($porcEspacioLibre%) en $hostname."
        SmtpServer = $servidorSMTP
        Port       = 587
        UseSsl     = $true
        Credential = $dataCreds
    }
    Send-MailMessage @correoParams
}
function Send-EmailDotNet {
    $dataCreds = Import-CliXml -Path $directorioActual"\.data\data.crd"
    $correoDestino = $Correo
    $servidorSMTP = 'smtp-mail.outlook.com'
    
    $from = New-Object System.Net.Mail.MailAddress($dataCreds.Username, "Jose Boullosa - backupAlert")
    $to = New-Object System.Net.Mail.MailAddress($correoDestino)
    $mail = New-Object System.Net.Mail.MailMessage($from, $to)
    
    $mail.Subject = "Alerta Crear backups en $hostname"
    $mail.Body = "No se realizan backups en '$backupFolder' desde hace $diasUltimoBackup dias en $hostname, por lo que se ha forzado la realización de backup y se notifica con este correo."

    $smtp = New-Object System.Net.Mail.SmtpClient($servidorSMTP, 587)
    $smtp.EnableSsl = $true
    $smtp.Credentials = New-Object System.Net.NetworkCredential($dataCreds.Username, $dataCreds.GetNetworkCredential().Password)

    $smtp.Send($mail)
}

#Variables
$directorioActual = Get-DirectorioActual
$timestamp = Get-Date -Format "yyyyMMdd"
$hostname=hostname
$rutaBackup="$directorioActual\rutaBackup"
$backupFolder = "$directorioActual\backups" #Ruta de backups
$backupZips = Get-ChildItem -Path $backupFolder | Where-Object { $_.Name -match "backup_\d{8}\.zip" }
$backupFile = Join-Path -Path $backupFolder -ChildPath "backup_$timestamp.zip"

#Comprobamos que los credenciales existen, si no existen los generamos
if (!(Test-Path $directorioActual"\.data\data.crd")) { 
    try{
        Write-Host "ERROR: No se pueden cargar los credenciales. Archivo no encontrado." -ForegroundColor "Red"
        Write-Host "Creamos nuevo archivo de credenciales. Se abre una nueva ventana." -ForegroundColor "Green"
        Get-Credenciales 
    }
    catch{
        Write-Host "ERROR: Fallo en el encriptado de credenciales"
        throw $_.Exception.Message
        }
    }

#Comprobamos si existe la carpeta de backups, si no existe la creamos
if (!(Test-Path $backupFolder)) {
    New-Item -Path $backupFolder -ItemType Directory -Force
    }

#Revisamos si hay algún backup realizado
if ($backupZips.Count -eq 0) {
    Write-Header
    $diasUltimoBackup = 'varios'
    Write-Host "No se encontraron archivos de respaldo en la carpeta, por lo que lo realizamos y notificamos" -ForegroundColor Red
    Compress-Archive -Path "$rutaBackup\*" -DestinationPath $backupFile
    Send-EmailDotNet
    return
    } 
else {
    $ultimoBackup = $backupZips | ForEach-Object { $_.Name -match "backup_(\d{8})\.zip" | Out-Null; [datetime]::ParseExact($matches[1], "yyyyMMdd", $null) } | Sort-Object -Descending | Select-Object -First 1
    $diasUltimoBackup = (Get-Date).Subtract($ultimoBackup).Days
    }

#Comprobamos los días que llevamos sin realizar backups, si es más de 1 día realizamos backup y notificamos
if ($diasUltimoBackup -gt 1) {
    try {
        Write-Header
        Write-Host "No se ha realizado el backup hoy, por lo tanto lo realizamos y notificamos" -ForegroundColor Red
        Compress-Archive -Path "$backupFolder\*" -DestinationPath $backupFile
        Send-EmailDotNet
    }
    catch {
        Write-Header
        Write-Host "Error al comprimir el archivo"
        throw $_.Exception.Message
    }
}
else {
    Write-Header
    Write-Host "El backup se ha realizado hoy. Estado correcto." -ForegroundColor Green
}