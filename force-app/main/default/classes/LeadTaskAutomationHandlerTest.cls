@isTest
public class LeadTaskAutomationHandlerTest {

    @testSetup
    static void setupTestData() {
        List<Lead> testLeads = new List<Lead>();

        for (Integer i = 0; i < 3; i++) {
            testLeads.add(new Lead(
                FirstName = 'Test',
                LastName = 'Lead' + i,
                Company = 'Test Company',
                Status = 'New'
            ));
        }

        insert testLeads;

        Task oldTask = new Task(
            Subject = 'Follow-Up Call',
            WhoId = testLeads[0].Id,
            OwnerId = UserInfo.getUserId(),
            Status = 'Not Started',
            Priority = 'Normal',
            ActivityDate = Date.today(),
            Description = 'Old auto-gen task',
            Status_Tag__c = 'New',
            Lead_Status_Based_Auto_Creation__c = true
        );
        insert oldTask;
    }

    @isTest
    static void testHotLeadTaskCreation() {
        
        Lead lead = [SELECT Id, Status FROM Lead LIMIT 1];
        lead.Status = 'HOT';

        Test.startTest();
        update lead;
        Test.stopTest();

        List<Task> tasks = [SELECT Id, ActivityDate, Status_Tag__c, Subject FROM Task WHERE WhoId = :lead.Id];
        System.assertEquals(52, tasks.size(), 'Should create 52 tasks for HOT status');
        System.assertEquals('HOT', tasks[0].Status_Tag__c);
    }

    @isTest
    static void testFollowUpLeadTaskCreation() {
        Lead lead = [SELECT Id, Status FROM Lead LIMIT 1 OFFSET 1];
        lead.Status = 'FOLLOW-UP';

        Test.startTest();
        update lead;
        Test.stopTest();

        List<Task> tasks = [SELECT Id FROM Task WHERE WhoId = :lead.Id];
        System.assertEquals(17, tasks.size(), 'Should create 17 tasks for FOLLOW-UP status');
    }

    @isTest
    static void testLongTermLeadTaskCreation() {
        Lead lead = [SELECT Id, Status FROM Lead LIMIT 1 OFFSET 2];
        lead.Status = 'LONG-TERM FOLLOW-UP';

        Test.startTest();
        update lead;
        Test.stopTest();

        List<Task> tasks = [SELECT Id FROM Task WHERE WhoId = :lead.Id];
        System.assertEquals(13, tasks.size(), 'Should create 13 tasks for LONG-TERM FOLLOW-UP status');
    }

    @isTest
    static void testNoStatusChange_NoTasksCreated() {
        Lead lead = [SELECT Id, Status FROM Lead LIMIT 1];
        lead.LastName = 'No Change';

        Test.startTest();
        update lead;
        Test.stopTest();

        List<Task> tasks = [SELECT Id FROM Task WHERE WhoId = :lead.Id];
        System.assertEquals(1, tasks.size(), 'Should not create new tasks if status hasn’t changed');
    }

    @isTest
    static void testOldTasksDeletedOnStatusChange() {
       
        Lead lead = [SELECT Id FROM Lead LIMIT 1];
        lead.Status = 'HOT';

        Test.startTest();
        update lead;
        Test.stopTest();

        List<Task> tasks = [SELECT Id, Status_Tag__c FROM Task WHERE WhoId = :lead.Id];
        System.assertEquals(52, tasks.size(), 'Should delete old task and create new HOT tasks');
        for (Task t : tasks) {
            System.assertEquals('HOT', t.Status_Tag__c);
        }
    }
}