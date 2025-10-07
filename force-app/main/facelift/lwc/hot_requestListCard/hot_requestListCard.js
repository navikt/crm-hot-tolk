import { LightningElement, api } from 'lwc';

export default class Hot_requestListCard extends LightningElement {
    @api records = [];
    @api columns = [];
    @api labelMap = {};
    @api ariaLabel;

    recordMap = {};

    get fieldPlan() {
        const cols = Array.isArray(this.columns) ? this.columns : [];
        const norm = (s) => (s || '').toString().trim().toLowerCase();

        const findByExactLabel = (label) => cols.find((c) => norm(c.label) === norm(label));
        const findByLabelIncludes = (frags) =>
            cols.find((c) => {
                const l = norm(c.label);
                return frags.some((f) => l.includes(f));
            });
        const findByFieldName = (name) => cols.find((c) => norm(c.fieldName) === norm(name));

        const temaCol = findByExactLabel('Tema') || findByFieldName('Subject');
        const tolkCol = findByExactLabel('Tolk') || findByFieldName('HOT_Interpreters__c');

        let primary =
            temaCol?.fieldName ||
            tolkCol?.fieldName ||
            findByFieldName('Subject')?.fieldName ||
            cols.find((c) => c.fieldName !== 'StartAndEndDate')?.fieldName ||
            cols[0]?.fieldName;

        let secondary =
            findByFieldName('StartAndEndDate')?.fieldName ||
            findByLabelIncludes(['tid', 'time', 'dato', 'kl'])?.fieldName ||
            cols.find((c) => c.fieldName !== primary)?.fieldName;

        let tertiary =
            findByExactLabel('Adresse')?.fieldName ||
            findByLabelIncludes(['adresse', 'address'])?.fieldName ||
            cols.find((c) => c.fieldName !== primary && c.fieldName !== secondary)?.fieldName ||
            null;

        if (secondary === primary) {
            secondary = cols.find((c) => c.fieldName !== primary)?.fieldName || secondary;
        }
        if (tertiary === primary || tertiary === secondary) {
            const alt = cols.find((c) => c.fieldName !== primary && c.fieldName !== secondary)?.fieldName;
            tertiary = alt || tertiary;
        }

        return { primary, secondary, tertiary };
    }

    get recordsToShow() {
        const processed = [];
        this.recordMap = {};

        if (!Array.isArray(this.records) || !Array.isArray(this.columns)) return processed;

        const { primary, secondary, tertiary } = this.fieldPlan;

        for (const record of this.records) {
            const fields = this.columns.map((col) => {
                const rawValue = record[col.fieldName];
                const mapping = this.labelMap[col.fieldName]?.[rawValue];
                return {
                    name: col.fieldName,
                    label: col.label,
                    value: rawValue,
                    displayLabel: mapping?.label ?? rawValue ?? '',
                    cssClass: mapping?.cssClass ?? ''
                };
            });

            const getField = (name) =>
                (name && fields.find((f) => f.name === name)) || {
                    name,
                    label: '',
                    value: '',
                    displayLabel: '',
                    cssClass: ''
                };

            const fPrimary = getField(primary);
            const fSecondary = getField(secondary);
            const fTertiary = tertiary ? getField(tertiary) : { displayLabel: '' };

            const lowerNames = ['status', 'status__c', 'hot_externalworkorderstatus__c', 'hot_status__c'];
            let statusField = fields.find((f) => (f.label || '').trim().toLowerCase() === 'status') ||
                fields.find((f) => lowerNames.includes((f.name || '').toLowerCase())) ||
                fields.find((f) => {
                    const cls = (f.cssClass || '').toLowerCase();
                    return (
                        cls.startsWith('label-') ||
                        cls.includes('status') ||
                        cls.includes('unreadthread') ||
                        cls.includes('readthread')
                    );
                }) || {
                    name: 'Status',
                    label: 'Status',
                    value: record?.Status ?? '',
                    displayLabel: this.labelMap?.Status?.[record?.Status]?.label ?? record?.Status ?? '',
                    cssClass: this.labelMap?.Status?.[record?.Status]?.cssClass ?? ''
                };

            const statusClassCombined = ['status-label', statusField.cssClass].filter(Boolean).join(' ');

            const tagFields = fields.filter((f) => {
                if (!f.displayLabel) return false;
                const isCore =
                    f.name === fPrimary.name ||
                    f.name === fSecondary.name ||
                    f.name === fTertiary.name ||
                    f === statusField;
                return !isCore;
            });

            const isTolkField = (f) =>
                (f.label || '').trim().toLowerCase() === 'tolk' ||
                (f.name || '').trim().toLowerCase() === 'hot_interpreters__c';

            const isEmptyValue = (f) => {
                const v = f.displayLabel ?? f.value;
                if (v === undefined || v === null) return true;
                if (Array.isArray(v)) return v.length === 0;
                return String(v).trim().length === 0;
            };

            const primaryDisplayLabel = isTolkField(fPrimary)
                ? isEmptyValue(fPrimary)
                    ? 'Tolk: Ingen tolk er tildelt enda'
                    : `Tolk: ${fPrimary.displayLabel}`
                : fPrimary.displayLabel;

            const temaField =
                fields.find((f) => (f.label || '').trim().toLowerCase() === 'tema') ||
                fields.find((f) => (f.name || '').trim().toLowerCase() === 'subject');

            const temaSpoken =
                temaField && (temaField.displayLabel || temaField.value)
                    ? `Tema: ${temaField.displayLabel || temaField.value}.`
                    : '';

            const secondarySpokenLabel = fSecondary.label || 'Tid';
            const tertiarySpokenLabel = fTertiary.label || 'Adresse';

            const primarySpokenLabel = fPrimary.label || (isTolkField(fPrimary) ? 'Tolk' : 'Detalj');
            const primarySpokenValue =
                isTolkField(fPrimary) && isEmptyValue(fPrimary)
                    ? 'Ingen tolk er tildelt enda'
                    : fPrimary.displayLabel || '';

            const dateFirst = fSecondary.displayLabel ? `${secondarySpokenLabel}: ${fSecondary.displayLabel}.` : '';
            const statusSpoken = statusField.displayLabel ? `Status: ${statusField.displayLabel}.` : '';
            const primaryOrTema =
                temaSpoken || (primarySpokenValue ? `${primarySpokenLabel}: ${primarySpokenValue}.` : '');
            const addressSpoken = fTertiary.displayLabel ? `${tertiarySpokenLabel}: ${fTertiary.displayLabel}.` : '';

            const fullAriaLabel = [
                dateFirst,
                statusSpoken,
                primaryOrTema,
                addressSpoken,
                tagFields.length ? `Andre detaljer: ${tagFields.map((t) => t.displayLabel).join(', ')}.` : ''
            ]
                .filter(Boolean)
                .join(' ');

            processed.push({
                id: record.Id,
                original: record,
                fields,
                fullAriaLabel,

                primary: fPrimary,
                primaryDisplayLabel,
                secondary: fSecondary,
                tertiary: fTertiary,

                secondaryMobilePrefix: fSecondary.label ? `${fSecondary.label}:` : '',
                tertiaryPrefixDesktop: fTertiary.label ? `(${fTertiary.label}):` : '',
                tertiaryPrefixMobile: fTertiary.label ? `${fTertiary.label}:` : '',

                status: statusField,
                statusClass: statusClassCombined,

                tagFields
            });

            this.recordMap[record.Id] = record;
        }

        return processed;
    }

    get hasData() {
        return this.recordsToShow.length > 0;
    }

    handleCardClick(event) {
        const recordId = event.currentTarget.value;
        const record = this.recordMap[recordId];
        this.dispatchEvent(
            new CustomEvent('rowclick', {
                detail: record,
                bubbles: true,
                composed: true
            })
        );
    }
}
