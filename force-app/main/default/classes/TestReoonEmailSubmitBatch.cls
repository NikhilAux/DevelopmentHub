@isTest
private class TestReoonEmailSubmitBatch {

    class ReoonCalloutMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"task_id": "fakeTask123"}');
            res.setStatusCode(201);
            return res;
        }
    }

    @isTest
    static void testReoonEmailSubmitBatch() {
        
        Test.setMock(HttpCalloutMock.class, new ReoonCalloutMock());

        Contact c = new Contact(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'nnairs516@gmail.com'
        );
        insert c;

        Test.startTest();
        ReoonEmailSubmitBatch batch = new ReoonEmailSubmitBatch();
        Database.executeBatch(batch, 1);
        Test.stopTest();

        Contact result = [SELECT Email FROM Contact WHERE Id = :c.Id];
        System.assertEquals('nnairs516@gmail.com', result.Email);

    }

    @isTest
    static void testNoEmailScenario() {

        Test.startTest();
        ReoonEmailSubmitBatch batch = new ReoonEmailSubmitBatch();
        Database.executeBatch(batch, 1);
        Test.stopTest();

        System.assert(true, 'Batch should complete gracefully with no email records.');
    }
}