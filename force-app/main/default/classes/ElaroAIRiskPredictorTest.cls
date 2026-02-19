/**
 * ElaroAIRiskPredictorTest
 * 
 * Test class for ElaroAIRiskPredictor
 * 
 * @author Elaro
 * @version 1.0
 */
@IsTest(testFor=ElaroAIRiskPredictor.class)
private class ElaroAIRiskPredictorTest {
    
    @IsTest
    static void testPredictRisk_Success() {
        Test.startTest();
        ElaroAIRiskPredictor.RiskPredictionResult result = 
            ElaroAIRiskPredictor.predictRisk('PERMISSION_SET', '001000000000001AAA', 'SOX');
        Test.stopTest();
        
        Assert.areNotEqual(null, result, 'Result should not be null');
        Assert.areEqual('PERMISSION_SET', result.entityType, 'Entity type should match');
        Assert.areEqual('SOX', result.framework, 'Framework should match');
        Assert.areNotEqual(null, result.riskScore, 'Risk score should not be null');
        Assert.areNotEqual(null, result.confidence, 'Confidence should not be null');
        Assert.areNotEqual(null, result.isViolation, 'Is violation should not be null');
        Assert.areNotEqual(null, result.recommendation, 'Recommendation should not be null');
    }
    
    @IsTest
    static void testPredictRisk_BlankParameters() {
        Test.startTest();
        try {
            ElaroAIRiskPredictor.predictRisk('', '001000000000001AAA', 'SOX');
            Assert.fail( 'Should have thrown IllegalArgumentException');
        } catch (IllegalArgumentException e) {
            Assert.isTrue(e.getMessage().contains('required'), 'Exception should mention required parameters');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testPredictRisk_NullParameters() {
        Test.startTest();
        try {
            ElaroAIRiskPredictor.predictRisk(null, null, null);
            Assert.fail( 'Should have thrown IllegalArgumentException');
        } catch (IllegalArgumentException e) {
            Assert.isTrue(e.getMessage().contains('required'), 'Exception should mention required parameters');
        }
        Test.stopTest();
    }
}
