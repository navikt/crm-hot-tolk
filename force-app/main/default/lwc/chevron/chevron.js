import { LightningElement, api } from 'lwc';

export default class Chevron extends LightningElement {
    @api direction;
    isRight = false;
    isLeft = false;
    connectedCallback() {
        this.isRight = this.direction.toLowerCase() === 'right';
        this.isLeft = this.direction.toLowerCase() === 'left';
    }
}
