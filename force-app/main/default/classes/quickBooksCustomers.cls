public class quickBooksCustomers {
    public static final String QB_BASE_URL = 'https://sandbox-quickbooks.api.intuit.com/v3/company/';

    public static void getAndUpsertQuickBooksCustomers() {
        QuickBooks_Details__c qbDetails = [SELECT Id, RealmId__c, Access_Token__c FROM QuickBooks_Details__c LIMIT 1];

        String requestURL = QB_BASE_URL + qbDetails.RealmId__c +
            '/query?query=' + EncodingUtil.urlEncode('select * from Customer', 'UTF-8') + '&minorversion=69';

        HttpRequest request = new HttpRequest();
        request.setEndpoint(requestURL);
        request.setMethod('GET');
        request.setHeader('Authorization', 'Bearer ' + qbDetails.Access_Token__c);
        request.setHeader('Accept', 'application/json');

        Http http = new Http();
        HttpResponse response = http.send(request);

        if (response.getStatusCode() == 200 && response.getBody() != null) {
            String responseBody = response.getBody();
            Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
            system.debug(payload);
            system.debug(payload.get('QueryResponse'));
            List<Object> customers = (List<Object>) ((Map<String, Object>) payload.get('QueryResponse')).get('Customer');
            system.debug(customers);

            List<Account> accountsToUpsert = new List<Account>();

            for (Object cust : customers) {
                Map<String, Object> custMap = (Map<String, Object>) cust;

                String name = (String) custMap.get('DisplayName');
                Map<String, Object> phoneObj = (Map<String, Object>) custMap.get('PrimaryPhone');
                String phone = phoneObj != null ? (String) phoneObj.get('FreeFormNumber') : null;
                String QBId = (String) custMap.get('Id');

                Account existingAcc = findMatchingAccount(name, phone);
                if (existingAcc == null) {
                    existingAcc = new Account();
                }

                existingAcc.Name = name;
                if (phone != null) existingAcc.Phone = phone;
                if (QBId != null) existingAcc.QuickBooks_Id__c = QBId;

                accountsToUpsert.add(existingAcc);
            }

            if (!accountsToUpsert.isEmpty()) {
                Database.upsert(accountsToUpsert);
                System.debug('Accounts upserted: ' + accountsToUpsert.size());
            }
        } else {
            System.debug('Error: ' + response.getBody());
        }
    }

    private static Account findMatchingAccount(String name, String phone) {
        List<Account> results;

        if (name != null && phone != null) {
            results = [SELECT Id FROM Account WHERE Name = :name AND Phone = :phone LIMIT 1];
            if (!results.isEmpty()) return results[0];
        }

        if (name != null) {
            results = [SELECT Id FROM Account WHERE Name = :name LIMIT 1];
            if (!results.isEmpty()) return results[0];
        }

        if (phone != null) {
            results = [SELECT Id FROM Account WHERE Phone = :phone LIMIT 1];
            if (!results.isEmpty()) return results[0];
        }

        return null;
    }
}