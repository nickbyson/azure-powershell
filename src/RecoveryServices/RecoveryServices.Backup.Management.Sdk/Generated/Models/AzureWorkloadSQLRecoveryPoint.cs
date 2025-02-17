// <auto-generated>
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for
// license information.
//
// Code generated by Microsoft (R) AutoRest Code Generator.
// Changes may cause incorrect behavior and will be lost if the code is
// regenerated.
// </auto-generated>

namespace Microsoft.Azure.Management.RecoveryServices.Backup.Models
{
    using Newtonsoft.Json;
    using System.Collections;
    using System.Collections.Generic;
    using System.Linq;

    /// <summary>
    /// SQL specific recoverypoint, specifically encapsulates full/diff
    /// recoverypoint along with extended info
    /// </summary>
    [Newtonsoft.Json.JsonObject("AzureWorkloadSQLRecoveryPoint")]
    public partial class AzureWorkloadSQLRecoveryPoint : AzureWorkloadRecoveryPoint
    {
        /// <summary>
        /// Initializes a new instance of the AzureWorkloadSQLRecoveryPoint
        /// class.
        /// </summary>
        public AzureWorkloadSQLRecoveryPoint()
        {
            CustomInit();
        }

        /// <summary>
        /// Initializes a new instance of the AzureWorkloadSQLRecoveryPoint
        /// class.
        /// </summary>
        /// <param name="recoveryPointTimeInUTC">UTC time at which recovery
        /// point was created</param>
        /// <param name="type">Type of restore point. Possible values include:
        /// 'Invalid', 'Full', 'Log', 'Differential', 'Incremental',
        /// 'SnapshotFull', 'SnapshotCopyOnlyFull'</param>
        /// <param name="recoveryPointTierDetails">Recovery point tier
        /// information.</param>
        /// <param name="recoveryPointMoveReadinessInfo">Eligibility of RP to
        /// be moved to another tier</param>
        /// <param name="recoveryPointProperties">Properties of Recovery
        /// Point</param>
        /// <param name="extendedInfo">Extended Info that provides data
        /// directory details. Will be populated in two cases:
        /// When a specific recovery point is accessed using GetRecoveryPoint
        /// Or when ListRecoveryPoints is called for Log RP only with
        /// ExtendedInfo query filter</param>
        public AzureWorkloadSQLRecoveryPoint(System.DateTime? recoveryPointTimeInUTC = default(System.DateTime?), string type = default(string), IList<RecoveryPointTierInformationV2> recoveryPointTierDetails = default(IList<RecoveryPointTierInformationV2>), IDictionary<string, RecoveryPointMoveReadinessInfo> recoveryPointMoveReadinessInfo = default(IDictionary<string, RecoveryPointMoveReadinessInfo>), RecoveryPointProperties recoveryPointProperties = default(RecoveryPointProperties), AzureWorkloadSQLRecoveryPointExtendedInfo extendedInfo = default(AzureWorkloadSQLRecoveryPointExtendedInfo))
            : base(recoveryPointTimeInUTC, type, recoveryPointTierDetails, recoveryPointMoveReadinessInfo, recoveryPointProperties)
        {
            ExtendedInfo = extendedInfo;
            CustomInit();
        }

        /// <summary>
        /// An initialization method that performs custom operations like setting defaults
        /// </summary>
        partial void CustomInit();

        /// <summary>
        /// Gets or sets extended Info that provides data directory details.
        /// Will be populated in two cases:
        /// When a specific recovery point is accessed using GetRecoveryPoint
        /// Or when ListRecoveryPoints is called for Log RP only with
        /// ExtendedInfo query filter
        /// </summary>
        [JsonProperty(PropertyName = "extendedInfo")]
        public AzureWorkloadSQLRecoveryPointExtendedInfo ExtendedInfo { get; set; }

    }
}
