/**
 * ChangeImpactAnalyzerTest
 * 
 * Test class for ChangeImpactAnalyzer
 * 
 * @author Prometheion
 * @version 1.0
 */
@IsTest
private class ChangeImpactAnalyzerTest {
    
    @IsTest
    static void testAnalyzeImpact_Success() {
        List<ChangeImpactAnalyzer.MetadataChange> changes = new List<ChangeImpactAnalyzer.MetadataChange>();
        
        ChangeImpactAnalyzer.MetadataChange change1 = new ChangeImpactAnalyzer.MetadataChange();
        change1.metadataType = 'PermissionSet';
        change1.metadataName = 'TestPS';
        change1.changeType = 'CREATE';
        changes.add(change1);
        
        ChangeImpactAnalyzer.MetadataChange change2 = new ChangeImpactAnalyzer.MetadataChange();
        change2.metadataType = 'ApexClass';
        change2.metadataName = 'TestClass';
        change2.changeType = 'DELETE';
        changes.add(change2);
        
        Test.startTest();
        ChangeImpactAnalyzer.ImpactAnalysisResult result = 
            ChangeImpactAnalyzer.analyzeImpact(changes);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(2, result.totalChanges, 'Should have 2 changes');
        System.assertNotEquals(null, result.overallRiskLevel, 'Overall risk level should not be null');
        System.assertNotEquals(null, result.risks, 'Risks should not be null');
    }
    
    @IsTest
    static void testAnalyzeImpact_NullChanges() {
        Test.startTest();
        try {
            ChangeImpactAnalyzer.analyzeImpact(null);
            System.assert(false, 'Should have thrown IllegalArgumentException');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'Expected exception for null changes');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testAnalyzeImpact_EmptyChanges() {
        Test.startTest();
        try {
            ChangeImpactAnalyzer.analyzeImpact(new List<ChangeImpactAnalyzer.MetadataChange>());
            System.assert(false, 'Should have thrown IllegalArgumentException');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'Expected exception for empty changes');
        }
        Test.stopTest();
    }
}
