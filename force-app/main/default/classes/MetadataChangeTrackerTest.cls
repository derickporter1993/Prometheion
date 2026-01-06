/**
 * MetadataChangeTrackerTest
 * 
 * Test class for MetadataChangeTracker
 * 
 * @author Prometheion
 * @version 1.0
 */
@IsTest
private class MetadataChangeTrackerTest {
    
    @IsTest
    static void testTrackChange_Success() {
        String changeDetails = JSON.serialize(new Map<String, Object>{
            'before' => 'OldValue',
            'after' => 'NewValue'
        });
        
        Test.startTest();
        String changeId = MetadataChangeTracker.trackChange(
            'UPDATE',
            'ApexClass',
            'TestClass',
            '001000000000001AAA',
            changeDetails
        );
        Test.stopTest();
        
        System.assertNotEquals(null, changeId, 'Change ID should not be null');
        
        // Verify change was inserted
        List<Metadata_Change__c> changes = [
            SELECT Id, Change_Type__c, Metadata_Type__c, Metadata_Name__c
            FROM Metadata_Change__c
            WHERE Id = :changeId
            WITH SECURITY_ENFORCED
        ];
        System.assertEquals(1, changes.size(), 'Change should be inserted');
        System.assertEquals('UPDATE', changes[0].Change_Type__c, 'Change type should match');
    }
    
    @IsTest
    static void testTrackChange_BlankParameters() {
        Test.startTest();
        try {
            MetadataChangeTracker.trackChange('', 'ApexClass', 'TestClass', null, '{}');
            System.assert(false, 'Should have thrown IllegalArgumentException');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'Expected exception for blank parameters');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testGetRecentChanges() {
        // Create test changes
        List<Metadata_Change__c> changes = ComplianceTestDataFactory.createMetadataChanges(5);
        insert changes;
        
        Test.startTest();
        List<Metadata_Change__c> recentChanges = MetadataChangeTracker.getRecentChanges(10);
        Test.stopTest();
        
        System.assertNotEquals(null, recentChanges, 'Recent changes should not be null');
        System.assert(recentChanges.size() > 0, 'Should have recent changes');
    }
}
