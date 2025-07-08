global class ReoonEmailSubmitBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Email FROM Contact 
            WHERE Email != null AND Email_Verification_Status__c = null 
        ]);
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<Contact> contacts = (List<Contact>)scope;
        List<String> emailList = new List<String>();
        
        for (Contact c : contacts) {
            emailList.add(c.Email);
        }

        if (emailList.isEmpty()) return;

        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://emailverifier.reoon.com/api/v1/create-bulk-verification-task/');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');

        Map<String, Object> payload = new Map<String, Object>{
            'name' => 'EmailVerifyBatch-' + DateTime.now().getTime(),
            'emails' => emailList,
            'key' => System.Label.Reoon_API_key
        };

        req.setBody(JSON.serialize(payload));

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 201) {
            Map<String, Object> resJson = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            String taskId = String.valueOf(resJson.get('task_id'));
            System.debug('Reoon Task ID: ' + taskId);

            String jobName = 'FetchReoonResult_' + taskId;
            String cronExp = getCronExpression(3);
            System.schedule(jobName, cronExp, new ReoonResultScheduler(taskId));
        } else {
            System.debug('Failed to submit emails to Reoon: ' + res.getBody());
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('Finished submitting emails to Reoon.');
    }

    private static String getCronExpression(Integer delayMinutes) {
        DateTime future = System.now().addMinutes(delayMinutes);
        return String.format('0 {0} {1} {2} {3} ? {4}', new List<String>{
            String.valueOf(future.minute()),
            String.valueOf(future.hour()),
            String.valueOf(future.day()),
            String.valueOf(future.month()),
            String.valueOf(future.year())
        });
    }
}