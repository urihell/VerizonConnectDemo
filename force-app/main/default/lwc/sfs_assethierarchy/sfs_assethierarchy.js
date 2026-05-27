import { LightningElement,api,track } from 'lwc';
import fetchAssets from '@salesforce/apex/SFS_AssetHierarchy.getAssetHierarchy';

export default class Sfs_assethierarchy extends LightningElement {
        @api recordId;
        @track assetHierarchy;
        @track error;
        connectedCallback() {
            this.fetchAssetHierarchy();            
        }
        
        fetchAssetHierarchy() {
        fetchAssets({ woId: this.recordId })
            .then(result => {
                if (result) {
                    this.assetHierarchy = result;
                    this.error = undefined;
                } else {
                    this.assetHierarchy = null;
                    this.error = 'No assets found.';
                }
            })
            .catch(error => {
                this.error = error;
                this.assetHierarchy = undefined;
                console.error('Error fetching asset hierarchy:', error);
            });
    }

}