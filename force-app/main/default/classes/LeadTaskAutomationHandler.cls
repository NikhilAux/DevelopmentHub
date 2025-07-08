public class LeadTaskAutomationHandler {

    public static void handleStatusBasedTaskAutomation(List<Lead> newLeads, Map<Id, Lead> oldLeadMap) {
        Map<Id, Lead> leadsToProcess = new Map<Id, Lead>();

        for (Lead newLead : newLeads) {
            Lead oldLead = oldLeadMap.get(newLead.Id);
            if (newLead.Status != null && oldLead != null && newLead.Status != oldLead.Status) {
                leadsToProcess.put(newLead.Id, newLead);
            }
        }

        if (leadsToProcess.isEmpty()) return;

        deleteOldTasks(oldLeadMap, leadsToProcess.keySet());

        List<Task> tasksToInsert = new List<Task>();
        for (Lead lead : leadsToProcess.values()) {
            tasksToInsert.addAll(generateTasksForStatus(lead));
        }

        if (!tasksToInsert.isEmpty()) {
            insert tasksToInsert;
        }
    }

    private static void deleteOldTasks(Map<Id, Lead> oldLeadMap, Set<Id> leadIdsToProcess) {
        List<Task> tasksToDelete = [
            SELECT Id, WhoId, Status_Tag__c, Status
            FROM Task
            WHERE WhoId IN :leadIdsToProcess
            AND Subject = 'Follow-Up Call'
            AND Status != 'Completed'
        ];

        List<Task> filteredTasks = new List<Task>();
        for (Task t : tasksToDelete) {
            Lead oldLead = oldLeadMap.get(t.WhoId);
            if (oldLead != null && t.Status_Tag__c == oldLead.Status) {
                filteredTasks.add(t);
            }
        }

        if (!filteredTasks.isEmpty()) {
            delete filteredTasks;
        }
    }

    private static List<Task> generateTasksForStatus(Lead lead) {
        List<Task> tasks = new List<Task>();
        Date startDate = Date.today();
        Integer numTasks;
        Integer intervalDays;

        switch on lead.Status {
            when 'HOT' {
                numTasks = 52;
                intervalDays = 7;
            }
            when 'FOLLOW-UP' {
                numTasks = 17;
                intervalDays = 21;
            }
            when 'LONG-TERM FOLLOW-UP' {
                numTasks = 13;
                intervalDays = 28;
            }
            when else {
                return tasks;
            }
        }

        for (Integer i = 0; i < numTasks; i++) {
            Task t = new Task();
            t.Subject = 'Follow-Up Call';
            t.WhoId = lead.Id;
            t.OwnerId = lead.OwnerId;
            t.Status = 'Not Started';
            t.Priority = 'Normal';
            t.ActivityDate = startDate.addDays(i * intervalDays);
            t.Description = 'Auto-generated follow-up based on ' + lead.Status + ' status';
            t.Status_Tag__c = lead.Status;
            t.Lead_Status_Based_Auto_Creation__c = true;
            tasks.add(t);
        }

        return tasks;
    }
}