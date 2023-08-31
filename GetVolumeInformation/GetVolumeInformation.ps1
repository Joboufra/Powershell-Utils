#Este script usa el mismo método que Metricbeat para obtener los datos del modulo System referentes a unidades de disco

$pinvokes = @'
[DllImport("Kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
[return: MarshalAs(UnmanagedType.Bool)]
public extern static bool GetVolumeInformationW(
  string rootPathName,
  [Out] System.Text.StringBuilder volumeNameBuffer,
  int volumeNameSize,
  out uint volumeSerialNumber,
  out uint maximumComponentLength,
  out uint fileSystemFlags,
  [Out] System.Text.StringBuilder fileSystemNameBuffer,
  int nFileSystemNameSize);
[DllImport("Kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
public static extern uint GetLogicalDriveStringsW(uint nBufferLength, [Out] char[] lpBuffer);
'@

Write-Host "======================================================================"
Write-Host "=============            GetVolumeInformation            ============="
Write-Host "======================================================================"
Write-Host ""
$Kernel32 = Add-Type -MemberDefinition $pinvokes -Name 'Kernel32' -Namespace 'Win32' -PassThru
$datosUnidades = [char[]]::new(512)
$Kernel32::GetLogicalDriveStringsW($datosUnidades.length, $datosUnidades) | Out-Null
$unidad = -join $datosUnidades
$datosUnidades = $unidad.Split("`0", [System.StringSplitOptions]::RemoveEmptyEntries)
Write-Host "Unidades encontradas por GetLogicalDriveStringsW: $datosUnidades."

$resultado = @()
$datosUnidades | ForEach-Object {
  $datosVolumenBuffer = New-Object -TypeName "System.Text.StringBuilder" -ArgumentList 255
  $datosFilesystem = New-Object -TypeName "System.Text.StringBuilder" -ArgumentList 255
  $res = $Kernel32::GetVolumeInformationW($_, $datosVolumenBuffer, 255, [ref]0, [ref]0, [ref]0, $datosFilesystem, 255)

  #Objeto con los resultados
  $ObjResultado = New-Object PSObject -Property @{
    'Drive' = $_
    'VolumeName' = $datosVolumenBuffer.ToString()
    'FileSystem' = $datosFilesystem.ToString()
    'Result' = $res
  }
  $resultado += $objResultado
}
$resultado | Format-Table -Property @{Name='Unidad'; Expression={$_.Drive}}, 
                                     @{Name='Nombre de Unidad'; Expression={$_.VolumeName}}, 
                                     @{Name='Sistema de Archivos'; Expression={$_.FileSystem}}, 
                                     @{Name='Resultado'; Expression={$_.Result}}