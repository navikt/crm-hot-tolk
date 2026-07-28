const fs = require('fs');
const path = require('path');

const COMPONENT_DIRECTORY = path.resolve(__dirname, '..');

describe('c-hot-tjenesteleverandor-sa-accepted-list details navigation contract', () => {
    it('keeps the modal and routes Vis mer info to the separate Experience page', () => {
        const template = fs.readFileSync(
            path.join(COMPONENT_DIRECTORY, 'hot_tjenesteleverandorSaAcceptedList.html'),
            'utf8'
        );
        const controller = fs.readFileSync(
            path.join(COMPONENT_DIRECTORY, 'hot_tjenesteleverandorSaAcceptedList.js'),
            'utf8'
        );

        expect(template).toContain('<dialog class="modal-container"');
        expect(template).toContain('label="Vis mer info"');
        expect(template).toContain('onclick={handleViewMoreInfo}');
        expect(controller).toContain("type: 'comm__namedPage'");
        expect(controller).toContain("name: 'Oppdragsdetaljer__c'");
        expect(controller).toContain('c__recordId: this.recordId');
        expect(controller).not.toContain("type: 'standard__recordPage'");
    });
});
