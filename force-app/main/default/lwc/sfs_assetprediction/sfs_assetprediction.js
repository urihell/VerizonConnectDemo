import { LightningElement,api } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import createPlan from '@salesforce/apex/SFS_AssetPredictionController.createWorkPlan';
export default class Sfs_assetprediction extends LightningElement {

@api predictionMsg;
@api recordId;
@api workPlanName;
@api workStepName;
addPlan()
{
    createPlan({ woId: this.recordId,workPlanName:this.workPlanName,workStepName:this.workStepName })
      .then(result => {
        console.log('Result', result);
        const evt = new ShowToastEvent({
            title: 'Success',
            message: 'Work Plan added Successfully!',
            variant: 'Success',
            });
            this.dispatchEvent(evt);
      })
      .catch(error => {
        console.error('Error:', error);
         const evt = new ShowToastEvent({
            title: 'Warning',
            message: error,
            variant: 'Warning',
            });
            this.dispatchEvent(evt);
    });

}
}