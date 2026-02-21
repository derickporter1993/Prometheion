/**
 * ChangeImpactAnalyzerTest
 * 
 * Test class for ChangeImpactAnalyzer
 * 
 * @author Elaro
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
        
        Assert.areNotEqual(null, result, 'Result should not be null');
        Assert.areEqual(2, result.totalChanges, 'Should have 2 changes');
        Assert.areNotEqual(null, result.overallRiskLevel, 'Overall risk level should not be null');
        Assert.areNotEqual(null, result.risks, 'Risks should not be null');
    }
    
    @IsTest
    static void testAnalyzeImpact_NullChanges() {
        Test.startTest();
        try {
            ChangeImpactAnalyzer.analyzeImpact(null);
            Assert.fail('Expected IllegalArgumentException for null changes');
        } catch (IllegalArgumentException e) {
            Assert.isTrue(e.getMessage().containsIgnoreCase('changes') || e.getMessage().containsIgnoreCase('required') || e.getMessage().containsIgnoreCase('null'),
                'Should have descriptive error message, got: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testAnalyzeImpact_EmptyChanges() {
        Test.startTest();
        try {
            ChangeImpactAnalyzer.analyzeImpact(new List<ChangeImpactAnalyzer.MetadataChange>());
            Assert.fail('Expected IllegalArgumentException for empty changes');
        } catch (IllegalArgumentException e) {
            Assert.isTrue(e.getMessage().containsIgnoreCase('changes') || e.getMessage().containsIgnoreCase('required') || e.getMessage().containsIgnoreCase('empty'),
                'Should have descriptive error message, got: ' + e.getMessage());
        }
        Test.stopTest();
    }
}
