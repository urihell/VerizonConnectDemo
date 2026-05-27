import { LightningElement, api } from 'lwc';

export default class ResizableImageDisplay extends LightningElement {
    @api imageUrl; // Public property for the image URL
    @api width = '100%'; // Default width
    @api height = 'auto'; // Default height

    get imageStyle() {
        return `width: ${this.width}; height: ${this.height};`;
    }
}