public with sharing class AccountCharacterCounterController {
    @AuraEnabled(cacheable=true)
    public static Account getAccountDetails(Id accountId) {
        return [SELECT Id, Name, Owner.Name, Parent.Name, AccountNumber, Type, Industry, AnnualRevenue,
                BillingStreet, BillingCity, BillingState, BillingPostalCode, CustomerPriority__c, SLAExpirationDate__c,
                Active__c, CreatedBy.Name, CreatedDate, LastModifiedBy.Name, LastModifiedDate
                FROM Account
                WHERE Id = :accountId
                LIMIT 1];
    }
}