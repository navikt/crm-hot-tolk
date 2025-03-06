public class HOT_RequestRoutingHandler extends MyTriggers {
    public override void onBeforeInsert() {
        // Setter feltene Account__c og Person__c (og Company__c om det eksisterer) når den blir opprettet av en Community-bruker
        //Feltet Orderer__c settes automatisk i skjemaet.
        List<String> idents = new List<String>();
        List<HOT_Request__c> accountConnectedRequests = new List<HOT_Request__c>();
        List<HOT_Request__c> imageInterpreterRequests = new List<HOT_Request__c>();
        for (HOT_Request__c request : (List<HOT_Request__c>) records) {
            if (request.Type__c == 'ImageInterpreter') {
                imageInterpreterRequests.add(request);
            } else {
                accountConnectedRequests.add(request);
                if (!String.isBlank(request.UserPersonNumber__c)) {
                    idents.add(request.UserPersonNumber__c.replaceAll(' ', ''));
                }
                if (!String.isBlank(request.OrganizationNumber__c)) {
                    idents.add(request.OrganizationNumber__c.replaceAll(' ', ''));
                }
                if (!String.isBlank(request.Account__c)) {
                    idents.add(request.Account__c);
                }
                if (!String.isBlank(request.UserPhone__c)) {
                    idents = addUserPhoneVariations(idents, request.UserPhone__c);
                }
            }
        }
        if (accountConnectedRequests.size() > 0) {
            routeAccountConnectedRequests(accountConnectedRequests, idents);
        }
        if (imageInterpreterRequests.size() > 0) {
            routeToCreatedByQueue(imageInterpreterRequests);
        }
    }

    private static List<String> addUserPhoneVariations(List<String> idents, String phoneNumber) {
        idents.add(phoneNumber);
        idents.add('+47' + phoneNumber);
        idents.add('0047' + phoneNumber);
        return idents;
    }

    public static void routeToCreatedByQueue(List<HOT_Request__c> imageInterpreterRequests) {
        List<Id> creatorIds = new List<Id>();
        for (HOT_Request__c req : imageInterpreterRequests) {
            creatorIds.add(req.OwnerId);
        }
        Map<Id, User> users = new Map<Id, User>([SELECT Id, Department FROM User WHERE Id IN :creatorIds]);
        Map<Id, String> departmentNameByUser = HOT_GroupMembersService.getDepartmentNameByUser(users);
        Map<String, String> queueNamesByDepartment = HOT_GroupMembersService.getGroupNames(null, null, 'queue');
        List<Group> queues = [
            SELECT Id, DeveloperName
            FROM Group
            WHERE DeveloperName IN :queueNamesByDepartment.values()
        ];
        Map<String, Id> queueIdByDeveloperName = new Map<String, Id>();
        for (Group queue : queues) {
            queueIdByDeveloperName.put(queue.DeveloperName, queue.Id);
        }
        Group adminGroup = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'HOT_Tolk_Admin' LIMIT 1];
        for (HOT_Request__c req : imageInterpreterRequests) {
            if (
                departmentNameByUser.get(req.OwnerId) != null &&
                queueNamesByDepartment.get(departmentNameByUser.get(req.OwnerId)) != null &&
                queueIdByDeveloperName.get(queueNamesByDepartment.get(departmentNameByUser.get(req.OwnerId))) != null
            ) {
                req.OwnerId = queueIdByDeveloperName.get(
                    queueNamesByDepartment.get(departmentNameByUser.get(req.OwnerId))
                );
            } else {
                req.OwnerId = adminGroup.Id;
            }
        }
    }

    public void routeAccountConnectedRequests(List<HOT_Request__c> accountConnectedRequests, List<String> idents) {
        User currentUser = [SELECT Id, AccountId, Account.CRM_Person__c FROM User WHERE Id = :UserInfo.getUserId()];
        List<Account> accounts = [
            SELECT
                Id,
                Name,
                INT_PersonIdent__c,
                CRM_Person__c,
                INT_OrganizationNumber__c,
                INT_KrrMobilePhone__c,
                CRM_Person__r.HOT_MobilePhoneStripped__c
            FROM Account
            WHERE
                INT_PersonIdent__c IN :idents
                OR INT_OrganizationNumber__c IN :idents
                OR INT_KrrMobilePhone__c IN :idents
                OR Id IN :idents
        ];

        Map<String, Account> personIdentToAccount = new Map<String, Account>();
        Map<String, Account> orgNumberToAccount = new Map<String, Account>();
        Map<String, Account> phoneNumberToAccount = new Map<String, Account>();
        Map<Id, Account> idToAccount = new Map<Id, Account>();

        for (Account account : accounts) {
            if (account.INT_PersonIdent__c != null) {
                personIdentToAccount.put(account.INT_PersonIdent__c, account);
            }
            if (account.INT_OrganizationNumber__c != null) {
                orgNumberToAccount.put(account.INT_OrganizationNumber__c, account);
            }
            if (account.CRM_Person__r.HOT_MobilePhoneStripped__c != null) {
                phoneNumberToAccount.put(account.CRM_Person__r.HOT_MobilePhoneStripped__c, account);
            }
            idToAccount.put(account.Id, account);
        }

        for (HOT_Request__c request : accountConnectedRequests) {
            if (request.Account__c == null && currentUser.AccountId != null) {
                //Sets account and Person fields if UserPersonNumber__c is filled out in form
                if (
                    request.UserPersonNumber__c != null &&
                    personIdentToAccount.get(request.UserPersonNumber__c) != null
                ) {
                    request.Account__c = personIdentToAccount.get(request.UserPersonNumber__c).Id;
                    request.Person__c = personIdentToAccount.get(request.UserPersonNumber__c).CRM_Person__c;
                } else if (request.UserPhone__c != null && phoneNumberToAccount.get(request.UserPhone__c) != null) {
                    request.Account__c = phoneNumberToAccount.get(request.UserPhone__c).Id;
                    request.Person__c = phoneNumberToAccount.get(request.UserPhone__c).CRM_Person__c;
                } else if (request.Type__c == 'Me') {
                    //Checks if user is putting in request for interpreter for itself
                    //Sets account and Person Fields if it should be connected to THIS.User
                    request.Account__c = currentUser.AccountId;
                    request.Person__c = currentUser.Account.CRM_Person__c;
                }
                //Sets Company-lookup if orgNumber is filled in
                if (
                    request.OrganizationNumber__c != null &&
                    orgNumberToAccount.get(request.OrganizationNumber__c) != null
                ) {
                    request.Company__c = orgNumberToAccount.get(request.OrganizationNumber__c).Id;
                }
            } else if (request.Account__c != null && idToAccount.get(request.Account__c) != null) {
                // Sets Person to the same as Account
                request.Person__c = idToAccount.get(request.Account__c).CRM_Person__c;
            }
        }

        // Tildeler til kø basert på region
        Map<Integer, ApexSharingRuleWrapper> ruleByByRequestId = RecordOwnerService.getQueuesAndNavUnits(
            getSobjectWrappers(),
            'HOT_Request__c'
        );
        //bildetolk requestMap
        Integer i = 0;
        Group adminGroup = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'HOT_Tolk_Admin' LIMIT 1];
        for (HOT_Request__c request : accountConnectedRequests) {
            ApexSharingRuleWrapper rule = ruleByByRequestId.get(i);
            if (rule == null) {
                request.OwnerId = adminGroup.Id;
            } else {
                request.OwnerId = rule.queueId;
                i++;
            }
        }
    }

    private List<SobjectWrapper> getSobjectWrappers() {
        Map<Id, SobjectWrapper> userInfoMap = getUserInfo();
        Map<Id, SobjectWrapper> companyInfoMap = getCompanyInfo();
        Map<Id, SobjectWrapper> ordererInfoMap = getOrdererInfo();
        List<SobjectWrapper> wrappers = new List<SobjectWrapper>();
        Integer recordIndex = 0;
        for (HOT_Request__c request : (List<HOT_Request__c>) records) {
            //If the request is connected to a user (Account__c)
            if (request.Account__c != null && userInfoMap.containsKey(request.Account__c)) {
                SobjectWrapper userInfo = userInfoMap.get(request.Account__c);
                String region = null;
                String municipality = null;
                if (userInfo != null) {
                    region = userInfo.Region;
                    municipality = userInfo.Municipality;
                }
                wrappers.add(new SobjectWrapper(recordIndex, municipality, region));
                recordIndex++;
            } else if (request.Company__c != null && companyInfoMap.containsKey(request.Company__c)) {
                //If the request is connected to a company (Company__c)
                SobjectWrapper companyInfo = companyInfoMap.get(request.Company__c);
                String region = null;
                String municipality = null;
                if (companyInfo != null) {
                    region = companyInfo.Region;
                    municipality = companyInfo.Municipality;
                }
                wrappers.add(new SobjectWrapper(recordIndex, municipality, region));
                recordIndex++;
            } else {
                //If there was an error connecting the request to a user or company, the request should be sent to the orderers region.
                SobjectWrapper ordererInfo = ordererInfoMap.get(request.Orderer__c);
                String region = null;
                String municipality = null;
                if (ordererInfo != null) {
                    region = ordererInfo.Region;
                    municipality = ordererInfo.Municipality;
                }
                wrappers.add(new SobjectWrapper(recordIndex, municipality, region));
                recordIndex++;
            }
        }
        return wrappers;
    }

    private Map<Id, SobjectWrapper> getUserInfo() {
        Set<Id> accountIds = new Set<Id>();
        for (HOT_Request__c request : (List<HOT_Request__c>) records) {
            if (request.Account__c != null) {
                accountIds.add(request.Account__c);
            }
        }
        Map<Id, SobjectWrapper> wrapperByAccountId = new Map<Id, SobjectWrapper>();
        for (Person__c per : getPersons()) {
            if (accountIds.contains(per.CRM_Account__c)) {
                SobjectWrapper wrapper = new SobjectWrapper();
                wrapper.Region = per.INT_RegionNumber__c;
                wrapper.Municipality = per.INT_MunicipalityNumber__c;
                wrapperByAccountId.put(per.CRM_Account__c, wrapper);
            }
        }

        return wrapperByAccountId;
    }

    private Map<Id, SobjectWrapper> getOrdererInfo() {
        Set<Id> accountIds = new Set<Id>();
        for (HOT_Request__c request : (List<HOT_Request__c>) records) {
            if (request.Orderer__c != null) {
                accountIds.add(request.Orderer__c);
            }
        }
        Map<Id, SobjectWrapper> wrapperByAccountId = new Map<Id, SobjectWrapper>();
        for (Person__c per : this.getPersons()) {
            if (accountIds.contains(per.CRM_Account__c)) {
                SobjectWrapper wrapper = new SobjectWrapper();
                wrapper.Region = per.INT_RegionNumber__c;
                wrapper.Municipality = per.INT_MunicipalityNumber__c;
                wrapperByAccountId.put(per.CRM_Account__c, wrapper);
            }
        }

        return wrapperByAccountId;
    }

    private List<Person__c> persons;
    private List<Person__c> getPersons() {
        if (this.persons == null) {
            Set<Id> accountIds = new Set<Id>();
            for (HOT_Request__c request : (List<HOT_Request__c>) records) {
                if (request.Account__c != null) {
                    accountIds.add(request.Account__c);
                } else {
                    accountIds.add(request.Orderer__c);
                }
            }
            this.persons = [
                SELECT Id, CRM_Account__c, INT_RegionNumber__c, INT_MunicipalityNumber__c
                FROM Person__c
                WHERE CRM_Account__c IN :accountIds
            ];
        }
        return this.persons;
    }

    private Map<Id, SobjectWrapper> getCompanyInfo() {
        Set<Id> accountIds = new Set<Id>();
        for (HOT_Request__c request : (List<HOT_Request__c>) records) {
            if (request.Company__c != null) {
                accountIds.add(request.Company__c);
            }
        }
        Map<Id, SobjectWrapper> wrapperByAccountId = new Map<Id, SobjectWrapper>();
        for (Account company : [
            SELECT Id, INT_RegionNumber__c, INT_MunicipalityNumber__c
            FROM Account
            WHERE Id IN :accountIds
        ]) {
            SobjectWrapper wrapper = new SobjectWrapper();
            wrapper.Region = company.INT_RegionNumber__c;
            wrapper.Municipality = company.INT_MunicipalityNumber__c;
            wrapperByAccountId.put(company.Id, wrapper);
        }

        return wrapperByAccountId;
    }
}
