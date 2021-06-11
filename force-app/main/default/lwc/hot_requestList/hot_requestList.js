import { LightningElement, wire, track, api } from 'lwc';
import getRequestList from '@salesforce/apex/HOT_RequestListContoller.getRequestList';
import { updateRecord } from 'lightning/uiRecordApi';
import STATUS from '@salesforce/schema/HOT_Request__c.Status__c';
import REQUEST_ID from '@salesforce/schema/HOT_Request__c.Id';
import NOTIFY_DISPATCHER from '@salesforce/schema/HOT_Request__c.IsNotifyDispatcher__c';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';
import isProdFunction from '@salesforce/apex/GlobalCommunityHeaderFooterController.isProd';
import getAssignedResources from '@salesforce/apex/HOT_Utility.getAssignedResources';
import getPersonAccount from '@salesforce/apex/HOT_Utility.getPersonAccount';
import { sortList, getMobileSortingOptions } from 'c/sortController';
import { requestFieldLabels } from 'c/hot_fieldLabels';
import { formatRecord } from 'c/hot_recordDetails';

export default class RequestList extends NavigationMixin(LightningElement) {
    rerenderCallback() {
        refreshApex(this.wiredRequestsResult);
    }
    @track choices = [
        { name: 'Active', label: 'Aktiv', selected: true },
        { name: 'Completed', label: 'Ferdig' },
        { name: 'Canceled', label: 'Avlyst' },
        { name: 'No interpreter available', label: 'Ikke ledig tolk' },
        { name: 'Denied', label: 'Avslått' },
        { name: 'All', label: 'Alle mine bestillinger' },
        { name: 'Others', label: 'Alle bestillinger på vegne av andre' }
    ];
    @track selectDisable = false;
    @track selectMultiple = false;
    @track selectRequired = false;
    @track selectSize = 1;

    @track isProd;
    @track error;
    @wire(isProdFunction)
    wiredIsProd({ error, data }) {
        this.isProd = data;
    }
    @track userRecord = { AccountId: null };
    @wire(getPersonAccount)
    wiredGetRecord({ error, data }) {
        if (data) {
            this.userRecord.AccountId = data.AccountId;
        }
    }

    @track columns = [
        {
            label: 'Start tid',
            fieldName: 'StartTime__c',
            type: 'date',
            sortable: true,
            typeAttributes: {
                day: 'numeric',
                month: 'numeric',
                year: 'numeric',
                hour: '2-digit',
                minute: '2-digit',
                hour12: false
            }
        },
        {
            label: 'Slutt tid',
            fieldName: 'EndTime__c',
            type: 'date',
            sortable: true,
            typeAttributes: {
                day: 'numeric',
                month: 'numeric',
                year: 'numeric',
                hour: '2-digit',
                minute: '2-digit',
                hour12: false
            }
        },
        {
            label: 'Bestilling',
            fieldName: 'Name',
            type: 'text',
            sortable: true
        },
        {
            label: 'Oppmøtested',
            fieldName: 'MeetingStreet__c',
            type: 'text',
            sortable: true
        },
        {
            label: 'Tema',
            fieldName: 'Subject__c',
            type: 'text',
            sortable: true
        },
        {
            label: 'Serieoppdrag',
            fieldName: 'IsSerieoppdrag__c',
            type: 'boolean',
            sortable: true
        },
        {
            label: 'Status',
            fieldName: 'ExternalRequestStatus__c',
            type: 'text',
            sortable: true
        },
        {
            type: 'action',
            typeAttributes: { rowActions: this.getRowActions }
        }
    ];
    mobileColumns = [
        "'Start tid'",
        "'Slutt tid'",
        "'Bestilling'",
        "'Oppmøtested'",
        "'Tema'",
        "'Serieoppdrag'",
        "'Status'"
    ];

    getRowActions(row, doneCallback) {
        let actions = [];
        let tempEndDate = new Date(row['EndTime__c']);
        if (row['Orderer__c'] == row['TempAccountId__c']) {
            if (
                row['Status__c'] != 'Avlyst' &&
                row['Status__c'] != 'Dekket' &&
                row['Status__c'] != 'Delvis dekket' &&
                tempEndDate.getTime() > Date.now()
            ) {
                actions.push({ label: 'Avlys', name: 'delete' });
            }
            if (row['Status__c'] == 'Åpen') {
                actions.push({ label: 'Rediger', name: 'edit_order' });
            }
            actions.push({ label: 'Kopier', name: 'clone_order' });
        }

        actions.push({ label: 'Detaljer', name: 'details' });
        actions.push({ label: 'Se tidsplan', name: 'see_times' });

        doneCallback(actions);
    }

    @track rerender;
    @track requests;
    @track allRequests;
    @track allOrderedRequests;
    @track allMyRequests;
    @track error;
    wiredRequestsResult;

    @wire(getRequestList)
    async wiredRequest(result) {
        this.wiredRequestsResult = result;
        if (result.data) {
            this.allRequests = this.distributeRequests(result.data);
            this.filterRequests();
            this.showAllOrNot();
            this.error = undefined;
            var requestIds = [];
            for (var request of result.data) {
                requestIds.push(request.Id);
            }
            this.requestAssignedResources = await getAssignedResources({
                requestIds
            });
        } else if (result.error) {
            this.error = result.error;
            this.allRequests = undefined;
        }
    }

    distributeRequests(data) {
        this.allMyRequests = [];
        this.allOrderedRequests = [];
        for (let request of data) {
            if (request.Account__c == this.userRecord.AccountId) {
                this.allMyRequests.push(request);
            } else if (
                request.Orderer__c == this.userRecord.AccountId &&
                request.Account__c != this.userRecord.AccountId
            ) {
                this.allOrderedRequests.push(request);
            }
        }
        return this.isMyRequests ? this.allMyRequests : this.allOrderedRequests;
    }

    filterActiveRequests(tempRequests, i) {
        if (
            this.allRequests[i].ExternalRequestStatus__c == 'Åpen' ||
            this.allRequests[i].ExternalRequestStatus__c == 'Under behandling' ||
            this.allRequests[i].ExternalRequestStatus__c == 'Du har fått tolk' ||
            this.allRequests[i].ExternalRequestStatus__c == 'Serieoppdrag' ||
            this.allRequests[i].ExternalRequestStatus__c == 'Pågår'
        ) {
            tempRequests.push(this.allRequests[i]);
        }
    }

    @track picklistValue = 'Active';
    handlePicklist(event) {
        this.picklistValue = event.detail;
        if (this.picklistValue == 'Others') {
            this.currentChoiceOthers = true;
            this.handleRequestType(false);
        } else if (this.picklistValue == 'All') {
            this.currentChoiceOthers = false;
            this.handleRequestType(true);
        } else {
            this.currentChoiceOthers = false;
            this.handleRequestType(true);
        }
    }
    filterRequests() {
        this.showAll = false;
        var tempRequests = [];
        let pickListValue = this.picklistValue;
        for (var i = 0; i < this.allRequests.length; i++) {
            let status = this.allRequests[i].ExternalRequestStatus__c;
            if (pickListValue == 'Active') {
                this.filterActiveRequests(tempRequests, i);
            } else if (status == 'Avlyst' && pickListValue == 'Canceled') {
                tempRequests.push(this.allRequests[i]);
            } else if (status == 'Ferdig' && pickListValue == 'Completed') {
                tempRequests.push(this.allRequests[i]);
            } else if (status == 'Ikke ledig tolk' && pickListValue == 'No interpreter available') {
                tempRequests.push(this.allRequests[i]);
            } else if (status == 'Avslått' && pickListValue == 'Denied') {
                tempRequests.push(this.allRequests[i]);
            } else if (pickListValue == 'All') {
                this.showAll = true;
                tempRequests = this.allMyRequests;
            } else if (pickListValue == 'Others') {
                tempRequests = this.allOrderedRequests;
            }
        }
        this.requests = tempRequests;
    }

    @track isMyRequests = true;
    @track previousChoiceOthers = false;
    @track currentChoiceOthers = false;
    handleRequestType(isMyReq) {
        this.filterRequests();
        this.showAllOrNot();
        let tempColumns = [...this.columns];
        let tempMobileColumns = [...this.mobileColumns];
        this.isMyRequests = isMyReq;

        if (this.isMyRequests && this.previousChoiceOthers) {
            tempColumns.shift();
            tempMobileColumns.shift();
            tempMobileColumns.push("''");
            this.previousChoiceOthers = false;
        } else if (this.currentChoiceOthers && !this.previousChoiceOthers) {
            tempColumns.unshift({
                label: 'Bruker',
                fieldName: 'UserName__c',
                type: 'text',
                sortable: true
            });
            tempMobileColumns.unshift("'Bruker'");
            this.previousChoiceOthers = true;
        }
        for (var i = 0; i < 10; i++) {
            if (i < tempMobileColumns.length) {
                document.documentElement.style.setProperty('--columnlabel_' + i.toString(), tempMobileColumns[i]);
            } else {
                document.documentElement.style.setProperty('--columnlabel_' + i.toString(), '');
            }
        }
        this.columns = [...tempColumns];
        this.mobileColumns = [...tempMobileColumns];
    }

    @track showAll = false;
    showAllOrNot() {
        if (this.showAll) {
            this.requests = this.allRequests;
        } else {
            this.filterRequests();
        }
    }

    @track defaultSortDirection = 'desc';
    @track sortDirection = 'desc';
    @track sortedBy = 'StartTime__c';

    mobileSortingDefaultValue = '{"fieldName": "StartTime__c", "sortDirection": "desc"} ';
    get sortingOptions() {
        return getMobileSortingOptions(this.columns);
    }
    handleMobileSorting(event) {
        let value = JSON.parse(event.detail.value);
        this.sortDirection = value.sortDirection;
        this.sortedBy = value.fieldName;
        this.allRequests = sortList(this.allRequests, this.sortedBy, this.sortDirection);
        this.showAllOrNot();
    }
    onHandleSort(event) {
        this.sortDirection = event.detail.sortDirection;
        this.sortedBy = event.detail.fieldName;
        this.allRequests = sortList(this.allRequests, this.sortedBy, this.sortDirection);
        this.showAllOrNot();
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        switch (actionName) {
            case 'delete':
                this.cancelOrder(row);
                break;
            case 'clone_order':
                this.cloneOrder(row);
                break;
            case 'edit_order':
                this.editOrder(row);
                break;
            case 'details':
                this.showDetails(row);
                break;
            case 'see_times':
                this.showTimes(row);
                break;
            default:
        }
    }
    connectedCallback() {
        for (var i = 0; i < 10; i++) {
            if (i < this.mobileColumns.length) {
                document.documentElement.style.setProperty('--columnlabel_' + i.toString(), this.mobileColumns[i]);
            } else {
                document.documentElement.style.setProperty('--columnlabel_' + i.toString(), '');
            }
        }
        window.scrollTo(0, 0);
        refreshApex(this.wiredRequestsResult);
    }

    findRowIndexById(Id) {
        let ret = -1;
        this.requests.some((row, index) => {
            if (row.Id === Id) {
                ret = index;
                return true;
            }
            return false;
        });
        return ret;
    }
    cancelOrder(row) {
        const { Id } = row;
        const index = this.findRowIndexById(Id);
        if (index != -1) {
            let tempEndDate = new Date(this.requests[index].EndTime__c);
            if (
                this.requests[index].ExternalRequestStatus__c != 'Avlyst' &&
                this.requests[index].ExternalRequestStatus__c != 'Dekket' &&
                tempEndDate.getTime() > Date.now()
            ) {
                if (confirm('Er du sikker på at du vil avlyse bestillingen?')) {
                    const fields = {};
                    fields[REQUEST_ID.fieldApiName] = Id;
                    fields[STATUS.fieldApiName] = 'Avlyst';
                    fields[NOTIFY_DISPATCHER.fieldApiName] = true;
                    const recordInput = { fields };
                    updateRecord(recordInput)
                        .then(() => {
                            refreshApex(this.wiredRequestsResult);
                        })
                        .catch((error) => {
                            alert('Kunne ikke avlyse bestilling.');
                        });
                }
            } else {
                alert('Du kan ikke avlyse denne bestillingen.');
            }
        }
    }

    cloneOrder(row) {
        const { Id } = row;
        const index = this.findRowIndexById(Id);
        if (index != -1) {
            //Here we should get the entire record from salesforce, to get entire interpretation address.
            let clone = this.requests[index];
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    pageName: 'ny-bestilling'
                },
                state: {
                    fieldValues: JSON.stringify(clone),
                    fromList: true,
                    copy: true
                }
            });
        }
    }

    editOrder(row) {
        const { Id } = row;
        const index = this.findRowIndexById(Id);
        if (index != -1) {
            if (row.Orderer__c == this.userRecord.AccountId) {
                if (this.requests[index].ExternalRequestStatus__c.includes('Åpen')) {
                    //Here we should get the entire record from salesforce, to get entire interpretation address.
                    let clone = this.requests[index];
                    this[NavigationMixin.Navigate]({
                        type: 'comm__namedPage',
                        attributes: {
                            pageName: 'ny-bestilling'
                        },
                        state: {
                            fieldValues: JSON.stringify(clone),
                            fromList: true,
                            edit: true
                        }
                    });
                }
            } else {
                alert('Denne bestillingen er bestilt av noen andre, og du har ikke rettigheter til å endre den.');
            }
        }
    }
    @track record = null;
    @track userForm = false;
    @track myRequest = false;
    @track companyForm = false;
    @track publicEvent = false;
    showDetails(row) {
        this.record = row;
        this.myRequest = this.record.Orderer__c == this.userRecord.AccountId;
        this.userForm =
            (this.record.Type__c == 'User' || this.record.Type__c == 'Company') && this.record.UserName__c != '';
        this.companyForm = this.record.Type__c == 'Company' || this.record.Type__c == 'PublicEvent';
        this.publicEvent = this.record.Type__c == 'PublicEvent';

        this.userFields = formatRecord(this.record, requestFieldLabels.getSubFields('user'));
        this.ordererFields = formatRecord(this.record, requestFieldLabels.getSubFields('orderer'));
        this.companyFields = formatRecord(this.record, requestFieldLabels.getSubFields('company'));
        this.requestFields = formatRecord(this.record, requestFieldLabels.getSubFields('request'));

        let detailPage = this.template.querySelector('.ReactModal__Overlay');
        detailPage.classList.remove('hidden');
        detailPage.focus();
    }

    @track userFields = null;
    @track ordererFields = null;
    @track companyFields = null;
    @track requestFields = null;

    @track formatedRecord = [];

    abortShowDetails() {
        this.template.querySelector('.ReactModal__Overlay').classList.add('hidden');
    }

    showTimes(row) {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                pageName: 'min-tidsplan'
            },
            state: {
                id: row.Name
            }
        });
    }

    goToMyRequests(event) {
        if (!this.isProd) {
            event.preventDefault();
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    pageName: 'mine-bestillinger'
                }
            });
        }
    }

    goToNewRequest() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                pageName: 'ny-bestilling'
            },
            state: {
                fromList: true
            }
        });
    }
    goToHome(event) {
        if (!this.isProd) {
            event.preventDefault();
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    pageName: 'home'
                }
            });
        }
    }
}
