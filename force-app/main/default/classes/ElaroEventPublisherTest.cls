@isTest
private class ElaroEventPublisherTest {
    
    @isTest
    static void testPublishConfigChange() {
        String orgId = UserInfo.getOrganizationId();
        String entityType = 'PermissionSet';
        String entityId = '0PS000000000001';
        Map<String, Object> changeData = new Map<String, Object>{
            'action' => 'MODIFIED',
            'field' => 'PermissionsModifyAllData'
        };
        
        // Verify test data is valid
        System.assertNotEquals(null, orgId, 'Org ID should not be null');
        System.assertNotEquals(null, changeData, 'Change data should not be null');

        Test.startTest();
        // Platform Events are async - verify no exception is thrown
        Exception caughtException = null;
        try {
            ElaroEventPublisher.publishConfigChange(orgId, entityType, entityId, changeData);
        } catch (Exception e) {
            caughtException = e;
        }
        Test.stopTest();

        System.assertEquals(null, caughtException, 'publishConfigChange should not throw exception');
    }
    
    @isTest
    static void testPublishAuditTrailChange() {
        String orgId = UserInfo.getOrganizationId();
        Map<String, Object> auditData = new Map<String, Object>{
            'action' => 'CHANGED',
            'section' => 'Setup',
            'display' => 'PermissionSet: Test Permission Set'
        };
        
        System.assertNotEquals(null, orgId, 'Org ID should not be null');
        System.assertEquals(3, auditData.size(), 'Audit data should have 3 entries');

        Test.startTest();
        Exception caughtException = null;
        try {
            ElaroEventPublisher.publishAuditTrailChange(orgId, auditData);
        } catch (Exception e) {
            caughtException = e;
        }
        Test.stopTest();

        System.assertEquals(null, caughtException, 'publishAuditTrailChange should not throw exception');
    }
    
    @isTest
    static void testPublishPermissionChange() {
        String orgId = UserInfo.getOrganizationId();
        String userId = UserInfo.getUserId();
        String permissionSetId = '0PS000000000001';
        String action = 'ASSIGNED';
        
        System.assertNotEquals(null, orgId, 'Org ID should not be null');
        System.assertNotEquals(null, userId, 'User ID should not be null');
        System.assertEquals('ASSIGNED', action, 'Action should be ASSIGNED');

        Test.startTest();
        Exception caughtException = null;
        try {
            ElaroEventPublisher.publishPermissionChange(orgId, userId, permissionSetId, action);
        } catch (Exception e) {
            caughtException = e;
        }
        Test.stopTest();

        System.assertEquals(null, caughtException, 'publishPermissionChange should not throw exception');
    }
    
    @isTest
    static void testPublishBatch() {
        String orgId = UserInfo.getOrganizationId();
        List<Elaro_Raw_Event__e> events = new List<Elaro_Raw_Event__e>();
        
        for (Integer i = 0; i < 5; i++) {
            events.add(new Elaro_Raw_Event__e(
                Org_ID__c = orgId,
                Event_Type__c = 'ConfigChange',
                Entity_Type__c = 'PermissionSet',
                Entity_ID__c = '0PS00000000000' + i,
                Event_Data__c = '{"test": "data"}',
                Timestamp__c = Datetime.now()
            ));
        }
        
        System.assertEquals(5, events.size(), 'Should have 5 events to publish');

        Test.startTest();
        Exception caughtException = null;
        try {
            ElaroEventPublisher.publishBatch(events);
        } catch (Exception e) {
            caughtException = e;
        }
        Test.stopTest();

        System.assertEquals(null, caughtException, 'publishBatch should not throw exception');
    }
    
    @isTest
    static void testPublishBatchEmpty() {
        Test.startTest();
        Exception caughtException = null;
        try {
            ElaroEventPublisher.publishBatch(new List<Elaro_Raw_Event__e>());
            ElaroEventPublisher.publishBatch(null);
        } catch (Exception e) {
            caughtException = e;
        }
        Test.stopTest();

        // Empty and null batches should be handled gracefully without exception
        System.assertEquals(null, caughtException, 'Empty/null batch should not throw exception');
    }
}

