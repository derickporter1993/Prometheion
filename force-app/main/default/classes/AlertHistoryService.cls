/**
 * Manages alert history records for compliance and security event tracking.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group System Monitoring
 */
public with sharing class AlertHistoryService {
    private class AlertRow {
        @AuraEnabled public String metric;
        @AuraEnabled public Decimal value;
        @AuraEnabled public Decimal threshold;
        @AuraEnabled public String contextRecordId;
        @AuraEnabled public Datetime createdDate;
        
        public AlertRow(Performance_Alert_History__c record) {
            this.metric = record.Metric__c;
            this.value = record.Value__c;
            this.threshold = record.Threshold__c;
            this.contextRecordId = record.Context_Record__c;
            this.createdDate = record.CreatedDate;
        }
    }
    
    /**
     * Retrieves the most recent performance alert history records.
     *
     * @param limitSize Maximum number of alert records to return
     * @return List of AlertRow DTOs ordered by most recent first
     * @throws AuraHandledException if user lacks read access to Performance_Alert_History__c
     */
    @AuraEnabled(cacheable=true)
    public static List<AlertRow> getRecentAlerts(Integer limitSize) {
        try {
            // Validate read access
            if (!ElaroSecurityUtils.hasReadAccess('Performance_Alert_History__c')) {
                throw new AuraHandledException('Insufficient access to Performance Alert History');
            }

            // Validate FLS for queried fields
            List<String> queriedFields = new List<String>{
                'Metric__c', 'Value__c', 'Threshold__c', 'Context_Record__c', 'CreatedDate'
            };
            ElaroSecurityUtils.validateFLSAccess('Performance_Alert_History__c', queriedFields, false);

            Integer recordLimit = Math.max(1, limitSize);
            List<AlertRow> out = new List<AlertRow>();
            for (Performance_Alert_History__c r : [
                SELECT Metric__c, Value__c, Threshold__c, Context_Record__c, CreatedDate
                FROM Performance_Alert_History__c
                WITH USER_MODE
                ORDER BY CreatedDate DESC
                LIMIT :recordLimit
            ]) {
                out.add(new AlertRow(r));
            }
            return out;
        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception e) {
            ElaroLogger.error('AlertHistoryService.getRecentAlerts', e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException('Unable to complete the operation. Please verify you have the required permissions and try again.');
        }
    }
}
