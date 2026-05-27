import { LightningElement, api } from 'lwc';
import generate from '@salesforce/apex/SDO_SFS_GenerateJwtApex.generate';
import isGuest from '@salesforce/user/isGuest';

export default class SdoSfsGenerateJwtLwc extends LightningElement {
    @api
    getJwt(callback) {
        if (!callback) return;
        if (isGuest) return callback({ jwt: null, errors: null });

        generate()
            .then((result) => {
                callback({ jwt: result, errors: null });
            })
            .catch((error) => {
                callback({ jwt: null, errors: error });
            });
    }

    connectedCallback() {
        console.log('isGuest: ' + isGuest);
        const evt = new CustomEvent('onGenerateJwtComponentCreated', {
            detail: {
                component: this,
            },
        });
        window.dispatchEvent(evt);
    }
}