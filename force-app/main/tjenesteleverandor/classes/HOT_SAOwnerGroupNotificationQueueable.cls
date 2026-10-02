public without sharing class HOT_SAOwnerGroupNotificationQueueable implements Queueable {
    @TestVisible
    private static final Integer CHUNK_SIZE = 10;

    private List<HOT_SAOwnerGroupNotification.WorkItem> workItems;

    public HOT_SAOwnerGroupNotificationQueueable(List<HOT_SAOwnerGroupNotification.WorkItem> workItems) {
        this.workItems = workItems == null ? new List<HOT_SAOwnerGroupNotification.WorkItem>() : workItems;
    }

    public void execute(QueueableContext context) {
        List<HOT_SAOwnerGroupNotification.WorkItem> currentChunk = firstChunk(workItems);
        List<HOT_SAOwnerGroupNotification.WorkItem> remainingWorkItems = remainingItems(workItems);

        try {
            new HOT_SAOwnerGroupNotificationService().process(currentChunk);
        } catch (Exception exceptionThrown) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(exceptionThrown, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
        }

        // Queueable Apex permits one child job, so each job processes one bounded chunk and chains the remainder.
        if (!remainingWorkItems.isEmpty()) {
            System.enqueueJob(new HOT_SAOwnerGroupNotificationQueueable(remainingWorkItems));
        }
    }

    @TestVisible
    private static List<HOT_SAOwnerGroupNotification.WorkItem> firstChunk(
        List<HOT_SAOwnerGroupNotification.WorkItem> allWorkItems
    ) {
        List<HOT_SAOwnerGroupNotification.WorkItem> chunk = new List<HOT_SAOwnerGroupNotification.WorkItem>();
        if (allWorkItems == null) {
            return chunk;
        }
        Integer chunkEnd = allWorkItems.size() < CHUNK_SIZE ? allWorkItems.size() : CHUNK_SIZE;
        for (Integer index = 0; index < chunkEnd; index++) {
            chunk.add(allWorkItems[index]);
        }
        return chunk;
    }

    @TestVisible
    private static List<HOT_SAOwnerGroupNotification.WorkItem> remainingItems(
        List<HOT_SAOwnerGroupNotification.WorkItem> allWorkItems
    ) {
        List<HOT_SAOwnerGroupNotification.WorkItem> remaining = new List<HOT_SAOwnerGroupNotification.WorkItem>();
        if (allWorkItems == null) {
            return remaining;
        }
        for (Integer index = CHUNK_SIZE; index < allWorkItems.size(); index++) {
            remaining.add(allWorkItems[index]);
        }
        return remaining;
    }
}
