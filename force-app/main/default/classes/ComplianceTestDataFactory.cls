/**
 * ComplianceTestDataFactory
 * 
 * Test data factory for creating compliance test data across all frameworks
 * 
 * @author Elaro
 * @version 1.0
 */
@IsTest
public class ComplianceTestDataFactory {
    
    /**
     * Create test compliance gaps for a framework
     * @param framework Framework name
     * @param count Number of gaps to create
     * @return List of Compliance_Gap__c records
     */
    public static List<Compliance_Gap__c> createComplianceGaps(String framework, Integer count) {
        List<Compliance_Gap__c> gaps = new List<Compliance_Gap__c>();
        
        for (Integer i = 0; i < count; i++) {
            Integer mod4 = Math.mod(i, 4);
            Integer mod3 = Math.mod(i, 3);
            
            Compliance_Gap__c gap = new Compliance_Gap__c(
                Framework__c = framework,
                Policy_Reference__c = 'TEST_POLICY_' + i,
                Gap_Description__c = 'Test gap ' + i + ' for ' + framework,
                Severity__c = mod4 == 0 ? 'CRITICAL' : mod4 == 1 ? 'HIGH' : mod4 == 2 ? 'MEDIUM' : 'LOW',
                Status__c = mod3 == 0 ? 'OPEN' : mod3 == 1 ? 'IN_PROGRESS' : 'REMEDIATED',
                Risk_Score__c = 5.0 + (i * 0.5),
                Detected_Date__c = System.now().addDays(-i),
                Entity_Type__c = 'PERMISSION_SET',
                Entity_Id__c = '00100000000000' + String.valueOf(1000 + i).substring(1)
            );
            gaps.add(gap);
        }
        
        return gaps;
    }
    
    /**
     * Create test compliance evidence for a framework
     * @param framework Framework name
     * @param count Number of evidence records to create
     * @return List of Compliance_Evidence__c records
     */
    public static List<Compliance_Evidence__c> createComplianceEvidence(String framework, Integer count) {
        List<Compliance_Evidence__c> evidence = new List<Compliance_Evidence__c>();
        
        List<String> evidenceTypes = new List<String>{
            'SETUP_AUDIT_TRAIL', 'FIELD_HISTORY', 'PERMISSION_SET', 
            'SHARING_RULE', 'LOGIN_HISTORY', 'API_USAGE', 'FLOW_EXECUTION', 'METADATA_CHANGE', 'DOCUMENT'
        };
        
        for (Integer i = 0; i < count; i++) {
            Integer mod2 = Math.mod(i, 2);
            
            Compliance_Evidence__c ev = new Compliance_Evidence__c(
                Framework__c = framework,
                Evidence_Type__c = evidenceTypes[Math.mod(i, evidenceTypes.size())],
                Evidence_Date__c = System.today().addDays(-i),
                Description__c = 'Test evidence ' + i + ' for ' + framework,
                Evidence_Data__c = JSON.serialize(new Map<String, Object>{
                    'testId' => 'TEST-' + i,
                    'framework' => framework,
                    'createdDate' => String.valueOf(System.now())
                }),
                Status__c = mod2 == 0 ? 'COLLECTED' : 'APPROVED',
                Compliance_Score__c = 70.0 + (i * 2.0)
            );
            evidence.add(ev);
        }
        
        return evidence;
    }
    
    /**
     * Create test metadata changes
     * @param count Number of changes to create
     * @return List of Metadata_Change__c records
     */
    public static List<Metadata_Change__c> createMetadataChanges(Integer count) {
        List<Metadata_Change__c> changes = new List<Metadata_Change__c>();
        
        List<String> changeTypes = new List<String>{'CREATE', 'UPDATE', 'DELETE'};
        List<String> metadataTypes = new List<String>{
            'CustomObject', 'ApexClass', 'Flow', 'PermissionSet', 'Profile', 'SharingRule'
        };
        
        for (Integer i = 0; i < count; i++) {
            Integer mod4 = Math.mod(i, 4);
            
            Metadata_Change__c change = new Metadata_Change__c(
                Change_Type__c = changeTypes[Math.mod(i, changeTypes.size())],
                Metadata_Type__c = metadataTypes[Math.mod(i, metadataTypes.size())],
                Metadata_Name__c = 'TestMetadata' + i,
                Metadata_Id__c = '00100000000000' + String.valueOf(1000 + i).substring(1),
                Changed_By__c = UserInfo.getUserId(),
                Change_Date__c = System.now().addDays(-i),
                Change_Details__c = JSON.serialize(new Map<String, Object>{
                    'before' => 'OldValue' + i,
                    'after' => 'NewValue' + i
                }),
                Risk_Level__c = mod4 == 0 ? 'CRITICAL' : mod4 == 1 ? 'HIGH' : mod4 == 2 ? 'MEDIUM' : 'LOW'
            );
            changes.add(change);
        }
        
        return changes;
    }
    
    /**
     * Create test compliance gaps for all frameworks
     * @param gapsPerFramework Number of gaps per framework
     * @return List of all Compliance_Gap__c records
     */
    public static List<Compliance_Gap__c> createGapsForAllFrameworks(Integer gapsPerFramework) {
        List<Compliance_Gap__c> allGaps = new List<Compliance_Gap__c>();
        
        List<String> frameworks = new List<String>{
            'SOX', 'SOC2', 'HIPAA', 'GDPR', 'CCPA', 'GLBA', 'NIST', 'ISO27001', 'PCI_DSS'
        };
        
        for (String framework : frameworks) {
            allGaps.addAll(createComplianceGaps(framework, gapsPerFramework));
        }
        
        return allGaps;
    }
    
    /**
     * Create test compliance evidence for all frameworks
     * @param evidencePerFramework Number of evidence records per framework
     * @return List of all Compliance_Evidence__c records
     */
    public static List<Compliance_Evidence__c> createEvidenceForAllFrameworks(Integer evidencePerFramework) {
        List<Compliance_Evidence__c> allEvidence = new List<Compliance_Evidence__c>();
        
        List<String> frameworks = new List<String>{
            'SOX', 'SOC2', 'HIPAA', 'GDPR', 'CCPA', 'GLBA', 'NIST', 'ISO27001', 'PCI_DSS'
        };
        
        for (String framework : frameworks) {
            allEvidence.addAll(createComplianceEvidence(framework, evidencePerFramework));
        }
        
        return allEvidence;
    }
    
    /**
     * Create a test user with permission set assignments
     * @return User record
     */
    public static User createTestUser() {
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser' + System.now().getTime() + '@elaro.test',
            Username = 'testuser' + System.now().getTime() + '@elaro.test',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US'
        );
        return testUser;
    }
    
    /**
     * Create test permission set with object permissions
     * @param name Permission set name
     * @param objectType SObject type to grant permissions on
     * @return PermissionSet record
     */
    public static PermissionSet createTestPermissionSet(String name, String objectType) {
        PermissionSet ps = new PermissionSet(
            Name = name,
            Label = name
        );
        return ps;
    }
}
