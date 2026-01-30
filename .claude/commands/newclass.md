# Create New Apex Class

Generate a new Apex class following Elaro coding standards and best practices.

## Usage

When creating a new Apex class, gather these details:

1. **Class Name** - Must start with "Elaro" prefix (e.g., ElaroMyFeature)
2. **Purpose** - Brief description of functionality
3. **Type** - Choose one:
   - Controller (LWC backend logic)
   - Service (Business logic layer)
   - Utility (Helper/common functions)
   - Batch (Async batch processing)
   - Scheduler (Scheduled jobs)
   - Trigger Handler (Trigger logic)
   - Test (Test class)

## Template Structure

Every new Apex class should include:

### 1. File Header
```apex
/**
 * @description [Purpose of class]
 * @author [Your Name]
 * @date [YYYY-MM-DD]
 * @group [Feature Group - e.g., Compliance Engine, Permission Intelligence]
 */
```

### 2. Class Declaration with Sharing
```apex
public with sharing class ElaroMyClass {
    // Use 'with sharing' for security enforcement
    // Use 'without sharing' ONLY if justified and documented
```

### 3. Security Checks
Import and use ElaroSecurityUtils:
```apex
    /**
     * @description Query records with security checks
     * @param recordIds List of record IDs to query
     * @return List of records
     * @throws ElaroSecurityException if user lacks permissions
     */
    public static List<MyObject__c> getRecords(List<Id> recordIds) {
        // Check CRUD permissions
        ElaroSecurityUtils.checkReadPermission('MyObject__c');

        // Check FLS for fields
        ElaroSecurityUtils.checkFieldReadPermission('MyObject__c',
            new Set<String>{'Name', 'Status__c', 'ComplianceRule__c'});

        // SOQL with security enforced
        return [
            SELECT Id, Name, Status__c, ComplianceRule__c
            FROM MyObject__c
            WHERE Id IN :recordIds
            WITH SECURITY_ENFORCED
        ];
    }
```

### 4. Error Handling
```apex
    public static void processData(List<MyObject__c> records) {
        try {
            ElaroSecurityUtils.checkUpdatePermission('MyObject__c');

            // Business logic here
            update records;

        } catch (DmlException e) {
            // Log and handle DML errors
            System.debug(LoggingLevel.ERROR, 'DML Error: ' + e.getMessage());
            throw new ElaroException('Failed to update records: ' + e.getMessage());
        }
    }
```

### 5. JSDoc for Public Methods
```apex
    /**
     * @description [Method purpose]
     * @param paramName [Parameter description]
     * @return [Return value description]
     * @throws ExceptionType [When exception is thrown]
     * @example
     * ElaroMyClass.myMethod('example');
     */
```

## File Locations

Place the new class in:
```
force-app/main/default/classes/ElaroMyClass.cls
force-app/main/default/classes/ElaroMyClass.cls-meta.xml
```

## Metadata File
Create accompanying `-meta.xml`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<ApexClass xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>65.0</apiVersion>
    <status>Active</status>
</ApexClass>
```

## Required Test Class

For every new class, create a test class:
```
force-app/main/default/classes/ElaroMyClassTest.cls
```

Test class requirements:
- ✅ Minimum 75% coverage (target 85%+)
- ✅ Test positive scenarios
- ✅ Test negative scenarios (exceptions)
- ✅ Test bulk operations (200+ records)
- ✅ Test security violations (without user permissions)
- ✅ Use Test.startTest()/Test.stopTest() for async
- ✅ Use System.runAs() for permission tests

## Example Test Structure
```apex
@isTest
private class ElaroMyClassTest {

    @TestSetup
    static void setup() {
        // Create test data
    }

    @isTest
    static void testPositiveScenario() {
        Test.startTest();
        // Test normal operation
        Test.stopTest();
        // Assert expected results
    }

    @isTest
    static void testSecurityException() {
        User testUser = createUserWithoutPermissions();
        System.runAs(testUser) {
            Test.startTest();
            try {
                ElaroMyClass.myMethod();
                System.assert(false, 'Expected security exception');
            } catch (ElaroSecurityException e) {
                System.assert(true);
            }
            Test.stopTest();
        }
    }

    @isTest
    static void testBulkOperation() {
        List<MyObject__c> records = new List<MyObject__c>();
        for (Integer i = 0; i < 200; i++) {
            records.add(new MyObject__c(Name = 'Test ' + i));
        }
        insert records;

        Test.startTest();
        ElaroMyClass.processBulk(records);
        Test.stopTest();

        // Assert bulk processing succeeded
    }
}
```

## After Creation

1. **Verify Syntax**
   ```bash
   sf project deploy validate --source-dir force-app/main/default/classes/ElaroMyClass.cls
   ```

2. **Run Tests**
   ```bash
   sf apex run test --tests ElaroMyClassTest --result-format human --code-coverage
   ```

3. **Check Coverage**
   Ensure coverage ≥ 75% for the new class

4. **Deploy**
   ```bash
   sf project deploy start --source-dir force-app/main/default/classes/ElaroMyClass.cls --target-org elaro-dev
   ```

## Common Patterns

### LWC Controller Pattern
```apex
public with sharing class ElaroMyComponentController {
    @AuraEnabled(cacheable=true)
    public static List<MyObject__c> getRecords() {
        ElaroSecurityUtils.checkReadPermission('MyObject__c');
        return [SELECT Id, Name FROM MyObject__c WITH SECURITY_ENFORCED LIMIT 50];
    }

    @AuraEnabled
    public static void updateRecord(Id recordId, String newValue) {
        ElaroSecurityUtils.checkUpdatePermission('MyObject__c');
        MyObject__c record = [SELECT Id FROM MyObject__c WHERE Id = :recordId WITH SECURITY_ENFORCED];
        record.Name = newValue;
        update record;
    }
}
```

### Batch Processing Pattern
```apex
public class ElaroMyBatch implements Database.Batchable<SObject> {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Name FROM MyObject__c
            WHERE Status__c = 'Pending'
            WITH SECURITY_ENFORCED
        ]);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<MyObject__c> recordsToUpdate = (List<MyObject__c>) scope;
        // Process records
        update recordsToUpdate;
    }

    public void finish(Database.BatchableContext bc) {
        // Post-processing
    }
}
```

## Checklist

Before considering the class complete:
- [ ] Class name starts with "Elaro"
- [ ] Uses `with sharing` (unless documented exception)
- [ ] All SOQL includes `WITH SECURITY_ENFORCED`
- [ ] Uses ElaroSecurityUtils for CRUD/FLS
- [ ] JSDoc comments on all public methods
- [ ] Test class created with 75%+ coverage
- [ ] Tests include positive, negative, and bulk scenarios
- [ ] Deployed successfully to dev org
- [ ] No compiler warnings
