/**
 * @description Test Data Factory for Prometheion compliance testing.
 * Provides reusable test data creation methods for all compliance-related tests.
 *
 * IMPORTANT: Big Objects (Prometheion_Compliance_Graph__b) cannot be inserted in test context.
 * Use the mock methods to create in-memory instances for unit testing.
 *
 * Custom Metadata (Compliance_Policy__mdt) cannot be inserted in tests.
 * Use createMockPolicy() for unit tests, and deploy actual records for integration tests.
 */
@IsTest
public class PrometheionTestDataFactory {

    // ============================================
    // CONSTANTS - Supported Frameworks
    // ============================================
    public static final Set<String> SUPPORTED_FRAMEWORKS = new Set<String>{
        'SOC2', 'HIPAA', 'GDPR', 'ISO27001', 'PCI_DSS', 'NIST', 'CCPA', 'GLBA', 'FedRAMP'
    };

    // Entity Types
    public static final String ENTITY_PERMISSION_SET = 'PERMISSION_SET';
    public static final String ENTITY_FLOW = 'FLOW';
    public static final String ENTITY_APEX_CLASS = 'APEX_CLASS';
    public static final String ENTITY_APEX_TRIGGER = 'APEX_TRIGGER';
    public static final String ENTITY_CUSTOM_OBJECT = 'CUSTOM_OBJECT';
    public static final String ENTITY_FIELD = 'FIELD';
    public static final String ENTITY_PROFILE = 'PROFILE';
    public static final String ENTITY_USER = 'USER';
    public static final String ENTITY_AI_ADJUDICATION = 'AI_ADJUDICATION';

    // Drift Categories
    public static final String DRIFT_POLICY_VIOLATION = 'POLICY_VIOLATION';
    public static final String DRIFT_UNAUTHORIZED = 'UNAUTHORIZED';
    public static final String DRIFT_ANOMALY = 'ANOMALY';
    public static final String DRIFT_MANUAL_OVERRIDE = 'MANUAL_OVERRIDE';

    // Risk Score Thresholds
    public static final Decimal RISK_CRITICAL = 9.0;
    public static final Decimal RISK_HIGH = 7.0;
    public static final Decimal RISK_MEDIUM = 5.0;
    public static final Decimal RISK_LOW = 3.0;
    public static final Decimal RISK_MINIMAL = 1.0;

    // ============================================
    // COMPLIANCE GRAPH NODE - Mock Creation
    // ============================================

    /**
     * @description Creates a mock Prometheion_Compliance_Graph__b node (in-memory only).
     * Big Objects cannot be inserted in test context.
     */
    public static Prometheion_Compliance_Graph__b createMockComplianceNode(
        String entityType,
        String entityRecordId,
        String framework,
        Decimal riskScore
    ) {
        return new Prometheion_Compliance_Graph__b(
            Graph_Node_Id__c = generateTestHash(entityType, entityRecordId, framework),
            Parent_Node_Id__c = null,
            Timestamp__c = System.now(),
            Entity_Type__c = entityType,
            Entity_Record_Id__c = entityRecordId,
            Compliance_Framework__c = framework,
            Risk_Score__c = riskScore,
            Drift_Category__c = determineDriftCategory(riskScore),
            Node_Metadata__c = '{"test": true}',
            AI_Confidence__c = 0.85,
            Human_Adjudicated__c = false,
            Graph_Version__c = 'v3.0'
        );
    }

    /**
     * @description Creates multiple mock compliance nodes for bulk testing.
     */
    public static List<Prometheion_Compliance_Graph__b> createMockComplianceNodes(
        String framework,
        Integer count
    ) {
        List<Prometheion_Compliance_Graph__b> nodes = new List<Prometheion_Compliance_Graph__b>();
        for (Integer i = 0; i < count; i++) {
            Decimal riskScore = Math.mod(i, 10) + 1; // Varies 1-10
            nodes.add(createMockComplianceNode(
                ENTITY_PERMISSION_SET,
                'TestEntity' + i,
                framework,
                riskScore
            ));
        }
        return nodes;
    }

    /**
     * @description Creates a mock AI adjudication node.
     */
    public static Prometheion_Compliance_Graph__b createMockAdjudicationNode(
        String parentNodeHash,
        Decimal confidence,
        String explanation
    ) {
        return new Prometheion_Compliance_Graph__b(
            Graph_Node_Id__c = generateTestHash(ENTITY_AI_ADJUDICATION, parentNodeHash, 'ADJUDICATION'),
            Parent_Node_Id__c = parentNodeHash,
            Timestamp__c = System.now(),
            Entity_Type__c = ENTITY_AI_ADJUDICATION,
            AI_Confidence__c = confidence,
            AI_Explanation__c = explanation,
            Human_Adjudicator__c = UserInfo.getUserId(),
            Human_Adjudicated__c = true,
            Graph_Version__c = 'v3.0'
        );
    }

    // ============================================
    // COMPLIANCE POLICY - Mock Creation
    // ============================================

    /**
     * @description Creates a mock Compliance_Policy__mdt record (in-memory only).
     * Custom Metadata cannot be inserted in test context.
     */
    public static Compliance_Policy__mdt createMockPolicy(
        String developerName,
        String framework,
        String description,
        String legalCitation,
        String remediationSteps
    ) {
        Compliance_Policy__mdt policy = new Compliance_Policy__mdt();
        policy.DeveloperName = developerName;
        policy.Policy_Description__c = description;
        policy.Legal_Citation__c = legalCitation;
        policy.Remediation_Steps__c = remediationSteps;
        // Note: Framework__c would need to be set if it exists as a field
        return policy;
    }

    /**
     * @description Returns SOC2-specific mock policies.
     */
    public static List<Compliance_Policy__mdt> createSOC2Policies() {
        List<Compliance_Policy__mdt> policies = new List<Compliance_Policy__mdt>();

        // CC6.1 - Logical and Physical Access Controls
        policies.add(createMockPolicy(
            'SOC2_CC6_1_Access_Control',
            'SOC2',
            'Logical and physical access controls must restrict access to authorized personnel',
            'SOC2 CC6.1',
            'Review permission sets, remove excessive permissions, implement least privilege'
        ));

        // CC6.2 - User Registration and Authorization
        policies.add(createMockPolicy(
            'SOC2_CC6_2_User_Registration',
            'SOC2',
            'User registration and authorization processes must be documented',
            'SOC2 CC6.2',
            'Document user provisioning process, implement approval workflows'
        ));

        // CC6.3 - Access Removal
        policies.add(createMockPolicy(
            'SOC2_CC6_3_Access_Removal',
            'SOC2',
            'Access must be removed when no longer required',
            'SOC2 CC6.3',
            'Implement automated deprovisioning, conduct periodic access reviews'
        ));

        // CC7.1 - Configuration Management
        policies.add(createMockPolicy(
            'SOC2_CC7_1_Config_Mgmt',
            'SOC2',
            'Configuration changes must be authorized and documented',
            'SOC2 CC7.1',
            'Implement change management process, require approvals for metadata changes'
        ));

        return policies;
    }

    /**
     * @description Returns HIPAA-specific mock policies.
     */
    public static List<Compliance_Policy__mdt> createHIPAAPolicies() {
        List<Compliance_Policy__mdt> policies = new List<Compliance_Policy__mdt>();

        // 164.312(a)(1) - Access Control
        policies.add(createMockPolicy(
            'HIPAA_164_312_a_Access',
            'HIPAA',
            'Implement technical policies to allow access only to authorized persons',
            'HIPAA 164.312(a)(1)',
            'Review user access, implement role-based access control, enable MFA'
        ));

        // 164.312(b) - Audit Controls
        policies.add(createMockPolicy(
            'HIPAA_164_312_b_Audit',
            'HIPAA',
            'Implement hardware, software, and procedural mechanisms to record and examine access',
            'HIPAA 164.312(b)',
            'Enable field audit trail, configure event monitoring, retain logs'
        ));

        // 164.312(c)(1) - Integrity
        policies.add(createMockPolicy(
            'HIPAA_164_312_c_Integrity',
            'HIPAA',
            'Implement policies to protect ePHI from improper alteration or destruction',
            'HIPAA 164.312(c)(1)',
            'Enable field history tracking, implement validation rules'
        ));

        // 164.312(d) - Authentication
        policies.add(createMockPolicy(
            'HIPAA_164_312_d_Auth',
            'HIPAA',
            'Implement procedures to verify person or entity seeking access is authorized',
            'HIPAA 164.312(d)',
            'Implement MFA, SSO integration, session timeout policies'
        ));

        return policies;
    }

    /**
     * @description Returns GDPR-specific mock policies.
     */
    public static List<Compliance_Policy__mdt> createGDPRPolicies() {
        List<Compliance_Policy__mdt> policies = new List<Compliance_Policy__mdt>();

        // Article 17 - Right to Erasure
        policies.add(createMockPolicy(
            'GDPR_Art17_Erasure',
            'GDPR',
            'Data subjects have the right to obtain erasure of personal data',
            'GDPR Article 17',
            'Implement data deletion workflows, document retention policies'
        ));

        // Article 20 - Data Portability
        policies.add(createMockPolicy(
            'GDPR_Art20_Portability',
            'GDPR',
            'Data subjects have the right to receive their data in a portable format',
            'GDPR Article 20',
            'Implement data export functionality, support standard formats (JSON, CSV)'
        ));

        // Article 25 - Privacy by Design
        policies.add(createMockPolicy(
            'GDPR_Art25_Privacy_Design',
            'GDPR',
            'Data protection must be implemented by design and by default',
            'GDPR Article 25',
            'Review data minimization, implement purpose limitation controls'
        ));

        // Article 32 - Security of Processing
        policies.add(createMockPolicy(
            'GDPR_Art32_Security',
            'GDPR',
            'Implement appropriate technical and organizational security measures',
            'GDPR Article 32',
            'Enable encryption, implement access controls, conduct security assessments'
        ));

        // Article 33 - Breach Notification
        policies.add(createMockPolicy(
            'GDPR_Art33_Breach_Notify',
            'GDPR',
            'Personal data breaches must be reported within 72 hours',
            'GDPR Article 33',
            'Implement breach detection, establish notification procedures'
        ));

        return policies;
    }

    // ============================================
    // AI SETTINGS - Test Data
    // ============================================

    /**
     * @description Creates default AI settings for testing.
     */
    public static Prometheion_AI_Settings__c createAISettings(
        Boolean enableAI,
        Decimal confidenceThreshold,
        Boolean requireHumanApproval
    ) {
        Prometheion_AI_Settings__c settings = new Prometheion_AI_Settings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            Enable_AI_Reasoning__c = enableAI,
            Confidence_Threshold__c = confidenceThreshold,
            Require_Human_Approval__c = requireHumanApproval,
            Auto_Remediation_Enabled__c = false,
            Blacklisted_Users__c = ''
        );
        insert settings;
        return settings;
    }

    /**
     * @description Creates AI settings with AI disabled (fallback mode).
     */
    public static Prometheion_AI_Settings__c createAISettingsDisabled() {
        return createAISettings(false, 0.85, true);
    }

    /**
     * @description Creates AI settings with strict thresholds.
     */
    public static Prometheion_AI_Settings__c createAISettingsStrict() {
        return createAISettings(true, 0.95, true);
    }

    /**
     * @description Creates AI settings with lenient thresholds.
     */
    public static Prometheion_AI_Settings__c createAISettingsLenient() {
        return createAISettings(true, 0.70, false);
    }

    // ============================================
    // PERMISSION SETS - Test Data
    // ============================================

    /**
     * @description Creates a test permission set with documentation.
     */
    public static PermissionSet createDocumentedPermissionSet(String name, String description) {
        PermissionSet ps = new PermissionSet(
            Name = name,
            Label = name.replace('_', ' '),
            Description = description
        );
        insert ps;
        return ps;
    }

    /**
     * @description Creates multiple permission sets for compliance scoring tests.
     */
    public static List<PermissionSet> createPermissionSetBatch(Integer count, Boolean withDescriptions) {
        List<PermissionSet> permSets = new List<PermissionSet>();
        for (Integer i = 0; i < count; i++) {
            permSets.add(new PermissionSet(
                Name = 'TestPS_' + i + '_' + System.currentTimeMillis(),
                Label = 'Test Permission Set ' + i,
                Description = withDescriptions ? 'Description for PS ' + i : null
            ));
        }
        insert permSets;
        return permSets;
    }

    // ============================================
    // FLOW EXECUTION - Test Data
    // ============================================

    /**
     * @description Creates flow execution records for testing.
     */
    public static List<Flow_Execution__c> createFlowExecutions(
        String flowName,
        Integer successCount,
        Integer faultCount
    ) {
        List<Flow_Execution__c> executions = new List<Flow_Execution__c>();

        for (Integer i = 0; i < successCount; i++) {
            executions.add(new Flow_Execution__c(
                Flow_Name__c = flowName,
                Status__c = 'SUCCESS',
                Run_Time__c = Datetime.now().addHours(-i),
                CPU__c = 100 + (Math.random() * 200).intValue(),
                SOQL__c = 5 + Math.mod(i, 10),
                DML__c = 2 + Math.mod(i, 5)
            ));
        }

        for (Integer i = 0; i < faultCount; i++) {
            executions.add(new Flow_Execution__c(
                Flow_Name__c = flowName,
                Status__c = 'Fault',
                Run_Time__c = Datetime.now().addHours(-i),
                CPU__c = 500 + (Math.random() * 500).intValue(),
                SOQL__c = 20 + Math.mod(i, 30),
                DML__c = 10 + Math.mod(i, 10)
            ));
        }

        insert executions;
        return executions;
    }

    /**
     * @description Creates flow executions for multiple flows.
     */
    public static List<Flow_Execution__c> createMultipleFlowExecutions(Integer flowCount, Integer execsPerFlow) {
        List<Flow_Execution__c> allExecutions = new List<Flow_Execution__c>();

        for (Integer f = 0; f < flowCount; f++) {
            String flowName = 'TestFlow_' + f;
            Integer faults = Math.mod(f, 3); // 0, 1, or 2 faults per flow
            allExecutions.addAll(createFlowExecutionRecords(flowName, execsPerFlow - faults, faults));
        }

        insert allExecutions;
        return allExecutions;
    }

    private static List<Flow_Execution__c> createFlowExecutionRecords(
        String flowName, Integer successCount, Integer faultCount
    ) {
        List<Flow_Execution__c> records = new List<Flow_Execution__c>();
        for (Integer i = 0; i < successCount; i++) {
            records.add(new Flow_Execution__c(
                Flow_Name__c = flowName,
                Status__c = 'SUCCESS',
                Run_Time__c = Datetime.now().addMinutes(-i),
                CPU__c = 100,
                SOQL__c = 5,
                DML__c = 2
            ));
        }
        for (Integer i = 0; i < faultCount; i++) {
            records.add(new Flow_Execution__c(
                Flow_Name__c = flowName,
                Status__c = 'Fault',
                Run_Time__c = Datetime.now().addMinutes(-i),
                CPU__c = 500,
                SOQL__c = 25,
                DML__c = 10
            ));
        }
        return records;
    }

    // ============================================
    // PERFORMANCE ALERTS - Test Data
    // ============================================

    /**
     * @description Creates performance alert history records.
     */
    public static List<Performance_Alert_History__c> createAlertHistory(Integer count) {
        List<Performance_Alert_History__c> alerts = new List<Performance_Alert_History__c>();
        String[] metrics = new String[]{'CPU', 'SOQL', 'DML', 'Heap', 'Callouts'};

        for (Integer i = 0; i < count; i++) {
            alerts.add(new Performance_Alert_History__c(
                Metric__c = metrics[Math.mod(i, metrics.size())],
                Value__c = 80 + (Math.random() * 20),
                Threshold__c = 100,
                Context_Record__c = 'TestContext_' + i
            ));
        }

        insert alerts;
        return alerts;
    }

    // ============================================
    // API USAGE - Test Data
    // ============================================

    /**
     * @description Creates API usage snapshot records.
     */
    public static List<API_Usage_Snapshot__c> createAPISnapshots(Integer count) {
        List<API_Usage_Snapshot__c> snapshots = new List<API_Usage_Snapshot__c>();

        for (Integer i = 0; i < count; i++) {
            Decimal percentUsed = 50 + (Math.random() * 45);
            snapshots.add(new API_Usage_Snapshot__c(
                Taken_On__c = Datetime.now().addHours(-i),
                Daily_Used__c = (percentUsed * 150).intValue(),
                Daily_Limit__c = 15000,
                Percent_Used__c = percentUsed,
                Projected_Exhaustion__c = percentUsed > 80 ? Datetime.now().addHours(24 - i) : null
            ));
        }

        insert snapshots;
        return snapshots;
    }

    // ============================================
    // USERS - Test Data
    // ============================================

    /**
     * @description Creates a test user with minimal access.
     */
    public static User createMinimalAccessUser() {
        Profile minProfile = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - Salesforce' LIMIT 1];

        User u = new User(
            Alias = 'minuser',
            Email = 'minuser@test.prometheion.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Minimal User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = minProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'minuser' + DateTime.now().getTime() + '@test.prometheion.com'
        );
        insert u;
        return u;
    }

    /**
     * @description Creates a test user with System Administrator profile.
     */
    public static User createAdminUser() {
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];

        User u = new User(
            Alias = 'admuser',
            Email = 'adminuser@test.prometheion.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Admin User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = adminProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'adminuser' + DateTime.now().getTime() + '@test.prometheion.com'
        );
        insert u;
        return u;
    }

    // ============================================
    // HELPER METHODS
    // ============================================

    private static String generateTestHash(String entityType, String entityId, String framework) {
        String input = entityType + '|' + entityId + '|' + framework + '|' + System.now().getTime();
        Blob hash = Crypto.generateDigest('SHA256', Blob.valueOf(input));
        return EncodingUtil.base64Encode(hash).substring(0, 50);
    }

    private static String determineDriftCategory(Decimal riskScore) {
        if (riskScore >= 8.0) return DRIFT_POLICY_VIOLATION;
        if (riskScore >= 5.0) return DRIFT_UNAUTHORIZED;
        if (riskScore >= 3.0) return DRIFT_ANOMALY;
        return DRIFT_MANUAL_OVERRIDE;
    }

    // ============================================
    // SCENARIO BUILDERS - Complex Test Scenarios
    // ============================================

    /**
     * @description Creates a complete SOC2 audit scenario with mixed compliance states.
     */
    public static void createSOC2AuditScenario() {
        // Create permission sets with varying documentation
        createPermissionSetBatch(5, true);  // Documented
        createPermissionSetBatch(3, false); // Undocumented (compliance gap)

        // Create flow executions with varying health
        createFlowExecutions('Compliant_Flow', 50, 2);      // 96% success
        createFlowExecutions('Problematic_Flow', 30, 15);   // 67% success
        createFlowExecutions('Critical_Flow', 10, 8);       // 56% success

        // Create AI settings
        createAISettings(true, 0.85, true);
    }

    /**
     * @description Creates a HIPAA compliance scenario with PHI-related entities.
     */
    public static void createHIPAAComplianceScenario() {
        // Create strict AI settings for healthcare
        createAISettingsStrict();

        // Create permission sets for PHI access
        createDocumentedPermissionSet('PHI_Read_Access', 'Read-only access to Protected Health Information');
        createDocumentedPermissionSet('PHI_Write_Access', 'Write access to Protected Health Information - requires approval');
        createDocumentedPermissionSet('PHI_Admin', 'Full administrative access to PHI - audit logged');

        // Create alert history for PHI access monitoring
        createAlertHistory(20);
    }

    /**
     * @description Creates a GDPR data privacy scenario.
     */
    public static void createGDPRPrivacyScenario() {
        // Create AI settings with human review required
        createAISettings(true, 0.90, true);

        // Create permission sets for data subject rights
        createDocumentedPermissionSet('Data_Export', 'Allows data portability exports per GDPR Art. 20');
        createDocumentedPermissionSet('Data_Erasure', 'Allows data erasure per GDPR Art. 17');
        createDocumentedPermissionSet('Consent_Manager', 'Manages consent records per GDPR Art. 7');
    }
}
