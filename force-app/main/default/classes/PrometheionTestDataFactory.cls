/**
 * @description Test data factory for Prometheion unit tests
 * Provides mock data for Shield events, audit packages, and evidence items
 * @group Tests
 * @author Prometheion Team
 */
@isTest
public class PrometheionTestDataFactory {
    
    // ═══════════════════════════════════════════════════════════════
    // MOCK EVENT DATA
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @description Create mock Login event data
     * @return Map of event fields simulating a Login event
     */
    public static Map<String, Object> createMockLoginEvent() {
        return new Map<String, Object>{
            'EVENT_TYPE' => 'Login',
            'USER_ID' => UserInfo.getUserId(),
            'USER_NAME' => UserInfo.getUserName(),
            'SOURCE_IP' => '192.168.1.100',
            'LOGIN_STATUS' => 'Success',
            'LOGIN_TYPE' => 'Application',
            'AUTHENTICATION_METHOD_REFERENCE' => 'Password',
            'BROWSER_TYPE' => 'Chrome',
            'PLATFORM_TYPE' => 'Windows',
            'CIPHER_SUITE' => 'TLS_AES_256_GCM_SHA384',
            'TLS_PROTOCOL' => 'TLSv1.3',
            'CITY' => 'San Francisco',
            'SUBDIVISION' => 'California',
            'COUNTRY' => 'United States',
            'SESSION_KEY' => 'abc123session',
            'TIMESTAMP' => String.valueOf(Datetime.now()),
            'RISK_LEVEL' => 'MEDIUM'
        };
    }
    
    /**
     * @description Create mock LoginAs event data (impersonation)
     * @return Map of event fields simulating a LoginAs event
     */
    public static Map<String, Object> createMockLoginAsEvent() {
        return new Map<String, Object>{
            'EVENT_TYPE' => 'LoginAs',
            'DELEGATED_USER_ID' => UserInfo.getUserId(),
            'DELEGATED_USER_NAME' => UserInfo.getUserName(),
            'USER_ID' => '005000000000001AAA',
            'USER_NAME' => 'target.user@test.com',
            'SOURCE_IP' => '10.0.0.50',
            'SESSION_KEY' => 'delegate123session',
            'TIMESTAMP' => String.valueOf(Datetime.now()),
            'RISK_LEVEL' => 'CRITICAL'
        };
    }
    
    /**
     * @description Create mock ReportExport event data
     * @return Map of event fields simulating a ReportExport event
     */
    public static Map<String, Object> createMockReportExportEvent() {
        return new Map<String, Object>{
            'EVENT_TYPE' => 'ReportExport',
            'USER_ID' => UserInfo.getUserId(),
            'REPORT_ID' => '00O000000000001AAA',
            'REPORT_NAME' => 'Customer Data Export',
            'EXPORT_TYPE' => 'CSV',
            'NUMBER_OF_COLUMNS' => '15',
            'ROWS_PROCESSED' => '5000',
            'SOURCE_IP' => '192.168.1.100',
            'TIMESTAMP' => String.valueOf(Datetime.now()),
            'RISK_LEVEL' => 'CRITICAL'
        };
    }
    
    /**
     * @description Create mock API event data
     * @return Map of event fields simulating an API event
     */
    public static Map<String, Object> createMockApiEvent() {
        return new Map<String, Object>{
            'EVENT_TYPE' => 'API',
            'USER_ID' => UserInfo.getUserId(),
            'API_TYPE' => 'REST',
            'API_VERSION' => '58.0',
            'METHOD_NAME' => 'query',
            'ENTITY_NAME' => 'Account',
            'ROWS_PROCESSED' => '1500',
            'CPU_TIME' => '500',
            'RUN_TIME' => '1200',
            'CLIENT_NAME' => 'External Integration',
            'SOURCE_IP' => '203.0.113.50',
            'TIMESTAMP' => String.valueOf(Datetime.now()),
            'RISK_LEVEL' => 'HIGH'
        };
    }
    
    /**
     * @description Create mock ContentDistribution event
     * @return Map of event fields simulating a ContentDistribution event
     */
    public static Map<String, Object> createMockContentDistributionEvent() {
        return new Map<String, Object>{
            'EVENT_TYPE' => 'ContentDistribution',
            'USER_ID' => UserInfo.getUserId(),
            'CONTENT_DOCUMENT_ID' => '069000000000001AAA',
            'DISTRIBUTION_TYPE' => 'Public',
            'EXPIRATION_DATE' => String.valueOf(Date.today().addDays(30)),
            'IS_PASSWORD_PROTECTED' => 'false',
            'SOURCE_IP' => '192.168.1.100',
            'TIMESTAMP' => String.valueOf(Datetime.now()),
            'RISK_LEVEL' => 'CRITICAL'
        };
    }
    
    /**
     * @description Create mock ApexExecution event
     * @return Map of event fields simulating an ApexExecution event
     */
    public static Map<String, Object> createMockApexExecutionEvent() {
        return new Map<String, Object>{
            'EVENT_TYPE' => 'ApexExecution',
            'USER_ID' => UserInfo.getUserId(),
            'ENTRY_POINT' => 'MyController.doSomething',
            'QUIDDITY' => 'SYNCHRONOUS',
            'CPU_TIME' => '2500',
            'EXEC_TIME' => '5000',
            'CALLOUT_TIME' => '1000',
            'DB_TOTAL_TIME' => '1500',
            'DML_ROWS' => '100',
            'SOQL_QUERIES' => '5',
            'SUCCESS' => 'true',
            'TIMESTAMP' => String.valueOf(Datetime.now()),
            'RISK_LEVEL' => 'MEDIUM'
        };
    }
    
    /**
     * @description Create mock PermissionSetEventLog
     * @return Map of event fields simulating a PermissionSetEvent
     */
    public static Map<String, Object> createMockPermissionSetEvent() {
        return new Map<String, Object>{
            'EVENT_TYPE' => 'PermissionSetEventLog',
            'USER_ID' => UserInfo.getUserId(),
            'PERMISSION_SET_ID' => '0PS000000000001AAA',
            'OPERATION' => 'PermissionSetAssignment',
            'DELEGATE_USER' => '005000000000002AAA',
            'SOURCE_IP' => '192.168.1.100',
            'TIMESTAMP' => String.valueOf(Datetime.now()),
            'RISK_LEVEL' => 'HIGH'
        };
    }
    
    /**
     * @description Create high-risk event for alert testing
     * @return Map of event fields with maximum risk factors
     */
    public static Map<String, Object> createHighRiskEvent() {
        Map<String, Object> event = createMockLoginAsEvent();
        event.put('ROWS_PROCESSED', '50000'); // Large data volume
        event.put('COUNTRY', 'Russia'); // Non-US location
        event.put('HOUR', '3'); // Outside business hours
        return event;
    }
    
    /**
     * @description Create mock event with specific risk level
     * @param riskLevel The desired risk level (CRITICAL, HIGH, MEDIUM, LOW)
     * @return Map of event fields with specified risk level
     */
    public static Map<String, Object> createMockEventWithRiskLevel(String riskLevel) {
        Map<String, Object> event;
        
        if (riskLevel == 'CRITICAL') {
            event = createMockLoginAsEvent();
        } else if (riskLevel == 'HIGH') {
            event = createMockApiEvent();
        } else if (riskLevel == 'MEDIUM') {
            event = createMockLoginEvent();
        } else {
            event = new Map<String, Object>{
                'EVENT_TYPE' => 'Logout',
                'USER_ID' => UserInfo.getUserId(),
                'TIMESTAMP' => String.valueOf(Datetime.now()),
                'RISK_LEVEL' => 'LOW'
            };
        }
        
        event.put('RISK_LEVEL', riskLevel);
        return event;
    }
    
    // ═══════════════════════════════════════════════════════════════
    // CSV DATA FOR EVENTLOGFILE PARSING
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @description Create mock CSV content for Login events
     * @param rowCount Number of rows to generate
     * @return CSV string with header and data rows
     */
    public static String createMockLoginCSV(Integer rowCount) {
        String csv = 'EVENT_TYPE,USER_ID,USER_NAME,SOURCE_IP,LOGIN_STATUS,LOGIN_TYPE,TIMESTAMP\n';
        
        for (Integer i = 0; i < rowCount; i++) {
            csv += 'Login,' + UserInfo.getUserId() + ',testuser' + i + '@test.com,192.168.1.' + 
                   Math.mod(i, 255) + ',Success,Application,' + String.valueOf(Datetime.now().addHours(-i)) + '\n';
        }
        
        return csv;
    }
    
    /**
     * @description Create mock CSV content with various event types
     * @return CSV string with multiple event types
     */
    public static String createMockMixedEventCSV() {
        String csv = 'EVENT_TYPE,USER_ID,SOURCE_IP,TIMESTAMP,ROWS_PROCESSED\n';
        csv += 'Login,' + UserInfo.getUserId() + ',192.168.1.1,' + Datetime.now() + ',0\n';
        csv += 'API,' + UserInfo.getUserId() + ',192.168.1.2,' + Datetime.now().addMinutes(-5) + ',1000\n';
        csv += 'ReportExport,' + UserInfo.getUserId() + ',192.168.1.3,' + Datetime.now().addMinutes(-10) + ',5000\n';
        return csv;
    }
    
    // ═══════════════════════════════════════════════════════════════
    // CUSTOM OBJECT RECORDS
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @description Create Audit Package record
     * @param framework The compliance framework (HIPAA, SOC2, GDPR, etc.)
     * @return Inserted Prometheion_Audit_Package__c record
     */
    public static Prometheion_Audit_Package__c createAuditPackage(String framework) {
        Prometheion_Audit_Package__c pkg = new Prometheion_Audit_Package__c(
            Package_Name__c = 'Test Package - ' + framework + ' - ' + Date.today().format(),
            Framework__c = framework,
            Status__c = 'DRAFT',
            Audit_Period_Start__c = Date.today().addDays(-30),
            Audit_Period_End__c = Date.today()
        );
        insert pkg;
        return pkg;
    }
    
    /**
     * @description Create Audit Package without insert
     * @param framework The compliance framework
     * @return Non-inserted Prometheion_Audit_Package__c record
     */
    public static Prometheion_Audit_Package__c buildAuditPackage(String framework) {
        return new Prometheion_Audit_Package__c(
            Package_Name__c = 'Test Package - ' + framework,
            Framework__c = framework,
            Status__c = 'DRAFT',
            Audit_Period_Start__c = Date.today().addDays(-30),
            Audit_Period_End__c = Date.today()
        );
    }
    
    /**
     * @description Create Evidence Item record
     * @param packageId The parent Audit Package ID
     * @return Inserted Prometheion_Evidence_Item__c record
     */
    public static Prometheion_Evidence_Item__c createEvidenceItem(Id packageId) {
        Prometheion_Evidence_Item__c item = new Prometheion_Evidence_Item__c(
            Audit_Package__c = packageId,
            Evidence_Type__c = 'Login',
            Evidence_Date__c = Date.today(),
            Description__c = 'Test evidence item',
            Status__c = 'COLLECTED'
        );
        insert item;
        return item;
    }
    
    /**
     * @description Create Evidence Item without insert
     * @param packageId The parent Audit Package ID
     * @return Non-inserted Prometheion_Evidence_Item__c record
     */
    public static Prometheion_Evidence_Item__c buildEvidenceItem(Id packageId) {
        return new Prometheion_Evidence_Item__c(
            Audit_Package__c = packageId,
            Evidence_Type__c = 'Login',
            Evidence_Date__c = Date.today(),
            Description__c = 'Test evidence item',
            Status__c = 'COLLECTED'
        );
    }
    
    /**
     * @description Create multiple evidence items
     * @param packageId The parent Audit Package ID
     * @param count Number of items to create
     * @return List of inserted Prometheion_Evidence_Item__c records
     */
    public static List<Prometheion_Evidence_Item__c> createEvidenceItems(Id packageId, Integer count) {
        List<Prometheion_Evidence_Item__c> items = new List<Prometheion_Evidence_Item__c>();
        
        List<String> eventTypes = new List<String>{'Login', 'LoginAs', 'API', 'ReportExport', 'ApexExecution'};
        List<String> statuses = new List<String>{'COLLECTED', 'REVIEWED', 'APPROVED'};
        
        for (Integer i = 0; i < count; i++) {
            items.add(new Prometheion_Evidence_Item__c(
                Audit_Package__c = packageId,
                Evidence_Type__c = eventTypes[Math.mod(i, eventTypes.size())],
                Evidence_Date__c = Date.today().addDays(-i),
                Description__c = 'Test evidence item ' + i,
                Status__c = statuses[Math.mod(i, statuses.size())]
            ));
        }
        
        insert items;
        return items;
    }
    
    /**
     * @description Create Framework Mapping record
     * @param framework The compliance framework
     * @param requirementCode The requirement/control code
     * @return Inserted Prometheion_Framework_Mapping__c record
     */
    public static Prometheion_Framework_Mapping__c createFrameworkMapping(String framework, String requirementCode) {
        Prometheion_Framework_Mapping__c mapping = new Prometheion_Framework_Mapping__c(
            Framework__c = framework,
            Requirement_Code__c = requirementCode,
            Requirement_Description__c = 'Test requirement for ' + requirementCode,
            Entity_Type__c = 'PermissionSet',
            Is_Active__c = true
        );
        insert mapping;
        return mapping;
    }
    
    /**
     * @description Create multiple framework mappings for a framework
     * @param framework The compliance framework
     * @return List of inserted Prometheion_Framework_Mapping__c records
     */
    public static List<Prometheion_Framework_Mapping__c> createFrameworkMappings(String framework) {
        List<Prometheion_Framework_Mapping__c> mappings = new List<Prometheion_Framework_Mapping__c>();
        
        Map<String, List<String>> frameworkControls = new Map<String, List<String>>{
            'HIPAA' => new List<String>{'164.312(b)', '164.312(c)', '164.312(d)', '164.312(e)'},
            'SOC2' => new List<String>{'CC6.1', 'CC6.2', 'CC6.3', 'CC7.2'},
            'NIST' => new List<String>{'AC-1', 'AC-2', 'AU-2', 'AU-3'},
            'GDPR' => new List<String>{'Article 30', 'Article 32', 'Article 33', 'Article 34'},
            'FINRA' => new List<String>{'Rule 3110', 'Rule 4511', 'Rule 4370'},
            'FedRAMP' => new List<String>{'AC-2', 'AU-2', 'CA-7', 'SC-8'}
        };
        
        List<String> controls = frameworkControls.containsKey(framework) 
            ? frameworkControls.get(framework) 
            : new List<String>{'CTRL-001', 'CTRL-002', 'CTRL-003'};
        
        for (String controlId : controls) {
            mappings.add(new Prometheion_Framework_Mapping__c(
                Framework__c = framework,
                Requirement_Code__c = controlId,
                Requirement_Description__c = 'Control ' + controlId,
                Entity_Type__c = 'PermissionSet',
                Is_Active__c = true
            ));
        }
        
        insert mappings;
        return mappings;
    }
    
    // ═══════════════════════════════════════════════════════════════
    // MOCK HTTP RESPONSES
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @description Create mock Claude API response for compliance analysis
     * @return JSON string mimicking Claude API response
     */
    public static String createMockClaudeResponse() {
        Map<String, Object> response = new Map<String, Object>{
            'id' => 'msg_' + String.valueOf(Datetime.now().getTime()),
            'type' => 'message',
            'role' => 'assistant',
            'content' => new List<Map<String, Object>>{
                new Map<String, Object>{
                    'type' => 'text',
                    'text' => JSON.serialize(new Map<String, Object>{
                        'recommendation' => 'Review user access patterns for potential unauthorized activity.',
                        'severity' => 'HIGH',
                        'relatedControls' => new List<String>{'164.312(b)', 'CC6.1'},
                        'suggestedActions' => new List<String>{
                            'Enable additional authentication factors',
                            'Review login patterns for anomalies'
                        },
                        'confidence' => 85
                    })
                }
            },
            'model' => 'claude-sonnet-4-20250514',
            'stop_reason' => 'end_turn'
        };
        return JSON.serialize(response);
    }
    
    /**
     * @description Create mock risk prediction response
     * @return JSON string with risk predictions
     */
    public static String createMockRiskPredictionResponse() {
        List<Map<String, Object>> predictions = new List<Map<String, Object>>{
            new Map<String, Object>{
                'controlId' => '164.312(b)',
                'riskProbability' => 75,
                'riskReason' => 'Increasing login failures detected',
                'predictedDate' => String.valueOf(Date.today().addDays(14))
            },
            new Map<String, Object>{
                'controlId' => 'CC6.1',
                'riskProbability' => 60,
                'riskReason' => 'Access pattern anomalies',
                'predictedDate' => String.valueOf(Date.today().addDays(30))
            }
        };
        
        Map<String, Object> response = new Map<String, Object>{
            'content' => new List<Map<String, Object>>{
                new Map<String, Object>{
                    'type' => 'text',
                    'text' => JSON.serialize(predictions)
                }
            }
        };
        return JSON.serialize(response);
    }
    
    // ═══════════════════════════════════════════════════════════════
    // USER &amp; PERMISSION SETUP
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @description Create test user with specific profile
     * @param profileName The profile name to assign
     * @return Inserted User record
     */
    public static User createTestUser(String profileName) {
        Profile p = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1];
        
        String uniqueId = String.valueOf(Datetime.now().getTime());
        User u = new User(
            FirstName = 'Test',
            LastName = 'User' + uniqueId,
            Email = 'testuser' + uniqueId + '@prometheion.test',
            Username = 'testuser' + uniqueId + '@prometheion.test',
            Alias = 'tu' + uniqueId.right(6),
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert u;
        return u;
    }
    
    /**
     * @description Assign permission set to user
     * @param userId The user ID to assign to
     * @param permissionSetName The permission set name
     */
    public static void assignPermissionSet(Id userId, String permissionSetName) {
        List<PermissionSet> psList = [
            SELECT Id FROM PermissionSet WHERE Name = :permissionSetName LIMIT 1
        ];
        
        if (!psList.isEmpty()) {
            insert new PermissionSetAssignment(
                AssigneeId = userId,
                PermissionSetId = psList[0].Id
            );
        }
    }
    
    // ═══════════════════════════════════════════════════════════════
    // UTILITY METHODS
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @description Generate a random IP address
     * @return Random IP address string
     */
    public static String generateRandomIP() {
        return String.valueOf(Math.floor(Math.random() * 255)) + '.' +
               String.valueOf(Math.floor(Math.random() * 255)) + '.' +
               String.valueOf(Math.floor(Math.random() * 255)) + '.' +
               String.valueOf(Math.floor(Math.random() * 255));
    }
    
    /**
     * @description Generate event data with specific timestamp
     * @param eventType The event type
     * @param hoursAgo Hours in the past for the timestamp
     * @return Map of event data
     */
    public static Map<String, Object> createEventWithTimestamp(String eventType, Integer hoursAgo) {
        Map<String, Object> event = createMockEventWithRiskLevel('MEDIUM');
        event.put('EVENT_TYPE', eventType);
        event.put('TIMESTAMP', String.valueOf(Datetime.now().addHours(-hoursAgo)));
        return event;
    }
    
    // ═══════════════════════════════════════════════════════════════
    // PERFORMANCE RULE ENGINE TEST DATA
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @description Create CCX_Settings__c custom setting with custom thresholds
     * @param cpuWarn CPU warning threshold (ms)
     * @param cpuCrit CPU critical threshold (ms)
     * @param heapWarn Heap warning threshold (KB)
     * @param heapCrit Heap critical threshold (KB)
     * @param soqlWarn SOQL warning threshold
     * @param soqlCrit SOQL critical threshold
     * @param dmlWarn DML warning threshold
     * @param dmlCrit DML critical threshold
     * @return Inserted CCX_Settings__c record
     */
    public static CCX_Settings__c createCCXSettings(
        Integer cpuWarn, Integer cpuCrit,
        Integer heapWarn, Integer heapCrit,
        Integer soqlWarn, Integer soqlCrit,
        Integer dmlWarn, Integer dmlCrit
    ) {
        CCX_Settings__c settings = new CCX_Settings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            CPU_Warn__c = cpuWarn,
            CPU_Crit__c = cpuCrit,
            Heap_Warn__c = heapWarn,
            Heap_Crit__c = heapCrit,
            SOQL_Warn__c = soqlWarn,
            SOQL_Crit__c = soqlCrit,
            DML_Warn__c = dmlWarn,
            DML_Crit__c = dmlCrit
        );
        insert settings;
        return settings;
    }
    
    /**
     * @description Create Performance_Alert_History__c record for testing
     * @param metric The metric name (CPU, HEAP, SOQL, DML)
     * @param value The metric value
     * @param threshold The threshold value
     * @return Inserted Performance_Alert_History__c record
     */
    public static Performance_Alert_History__c createPerformanceAlert(
        String metric, Decimal value, Decimal threshold
    ) {
        Performance_Alert_History__c alert = new Performance_Alert_History__c(
            Metric__c = metric,
            Value__c = value,
            Threshold__c = threshold,
            Context_Record__c = UserInfo.getUserId(),
            Stack__c = metric + ' threshold exceeded: ' + value + ' >= ' + threshold
        );
        insert alert;
        return alert;
    }
}
