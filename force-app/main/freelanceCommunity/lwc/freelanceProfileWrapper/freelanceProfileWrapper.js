import { LightningElement, track, api } from 'lwc';

export default class FreelanceProfileWrapper extends LightningElement {
    @track hot_frilanstolkEditProfile = false;
    @track hot_frilanstolkUserInformation = true;
    editProfile() {
        this.hot_frilanstolkEditProfile = true;
        this.hot_frilanstolkUserInformation = false;
    }
    updateProfile = () => {
        this.hot_frilanstolkEditProfile = false;
        this.hot_frilanstolkUserInformation = true;
        alert('Profilen er oppdatert!');
    };
}
