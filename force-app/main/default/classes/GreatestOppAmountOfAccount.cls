public class GreatestOppAmountOfAccount {
    
    public static void OppWithHighestAmtCalculationOnInsertDeleteUndelete(List<Opportunity> opps) {
        
        Set<Id> accountIds = new Set<Id>();
        
        for(Opportunity opp : opps) {
            
            accountIds.add(opp.AccountId);
        }
        
        if (accountIds.isEmpty()) return;
        
        List<Opportunity> relatedOpps = [
            SELECT Id, Name, Amount, AccountId 
            FROM Opportunity 
            WHERE AccountId IN :accountIds AND Amount != null
        ];
        
        Map<Id, Opportunity> accIdToHighestOppMap = new Map<Id, Opportunity>();
        
        for(Opportunity opp : relatedOpps) {
            
            Opportunity current = accIdToHighestOppMap.get(opp.AccountId);
            
            if(current == null || opp.Amount > current.Amount) {
                
                accIdToHighestOppMap.put(opp.AccountId, opp);
            }
        }
        
        List<Account> accToUpdate = [SELECT Id, Opportunity_With_Highest_Amount__c 
                                     FROM Account 
                                     WHERE Id IN:accIdToHighestOppMap.keySet()
                                    ];
        
        for(Account acc : accToUpdate) {
            
            Opportunity bestOpp = accIdToHighestOppMap.get(acc.Id);
            
            if(bestOpp != null) {
                
                acc.Opportunity_With_Highest_Amount__c = bestOpp.Name;
                
            }
        }
        
         if (!accToUpdate.isEmpty()) {
            update accToUpdate;
        }
        
    }
    
    public static void OppWithHighestAmtCalculationOnUpdate(List<Opportunity> opps, Map<Id, Opportunity> oldMap) {
        
        Set<Id> accountIds = new Set<Id>();
        
        for(Opportunity opp : opps) {
            
             Opportunity oldOpp = oldMap.get(opp.Id);
            
            if (opp.AccountId != oldOpp.AccountId || opp.Amount != oldOpp.Amount) {
            if (opp.AccountId != null) {
                accountIds.add(opp.AccountId); 
            }
            if (oldOpp.AccountId != null) {
                accountIds.add(oldOpp.AccountId);
            }
        }
        }
        
        if (accountIds.isEmpty()) return;
        
        List<Opportunity> relatedOpps = [
            SELECT Id, Name, Amount, AccountId 
            FROM Opportunity 
            WHERE AccountId IN :accountIds AND Amount != null
        ];
        
        Map<Id, Opportunity> accIdToHighestOppMap = new Map<Id, Opportunity>();
        
        for(Opportunity opp : relatedOpps) {
            
            Opportunity current = accIdToHighestOppMap.get(opp.AccountId);
            
            if(current == null || opp.Amount > current.Amount) {
                
                accIdToHighestOppMap.put(opp.AccountId, opp);
            }
        }
        
        List<Account> accToUpdate = [SELECT Id, Opportunity_With_Highest_Amount__c 
                                     FROM Account 
                                     WHERE Id IN:accIdToHighestOppMap.keySet()
                                    ];
        
        for(Account acc : accToUpdate) {
            
            Opportunity bestOpp = accIdToHighestOppMap.get(acc.Id);
            
            if(bestOpp != null) {
                
                acc.Opportunity_With_Highest_Amount__c = bestOpp.Name;
                
            }
        }
        
         if (!accToUpdate.isEmpty()) {
            update accToUpdate;
        }
        
    }

}