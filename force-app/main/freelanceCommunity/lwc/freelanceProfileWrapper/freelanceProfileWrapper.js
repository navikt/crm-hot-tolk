import { LightningElement, track } from 'lwc';

export default class FreelanceProfileWrapper extends LightningElement {
    @track hot_frilanstolkEditProfile = false;
    showSearch() {
        console.log(2);
        this.hot_frilanstolkEditProfile = true;
        this.diabled = true;
    }
}
