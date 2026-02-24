/**
 * Test class for CCPAConsumerRightsService
 * Tests CCPA consumer rights: Know, Delete, Opt-Out
 * 
 * @author Elaro
 * @version 3.0
 */
@IsTest(testFor=CCPAConsumerRightsService.class)
private class CCPAConsumerRightsServiceTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test contacts
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 200; i++) {
            contacts.add(new Contact(
                FirstName = 'Test',
                LastName = 'Consumer' + i,
                Email = 'consumer' + i + '@example.com',
                Phone = '555-000' + String.valueOf(i).leftPad(4, '0')
            ));
        }
        insert as user contacts;
        
        // Create CCPA requests
        List<CCPA_Request__c> requests = new List<CCPA_Request__c>();
        for (Integer i = 0; i < 50; i++) {
            requests.add(new CCPA_Request__c(
                Contact__c = contacts[i].Id,
                Request_Type__c = 'Know',
                Status__c = 'Pending'
            ));
        }
        insert as user requests;
    }
    
    @IsTest
    static void testHandleKnowRequest_Success() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        CCPA_Request__c request = [SELECT Id FROM CCPA_Request__c WHERE Contact__c = :testContact.Id LIMIT 1];
        
        Test.startTest();
        CCPAConsumerRightsService service = new CCPAConsumerRightsService();
        Map<String, Object> result = service.handleKnowRequest(request.Id, testContact.Id);
        Test.stopTest();
        
        Assert.areEqual(true, result.get('success'), 'Know request should succeed');
        Assert.areNotEqual(null, result.get('personalInformation'), 'Personal information should be returned');
        Assert.areNotEqual(null, result.get('dataSales'), 'Data sales should be returned');
    }
    
    @IsTest
    static void testHandleKnowRequest_Bulk() {
        List<Contact> contacts = [SELECT Id FROM Contact LIMIT 200];
        List<CCPA_Request__c> requests = [SELECT Id FROM CCPA_Request__c LIMIT 50];
        
        Test.startTest();
        CCPAConsumerRightsService service = new CCPAConsumerRightsService();
        List<Map<String, Object>> results = new List<Map<String, Object>>();
        for (Integer i = 0; i < Math.min(contacts.size(), requests.size()); i++) {
            try {
                Map<String, Object> result = service.handleKnowRequest(requests[i].Id, contacts[i].Id);
                results.add(result);
            } catch (Exception e) {
                Assert.isNotNull(e.getMessage(), 'Exception message should not be null');
            }
        }
        Test.stopTest();
        
        Assert.isTrue(results.size() > 0, 'Should process bulk requests');
    }
    
    @IsTest
    static void testHandleDeleteRequest_Success() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        CCPA_Request__c request = new CCPA_Request__c(
            Contact__c = testContact.Id,
            Request_Type__c = 'Delete',
            Status__c = 'Pending'
        );
        insert as user request;
        
        Test.startTest();
        CCPAConsumerRightsService service = new CCPAConsumerRightsService();
        Map<String, Object> result = service.handleDeleteRequest(request.Id, testContact.Id);
        Test.stopTest();
        
        Assert.areNotEqual(null, result, 'Delete result should not be null');
    }
    
    @IsTest
    static void testHandleOptOutRequest_Success() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        CCPA_Request__c request = new CCPA_Request__c(
            Contact__c = testContact.Id,
            Request_Type__c = 'Opt-Out',
            Status__c = 'Pending'
        );
        insert as user request;
        
        Test.startTest();
        CCPAConsumerRightsService service = new CCPAConsumerRightsService();
        Map<String, Object> result = service.handleOptOutRequest(request.Id, testContact.Id);
        Test.stopTest();
        
        Assert.areNotEqual(null, result, 'Opt-out result should not be null');
    }
    
    @IsTest
    static void testVerifyIdentity_Success() {
        Contact testContact = [SELECT Id, Email FROM Contact LIMIT 1];
        Map<String, Object> verificationData = new Map<String, Object>{
            'email' => testContact.Email
        };
        
        Test.startTest();
        CCPAConsumerRightsService service = new CCPAConsumerRightsService();
        Boolean verified = service.verifyIdentity(testContact.Id, verificationData);
        Test.stopTest();
        
        Assert.areEqual(true, verified, 'Identity should be verified');
    }
    
    @IsTest
    static void testVerifyIdentity_Failure() {
        Contact testContact = [SELECT Id, Email FROM Contact LIMIT 1];
        Map<String, Object> verificationData = new Map<String, Object>{
            'email' => 'wrong@example.com'
        };
        
        Test.startTest();
        CCPAConsumerRightsService service = new CCPAConsumerRightsService();
        Boolean verified = service.verifyIdentity(testContact.Id, verificationData);
        Test.stopTest();
        
        Assert.areEqual(false, verified, 'Identity should not be verified');
    }
    
    @IsTest
    static void testHandleAccessRequest_Interface() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        CCPA_Request__c request = [SELECT Id FROM CCPA_Request__c WHERE Contact__c = :testContact.Id LIMIT 1];
        
        Test.startTest();
        CCPAConsumerRightsService service = new CCPAConsumerRightsService();
        Map<String, Object> result = service.handleAccessRequest(request.Id, testContact.Id);
        Test.stopTest();
        
        Assert.areEqual(true, result.get('success'), 'Access request should succeed');
    }
    
    @IsTest
    static void testHandleErasureRequest_Interface() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        CCPA_Request__c request = new CCPA_Request__c(
            Contact__c = testContact.Id,
            Request_Type__c = 'Delete',
            Status__c = 'Pending'
        );
        insert as user request;
        
        Test.startTest();
        CCPAConsumerRightsService service = new CCPAConsumerRightsService();
        Map<String, Object> result = service.handleErasureRequest(request.Id, testContact.Id, 'Consumer request');
        Test.stopTest();
        
        Assert.areNotEqual(null, result, 'Erasure result should not be null');
    }
    
    @IsTest
    static void testHandleKnowRequest_NullParameters() {
        Test.startTest();
        CCPAConsumerRightsService service = new CCPAConsumerRightsService();
        try {
            service.handleKnowRequest(null, null);
            Assert.fail( 'Should throw exception for null parameters');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('required'), 'Should validate required parameters');
        }
        Test.stopTest();
    }
}
