
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

function Update-AzMigrateDiscoveredInventory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$InputCsvFile,

        [Parameter()]
        [string]$OutputCsvFile
    )

    process {
        # Validate input CSV file
        ValidateCsvFileHelper -InputCsvFile $InputCsvFile

        # Validate output CSV file path
        if ($OutputCsvFile) {
            ValidateCsvPathHelper -OutputCsvFile $OutputCsvFile
        }

        # Read the input CSV file
        $data = Import-Csv -Path $InputCsvFile -Delimiter ','
        
        # Concurrent processing using PowerShell jobs
        $results = $data | ForEach-Object {
            $tagtable = @{}
            try {
                $Row = $_
                
                # Validate Row data
                if ($Row.id -and $Row.etag -and $Row.tags) {
                    Write-Host "Row: $Row"        
                    $ArmResource = ParseAzureResourceId $Row.id
                    $Etag = EtagFormatHelper $Row.etag
                    
                    $Tags = $Row.tags
                    $keyValuePairs = $Tags -split ','
                    foreach ($pair in $keyValuePairs) {
                        $key, $value = $pair -split '=', 2
                        $tagtable[$key.Trim()] = $value.Trim()
                    }
    
                    # Make the API call
                    $response = Update-AzMigrateMachinesController -MachineName $ArmResource.LeafResourceId -ResourceGroupName $ArmResource.ResourceGroupName -SiteName $ArmResource.SiteName -SubscriptionId $ArmResource.SubscriptionId -Tag @{"tag03"="tagValue300"} -IfMatch $Etag
            
                    # Create a custom object to store the results
                    [PSCustomObject]@{
                        Id     = $Row.id
                        Tags   = $Row.tags
                        Etag   = $Row.etag
                        status = $response.Status
                        error  = $null
                    }
                }
                else {
                    throw "Invalid data in CSV row: $Row"
                }
            }
            catch {
                # Handle API call errors
                [PSCustomObject]@{
                    Id     = $Row.id
                    Tags   = $Row.tags
                    Etag   = $Row.etag
                    status = $null
                    error  = $_.Exception.Message
                }
            }
        }

        # Write the results to CSV
        if ($OutputCsvFile) {
            $results | Export-Csv -Path $OutputCsvFile -NoTypeInformation
        }

        # Output the results to the pipeline
        $results
    }
}
