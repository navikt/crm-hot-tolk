import { LightningElement, api } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';

export default class Hot_flowRangePicklist extends LightningElement {
    @api label;
    @api from;
    @api to;
    @api defaultValue;
    @api required = false;

    _value = '';
    errorMessage = '';

    @api
    get value() {
        return this._value;
    }

    set value(v) {
        this._value = v === null || v === undefined ? '' : String(v);
    }

    connectedCallback() {
        this.setInitialValue();
    }

    setInitialValue() {
        // Hvis Flow allerede har en verdi (f.eks. etter Back/Next) → gjør ingenting
        if (this._value && this._value !== '') {
            return;
        }

        const start = this.normalizeFrom();
        const end = this.normalizeTo();
        if (end === null) return;

        const def = this.normalizeDefaultValue();

        const selected = def !== null && def >= start && def <= end ? String(def) : String(start);

        this._value = selected;

        this.dispatchEvent(new FlowAttributeChangeEvent('value', this._value));
    }

    get options() {
        const start = this.normalizeFrom();
        const end = this.normalizeTo();
        if (end === null) return [];

        const opts = [];
        for (let i = start; i <= end; i++) {
            const s = String(i);
            opts.push({ label: s, value: s });
        }
        return opts;
    }

    handleChange(event) {
        this._value = event.detail.value;
        this.errorMessage = '';

        this.dispatchEvent(new FlowAttributeChangeEvent('value', this._value));
    }

    @api
    validate() {
        if (this.required && (!this._value || this._value.trim() === '')) {
            return {
                isValid: false,
                errorMessage: 'Vennligst velg et alternativ.'
            };
        }
        return { isValid: true };
    }

    normalizeFrom() {
        const n = Number(this.from);
        return Number.isFinite(n) ? Math.trunc(n) : 0;
    }

    normalizeTo() {
        const n = Number(this.to);
        if (!Number.isFinite(n)) return null;

        const start = this.normalizeFrom();
        const end = Math.trunc(n);
        return end < start ? start : end;
    }

    normalizeDefaultValue() {
        const n = Number(this.defaultValue);
        return Number.isFinite(n) ? Math.trunc(n) : null;
    }
}
