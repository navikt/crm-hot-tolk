User darth = [SELECT Id, Name FROM User WHERE Username LIKE 'darth.vader.test%' AND IsActive = true LIMIT 1];

List<ServiceResource> existingSR = [SELECT Id FROM ServiceResource WHERE RelatedRecordId = :darth.Id];
ServiceResource sr;

if (existingSR.isEmpty()) {
    sr = new ServiceResource(
        Name = darth.Name,
        RelatedRecordId = darth.Id,
        ResourceType = 'T', // T = Technician (brukes for Tolker i HOT)
        IsActive = true
    );
    insert sr;
    System.debug('Service Resource opprettet for: ' + darth.Name);
} else {
    sr = existingSR[0];
    System.debug('Service Resource eksisterte allerede.');
}

// Hent Territory og Skill
ServiceTerritory territory = [SELECT Id, Name FROM ServiceTerritory WHERE Name = 'Nordland' LIMIT 1];
Skill tolkSkill = [SELECT Id, MasterLabel FROM Skill WHERE DeveloperName = 'Tegnspraktolk' LIMIT 1];

// Opprett Service Territory Member (Kobling mellom ressurs og område)
List<ServiceTerritoryMember> existingSTM = [
    SELECT Id FROM ServiceTerritoryMember 
    WHERE ServiceResourceId = :sr.Id AND ServiceTerritoryId = :territory.Id
];

if (existingSTM.isEmpty()) {
    insert new ServiceTerritoryMember(
        ServiceResourceId = sr.Id,
        ServiceTerritoryId = territory.Id,
        EffectiveStartDate = System.now().addDays(-30),
        TerritoryType = 'P' // Primary
    );
    System.debug('Lagt til i Territory: ' + territory.Name);
}

// Opprett Service Resource Skill (Kobling mellom ressurs og kompetanse)
List<ServiceResourceSkill> existingSRS = [
    SELECT Id FROM ServiceResourceSkill 
    WHERE ServiceResourceId = :sr.Id AND SkillId = :tolkSkill.Id
];

if (existingSRS.isEmpty()) {
    insert new ServiceResourceSkill(
        ServiceResourceId = sr.Id,
        SkillId = tolkSkill.Id,
        EffectiveStartDate = System.now().addDays(-30),
        SkillLevel = 5
    );
    System.debug('Skill lagt til: ' + tolkSkill.MasterLabel);
}