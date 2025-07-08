public class ReoonResultFetcherQueueable implements Queueable, Database.AllowsCallouts {
    private String taskId;

    public ReoonResultFetcherQueueable(String taskId) {
        this.taskId = taskId;
    }

    public void execute(QueueableContext context) {
        String apiKey = System.Label.Reoon_API_key;
        String url = 'https://emailverifier.reoon.com/api/v1/get-result-bulk-verification-task/?key=' 
                     + apiKey + '&task_id=' + taskId;

        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod('GET');
        Http http = new Http();

        try {
            HttpResponse res = http.send(req);
            if (res.getStatusCode() == 200) {
                Map<String, Object> resJson = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                Map<String, Object> results = (Map<String, Object>) resJson.get('results');
                system.debug(results);

                Set<String> emailSet = results.keySet();
                system.debug(emailSet);

                List<Contact> contacts = [SELECT Id, Email, Email_Verification_Status__c, Last_Email_Verified__c 
                                          FROM Contact 
                                          WHERE Email IN :emailSet];

                Map<String, Contact> emailToContactMap = new Map<String, Contact>();
                for (Contact c : contacts) {
                    emailToContactMap.put(c.Email, c);
                }

                List<Contact> updates = new List<Contact>();
                for (String email : emailSet) {
                    Map<String, Object> emailResult = (Map<String, Object>) results.get(email);

                    if (emailToContactMap.containsKey(email)) {
                        Contact c = emailToContactMap.get(email);
                        c.Email_Verification_Status__c = String.valueOf(emailResult.get('status'));
                        c.Last_Email_Verified__c = Date.today();
                        updates.add(c);
                    }
                }

                if (!updates.isEmpty()) {
                    update updates;
                }

                System.debug('Verification results updated successfully.');

            } else {
                System.debug('Error fetching results: ' + res.getBody());
            }

        } catch (Exception ex) {
            System.debug('Exception during result fetch: ' + ex.getMessage());
        }
    }

}