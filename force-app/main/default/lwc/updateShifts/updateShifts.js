import { LightningElement, track, wire, api } from 'lwc';
import { sortList, getMobileSortingOptions } from 'c/sortController';
import getShifts from '@salesforce/apex/HOT_UpdateShiftsController.getShifts';
import updateRecords from '@salesforce/apex/HOT_UpdateShiftsController.updateRecords';
import deleteRecords from '@salesforce/apex/HOT_UpdateShiftsController.deleteRecords';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';

export default class UpdateShifts extends NavigationMixin(LightningElement) {
    @track columns = [
        {
            label: 'Skift',
            fieldName: 'ShiftNumber',
            type: 'text',
            sortable: true
        },
        {
            label: 'Start tid',
            fieldName: 'StartTime',
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
            fieldName: 'EndTime',
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
            label: 'Tittel',
            fieldName: 'Label',
            type: 'text',
            sortable: true
        },
        {
            label: 'Opprettelsesdato',
            fieldName: 'CreatedDate',
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
        }
    ];

    @api recordId;

    wiredResult;
    @track shifts;
    @track record;
    @wire(getShifts, { recordId: '$recordId' })
    wiredMethod(result) {
        this.wiredResult = result;
        if (result.data) {
            this.shifts = result.data;
            this.shifts.forEach((shift) => {
                if (this.recordId === shift.Id) {
                    this.record = { ...shift };
                    this.record.StartTime = this.dateTimeToTimeString(new Date(this.record.StartTime));
                    this.record.EndTime = this.dateTimeToTimeString(new Date(this.record.EndTime));
                }
            });
        }
    }
    dateTimeToTimeString(dateTime) {
        let hours = dateTime.getHours();
        return (hours < 10 ? '0' + hours.toString() : hours.toString()) + ':00';
    }
    filterShifts() {}

    thisSelected = false;
    @track selectedShifts;
    handleRowSelection(event) {
        this.thisSelected = false;
        this.selectedShifts = event.detail.selectedRows;
        this.isSelected = this.selectedShifts.length > 0;
        for (let row of this.selectedShifts) {
            if (row.Id === this.recordId) {
                this.thisSelected = true;
            }
        }
    }

    isSelected = false;
    showForm = false;
    editShifts() {
        this.reset();
        this.showForm = true;
    }
    showPrompt = false;
    deleteShifts() {
        this.reset();
        this.showPrompt = true;
    }
    confirmDeleteShifts() {
        deleteRecords({ records: this.selectedShifts }).then(() => {
            if (this.thisSelected) {
                this[NavigationMixin.Navigate]({
                    type: 'standard__objectPage',
                    attributes: {
                        objectApiName: 'Shift',
                        actionName: 'home'
                    }
                });
            } else {
                refreshApex(this.wiredResult);
                this.reset();
            }
        });
    }
    handleSubmit() {
        let fields = {};
        this.template.querySelectorAll('lightning-input').forEach((element) => {
            fields[element.name] = element.value;
        });
        updateRecords({ records: this.selectedShifts, fieldValues: fields }).then(() => {
            refreshApex(this.wiredResult);
            this.reset();
        });
    }
    reset() {
        this.showPrompt = false;
        this.showForm = false;
    }

    //Sorting methods
    @track defaultSortDirection = 'asc';
    @track sortDirection = 'asc';
    @track sortedBy = 'ServiceAppointmentStartTime__c';

    get sortingOptions() {
        return getMobileSortingOptions(this.columns);
    }

    onHandleSort(event) {
        this.sortDirection = event.detail.sortDirection;
        this.sortedBy = event.detail.fieldName;
        this.shifts = sortList(this.shifts, this.sortedBy, this.sortDirection);
        this.filterShifts();
    }
}
