public without sharing class HOT_MassNotificationService {
    public static Set<String> getUsersWithProfiles(List<String> profileNames) {
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name IN :profileNames];
        Map<Id, User> users = new Map<Id, User>([SELECT Id FROM User WHERE ProfileId IN :profiles AND IsActive = TRUE]);
        return (Set<String>) JSON.deserialize(JSON.serialize(users.keySet()), Set<String>.class);
    }

    public static Id getMassNotificationTypeId() {
        return [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName = 'HOT_MassNotification'].Id;
    }

    //------ Example -------//
    /*
    Messaging.CustomNotification notification = new Messaging.CustomNotification();
    notification.setNotificationTypeId(HOT_MassNotificationService.getMassNotificationTypeId());
    notification.setTargetId('000000000000000AAA'); //Dummy-Id
    notification.setTitle('Fjern Buffrede metadata');
    notification.setBody('Det har nå kommet oppdateringer, og vi ber deg derfor gå inn på innstillinger og trykke "Fjern Buffrede Metadata"');
    notification.send(getUsersWithProfiles(new List<String>{'NAV Samhandler', 'HOT Tolk Ansatt'}));
    */
}
