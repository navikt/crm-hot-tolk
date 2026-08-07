import { LightningElement } from 'lwc';

export const open = jest.fn(() => Promise.resolve());
export const close = jest.fn();

export default class LightningModal extends LightningElement {
    static open(options) {
        return open(options);
    }

    close(result) {
        close(result);
    }
}
