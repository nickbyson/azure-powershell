
# ----------------------------------------------------------------------------------
#
# Copyright Microsoft Corporation
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ----------------------------------------------------------------------------------

<#
.Synopsis
Get All discovered inventory in a migrate project.
.Description
Get Azure migrate inventory commandlet fetches all inventory in a migrate project.
.Link
https://learn.microsoft.com/powershell/module/az.migrate/get-azmigratediscoveredserver
#>
function Get-AzMigrateDiscoveredInventory {
    [OutputType('PSObject')]
    [CmdletBinding(DefaultParameterSetName='List', PositionalBinding=$false, SupportsShouldProcess, ConfirmImpact='Medium')]
    param (
        [Parameter(Mandatory)]
        [Microsoft.Azure.PowerShell.Cmdlets.Migrate.Category('Path')]
        [System.String]
        # Specifies the migrate project name.
        ${ProjectName},

        [Parameter(Mandatory)]
        [Microsoft.Azure.PowerShell.Cmdlets.Migrate.Category('Path')]
        [System.String]
        # Specifies the resource group name.
        ${ResourceGroupName},

        [Parameter()]
        [Microsoft.Azure.PowerShell.Cmdlets.Migrate.Category('Path')]
        [Microsoft.Azure.PowerShell.Cmdlets.Migrate.Runtime.DefaultInfo(Script='(Get-AzContext).Subscription.Id')]
        [System.String[]]
        # Specifies the subscription id.
        ${SubscriptionId},

        [Parameter()]
        [ExportResourceType]
        # Specifies the type of resources to export.
        ${ExportType}
    )
    
    process {
        
        # Validate parameters
        $errorActionPreference = "Stop"
        $invalidParams = @()
        
        if ($invalidParams.Count -gt 0) {
            $invalidParams = $invalidParams -join ", "
            throw "Invalid parameter(s): $invalidParams"
        }

        CheckResourceGraphModuleDependency

        $query = "resources
        | where type == 'microsoft.offazure/mastersites'
        | where subscriptionId == '$SubscriptionId'
        | where id contains '$ResourceGroupName'
        | where ['tags'] contains '$ProjectName'
        | project properties.nestedSites,properties.sites"

        $argInstanceResponse = Az.ResourceGraph\Search-AzGraph -Query $query -Subscription $Subscription
        $migrateInventory = @()
        
        if($null -eq $argInstanceResponse)
        {
            throw "No inventory found for the given project name: $ProjectName"
        }

        foreach($item in $argInstanceResponse)
        {
            $nestedSites = $item.properties_nestedSites
            $sites = $item.properties_sites

            if($null -ne $nestedSites)
            {
                foreach($nestedSite in $nestedSites)
                {
                    $sites += $nestedSite
                }
            }

            foreach($site in $sites)
            {
                $migrateInventory += $site
            }
        }
        $migrateSqlInventory = @()
        $migrateWebAppInventory = @()
        $migrateMachineInventory = @()
        $inventoryTypes = @{
            "sqlServers" = "SQLInventory.csv"
            "TomcatWebApplications" = "WebAppInventory.csv"
            "IISWebApplications" = "WebAppInventory.csv"
            "machines" = "MachineInventory.csv"
        }
        $migrateInventories = @{
            "sqlServers" = $migrateSqlInventory
            "TomcatWebApplications" = $migrateWebAppInventory
            "IISWebApplications" = $migrateWebAppInventory
            "machines" = $migrateMachineInventory
        }

        foreach($item in $migrateInventory)
        {
            $query = "migrateresources
            | where id contains '$item'"

            $argInstanceResponse = Az.ResourceGraph\Search-AzGraph -Query $query -Subscription $Subscription
            
            foreach($resource in $argInstanceResponse)
            {
                $ArmResource = ParseAzureResourceId $resource.id
                
                if($ArmResource.LeafResourceName -eq "sqlServers")
                {
                    Write-Host "SQL: $ArmResource.LeafResourceName"                    
                    $migrateInventories["sqlServers"] += $resource
                }
                elseif ($ArmResource.LeafResourceName -eq "TomcatWebApplications" -or $ArmResource.LeafResourceName -eq "IISWebApplications") {
                    Write-Host "WebApp: $ArmResource.LeafResourceName"
                    $migrateInventories["IISWebApplications"] += $resource
                }
                elseif ($ArmResource.LeafResourceName -eq "machines") {        
                    Write-Host "Machines: $ArmResource.LeafResourceName"            
                    $migrateInventories["machines"] += $resource
                }
            }
        }
        
        foreach ($inventoryType in $migrateInventories.Keys) {
            if ($null -eq $ExportType -or $ExportType -eq [ExportResourceType]::All -or $ExportType -eq $inventoryType) {
                if ($migrateInventories[$inventoryType].Count -gt 0) {
                    $selectedColumns = @{"id"="id"; "Name"="properties.displayName"; "tags"="properties.tags"}

                    if ($inventoryType -eq "TomcatWebApplications" -or $inventoryType -eq "IISWebApplications") {
                        $selectedColumns["Name"] = "properties.serverFqdn"
                    }
                    elseif ($inventoryType -eq "sqlServers") {
                        $selectedColumns["Name"] = "properties.sqlServerName"
                    }

                    $OutputCsvFile = [System.IO.Path]::Combine("/src/migrate", $inventoryTypes[$inventoryType])
                    Convert-JsonToCsv $migrateInventories[$inventoryType] $selectedColumns $OutputCsvFile
                }
            }
        }

        return $migrateInventory
    }
}
