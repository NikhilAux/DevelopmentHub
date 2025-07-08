public class quickBooksInvoices {
    public static final string QB_BASE_URL = 'https://sandbox-quickbooks.api.intuit.com/v3/company/';

    public static void getQuickBooksInvoices() {
        QuickBooks_Details__c qbDetails = [SELECT Id, RealmId__c, Access_Token__c FROM QuickBooks_Details__c LIMIT 1];

        String requestURL = QB_BASE_URL + qbDetails.RealmId__c + '/query?query=' +
            EncodingUtil.urlEncode('select * from Invoice', 'UTF-8') + '&minorversion=69';

        HttpRequest request = new HttpRequest();
        request.setEndpoint(requestURL);
        request.setMethod('GET');
        request.setHeader('Authorization', 'Bearer ' + qbDetails.Access_Token__c);
        request.setHeader('Accept', 'application/json');

        Http http = new Http();
        HTTPResponse response = http.send(request);

        if (response.getStatusCode() == 200 && response.getBody() != null) {
            String respBody = response.getBody();
            System.debug('Invoice Response: ' + respBody);

            Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(respBody);
            List<Object> invoicesFromQB = (List<Object>) ((Map<String, Object>) jsonResponse.get('QueryResponse')).get('Invoice');

            List<Invoice__c> invoicesToUpsert = new List<Invoice__c>();

            for (Object invObj : invoicesFromQB) {
                Map<String, Object> qbInvoice = (Map<String, Object>) invObj;
                Invoice__c invoice = new Invoice__c();

                invoice.QuickBooks_Id__c = String.valueOf(qbInvoice.get('Id')); // External ID for upsert
                invoice.InvoiceNumber__c = String.valueOf(qbInvoice.get('DocNumber'));
                invoice.Status__c = String.valueOf(qbInvoice.get('TxnStatus'));
                
                if (qbInvoice.containsKey('TxnDate')) {
                    invoice.InvoiceDate__c = Date.valueOf((String) qbInvoice.get('TxnDate'));
                }

                if (qbInvoice.containsKey('DueDate')) {
                    invoice.DueDate__c = Date.valueOf((String) qbInvoice.get('DueDate'));
                }

                if (qbInvoice.containsKey('TotalAmt')) {
                    invoice.Amount__c = (Decimal) qbInvoice.get('TotalAmt');
                }

                // Optional: Set related Account if you have Account records mapped with QuickBooks customer
                if (qbInvoice.containsKey('CustomerRef')) {
                    Map<String, Object> custRef = (Map<String, Object>) qbInvoice.get('CustomerRef');
                    String quickBooksCustomerId = (String) custRef.get('value');

                    // Match against Account.QuickBooks_Id__c
                    List<Account> matchedAccounts = [SELECT Id FROM Account WHERE QuickBooks_Id__c = :quickBooksCustomerId LIMIT 1];
                    if (!matchedAccounts.isEmpty()) {
                        invoice.BillingAccountId__c = matchedAccounts[0].Id;
                    }
                }

                invoicesToUpsert.add(invoice);
            }

            if (!invoicesToUpsert.isEmpty()) {
                upsert invoicesToUpsert QuickBooks_Id__c;
                System.debug('Upserted ' + invoicesToUpsert.size() + ' invoices into Salesforce.');
            } else {
                System.debug('No invoices found to upsert.');
            }
        } else {
            System.debug('Failed to fetch invoices. StatusCode: ' + response.getStatusCode() + ', Body: ' + response.getBody());

            if (response.getStatusCode() == 401) {
                System.debug('Access token expired. Consider calling token refresh logic here.');
            }
        }
    }
}