import { require } from 'c/validationController';

export let organizationNumberValidationRules = [validOrganizationNumber, require];
export default { validOrganizationNumber };

function validOrganizationNumber(organizationNumber) {
    let regExp = RegExp('\\d{9}');
    return regExp.test(organizationNumber) ? '' : 'Ikke gyldig format for organisasjonsnummer';
}
