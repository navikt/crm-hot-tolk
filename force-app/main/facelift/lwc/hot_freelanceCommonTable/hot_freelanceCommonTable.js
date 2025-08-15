import { LightningElement, api } from 'lwc';

export default class Hot_freelanceCommonTable extends LightningElement {
    @api columns;
    @api records;
    @api ariaLabel;
    @api iconByValue;

    @api checkbox = false;
    @api checkedRows = [];

    // WIP: return badge css will be changed when we have a decided on design colors
    statusBadgeMap = {
        'badge-gray': ['Åpen', 'Open'],
        'badge-blue': ['Reserved', 'Reservert'],
        'badge-green': ['Assigned', 'Tildelt', 'Dekket', 'Covered'],
        'badge-yellow': ['Interested', 'Påmeldt', 'Wanted', 'Ønsket til'],
        'badge-red': [
            'Not Assigned',
            'Ikke tildelt deg',
            'Withdrawn',
            'Tatt av oppdraget',
            'Canceled',
            'Avlyst',
            'Canceled by Interpreter',
            'Avlyst av tolk',
            'Declined',
            'Avslått',
            'Retracted Interest',
            'Tilbaketrukket påmelding',
            'Service Appointment Retracted',
            'Oppdrag tilbaketrukket',
            'Annullert',
            'Annul',
            'Tilbaketrukket tilgjengelighet',
            'Retracted Availability'
        ]
    };

    // Maps aria-label from message icons to CSS badge classes
    statusBadgeIconByAriaLabel = {
        'Ulest melding': 'badge-yellow',
        'Ingen nye meldinger': 'badge-green',
        'Høyt prioritert': 'badge-orange'
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
                    this.applyIconDataToField(value, field);
                }

                if (column.name === 'Status__c' || column.name === 'statusMobile' || column.name === 'Status') {
                    field.statusBadgeClass = this.getStatusBadgeClass(value);
                    field.statusBadgeLabel = value;
                }

                // Apply bold font weight and size to date columns
                if (column.name === 'StartAndEndDate' || column.name === 'startAndEndDateWeekday') {
                    field.cssClass = 'bold-date';
                }

                fields.push(field);
            }

            // Store processed record and track checked state
            records.push({
                id: record.Id,
                checked: this.checkedRows.includes(record.Id),
                fields: fields
            });
            this.recordMap[record.Id] = record;
        }

        return records;
    }

    applyIconDataToField(value, field) {
        const iconData = this.iconByValue[value];
        if (!iconData) return;

        field.icon = iconData.icon;
        field.iconFill = iconData.fill;
        field.iconAriaLabel = iconData.ariaLabel === 'Høyt prioritert' ? 'Prioritert' : iconData.ariaLabel;

        // Assign a CSS class based on the ariaLabel
        field.badgeClass = this.getBadgeClassByAriaLabel(iconData.ariaLabel || '');
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
        const eventToSend = new CustomEvent('rowclick', {
            detail: this.recordMap[event.currentTarget.dataset.id]
        });
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
