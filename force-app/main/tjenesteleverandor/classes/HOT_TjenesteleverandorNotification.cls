public with sharing class HOT_TjenesteleverandorNotification {
    public String notificationTitle { get; set; }
    public String notificationMessage { get; set; }
    public String relatedRecordId { get; set; }
    public String relatedRecordType { get; set; }
    public String recipientId { get; set; }

    public HOT_TjenesteleverandorNotification(
        String notificationTitle,
        String notificationMessage,
        String relatedRecordId,
        String relatedRecordType,
        String recipientId
    ) {
        this.notificationTitle = notificationTitle;
        this.notificationMessage = notificationMessage;
        this.relatedRecordId = relatedRecordId;
        this.relatedRecordType = relatedRecordType;
        this.recipientId = recipientId;
    }

    public void sendNotification() {
        HOT_Notification__c notification = new HOT_Notification__c();
        notification.Tjenesteleverandor__c = this.recipientId;
        notification.HOT_Subject__c = this.notificationTitle;
        notification.HOT_NotificationText__c = this.notificationMessage;
        notification.HOT_RelatedObject__c = this.relatedRecordId;
        notification.HOT_RelatedObjectType__c = this.relatedRecordType;
        insert notification;
    }
}
