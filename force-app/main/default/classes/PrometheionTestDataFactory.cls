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
    public static Map&lt;String, Object&gt; createMockLoginEvent() {
        return new Map&lt;String, Object&gt;{
            'EVENT_TYPE' =&gt; 'Login',
            'USER_ID' =&gt; UserInfo.getUserId(),
            'USER_NAME' =&gt; UserInfo.getUserName(),
            'SOURCE_IP' =&gt; '192.168.1.100',
            'LOGIN_STATUS' =&gt; 'Success',
            'LOGIN_TYPE' =&gt; 'Application',
            'AUTHENTICATION_METHOD_REFERENCE' =&gt; 'Password',
            'BROWSER_TYPE' =&gt; 'Chrome',
            'PLATFORM_TYPE' =&gt; 'Windows',
            'CIPHER_SUITE' =&gt; 'TLS_AES_256_GCM_SHA384',
            'TLS_PROTOCOL' =&gt; 'TLSv1.3',
            'CITY' =&gt; 'San Francisco',
            'SUBDIVISION' =&gt; 'California',
            'COUNTRY' =&gt; 'United States',
            'SESSION_KEY' =&gt; 'abc123session',
            'TIMESTAMP' =&gt; String.valueOf(Datetime.now()),
            'RISK_LEVEL' =&gt; 'MEDIUM'
        };
    }
    
    /**
     * @description Create mock LoginAs event data (impersonation)
     * @return Map of event fields simulating a LoginAs event
     */
    public static Map&lt;String, Object&gt; createMockLoginAsEvent() {
        return new Map&lt;String, Object&gt;{
            'EVENT_TYPE' =&gt; 'LoginAs',
            'DELEGATED_USER_ID' =&gt; UserInfo.getUserId(),
            'DELEGATED_USER_NAME' =&gt; UserInfo.getUserName(),
            'USER_ID' =&gt; '005000000000001AAA',
            'USER_NAME' =&gt; 'target.user@test.com',
            'SOURCE_IP' =&gt; '10.0.0.50',
            'SESSION_KEY' =&gt; 'delegate123session',
            'TIMESTAMP' =&gt; String.valueOf(Datetime.now()),
            'RISK_LEVEL' =&gt; 'CRITICAL'
        };
    }
    
    /**
     * @description Create mock ReportExport event data
     * @return Map of event fields simulating a ReportExport event
     */
    public static Map&lt;String, Object&gt; createMockReportExportEvent() {
        return new Map&lt;String, Object&gt;{
            'EVENT_TYPE' =&gt; 'ReportExport',
            'USER_ID' =&gt; UserInfo.getUserId(),
            'REPORT_ID' =&gt; '00O000000000001AAA',
            'REPORT_NAME' =&gt; 'Customer Data Export',
            'EXPORT_TYPE' =&gt; 'CSV',
            'NUMBER_OF_COLUMNS' =&gt; '15',
            'ROWS_PROCESSED' =&gt; '5000',
            'SOURCE_IP' =&gt; '192.168.1.100',
            'TIMESTAMP' =&gt; String.valueOf(Datetime.now()),
            'RISK_LEVEL' =&gt; 'CRITICAL'
        };
    }
    
    /**
     * @description Create mock API event data
     * @return Map of event fields simulating an API event
     */
    public static Map&lt;String, Object&gt; createMockApiEvent() {
        return new Map&lt;String, Object&gt;{
            'EVENT_TYPE' =&gt; 'API',
            'USER_ID' =&gt; UserInfo.getUserId(),
            'API_TYPE' =&gt; 'REST',
            'API_VERSION' =&gt; '58.0',
            'METHOD_NAME' =&gt; 'query',
            'ENTITY_NAME' =&gt; 'Account',
            'ROWS_PROCESSED' =&gt; '1500',
            'CPU_TIME' =&gt; '500',
            'RUN_TIME' =&gt; '1200',
            'CLIENT_NAME' =&gt; 'External Integration',
            'SOURCE_IP' =&gt; '203.0.113.50',
            'TIMESTAMP' =&gt; String.valueOf(Datetime.now()),
            'RISK_LEVEL' =&gt; 'HIGH'
        };
    }
    
    /**
     * @description Create mock ContentDistribution event
     * @return Map of event fields simulating a ContentDistribution event
     */
    public static Map&lt;String, Object&gt; createMockContentDistributionEvent() {
        return new Map&lt;String, Object&gt;{
            'EVENT_TYPE' =&gt; 'ContentDistribution',
            'USER_ID' =&gt; UserInfo.getUserId(),
            'CONTENT_DOCUMENT_ID' =&gt; '069000000000001AAA',
            'DISTRIBUTION_TYPE' =&gt; 'Public',
            'EXPIRATION_DATE' =&gt; String.valueOf(Date.today().addDays(30)),
            'IS_PASSWORD_PROTECTED' =&gt; 'false',
            'SOURCE_IP' =&gt; '192.168.1.100',
            'TIMESTAMP' =&gt; String.valueOf(Datetime.now()),
            'RISK_LEVEL' =&gt; 'CRITICAL'
        };
    }
    
    /**
     * @description Create mock ApexExecution event
     * @return Map of event fields simulating an ApexExecution event
     */
    public static Map&lt;String, Object&gt; createMockApexExecutionEvent() {
        return new Map&lt;String, Object&gt;{
            'EVENT_TYPE' =&gt; 'ApexExecution',
            'USER_ID' =&gt; UserInfo.getUserId(),
            'ENTRY_POINT' =&gt; 'MyController.doSomething',
            'QUIDDITY' =&gt; 'SYNCHRONOUS',
            'CPU_TIME' =&gt; '2500',
            'EXEC_TIME' =&gt; '5000',
            'CALLOUT_TIME' =&gt; '1000',
            'DB_TOTAL_TIME' =&gt; '1500',
            'DML_ROWS' =&gt; '100',
            'SOQL_QUERIES' =&gt; '5',
            'SUCCESS' =&gt; 'true',
            'TIMESTAMP' =&gt; String.valueOf(Datetime.now()),
            'RISK_LEVEL' =&gt; 'MEDIUM'
        };
    }
    
    /**
     * @description Create mock PermissionSetEventLog
     * @return Map of event fields simulating a PermissionSetEvent
     */
    public static Map&lt;String, Object&gt; createMockPermissionSetEvent() {
        return new Map&lt;String, Object&gt;{
            'EVENT_TYPE' =&gt; 'PermissionSetEventLog',
            'USER_ID' =&gt; UserInfo.getUserId(),
            'PERMISSION_SET_ID' =&gt; '0PS000000000001AAA',
            'OPERATION' =&gt; 'PermissionSetAssignment',
            'DELEGATE_USER' =&gt; '005000000000002AAA',
            'SOURCE_IP' =&gt; '192.168.1.100',
            'TIMESTAMP' =&gt; String.valueOf(Datetime.now()),
            'RISK_LEVEL' =&gt; 'HIGH'
        };
    }
    
    /**
     * @description Create high-risk event for alert testing
     * @return Map of event fields with maximum risk factors
     */
    public static Map&lt;String, Object&gt; createHighRiskEvent() {
        Map&lt;String, Object&gt; event = createMockLoginAsEvent();
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
    public static Map&lt;String, Object&gt; createMockEventWithRiskLevel(String riskLevel) {
        Map&lt;String, Object&gt; event;
        
        if (riskLevel == 'CRITICAL') {
            event = createMockLoginAsEvent();
        } else if (riskLevel == 'HIGH') {
            event = createMockApiEvent();
        } else if (riskLevel == 'MEDIUM') {
            event = createMockLoginEvent();
        } else {
            event = new Map&lt;String, Object&gt;{
                'EVENT_TYPE' =&gt; 'Logout',
                'USER_ID' =&gt; UserInfo.getUserId(),
                'TIMESTAMP' =&gt; String.valueOf(Datetime.now()),
                'RISK_LEVEL' =&gt; 'LOW'
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
        
        for (Integer i = 0; i &lt; rowCount; i++) {
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
    public static List&lt;Prometheion_Evidence_Item__c&gt; createEvidenceItems(Id packageId, Integer count) {
        List&lt;Prometheion_Evidence_Item__c&gt; items = new List&lt;Prometheion_Evidence_Item__c&gt;();
        
        List&lt;String&gt; eventTypes = new List&lt;String&gt;{'Login', 'LoginAs', 'API', 'ReportExport', 'ApexExecution'};
        List&lt;String&gt; statuses = new List&lt;String&gt;{'COLLECTED', 'REVIEWED', 'APPROVED'};
        
        for (Integer i = 0; i &lt; count; i++) {
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
    public static List&lt;Prometheion_Framework_Mapping__c&gt; createFrameworkMappings(String framework) {
        List&lt;Prometheion_Framework_Mapping__c&gt; mappings = new List&lt;Prometheion_Framework_Mapping__c&gt;();
        
        Map&lt;String, List&lt;String&gt;&gt; frameworkControls = new Map&lt;String, List&lt;String&gt;&gt;{
            'HIPAA' =&gt; new List&lt;String&gt;{'164.312(b)', '164.312(c)', '164.312(d)', '164.312(e)'},
            'SOC2' =&gt; new List&lt;String&gt;{'CC6.1', 'CC6.2', 'CC6.3', 'CC7.2'},
            'NIST' =&gt; new List&lt;String&gt;{'AC-1', 'AC-2', 'AU-2', 'AU-3'},
            'GDPR' =&gt; new List&lt;String&gt;{'Article 30', 'Article 32', 'Article 33', 'Article 34'},
            'FINRA' =&gt; new List&lt;String&gt;{'Rule 3110', 'Rule 4511', 'Rule 4370'},
            'FedRAMP' =&gt; new List&lt;String&gt;{'AC-2', 'AU-2', 'CA-7', 'SC-8'}
        };
        
        List&lt;String&gt; controls = frameworkControls.containsKey(framework) 
            ? frameworkControls.get(framework) 
            : new List&lt;String&gt;{'CTRL-001', 'CTRL-002', 'CTRL-003'};
        
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
        Map&lt;String, Object&gt; response = new Map&lt;String, Object&gt;{
            'id' =&gt; 'msg_' + String.valueOf(Datetime.now().getTime()),
            'type' =&gt; 'message',
            'role' =&gt; 'assistant',
            'content' =&gt; new List&lt;Map&lt;String, Object&gt;&gt;{
                new Map&lt;String, Object&gt;{
                    'type' =&gt; 'text',
                    'text' =&gt; JSON.serialize(new Map&lt;String, Object&gt;{
                        'recommendation' =&gt; 'Review user access patterns for potential unauthorized activity.',
                        'severity' =&gt; 'HIGH',
                        'relatedControls' =&gt; new List&lt;String&gt;{'164.312(b)', 'CC6.1'},
                        'suggestedActions' =&gt; new List&lt;String&gt;{
                            'Enable additional authentication factors',
                            'Review login patterns for anomalies'
                        },
                        'confidence' =&gt; 85
                    })
                }
            },
            'model' =&gt; 'claude-sonnet-4-20250514',
            'stop_reason' =&gt; 'end_turn'
        };
        return JSON.serialize(response);
    }
    
    /**
     * @description Create mock risk prediction response
     * @return JSON string with risk predictions
     */
    public static String createMockRiskPredictionResponse() {
        List&lt;Map&lt;String, Object&gt;&gt; predictions = new List&lt;Map&lt;String, Object&gt;&gt;{
            new Map&lt;String, Object&gt;{
                'controlId' =&gt; '164.312(b)',
                'riskProbability' =&gt; 75,
                'riskReason' =&gt; 'Increasing login failures detected',
                'predictedDate' =&gt; String.valueOf(Date.today().addDays(14))
            },
            new Map&lt;String, Object&gt;{
                'controlId' =&gt; 'CC6.1',
                'riskProbability' =&gt; 60,
                'riskReason' =&gt; 'Access pattern anomalies',
                'predictedDate' =&gt; String.valueOf(Date.today().addDays(30))
            }
        };
        
        Map&lt;String, Object&gt; response = new Map&lt;String, Object&gt;{
            'content' =&gt; new List&lt;Map&lt;String, Object&gt;&gt;{
                new Map&lt;String, Object&gt;{
                    'type' =&gt; 'text',
                    'text' =&gt; JSON.serialize(predictions)
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
        List&lt;PermissionSet&gt; psList = [
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
    public static Map&lt;String, Object&gt; createEventWithTimestamp(String eventType, Integer hoursAgo) {
        Map&lt;String, Object&gt; event = createMockEventWithRiskLevel('MEDIUM');
        event.put('EVENT_TYPE', eventType);
        event.put('TIMESTAMP', String.valueOf(Datetime.now().addHours(-hoursAgo)));
        return event;
    }
}
