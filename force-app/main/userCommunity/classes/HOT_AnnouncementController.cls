public without sharing class HOT_AnnouncementController {
    public class AnnouncementWrapper {
        @AuraEnabled
        public List<HOT_Announcement__c> infoWarningAnnouncements;

        @AuraEnabled
        public List<HOT_Announcement__c> newsAnnouncements;

        @AuraEnabled
        public List<Id> unreadAnnouncementIds;

        public AnnouncementWrapper() {
            infoWarningAnnouncements = new List<HOT_Announcement__c>();
            newsAnnouncements = new List<HOT_Announcement__c>();
            unreadAnnouncementIds = new List<Id>();
        }
    }

    @AuraEnabled(cacheable=true)
    public static AnnouncementWrapper getAnnouncementWrapper() {
        List<HOT_Announcement__c> announcements = getAnnouncements();
        AnnouncementWrapper wrapper = new AnnouncementWrapper();

        if (announcements.isEmpty()) {
            return wrapper;
        }

        Set<Id> announcementIds = new Set<Id>();

        for (HOT_Announcement__c announcement : announcements) {
            announcementIds.add(announcement.Id);

            if (announcement.Type__c == 'Information' || announcement.Type__c == 'Warning') {
                wrapper.infoWarningAnnouncements.add(announcement);
            }

            if (announcement.Type__c == 'News') {
                wrapper.newsAnnouncements.add(announcement);
            }
        }

        Set<Id> readAnnouncementIds = getReadAnnouncementIds(announcementIds);

        for (HOT_Announcement__c announcement : announcements) {
            if (announcement.Type__c == 'News' && !readAnnouncementIds.contains(announcement.Id)) {
                wrapper.unreadAnnouncementIds.add(announcement.Id);
            }
        }

        return wrapper;
    }

    @AuraEnabled(cacheable=true)
    public static List<HOT_Announcement__c> getAnnouncements() {
        User currentUser = getCurrentUser();
        Boolean isInterpreter = currentUser.Profile.Name == 'NAV Samhandler';
        String userRegion = currentUser.Account?.CRM_Person__r?.CRM_Region__r?.CRM_Code__c;

        Map<String, String> regionMap = new Map<String, String>();
        for (Common_Code__c r : [
            SELECT Name, CRM_Code__c
            FROM Common_Code__c
            WHERE CRM_Code_Set__c = 'Fylke' AND CRM_Active__c = TRUE
        ]) {
            regionMap.put(r.Name, r.CRM_Code__c);
        }

        List<HOT_Announcement__c> announcements = [
            SELECT
                Id,
                IsActive__c,
                Title__c,
                Description__c,
                RegionAudience__c,
                TargetSite__c,
                Type__c,
                Audience__c,
                CreatedDate,
                Url__c,
                UrlLabel__c
            FROM HOT_Announcement__c
            WHERE IsActive__c = TRUE AND TargetSite__c = 'Tolkebestilling' AND RecordType.DeveloperName = 'TolkEkstern'
            ORDER BY CreatedDate DESC
        ];

        List<HOT_Announcement__c> filteredAnnouncements = new List<HOT_Announcement__c>();

        for (HOT_Announcement__c announcement : announcements) {
            Boolean audienceMatches =
                (isInterpreter &&
                (announcement.Audience__c == 'Bare frilanstolk' ||
                announcement.Audience__c == 'Alle')) ||
                (!isInterpreter &&
                (announcement.Audience__c == 'Bare tolkebruker' ||
                announcement.Audience__c == 'Alle'));

            if (!audienceMatches) {
                continue;
            }

            if (String.isBlank(announcement.RegionAudience__c)) {
                filteredAnnouncements.add(announcement);
                continue;
            }

            List<String> fylker = announcement.RegionAudience__c.split(';');

            for (String fylke : fylker) {
                String trimmedFylke = fylke.trim();

                if (regionMap.containsKey(trimmedFylke) && regionMap.get(trimmedFylke) == userRegion) {
                    filteredAnnouncements.add(announcement);
                    break;
                }
            }
        }

        return filteredAnnouncements;
    }

    public static Set<Id> getReadAnnouncementIds(Set<Id> announcementIds) {
        Set<Id> readAnnouncementIds = new Set<Id>();

        if (announcementIds.isEmpty()) {
            return readAnnouncementIds;
        }

        for (HOT_ReadReceipt__c receipt : [
            SELECT Announcement__c
            FROM HOT_ReadReceipt__c
            WHERE User__c = :UserInfo.getUserId() AND Announcement__c IN :announcementIds
        ]) {
            readAnnouncementIds.add(receipt.Announcement__c);
        }

        return readAnnouncementIds;
    }

    @AuraEnabled
    public static void markAnnouncementsAsRead() {
        List<HOT_Announcement__c> announcements = getAnnouncements();

        if (announcements.isEmpty()) {
            return;
        }

        Set<Id> announcementIds = new Set<Id>();

        for (HOT_Announcement__c announcement : announcements) {
            announcementIds.add(announcement.Id);
        }

        Set<Id> existingReceiptAnnouncementIds = getReadAnnouncementIds(announcementIds);
        List<HOT_ReadReceipt__c> receiptsToInsert = new List<HOT_ReadReceipt__c>();

        for (HOT_Announcement__c announcement : announcements) {
            if (!existingReceiptAnnouncementIds.contains(announcement.Id)) {
                receiptsToInsert.add(
                    new HOT_ReadReceipt__c(User__c = UserInfo.getUserId(), Announcement__c = announcement.Id)
                );
            }
        }

        if (!receiptsToInsert.isEmpty()) {
            insert receiptsToInsert;
        }
    }

    public static User getCurrentUser() {
        return [
            SELECT Id, Profile.Name, Account.CRM_Person__r.CRM_Region__r.CRM_Code__c
            FROM User
            WHERE Id = :UserInfo.getUserId()
        ];
    }
}
