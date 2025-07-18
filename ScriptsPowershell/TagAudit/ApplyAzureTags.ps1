param(
    [Parameter(Mandatory = $true)]
    [string]$TagsToApply,
    
    [Parameter(Mandatory = $true)]
    [ValidateSet("ResourceGroups", "Resources", "Both")]
    [string]$ApplyTo,
    
    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId = $null,
    
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupFilter = $null,
    
    [Parameter(Mandatory = $false)]
    [string]$ResourceTypeFilter = $null,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Add", "Replace", "Merge")]
    [string]$TagAction = "Merge",
    
    [Parameter(Mandatory = $false)]
    [switch]$WhatIf,
    
    [Parameter(Mandatory = $false)]
    [switch]$IncludeResourcesInGroups,
    
    [Parameter(Mandatory = $false)]
    [string]$InputCSV = $null,
    
    [Parameter(Mandatory = $false)]
    [string]$LogPath = $null,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force,
    
    [Parameter(Mandatory = $false)]
    [int]$BatchSize = 50
)

# Variables globales
$script:LogFile = $null
$script:OperationResults = @()

# Función para inicializar logging
function Initialize-Logging {
    param(
        [string]$LogPath
    )
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    
    if ([string]::IsNullOrEmpty($LogPath)) {
        $script:LogFile = ".\Azure_Tags_Remediation_${timestamp}.log"
    } else {
        $script:LogFile = $LogPath
    }
    
    $logHeader = @"
===================================================
Azure Tags Remediation Script - $timestamp
===================================================
Parameters:
- TagsToApply: $TagsToApply
- ApplyTo: $ApplyTo
- TagAction: $TagAction
- WhatIf: $WhatIf
- IncludeResourcesInGroups: $IncludeResourcesInGroups
- BatchSize: $BatchSize
===================================================

"@
    
    Add-Content -Path $script:LogFile -Value $logHeader
    Write-Host "📝 Log file creado: $script:LogFile" -ForegroundColor Green
}

# Función para escribir en log
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    Add-Content -Path $script:LogFile -Value $logEntry
    
    switch ($Level) {
        "ERROR" { Write-Host $Message -ForegroundColor Red }
        "WARNING" { Write-Host $Message -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $Message -ForegroundColor Green }
        default { Write-Host $Message -ForegroundColor White }
    }
}

# Función para verificar si está conectado a Azure
function Test-AzureConnection {
    try {
        $context = Get-AzContext
        if ($null -eq $context) {
            Write-Log "No hay una sesión activa de Azure. Por favor, ejecute Connect-AzAccount primero." "ERROR"
            return $false
        }
        return $true
    }
    catch {
        Write-Log "Error al verificar la conexión de Azure: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Función para parsear tags a aplicar
function Parse-TagsToApply {
    param(
        [string]$TagsString
    )
    
    $tagsHash = @{}
    
    try {
        $tagPairs = $TagsString -split ','
        
        foreach ($tagPair in $tagPairs) {
            $tagPair = $tagPair.Trim()
            if ($tagPair -match '^(.+?)=(.+)$') {
                $tagName = $matches[1].Trim()
                $tagValue = $matches[2].Trim()
                $tagsHash[$tagName] = $tagValue
            }
            else {
                Write-Log "Formato incorrecto en tag: '$tagPair'. Use formato: tagName=tagValue" "WARNING"
            }
        }
        
        return $tagsHash
    }
    catch {
        Write-Log "Error al parsear tags: $($_.Exception.Message)" "ERROR"
        return @{}
    }
}

# Función para leer recursos desde CSV
function Read-ResourcesFromCSV {
    param(
        [string]$CSVPath
    )
    
    try {
        if (-not (Test-Path $CSVPath)) {
            Write-Log "Archivo CSV no encontrado: $CSVPath" "ERROR"
            return @()
        }
        
        $csvData = Import-Csv -Path $CSVPath
        Write-Log "Leídos $($csvData.Count) elementos desde CSV: $CSVPath" "INFO"
        
        return $csvData
    }
    catch {
        Write-Log "Error al leer CSV: $($_.Exception.Message)" "ERROR"
        return @()
    }
}

# Función para merge de tags
function Merge-Tags {
    param(
        [hashtable]$ExistingTags,
        [hashtable]$NewTags,
        [string]$Action
    )
    
    $resultTags = @{}
    
    switch ($Action) {
        "Replace" {
            # Reemplazar completamente con los nuevos tags
            $resultTags = $NewTags.Clone()
        }
        
        "Add" {
            # Agregar solo tags que no existen
            if ($ExistingTags) {
                $resultTags = $ExistingTags.Clone()
            }
            foreach ($tag in $NewTags.GetEnumerator()) {
                if (-not $resultTags.ContainsKey($tag.Key)) {
                    $resultTags[$tag.Key] = $tag.Value
                }
            }
        }
        
        "Merge" {
            # Merge: mantener existentes y agregar/sobrescribir nuevos
            if ($ExistingTags) {
                $resultTags = $ExistingTags.Clone()
            }
            foreach ($tag in $NewTags.GetEnumerator()) {
                $resultTags[$tag.Key] = $tag.Value
            }
        }
    }
    
    return $resultTags
}

# Función para aplicar tags a grupo de recursos
function Set-ResourceGroupTags {
    param(
        [string]$ResourceGroupName,
        [hashtable]$TagsToApply,
        [string]$TagAction,
        [bool]$WhatIfMode
    )
    
    try {
        $rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction Stop
        
        $currentTags = if ($rg.Tags) { $rg.Tags } else { @{} }
        $newTags = Merge-Tags -ExistingTags $currentTags -NewTags $TagsToApply -Action $TagAction
        
        $currentTagsStr = if ($currentTags.Count -gt 0) { 
            ($currentTags.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join "; " 
        } else { 
            "No Tags" 
        }
        
        $newTagsStr = ($newTags.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join "; "
        
        if ($WhatIfMode) {
            Write-Log "WHAT-IF: Aplicaría tags al grupo de recursos '$ResourceGroupName'" "INFO"
            Write-Log "  Tags actuales: $currentTagsStr" "INFO"
            Write-Log "  Tags nuevos: $newTagsStr" "INFO"
            
            $script:OperationResults += [PSCustomObject]@{
                ResourceType = "ResourceGroup"
                ResourceName = $ResourceGroupName
                ResourceGroupName = $ResourceGroupName
                Operation = "WhatIf"
                Status = "Simulated"
                CurrentTags = $currentTagsStr
                NewTags = $newTagsStr
                Error = $null
            }
        }
        else {
            Set-AzResourceGroup -Name $ResourceGroupName -Tag $newTags -ErrorAction Stop
            Write-Log "✅ Tags aplicados al grupo de recursos '$ResourceGroupName'" "SUCCESS"
            Write-Log "  Tags aplicados: $newTagsStr" "INFO"
            
            $script:OperationResults += [PSCustomObject]@{
                ResourceType = "ResourceGroup"
                ResourceName = $ResourceGroupName
                ResourceGroupName = $ResourceGroupName
                Operation = "Apply"
                Status = "Success"
                CurrentTags = $currentTagsStr
                NewTags = $newTagsStr
                Error = $null
            }
        }
        
        return $true
    }
    catch {
        Write-Log "❌ Error al aplicar tags al grupo de recursos '$ResourceGroupName': $($_.Exception.Message)" "ERROR"
        
        $script:OperationResults += [PSCustomObject]@{
            ResourceType = "ResourceGroup"
            ResourceName = $ResourceGroupName
            ResourceGroupName = $ResourceGroupName
            Operation = if ($WhatIfMode) { "WhatIf" } else { "Apply" }
            Status = "Failed"
            CurrentTags = $null
            NewTags = $null
            Error = $_.Exception.Message
        }
        
        return $false
    }
}

# Función para aplicar tags a recursos
function Set-ResourceTags {
    param(
        [object]$Resource,
        [hashtable]$TagsToApply,
        [string]$TagAction,
        [bool]$WhatIfMode
    )
    
    try {
        $currentTags = if ($Resource.Tags) { $Resource.Tags } else { @{} }
        $newTags = Merge-Tags -ExistingTags $currentTags -NewTags $TagsToApply -Action $TagAction
        
        $currentTagsStr = if ($currentTags.Count -gt 0) { 
            ($currentTags.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join "; " 
        } else { 
            "No Tags" 
        }
        
        $newTagsStr = ($newTags.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join "; "
        
        if ($WhatIfMode) {
            Write-Log "WHAT-IF: Aplicaría tags al recurso '$($Resource.Name)' ($($Resource.ResourceType))" "INFO"
            Write-Log "  Tags actuales: $currentTagsStr" "INFO"
            Write-Log "  Tags nuevos: $newTagsStr" "INFO"
            
            $script:OperationResults += [PSCustomObject]@{
                ResourceType = $Resource.ResourceType
                ResourceName = $Resource.Name
                ResourceGroupName = $Resource.ResourceGroupName
                Operation = "WhatIf"
                Status = "Simulated"
                CurrentTags = $currentTagsStr
                NewTags = $newTagsStr
                Error = $null
            }
        }
        else {
            Set-AzResource -ResourceId $Resource.ResourceId -Tag $newTags -Force -ErrorAction Stop
            Write-Log "✅ Tags aplicados al recurso '$($Resource.Name)' ($($Resource.ResourceType))" "SUCCESS"
            
            $script:OperationResults += [PSCustomObject]@{
                ResourceType = $Resource.ResourceType
                ResourceName = $Resource.Name
                ResourceGroupName = $Resource.ResourceGroupName
                Operation = "Apply"
                Status = "Success"
                CurrentTags = $currentTagsStr
                NewTags = $newTagsStr
                Error = $null
            }
        }
        
        return $true
    }
    catch {
        Write-Log "❌ Error al aplicar tags al recurso '$($Resource.Name)': $($_.Exception.Message)" "ERROR"
        
        $script:OperationResults += [PSCustomObject]@{
            ResourceType = $Resource.ResourceType
            ResourceName = $Resource.Name
            ResourceGroupName = $Resource.ResourceGroupName
            Operation = if ($WhatIfMode) { "WhatIf" } else { "Apply" }
            Status = "Failed"
            CurrentTags = $null
            NewTags = $null
            Error = $_.Exception.Message
        }
        
        return $false
    }
}

# Función para procesar grupos de recursos
function Process-ResourceGroups {
    param(
        [string]$SubscriptionId,
        [string]$ResourceGroupFilter,
        [hashtable]$TagsToApply,
        [string]$TagAction,
        [bool]$WhatIfMode,
        [bool]$IncludeResources
    )
    
    try {
        if ($SubscriptionId) {
            Set-AzContext -SubscriptionId $SubscriptionId
        }
        
        $resourceGroups = Get-AzResourceGroup
        
        if ($ResourceGroupFilter) {
            $resourceGroups = $resourceGroups | Where-Object { $_.ResourceGroupName -like $ResourceGroupFilter }
        }
        
        Write-Log "Procesando $($resourceGroups.Count) grupos de recursos..." "INFO"
        
        $successCount = 0
        $failureCount = 0
        
        foreach ($rg in $resourceGroups) {
            Write-Progress -Activity "Procesando grupos de recursos" -Status $rg.ResourceGroupName -PercentComplete (($successCount + $failureCount) / $resourceGroups.Count * 100)
            
            $result = Set-ResourceGroupTags -ResourceGroupName $rg.ResourceGroupName -TagsToApply $TagsToApply -TagAction $TagAction -WhatIfMode $WhatIfMode
            
            if ($result) {
                $successCount++
                
                # Procesar recursos dentro del grupo si se solicita
                if ($IncludeResources) {
                    Process-ResourcesInGroup -ResourceGroupName $rg.ResourceGroupName -TagsToApply $TagsToApply -TagAction $TagAction -WhatIfMode $WhatIfMode
                }
            }
            else {
                $failureCount++
            }
        }
        
        Write-Progress -Activity "Procesando grupos de recursos" -Completed
        
        Write-Log "Grupos de recursos procesados: $successCount exitosos, $failureCount fallos" "INFO"
        
    }
    catch {
        Write-Log "Error al procesar grupos de recursos: $($_.Exception.Message)" "ERROR"
    }
}

# Función para procesar recursos en un grupo específico
function Process-ResourcesInGroup {
    param(
        [string]$ResourceGroupName,
        [hashtable]$TagsToApply,
        [string]$TagAction,
        [bool]$WhatIfMode
    )
    
    try {
        $resources = Get-AzResource -ResourceGroupName $ResourceGroupName
        
        Write-Log "Procesando $($resources.Count) recursos en el grupo '$ResourceGroupName'..." "INFO"
        
        foreach ($resource in $resources) {
            Set-ResourceTags -Resource $resource -TagsToApply $TagsToApply -TagAction $TagAction -WhatIfMode $WhatIfMode
        }
        
    }
    catch {
        Write-Log "Error al procesar recursos en el grupo '$ResourceGroupName': $($_.Exception.Message)" "ERROR"
    }
}

# Función para procesar recursos individuales
function Process-Resources {
    param(
        [string]$SubscriptionId,
        [string]$ResourceGroupFilter,
        [string]$ResourceTypeFilter,
        [hashtable]$TagsToApply,
        [string]$TagAction,
        [bool]$WhatIfMode,
        [int]$BatchSize
    )
    
    try {
        if ($SubscriptionId) {
            Set-AzContext -SubscriptionId $SubscriptionId
        }
        
        $resources = Get-AzResource
        
        if ($ResourceGroupFilter) {
            $resources = $resources | Where-Object { $_.ResourceGroupName -like $ResourceGroupFilter }
        }
        
        if ($ResourceTypeFilter) {
            $resources = $resources | Where-Object { $_.ResourceType -like $ResourceTypeFilter }
        }
        
        Write-Log "Procesando $($resources.Count) recursos..." "INFO"
        
        $successCount = 0
        $failureCount = 0
        $processedCount = 0
        
        # Procesar en lotes
        for ($i = 0; $i -lt $resources.Count; $i += $BatchSize) {
            $batch = $resources[$i..([Math]::Min($i + $BatchSize - 1, $resources.Count - 1))]
            
            Write-Progress -Activity "Procesando recursos" -Status "Lote $([Math]::Floor($i / $BatchSize) + 1)" -PercentComplete ($i / $resources.Count * 100)
            
            foreach ($resource in $batch) {
                $processedCount++
                
                $result = Set-ResourceTags -Resource $resource -TagsToApply $TagsToApply -TagAction $TagAction -WhatIfMode $WhatIfMode
                
                if ($result) {
                    $successCount++
                } else {
                    $failureCount++
                }
                
                # Pausa breve para evitar throttling
                if ($processedCount % 10 -eq 0) {
                    Start-Sleep -Milliseconds 100
                }
            }
        }
        
        Write-Progress -Activity "Procesando recursos" -Completed
        
        Write-Log "Recursos procesados: $successCount exitosos, $failureCount fallos" "INFO"
        
    }
    catch {
        Write-Log "Error al procesar recursos: $($_.Exception.Message)" "ERROR"
    }
}

# Función para procesar desde CSV
function Process-FromCSV {
    param(
        [string]$CSVPath,
        [hashtable]$TagsToApply,
        [string]$TagAction,
        [bool]$WhatIfMode
    )
    
    $csvData = Read-ResourcesFromCSV -CSVPath $CSVPath
    
    if ($csvData.Count -eq 0) {
        return
    }
    
    Write-Log "Procesando $($csvData.Count) elementos desde CSV..." "INFO"
    
    foreach ($item in $csvData) {
        try {
            if ($item.ResourceType -eq "ResourceGroup") {
                Set-ResourceGroupTags -ResourceGroupName $item.ResourceGroupName -TagsToApply $TagsToApply -TagAction $TagAction -WhatIfMode $WhatIfMode
            }
            else {
                $resource = Get-AzResource -ResourceId $item.ResourceId -ErrorAction Stop
                Set-ResourceTags -Resource $resource -TagsToApply $TagsToApply -TagAction $TagAction -WhatIfMode $WhatIfMode
            }
        }
        catch {
            Write-Log "Error al procesar elemento desde CSV: $($_.Exception.Message)" "ERROR"
        }
    }
}

# Función para generar reporte final
function Generate-FinalReport {
    $successCount = ($script:OperationResults | Where-Object { $_.Status -eq "Success" }).Count
    $failureCount = ($script:OperationResults | Where-Object { $_.Status -eq "Failed" }).Count
    $simulatedCount = ($script:OperationResults | Where-Object { $_.Status -eq "Simulated" }).Count
    
    $report = @"

===================================================
REPORTE FINAL DE OPERACIONES
===================================================
Total de operaciones: $($script:OperationResults.Count)
Exitosas: $successCount
Fallidas: $failureCount
Simuladas (WhatIf): $simulatedCount

Operaciones por tipo de recurso:
"@
    
    $groupedResults = $script:OperationResults | Group-Object ResourceType
    foreach ($group in $groupedResults) {
        $report += "`n- $($group.Name): $($group.Count) operaciones"
    }
    
    $report += "`n===================================================`n"
    
    Write-Log $report "INFO"
    
    # Exportar resultados detallados
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $reportPath = ".\Azure_Tags_Operations_Report_${timestamp}.csv"
    
    $script:OperationResults | Export-Csv -Path $reportPath -NoTypeInformation -Encoding UTF8
    Write-Log "Reporte detallado exportado a: $reportPath" "SUCCESS"
}

# Script principal
Write-Host "🚀 Iniciando script de remediación de tags en Azure..." -ForegroundColor Cyan

# Inicializar logging
Initialize-Logging -LogPath $LogPath

# Verificar conexión a Azure
if (-not (Test-AzureConnection)) {
    exit 1
}

# Parsear tags a aplicar
$tagsToApplyHash = Parse-TagsToApply -TagsString $TagsToApply

if ($tagsToApplyHash.Count -eq 0) {
    Write-Log "No se pudieron parsear los tags a aplicar. Verifique el formato." "ERROR"
    exit 1
}

# Mostrar configuración
Write-Log "Configuración de la operación:" "INFO"
Write-Log "- Modo: $(if ($WhatIf) { 'SIMULACIÓN (WhatIf)' } else { 'APLICACIÓN REAL' })" "INFO"
Write-Log "- Acción de tags: $TagAction" "INFO"
Write-Log "- Aplicar a: $ApplyTo" "INFO"

foreach ($tag in $tagsToApplyHash.GetEnumerator()) {
    Write-Log "- Tag: $($tag.Key) = $($tag.Value)" "INFO"
}

# Confirmación si no es WhatIf
if (-not $WhatIf -and -not $Force) {
    Write-Host "`n⚠️  ADVERTENCIA: Esta operación modificará tags en Azure." -ForegroundColor Yellow
    Write-Host "¿Desea continuar? (y/N): " -NoNewline -ForegroundColor Yellow
    $confirmation = Read-Host
    
    if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
        Write-Log "Operación cancelada por el usuario." "INFO"
        exit 0
    }
}

# Mostrar contexto actual
$currentContext = Get-AzContext
Write-Log "Contexto de Azure:" "INFO"
Write-Log "- Suscripción: $($currentContext.Subscription.Name) ($($currentContext.Subscription.Id))" "INFO"
Write-Log "- Cuenta: $($currentContext.Account.Id)" "INFO"

# Ejecutar operación según el tipo
if ($InputCSV) {
    Write-Log "Procesando desde archivo CSV: $InputCSV" "INFO"
    Process-FromCSV -CSVPath $InputCSV -TagsToApply $tagsToApplyHash -TagAction $TagAction -WhatIfMode $WhatIf
}
else {
    switch ($ApplyTo) {
        "ResourceGroups" {
            Process-ResourceGroups -SubscriptionId $SubscriptionId -ResourceGroupFilter $ResourceGroupFilter -TagsToApply $tagsToApplyHash -TagAction $TagAction -WhatIfMode $WhatIf -IncludeResources $IncludeResourcesInGroups
        }
        
        "Resources" {
            Process-Resources -SubscriptionId $SubscriptionId -ResourceGroupFilter $ResourceGroupFilter -ResourceTypeFilter $ResourceTypeFilter -TagsToApply $tagsToApplyHash -TagAction $TagAction -WhatIfMode $WhatIf -BatchSize $BatchSize
        }
        
        "Both" {
            Write-Log "Procesando grupos de recursos..." "INFO"
            Process-ResourceGroups -SubscriptionId $SubscriptionId -ResourceGroupFilter $ResourceGroupFilter -TagsToApply $tagsToApplyHash -TagAction $TagAction -WhatIfMode $WhatIf -IncludeResources $false
            
            Write-Log "Procesando recursos..." "INFO"
            Process-Resources -SubscriptionId $SubscriptionId -ResourceGroupFilter $ResourceGroupFilter -ResourceTypeFilter $ResourceTypeFilter -TagsToApply $tagsToApplyHash -TagAction $TagAction -WhatIfMode $WhatIf -BatchSize $BatchSize
        }
    }
}

# Generar reporte final
Generate-FinalReport

Write-Host "`n✅ Operación de remediación completada." -ForegroundColor Green
Write-Host "📝 Consulte el archivo de log para más detalles: $script:LogFile" -ForegroundColor Cyan