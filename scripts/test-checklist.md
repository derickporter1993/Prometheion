# Elaro Manual Testing Checklist

## Pre-Test Setup

### Platform Cache (Required for Rate Limiting)
- [ ] Go to Setup → Platform Cache
- [ ] Create partition named `ElaroRateLimit`
- [ ] Allocate at least 1 MB to Org cache

### Permission Set Assignment
- [ ] Assign `Elaro_Admin` permission set to test user
- [ ] Verify `Integration_Error__c` object is accessible

---

## P1 Security Tests

### 1. Input Validation - FlowExecutionLogger
```
Test Steps:
1. Open Developer Console
2. Execute: FlowExecutionLogger.log('', null, '', 0, 0, 0);
3. Verify: AuraHandledException with "Flow name cannot be blank"

4. Execute: FlowExecutionLogger.log('TestFlow', null, '', 0, 0, 0);
5. Verify: AuraHandledException with "Status cannot be blank"
```
- [ ] Blank flow name throws error
- [ ] Blank status throws error
- [ ] Valid inputs work correctly

### 2. Input Validation - ElaroLegalDocumentGenerator
```
Test Steps:
1. Execute: ElaroLegalDocumentGenerator.generateDocument('InvalidFramework', Date.today());
2. Verify: Error for unsupported framework

3. Execute: ElaroLegalDocumentGenerator.generateDocument('HIPAA', Date.today().addDays(30));
4. Verify: Error for future date
```
- [ ] Invalid framework throws error
- [ ] Future date throws error
- [ ] Valid inputs work correctly

### 3. SOQL Security - WITH USER_MODE
```
Test with limited user:
1. Create user with minimal permissions
2. Run as that user
3. Query AlertHistoryService.getRecentAlerts(10)
4. Verify: Only accessible records returned (no security bypass)
```
- [ ] Queries respect user permissions
- [ ] No unauthorized data exposure

---

## P2 Rate Limiting Tests

### 1. FlowExecutionLogger Rate Limit
```
Test Steps:
1. Execute in loop (101 times):
   for (Integer i = 0; i < 101; i++) {
       FlowExecutionLogger.log('Test', null, 'Success', 0, 0, 0);
   }
2. Verify: 101st call throws "Rate limit exceeded"
3. Wait 60 seconds
4. Verify: Calls work again
```
- [ ] Rate limit triggers at 100 calls
- [ ] Rate limit resets after 60 seconds
- [ ] Graceful degradation if cache unavailable

### 2. ElaroLegalDocumentGenerator Rate Limit
```
Test Steps:
1. Execute in loop (11 times):
   for (Integer i = 0; i < 11; i++) {
       ElaroLegalDocumentGenerator.generateDocument('HIPAA', Date.today());
   }
2. Verify: 11th call throws "Rate limit exceeded"
```
- [ ] Rate limit triggers at 10 calls
- [ ] Rate limit resets after 60 seconds

---

## P3 Method Naming Tests

### 1. LWC API Changes
```
Test Steps:
1. Open Elaro Dashboard
2. Check browser console for errors
3. Verify apiUsageDashboard loads data correctly
4. Verify alertHistoryService methods work
```
- [ ] No JavaScript errors in console
- [ ] Data loads correctly in components
- [ ] Method names match between LWC and Apex

### 2. Constants Usage
```
Test Steps:
1. Check ElaroGraphIndexer.determineDriftCategory():
   - Score >= 8.0 → POLICY_VIOLATION
   - Score >= 5.0 → UNAUTHORIZED
   - Score >= 3.0 → ANOMALY
   - Score < 3.0 → MANUAL_OVERRIDE
```
- [ ] Drift categories calculated correctly
- [ ] Constants match expected values

---

## Frontend Tests

### 1. Loading States
```
Components to check:
- apiUsageDashboard
- systemMonitorDashboard
- All dashboard components
```
- [ ] Spinner shows during data load
- [ ] Spinner disappears after load
- [ ] Error states display correctly

### 2. Accessibility
```
Test with keyboard only:
1. Tab through all interactive elements
2. Verify focus visible
3. Check screen reader announces correctly
```
- [ ] All interactive elements keyboard accessible
- [ ] Decorative icons have aria-hidden="true"
- [ ] Form inputs have proper labels

---

## Error Logging Tests

### 1. Integration_Error__c Records
```
Test Steps:
1. Trigger an error (e.g., Einstein prediction failure)
2. Query: SELECT Id, Error_Type__c, Error_Message__c FROM Integration_Error__c
3. Verify error was logged
```
- [ ] Errors create Integration_Error__c records
- [ ] Error details captured correctly
- [ ] Correlation IDs present

### 2. Audit Logging
```
Test Steps:
1. Generate a legal document
2. Query: SELECT Id, Action__c, User__c FROM Elaro_Audit_Log__c
3. Verify audit record created
```
- [ ] Audit records created for sensitive operations
- [ ] User and timestamp captured

---

## Performance Tests

### 1. Bulk Operations
```
Test Steps:
1. Create 200+ compliance records
2. Run batch operations
3. Verify no governor limit errors
```
- [ ] Bulk operations complete without errors
- [ ] Performance within acceptable limits

---

## Sign-Off

| Test Area | Tester | Date | Pass/Fail |
|-----------|--------|------|-----------|
| P1 Security | | | |
| P2 Rate Limiting | | | |
| P3 Refactoring | | | |
| Frontend | | | |
| Error Logging | | | |
| Performance | | | |

**Overall Status:** [ ] PASS  [ ] FAIL

**Notes:**
