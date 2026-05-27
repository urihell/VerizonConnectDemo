import { LightningElement } from 'lwc';

export default class SdoSfsLaunchChat extends LightningElement {
    connectedCallback() {
        const launchChatRequestEvent = new CustomEvent(
            'onSdoSfsLaunchChatRequest'
        );

        window.dispatchEvent(launchChatRequestEvent);
    }
}