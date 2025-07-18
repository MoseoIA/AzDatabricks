param(
    [Parameter(Mandatory = $true)]
    [string]$MandatoryTags,
    
    [Parameter(Mandatory = $true)]
    [ValidateSet("ResourceGroups", "Resources", "Both")]
    [string]$AuditType,
    
    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId = $null,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = $null,
    
    [Parameter(Mandatory = $false)]
    [switch]$ExportToCSV,
    
    [Parameter(Mandatory = $false)]
    [switch]$ValidateValues,
    
    [Parameter(Mandatory = $false)]
    [switch]$OnlyMissingTags
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

# Función para parsear los tags mandatorios
function Parse-MandatoryTags {
    param(
        [string]$MandatoryTagsString
    )
    
    $mandatoryTagsHash = @{}
    
    try {
        $tagPairs = $MandatoryTagsString -split ','
        
        foreach ($tagPair in $tagPairs) {
            $tagPair = $tagPair.Trim()
            if ($tagPair -match '^(.+?)=(.+)$') {
                $tagName = $matches[1].Trim()
                $tagValue = $matches[2].Trim()
                $mandatoryTagsHash[$tagName] = $tagValue
            }
            else {
                Write-Host "⚠️  Formato incorrecto en tag: '$tagPair'. Use formato: tagName=tagValue" -ForegroundColor Yellow
            }
        }
        
        return $mandatoryTagsHash
    }
    catch {
        Write-Host "Error al parsear tags mandatorios: $($_.Exception.Message)" -ForegroundColor Red
        return @{}
    }
}

# Función para validar tags de un recurso
function Test-ResourceTags {
    param(
        [hashtable]$ResourceTags,
        [hashtable]$MandatoryTags,
        [bool]$ValidateValues
    )
    
    $missingTags = @()
    $incorrectValues = @()
    
    foreach ($mandatoryTag in $MandatoryTags.Keys) {
        if ($null -eq $ResourceTags -or -not $ResourceTags.ContainsKey($mandatoryTag)) {
            $missingTags += $mandatoryTag
        }
        elseif ($ValidateValues -and $ResourceTags[$mandatoryTag] -ne $MandatoryTags[$mandatoryTag]) {
            $incorrectValues += [PSCustomObject]@{
                TagName = $mandatoryTag
                ExpectedValue = $MandatoryTags[$mandatoryTag]
                ActualValue = $ResourceTags[$mandatoryTag]
            }
        }
    }
    
    return [PSCustomObject]@{
        MissingTags = $missingTags
        IncorrectValues = $incorrectValues
        IsCompliant = ($missingTags.Count -eq 0 -and $incorrectValues.Count -eq 0)
    }
}

# Función para obtener grupos de recursos no conformes
function Get-NonCompliantResourceGroups {
    param(
        [string]$SubscriptionId,
        [hashtable]$MandatoryTags,
        [bool]$ValidateValues,
        [bool]$OnlyMissingTags
    )
    
    Write-Host "Validando grupos de recursos..." -ForegroundColor Yellow
    
    try {
        if ($SubscriptionId) {
            $resourceGroups = Get-AzResourceGroup -DefaultProfile (Get-AzContext) | Where-Object { $_.ResourceGroupName -and $_.SubscriptionId -eq $SubscriptionId }
        } else {
            $resourceGroups = Get-AzResourceGroup
        }
        
        $nonCompliantResourceGroups = @()
        $compliantCount = 0
        
        foreach ($rg in $resourceGroups) {
            $tagValidation = Test-ResourceTags -ResourceTags $rg.Tags -MandatoryTags $MandatoryTags -ValidateValues $ValidateValues
            
            if (-not $tagValidation.IsCompliant) {
                if ($OnlyMissingTags -and $tagValidation.MissingTags.Count -eq 0) {
                    continue
                }
                
                $currentTags = if ($rg.Tags) { 
                    ($rg.Tags.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join "; " 
                } else { 
                    "No Tags" 
                }
                
                $missingTagsStr = if ($tagValidation.MissingTags.Count -gt 0) { 
                    $tagValidation.MissingTags -join ", " 
                } else { 
                    "None" 
                }
                
                $incorrectValuesStr = if ($tagValidation.IncorrectValues.Count -gt 0) { 
                    ($tagValidation.IncorrectValues | ForEach-Object { "$($_.TagName): Expected='$($_.ExpectedValue)', Actual='$($_.ActualValue)'" }) -join "; " 
                } else { 
                    "None" 
                }
                
                $nonCompliantResourceGroups += [PSCustomObject]@{
                    ResourceGroupName = $rg.ResourceGroupName
                    ResourceType = "ResourceGroup"
                    Location = $rg.Location
                    SubscriptionId = $rg.ResourceId.Split('/')[2]
                    CurrentTags = $currentTags
                    MissingTags = $missingTagsStr
                    IncorrectValues = $incorrectValuesStr
                    ResourceId = $rg.ResourceId
                    ComplianceStatus = "Non-Compliant"
                }
            } else {
                $compliantCount++
            }
        }
        
        Write-Host "✅ Grupos de recursos conformes: $compliantCount" -ForegroundColor Green
        Write-Host "⚠️  Grupos de recursos no conformes: $($nonCompliantResourceGroups.Count)" -ForegroundColor Yellow
        
        return $nonCompliantResourceGroups
    }
    catch {
        Write-Host "Error al validar grupos de recursos: $($_.Exception.Message)" -ForegroundColor Red
        return @()
    }
}

# Función para obtener recursos no conformes
function Get-NonCompliantResources {
    param(
        [string]$SubscriptionId,
        [hashtable]$MandatoryTags,
        [bool]$ValidateValues,
        [bool]$OnlyMissingTags
    )
    
    Write-Host "Validando recursos..." -ForegroundColor Yellow
    
    try {
        if ($SubscriptionId) {
            Set-AzContext -SubscriptionId $SubscriptionId
            $resources = Get-AzResource
        } else {
            $resources = Get-AzResource
        }
        
        $nonCompliantResources = @()
        $compliantCount = 0
        $processedCount = 0
        
        foreach ($resource in $resources) {
            $processedCount++
            
            # Mostrar progreso cada 100 recursos
            if ($processedCount % 100 -eq 0) {
                Write-Progress -Activity "Validando recursos" -Status "Procesados: $processedCount de $($resources.Count)" -PercentComplete (($processedCount / $resources.Count) * 100)
            }
            
            $tagValidation = Test-ResourceTags -ResourceTags $resource.Tags -MandatoryTags $MandatoryTags -ValidateValues $ValidateValues
            
            if (-not $tagValidation.IsCompliant) {
                if ($OnlyMissingTags -and $tagValidation.MissingTags.Count -eq 0) {
                    continue
                }
                
                $currentTags = if ($resource.Tags) { 
                    ($resource.Tags.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join "; " 
                } else { 
                    "No Tags" 
                }
                
                $missingTagsStr = if ($tagValidation.MissingTags.Count -gt 0) { 
                    $tagValidation.MissingTags -join ", " 
                } else { 
                    "None" 
                }
                
                $incorrectValuesStr = if ($tagValidation.IncorrectValues.Count -gt 0) { 
                    ($tagValidation.IncorrectValues | ForEach-Object { "$($_.TagName): Expected='$($_.ExpectedValue)', Actual='$($_.ActualValue)'" }) -join "; " 
                } else { 
                    "None" 
                }
                
                $nonCompliantResources += [PSCustomObject]@{
                    ResourceName = $resource.Name
                    ResourceType = $resource.ResourceType
                    ResourceGroupName = $resource.ResourceGroupName
                    Location = $resource.Location
                    SubscriptionId = $resource.ResourceId.Split('/')[2]
                    CurrentTags = $currentTags
                    MissingTags = $missingTagsStr
                    IncorrectValues = $incorrectValuesStr
                    ResourceId = $resource.ResourceId
                    ComplianceStatus = "Non-Compliant"
                }
            } else {
                $compliantCount++
            }
        }
        
        Write-Progress -Activity "Validando recursos" -Completed
        
        Write-Host "✅ Recursos conformes: $compliantCount" -ForegroundColor Green
        Write-Host "⚠️  Recursos no conformes: $($nonCompliantResources.Count)" -ForegroundColor Yellow
        
        return $nonCompliantResources
    }
    catch {
        Write-Host "Error al validar recursos: $($_.Exception.Message)" -ForegroundColor Red
        return @()
    }
}

# Función para exportar resultados a CSV
function Export-ResultsToCSV {
    param(
        [array]$Results,
        [string]$OutputPath,
        [string]$AuditType
    )
    
    if ($Results.Count -eq 0) {
        Write-Host "No hay resultados para exportar." -ForegroundColor Yellow
        return
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    
    if ([string]::IsNullOrEmpty($OutputPath)) {
        $OutputPath = ".\Azure_MandatoryTags_Validation_${AuditType}_${timestamp}.csv"
    }
    
    try {
        $Results | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
        Write-Host "Resultados exportados a: $OutputPath" -ForegroundColor Green
    }
    catch {
        Write-Host "Error al exportar resultados: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Función para mostrar resultados en consola
function Show-Results {
    param(
        [array]$Results,
        [string]$Type
    )
    
    if ($Results.Count -eq 0) {
        Write-Host "✅ Todos los $Type cumplen con los tags mandatorios." -ForegroundColor Green
        return
    }
    
    Write-Host "`n⚠️  $Type no conformes encontrados: $($Results.Count)" -ForegroundColor Yellow
    Write-Host "=" * 120 -ForegroundColor Cyan
    
    foreach ($item in $Results) {
        Write-Host "Nombre: $($item.ResourceName -or $item.ResourceGroupName)" -ForegroundColor White
        Write-Host "Tipo: $($item.ResourceType)" -ForegroundColor Gray
        if ($item.ResourceGroupName) {
            Write-Host "Grupo de Recursos: $($item.ResourceGroupName)" -ForegroundColor Gray
        }
        Write-Host "Ubicación: $($item.Location)" -ForegroundColor Gray
        Write-Host "Tags Actuales: $($item.CurrentTags)" -ForegroundColor DarkYellow
        Write-Host "Tags Faltantes: $($item.MissingTags)" -ForegroundColor Red
        Write-Host "Valores Incorrectos: $($item.IncorrectValues)" -ForegroundColor Magenta
        Write-Host "Resource ID: $($item.ResourceId)" -ForegroundColor DarkGray
        Write-Host "-" * 120 -ForegroundColor DarkGray
    }
}

# Script principal
Write-Host "🚀 Iniciando validación de tags mandatorios en Azure..." -ForegroundColor Cyan
Write-Host "Tipo de auditoría: $AuditType" -ForegroundColor Cyan

# Verificar conexión a Azure
if (-not (Test-AzureConnection)) {
    exit 1
}

# Parsear tags mandatorios
$mandatoryTagsHash = Parse-MandatoryTags -MandatoryTagsString $MandatoryTags

if ($mandatoryTagsHash.Count -eq 0) {
    Write-Host "❌ No se pudieron parsear los tags mandatorios. Verifique el formato." -ForegroundColor Red
    exit 1
}

# Mostrar tags mandatorios
Write-Host "`n📋 Tags mandatorios configurados:" -ForegroundColor Cyan
foreach ($tag in $mandatoryTagsHash.GetEnumerator()) {
    $validationMode = if ($ValidateValues) { "Valor requerido: $($tag.Value)" } else { "Solo presencia requerida" }
    Write-Host "  • $($tag.Key): $validationMode" -ForegroundColor White
}

# Mostrar contexto actual
$currentContext = Get-AzContext
Write-Host "`nContexto actual:" -ForegroundColor Cyan
Write-Host "  Suscripción: $($currentContext.Subscription.Name) ($($currentContext.Subscription.Id))" -ForegroundColor White
Write-Host "  Cuenta: $($currentContext.Account.Id)" -ForegroundColor White

$allResults = @()

# Ejecutar validación según el tipo especificado
switch ($AuditType) {
    "ResourceGroups" {
        $results = Get-NonCompliantResourceGroups -SubscriptionId $SubscriptionId -MandatoryTags $mandatoryTagsHash -ValidateValues $ValidateValues -OnlyMissingTags $OnlyMissingTags
        Show-Results -Results $results -Type "grupos de recursos"
        $allResults += $results
    }
    
    "Resources" {
        $results = Get-NonCompliantResources -SubscriptionId $SubscriptionId -MandatoryTags $mandatoryTagsHash -ValidateValues $ValidateValues -OnlyMissingTags $OnlyMissingTags
        Show-Results -Results $results -Type "recursos"
        $allResults += $results
    }
    
    "Both" {
        Write-Host "`n📋 Validando grupos de recursos..." -ForegroundColor Cyan
        $rgResults = Get-NonCompliantResourceGroups -SubscriptionId $SubscriptionId -MandatoryTags $mandatoryTagsHash -ValidateValues $ValidateValues -OnlyMissingTags $OnlyMissingTags
        Show-Results -Results $rgResults -Type "grupos de recursos"
        
        Write-Host "`n📋 Validando recursos..." -ForegroundColor Cyan
        $resourceResults = Get-NonCompliantResources -SubscriptionId $SubscriptionId -MandatoryTags $mandatoryTagsHash -ValidateValues $ValidateValues -OnlyMissingTags $OnlyMissingTags
        Show-Results -Results $resourceResults -Type "recursos"
        
        $allResults += $rgResults
        $allResults += $resourceResults
    }
}

# Exportar resultados si se solicita
if ($ExportToCSV) {
    Export-ResultsToCSV -Results $allResults -OutputPath $OutputPath -AuditType $AuditType
}

# Resumen final
Write-Host "`n📊 Resumen de validación:" -ForegroundColor Cyan
Write-Host "Total de elementos no conformes: $($allResults.Count)" -ForegroundColor $(if ($allResults.Count -gt 0) { "Yellow" } else { "Green" })

if ($allResults.Count -gt 0) {
    # Estadísticas adicionales
    $resourcesWithMissingTags = $allResults | Where-Object { $_.MissingTags -ne "None" }
    $resourcesWithIncorrectValues = $allResults | Where-Object { $_.IncorrectValues -ne "None" }
    
    Write-Host "  • Elementos con tags faltantes: $($resourcesWithMissingTags.Count)" -ForegroundColor Yellow
    Write-Host "  • Elementos con valores incorrectos: $($resourcesWithIncorrectValues.Count)" -ForegroundColor Yellow
    
    Write-Host "`n💡 Próximos pasos recomendados:" -ForegroundColor Cyan
    Write-Host "1. Aplicar tags faltantes usando scripts de remediación" -ForegroundColor White
    Write-Host "2. Corregir valores incorrectos de tags" -ForegroundColor White
    Write-Host "3. Implementar Azure Policy para enforçar tags mandatorios" -ForegroundColor White
    Write-Host "4. Configurar alertas para detectar recursos no conformes" -ForegroundColor White
}

Write-Host "`n✅ Validación completada." -ForegroundColor Green