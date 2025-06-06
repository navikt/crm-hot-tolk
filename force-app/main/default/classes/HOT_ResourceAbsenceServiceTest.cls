@IsTest
private class HOT_ResourceAbsenceServiceTest {
    @testSetup
    static void setup() {
        OperatingHours operatingHours = HOT_TestDataFactory.createOperatingHours();
        insert operatingHours;
        ServiceTerritory serviceTerritory = HOT_TestDataFactory.createServiceTerritory(operatingHours);
        insert serviceTerritory;

        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
        insert serviceResource;
    }

    @IsTest
    private static void createResourceAbsenceTest() {
        RecordType eventRecordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'HOT_Events'];

        List<Event> events = new List<Event>();
        Event event1 = HOT_TestDataFactory.createEvent(eventRecordType, 1);
        events.add(event1);

        Event event2 = HOT_TestDataFactory.createEvent(eventRecordType, 2);
        event2.ShowAs = 'Free';
        events.add(event2);

        Event event3 = HOT_TestDataFactory.createEvent(eventRecordType, 3);
        events.add(event3);

        insert events;

        Test.startTest();
        Database.executeBatch(new HOT_ResourceAbsenceCreateService(), 100);
        Test.stopTest();

        List<ResourceAbsence> resourceAbsenceList = [SELECT Id FROM ResourceAbsence];
        System.assertEquals(2, resourceAbsenceList.size());
    }

    @IsTest
    private static void createResourceAbsenceTestTime() {
        RecordType eventRecordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'HOT_Events'];

        List<Event> events = new List<Event>();
        Event event1 = HOT_TestDataFactory.createEvent(eventRecordType, 1);
        event1.StartDateTime = Datetime.now();
        event1.EndDateTime = Datetime.now();
        events.add(event1);

        Event event2 = HOT_TestDataFactory.createEvent(eventRecordType, 2);
        event2.ShowAs = 'Free';
        events.add(event2);

        Event event3 = HOT_TestDataFactory.createEvent(eventRecordType, 3);
        events.add(event3);

        insert events;

        Test.startTest();
        Database.executeBatch(new HOT_ResourceAbsenceCreateService(), 100);
        Test.stopTest();

        List<ResourceAbsence> resourceAbsenceList = [SELECT Id FROM ResourceAbsence];
        System.assertEquals(2, resourceAbsenceList.size());
    }

    @IsTest
    private static void createResourceAbsenceTestScope() {
        RecordType eventRecordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'HOT_Events'];

        List<Event> events = new List<Event>();
        Event event1 = HOT_TestDataFactory.createEvent(eventRecordType, 1);
        event1.StartDateTime = Datetime.now();
        event1.EndDateTime = Datetime.now();
        events.add(event1);

        Event event2 = HOT_TestDataFactory.createEvent(eventRecordType, 2);
        event2.ShowAs = 'Free';
        events.add(event2);

        Event event3 = HOT_TestDataFactory.createEvent(eventRecordType, 3);
        events.add(event3);

        insert events;

        Test.startTest();
        Database.executeBatch(new HOT_ResourceAbsenceCreateService(Datetime.now()), 100);
        Test.stopTest();

        List<ResourceAbsence> resourceAbsenceList = [SELECT Id FROM ResourceAbsence];
        System.assertEquals(0, resourceAbsenceList.size());
    }

    @IsTest
    private static void deleteResourceAbsenceTest() {
        RecordType eventRecordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'HOT_Events'];

        List<Event> events = new List<Event>();
        Event event1 = HOT_TestDataFactory.createEvent(eventRecordType, 1);
        events.add(event1);

        Event event2 = HOT_TestDataFactory.createEvent(eventRecordType, 2);
        events.add(event2);

        insert events;

        ServiceResource serviceResource = [SELECT Id FROM ServiceResource];

        List<ResourceAbsence> resourceAbsences = new List<ResourceAbsence>();
        ResourceAbsence resourceAbsence1 = new ResourceAbsence();
        resourceAbsence1.ResourceId = serviceResource.Id;
        resourceAbsence1.HOT_EventId__c = event1.Id;
        resourceAbsence1.Start = event1.StartDateTime;
        resourceAbsence1.End = event1.EndDateTime;
        resourceAbsence1.Type = 'Møte';
        resourceAbsences.add(resourceAbsence1);

        ResourceAbsence resourceAbsence2 = new ResourceAbsence();
        resourceAbsence2.ResourceId = serviceResource.Id;
        resourceAbsence2.HOT_EventId__c = event2.Id;
        resourceAbsence2.Start = event2.StartDateTime;
        resourceAbsence2.End = event2.EndDateTime;
        resourceAbsence2.Type = 'Møte';
        resourceAbsences.add(resourceAbsence2);

        insert resourceAbsences;

        delete event1;
        event2.ShowAs = 'Free';
        update event2;

        Test.startTest();
        Database.executeBatch(new HOT_ResourceAbsenceDeleteService(), 1000);
        Test.stopTest();

        List<ResourceAbsence> resourceAbsenceList = [SELECT Id FROM ResourceAbsence];
        System.assertEquals(0, resourceAbsenceList.size());
    }

    
}
