public without sharing class HOT_NotificationHandler {
    public static void sendNotification(Messaging.CustomNotification notification, Set<String> recipients) {
        try {
            notification.send(recipients);
        } catch (Exception e) {
            System.debug('Problem sending notification: ' + e.getMessage());
        }
    }
    public static Messaging.CustomNotification prepareNotification(
        String title,
        String body,
        Id notificationTypeId,
        Id targetId
    ) {
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setTitle(title);
        notification.setBody(body);
        notification.setNotificationTypeId(notificationTypeId);
        notification.setTargetId(targetId);

        return notification;
    }

    public static Map<Id, Id> getGroupIdByQueueId(List<Id> queueIds) {
        List<Group> queues = [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' AND Id IN :queueIds];
        Map<Id, String> groupNamesByQueueId = new Map<Id, String>();
        for (Group queue : queues) {
            String groupName = '';
            for (String substr : queue.DeveloperName.split('_')) {
                if (substr == 'queue') {
                    groupName += 'group';
                } else {
                    groupName += substr;
                }
                groupName += '_';
            }
            groupName.removeEnd('_');
            groupNamesByQueueId.put(queue.Id, groupName);
        }
        List<Group> groups = [
            SELECT Id, DeveloperName
            FROM Group
            WHERE Type = 'Group' AND DeveloperName IN :groupNamesByQueueId.values()
        ];
        Map<String, Id> groupByDeveloperName = new Map<String, Id>();
        for (Group grp : groups) {
            groupByDeveloperName.put(grp.DeveloperName, grp.Id);
        }
        Map<Id, Id> groupByQueue = new Map<Id, Id>();
        for (Group queue : queues) {
            groupByQueue.put(queue.Id, groupByDeveloperName.get(groupNamesByQueueId.get(queue.Id)));
        }
        return groupByQueue;
    }
}
