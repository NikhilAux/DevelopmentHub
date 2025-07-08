public with sharing class ReoonEmailVerifier {
    private static final String API_KEY = Label.Reoon_API_Key;

    public class VerificationResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String email;
        @AuraEnabled public String status;
        @AuraEnabled public String sub_status;
        @AuraEnabled public Boolean safe_to_send;
        @AuraEnabled public String domain;
        @AuraEnabled public String did_you_mean;
        @AuraEnabled public String error;
    }

    @AuraEnabled
    public static VerificationResult verifyEmailFromLWC(Id recordId, String objectType) {
        String email = '';

        if (objectType == 'Contact') {
            Contact c = [SELECT Id, Email FROM Contact WHERE Id = :recordId LIMIT 1];
            email = c.Email;
        } else if (objectType == 'Lead') {
            Lead l = [SELECT Id, Email FROM Lead WHERE Id = :recordId LIMIT 1];
            email = l.Email;
        }

        if (String.isBlank(email)) {
            VerificationResult emptyResult = new VerificationResult();
            emptyResult.success = false;
            emptyResult.error = 'Email is empty';
            return emptyResult;
        }

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        String url = 'https://emailverifier.reoon.com/api/v1/verify?email=' +
            EncodingUtil.urlEncode(email, 'UTF-8') +
            '&key=' + API_KEY + '&mode=power';
        req.setEndpoint(url);
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + API_KEY);
        req.setHeader('Accept', 'application/json');

        HttpResponse res = http.send(req);
        VerificationResult result = (VerificationResult) JSON.deserialize(res.getBody(), VerificationResult.class);
        system.debug(objectType);
        system.debug(recordId);
        system.debug(result);

        if (result != null) {
            if (objectType == 'Contact') {
                Contact c = [SELECT Id FROM Contact WHERE Id = :recordId LIMIT 1];
                system.debug(c);
                c.Email_Verification_Status__c = result.status;
                c.Last_Email_Validated_Date__c = Date.today();
                update c;
            } else if (objectType == 'Lead') {
                Lead l = [SELECT Id FROM Lead WHERE Id = :recordId LIMIT 1];
                l.Email_Verification_Status__c = result.status;
                l.Last_Email_Validated_Date__c = Date.today();
                update l;
            }
        }

        return result;
    }
}