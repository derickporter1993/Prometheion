/**
 * AnomalyDetectionService
 * 
 * Pattern detection for compliance anomalies
 * 
 * @author Elaro
 * @version 1.0
 * @since v3.1.0 (Spring '26)
 * @group Security
 */
public with sharing class AnomalyDetectionService {
    
    /**
     * Detects anomalies in compliance data including unusual permissions, metadata changes, and access patterns.
     *
     * @param framework Framework to analyze
     * @param daysBack Number of days to look back
     * @return List of detected anomalies
     * @throws IllegalArgumentException if framework is blank
     */
    @AuraEnabled
    public static List<Anomaly> detectAnomalies(String framework, Integer daysBack) {
        try {
            if (String.isBlank(framework)) {
                throw new IllegalArgumentException('Framework is required');
            }
            if (daysBack == null || daysBack < 1) {
                daysBack = 30; // Default to 30 days
            }

            List<Anomaly> anomalies = new List<Anomaly>();
            Datetime startDate = System.now().addDays(-daysBack);

            // Detect unusual permission set assignments
            anomalies.addAll(detectUnusualPermissionAssignments(startDate));

            // Detect unusual metadata changes
            anomalies.addAll(detectUnusualMetadataChanges(startDate));

            // Detect unusual access patterns
            anomalies.addAll(detectUnusualAccessPatterns(startDate));

            return anomalies;
        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception e) {
            ElaroLogger.error('AnomalyDetectionService.detectAnomalies', e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException('Unable to complete the operation. Please verify you have the required permissions and try again.');
        }
    }
    
    /**
     * Detect unusual permission set assignments
     */
    private static List<Anomaly> detectUnusualPermissionAssignments(Datetime startDate) {
        List<Anomaly> anomalies = new List<Anomaly>();
        
        // Find users with excessive permission sets (more than 10)
        // Note: PermissionSetAssignment doesn't have CreatedDate, using SystemModstamp instead
        List<AggregateResult> excessiveAssignments = [
            SELECT AssigneeId, COUNT(Id) assignmentCount
            FROM PermissionSetAssignment
            WHERE SystemModstamp >= :startDate
            WITH USER_MODE
            GROUP BY AssigneeId
            HAVING COUNT(Id) > 10
        ];
        
        for (AggregateResult ar : excessiveAssignments) {
            Anomaly anomaly = new Anomaly();
            anomaly.type = 'EXCESSIVE_PERMISSIONS';
            anomaly.severity = 'HIGH';
            anomaly.description = 'User has ' + ar.get('assignmentCount') + ' permission set assignments';
            anomaly.entityId = (String)ar.get('AssigneeId');
            anomalies.add(anomaly);
        }
        
        return anomalies;
    }
    
    /**
     * Detect unusual metadata changes
     */
    private static List<Anomaly> detectUnusualMetadataChanges(Datetime startDate) {
        List<Anomaly> anomalies = new List<Anomaly>();
        
        // Find high-risk metadata changes
        List<Metadata_Change__c> highRiskChanges = [
            SELECT Id, Metadata_Type__c, Metadata_Name__c, Change_Type__c, Risk_Level__c
            FROM Metadata_Change__c
            WHERE Change_Date__c >= :startDate
            AND Risk_Level__c = 'CRITICAL'
            WITH USER_MODE
        ];
        
        for (Metadata_Change__c change : highRiskChanges) {
            Anomaly anomaly = new Anomaly();
            anomaly.type = 'HIGH_RISK_CHANGE';
            anomaly.severity = 'CRITICAL';
            anomaly.description = change.Change_Type__c + ' of ' + change.Metadata_Type__c + ': ' + change.Metadata_Name__c;
            anomaly.entityId = change.Id;
            anomalies.add(anomaly);
        }
        
        return anomalies;
    }
    
    /**
     * Detect unusual access patterns
     */
    private static List<Anomaly> detectUnusualAccessPatterns(Datetime startDate) {
        List<Anomaly> anomalies = new List<Anomaly>();
        
        // Simplified - in production, analyze login patterns, API usage, etc.
        // For now, return empty list
        
        return anomalies;
    }
    
    /**
     * Anomaly
     */
    public class Anomaly {
        @AuraEnabled public String type;
        @AuraEnabled public String severity;
        @AuraEnabled public String description;
        @AuraEnabled public String entityId;
        @AuraEnabled public Datetime detectedDate = System.now();
    }
}
