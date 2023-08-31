
param ( 
    [string]$url = 'Z:\' #Default
)
#Funciones
    function Write-Header {
        $nombreApp= 'obtenerConnectionStrings // Jose Boullosa '
        $linea = '=' * ($nombreApp.Length + 10)
        Write-Host $linea
    Write-Host "==   $nombreApp   =="
    Write-Host $linea
}

#Lógica
$pathCS = "$url\connectionStrings.config"
Write-Header
if (-Not (Test-Path $pathCS)) {
    Write-Host "Error: No se pudo encontrar el archivo $pathCS" -ForegroundColor Red
    exit
    }   
else {
    Write-Host "Archivo encontrado en $pathCS" -ForegroundColor Green
    }

$xml = [xml](Get-Content $pathCS)
$connString = $xml.SelectNodes("connectionStrings/add") | Select-Object connectionString -First 1

$sb = New-Object System.Data.Common.DbConnectionStringBuilder
$sb.set_ConnectionString($connString.connectionString)

$Username = $sb["User Id"]
$Password = $sb["Password"]
$BaseDatos = $sb["Database"]
$Servidor = $sb["Server"]

$csData = @{
    Username = $Username
    Password = $Password
    BaseDatos = $BaseDatos
    Servidor = $Servidor
    }

Write-Host ""
Write-Host "Username: $($csData.Username)" -ForegroundColor Yellow
Write-Host "Password: $($csData.Password)" -ForegroundColor Yellow
Write-Host "Database: $($csData.BaseDatos)" -ForegroundColor Yellow
Write-Host "Servidor: $($csData.Servidor)" -ForegroundColor Yellow
