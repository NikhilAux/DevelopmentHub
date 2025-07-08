public class OpportunityTriggerHandler {

    public static void GreatestOppAmountOfAccount(List<Opportunity> oppList, TriggerOperation triggerOp) {
        
        if (triggerOp == TriggerOperation.AFTER_INSERT) {
            
            GreatestOppAmountOfAccount.OppWithHighestAmtCalculationOnInsertDeleteUndelete(oppList);
            
        } else if (triggerOp == TriggerOperation.AFTER_DELETE) {
            
            GreatestOppAmountOfAccount.OppWithHighestAmtCalculationOnInsertDeleteUndelete(oppList);
            
        } else if (triggerOp == TriggerOperation.AFTER_UNDELETE) {
            
            GreatestOppAmountOfAccount.OppWithHighestAmtCalculationOnInsertDeleteUndelete(oppList);
            
        }
    }
    
    public static void GreatestOppAmountOfAccountUpdate(List<Opportunity> oppList, Map<Id, Opportunity> oldMap, TriggerOperation triggerOp) {
        
        if (triggerOp == TriggerOperation.AFTER_UPDATE) {
            
            GreatestOppAmountOfAccount.OppWithHighestAmtCalculationOnUpdate(oppList, oldMap);
            
        }
    }
}