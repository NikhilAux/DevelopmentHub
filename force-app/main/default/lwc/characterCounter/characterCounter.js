import { LightningElement, api, track } from 'lwc';

export default class AccountDetailPage extends LightningElement {
    @api recordId;
    @track name = '';
    @track nameLength = 0;

    handleInput(event) {
        const field = event.target.name;
        const value = event.target.value;

        if (field === 'Name') {
            this.name = value;
            this.nameLength = value.length;
        }

        // Repeat for other text fields if needed
    }

    handleChange(event) {
        // Optional if you want to track dirty values or do validations
    }
}