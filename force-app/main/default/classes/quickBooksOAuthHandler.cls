public class quickBooksOAuthHandler {

    public String buttonLink { get; private set; }
    public Boolean showHideOAuthButton { get; private set; }
    public Boolean isAuthorized { get; private set; }
    public String code;
    public String realmId;

    QuickBooks_Details__c qbDetails;
    final String redirect_uri = 'https://orgfarm-42fa973fcf-dev-ed--c.develop.vf.force.com/apex/qboAuthorizationRedirect'; // Replace with your actual VF URL
    final String base_url = 'https://appcenter.intuit.com/connect/oauth2?response_type=code&scope=com.intuit.quickbooks.accounting&state=testStateSecurity';

    public quickBooksOAuthHandler() {
        showHideOAuthButton = false;
        isAuthorized = false;

        try {
            qbDetails = [SELECT Id, Client_Id__c, Client_Secret__c FROM QuickBooks_Details__c LIMIT 1];
            System.debug('Fetched QuickBooks_Details__c: ' + qbDetails);

            Map<String, String> urlParameters = ApexPages.currentPage().getParameters();
            System.debug('URL Parameters: ' + urlParameters);
            system.debug(urlParameters.get('code'));
            system.debug(urlParameters.get('realmId'));

            if (urlParameters.containsKey('realmId')) {
                code = urlParameters.get('code');
                realmId = urlParameters.get('realmId');
                System.debug('Received code: ' + code + ', realmId: ' + realmId);
            } else {
                showHideOAuthButton = true;
                buttonLink = base_url + '&client_id=' + qbDetails.Client_Id__c + '&redirect_uri=' + redirect_uri;
                System.debug('OAuth Button URL: ' + buttonLink);
            }

        } catch (Exception e) {
            System.debug('Exception in Constructor: ' + e.getMessage());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error initializing QuickBooks OAuth Handler: ' + e.getMessage()));
        }
    }

    public PageReference getQuickBooksOAuthTokens() {
        if (String.isNotBlank(code) && String.isNotBlank(realmId)) {
            try {
                System.debug('Getting tokens with code: ' + code + ' and realmId: ' + realmId);
                Blob headerTokens = Blob.valueOf(qbDetails.Client_Id__c + ':' + qbDetails.Client_Secret__c);
                String authorizationToken = 'Basic ' + EncodingUtil.base64Encode(headerTokens);
                String payloadBody = 'grant_type=authorization_code&code=' + code + '&redirect_uri=' + redirect_uri;

                HttpRequest request = new HttpRequest();
                request.setEndpoint('https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer');
                request.setMethod('POST');
                request.setHeader('Authorization', authorizationToken);
                request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
                request.setHeader('Accept', 'application/json');
                request.setBody(payloadBody);

                System.debug('HTTP Request: ' + request);

                Http http = new Http();
                HttpResponse res = http.send(request);

                System.debug('HTTP Response Status: ' + res.getStatus());
                System.debug('HTTP Response Code: ' + res.getStatusCode());
                System.debug('HTTP Response Body: ' + res.getBody());

                if (res.getStatusCode() == 200 && String.isNotBlank(res.getBody())) {
                    isAuthorized = true;
                    updateQBDeatilsinSalesforce(res.getBody(), realmId, qbDetails.Id);
                } else {
                    System.debug('Failed to get tokens. StatusCode: ' + res.getStatusCode() + ', Response: ' + res.getBody());
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Failed to retrieve QuickBooks tokens. Check the debug logs.'));
                }

            } catch (Exception e) {
                System.debug('Exception during token exchange: ' + e.getMessage());
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error during token exchange: ' + e.getMessage()));
            }
        } else {
            System.debug('Code or RealmId is missing. Code: ' + code + ', RealmId: ' + realmId);
        }

        return null;
    }

    public static void updateQBDeatilsinSalesforce(String resBody, String realmId, Id qbDetailsId) {
        System.debug('Parsing token response: ' + resBody);
        try {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(resBody);
            QuickBooks_Details__c qbDetails = new QuickBooks_Details__c(Id = qbDetailsId);

            if (responseMap.containsKey('access_token')) {
                qbDetails.Access_Token__c = String.valueOf(responseMap.get('access_token'));
                System.debug('Access Token set');
            }

            if (responseMap.containsKey('refresh_token')) {
                qbDetails.Refresh_Token__c = String.valueOf(responseMap.get('refresh_token'));
                System.debug('Refresh Token set');
            }

            if (responseMap.containsKey('expires_in')) {
                qbDetails.Access_Token_Expiry__c = Integer.valueOf(responseMap.get('expires_in'));
                System.debug('Access Token Expiry set');
            }

            if (responseMap.containsKey('x_refresh_token_expires_in')) {
                qbDetails.Refresh_Token_Expiry__c = Integer.valueOf(responseMap.get('x_refresh_token_expires_in'));
                System.debug('Refresh Token Expiry set');
            }

            if (String.isNotBlank(realmId)) {
                qbDetails.RealmId__c = realmId;
                System.debug('RealmId set: ' + realmId);
            }

            update qbDetails;
            System.debug('QuickBooks details updated successfully.');

        } catch (Exception e) {
            System.debug('Exception while updating QuickBooks details: ' + e.getMessage());
        }
    }
}