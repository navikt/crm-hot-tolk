List<HOT_Request__c> requestsToUpdate = [
    SELECT Id, Status__c 
    FROM HOT_Request__c 
    WHERE Subject__c = 'Forespørsel 0' 
    LIMIT 1
];

if (!requestsToUpdate.isEmpty()) {
    HOT_Request__c req = requestsToUpdate[0];
    req.Status__c = 'Godkjent';
    update req;
    System.debug('Request status updated to Godkjent: ' + req);
}