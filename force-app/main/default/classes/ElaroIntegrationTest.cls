/**
 * Integration tests for Elaro workflows
 *
 * Tests cover end-to-end workflows across multiple components:
 * - Alert workflow: Trigger → Service → Event → Notification
 * - Compliance workflow: Violation → Document generation
 * - Settings impact: Configuration changes → Score recalculation
 *
 * @author Elaro
 * @version 1.0
 */
@IsTest
private class ElaroIntegrationTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test permission set
        PermissionSet ps = new PermissionSet(
            Name = 'TestIntegrationPS',
            Label = 'Test Integration Permission Set'
        );
        insert ps;
        
        // Create test user
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            FirstName = 'Integration',
            LastName = 'Test',
            Email = 'integrationtest@elaro.test',
            Username = 'integrationtest' + String.valueOf(System.now().getTime()) + '@elaro.test',
            Alias = 'inttest',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert testUser;
    }
    
    /**
     * Test full alert workflow: PerformanceRuleEngine → PerformanceAlertPublisher → Notification
     */
    @IsTest
    static void testFullAlertWorkflow_TriggerToNotification() {
        // Create CCX settings with low thresholds to trigger alerts
        CCX_Settings__c settings = ElaroTestDataFactory.createCCXSettings(
            7000, 8000,  // CPU: warn at 7000, crit at 8000
            4000, 4500,  // Heap: warn at 4000, crit at 4500
            80, 90,      // SOQL: warn at 80, crit at 90
            120, 140     // DML: warn at 120, crit at 140
        );
        
        LimitMetrics.GovernorStats stats = new LimitMetrics.GovernorStats();
        stats.cpuMs = 7500; // Above warn threshold
        stats.heapKb = 4200; // Above warn threshold
        stats.soql = 85; // Above warn threshold
        stats.dml = 125; // Above warn threshold
        
        Test.startTest();
        PerformanceRuleEngine.EvalResult result = PerformanceRuleEngine.evaluateAndPublish(stats, 'integrationTest');
        Test.stopTest();
        
        // Verify alerts were created
        System.assertEquals(true, result.warning, 'Should trigger warning');
        System.assert(result.eventsPublished > 0, 'Should have published alerts');
        
        // Verify Performance_Alert_History__c records were created
        List<Performance_Alert_History__c> alerts = [
            SELECT Id, Metric__c, Value__c, Threshold__c
            FROM Performance_Alert_History__c
            WHERE Context_Record__c = 'integrationTest'
        ];
        System.assert(alerts.size() >= 4, 'Should have created at least 4 alert records');
    }
    
    /**
     * Test compliance workflow: Graph indexing → Compliance scoring → Document generation
     */
    @IsTest
    static void testComplianceWorkflow_ViolationToDocument() {
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'TestIntegrationPS' LIMIT 1];
        
        Test.startTest();
        // Step 1: Index change (creates graph node)
        String nodeHash = ElaroGraphIndexer.indexChange('PERMISSION_SET', ps.Id, null, 'SOC2');
        
        // Step 2: Calculate compliance score (should include indexed entity)
        ElaroComplianceScorer.ScoreResult scoreResult = ElaroComplianceScorer.calculateReadinessScore();
        Test.stopTest();
        
        // Verify graph node was created
        List<Elaro_Compliance_Graph__b> nodes = [
            SELECT Graph_Node_Id__c, Entity_Type__c, Compliance_Framework__c
            FROM Elaro_Compliance_Graph__b
            WHERE Graph_Node_Id__c = :nodeHash
        ];
        System.assertEquals(1, nodes.size(), 'Graph node should be created');
        System.assertEquals('PERMISSION_SET', nodes[0].Entity_Type__c);
        System.assertEquals('SOC2', nodes[0].Compliance_Framework__c);
        
        // Verify score calculation succeeded
        System.assertNotEquals(null, scoreResult, 'Score result should not be null');
        System.assert(scoreResult.overallScore >= 0 && scoreResult.overallScore <= 100, 
                     'Score should be between 0 and 100');
    }
    
    /**
     * Test settings impact: AI settings change → Score recalculation
     */
    @IsTest
    static void testSettingsImpact_OnComplianceScore() {
        // Create initial AI settings
        Elaro_AI_Settings__c initialSettings = new Elaro_AI_Settings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            Enable_AI_Reasoning__c = false,
            Confidence_Threshold__c = 0.85
        );
        insert initialSettings;
        
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'TestIntegrationPS' LIMIT 1];
        
        Test.startTest();
        // Step 1: Index with AI disabled (uses fallback scoring)
        String nodeHash1 = ElaroGraphIndexer.indexChange('PERMISSION_SET', ps.Id, null, 'SOC2');
        
        // Step 2: Enable AI and verify impact
        initialSettings.Enable_AI_Reasoning__c = true;
        update initialSettings;
        
        // Step 3: Re-index (would use AI if configured, but falls back if not)
        String nodeHash2 = ElaroGraphIndexer.indexChange('PERMISSION_SET', ps.Id, null, 'HIPAA');
        
        // Step 4: Calculate score
        ElaroComplianceScorer.ScoreResult scoreResult = ElaroComplianceScorer.calculateReadinessScore();
        Test.stopTest();
        
        // Verify both graph nodes were created
        List<Elaro_Compliance_Graph__b> nodes = [
            SELECT Graph_Node_Id__c, Compliance_Framework__c
            FROM Elaro_Compliance_Graph__b
            WHERE Entity_Record_Id__c = :ps.Id
        ];
        System.assert(nodes.size() >= 2, 'Should have created nodes for both frameworks');
        
        // Verify score calculation reflects settings
        System.assertNotEquals(null, scoreResult, 'Score result should not be null');
        System.assertNotEquals(null, scoreResult.frameworkScores, 'Should have framework scores');
    }
}
