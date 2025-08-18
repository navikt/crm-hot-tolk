import { LightningElement, api } from 'lwc';
import { setDefaultValue, convertStringToBoolean } from 'c/componentHelperClass';

export default class Input extends LightningElement {
    @api type = 'text';
    @api name = 'input';
    @api alt = ''; // Alternate text for image
    @api label = '';
    @api value;
    @api form;
    @api helptextContent = '';
    @api helptextHovertext;
    @api errorText;
    @api labelSize;
    @api errorSize;
    @api autofocus;
    @api disabled = false;
    @api readonly = false;
    @api maxLength = '255';
    @api minLength = '0';
    @api placeholder = '';
    @api id = 'inputcomponent';
    @api mobileStyle;
    @api desktopStyle;

    isLabel = false;
    handleFocus(event) {
        event.target.focus(); // Ensure the input activates fully
    }
    get haslabel() {
        return this.label !== '' && this.label !== undefined;
    }

    get idValue() {
        return this.id !== '' && this.id !== undefined ? this.id : 'inputcomponent';
    }

    get labelFontSize() {
        return 'font-size: ' + setDefaultValue(this.labelSize, '1.125rem') + ';';
    }

    get errorFontSize() {
        return 'font-size: ' + setDefaultValue(this.errorSize, '1.125rem') + ';';
    }

    get isHelpText() {
        return this.helptextContent !== '' && this.helptextContent !== undefined ? true : false;
    }

    get setDefaultAutofocus() {
        return convertStringToBoolean(this.autofocus);
    }

    // Call this when value is needed
    @api getValue() {
        return this.template.querySelector('input').value;
    }

    @api setValue(val) {
        this.template.querySelector('input').value = val;
        this.sendValueOnChange();
    }

    @api sendErrorMessage(errorMessage) {
        this.showError = errorMessage !== '' && errorMessage !== undefined;
        this.actualErrorText = errorMessage;
        this.setErrorCss();
    }
    showError;
    actualErrorText;
    updateShowErrorTextValue() {
        this.showError =
            this.errorText !== undefined &&
            this.errorText !== '' &&
            !this.disabled &&
            (this.template.querySelector('input').value === undefined ||
                this.template.querySelector('input').value === '' ||
                this.template.querySelector('input').value === null);
        this.actualErrorText = this.errorText;
        this.setErrorCss();
        return this.showError;
    }

    setErrorCss() {
        if (this.showError) {
            this.template.querySelector('.navds-form-field').classList.add('navds-text-field--error');
            this.template.querySelector('input').focus();
        } else {
            this.template.querySelector('.navds-form-field').classList.remove('navds-text-field--error');
        }
    }

    // Sends value on change
    handleonchange() {
        const selectedEvent = new CustomEvent('change', {
            detail: this.template.querySelector('input').value
        });
        this.dispatchEvent(selectedEvent);
    }

    // Sends value on change
    sendValueOnChange() {
        let inputValue = this.template.querySelector('input').value;
        this.value = inputValue;
        const selectedEvent = new CustomEvent('getvalueonchange', {
            detail: inputValue
        });
        if (this.showError) {
            this.updateShowErrorTextValue();
        }
        this.dispatchEvent(selectedEvent);
    }

    // Checks if number is mobile, ref: https://no.wikipedia.org/wiki/Nummerplan_(E.164)
    // Returns true if mobile
    @api
    validatePhone(errMsg) {
        errMsg = setDefaultValue(errMsg, this.errorText);
        this.showError = false;
        let num = this.template.querySelector('input').value.replaceAll(' ', '');
        if (num.substring(0, 4) === '0047' && num.length === 12) {
            num = num.substring(4, num.length);
        }
        if (num.charAt(0) === '+') {
            this.showError = true;
        }
        if (num.substring(0, 3) === '+47') {
            if (num.length < 11) {
                this.showError = true;
            }
            num = num.substring(3, num.length);
        }
        if (isNaN(num)) {
            this.showError = true;
        }
        if (num.charAt(0) !== '4' && num.charAt(0) !== '9') {
            // Norwegian mobile number
            this.showError = true;
        }
        if (num.length !== 8) {
            this.showError = true;
        }
        this.actualErrorText = errMsg;
        if (this.disabled) {
            return false;
        }
        this.setErrorCss();
        return this.showError;
    }

    @api validateOrgNumber(errMsg) {
        errMsg = setDefaultValue(errMsg, this.errorText);
        let regExp = RegExp('\\d{9}');
        let orgNumber = this.template.querySelector('input').value.replaceAll(' ', '');
        this.showError = regExp.test(orgNumber) ? false : true;
        this.actualErrorText = errMsg;
        if (this.disabled) {
            return false;
        }
        this.setErrorCss();
        return this.showError;
    }

    @api validatePersonNumber(errMsg) {
        errMsg = setDefaultValue(errMsg, this.errorText);
        let regExp = RegExp('[0-7][0-9][0-1][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]');
        let personNumber = this.template.querySelector('input').value.replaceAll(' ', '');
        this.showError = regExp.test(personNumber) ? false : true;
        this.actualErrorText = errMsg;
        if (this.disabled) {
            return false;
        }
        this.setErrorCss();
        return this.showError;
    }

    @api validatePhoneLength(errMsg) {
        errMsg = setDefaultValue(errMsg, this.errorText);
        let number = this.template.querySelector('input').value.replaceAll(' ', '');
        if (number.length !== 8) {
            this.showError = true;
        }
        if (number.substring(0, 1) === '+') {
            this.showError = true;
        }
        if (isNaN(number)) {
            this.showError = true;
        }
        this.actualErrorText = errMsg;
        if (this.disabled) {
            return false;
        }
        this.setErrorCss();
        return this.showError;
    }

    @api
    validationHandler() {
        return this.updateShowErrorTextValue();
    }

    get setDefaultStyle() {
        let style = this.desktopStyle;
        if (window.screen.width < 576) {
            style = this.mobileStyle;
        }
        return setDefaultValue(style, '');
    }
}
