﻿// ----------------------------------------------------------------------------------
//
// Copyright Microsoft Corporation
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// http://www.apache.org/licenses/LICENSE-2.0
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// ----------------------------------------------------------------------------------

using System.Management.Automation;
using Microsoft.Azure.Commands.CosmosDB.Models;
using Microsoft.Azure.Commands.CosmosDB.Helpers;
using System.Collections.Generic;
using Microsoft.Azure.PowerShell.Cmdlets.CosmosDB.Models.MongoDB;
namespace Microsoft.Azure.Commands.CosmosDB
{
    [Cmdlet(VerbsCommon.New, ResourceManager.Common.AzureRMConstants.AzureRMPrefix + "CosmosDBMongoDBPrivilege"), OutputType(typeof(PSMongoPrivilege))]
    public class NewAzCosmosDBMongoDBPrivilege : AzureCosmosDBCmdletBase
    {
        [Parameter(Mandatory = false, HelpMessage = Constants.MongoRoleDefinitionPrivilegeResourcHelpMessage)]
        [ValidateNotNullOrEmpty]
        public PSMongoPrivilegeResource PrivilegeResource { get; set; }

        [Parameter(Mandatory = false, HelpMessage = Constants.MongoRoleDefinitionPrivilegeActionsHelpMessage)]
        [ValidateNotNullOrEmpty]
        public string[] Actions { get; set; }

        public override void ExecuteCmdlet()
        {
            PSMongoPrivilege pSMongoPrivilege = new PSMongoPrivilege();
            pSMongoPrivilege.Resource = PrivilegeResource;
            pSMongoPrivilege.Actions = Actions;

            WriteObject(pSMongoPrivilege);
            return;
        }
    }
}
