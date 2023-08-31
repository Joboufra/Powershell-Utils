#Parámetros
param (
    [string]$Unidad = 'C:', #Valores default
    [string]$Umbral = '25', #Valores default
    [string]$Correo = 'joboufra@gmail.com' #Valores default
)

#Funciones
Function Get-DirectorioActual {
    if (!$PSScriptRoot) { 
        Split-Path -Parent (Convert-Path ([environment]::GetCommandLineArgs()[0])) 
    } 
    else { 
        $PSScriptRoot 
    }
}   
function Write-Header {
    $nombreApp= 'Alerta de Espacio en disco // Jose Boullosa '
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
    $correoDestino = 'joboufra@gmail.com'
    $servidorSMTP = 'smtp-mail.outlook.com'
    $correoParams = @{
        From       = $dataCreds.Username
        To         = $correoDestino
        Subject    = "Alerta de Backups en $hostname"
        Body       = "No se ha realizado backup en los últimos $countDias días en $hostname."
        SmtpServer = $servidorSMTP
        Port       = 587
        UseSsl     = $true
        Credential = $dataCreds
    }
    Send-MailMessage @correoParams
}
function Send-EmailDotNet {
        $dataCreds = Import-CliXml -Path $directorioActual"\.data\data.crd"
        $correoDestino = $correo
        $servidorSMTP = 'smtp-mail.outlook.com'
        
        $from = New-Object System.Net.Mail.MailAddress($dataCreds.Username, "Jose Boullosa - freeSpaceAlert")
        $to = New-Object System.Net.Mail.MailAddress($correoDestino)
        $mail = New-Object System.Net.Mail.MailMessage($from, $to)
        
        $mail.Subject = "Alerta de Espacio en Disco en $hostname"
        $mail.Body = "La unidad $unidad tiene espacio en disco por debajo del umbral ($porcEspacioLibre%) en $hostname."
        
        $smtp = New-Object System.Net.Mail.SmtpClient($servidorSMTP, 587)
        $smtp.EnableSsl = $true
        $smtp.Credentials = New-Object System.Net.NetworkCredential($dataCreds.Username, $dataCreds.GetNetworkCredential().Password)

        $smtp.Send($mail)
    }

#Variables
$directorioActual = Get-DirectorioActual
$valorUnidad = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID = '$unidad'"
$porcEspacioLibre = [math]::Round(($valorUnidad.FreeSpace / $valorUnidad.Size) * 100, 2)
[string]$hostname=hostname

#Lógica
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
else {
    if ($porcEspacioLibre -lt $umbral) {
        Write-Header
        Write-Host "Unidad seleccionada: $unidad"
        Write-Host "Umbral de porcentaje seleccionado: $umbral%"
        Write-Host "---------------------------------------------------"
        Write-Host "[Alerta] Espacio libre en disco en la unidad $unidad por debajo del umbral establecido: ($porcEspacioLibre%)."
        Send-EmailDotNet

    } else {
        Write-Header
        Write-Host "Unidad seleccionada: $unidad"
        Write-Host "Umbral de porcentaje seleccionado: $umbral%"
        Write-Host "---------------------------------------------------"
        Write-Host "El espacio libre en en la unidad $unidad es superior al umbral establecido: ($porcEspacioLibre%)."
    }
}
