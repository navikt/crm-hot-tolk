import { LightningElement, api } from 'lwc';
import personHighlightPanel from './personHighlightPanel.html';

export default class SkeletonLoadingComponent extends LightningElement {
    @api type;
    render() {
        return personHighlightPanel;
    }
}
