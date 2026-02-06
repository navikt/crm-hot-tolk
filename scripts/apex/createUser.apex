Account darthAccount = [
    SELECT Id, PersonContactId, Name, INT_PersonIdent__c 
    FROM Account 
    WHERE Name = 'Darth Vader' 
    LIMIT 1
];

Profile portalProfile = [
    SELECT Id 
    FROM Profile 
    WHERE Name = 'NAV Samhandler' 
    LIMIT 1
];

String uniqueSuffix = String.valueOf(System.currentTimeMillis());

User darthUser = new User(
    FirstName = 'Darth',
    LastName = 'Vader',
    Email = 'darth.vader@test.no',
    Username = 'darth.vader.test' + uniqueSuffix + '@nav.hot.no',
    Alias = 'dvade',
    TimeZoneSidKey = 'Europe/Oslo',
    LocaleSidKey = 'no_NO',
    EmailEncodingKey = 'UTF-8',
    LanguageLocaleKey = 'no',
    ProfileId = portalProfile.Id,
    ContactId = darthAccount.PersonContactId, // Koblingen til Account skjer her
    IsActive = true
);
insert darthUser;
System.debug('Community User Created: ' + darthUser.Username);

List<PermissionSet> permSets = [
    SELECT Id FROM PermissionSet WHERE Name IN ('HOT_Tolk_Frilans')
];

List<PermissionSetGroup> permGroups = [
    SELECT Id FROM PermissionSetGroup WHERE DeveloperName IN ('HOT_Tolk_Frilans_Gruppe')
];

List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();

for(PermissionSet ps : permSets){
    assignments.add(new PermissionSetAssignment(
        AssigneeId = darthUser.Id,
        PermissionSetId = ps.Id
    ));
}

for(PermissionSetGroup psg : permGroups){
    assignments.add(new PermissionSetAssignment(
        AssigneeId = darthUser.Id,
        PermissionSetGroupId = psg.Id
    ));
}

insert assignments;
System.debug('Permission Sets og Groups er tildelt');