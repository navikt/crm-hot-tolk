import { require } from 'c/validationController';

export let personNumberValidationRules = [validPersonNumber, require];

function validPersonNumber(organizationNumber) {
    let regExp = RegExp('[0-7][0-9][0-1][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]');
    return regExp.test(organizationNumber) ? '' : 'Ikke gyldig format for organisasjonsnummer';
}
