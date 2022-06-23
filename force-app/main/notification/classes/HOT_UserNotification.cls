public without sharing class HOT_UserNotification {
    //Make future
    public static void notifyUser_requestCreated(List<HOT_Request__c> requests) {
        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'HOT_UserNotification'
        ];
        Map<Id, Id> userIdByRequestId = getUserIdByRequestId(requests);

        for (HOT_Request__c request : requests) {
            if (request.Account__c != null && request.Type__c != 'Me') {
                requestCreatedForYou(
                    notificationType,
                    request,
                    new Set<String>{ (String) userIdByRequestId.get(request.Id) }
                );
            }
        }
    }

    public static Map<Id, Id> getUserIdByRequestId(List<HOT_Request__c> requests) {
        Map<Id, HOT_Request__c> requestMap = new Map<Id, HOT_Request__c>(requests);
        Map<Id, Id> accountIdByRequestId = new Map<Id, Id>();

        for (HOT_Request__c request : requests) {
            accountIdByRequestId.put(request.Id, request.Account__c);
        }
        List<User> users = [SELECT Id, AccountId FROM User WHERE AccountId IN :accountIdByRequestId.values()];
        Map<Id, Id> userIdByAccountId = new Map<Id, Id>();
        for (User user : users) {
            userIdByAccountId.put(user.AccountId, user.Id);
        }
        Map<Id, Id> userIdByRequestId = new Map<Id, Id>();
        for (Id requestId : requestMap.keySet()) {
            userIdByRequestId.put(requestId, userIdByAccountId.get(accountIdByRequestId.get(requestId)));
        }
        return userIdByRequestId;
    }

    public static void requestCreatedForYou(
        CustomNotificationType notificationType,
        HOT_Request__c request,
        Set<String> recipients
    ) {
        String title = 'Du har en ny bestilling - ' + request.StartTime__c?.format('d.M.yyyy hh:mm');
        String body =
            'Noen har lagt inn en bestilling på vegne av deg: ' +
            request.StartTime__c?.format('d.M.yyyy hh:mm') +
            ' - ' +
            request.EndTime__c?.format('hh:mm');
        String pageRef =
            '{"type": "comm__namedPage","attributes": {"pageName": "mine-bestillinger"}, "state": { "id": ' +
            request.Id +
            ', "level" : "R"}}';

        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setTitle(title);
        notification.setBody(body);
        notification.setNotificationTypeId(notificationType.Id);
        notification.setTargetPageRef(pageRef);

        HOT_NotificationHandler.sendNotification(notification, recipients, (SObject) request);
    }

    public static List<Object> getAllNotifications() {
        String sfdcURL = URL.getOrgDomainUrl().toExternalForm();
        String restAPIURL = sfdcURL + '/services/data/v51.0/connect/notifications';
        HttpRequest httpRequest = new HttpRequest();

        httpRequest.setMethod('GET');

        httpRequest.setHeader('Authorization', 'OAuth ' + UserInfo.getSessionId());
        httpRequest.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID());
        httpRequest.setEndpoint(restAPIURL);
        try {
            Http http = new Http();
            HttpResponse httpResponse = http.send(httpRequest);
            Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(httpResponse.getBody());

            return (List<Object>) response.get('notifications');
        } catch (System.Exception e) {
            System.debug('ERROR: ' + e);
            return null;
        }
    }

    @AuraEnabled(cacheable=true)
    public static Notifications getNotifications(String notificationTypeNames) {
        List<String> notificationTypes = notificationTypeNames.split(', ');
        Map<String, Id> notificationTypeMap = getNotificationTypeMap(notificationTypes);
        List<Object> notifications = getAllNotifications();
        List<Object> objects = new List<Object>();

        Notifications notificationClass = new Notifications();
        for (Object obj : notifications) {
            Map<String, Object> objectMap = (Map<String, Object>) obj;
            if (notificationTypeMap.values().contains((String) objectMap.get('type')) || notificationTypeNames == '') {
                objects.add(obj);
                notificationClass.addNotification(new Notification((Map<String, Object>) obj));
            }
        }
        return notificationClass;
    }

    public static Map<String, Id> getNotificationTypeMap(List<String> notificationTypes) {
        Map<String, Id> notificationTypeMap = new Map<String, Id>();
        for (CustomNotificationType notificationType : [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName IN :notificationTypes
        ]) {
            notificationTypeMap.put(notificationType.DeveloperName, notificationType.Id);
        }
        return notificationTypeMap;
    }

    class Notifications {
        @AuraEnabled
        public Integer numberOfUnreads;
        @AuraEnabled
        public Integer numberOfNotifications;
        @AuraEnabled
        public List<Notification> notifications;

        Notifications() {
            this.numberOfUnreads = 0;
            this.numberOfNotifications = 0;
            this.notifications = new List<Notification>();
        }

        void addNotification(Notification notification) {
            this.notifications.add(notification);
            this.numberOfNotifications++;
            this.numberOfNotifications += notification.isRead ? 0 : 1;
        }
    }
    class Notification {
        @AuraEnabled
        public String title;
        @AuraEnabled
        public String body;
        @AuraEnabled
        public Boolean isRead;
        @AuraEnabled
        public Datetime createdDate;
        @AuraEnabled
        public String timeSinceCreated;

        Notification(Map<String, Object> notificationObject) {
            this.title = (String) notificationObject.get('messageTitle');
            this.body = (String) notificationObject.get('messageBody');
            this.isRead = (Boolean) notificationObject.get('read');
            //this.createdDate = (Datetime) notificationObject.get('mostRecentActivityDate');
            this.timeSinceCreated = calculateTimeSinceCreated();
        }

        String calculateTimeSinceCreated() {
            return '2 timer';
        }
    }
}
