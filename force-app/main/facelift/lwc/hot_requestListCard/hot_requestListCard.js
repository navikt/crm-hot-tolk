import { LightningElement, api } from 'lwc';

export default class Hot_requestListCard extends LightningElement {
    @api records = [];
    @api columns = [];
    @api labelMap = {};
    @api ariaLabel;

    recordMap = {};

    // Decide middle/left/right columns based on labels/field names
    get fieldPlan() {
        const cols = Array.isArray(this.columns) ? this.columns : [];
        const lc = (s) => (s || '').toString().trim().toLowerCase();
        const byLabel = (label) => cols.find((c) => lc(c.label) === lc(label));
        const byField = (name) => cols.find((c) => lc(c.fieldName) === lc(name));
        const labelIncludes = (frags) => cols.find((c) => frags.some((f) => lc(c.label).includes(f)));

        const temaCol = byLabel('Tema') || byField('Subject');
        const tolkCol = byLabel('Tolk') || byField('HOT_Interpreters__c');

        let primary =
            temaCol?.fieldName ||
            tolkCol?.fieldName ||
            byField('Subject')?.fieldName ||
            cols.find((c) => c.fieldName !== 'StartAndEndDate')?.fieldName ||
            cols[0]?.fieldName;

        let secondary =
            byField('StartAndEndDate')?.fieldName ||
            labelIncludes(['tid', 'time', 'dato', 'kl'])?.fieldName ||
            cols.find((c) => c.fieldName !== primary)?.fieldName;

        let tertiary =
            byLabel('Adresse')?.fieldName ||
            labelIncludes(['adresse', 'address'])?.fieldName ||
            cols.find((c) => c.fieldName !== primary && c.fieldName !== secondary)?.fieldName ||
            null;

        // De-duplicate
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
        const out = [];
        this.recordMap = {};
        if (!Array.isArray(this.records) || !Array.isArray(this.columns)) return out;

        const { primary, secondary, tertiary } = this.fieldPlan;
        const lc = (s) => (s || '').toString().trim().toLowerCase();

        for (const record of this.records) {
            // Build normalized field list (apply labelMap for label/cssClass)
            const fields = this.columns.map((col) => {
                const raw = record[col.fieldName];
                const map = this.labelMap[col.fieldName]?.[raw];
                return {
                    name: col.fieldName,
                    label: col.label,
                    value: raw,
                    displayLabel: map?.label ?? raw ?? '',
                    cssClass: map?.cssClass ?? ''
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
            const fTertiary = tertiary ? getField(tertiary) : { displayLabel: '', label: '' };

            if (fSecondary?.displayLabel) {
                fSecondary.displayLabel = String(fSecondary.displayLabel).replace(/\s*-\s*/g, ' – ');
            }

            // Status detection: by label, field name, or css class hints; fallback to record.Status
            const statusNameCandidates = ['status', 'status__c', 'hot_externalworkorderstatus__c', 'hot_status__c'];
            const statusField = fields.find((f) => lc(f.label) === 'status') ||
                fields.find((f) => statusNameCandidates.includes(lc(f.name))) ||
                fields.find((f) => {
                    const cls = lc(f.cssClass);
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

            const statusClass = ['status-label', statusField.cssClass].filter(Boolean).join(' ');

            // Helpers
            const isTolkField = lc(fPrimary.label) === 'tolk' || lc(fPrimary.name) === 'hot_interpreters__c';
            const isEmpty = (f) => {
                const v = f.displayLabel ?? f.value;
                if (v === undefined || v === null) return true;
                if (Array.isArray(v)) return v.length === 0;
                return String(v).trim().length === 0;
            };

            const primaryDisplayLabel = isTolkField
                ? isEmpty(fPrimary)
                    ? 'Tolk: Ingen tolk er tildelt enda'
                    : `Tolk: ${fPrimary.displayLabel}`
                : fPrimary.displayLabel;

            const tagFields = fields.filter((f) => {
                if (!f.displayLabel) return false;
                const core = [fPrimary.name, fSecondary.name, fTertiary.name];
                return !core.includes(f.name) && f !== statusField;
            });

            const formatHyphen = (text) => String(text).replace(/\s*-\s*/g, ' – ');

            const temaField =
                fields.find((f) => lc(f.label) === 'tema') || fields.find((f) => lc(f.name) === 'subject');

            const pieces = [];
            if (fSecondary.displayLabel) pieces.push(`${formatHyphen(fSecondary.displayLabel)}.`);
            if (statusField.displayLabel) pieces.push(`Status: ${statusField.displayLabel}.`);

            if (temaField && (temaField.displayLabel || temaField.value)) {
                pieces.push(`Tema: ${temaField.displayLabel || temaField.value}.`);
            } else if (isTolkField) {
                pieces.push(`Tolk: ${isEmpty(fPrimary) ? 'Ingen tolk er tildelt enda' : fPrimary.displayLabel}.`);
            } else if (fPrimary.displayLabel) {
                pieces.push(`${fPrimary.label || 'Detalj'}: ${fPrimary.displayLabel}.`);
            }

            if (fTertiary.displayLabel) pieces.push(`${fTertiary.label || 'Adresse'}: ${fTertiary.displayLabel}.`);
            if (tagFields.length) pieces.push(`Andre detaljer: ${tagFields.map((t) => t.displayLabel).join(', ')}.`);

            const fullAriaLabel = pieces.join(' ');

            out.push({
                id: record.Id,
                original: record,
                fields,
                fullAriaLabel,
                primary: fPrimary,
                primaryDisplayLabel,
                secondary: fSecondary,
                tertiary: fTertiary,
                status: statusField,
                statusClass
            });

            this.recordMap[record.Id] = record;
        }

        return out;
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
