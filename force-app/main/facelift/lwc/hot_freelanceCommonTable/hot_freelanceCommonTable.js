import { LightningElement, api } from 'lwc';

export default class Hot_freelanceCommonTable extends LightningElement {
    @api columns;
    @api records;
    @api ariaLabel;
    @api iconByValue;

    @api checkbox = false;
    @api checkedRows = [];

    // WIP Not sure what css to return based of status
    // All css badge-status are only temporary placement until we have a proper design for them
    statusBadgeMap = {
        'badge-green': ['Assigned', 'Tildelt'],
        'badge-status-canceled': ['Canceled', 'Avlyst'],
        'badge-status-canceled-by-interpreter': ['Canceled by Interpreter', 'Avlyst av tolk'],
        'badge-status-declined': ['Declined', 'Avslått'],
        'badge-orange': ['Interested', 'Påmeldt'],
        'badge-status-not-assigned': ['Not Assigned', 'Ikke tildelt deg'],
        'badge-status-reserved': ['Reserved', 'Reservert'],
        'badge-status-retracted': ['Retracted Interest', 'Tilbaketrukket påmelding'],
        'badge-status-sa-retracted': ['Service Appointment Retracted', 'Oppdrag tilbaketrukket'],
        'badge-status-wanted': ['Wanted', 'Ønsket til'],
        'badge-red': ['Withdrawn', 'Tatt av oppdraget']
    };

    // Maps aria-label from message icons to CSS badge classes
    statusBadgeIconByAriaLabel = {
        'Ulest melding': 'badge-orange',
        'Ingen nye meldinger': 'badge-green'
    };

    recordMap = {};
    get recordsToShow() {
        const records = [];
        this.recordMap = {};

        if (!this.records || !this.columns) return records;

        for (const record of this.records) {
            const fields = [];

            for (const column of this.columns) {
                const value = record?.[column.name];
                const field = {
                    name: column.name,
                    label: column.label,
                    value: value,
                    type: column.type
                };

                if (column.svg && this.iconByValue) {
                    const iconData = this.iconByValue[value];

                    if (iconData) {
                        // Add icon details to field
                        field.icon = iconData.icon;
                        field.iconFill = iconData.fill;
                        field.iconAriaLabel = iconData.ariaLabel;

                        // Set badge CSS class from aria-label
                        field.badgeClass = this.getBadgeClassByAriaLabel(iconData.ariaLabel || '');
                    }
                }

                if (column.name === 'Status__c') {
                    field.statusBadgeClass = this.getStatusBadgeClass(value);
                    field.statusBadgeLabel = value;
                }

                fields.push(field);
            }

            // Store processed record and track checked state
            records.push({
                id: record.Id,
                checked: this.checkedRows?.includes(record.Id),
                fields
            });
            this.recordMap[record.Id] = record;
        }

        return records;
    }

    getBadgeClassByAriaLabel(ariaLabel) {
        return this.statusBadgeIconByAriaLabel[ariaLabel] || 'badge-none';
    }

    // Returns the CSS badge class matching the given status value
    // Checks statusBadgeMap for Norwegian and English picklist values
    getStatusBadgeClass(value) {
        for (let badgeClass in this.statusBadgeMap) {
            if (this.statusBadgeMap[badgeClass].includes(value)) {
                return badgeClass;
            }
        }
        return 'badge-none';
    }

    handleOnRowClick(event) {
        const eventToSend = new CustomEvent('rowclick', { detail: this.recordMap[event.currentTarget.dataset.id] });
        this.dispatchEvent(eventToSend);
    }

    sendCheckedRows() {
        const eventToSend = new CustomEvent('checkedrows', {
            detail: { checkedRows: this.checkedRows }
        });
        this.dispatchEvent(eventToSend);
    }

    @api getCheckedRows() {
        return this.checkedRows;
    }

    @api unsetCheckboxes() {
        this.template.querySelectorAll('c-checkbox').forEach((element) => {
            element.clearCheckboxValue();
        });
        this.checkedRows = [];
    }

    handleSingleCheckboxClick() {
        let recordIdArray = this.resetRecordIdArray();
        this.template.querySelectorAll('c-checkbox').forEach((element, index) => {
            if (element.getValue()) {
                recordIdArray[index - 1].checked = true;
            }
        });
        recordIdArray.forEach((element) => {
            if (element.checked) {
                this.checkedRows.push(element.id);
            }
        });
        this.sendCheckedRows();
    }

    // Handles "select all" checkbox in table header
    handleAllCheckboxesClick(event) {
        let recordIdArray = this.resetRecordIdArray();
        this.template.querySelectorAll('c-checkbox').forEach((element) => {
            element.setCheckboxValue(event.detail);
        });
        // mark all rows as checked if header checkbox is checked
        let tempArr = recordIdArray.map((headerCheckbox) => ({ ...headerCheckbox, checked: event.detail }));
        tempArr.forEach((element) => {
            if (element.checked) {
                this.checkedRows.push(element.id);
            }
        });
        this.sendCheckedRows();
    }

    resetRecordIdArray() {
        this.checkedRows = [];
        let recordArray = Object.entries(this.recordMap);
        let recordIdArray = [];
        recordArray.forEach((element) => {
            recordIdArray.push({ id: element[0], checked: false });
        });
        return recordIdArray;
    }
}
