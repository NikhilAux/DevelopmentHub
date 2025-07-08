@isTest
private class TestReoonResultFetcherQueueable {

    class ReoonResultMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            Map<String, Object> resultMap = new Map<String, Object>{
                'results' => new Map<String, Object>{
                    'nnairs516@gmail.com' => new Map<String, Object>{
                        'status' => 'valid'
                    }
                }
            };

            res.setBody(JSON.serialize(resultMap));
            res.setStatusCode(200);
            return res;
        }
    }

    @isTest
    static void testSuccessScenario() {
       
        Contact c = new Contact(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'nnairs516@gmail.com'
        );
        insert c;

        Test.setMock(HttpCalloutMock.class, new ReoonResultMock());

        Test.startTest();
        System.enqueueJob(new ReoonResultFetcherQueueable('testTask123'));
        Test.stopTest();

        Contact updated = [SELECT Email_Verification_Status__c, Last_Email_Verified__c 
                           FROM Contact WHERE Id = :c.Id];
        System.assertEquals('valid', updated.Email_Verification_Status__c);
        System.assertEquals(Date.today(), updated.Last_Email_Verified__c);
    }

    class EmptyResultMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"results": {}}');
            return res;
        }
    }

    @isTest
    static void testEmptyResultsScenario() {
        Contact c = new Contact(
            FirstName = 'NoUpdate',
            LastName = 'User',
            Email = 'nochange@example.com'
        );
        insert c;

        Test.setMock(HttpCalloutMock.class, new EmptyResultMock());

        Test.startTest();
        System.enqueueJob(new ReoonResultFetcherQueueable('emptyTask123'));
        Test.stopTest();

        Contact result = [SELECT Email_Verification_Status__c FROM Contact WHERE Id = :c.Id];
        System.assertEquals(null, result.Email_Verification_Status__c);
    }
}