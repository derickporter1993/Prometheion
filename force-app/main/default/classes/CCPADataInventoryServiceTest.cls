/**
 * Test class for CCPADataInventoryService
 * Tests data categorization, data sales identification, third-party sharing
 * 
 * @author Elaro
 * @version 3.0
 */
@IsTest
private class CCPADataInventoryServiceTest {
    
    @TestSetup
    static void setupTestData() {
        // Create third-party recipients
        List<Third_Party_Recipient__c> recipients = new List<Third_Party_Recipient__c>();
        for (Integer i = 0; i < 200; i++) {
            recipients.add(new Third_Party_Recipient__c(
                Recipient_Name__c = 'Recipient ' + i,
                Country__c = 'United States',
                DPA_Signed__c = (Math.mod(i, 2) == 0),
                Data_Categories_Shared__c = 'Identifiers, Commercial Information'
            ));
        }
        insert recipients;
    }
    
    @IsTest
    static void testCategorizePersonalInfo_Success() {
        Map<String, Object> parameters = new Map<String, Object>();
        
        Test.startTest();
        CCPADataInventoryService service = new CCPADataInventoryService();
        Map<String, Object> result = service.categorizePersonalInfo(parameters);
        Test.stopTest();
        
        Assert.areNotEqual(null, result, 'Categorization should not be null');
        Assert.isTrue(result.containsKey('categories'), 'Should include categories');
    }
    
    @IsTest
    static void testIdentifyDataSales() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        if (testContact == null) {
            testContact = new Contact(FirstName = 'Test', LastName = 'Contact', Email = 'test@example.com');
            insert testContact;
        }
        
        Test.startTest();
        CCPADataInventoryService service = new CCPADataInventoryService();
        List<Map<String, Object>> sales = service.identifyDataSales(testContact.Id);
        Test.stopTest();
        
        Assert.areNotEqual(null, sales, 'Sales list should not be null');
    }
    
    @IsTest
    static void testTrackThirdPartySharing() {
        Test.startTest();
        CCPADataInventoryService service = new CCPADataInventoryService();
        Map<String, Object> result = service.trackThirdPartySharing();
        Test.stopTest();
        
        Assert.areNotEqual(null, result, 'Sharing data should not be null');
        Assert.isTrue(result.containsKey('totalRecipients'), 'Should include recipient count');
        Assert.isTrue(result.containsKey('recipientsWithDPA'), 'Should include DPA count');
    }
    
    @IsTest
    static void testCollectEvidence() {
        String controlId = 'TEST_CONTROL';
        String framework = 'CCPA';
        
        Test.startTest();
        CCPADataInventoryService service = new CCPADataInventoryService();
        try {
            Map<String, Object> evidence = service.collectEvidence(controlId, framework);
            Assert.areNotEqual(null, evidence, 'Evidence should not be null');
        } catch (Exception e) {
            // May fail if control doesn't exist
            Assert.isTrue(e.getMessage().contains('Control not found') || e.getMessage().contains('required'), 
                'Should handle missing control gracefully');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testClassifyDataCategories() {
        List<Object> dataFields = new List<Object>{
            'Email', 'Phone', 'PurchaseHistory', 'LocationData'
        };
        
        Test.startTest();
        CCPADataInventoryService service = new CCPADataInventoryService();
        Map<String, Object> classification = service.classifyDataCategories(dataFields);
        Test.stopTest();
        
        Assert.areNotEqual(null, classification, 'Classification should not be null');
        Assert.areEqual(4, classification.get('totalFields'), 'Should classify all fields');
    }
    
    @IsTest
    static void testMapDataFlows() {
        String sourceSystem = 'Salesforce';
        String targetSystem = 'Third Party Vendor';
        
        Test.startTest();
        CCPADataInventoryService service = new CCPADataInventoryService();
        Map<String, Object> flowMap = service.mapDataFlows(sourceSystem, targetSystem);
        Test.stopTest();
        
        Assert.areEqual(sourceSystem, flowMap.get('sourceSystem'), 'Source system should match');
    }
    
    @IsTest
    static void testGenerateEvidenceReport() {
        Map<String, Object> parameters = new Map<String, Object>();
        
        Test.startTest();
        CCPADataInventoryService service = new CCPADataInventoryService();
        Map<String, Object> report = (Map<String, Object>)service.generateEvidenceReport('Data Inventory', parameters);
        Test.stopTest();
        
        Assert.areNotEqual(null, report, 'Report should not be null');
    }
    
    @IsTest
    static void testGenerateEvidenceReport_InvalidType() {
        Map<String, Object> parameters = new Map<String, Object>();
        
        Test.startTest();
        CCPADataInventoryService service = new CCPADataInventoryService();
        try {
            service.generateEvidenceReport('INVALID', parameters);
            Assert.fail( 'Should throw exception for invalid report type');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('Unsupported'), 'Should throw unsupported error');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testClassifyDataCategories_Bulk() {
        List<Object> dataFields = new List<Object>();
        for (Integer i = 0; i < 200; i++) {
            dataFields.add('Field' + i);
        }
        
        Test.startTest();
        CCPADataInventoryService service = new CCPADataInventoryService();
        Map<String, Object> classification = service.classifyDataCategories(dataFields);
        Test.stopTest();
        
        Assert.areEqual(200, classification.get('totalFields'), 'Should classify all fields');
    }
}
