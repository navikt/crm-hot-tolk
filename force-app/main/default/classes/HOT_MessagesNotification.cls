public without sharing class HOT_MessagesNotification {
    private static Map<String, CustomNotificationType> notificationTypeCache;

    private class MessageContent {
        public String title;
        public String body;

        public MessageContent(String title, String body) {
            this.title = title;
            this.body = body;
        }
    }

    private static HOT_Notification__c newMessageNotification(
        Id accountId,
        Id serviceResourceId,
        Thread__c thread,
        String type,
        String channel,
        String notificationSubject,
        String notificationText
    ) {
        HOT_Notification__c notification = new HOT_Notification__c();
        notification.HOT_Account__c = accountId;
        notification.HOT_ServiceResource__c = serviceResourceId;
        notification.HOT_NotificationChannel__c = channel;
        notification.HOT_Subject__c = notificationSubject;
        notification.HOT_NotificationText__c = notificationText;
        notification.HOT_RelatedObject__c = thread.Id;
        notification.HOT_RelatedObjectType__c = type;
        return notification;
    }

    private static void insertNotifications(List<HOT_Notification__c> notifications) {
        if (notifications == null || notifications.isEmpty()) {
            return;
        }

        try {
            HOT_NotificationCentreController.createNotification(notifications);
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publish();
        }
    }

    private static MessageContent getContentForChannel(
        String senderRole,
        String channel,
        Boolean isInterpreterReciever
    ) {
        String title = HOT_MessageHelper.buildHeader(senderRole, isInterpreterReciever);
        String body = channel == 'SMS'
            ? HOT_MessageHelper.buildSMSNewMessage(senderRole, isInterpreterReciever)
            : HOT_MessageHelper.buildPushNewMessageBody();

        return new MessageContent(title, body);
    }

    public static void NotifyDispatcher(List<Id> threadIds) {
        List<Thread__c> threads = [
            SELECT Id, Name, OwnerId, HOT_Dispatcher__c, HOT_Subject__c
            FROM Thread__c
            WHERE Id IN :threadIds
        ];

        List<Id> ownerIds = new List<Id>();
        for (Thread__c thread : threads) {
            ownerIds.add(thread.OwnerId);
        }

        Map<Id, Id> groupByQueue = HOT_NotificationHandler.getGroupIdByQueueId(ownerIds);
        String notificationTypeID = getCustomNotificationType('HOT_NotifyDispatcher').Id;

        for (Thread__c thread : threads) {
            Set<String> recipients = new Set<String>();
            if (thread.HOT_Dispatcher__c != null) {
                recipients.add(thread.HOT_Dispatcher__c);
            } else {
                recipients.add(groupByQueue.get(thread.OwnerId));
            }

            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setTitle('Ny melding');
            notification.setBody(thread.HOT_Subject__c);
            notification.setNotificationTypeId(notificationTypeID);
            notification.setTargetId(thread.Id);
            HOT_NotificationHandler.sendNotification(notification, recipients, (SObject) thread);
        }
    }
    //Felles metode som sender varsel til enten bruker eller tolk basert på type tråd
    public static void NotifyUserOnNewMessage(List<Id> threadIds) {
        List<Thread__c> threadsToNotifyUsers = new List<Thread__c>();
        List<Thread__c> threadsToNotifyInterpreters = new List<Thread__c>();

        List<Thread__c> threads = [
            SELECT
                Id,
                CRM_Account__c,
                CRM_Related_Object__c,
                CRM_Thread_Type__c,
                HOT_ParticipantIds__c,
                HOT_IsEmployeeThread__c,
                LastModifiedById,
                HOT_ServiceResource__c,
                HOT_ServiceResource__r.HOT_MobilePhone__c,
                CRM_Account__r.INT_KrrMobilePhone__c,
                CRM_Account__r.CRM_Person__r.HOT_MobilePhone__c,
                CRM_Account__r.CRM_Person__r.HOT_NotificationChannel__c,
                CRM_Account__r.CRM_Person__r.HOT_IsReservationAgainstNotifications__c
            FROM Thread__c
            WHERE Id IN :threadIds
        ];

        for (Thread__c thread : threads) {
            if (
                thread.CRM_Thread_Type__c == 'HOT_BRUKER-FORMIDLER' ||
                thread.CRM_Thread_Type__c == 'HOT_BESTILLER-FORMIDLER' ||
                thread.CRM_Thread_Type__c == 'HOT_BRUKER-TOLK'
            ) {
                //Ved disse typene er det varsel til bruker som gjelder, og må dermed bruke varslingskanal til bruker.
                threadsToNotifyUsers.add(thread);
            }

            if (
                thread.CRM_Thread_Type__c == 'HOT_TOLK-TOLK' ||
                thread.CRM_Thread_Type__c == 'HOT_TOLK-FORMIDLER' ||
                thread.CRM_Thread_Type__c == 'HOT_TOLK-RESSURSKONTOR' ||
                thread.CRM_Thread_Type__c == 'HOT_BRUKER-TOLK'
            ) {
                //Ved disse typene er det varsel til tolk som gjelder, og må dermed bruke varslingskanal til tolk.
                threadsToNotifyInterpreters.add(thread);
            }
        }

        if (!threadsToNotifyUsers.isEmpty()) {
            notifyUser(threadsToNotifyUsers);
        }

        if (!threadsToNotifyInterpreters.isEmpty()) {
            notifyInterpreter(threadsToNotifyInterpreters);
        }
    }

    public static void notifyUser(List<Thread__c> threadList) {
        Set<Id> accountIds = new Set<Id>();
        Set<Id> threadIds = new Set<Id>();

        for (Thread__c thread : threadList) {
            threadIds.add(thread.Id);

            if (
                thread.CRM_Account__c != null &&
                thread.CRM_Account__r.CRM_Person__r.HOT_IsReservationAgainstNotifications__c == false
            ) {
                accountIds.add(thread.CRM_Account__c);
            }
        }
        //Mapper account til user
        Map<Id, Id> accountToUserId = new Map<Id, Id>();
        for (User userRecord : [SELECT Id, AccountId FROM User WHERE AccountId IN :accountIds]) {
            accountToUserId.put(userRecord.AccountId, userRecord.Id);
        }
        //Finner hvem som har sendt siste melding i hver tråd
        Map<Id, Id> threadToLastSender = getLastMessageSenderPerThread(threadIds);
        //Finner rollen ifht oppdraget/bestillingen til den som har sendt siste melding i hver tråd
        Map<Id, String> threadToSenderRole = HOT_ThreadParticipants.getUserSenderRoleInThread(
            threadList,
            threadToLastSender
        );

        CustomNotificationType notificationType = getCustomNotificationType('HOT_NotifyUser');
        List<HOT_Notification__c> notificationList = new List<HOT_Notification__c>();
        List<Thread__c> threadsForSMS = new List<Thread__c>();

        for (Thread__c thread : threadList) {
            Id userId = accountToUserId.get(thread.CRM_Account__c);
            Id lastSender = threadToLastSender.get(thread.Id);
            //Skal ikke varsle om det er brukeren selv som har sendt siste melding
            if (userId == null || userId == lastSender) {
                continue;
            }

            String notificationChannel = thread.CRM_Account__r.CRM_Person__r.HOT_NotificationChannel__c;
            String channel = notificationChannel != null && notificationChannel.contains('Push')
                ? 'Push-varsel i appen'
                : 'SMS';
            //Bygger varsel innhold basert på kanal
            MessageContent content = getContentForChannel(threadToSenderRole.get(thread.Id), channel, false);

            //Oppretter varsel record for innsetting i til varslingsliste
            notificationList.add(
                newMessageNotification(
                    thread.CRM_Account__c,
                    null,
                    thread,
                    'threadUser',
                    channel,
                    content.title,
                    content.body
                )
            );

            if (channel == 'Push-varsel i appen') {
                HOT_UserNotificationService.newMessageNotification(
                    notificationType,
                    thread,
                    false,
                    true,
                    new Set<String>{ userId },
                    content.title,
                    content.body
                );
            } else {
                threadsForSMS.add(thread);
            }
        }

        HOT_ReminderSMSService.sendSMSOnNewMessage(threadsForSMS, threadToLastSender, threadToSenderRole);
        insertNotifications(notificationList);
    }

    public static Map<Id, Id> getLastMessageSenderPerThread(Set<Id> threadIds) {
        Map<Id, Id> result = new Map<Id, Id>();

        if (threadIds == null || threadIds.isEmpty()) {
            return result;
        }

        List<Message__c> messages = [
            SELECT Id, CRM_Thread__c, CreatedById, CreatedDate
            FROM Message__c
            WHERE CRM_Thread__c IN :threadIds
            ORDER BY CRM_Thread__c, CreatedDate DESC
        ];

        for (Message__c messageRecord : messages) {
            if (!result.containsKey(messageRecord.CRM_Thread__c)) {
                result.put(messageRecord.CRM_Thread__c, messageRecord.CreatedById);
            }
        }

        return result;
    }

    public static void notifyInterpreter(List<Thread__c> threadList) {
        CustomNotificationType notificationType = getCustomNotificationType('HOT_NotifyInterpreter');
        Map<Id, List<Thread__c>> accountToThreads = new Map<Id, List<Thread__c>>();
        Map<Id, List<Thread__c>> serviceResourceToThreads = new Map<Id, List<Thread__c>>();
        Map<Id, List<Thread__c>> interpretersOnThreadMap = new Map<Id, List<Thread__c>>();
        Set<Id> threadIds = new Set<Id>();

        for (Thread__c thread : threadList) {
            threadIds.add(thread.Id);

            if (
                thread.CRM_Thread_Type__c == 'HOT_TOLK-FORMIDLER' ||
                thread.CRM_Thread_Type__c == 'HOT_TOLK-RESSURSKONTOR'
            ) {
                //En til en samtaler
                if (thread.CRM_Account__c != null) {
                    if (!accountToThreads.containsKey(thread.CRM_Account__c)) {
                        accountToThreads.put(thread.CRM_Account__c, new List<Thread__c>());
                    }
                    accountToThreads.get(thread.CRM_Account__c).add(thread);
                }

                if (thread.HOT_ServiceResource__c != null) {
                    if (!serviceResourceToThreads.containsKey(thread.HOT_ServiceResource__c)) {
                        serviceResourceToThreads.put(thread.HOT_ServiceResource__c, new List<Thread__c>());
                    }
                    serviceResourceToThreads.get(thread.HOT_ServiceResource__c).add(thread);
                }
            } else {
                //Samtaler med flere deltakere, må mappe ut ifht deltakere
                if (String.isBlank(thread.HOT_ParticipantIds__c)) {
                    continue;
                }

                for (String participantId : thread.HOT_ParticipantIds__c.split(',')) {
                    participantId = participantId.trim();
                    if (participantId == '') {
                        continue;
                    }

                    Id participantUserId = (Id) participantId;

                    if (!interpretersOnThreadMap.containsKey(participantUserId)) {
                        interpretersOnThreadMap.put(participantUserId, new List<Thread__c>());
                    }
                    interpretersOnThreadMap.get(participantUserId).add(thread);
                }
            }
        }
        //Finner hvem som har sendt siste melding i hver tråd
        Map<Id, Id> threadToLastSender = getLastMessageSenderPerThread(threadIds);
        //Finner rollen ifht oppdraget/bestillingen til den som har sendt siste melding i hver tråd
        Map<Id, String> threadToSenderRole = HOT_ThreadParticipants.getUserSenderRoleInThread(
            threadList,
            threadToLastSender
        );

        Set<Id> participantUserIds = interpretersOnThreadMap.keySet();
        Set<Id> serviceResourceIdsSet = serviceResourceToThreads.keySet();
        Set<Id> accountIdsSet = accountToThreads.keySet();

        List<ServiceResource> allRelevantServiceResources = [
            SELECT
                Id,
                RelatedRecordId,
                AccountId,
                HOT_MobilePhone__c,
                HOT_NotificationChannel__c,
                HOT_IsEmployedInterpreter__c,
                HOT_IsFreelanceInterpreter__c
            FROM ServiceResource
            WHERE RelatedRecordId IN :participantUserIds OR Id IN :serviceResourceIdsSet OR AccountId IN :accountIdsSet
        ];

        Map<Id, ServiceResource> allRelevantServiceResourcesMap = new Map<Id, ServiceResource>();
        Map<Id, List<Thread__c>> serviceResourceToThreadsMap = new Map<Id, List<Thread__c>>();

        for (ServiceResource sr : allRelevantServiceResources) {
            allRelevantServiceResourcesMap.put(sr.Id, sr);

            List<Thread__c> threadsForSR = new List<Thread__c>();

            if (sr.RelatedRecordId != null && interpretersOnThreadMap.containsKey(sr.RelatedRecordId)) {
                threadsForSR.addAll(interpretersOnThreadMap.get(sr.RelatedRecordId));
            }

            if (serviceResourceToThreads.containsKey(sr.Id)) {
                threadsForSR.addAll(serviceResourceToThreads.get(sr.Id));
            }

            if (sr.AccountId != null && accountToThreads.containsKey(sr.AccountId)) {
                threadsForSR.addAll(accountToThreads.get(sr.AccountId));
            }

            if (!threadsForSR.isEmpty()) {
                serviceResourceToThreadsMap.put(sr.Id, threadsForSR);
            }
        }

        List<HOT_Notification__c> notificationList = new List<HOT_Notification__c>();
        Map<ServiceResource, List<Thread__c>> serviceResourceToThreadMapSMS = new Map<ServiceResource, List<Thread__c>>();

        for (Id serviceResourceId : serviceResourceToThreadsMap.keySet()) {
            ServiceResource sr = allRelevantServiceResourcesMap.get(serviceResourceId);
            if (sr == null) {
                continue;
            }

            Id userId = sr.RelatedRecordId;
            Boolean isFreelance = sr.HOT_IsFreelanceInterpreter__c;
            String notificationChannel = sr.HOT_NotificationChannel__c;
            Set<Id> processedThreadIds = new Set<Id>();

            for (Thread__c thread : serviceResourceToThreadsMap.get(serviceResourceId)) {
                if (processedThreadIds.contains(thread.Id)) {
                    continue;
                }
                processedThreadIds.add(thread.Id);

                if (userId != null && threadToLastSender.get(thread.Id) == userId) {
                    continue;
                }

                String channel = notificationChannel != null && notificationChannel.contains('Push')
                    ? 'Push-varsel i appen'
                    : 'SMS';
                //Bygger varsel innhold basert på kanal
                MessageContent content = getContentForChannel(threadToSenderRole.get(thread.Id), channel, true);
                //Oppretter varsel record for innsetting i til varslingsliste
                notificationList.add(
                    newMessageNotification(
                        null,
                        sr.Id,
                        thread,
                        'threadInterpreter',
                        channel,
                        content.title,
                        content.body
                    )
                );

                if (channel == 'Push-varsel i appen') {
                    if (userId != null) {
                        HOT_UserNotificationService.newMessageNotification(
                            notificationType,
                            thread,
                            isFreelance,
                            false,
                            new Set<String>{ userId },
                            content.title,
                            content.body
                        );
                    }
                } else {
                    if (!serviceResourceToThreadMapSMS.containsKey(sr)) {
                        serviceResourceToThreadMapSMS.put(sr, new List<Thread__c>());
                    }
                    serviceResourceToThreadMapSMS.get(sr).add(thread);
                }
            }
        }

        insertNotifications(notificationList);
        HOT_ReminderSMSService.sendSMSOnNewMessageInterpreter(serviceResourceToThreadMapSMS, threadToSenderRole);
    }

    public static CustomNotificationType getCustomNotificationType(String devName) {
        if (notificationTypeCache == null) {
            notificationTypeCache = new Map<String, CustomNotificationType>();
            List<CustomNotificationType> types = [
                SELECT Id, DeveloperName
                FROM CustomNotificationType
                WHERE DeveloperName IN ('HOT_NotifyDispatcher', 'HOT_NotifyUser', 'HOT_NotifyInterpreter')
            ];

            for (CustomNotificationType typeRecord : types) {
                notificationTypeCache.put(typeRecord.DeveloperName, typeRecord);
            }
        }

        return notificationTypeCache.get(devName);
    }
}
