import { LightningElement, api } from 'lwc';

export default class CommunityErrorItem extends LightningElement {
    @api error;

    handleLinkClick(event) {
        event.preventDefault();
        const clickedItemEvent = new CustomEvent('clickeditemevent', {
            detail: this.error.EventItem
        });

        this.dispatchEvent(clickedItemEvent);
    }

    get linkToElement() {
        return this.error.EventItem !== '';
    }
}
