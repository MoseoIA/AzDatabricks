<#
.SYNOPSIS
    Este script se conecta a Microsoft Graph para encontrar todos los usuarios
    que no tienen un método de autenticación multifactor (MFA) registrado.
    Está diseñado para ejecutarse directamente en Azure Cloud Shell.
.DESCRIPTION
    El script utiliza el cmdlet Get-MgReportAuthenticationMethodUserRegistrationDetail
    con un filtro para obtener solo los usuarios donde 'isMfaRegistered' es 'false'.
    Luego, muestra los resultados en una tabla y opcionalmente los puede exportar a un archivo CSV.
.NOTES
    Autor: Gemini
    Versión: 1.0
    Requisitos: Ejecutar en una sesión de Azure Cloud Shell.
#>

# Mensaje de inicio
Write-Host "Iniciando la búsqueda de usuarios sin registro de MFA..." -ForegroundColor Yellow

# Conectarse a Microsoft Graph. En Cloud Shell, esto usará tu sesión existente.
# Se solicitarán los permisos necesarios la primera vez que se ejecute.
Connect-MgGraph -Scopes "UserAuthenticationMethod.Read.All"

Write-Host "Permisos verificados. Obteniendo la lista de usuarios..." -ForegroundColor Green

try {
    # El parámetro -All asegura que se obtengan todos los resultados, manejando la paginación automáticamente.
    $usersWithoutMfa = Get-MgReportAuthenticationMethodUserRegistrationDetail -Filter "isMfaRegistered eq false" -All -ErrorAction Stop

    if ($null -ne $usersWithoutMfa) {
        Write-Host "Se encontraron los siguientes usuarios sin MFA registrado:" -ForegroundColor Cyan
        
        # Mostrar los resultados en un formato de tabla fácil de leer
        $usersWithoutMfa | Select-Object UserPrincipalName, UserDisplayName, IsMfaRegistered | Format-Table

        # Opcional: Exportar a un archivo CSV en el directorio home de Cloud Shell
        # Para ejecutar esta línea, simplemente quita el símbolo '#' al principio.
        # $usersWithoutMfa | Select-Object UserPrincipalName, UserDisplayName, IsMfaRegistered | Export-Csv -Path "~/UsuariosSinMFA.csv" -NoTypeInformation
        # Write-Host "Reporte exportado a '~/UsuariosSinMFA.csv'. Puedes descargarlo desde el explorador de archivos de Cloud Shell." -ForegroundColor Green

    } else {
        Write-Host "¡Felicidades! Todos los usuarios en el tenant tienen al menos un método de MFA registrado." -ForegroundColor Green
    }
}
catch {
    Write-Host "Ocurrió un error al ejecutar la consulta:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

# Desconectarse de la sesión de Graph (buena práctica)
# Disconnect-MgGraph
