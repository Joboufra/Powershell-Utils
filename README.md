# Powershell Utils 
En este repositorio guardo scripts creados en Powershell los cuales considero útiles. Esta es la lista de scripts disponibles:

### GetVolumeInformation
* Uso de GetLogicalDriveStringsW para obtener datos de unidades del sistema. (Mismo método que usa Metricbeat para recuperar la info, útil para revisar dichos valores)

### backupAlert
* Genera una alerta a través del envio de un email si no se realizan backups en el umbral de días establecido y, en caso de que ese umbral se supere, realiza un backup

### freeSpaceAlert
* Genera una alerta a través del envio de un email si el espacio en disco es inferior al umbral establecido

### InformeSistema
* Genera un informe en HTML del estado de un servidor.

### ObtenerConnectionStrings
* Util para recuperar de un ConnectionString los valores en variables separadas. Se puede llevar fácilmente a función.

### MonitorPing
* Monitor pensado para su ejecución en background que nos genera un csv indicando los tiempos de respuesta a través del comando ping o, en su defecto, los errores de conexión que ocurran. Configurable a través de archivo de config.

### MonitorProcesos
* Monitor pensado para monitorizar el consumo de memoria de procesos concretos. Se opera a través de consola y te indica el Top 20 de procesos por uso de memoria de mayor a menor. Tiene funciones de filtro para la búsqueda de un proceso concreto, o aumento o disminución del tiempo de obtención del dato.
