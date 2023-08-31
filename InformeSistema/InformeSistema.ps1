$DirectorioInforme = $PSScriptRoot + "\Informe.html"
Write-Host "Informe en $DirectorioInforme"
$fecha = Get-Date -Format "dd/MM/yyyy HH:mm:ss"

#Encabezado y pie de página
$EncabezadoHtml = @"
<header class='header'>
    <p class='logo'>
	<!--Reemplazar el tag svg con el logo que queramos*/-->
	<svg xmlns="http://www.w3.org/2000/svg" x="0px" y="0px" width="100" height="100" viewBox="0 0 22 22.969">
		<path d="M 9.691,14.8 6.411,11.488 9.6,8.3 C 9.336,8.026 9.066,7.74 8.8,7.44 A 5.857,5.857 0 0 1 7.263,3.807 l -6.97,6.97 a 1,1 0 0 0 0,1.414 l 10.777,10.778 0.7,-0.847 a 4.02,4.02 0 0 0 -0.061,-5.27 C 10.755,15.775 9.7,14.807 9.691,14.8 Z m 2.617,-6.631 3.281,3.311 -3.184,3.185 c 0.264,0.273 0.534,0.56 0.8,0.859 a 5.866,5.866 0 0 1 1.531,3.638 l 6.971,-6.971 a 1,1 0 0 0 0,-1.414 L 10.93,0 10.23,0.847 a 4.02,4.02 0 0 0 0.062,5.27 c 0.953,1.076 2.008,2.045 2.016,2.052 z"></path>
	</svg>
    </p>
    <div class='title' style="color: white">
        <h1>Informe de Sistema</h1>
        <p>Generado el $fecha</p>
    </div>
</header>
"@

$FooterHTML = "<footer class='footer'><p>Jose Boullosa - 2023</p></footer>"

#Variables de info
$ram = [math]::Round((Get-WmiObject Win32_OperatingSystem | Select-Object -ExpandProperty TotalVisibleMemorySize)/1MB, 2)
$sistemaOperativo = Get-WmiObject Win32_OperatingSystem | Select-Object -ExpandProperty Caption
$version = Get-WmiObject Win32_OperatingSystem | Select-Object -ExpandProperty Version
$proc = Get-WmiObject Win32_Processor
$procesador = $proc.Name
$velocidad = [math]::Round($proc.MaxClockSpeed / 1000, 2)
$nucleos = $proc.NumberOfCores
$maquina = Get-WmiObject win32_ComputerSystemProduct | Select-Object -ExpandProperty Name

#Objeto que rellenará Información de sistema
$infoSistema = @(
	@{ 'Clave' = 'Modelo del equipo'; 'Valor' = $maquina },
    @{ 'Clave' = 'Sistema Operativo'; 'Valor' = $SistemaOperativo },
    @{ 'Clave' = 'Version SO'; 'Valor' = $version },
    @{ 'Clave' = 'Modelo CPU'; 'Valor' = $procesador },
    @{ 'Clave' = 'Velocidad CPU'; 'Valor' = "$velocidad GHz"},
    @{ 'Clave' = 'Cores CPU'; 'Valor' = $nucleos },
    @{ 'Clave' = 'Memoria RAM total'; 'Valor' = "$ram GB"}
)

$sistemaHtml = "<div class='table-container'><h2>Especificaciones del sistema</h2><table></tr>"
foreach ($row in $infoSistema) {
    $sistemaHtml += "<tr><td><b>$($row.Clave)</b></td><td>$($row.Valor)</td></tr>"
}
$sistemaHtml += "</table></div>"

#Información de disco
$infoDiscos = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3"| Select-Object @{Label="Letra de unidad"; Expression={$_.DeviceID}},@{Label="Espacio libre"; Expression={"{0:n2} GB" -f ($_.FreeSpace/1GB)}},@{Label="Espacio Total"; Expression={"{0:n2} GB" -f ($_.Size/1GB)}}
$discosHtml = "<div class='table-container'><h2>Detalle espacio en disco</h2><table><tr><th>Letra de unidad</th><th>Espacio libre</th><th>Espacio Total</th></tr>" + (($infoDiscos | ForEach-Object { "<tr><td>$($_.'Letra de unidad')</td><td>$($_.'Espacio libre')</td><td>$($_.'Espacio Total')</td></tr>" }) -join "") + "</table></div>"

#Resumen de estado actual
$usoCPUactual= Get-CimInstance Win32_Processor | Select-Object -ExpandProperty LoadPercentage 

#UsoMemoriaReservada
$usoMemoriaReservadaMB = [math]::Round((Get-Process | Measure-Object PrivateMemorySize64 -Sum).Sum / 1MB, 2)
if ($usoMemoriaReservadaMB -gt 1024) {
    $usoMemoriaReservada = [math]::Round($usoMemoriaReservadaMB / 1024, 2)
    $usoMemoriaReservada = "$usoMemoriaReservada GB"
} else {
    $usoMemoriaReservada = "$usoMemoriaReservadaMB MB"
}

#UsoMemoriaTotal
$usoMemoriaActualMB = [math]::Round((Get-Process | Measure-Object WS -Sum).Sum / 1MB, 2)
if ($usoMemoriaActualMB -gt 1024) { 
	$usoMemoriaActual=[math]::Round($usoMemoriaActualMB / 1024, 2)
	$usoMemoriaActual= "$usoMemoriaActual GB"
} else {
	$usoMemoriaActual = "$usoMemoriaActualMB MB"
}

$infoResumen = @( 
	@{ 'Clave' = 'Uso de CPU actual'; 'Valor' = "$usoCPUactual %"},
    @{ 'Clave' = 'Uso de memoria por procesos actual:'; 'Valor' ="$usoMemoriaActual "},
	@{ 'Clave' = 'Suma de memoria reservada por procesos:'; 'Valor' ="$usoMemoriaReservada "}
)
$resumenHTML = "<div class='table-container'><h2>Resumen de estado actual</h2><table></tr>"
foreach ($row in $infoResumen) {
    $resumenHTML += "<tr><td><b>$($row.Clave)</b></td><td>$($row.Valor)</td></tr>"
}
$resumenHTML += "</table></div>"

#Información Top 20 procesos
$infoProcesos = Get-Process | Select-Object ProcessName, 
								@{Name="ProcessID"; Expression={$_.Id}},
								@{Name="Memoria RAM en uso (MB)"; Expression={"{0:N2}"-f ($_.WS / 1MB)}}, 
								@{Name="Memoria Reservada (MB)"; Expression={"{0:N2}" -f ($_.PrivateMemorySize64 / 1MB)}} | 
							Sort-Object {$_."Memoria RAM en uso (MB)" -as [decimal]} -Descending |
							ForEach-Object {
								$_."Memoria RAM en uso (MB)" = "$($_."Memoria RAM en uso (MB)") MB"
								$_
								} |
							Select-Object -First 20

$procesosHtml = "<div class='table-container'><h2>Top 20 Procesos activos</h2><table><tr><th>Proceso</th><th>ProcessId</th><th>Uso de memoria</th></tr>"
	foreach ($proceso in $infoProcesos) {
    	$procesosHtml += "<tr><td>$($proceso.ProcessName)</td><td>$($proceso.ProcessID)</td><td>$($proceso.'Memoria RAM en uso (MB)')</td></tr>"
	}
$procesosHtml += "</table></div>"

#CSS
$head = @"
	<title>Informe del equipo</title>
	<style>
		body {
			font-family: "Calibri", sans-serif;
			display: flex;
			flex-direction: column;
			justify-content: flex-start;
			align-items: center;
			padding: 10px;
			background: repeating-linear-gradient(135deg, #000000 0%, #00a3c0 45%, #0495af 100%);
		}
		.header {
			width: 100%;
			color: white;
			margin: 10px;
			text-align: center;
		}
		.footer {
			width: 99%;
			border-radius: 8px;
			overflow: hidden;
			margin-top: 10px;
			margin-bottom: 20px;
			text-align: center;
			background-color: #00000030;

		}
		.footer p {
			font-size: 14px;
			color: white;
			margin: 10px;
		}
		.content {
			display: flex;
			flex-wrap: wrap;
			justify-content: space-evenly;
			align-items: stretch;
			width: 100%;
			margin-bottom: 10px;
		}
		.content-row {
			display: flex;
			justify-content: space-between;
			flex-wrap: wrap;
		}
		.table-container {
			box-shadow: 0px 0px 10px 0px rgba(0,0,0,0.6);
			border-radius: 10px;
			overflow: hidden;
			background-color: #fff;
			flex: 1 0 45%;
			margin: 10px;
		}
		h2 {
			background-color: #086184;
			color: #ffffff;
			margin: 0;
			padding: 10px;
			text-align: center;
		}
		table {
			width: 100%;
			border-collapse: collapse;
		}
		td, th {
			border: 0px solid #ddd;
			padding: 8px;
			text-align: center;
		}
		tr:nth-child(even) {
			background-color: #f2f2f2;
		}
		tr:hover {
			background-color: #477686;
			color: white;
			transition: all 0.2s;
		}
		/* Click en celda, aplicar color a fila */
		tr.clicked {
			background-color: #477686;
			color: white;
		}
		/* Cambio de flex para responsive */
		@media (max-width: 800px) {
			body {
				flex-direction: column;
			}
			.table-container {
				flex: 1 0 100%;
			}
		}
	</style>
	<script>
		document.addEventListener('DOMContentLoaded', (event) => {
			document.querySelectorAll('td').forEach(cell => {
				cell.addEventListener('click', (event) => {
					event.target.parentNode.classList.toggle('clicked');
				});
			});
		});
	</script>
"@

#Escribir informe
Set-Content -Encoding utf8 -Path $DirectorioInforme -Value ("
<html>
<head>$head</head>
<body>
	$EncabezadoHtml
	<div class='content'>
		$resumenHTML
	</div>
	<div class='content'>
		$sistemaHtml
		$discosHtml
	</div>
	<div class='content'>
		$procesosHtml
	</div>
	$FooterHTML
</body>
</html>")
Start-Process $DirectorioInforme