public without sharing class HOT_AnnouncementController {
    @AuraEnabled
    public static List<HOT_Announcement__c> getAnnouncements() {
        // Hent nåværende bruker
        User currentUser = getCurrentUser();
        Boolean isInterpreter = currentUser.Profile.Name == 'NAV Samhandler';

        // Hent brukerens region (CRM_Code__c)
        String userRegion = currentUser.Account?.CRM_Person__r?.CRM_Region__r?.CRM_Code__c;

        // Hent alle regioner (Name → CRM_Code__c)
        Map<String, String> regionMap = new Map<String, String>();
        for (Common_Code__c r : [
            SELECT Name, CRM_Code__c
            FROM Common_Code__c
            WHERE CRM_Code_Set__c = 'Fylke' AND CRM_Active__c = TRUE
        ]) {
            regionMap.put(r.Name, r.CRM_Code__c);
        }

        // Hent alle aktive announcements
        List<HOT_Announcement__c> announcements = [
            SELECT Id, IsActive__c, Title__c, Description__c, RegionAudience__c, TargetSite__c, Type__c, Audience__c
            FROM HOT_Announcement__c
            WHERE IsActive__c = TRUE
        ];

        // Filtrer announcements som matcher brukerens region
        List<HOT_Announcement__c> filteredAnnouncements = new List<HOT_Announcement__c>();

        for (HOT_Announcement__c ann : announcements) {
            if (String.isNotBlank(ann.RegionAudience__c)) {
                List<String> fylker = ann.RegionAudience__c.split(';');
                for (String fylke : fylker) {
                    fylke = fylke.trim();
                    if (regionMap.containsKey(fylke) && regionMap.get(fylke) == userRegion) {
                        filteredAnnouncements.add(ann);
                        break; // allerede lagt til, gå til neste announcement
                    }
                }
            }
        }

        return filteredAnnouncements;
    }

    // Hent nåværende bruker
    public static User getCurrentUser() {
        return [
            SELECT Id, Profile.Name, Account.CRM_Person__r.CRM_Region__r.CRM_Code__c
            FROM User
            WHERE Id = :UserInfo.getUserId()
        ];
    }
}
