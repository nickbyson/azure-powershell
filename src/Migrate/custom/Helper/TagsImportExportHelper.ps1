function CheckResourceGraphModuleDependency {
    [Microsoft.Azure.PowerShell.Cmdlets.Migrate.DoNotExportAttribute()]
    param() 

    process {
        $module = Get-Module -ListAvailable | Where-Object { $_.Name -eq "Az.ResourceGraph" }
        if ($null -eq $module) {
            $message = "Az.ResourceGraph Module must be installed to run this command. Please run 'Install-Module -Name Az.ResourceGraph' to install and continue."
            throw $message
        }
    }
}

function Convert-JsonToCsv {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$response,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$SelectedColumns,

        [Parameter(Mandatory = $true)]
        [string]$CsvFilePath
    )

    process {
        try {
            Write-Host "Exporting the following columns to CSV: $SelectedColumns"

            # Create an array to store the selected data
            $selectedData = @()

            # Loop through the JSON response and select the desired columns
            foreach ($item in $response) {
                $selectedItem = @{}
                foreach ($column in $SelectedColumns.Keys) {
                    $selectedItem[$column] = Invoke-Expression -Command "`$item.$($SelectedColumns[$column])"
                }
                $selectedItem["etag"] = "*"

                if($null -ne $selectedItem["tags"]){
                    $selectedItem["tags"] = $selectedItem["tags"] -replace '^@{(.*)}$', '$1' 
                    $selectedItem["tags"] = $selectedItem["tags"] -replace ';', ','
                }
                
                if($null -ne $selectedItem["id"]){

                    $selectedData += New-Object -TypeName PSObject -Property $selectedItem
                }
            }

            # Convert the selected data to CSV format
            $selectedData | Export-Csv -Path $CsvFilePath -NoTypeInformation

            Write-Host "Data has been successfully saved to $CsvFilePath"
        } catch {
            Write-Host "Error occurred: $_" -ForegroundColor Red
        }
    }
}


function ValidateCsvFileHelper {
    param (
        [Parameter(Mandatory = $true)]
        [string]$InputCsvFile
    )

    if (-Not (Test-Path $InputCsvFile -PathType Leaf)) {
        throw "Input CSV file not found at path: $InputCsvFile"
    }
}

function ValidateCsvPathHelper {
    param (
        [Parameter(Mandatory = $true)]
        [string]$OutputCsvFile
    )

    if (-Not (Test-Path (Split-Path -Path $OutputCsvFile) -PathType Container)) {
        throw "Output CSV file path is invalid: $OutputCsvFile"
    }
}

function ValidateRequiredParameterHelper {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ParameterName,

        [Parameter(Mandatory = $true)]
        [string]$ParameterValue
    )

    if (-Not $ParameterValue) {
        throw "$ParameterName is a required parameter and cannot be empty."
    }
}

function EtagFormatHelper {
    param (
        [Parameter(Mandatory = $true)]
        [string]$EtagValue
    )
    
    if ($EtagValue -match '^[0-9a-fA-F-*]+$') {
        $etagFormatted = 'W/"{0}"' -f $EtagValue
    }
    else {
        throw "$EtagValue is in InvalidFormat."
    }
    
    $etagFormatted
}

function global:ProcessApiCallHelper {
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Row
    )
    
    try {
        $ArmResource = ParseAzureResourceId -ResourceId $Row.id
        $TagValue = EtagFormatHelper $Row.tags
        # Make the API call
        $response = Update-AzMigrateMachinesController -MachineName $ArmResource.LeafResourceId -ResourceGroupName $ArmResource.ResourceGroupName -SiteName $ArmResource.SiteName -SubscriptionId $ArmResource.SubscriptionId -Tag $TagValue -IfMatch $TagValue -ErrorAction Stop

        # Create a custom object to store the results
        [PSCustomObject]@{
            Id  = $Row.id
            Tags  = $Row.tags
            Etag  = $Row.etag
            status = $response.Status
            error  = $null
        }
    }
    catch {
        # Handle API call errors
        [PSCustomObject]@{
            Id  = $Row.id
            Tags  = $Row.tags
            Etag  = $Row.etag
            status = $null
            error  = $_.Exception.Message
        }
    }
}

function WriteResultsToCsvHeper {
    param (
        [Parameter(Mandatory = $true)]
        [array]$Results,

        [Parameter(Mandatory = $true)]
        [string]$OutputCsvFile
    )

    $Results | Export-Csv -Path $OutputCsvFile -NoTypeInformation
}

function ParseAzureResourceId {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias("ResourceId")]
        [string]$InputObject
    )

    process {
        foreach ($id in $InputObject) {
            $parts = $id.Split("/")
            
            if ($parts.Length -lt 9) {
                Write-Error "Invalid Azure Resource ID: $id. The ID is too short."
                continue
            }
            
            if ($parts[0] -ne '' -or $parts[1] -ne 'subscriptions') {
                Write-Error "Invalid Azure Resource ID: $id. Missing or incorrect subscription segment."
                continue
            }

            $resourceTypeIndex = [Array]::IndexOf($parts, 'providers')
            if ($resourceTypeIndex -eq -1 -or $resourceTypeIndex -ge $parts.Length - 2) {
                Write-Error "Invalid Azure Resource ID: $id. Missing or incorrect 'providers' segment."
                continue
            }
            
            [PSCustomObject]@{
                "SubscriptionId"       = $parts[2]
                "ResourceGroupName"    = $parts[4]
                "ResourceProviderName" = $parts[$resourceTypeIndex + 1]
                "ResourceType"         = $parts[$resourceTypeIndex + 2]
                "SiteName"             = $parts[$resourceTypeIndex + 3]
                "LeafResourceName"     = $parts[-2]
                "LeafResourceId"       = $parts[-1]
            }
        }
    }
}