trigger LeadTrigger on Lead (after update) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        LeadTaskAutomationHandler.handleStatusBasedTaskAutomation(Trigger.new, Trigger.oldMap);
    }
}