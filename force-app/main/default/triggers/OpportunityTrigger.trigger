trigger OpportunityTrigger on Opportunity (after insert, after update, after delete, after undelete) {
    
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            OpportunityTriggerHandler.GreatestOppAmountOfAccount(Trigger.new, TriggerOperation.AFTER_INSERT);
        }
        else if (Trigger.isUpdate) {
            OpportunityTriggerHandler.GreatestOppAmountOfAccountUpdate(Trigger.new, Trigger.oldMap, TriggerOperation.AFTER_UPDATE);
        }
        else if (Trigger.isDelete) {
            OpportunityTriggerHandler.GreatestOppAmountOfAccount(Trigger.old, TriggerOperation.AFTER_DELETE);
        }
        else if (Trigger.isUndelete) {
            OpportunityTriggerHandler.GreatestOppAmountOfAccount(Trigger.new, TriggerOperation.AFTER_UNDELETE);
        }
    }
}