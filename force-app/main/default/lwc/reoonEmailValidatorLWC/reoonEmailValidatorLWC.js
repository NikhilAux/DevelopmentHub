import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import verifyEmailFromLWC from '@salesforce/apex/ReoonEmailVerifier.verifyEmailFromLWC';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

const EMAIL_FIELD = ['Contact.Email', 'Lead.Email'];

export default class EmailValidator extends LightningElement {
    @api recordId;
    @api objectApiName;

    email = '';
    message = '';
    messageClass = '';
    showModal = false;

    @wire(getRecord, { recordId: '$recordId', fields: EMAIL_FIELD })
    wiredRecord({ data, error }) {
        if (data) {
            this.email = getFieldValue(data, `${this.objectApiName}.Email`);
        } else if (error) {
            this.message = 'Error fetching email.';
            this.messageClass = 'error-text';
        }
    }

    handleEmailChange(event) {
        this.email = event.target.value.trim();
    }

    validateEmail() {
        if (!this.recordId || !this.objectApiName) {
            this.message = 'Missing record context.';
            this.messageClass = 'error-text';
            this.showModal = true;
            return;
        }

        verifyEmailFromLWC({ recordId: this.recordId, objectType: this.objectApiName })
            .then(result => {
                if (result) {
                    this.message = `✅ ${result.status}`;
                    this.messageClass = result.status === 'valid' ? 'success-text' : 'warning-text';
                } else {
                    this.message = '❌ ' + (result.error || 'Verification failed.');
                    this.messageClass = 'error-text';
                }
                this.showModal = true;
            })
            .catch(error => {
                this.message = '❌ Apex error: ' + error.body.message;
                this.messageClass = 'error-text';
                this.showModal = true;
            });
    }

    closeModal() {
        this.showModal = false;
    }
}