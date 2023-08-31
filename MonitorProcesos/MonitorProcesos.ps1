function Write-Header {
    $nombreApp= 'Monitor de procesos // Jose Boullosa '
    $linea = '=' * ($nombreApp.Length + 10)
    Write-Host $linea
    Write-Host "==   $nombreApp   =="
    Write-Host $linea
}

$opciones = @(
    "_Filtrar por nombre de proceso",
    "_+ Aumentar tiempo de refresco "
    "_- Disminuir tiempo de refresco"
    "_Salir"
)

$menuOpciones = @()
foreach ( $opcion in $opciones ) {
    $opcionInput = $opcion -replace '.*_(.).*','$1'
    $menuOpciones += @{
        'input' = $opcionInput
        'menuItem' = $opcion.Replace("_$($opcionInput)","[$opcionInput]")
    }
}

$duracionMS = 10000
$run = $true
$params = @{}
$top = 20

while ( $run ) {
    #Limpiar la consola
    [Console]::Clear()
    Write-Header
    #Mostrar información de procesos
    Get-Process @params |
        `Sort-Object WorkingSet -Descending |
        `Select-Object @{Label="Nombre del proceso"; Expression={$_.ProcessName}},@{Label="Id del proceso"; Expression={$_.Id}},@{Label="Uso de memoria (MB)"; Expression={"{0:N2}" -f ($_.WorkingSet / 1MB)}} |
        `Select-Object -First $top |
        `Out-String
    #Mostrar un prompt de una única línea
    Write-Host "[Tiempo de refresco: $($duracionMS)ms]" -ForegroundColor Green
    Write-Host "[Filtro aplicado: $filtro]" -ForegroundColor Green
    Write-Host ""
    Write-Host "$($menuOpciones.MenuItem-join(', ')): " -ForegroundColor Yellow #-NoNewline
    
    #Iniciar bucle y esperar por input de usuario hasta que la valor de refresco termine o el usuario nos de un input
    $inicioEspera = Get-Date
    $wait = $true
    While ( ((Get-Date) - $inicioEspera).TotalMilliseconds -le $duracionMS -and $wait) {
        if ( [Console]::KeyAvailable ) {
            $opcionUsuario = [Console]::ReadKey()
            if ( $opcionUsuario.KeyChar -in $menuOpciones.Input ) {
                switch ($opcionUsuario.KeyChar) {
                    F { 
                        # Obtener el filtro del proceso
                        Write-Host ""
                        Write-Host "`n[Introduce el nombre del proceso a filtrar. Si quieres eliminar el filtro no escribas nada y pulsa ENTER]" -ForegroundColor Yellow
                        $filtro = [Console]::ReadLine()

                        if ( $filtro ) { 
                            $params.Name = "*$($filtro)*"
                        } else {
                            #Eliminar el filtro si el nombre es vacío
                            $params.Remove("Name")
                        }
                        $wait = $false
                    }
                    - {
                        $duracionMS -= 500
                        $wait = $false
                    }
                    + {
                        $duracionMS += 500
                        $wait = $false
                    }
                    S {
                        $wait = $false
                        $run = $false
                        Write-Host ""
                        Write-Host "`n[Parando monitor y cerrando programa]" -ForegroundColor Red
                    }
                }
            } else {
                Write-Host ""
                Write-Host "`n[Opcion incorrecta]" -ForegroundColor Red
                Start-Sleep -Milliseconds 500
                #Romper el bucle
                $wait = $false
            }
        }
        Start-Sleep -Milliseconds 10
    }
}