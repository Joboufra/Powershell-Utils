[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Send-ntfy{
    param (
        [string]$m,
        [string]$p = 'default',
        [string]$tags = ''
    )
        $msgNTFY = @{
        Method = "POST"
        URI = "https://ntfy.joboufra.es/joboufra"
        Headers = @{
            Tags = "$tags"
            Title = "joboufra - DNSupdater"
            Priority = "$p"
            Authorization = "Bearer $ntfyTk"
        }
        Body = $m
    }  
    Invoke-RestMethod @msgNTFY | Out-Null
}

#Config
[xml]$xml= Get-Content $PSScriptRoot\config.xml
$apiToken = $xml.config.cfToken
$idZona= $xml.config.cfZoneId
$ntfyTk= $xml.config.ntfyToken
$email = $xml.config.email
$ipActual = Invoke-RestMethod http://ipinfo.io/json | Select-Object -ExpandProperty ip #Obtener IP actual

#Header para la petición
$headers = @{
    "X-Auth-Email" = $email
    "Authorization" = "Bearer $apiToken"
}

#Recuperamos todos los registros A de Cloudflare
$respuesta = Invoke-RestMethod -Uri "https://api.cloudflare.com/client/v4/zones/$idZona/dns_records?type=A" -Headers $headers
$registros = $respuesta.result

#Analizamos, actualizamos y notificamos
foreach ($registro in $registros) {
    $idRegistro = $registro.id
    $nombreRegistro = $registro.name
    $cloudflareIP = $registro.content

    if ($ipActual -ne $cloudflareIP) {
        $updateDNS = @{
            Uri     = "https://api.cloudflare.com/client/v4/zones/$idZona/dns_records/$idRegistro"
            Method  = 'PUT'
            Headers = @{"Authorization" = "Bearer $apiToken"; "Content-Type" = "application/json" }
            Body    = @{
              "type"    = "A"
              "name"    = $registro.name
              "content" = $ipActual
              "proxied" = $true
              "ttl"     = 3600
            } | ConvertTo-Json
          }
        $resultadoUpdateDNS = Invoke-RestMethod @updateDNS
        if ($resultadoUpdateDNS.success -ne "True") {
            Write-Output "ERROR ==> $nombreRegistro - Fallo al actualizar"
            Send-ntfy -m "El registro DNS de $nombreRegistro no se ha podido actualizar $ipActual"  -p high -tags rotating_light
          }
          Write-Output "==> $nombreRegistro DNS Record se actualiza a: $ipActual" 
          Send-ntfy -m "El registro DNS de $nombreRegistro se actualiza a: $ipActual" -tags heavy_check_mark
    }
    else {
        Write-Host "==> Las ips coinciden, $nombreRegistro no se actualiza"
        Send-ntfy -m "Las ips coinciden, el registro DNS de $nombreRegistro no se actualiza"
    }
}
