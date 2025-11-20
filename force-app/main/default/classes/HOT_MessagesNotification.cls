public without sharing class HOT_MessagesNotification {
    //Cacher
    private static Map<String, CustomNotificationType> notificationTypeCache;

    //Felles metode som oppretter en ny meldingsnotifikasjon til varsel liste.
    private static HOT_Notification__c newMessageNotification(
        Id accountId,
        Id serviceResourceId,
        Thread__c thread,
        String type,
        String channel
    ) {
        HOT_Notification__c notification = new HOT_Notification__c();
        notification.HOT_Account__c = accountId;
        notification.HOT_ServiceResource__c = serviceResourceId;
        notification.HOT_NotificationChannel__c = channel;
        notification.HOT_Subject__c = 'Ny melding fra Tolketjenesten';
        notification.HOT_NotificationText__c = 'Du har fått en melding fra Tolketjenesten.';
        notification.HOT_RelatedObject__c = thread.Id;
        notification.HOT_RelatedObjectType__c = type;
        return notification;
    }

    private static void insertNotifications(List<HOT_Notification__c> notifications) {
        try {
            HOT_NotificationCentreController.createNotification(notifications);
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publish();
        }
    }
    //Varsel til formidler
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
        Map<Id, ID> groupByQueue = HOT_NotificationHandler.getGroupIdByQueueId(ownerIds);

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
                CRM_Thread_Type__c,
                HOT_ParticipantIds__c,
                HOT_IsEmployeeThread__c,
                LastModifiedById,
                HOT_ServiceResource__c,
                HOT_ServiceResource__r.HOT_MobilePhone__c,
                CRM_Account__r.INT_KrrMobilePhone__c,
                CRM_Account__r.CRM_Person__r.INT_KrrMobilePhone__c,
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

        for (Thread__c t : threadList) {
            threadIds.add(t.Id);
            if (
                t.CRM_Account__c != null &&
                t.CRM_Account__r.CRM_Person__r.HOT_IsReservationAgainstNotifications__c == false
            ) {
                //Skal kun sende varsel til de som ikke har reservert seg mot varsler
                accountIds.add(t.CRM_Account__c);
            }
        }
        //Mapper account til user
        Map<Id, Id> accountToUserId = new Map<Id, Id>();

        for (User u : [SELECT Id, AccountId FROM User WHERE AccountId IN :accountIds]) {
            accountToUserId.put(u.AccountId, u.Id);
        }
        //Lager varslingsliste til insetting senere
        List<HOT_Notification__c> notificationList = new List<HOT_Notification__c>();

        CustomNotificationType notificationType = getCustomNotificationType('HOT_NotifyUser');
        //Henter userId til siste som sendte melding i tråder
        Map<Id, Id> threadToLastSender = getLastMessageSenderPerThread(threadIds);
        Set<Id> threadIdsToSMSNotification = new Set<Id>();

        for (Thread__c thread : threadList) {
            Set<String> recipients = new Set<String>();

            Id accountId = thread.CRM_Account__c;
            Id userId = accountToUserId.get(accountId);
            String notificationChannel = thread.CRM_Account__r.CRM_Person__r.HOT_NotificationChannel__c;
            Id lastSender = threadToLastSender.get(thread.Id);

            //Ikke varsle hvis brukeren selv er siste avsender
            if (userId == null || userId == lastSender) {
                continue;
            }

            recipients.add(userId);
            if (notificationChannel.contains('Push')) {
                //Lager notifikasjon til liste
                notificationList.add(
                    newMessageNotification(
                        thread.CRM_Account__c,
                        null, // ingen service resource
                        thread,
                        'threadUser',
                        'Push-varsel i appen'
                    )
                );
                //Sender ut pushvarsel til appbruker
                HOT_UserNotificationService.newMessageNotification(notificationType, thread, false, recipients);
            } else {
                //Ellers sendes det ut sms til bruker
                //Lager notifikasjon til liste
                notificationList.add(newMessageNotification(thread.CRM_Account__c, null, thread, 'threadUser', 'SMS'));
                threadIdsToSMSNotification.add(thread.Id);
            }
        }
        //Sender SMS
        HOT_ReminderSMSService.sendSMSOnNewMessage(threadIdsToSMSNotification);
        //Innsetter notifikasjonsrecord til varslingsliste
        insertNotifications(notificationList);
    }
    public static Map<Id, Id> getLastMessageSenderPerThread(Set<Id> threadIds) {
        Map<Id, Id> result = new Map<Id, Id>();

        if (threadIds.isEmpty())
            return result;

        //Henter siste melding per tråd
        List<Message__c> messages = [
            SELECT Id, CRM_Thread__c, CreatedById, CreatedDate
            FROM Message__c
            WHERE CRM_Thread__c IN :threadIds
            ORDER BY CRM_Thread__c, CreatedDate DESC
        ];

        for (Message__c msg : messages) {
            // Legg kun inn første gangen vi ser en tråd = siste melding
            if (!result.containsKey(msg.CRM_Thread__c)) {
                result.put(msg.CRM_Thread__c, msg.CreatedById);
            }
        }

        return result;
    }

    public static void NotifyInterpreter(List<Thread__c> threadList) {
        CustomNotificationType notificationType = getCustomNotificationType('HOT_NotifyInterpreter');
        //mapping for tolketråder hvor det kun er én-til-én (tolk og formidler, og tolk-ressurskontor)
        Map<Id, List<Thread__c>> accountToThreads = new Map<Id, List<Thread__c>>();
        Map<Id, List<Thread__c>> serviceResourceToThreads = new Map<Id, List<Thread__c>>();

        // participant-tråder (bruker-tolk og medtolk tråder)
        Map<Id, List<Thread__c>> interpretersOnThreadMap = new Map<Id, List<Thread__c>>();
        Set<Id> threadIds = new Set<Id>();
        for (Thread__c thread : threadList) {
            threadIds.add(thread.Id);
            if (
                thread.CRM_Thread_Type__c == 'HOT_TOLK-FORMIDLER' ||
                thread.CRM_Thread_Type__c == 'HOT_TOLK-RESSURSKONTOR'
            ) {
                // ===== account mapping =====
                if (thread.CRM_Account__c != null) {
                    if (!accountToThreads.containsKey(thread.CRM_Account__c)) {
                        accountToThreads.put(thread.CRM_Account__c, new List<Thread__c>{ thread });
                    } else {
                        accountToThreads.get(thread.CRM_Account__c).add(thread);
                    }
                }

                // ===== service resource mapping =====
                if (thread.HOT_ServiceResource__c != null) {
                    if (!serviceResourceToThreads.containsKey(thread.HOT_ServiceResource__c)) {
                        serviceResourceToThreads.put(thread.HOT_ServiceResource__c, new List<Thread__c>{ thread });
                    } else {
                        serviceResourceToThreads.get(thread.HOT_ServiceResource__c).add(thread);
                    }
                }
            } else {
                String[] participantIds = thread.HOT_ParticipantIds__c.split(',');

                for (String participantId : participantIds) {
                    participantId = participantId.trim();

                    if (participantId == '') {
                        continue;
                    }
                    if (interpretersOnThreadMap.containsKey(participantId)) {
                        interpretersOnThreadMap.get(participantId).add(thread);
                    } else {
                        interpretersOnThreadMap.put(participantId, new List<Thread__c>{ thread });
                    }
                }
            }
        }
        //Henter userId til siste som sendte melding i tråder
        Map<Id, Id> threadToLastSender = getLastMessageSenderPerThread(threadIds);

        // Sett opp mappings
        Map<Id, List<Thread__c>> serviceResourceToThreadsMap = new Map<Id, List<Thread__c>>();

        // Skal nå finne alle ServiceResource som er relevante
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
        // Mapper hver ServiceResource til de trådene den tilhører
        for (ServiceResource sr : allRelevantServiceResources) {
            allRelevantServiceResourcesMap.put(sr.Id, sr);
            List<Thread__c> threadsForSR = new List<Thread__c>();

            // 1) Hvis ServiceResource er en ansatt tolk fra participant-tråder
            if (sr.RelatedRecordId != null && interpretersOnThreadMap.containsKey(sr.RelatedRecordId)) {
                threadsForSR.addAll(interpretersOnThreadMap.get(sr.RelatedRecordId));
            }

            // 2) Hvis ServiceResource er direkte koblet til tråd (serviceResourceToThreads)
            if (sr.Id != null && serviceResourceToThreads.containsKey(sr.Id)) {
                threadsForSR.addAll(serviceResourceToThreads.get(sr.Id));
            }

            // 3) Hvis ServiceResource tilhører en Account (accountToThreads)
            if (sr.AccountId != null && accountToThreads.containsKey(sr.AccountId)) {
                threadsForSR.addAll(accountToThreads.get(sr.AccountId));
            }

            if (!threadsForSR.isEmpty()) {
                serviceResourceToThreadsMap.put(sr.Id, threadsForSR);
            }
        }

        //LAGER VARSLINGS LISTE TIL INSETTING SENERE
        List<HOT_Notification__c> notificationList = new List<HOT_Notification__c>();
        //ANSATTOLKER VARSEL

        Map<ServiceResource, List<Thread__c>> serviceResourceToThreadMapSMS = new Map<ServiceResource, List<Thread__c>>();
        for (Id serviceResourceId : serviceResourceToThreadsMap.keySet()) {
            ServiceResource sr = allRelevantServiceResourcesMap.get(serviceResourceId);
            if (sr == null)
                continue;

            Id userId = sr.RelatedRecordId;
            Id accountId = sr.AccountId;
            String notificationChannel = sr.HOT_NotificationChannel__c;
            Boolean isFreelance = sr.HOT_IsFreelanceInterpreter__c;

            for (Thread__c thread : serviceResourceToThreadsMap.get(serviceResourceId)) {
                //Hopp over hvis siste avsender er samme som ServiceResource sin user
                if (userId != null && threadToLastSender.get(thread.Id) == userId) {
                    continue;
                }
                if (notificationChannel.contains('Push')) {
                    notificationList.add(
                        newMessageNotification(
                            null, // no accountId
                            sr.Id, // service resource
                            thread,
                            'threadInterpreter',
                            'Push-varsel i appen'
                        )
                    );

                    HOT_UserNotificationService.newMessageNotification(
                        notificationType,
                        thread,
                        isFreelance,
                        new Set<String>{ userId }
                    );
                } else {
                    notificationList.add(newMessageNotification(null, sr.Id, thread, 'threadInterpreter', 'SMS'));

                    // Legg til i map-en for SMS
                    if (!serviceResourceToThreadMapSMS.containsKey(sr)) {
                        serviceResourceToThreadMapSMS.put(sr, new List<Thread__c>{ thread });
                    } else {
                        serviceResourceToThreadMapSMS.get(sr).add(thread);
                    }
                }
            }
        }
        //Innsetter notifikasjonsrecord for varslingsliste
        insertNotifications(notificationList);
        HOT_ReminderSMSService.sendSMSOnNewMessageInterpreter(serviceResourceToThreadMapSMS);
    }

    public static CustomNotificationType getCustomNotificationType(String devName) {
        //Cache ved første bruk
        if (notificationTypeCache == null) {
            notificationTypeCache = new Map<String, CustomNotificationType>();
            List<CustomNotificationType> types = [
                SELECT Id, DeveloperName
                FROM CustomNotificationType
                WHERE DeveloperName IN ('HOT_NotifyDispatcher', 'HOT_NotifyUser', 'HOT_NotifyInterpreter')
            ];

            for (CustomNotificationType t : types) {
                notificationTypeCache.put(t.DeveloperName, t);
            }
        }

        return notificationTypeCache.get(devName);
    }
}
