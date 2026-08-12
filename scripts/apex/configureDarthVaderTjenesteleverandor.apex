User darth = [
    SELECT Id, IsActive, ProfileId
    FROM User
    WHERE Name = 'Darth Vader' AND Username LIKE 'darth.vader.test%'
    ORDER BY CreatedDate DESC
    LIMIT 1
];

Profile supplierProfile = [
    SELECT Id
    FROM Profile
    WHERE Name = 'HOT Tolk Tjenestesteleverandør'
    LIMIT 1
];

if (!darth.IsActive || darth.ProfileId != supplierProfile.Id) {
    darth.IsActive = true;
    darth.ProfileId = supplierProfile.Id;
    update darth;
}

List<PermissionSetAssignment> freelanceAssignments = [
    SELECT Id
    FROM PermissionSetAssignment
    WHERE
        AssigneeId = :darth.Id
        AND (
            PermissionSet.Name = 'HOT_Tolk_Frilans'
            OR PermissionSetGroup.DeveloperName = 'HOT_Tolk_Frilans_Gruppe'
        )
];
if (!freelanceAssignments.isEmpty()) {
    delete freelanceAssignments;
}

PermissionSet supplierPermissionSet = [
    SELECT Id
    FROM PermissionSet
    WHERE Name = 'HOT_Tolk_Tjenesteleverandor'
    LIMIT 1
];
if (
    [
        SELECT COUNT()
        FROM PermissionSetAssignment
        WHERE AssigneeId = :darth.Id AND PermissionSetId = :supplierPermissionSet.Id
    ] == 0
) {
    insert new PermissionSetAssignment(AssigneeId = darth.Id, PermissionSetId = supplierPermissionSet.Id);
}

PermissionSetGroup supplierPermissionSetGroup = [
    SELECT Id
    FROM PermissionSetGroup
    WHERE DeveloperName = 'HOT_Tolk_Tjenesteleverandor_Gruppe'
    LIMIT 1
];
if (
    [
        SELECT COUNT()
        FROM PermissionSetAssignment
        WHERE AssigneeId = :darth.Id AND PermissionSetGroupId = :supplierPermissionSetGroup.Id
    ] == 0
) {
    insert new PermissionSetAssignment(AssigneeId = darth.Id, PermissionSetGroupId = supplierPermissionSetGroup.Id);
}

Group supplierPublicGroup = [
    SELECT Id
    FROM Group
    WHERE DeveloperName = 'HOT_Tolk_Tjenesteleverandor' AND Type = 'Regular'
    LIMIT 1
];
if (
    [
        SELECT COUNT()
        FROM GroupMember
        WHERE GroupId = :supplierPublicGroup.Id AND UserOrGroupId = :darth.Id
    ] == 0
) {
    insert new GroupMember(GroupId = supplierPublicGroup.Id, UserOrGroupId = darth.Id);
}

System.debug(LoggingLevel.ERROR, 'Configured Darth Vader as a tjenesteleverandør dispatcher: ' + darth.Id);
