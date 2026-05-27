import { LightningElement,api } from 'lwc';
export default class Sfs_assetdetails extends LightningElement {

 @api assetHierarchy;
 assetStatus=true;
 assetLabel='';
 connectedCallback() {
     if(this.assetHierarchy.Status=='Installed')
     {
         this.assetStatus=true;
         this.assetLabel=this.assetHierarchy.Name+ ' - Normal'
     }
     else
     {
         this.assetStatus=false;
        this.assetLabel=this.assetHierarchy.Name+ ' - Critical'

     }
 }
}