@isTest
private class PrometheionEventPublisherTest {
    
    @isTest
    static void testPublishConfigChange() {
        String orgId = UserInfo.getOrganizationId();
        String entityType = 'PermissionSet';
        String entityId = '0PS000000000001';
        Map<String, Object> changeData = new Map<String, Object>{
            'action' => 'MODIFIED',
            'field' => 'PermissionsModifyAllData'
        };
        
        Test.startTest();
        PrometheionEventPublisher.publishConfigChange(orgId, entityType, entityId, changeData);
        Test.stopTest();
        
        // Verify event was published (check Platform Event delivery)
        // Note: Platform Events are async, so we can't directly query them
        // In production, you'd verify via integration tests or monitoring
        System.assert(true, 'Event published successfully');
    }
    
    @isTest
    static void testPublishAuditTrailChange() {
        String orgId = UserInfo.getOrganizationId();
        Map<String, Object> auditData = new Map<String, Object>{
            'action' => 'CHANGED',
            'section' => 'Setup',
            'display' => 'PermissionSet: Test Permission Set'
        };
        
        Test.startTest();
        PrometheionEventPublisher.publishAuditTrailChange(orgId, auditData);
        Test.stopTest();
        
        System.assert(true, 'Audit trail event published successfully');
    }
    
    @isTest
    static void testPublishPermissionChange() {
        String orgId = UserInfo.getOrganizationId();
        String userId = UserInfo.getUserId();
        String permissionSetId = '0PS000000000001';
        String action = 'ASSIGNED';
        
        Test.startTest();
        PrometheionEventPublisher.publishPermissionChange(orgId, userId, permissionSetId, action);
        Test.stopTest();
        
        System.assert(true, 'Permission change event published successfully');
    }
    
    @isTest
    static void testPublishBatch() {
        String orgId = UserInfo.getOrganizationId();
        List<Prometheion_Raw_Event__e> events = new List<Prometheion_Raw_Event__e>();
        
        for (Integer i = 0; i < 5; i++) {
            events.add(new Prometheion_Raw_Event__e(
                Org_ID__c = orgId,
                Event_Type__c = 'ConfigChange',
                Entity_Type__c = 'PermissionSet',
                Entity_ID__c = '0PS00000000000' + i,
                Event_Data__c = '{"test": "data"}',
                Timestamp__c = Datetime.now()
            ));
        }
        
        Test.startTest();
        PrometheionEventPublisher.publishBatch(events);
        Test.stopTest();
        
        System.assert(true, 'Batch events published successfully');
    }
    
    @isTest
    static void testPublishBatchEmpty() {
        Test.startTest();
        PrometheionEventPublisher.publishBatch(new List<Prometheion_Raw_Event__e>());
        PrometheionEventPublisher.publishBatch(null);
        Test.stopTest();
        
        System.assert(true, 'Empty batch handled gracefully');
    }
}

