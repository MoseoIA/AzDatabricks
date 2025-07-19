param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("ResourceGroups", "Resources", "Both")]
    [string]$AuditType,
    
    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId = $null,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = $null,
    
    [Parameter(Mandatory = $false)]
    [switch]$ExportToCSV
)

# Función para verificar si está conectado a Azure
function Test-AzureConnection {
    try {
        $context = Get-AzContext
        if ($null -eq $context) {
            Write-Host "No hay una sesión activa de Azure. Por favor, ejecute Connect-AzAccount primero." -ForegroundColor Red
            return $false
        }
        return $true
    }
    catch {
        Write-Host "Error al verificar la conexión de Azure: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Función para obtener grupos de recursos sin tags
function Get-ResourceGroupsWithoutTags {
    param(
        [string]$SubscriptionId
    )
    
    Write-Host "Obteniendo grupos de recursos sin tags..." -ForegroundColor Yellow
    
    try {
        if ($SubscriptionId) {
            $resourceGroups = Get-AzResourceGroup -DefaultProfile (Get-AzContext) | Where-Object { $_.ResourceGroupName -and $_.SubscriptionId -eq $SubscriptionId }
        } else {
            $resourceGroups = Get-AzResourceGroup
        }
        
        $resourceGroupsWithoutTags = @()
        
        foreach ($rg in $resourceGroups) {
            if ($null -eq $rg.Tags -or $rg.Tags.Count -eq 0) {
                $resourceGroupsWithoutTags += [PSCustomObject]@{
                    ResourceGroupName = $rg.ResourceGroupName
                    Location = $rg.Location
                    SubscriptionId = $rg.ResourceId.Split('/')[2]
                    ResourceType = "ResourceGroup"
                    Tags = "No Tags"
                    ResourceId = $rg.ResourceId
                }
            }
        }
        
        return $resourceGroupsWithoutTags
    }
    catch {
        Write-Host "Error al obtener grupos de recursos: $($_.Exception.Message)" -ForegroundColor Red
        return @()
    }
}

# Función para obtener recursos sin tags
function Get-ResourcesWithoutTags {
    param(
        [string]$SubscriptionId
    )
    
    Write-Host "Obteniendo recursos sin tags..." -ForegroundColor Yellow
    
    try {
        if ($SubscriptionId) {
            Set-AzContext -SubscriptionId $SubscriptionId
            $resources = Get-AzResource
        } else {
            $resources = Get-AzResource
        }
        
        $resourcesWithoutTags = @()
        
        foreach ($resource in $resources) {
            if ($null -eq $resource.Tags -or $resource.Tags.Count -eq 0) {
                $resourcesWithoutTags += [PSCustomObject]@{
                    ResourceName = $resource.Name
                    ResourceType = $resource.ResourceType
                    ResourceGroupName = $resource.ResourceGroupName
                    Location = $resource.Location
                    SubscriptionId = $resource.ResourceId.Split('/')[2]
                    Tags = "No Tags"
                    ResourceId = $resource.ResourceId
                }
            }
        }
        
        return $resourcesWithoutTags
    }
    catch {
        Write-Host "Error al obtener recursos: $($_.Exception.Message)" -ForegroundColor Red
        return @()
    }
}

# Función para exportar resultados a CSV - MEJORADA
function Export-ResultsToCSV {
    param(
        [array]$Results,
        [string]$OutputPath,
        [string]$AuditType
    )
    
    if ($null -eq $Results -or $Results.Count -eq 0) {
        Write-Host "No hay resultados para exportar." -ForegroundColor Yellow
        return
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    
    if ([string]::IsNullOrEmpty($OutputPath)) {
        $OutputPath = ".\Azure_Tags_Audit_${AuditType}_${timestamp}.csv"
    }
    
    # Verificar que el directorio de destino existe
    $directory = Split-Path -Path $OutputPath -Parent
    if ($directory -and -not (Test-Path $directory)) {
        try {
            New-Item -ItemType Directory -Path $directory -Force | Out-Null
            Write-Host "Directorio creado: $directory" -ForegroundColor Yellow
        }
        catch {
            Write-Host "Error al crear directorio: $($_.Exception.Message)" -ForegroundColor Red
            return
        }
    }
    
    try {
        Write-Host "Exportando $($Results.Count) resultados..." -ForegroundColor Yellow
        $Results | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
        Write-Host "✅ Resultados exportados exitosamente a: $OutputPath" -ForegroundColor Green
        
        # Verificar que el archivo se creó correctamente
        if (Test-Path $OutputPath) {
            $fileInfo = Get-Item $OutputPath
            Write-Host "Tamaño del archivo: $($fileInfo.Length) bytes" -ForegroundColor Cyan
        } else {
            Write-Host "⚠️  Advertencia: No se pudo verificar la creación del archivo" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "❌ Error al exportar resultados: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Ruta intentada: $OutputPath" -ForegroundColor Gray
    }
}

# Función para mostrar resultados en consola
function Show-Results {
    param(
        [array]$Results,
        [string]$Type
    )
    
    if ($null -eq $Results -or $Results.Count -eq 0) {
        Write-Host "✅ No se encontraron $Type sin tags." -ForegroundColor Green
        return
    }
    
    Write-Host "`n⚠️  Se encontraron $($Results.Count) $Type sin tags:" -ForegroundColor Yellow
    Write-Host "=" * 80 -ForegroundColor Cyan
    
    foreach ($item in $Results) {
        Write-Host "Nombre: $($item.ResourceName -or $item.ResourceGroupName)" -ForegroundColor White
        Write-Host "Tipo: $($item.ResourceType)" -ForegroundColor Gray
        Write-Host "Grupo de Recursos: $($item.ResourceGroupName)" -ForegroundColor Gray
        Write-Host "Ubicación: $($item.Location)" -ForegroundColor Gray
        Write-Host "Suscripción: $($item.SubscriptionId)" -ForegroundColor Gray
        Write-Host "Resource ID: $($item.ResourceId)" -ForegroundColor DarkGray
        Write-Host "-" * 80 -ForegroundColor DarkGray
    }
}

# Script principal
Write-Host "🚀 Iniciando auditoría de tags en Azure..." -ForegroundColor Cyan
Write-Host "Tipo de auditoría: $AuditType" -ForegroundColor Cyan

# Verificar conexión a Azure
if (-not (Test-AzureConnection)) {
    exit 1
}

# Mostrar contexto actual
$currentContext = Get-AzContext
Write-Host "Contexto actual:" -ForegroundColor Cyan
Write-Host "  Suscripción: $($currentContext.Subscription.Name) ($($currentContext.Subscription.Id))" -ForegroundColor White
Write-Host "  Cuenta: $($currentContext.Account.Id)" -ForegroundColor White

$allResults = @()

# Ejecutar auditoría según el tipo especificado
switch ($AuditType) {
    "ResourceGroups" {
        $results = Get-ResourceGroupsWithoutTags -SubscriptionId $SubscriptionId
        Show-Results -Results $results -Type "grupos de recursos"
        $allResults += $results
    }
    
    "Resources" {
        $results = Get-ResourcesWithoutTags -SubscriptionId $SubscriptionId
        Show-Results -Results $results -Type "recursos"
        $allResults += $results
    }
    
    "Both" {
        Write-Host "`n📋 Auditando grupos de recursos..." -ForegroundColor Cyan
        $rgResults = Get-ResourceGroupsWithoutTags -SubscriptionId $SubscriptionId
        Show-Results -Results $rgResults -Type "grupos de recursos"
        
        Write-Host "`n📋 Auditando recursos..." -ForegroundColor Cyan
        $resourceResults = Get-ResourcesWithoutTags -SubscriptionId $SubscriptionId
        Show-Results -Results $resourceResults -Type "recursos"
        
        if ($rgResults) { $allResults += $rgResults }
        if ($resourceResults) { $allResults += $resourceResults }
    }
}

# Exportar resultados si se solicita
if ($ExportToCSV) {
    Write-Host "`n📤 Iniciando exportación a CSV..." -ForegroundColor Cyan
    Export-ResultsToCSV -Results $allResults -OutputPath $OutputPath -AuditType $AuditType
}

# Resumen final
Write-Host "`n📊 Resumen de auditoría:" -ForegroundColor Cyan
Write-Host "Total de elementos sin tags encontrados: $($allResults.Count)" -ForegroundColor $(if ($allResults.Count -gt 0) { "Yellow" } else { "Green" })

if ($allResults.Count -gt 0) {
    Write-Host "`n💡 Próximos pasos recomendados:" -ForegroundColor Cyan
    Write-Host "1. Revisar los elementos listados arriba" -ForegroundColor White
    Write-Host "2. Definir tags obligatorios para tu organización" -ForegroundColor White
    Write-Host "3. Implementar políticas de Azure Policy para tags obligatorios" -ForegroundColor White
    Write-Host "4. Usar scripts de remediación para aplicar tags masivamente" -ForegroundColor White
}

Write-Host "`n✅ Auditoría completada." -ForegroundColor Green