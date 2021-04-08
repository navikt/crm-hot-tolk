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
            String groupName = 'HOT_group_' + queue.DeveloperName.split('_')[1] + '_formidler';
            groupNamesByQueueId.put(queue.Id, groupName);
        }
        List<Group> groups = [
            SELECT Id, DeveloperName
            FROM Group
            WHERE Type = 'Regular' AND DeveloperName IN :groupNamesByQueueId.values()
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

    public static Map<Id, Set<String>> getUsersInGroup(List<Id> groupIds) {
        Map<Id, Set<String>> usersByGroupId = new Map<Id, Set<String>>();
        List<GroupMember> groupMembers = [SELECT GroupId, UserOrGroupId FROM GroupMember WHERE GroupId IN :groupIds];
        for (GroupMember groupMember : groupMembers) {
            if (groupMember.UserOrGroupId.getSObjectType().getDescribe().getName() == 'User') {
                if (usersByGroupId.get(groupMember.GroupId) == null) {
                    Set<String> users = new Set<String>();
                    users.add(groupMember.UserOrGroupId);
                    usersByGroupId.put(groupMember.GroupId, users);
                } else {
                    usersByGroupId.get(groupMember.GroupId).add(groupMember.UserOrGroupId);
                }
            }
        }
        return usersByGroupId;
    }
}
