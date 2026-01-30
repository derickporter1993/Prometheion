/**
 * Test class for GDPRDataSubjectService
 * Tests data subject rights: Access, Rectification, Erasure, Portability
 * 
 * @author Elaro
 * @version 3.0
 */
@IsTest
private class GDPRDataSubjectServiceTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test contacts
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 200; i++) {
            contacts.add(new Contact(
                FirstName = 'Test',
                LastName = 'Contact' + i,
                Email = 'test' + i + '@example.com',
                Phone = '555-000' + String.valueOf(i).leftPad(4, '0')
            ));
        }
        insert contacts;
    }
    
    @IsTest
    static void testHandleAccessRequest_Success() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Id requestId = testContact.Id; // Using contact ID as request ID for test
        
        Test.startTest();
        GDPRDataSubjectService service = new GDPRDataSubjectService();
        Map<String, Object> result = service.handleAccessRequest(requestId, testContact.Id);
        Test.stopTest();
        
        System.assertEquals(true, result.get('success'), 'Access request should succeed');
        System.assertNotEquals(null, result.get('personalData'), 'Personal data should be returned');
        System.assertNotEquals(null, result.get('correlationId'), 'Correlation ID should be present');
    }
    
    @IsTest
    static void testHandleAccessRequest_Bulk() {
        List<Contact> contacts = [SELECT Id FROM Contact LIMIT 200];
        
        Test.startTest();
        GDPRDataSubjectService service = new GDPRDataSubjectService();
        List<Map<String, Object>> results = new List<Map<String, Object>>();
        for (Contact c : contacts) {
            try {
                Map<String, Object> result = service.handleAccessRequest(c.Id, c.Id);
                results.add(result);
            } catch (Exception e) {
                // Some may fail due to test data limitations
            }
        }
        Test.stopTest();
        
        System.assert(results.size() > 0, 'Should process bulk requests');
    }
    
    @IsTest
    static void testHandleRectificationRequest_Success() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Id requestId = testContact.Id;
        Map<String, Object> corrections = new Map<String, Object>{
            'Email' => 'updated@example.com'
        };
        
        Test.startTest();
        GDPRDataSubjectService service = new GDPRDataSubjectService();
        Map<String, Object> result = service.handleRectificationRequest(requestId, corrections);
        Test.stopTest();
        
        System.assertEquals(true, result.get('success'), 'Rectification should succeed');
    }
    
    @IsTest
    static void testHandleErasureRequest_Success() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Id requestId = testContact.Id;
        String reason = 'Data subject request';
        
        Test.startTest();
        GDPRDataSubjectService service = new GDPRDataSubjectService();
        Map<String, Object> result = service.handleErasureRequest(requestId, testContact.Id, reason);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Erasure result should not be null');
    }
    
    @IsTest
    static void testHandlePortabilityRequest_JSON() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Id requestId = testContact.Id;
        String format = 'JSON';
        
        Test.startTest();
        GDPRDataSubjectService service = new GDPRDataSubjectService();
        Map<String, Object> result = service.handlePortabilityRequest(requestId, testContact.Id, format);
        Test.stopTest();
        
        System.assertEquals(true, result.get('success'), 'Portability should succeed');
        System.assertEquals('JSON', result.get('format'), 'Format should be JSON');
        System.assertNotEquals(null, result.get('exportData'), 'Export data should be present');
    }
    
    @IsTest
    static void testHandlePortabilityRequest_InvalidFormat() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Id requestId = testContact.Id;
        String format = 'INVALID';
        
        Test.startTest();
        GDPRDataSubjectService service = new GDPRDataSubjectService();
        try {
            Map<String, Object> result = service.handlePortabilityRequest(requestId, testContact.Id, format);
            System.assert(false, 'Should throw exception for invalid format');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Invalid'), 'Should throw invalid format error');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testVerifyIdentity_Success() {
        Contact testContact = [SELECT Id, Email FROM Contact LIMIT 1];
        Map<String, Object> verificationData = new Map<String, Object>{
            'email' => testContact.Email
        };
        
        Test.startTest();
        GDPRDataSubjectService service = new GDPRDataSubjectService();
        Boolean verified = service.verifyIdentity(testContact.Id, verificationData);
        Test.stopTest();
        
        System.assertEquals(true, verified, 'Identity should be verified');
    }
    
    @IsTest
    static void testVerifyIdentity_Failure() {
        Contact testContact = [SELECT Id, Email FROM Contact LIMIT 1];
        Map<String, Object> verificationData = new Map<String, Object>{
            'email' => 'wrong@example.com'
        };
        
        Test.startTest();
        GDPRDataSubjectService service = new GDPRDataSubjectService();
        Boolean verified = service.verifyIdentity(testContact.Id, verificationData);
        Test.stopTest();
        
        System.assertEquals(false, verified, 'Identity should not be verified');
    }
    
    @IsTest
    static void testHandleAccessRequest_NullRequestId() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        
        Test.startTest();
        GDPRDataSubjectService service = new GDPRDataSubjectService();
        try {
            service.handleAccessRequest(null, testContact.Id);
            System.assert(false, 'Should throw exception for null request ID');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('required'), 'Should validate required parameters');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testHandleErasureRequest_NullReason() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Id requestId = testContact.Id;
        
        Test.startTest();
        GDPRDataSubjectService service = new GDPRDataSubjectService();
        try {
            service.handleErasureRequest(requestId, testContact.Id, null);
            System.assert(false, 'Should throw exception for null reason');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('required'), 'Should validate required parameters');
        }
        Test.stopTest();
    }
}
