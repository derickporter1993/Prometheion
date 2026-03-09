/**
 * Test class for GDPRDataInventoryService
 * Tests data inventory, classification, ROPA generation
 * 
 * @author Elaro
 * @version 3.0
 */
@IsTest
private class GDPRDataInventoryServiceTest {
    
    @TestSetup
    static void setupTestData() {
        // Create data processing activities
        List<Data_Processing_Activity__c> activities = new List<Data_Processing_Activity__c>();
        for (Integer i = 0; i < 200; i++) {
            activities.add(new Data_Processing_Activity__c(
                Activity_Name__c = 'Activity ' + i,
                Legal_Basis__c = 'Consent',
                Data_Categories__c = 'Contact Information, Email',
                Retention_Period__c = 365
            ));
        }
        insert activities;
        
        // Create third-party recipients
        List<Third_Party_Recipient__c> recipients = new List<Third_Party_Recipient__c>();
        for (Integer i = 0; i < 50; i++) {
            recipients.add(new Third_Party_Recipient__c(
                Recipient_Name__c = 'Recipient ' + i,
                Country__c = 'United States',
                DPA_Signed__c = true
            ));
        }
        insert recipients;
    }
    
    @IsTest
    static void testInventoryPersonalData_Success() {
        Test.startTest();
        GDPRDataInventoryService service = new GDPRDataInventoryService();
        Map<String, Object> inventory = service.inventoryPersonalData();
        Test.stopTest();
        
        Assert.areNotEqual(null, inventory, 'Inventory should not be null');
        Assert.isTrue(inventory.containsKey('totalActivities'), 'Should include activity count');
        Assert.isTrue(inventory.containsKey('totalRecipients'), 'Should include recipient count');
    }
    
    @IsTest
    static void testCollectEvidence_Success() {
        // Create compliance control metadata (would need to be created in org)
        String controlId = 'TEST_CONTROL';
        String framework = 'GDPR';
        
        Test.startTest();
        GDPRDataInventoryService service = new GDPRDataInventoryService();
        try {
            Map<String, Object> evidence = service.collectEvidence(controlId, framework);
            Assert.areNotEqual(null, evidence, 'Evidence should not be null');
        } catch (Exception e) {
            // May fail if control doesn't exist - that's expected in test
            Assert.isTrue(e.getMessage().contains('Control not found') || e.getMessage().contains('required'), 
                'Should handle missing control gracefully');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testClassifyDataCategories() {
        List<Object> dataFields = new List<Object>{
            'Email', 'Phone', 'FirstName', 'LastName', 'SSN', 'PurchaseHistory'
        };
        
        Test.startTest();
        GDPRDataInventoryService service = new GDPRDataInventoryService();
        Map<String, Object> classification = service.classifyDataCategories(dataFields);
        Test.stopTest();
        
        Assert.areNotEqual(null, classification, 'Classification should not be null');
        Assert.isTrue(classification.containsKey('categories'), 'Should include categories');
        Assert.areEqual(6, classification.get('totalFields'), 'Should classify all fields');
    }
    
    @IsTest
    static void testMapDataFlows_Internal() {
        String sourceSystem = 'Salesforce';
        String targetSystem = null;
        
        Test.startTest();
        GDPRDataInventoryService service = new GDPRDataInventoryService();
        Map<String, Object> flowMap = service.mapDataFlows(sourceSystem, targetSystem);
        Test.stopTest();
        
        Assert.areEqual(sourceSystem, flowMap.get('sourceSystem'), 'Source system should match');
        Assert.areEqual(false, flowMap.get('isThirdPartyTransfer'), 'Should be internal flow');
    }
    
    @IsTest
    static void testMapDataFlows_ThirdParty() {
        Third_Party_Recipient__c recipient = [SELECT Recipient_Name__c FROM Third_Party_Recipient__c LIMIT 1];
        String sourceSystem = 'Salesforce';
        String targetSystem = recipient.Recipient_Name__c;
        
        Test.startTest();
        GDPRDataInventoryService service = new GDPRDataInventoryService();
        Map<String, Object> flowMap = service.mapDataFlows(sourceSystem, targetSystem);
        Test.stopTest();
        
        Assert.areEqual(true, flowMap.get('isThirdPartyTransfer'), 'Should be third-party transfer');
    }
    
    @IsTest
    static void testGenerateROPA() {
        Map<String, Object> parameters = new Map<String, Object>();
        
        Test.startTest();
        GDPRDataInventoryService service = new GDPRDataInventoryService();
        Map<String, Object> ropa = (Map<String, Object>)service.generateEvidenceReport('ROPA', parameters);
        Test.stopTest();
        
        Assert.areEqual('ROPA', ropa.get('reportType'), 'Report type should be ROPA');
        Assert.areNotEqual(null, ropa.get('activities'), 'Should include activities');
    }
    
    @IsTest
    static void testGenerateEvidenceReport_InvalidType() {
        Map<String, Object> parameters = new Map<String, Object>();
        
        Test.startTest();
        GDPRDataInventoryService service = new GDPRDataInventoryService();
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
        GDPRDataInventoryService service = new GDPRDataInventoryService();
        Map<String, Object> classification = service.classifyDataCategories(dataFields);
        Test.stopTest();
        
        Assert.areEqual(200, classification.get('totalFields'), 'Should classify all fields');
    }
}
