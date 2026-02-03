/**
 * Elaro Test Data Generator (Validation Dataset)
 *
 * Creates a representative mix of data to validate:
 * - Compliance dashboards (scores, gaps, evidence)
 * - Audit packages and evidence items
 * - Framework services (GDPR/CCPA/GLBA/ISO)
 * - Monitoring dashboards (API usage, flow execution, performance alerts)
 * - Integration error handling and metadata change tracking
 *
 * Usage: sf apex run --file scripts/create-test-data.apex --target-org [org-alias]
 */

String dataTag = 'ElaroTestData:Validation';
Datetime now = System.now();
Date today = Date.today();
User currentUser = [SELECT Id, Name, Email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

System.debug('=== Elaro Validation Test Data ===');
System.debug('Tag: ' + dataTag);
System.debug('Running as: ' + currentUser.Name + ' (' + currentUser.Email + ')');

// Base Account + Contact for framework records
Account testAccount;
List<Account> accountMatches = [
    SELECT Id, Name
    FROM Account
    WHERE Name = 'Elaro Test Account'
    LIMIT 1
];
if (accountMatches.isEmpty()) {
    testAccount = new Account(
        Name = 'Elaro Test Account',
        Description = dataTag + ' demo account'
    );
    insert testAccount;
} else {
    testAccount = accountMatches[0];
}

Contact testContact;
List<Contact> contactMatches = [
    SELECT Id, Email, LastName
    FROM Contact
    WHERE Email = 'elaro.test@example.com'
    LIMIT 1
];
if (contactMatches.isEmpty()) {
    testContact = new Contact(
        FirstName = 'Elaro',
        LastName = 'Validation',
        Email = 'elaro.test@example.com',
        AccountId = testAccount.Id
    );
    insert testContact;
} else {
    testContact = contactMatches[0];
}

System.debug('Using Account: ' + testAccount.Id + ', Contact: ' + testContact.Id);

// Permission sets + assignments
Set<String> permSetNames = new Set<String>{
    'Test_ModifyAll_Access',
    'Test_ViewAll_Access',
    'Test_Standard_Access'
};

Map<String, PermissionSet> existingPermSets = new Map<String, PermissionSet>();
for (PermissionSet ps : [
    SELECT Id, Name
    FROM PermissionSet
    WHERE Name IN :permSetNames
]) {
    existingPermSets.put(ps.Name, ps);
}

List<PermissionSet> newPermSets = new List<PermissionSet>();
if (!existingPermSets.containsKey('Test_ModifyAll_Access')) {
    newPermSets.add(new PermissionSet(
        Name = 'Test_ModifyAll_Access',
        Label = 'Test Modify All Data Access',
        Description = dataTag + ' permission set for sprawl testing'
    ));
}
if (!existingPermSets.containsKey('Test_ViewAll_Access')) {
    newPermSets.add(new PermissionSet(
        Name = 'Test_ViewAll_Access',
        Label = 'Test View All Data Access',
        Description = dataTag + ' permission set for sprawl testing'
    ));
}
if (!existingPermSets.containsKey('Test_Standard_Access')) {
    newPermSets.add(new PermissionSet(
        Name = 'Test_Standard_Access',
        Label = 'Test Standard Access',
        Description = dataTag + ' standard access permission set'
    ));
}

if (!newPermSets.isEmpty()) {
    List<Database.SaveResult> permResults = Database.insert(newPermSets, false);
    Integer permCreated = 0;
    Integer permFailed = 0;
    for (Database.SaveResult sr : permResults) {
        if (sr.isSuccess()) {
            permCreated++;
        } else {
            permFailed++;
        }
    }
    System.debug('Permission sets created: ' + permCreated + ', failed: ' + permFailed);
}

Map<String, PermissionSet> permSets = new Map<String, PermissionSet>();
for (PermissionSet ps : [
    SELECT Id, Name
    FROM PermissionSet
    WHERE Name IN :permSetNames
]) {
    permSets.put(ps.Name, ps);
}

Set<Id> permSetIds = new Set<Id>();
for (PermissionSet ps : permSets.values()) {
    permSetIds.add(ps.Id);
}

Map<Id, PermissionSetAssignment> existingAssignments = new Map<Id, PermissionSetAssignment>();
if (!permSetIds.isEmpty()) {
    for (PermissionSetAssignment psa : [
        SELECT Id, PermissionSetId
        FROM PermissionSetAssignment
        WHERE AssigneeId = :currentUser.Id
        AND PermissionSetId IN :permSetIds
    ]) {
        existingAssignments.put(psa.PermissionSetId, psa);
    }
}

List<PermissionSetAssignment> newAssignments = new List<PermissionSetAssignment>();
for (Id psId : permSetIds) {
    if (!existingAssignments.containsKey(psId)) {
        newAssignments.add(new PermissionSetAssignment(
            AssigneeId = currentUser.Id,
            PermissionSetId = psId
        ));
    }
}

if (!newAssignments.isEmpty()) {
    List<Database.SaveResult> assignmentResults = Database.insert(newAssignments, false);
    Integer assignCreated = 0;
    Integer assignFailed = 0;
    for (Database.SaveResult sr : assignmentResults) {
        if (sr.isSuccess()) {
            assignCreated++;
        } else {
            assignFailed++;
        }
    }
    System.debug('Permission set assignments created: ' + assignCreated + ', failed: ' + assignFailed);
}

System.debug('Note: Modify All Data / View All Data permissions cannot be set via DML.');
System.debug('Assign elevated permissions manually if you need sprawl scoring to reflect them.');

// Audit package + framework mapping for evidence items
String auditPackageName = 'Elaro Validation Audit Package';
Elaro_Audit_Package__c auditPackage;
List<Elaro_Audit_Package__c> packageMatches = [
    SELECT Id, Package_Name__c
    FROM Elaro_Audit_Package__c
    WHERE Package_Name__c = :auditPackageName
    LIMIT 1
];
if (packageMatches.isEmpty()) {
    auditPackage = new Elaro_Audit_Package__c(
        Package_Name__c = auditPackageName,
        Framework__c = 'SOC2',
        Status__c = 'IN_PROGRESS',
        Audit_Period_Start__c = today.addMonths(-3),
        Audit_Period_End__c = today,
        Description__c = dataTag + ' audit package for validation'
    );
    insert auditPackage;
} else {
    auditPackage = packageMatches[0];
}

String mappingCode = 'SOC2-CC6.1-VALIDATION';
Elaro_Framework_Mapping__c frameworkMapping;
List<Elaro_Framework_Mapping__c> mappingMatches = [
    SELECT Id, Requirement_Code__c
    FROM Elaro_Framework_Mapping__c
    WHERE Requirement_Code__c = :mappingCode
    LIMIT 1
];
if (mappingMatches.isEmpty()) {
    frameworkMapping = new Elaro_Framework_Mapping__c(
        Framework__c = 'SOC2',
        Requirement_Code__c = mappingCode,
        Requirement_Description__c = dataTag + ' logical access control validation mapping',
        Entity_Type__c = 'PERMISSION_SET',
        Audit_Package__c = auditPackage.Id
    );
    insert frameworkMapping;
} else {
    frameworkMapping = mappingMatches[0];
}

String gapEntityId = permSets.containsKey('Test_ViewAll_Access')
    ? String.valueOf(permSets.get('Test_ViewAll_Access').Id)
    : currentUser.Id;

// Compliance scores
List<Compliance_Score__c> scores = new List<Compliance_Score__c>{
    new Compliance_Score__c(
        Org_ID__c = UserInfo.getOrganizationId(),
        Entity_Type__c = 'ORG',
        Entity_Id__c = UserInfo.getOrganizationId(),
        Risk_Score__c = 6.8,
        Framework_Scores__c = '{"HIPAA":82.5,"SOC2":90.1,"GDPR":78.2,"PCI_DSS":88.0,"NIST":84.0}',
        Findings__c = dataTag + '\n- Elevated access coverage above threshold\n- Password policy below HIPAA target',
        S3_Key__c = 'validation/score/org-score.json',
        Calculated_At__c = now.addMinutes(-30)
    ),
    new Compliance_Score__c(
        Org_ID__c = UserInfo.getOrganizationId(),
        Entity_Type__c = 'PERMISSION_SET',
        Entity_Id__c = gapEntityId,
        Risk_Score__c = 8.9,
        Framework_Scores__c = '{"HIPAA":72.0,"SOC2":68.5,"GDPR":70.2}',
        Findings__c = dataTag + '\n- Modify All Data detected\n- Field history missing on PHI',
        S3_Key__c = 'validation/score/permission-set-score.json',
        Calculated_At__c = now.addMinutes(-20)
    ),
    new Compliance_Score__c(
        Org_ID__c = UserInfo.getOrganizationId(),
        Entity_Type__c = 'USER',
        Entity_Id__c = currentUser.Id,
        Risk_Score__c = 4.2,
        Framework_Scores__c = '{"HIPAA":88.0,"SOC2":92.0,"GDPR":85.0}',
        Findings__c = dataTag + '\n- User has elevated permissions assigned',
        S3_Key__c = 'validation/score/user-score.json',
        Calculated_At__c = now.addMinutes(-10)
    )
};

List<Database.SaveResult> scoreResults = Database.insert(scores, false);
Integer scoreCreated = 0;
Integer scoreFailed = 0;
for (Database.SaveResult sr : scoreResults) {
    if (sr.isSuccess()) {
        scoreCreated++;
    } else {
        scoreFailed++;
    }
}
System.debug('Compliance scores created: ' + scoreCreated + ', failed: ' + scoreFailed);

// Compliance gaps
List<Compliance_Gap__c> gaps = new List<Compliance_Gap__c>{
    new Compliance_Gap__c(
        Framework__c = 'HIPAA',
        Policy_Reference__c = 'HIPAA_164_312_a_Access',
        Severity__c = 'HIGH',
        Status__c = 'OPEN',
        Detected_Date__c = now.addDays(-7),
        Gap_Description__c = dataTag + ' Elevated access to PHI fields',
        Remediation_Plan__c = 'Review permission sets and remove broad access',
        Remediation_Owner__c = currentUser.Id,
        Target_Remediation_Date__c = today.addDays(30),
        Risk_Score__c = 8.2,
        Entity_Type__c = 'PERMISSION_SET',
        Entity_Id__c = gapEntityId,
        Notes__c = 'Created for validation',
        Jira_Issue_Key__c = 'ELARO-TEST-001'
    ),
    new Compliance_Gap__c(
        Framework__c = 'SOC2',
        Policy_Reference__c = 'SOC2_CC6_1_Access_Control',
        Severity__c = 'MEDIUM',
        Status__c = 'IN_PROGRESS',
        Detected_Date__c = now.addDays(-5),
        Gap_Description__c = dataTag + ' Review privileged access assignments',
        Remediation_Plan__c = 'Initiate quarterly access review',
        Remediation_Owner__c = currentUser.Id,
        Target_Remediation_Date__c = today.addDays(14),
        Risk_Score__c = 6.1,
        Entity_Type__c = 'USER',
        Entity_Id__c = currentUser.Id,
        Notes__c = 'Created for validation',
        Jira_Issue_Key__c = 'ELARO-TEST-002'
    ),
    new Compliance_Gap__c(
        Framework__c = 'GDPR',
        Policy_Reference__c = 'GDPR_Data_Minimization',
        Severity__c = 'LOW',
        Status__c = 'ACCEPTED_RISK',
        Detected_Date__c = now.addDays(-12),
        Gap_Description__c = dataTag + ' Excessive data exposure on Contact',
        Remediation_Plan__c = 'Document business justification for access',
        Remediation_Owner__c = currentUser.Id,
        Target_Remediation_Date__c = today.addDays(45),
        Risk_Score__c = 3.5,
        Entity_Type__c = 'FIELD_SECURITY',
        Entity_Id__c = gapEntityId,
        Notes__c = 'Created for validation',
        Jira_Issue_Key__c = 'ELARO-TEST-003'
    ),
    new Compliance_Gap__c(
        Framework__c = 'PCI_DSS',
        Policy_Reference__c = 'PCI_DSS_Data_Encryption',
        Severity__c = 'CRITICAL',
        Status__c = 'OPEN',
        Detected_Date__c = now.addDays(-3),
        Gap_Description__c = dataTag + ' Encryption not enabled for card data',
        Remediation_Plan__c = 'Enable Shield Platform Encryption for cardholder data',
        Remediation_Owner__c = currentUser.Id,
        Target_Remediation_Date__c = today.addDays(7),
        Risk_Score__c = 9.6,
        Entity_Type__c = 'CUSTOM_OBJECT',
        Entity_Id__c = gapEntityId,
        Notes__c = 'Created for validation',
        Jira_Issue_Key__c = 'ELARO-TEST-004'
    ),
    new Compliance_Gap__c(
        Framework__c = 'SOX',
        Policy_Reference__c = 'SOX_Change_Management',
        Severity__c = 'MEDIUM',
        Status__c = 'REMEDIATED',
        Detected_Date__c = now.addDays(-20),
        Gap_Description__c = dataTag + ' Untracked metadata change',
        Remediation_Plan__c = 'Require change approval workflow',
        Remediation_Owner__c = currentUser.Id,
        Actual_Remediation_Date__c = today.addDays(-2),
        Risk_Score__c = 5.0,
        Entity_Type__c = 'METADATA_CHANGE',
        Entity_Id__c = gapEntityId,
        Notes__c = 'Created for validation',
        Jira_Issue_Key__c = 'ELARO-TEST-005'
    )
};

List<Database.SaveResult> gapResults = Database.insert(gaps, false);
Integer gapCreated = 0;
Integer gapFailed = 0;
for (Database.SaveResult sr : gapResults) {
    if (sr.isSuccess()) {
        gapCreated++;
    } else {
        gapFailed++;
    }
}
System.debug('Compliance gaps created: ' + gapCreated + ', failed: ' + gapFailed);

// Compliance evidence
List<Compliance_Evidence__c> evidence = new List<Compliance_Evidence__c>{
    new Compliance_Evidence__c(
        Framework__c = 'HIPAA',
        Evidence_Type__c = 'SETUP_AUDIT_TRAIL',
        Evidence_Date__c = today.addDays(-10),
        Status__c = 'COLLECTED',
        Description__c = dataTag + ' Setup audit trail evidence sample',
        Evidence_Data__c = '{"source":"SetupAuditTrail","entries":5,"tag":"Validation"}',
        Policy_Reference__c = 'HIPAA_164_312_b_Audit',
        Compliance_Score__c = 82.5
    ),
    new Compliance_Evidence__c(
        Framework__c = 'SOC2',
        Evidence_Type__c = 'PERMISSION_SET',
        Evidence_Date__c = today.addDays(-8),
        Status__c = 'REVIEWED',
        Description__c = dataTag + ' Permission set export for access review',
        Evidence_Data__c = '{"source":"PermissionSet","count":3,"tag":"Validation"}',
        Policy_Reference__c = 'SOC2_CC6_1_Access_Control',
        Compliance_Score__c = 90.1,
        Reviewed_By__c = currentUser.Id,
        Reviewed_Date__c = now.addDays(-7)
    ),
    new Compliance_Evidence__c(
        Framework__c = 'GDPR',
        Evidence_Type__c = 'FIELD_HISTORY',
        Evidence_Date__c = today.addDays(-6),
        Status__c = 'APPROVED',
        Description__c = dataTag + ' Field history tracking coverage',
        Evidence_Data__c = '{"source":"FieldDefinition","tracked":12,"tag":"Validation"}',
        Policy_Reference__c = 'GDPR_Data_Minimization',
        Compliance_Score__c = 78.2,
        Reviewed_By__c = currentUser.Id,
        Reviewed_Date__c = now.addDays(-5)
    ),
    new Compliance_Evidence__c(
        Framework__c = 'PCI_DSS',
        Evidence_Type__c = 'API_USAGE',
        Evidence_Date__c = today.addDays(-4),
        Status__c = 'COLLECTED',
        Description__c = dataTag + ' API usage snapshot evidence',
        Evidence_Data__c = '{"source":"API_Usage_Snapshot","tag":"Validation"}',
        Policy_Reference__c = 'PCI_DSS_Data_Encryption',
        Compliance_Score__c = 88.0
    ),
    new Compliance_Evidence__c(
        Framework__c = 'SOX',
        Evidence_Type__c = 'METADATA_CHANGE',
        Evidence_Date__c = today.addDays(-3),
        Status__c = 'REJECTED',
        Description__c = dataTag + ' Metadata change without approval',
        Evidence_Data__c = '{"source":"Metadata_Change","tag":"Validation"}',
        Policy_Reference__c = 'SOX_Change_Management',
        Compliance_Score__c = 65.0,
        Reviewed_By__c = currentUser.Id,
        Reviewed_Date__c = now.addDays(-2)
    )
};

List<Database.SaveResult> evidenceResults = Database.insert(evidence, false);
Integer evidenceCreated = 0;
Integer evidenceFailed = 0;
for (Database.SaveResult sr : evidenceResults) {
    if (sr.isSuccess()) {
        evidenceCreated++;
    } else {
        evidenceFailed++;
    }
}
System.debug('Compliance evidence created: ' + evidenceCreated + ', failed: ' + evidenceFailed);

// Audit package evidence items
List<Elaro_Evidence_Item__c> evidenceItems = new List<Elaro_Evidence_Item__c>();
Elaro_Evidence_Item__c item1 = new Elaro_Evidence_Item__c(
    Audit_Package__c = auditPackage.Id,
    Evidence_Type__c = 'SETUP_AUDIT_TRAIL',
    Evidence_Date__c = today.addDays(-9),
    Status__c = 'COLLECTED',
    Description__c = dataTag + ' audit package evidence item',
    Evidence_Data__c = '{"source":"SetupAuditTrail","tag":"Validation"}'
);
if (frameworkMapping != null) {
    item1.Framework_Mapping__c = frameworkMapping.Id;
}
evidenceItems.add(item1);

evidenceItems.add(new Elaro_Evidence_Item__c(
    Audit_Package__c = auditPackage.Id,
    Evidence_Type__c = 'LOGIN_HISTORY',
    Evidence_Date__c = today.addDays(-7),
    Status__c = 'REVIEWED',
    Description__c = dataTag + ' login history evidence item',
    Evidence_Data__c = '{"source":"LoginHistory","tag":"Validation"}',
    Reviewed_By__c = currentUser.Id,
    Reviewed_Date__c = now.addDays(-6)
));

List<Database.SaveResult> evidenceItemResults = Database.insert(evidenceItems, false);
Integer evidenceItemCreated = 0;
Integer evidenceItemFailed = 0;
for (Database.SaveResult sr : evidenceItemResults) {
    if (sr.isSuccess()) {
        evidenceItemCreated++;
    } else {
        evidenceItemFailed++;
    }
}
System.debug('Audit package evidence items created: ' + evidenceItemCreated + ', failed: ' + evidenceItemFailed);

// Vendor compliance records (avoid duplicates for unique Vendor_Name__c)
List<String> vendorNames = new List<String>{
    'Acme Cloud Storage',
    'Redwood Analytics',
    'Beacon Payments'
};
Set<String> existingVendors = new Set<String>();
for (Vendor_Compliance__c vc : [
    SELECT Id, Vendor_Name__c
    FROM Vendor_Compliance__c
    WHERE Vendor_Name__c IN :vendorNames
]) {
    existingVendors.add(vc.Vendor_Name__c);
}

List<Vendor_Compliance__c> vendors = new List<Vendor_Compliance__c>();
if (!existingVendors.contains('Acme Cloud Storage')) {
    vendors.add(new Vendor_Compliance__c(
        Name = 'Acme Cloud Storage',
        Vendor_Name__c = 'Acme Cloud Storage',
        Vendor_Type__c = 'CLOUD_SERVICE',
        Status__c = 'ACTIVE',
        Compliance_Frameworks__c = 'SOC2;ISO27001',
        Risk_Score__c = 4.5,
        Last_Assessment_Date__c = today.addDays(-45),
        Next_Assessment_Date__c = today.addDays(320),
        Assessment_Notes__c = dataTag + ' annual review completed',
        Owner__c = currentUser.Id
    ));
}
if (!existingVendors.contains('Redwood Analytics')) {
    vendors.add(new Vendor_Compliance__c(
        Name = 'Redwood Analytics',
        Vendor_Name__c = 'Redwood Analytics',
        Vendor_Type__c = 'DATA_PROCESSOR',
        Status__c = 'UNDER_REVIEW',
        Compliance_Frameworks__c = 'GDPR;CCPA',
        Risk_Score__c = 6.7,
        Last_Assessment_Date__c = today.addDays(-20),
        Next_Assessment_Date__c = today.addDays(180),
        Assessment_Notes__c = dataTag + ' pending DPIA validation',
        Owner__c = currentUser.Id
    ));
}
if (!existingVendors.contains('Beacon Payments')) {
    vendors.add(new Vendor_Compliance__c(
        Name = 'Beacon Payments',
        Vendor_Name__c = 'Beacon Payments',
        Vendor_Type__c = 'INTEGRATION',
        Status__c = 'ACTIVE',
        Compliance_Frameworks__c = 'PCI_DSS',
        Risk_Score__c = 3.2,
        Last_Assessment_Date__c = today.addDays(-60),
        Next_Assessment_Date__c = today.addDays(300),
        Assessment_Notes__c = dataTag + ' PCI attestation on file',
        Owner__c = currentUser.Id
    ));
}

if (!vendors.isEmpty()) {
    List<Database.SaveResult> vendorResults = Database.insert(vendors, false);
    Integer vendorCreated = 0;
    Integer vendorFailed = 0;
    for (Database.SaveResult sr : vendorResults) {
        if (sr.isSuccess()) {
            vendorCreated++;
        } else {
            vendorFailed++;
        }
    }
    System.debug('Vendor compliance records created: ' + vendorCreated + ', failed: ' + vendorFailed);
}

// Integration errors
List<Integration_Error__c> integrationErrors = new List<Integration_Error__c>{
    new Integration_Error__c(
        Error_Type__c = 'SLACK',
        Timestamp__c = now.addMinutes(-45),
        Error_Message__c = dataTag + ' Slack webhook returned 429',
        Retry_Count__c = 1,
        Status__c = 'RETRYING',
        Correlation_Id__c = 'TEST-SLACK-001',
        Context__c = 'channel=#compliance-alerts'
    ),
    new Integration_Error__c(
        Error_Type__c = 'API_CALLOUT',
        Timestamp__c = now.addMinutes(-90),
        Error_Message__c = dataTag + ' Limits API timeout',
        Retry_Count__c = 0,
        Status__c = 'NEW',
        Correlation_Id__c = 'TEST-API-001',
        Context__c = 'endpoint=SF_Limits'
    )
};
Database.insert(integrationErrors, false);

// Metadata changes
List<Metadata_Change__c> metadataChanges = new List<Metadata_Change__c>{
    new Metadata_Change__c(
        Change_Type__c = 'UPDATE',
        Metadata_Type__c = 'PermissionSet',
        Metadata_Name__c = 'Elaro_Admin',
        Change_Date__c = now.addDays(-2),
        Risk_Level__c = 'HIGH',
        Change_Details__c = '{"field":"PermissionsModifyAllData","old":false,"new":true,"tag":"Validation"}',
        Impact_Analysis__c = dataTag + ' elevated access risk',
        Compliance_Impact__c = 'SOC2 CC6.1 potential violation',
        Rollback_Available__c = true,
        Changed_By__c = currentUser.Id
    ),
    new Metadata_Change__c(
        Change_Type__c = 'CREATE',
        Metadata_Type__c = 'CustomObject',
        Metadata_Name__c = 'Compliance_Gap__c',
        Change_Date__c = now.addDays(-15),
        Risk_Level__c = 'MEDIUM',
        Change_Details__c = '{"object":"Compliance_Gap__c","tag":"Validation"}',
        Impact_Analysis__c = dataTag + ' new object introduced',
        Compliance_Impact__c = 'SOX change management review required',
        Rollback_Available__c = false,
        Changed_By__c = currentUser.Id
    )
};
Database.insert(metadataChanges, false);

// GDPR / CCPA / GLBA / ISO framework records
List<GDPR_Erasure_Request__c> erasureRequests = new List<GDPR_Erasure_Request__c>{
    new GDPR_Erasure_Request__c(
        Contact_Email__c = testContact.Email,
        Contact_Id__c = String.valueOf(testContact.Id),
        Request_Date__c = now.addDays(-14),
        Status__c = 'Pending',
        Request_Reason__c = dataTag + ' GDPR erase request',
        Requested_By__c = currentUser.Id
    ),
    new GDPR_Erasure_Request__c(
        Contact_Email__c = testContact.Email,
        Contact_Id__c = String.valueOf(testContact.Id),
        Request_Date__c = now.addDays(-30),
        Status__c = 'Completed',
        Request_Reason__c = dataTag + ' GDPR erase request completed',
        Requested_By__c = currentUser.Id,
        Completion_Date__c = now.addDays(-25)
    )
};
Database.insert(erasureRequests, false);

List<CCPA_Request__c> ccpaRequests = new List<CCPA_Request__c>{
    new CCPA_Request__c(
        Contact__c = testContact.Id,
        Request_Type__c = 'Right to Know',
        Request_Date__c = now.addDays(-20),
        Status__c = 'Completed',
        Response_Date__c = now.addDays(-10)
    ),
    new CCPA_Request__c(
        Contact__c = testContact.Id,
        Request_Type__c = 'Do Not Sell',
        Request_Date__c = now.addDays(-5),
        Status__c = 'In Progress'
    )
};
Database.insert(ccpaRequests, false);

List<Privacy_Notice__c> privacyNotices = new List<Privacy_Notice__c>{
    new Privacy_Notice__c(
        Contact__c = testContact.Id,
        Account__c = testAccount.Id,
        Notice_Type__c = 'Initial',
        Sent_Date__c = now.addDays(-60),
        Delivery_Method__c = 'Email',
        Delivery_Status__c = 'Delivered'
    ),
    new Privacy_Notice__c(
        Contact__c = testContact.Id,
        Account__c = testAccount.Id,
        Notice_Type__c = 'Annual',
        Sent_Date__c = now.addDays(-5),
        Delivery_Method__c = 'Email',
        Delivery_Status__c = 'Pending'
    )
};
Database.insert(privacyNotices, false);

List<Consent__c> consents = new List<Consent__c>{
    new Consent__c(
        Contact__c = testContact.Id,
        Consent_Type__c = 'Marketing Communications',
        Consent_Version__c = 'v2026.1',
        Consent_Date__c = now.addDays(-120),
        Consent_Given__c = true
    ),
    new Consent__c(
        Contact__c = testContact.Id,
        Consent_Type__c = 'Data Processing',
        Consent_Version__c = 'v2026.1',
        Consent_Date__c = now.addDays(-10),
        Consent_Given__c = true
    )
};
Database.insert(consents, false);

List<Access_Review__c> accessReviews = new List<Access_Review__c>{
    new Access_Review__c(
        User__c = currentUser.Id,
        Reviewer__c = currentUser.Id,
        Review_Type__c = 'Quarterly Review',
        Review_Status__c = 'Pending',
        Status__c = 'PENDING',
        Due_Date__c = today.addDays(14),
        Profiles_Reviewed__c = 'System Administrator',
        Permission_Sets_Reviewed__c = 'Elaro_Admin',
        Risk_Level__c = 'High'
    ),
    new Access_Review__c(
        User__c = currentUser.Id,
        Reviewer__c = currentUser.Id,
        Review_Type__c = 'Privileged Access Review',
        Review_Status__c = 'In Progress',
        Status__c = 'IN_PROGRESS',
        Due_Date__c = today.addDays(7),
        Profiles_Reviewed__c = 'System Administrator',
        Permission_Sets_Reviewed__c = 'Elaro_Admin',
        Risk_Level__c = 'Critical'
    )
};
Database.insert(accessReviews, false);

// Monitoring dashboards (API usage, flow execution, performance alerts)
List<API_Usage_Snapshot__c> apiSnapshots = new List<API_Usage_Snapshot__c>{
    new API_Usage_Snapshot__c(
        Taken_On__c = now.addHours(-6),
        Daily_Used__c = 1200,
        Daily_Limit__c = 15000,
        Percent_Used__c = 8.0,
        Projected_Exhaustion__c = now.addDays(5)
    ),
    new API_Usage_Snapshot__c(
        Taken_On__c = now.addHours(-1),
        Daily_Used__c = 6400,
        Daily_Limit__c = 15000,
        Percent_Used__c = 42.7,
        Projected_Exhaustion__c = now.addDays(2)
    )
};
Database.insert(apiSnapshots, false);

List<Flow_Execution__c> flowExecutions = new List<Flow_Execution__c>{
    new Flow_Execution__c(
        Flow_Name__c = 'Contact_Onboarding',
        Primary_Record__c = testAccount.Id,
        Status__c = 'Success',
        CPU__c = 1200,
        SOQL__c = 14,
        DML__c = 5,
        Run_Time__c = now.addDays(-1)
    ),
    new Flow_Execution__c(
        Flow_Name__c = 'Opportunity_Compliance_Check',
        Primary_Record__c = testAccount.Id,
        Status__c = 'Fault',
        CPU__c = 3400,
        SOQL__c = 48,
        DML__c = 18,
        Run_Time__c = now.addHours(-6)
    )
};
Database.insert(flowExecutions, false);

List<Performance_Alert_History__c> performanceAlerts = new List<Performance_Alert_History__c>{
    new Performance_Alert_History__c(
        Metric__c = 'CPU',
        Value__c = 9200,
        Threshold__c = 9000,
        Context_Record__c = String.valueOf(currentUser.Id),
        Stack__c = dataTag + ' CPU threshold exceeded'
    ),
    new Performance_Alert_History__c(
        Metric__c = 'HEAP',
        Value__c = 5200,
        Threshold__c = 5000,
        Context_Record__c = String.valueOf(currentUser.Id),
        Stack__c = dataTag + ' Heap threshold exceeded'
    ),
    new Performance_Alert_History__c(
        Metric__c = 'SOQL',
        Value__c = 95,
        Threshold__c = 90,
        Context_Record__c = String.valueOf(currentUser.Id),
        Stack__c = dataTag + ' SOQL threshold exceeded'
    )
};
Database.insert(performanceAlerts, false);

// Audit log entry
List<Elaro_Audit_Log__c> auditLogs = new List<Elaro_Audit_Log__c>{
    new Elaro_Audit_Log__c(
        Action__c = 'Validation Test Data',
        Timestamp__c = now,
        Details__c = dataTag + ' created via create-test-data.apex',
        Entity_Type__c = 'SCRIPT',
        Entity_Id__c = 'create-test-data',
        User__c = currentUser.Id
    )
};
Database.insert(auditLogs, false);

// Verify SetupAuditTrail has data (read-only, but we can check)
Integer auditTrailCount = [
    SELECT COUNT()
    FROM SetupAuditTrail
    WHERE CreatedDate >= LAST_N_DAYS:30
];

System.debug('SetupAuditTrail entries (last 30 days): ' + auditTrailCount);
if (auditTrailCount == 0) {
    System.debug('Warning: No SetupAuditTrail entries found in last 30 days');
    System.debug('The compliance scorer will still work, but may show lower scores');
    System.debug('Make some configuration changes to generate audit trail data');
}

// Check for Field History tracking
Integer objectsWithHistory = [
    SELECT COUNT()
    FROM FieldDefinition
    WHERE IsFieldHistoryTracked = true
    LIMIT 1
];

System.debug('Objects with Field History Tracking: ' + (objectsWithHistory > 0 ? 'Yes' : 'No'));
if (objectsWithHistory == 0) {
    System.debug('Warning: No objects have Field History Tracking enabled');
    System.debug('Enable Field History on compliance-sensitive objects for better scoring');
}

System.debug('Test data setup complete.');
System.debug('Next steps:');
System.debug('1. Navigate to Elaro Compliance Hub dashboard');
System.debug('2. Verify readiness score and framework scores display');
System.debug('3. Review gaps, evidence, and audit package data');
System.debug('4. Check monitoring dashboards for API/flow/performance history');
