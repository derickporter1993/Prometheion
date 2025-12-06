/**
 * AlertHistoryServiceTest - Test class for AlertHistoryService
 * 
 * @author Solentra
 * @version 1.0 (Stub)
 */
@isTest
private class AlertHistoryServiceTest {
    
    @isTest
    static void testRecentReturnsEmptyList() {
        Test.startTest();
        List<AlertHistoryService.AlertRow> rows = AlertHistoryService.recent(10);
        Test.stopTest();
        
        System.assertNotEquals(null, rows, 'Should return a list');
        System.assertEquals(0, rows.size(), 'Stub should return empty list');
    }
    
    @isTest
    static void testAlertRowDefaults() {
        AlertHistoryService.AlertRow row = new AlertHistoryService.AlertRow();
        System.assertEquals(0, row.value, 'Default value should be 0');
        System.assertEquals(0, row.threshold, 'Default threshold should be 0');
    }
}
