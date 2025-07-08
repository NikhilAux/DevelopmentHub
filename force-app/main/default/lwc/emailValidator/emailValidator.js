import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import verifyEmailFromLWC from '@salesforce/apex/ReoonEmailVerifier.verifyEmailFromLWC';
import { getRecord } from 'lightning/uiRecordApi';

const EMAIL_FIELD = ['Contact.Email', 'Lead.Email']; // flexible for both

export default class EmailValidator extends LightningElement {
    @api recordId;
    @api objectApiName;

    email = '';
    message = '';
    messageClass = '';

    // Auto-populate email from record
    @wire(getRecord, { recordId: '$recordId', fields: EMAIL_FIELD })
    wiredRecord({ data, error }) {
        if (data) {
            this.email = data.fields.Email.value;
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
            return;
        }

        verifyEmailFromLWC({ recordId: this.recordId, objectType: this.objectApiName })
            .then(result => {
                if (result && result.success) {
                    this.message = `✅ ${result.status}`;
                    this.messageClass = result.status === 'valid' ? 'success-text' : 'warning-text';
                } else {
                    this.message = '❌ ' + (result.error || 'Verification failed.');
                    this.messageClass = 'error-text';
                }
            })
            .catch(error => {
                this.message = '❌ Apex error: ' + error.body.message;
                this.messageClass = 'error-text';
            });
    }
}