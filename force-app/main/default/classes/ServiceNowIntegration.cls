/**
 * @description ServiceNow integration service for Elaro
 * Provides control sync, evidence push, and incident creation
 * @group Integrations
 * @author Elaro Team
 */
public with sharing class ServiceNowIntegration {
    
    private static final String NAMED_CREDENTIAL = 'callout:ServiceNow_API';
    
    /**
     * @description Sync controls from Elaro to ServiceNow GRC
     * @param frameworkName Framework name (HIPAA, SOC2, etc.)
     */
    @future(callout=true)
    public static void syncControls(String frameworkName) {
        // Get controls based on framework
        List<Map<String, Object>> controls = getControlsForFramework(frameworkName);
        
        for (Map<String, Object> control : controls) {
            syncSingleControl(control);
        }
    }
    
    /**
     * @description Push evidence to ServiceNow
     * @param evidenceId Evidence item ID
     */
    @future(callout=true)
    public static void pushEvidence(String evidenceId) {
        Elaro_Evidence_Item__c evidence = [
            SELECT Id, Name, Evidence_Type__c, Description__c, Evidence_Date__c, Status__c
            FROM Elaro_Evidence_Item__c
            WHERE Id = :evidenceId
            LIMIT 1
        ];
        
        Map<String, Object> snowEvidence = new Map<String, Object>{
            'u_external_id' => evidence.Id,
            'u_evidence_type' => evidence.Evidence_Type__c,
            'short_description' => evidence.Name,
            'description' => evidence.Description__c,
            'u_evidence_date' => evidence.Evidence_Date__c,
            'u_status' => evidence.Status__c,
            'u_source' => 'Elaro'
        };
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(NAMED_CREDENTIAL + '/api/now/table/u_compliance_evidence');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        req.setBody(JSON.serialize(snowEvidence));
        req.setTimeout(60000);
        
        try {
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 201) {
                System.debug(LoggingLevel.INFO, 'Evidence pushed to ServiceNow: ' + evidenceId);
            } else {
                System.debug(LoggingLevel.ERROR, 'ServiceNow push failed: ' + res.getBody());
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'ServiceNow integration error: ' + e.getMessage());
        }
    }
    
    /**
     * @description Create incident in ServiceNow
     * @param incidentData Incident details
     * @return ServiceNow incident sys_id
     */
    @AuraEnabled
    public static String createIncident(Map<String, Object> incidentData) {
        Map<String, Object> snowIncident = new Map<String, Object>{
            'short_description' => incidentData.get('title'),
            'description' => incidentData.get('description'),
            'urgency' => mapUrgency((String)incidentData.get('severity')),
            'impact' => mapImpact((String)incidentData.get('severity')),
            'category' => 'Security',
            'subcategory' => 'Compliance',
            'u_compliance_alert_id' => incidentData.get('alertId'),
            'u_source' => 'Elaro'
        };
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(NAMED_CREDENTIAL + '/api/now/table/incident');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        req.setBody(JSON.serialize(snowIncident));
        req.setTimeout(60000);
        
        try {
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 201) {
                Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
                Map<String, Object> result = (Map<String, Object>)response.get('result');
                return (String)result.get('sys_id');
            } else {
                throw new AuraHandledException('ServiceNow incident creation failed: ' + res.getBody());
            }
        } catch (CalloutException e) {
            throw new AuraHandledException('ServiceNow connection failed: ' + e.getMessage());
        }
    }
    
    /**
     * @description Get incident status from ServiceNow
     * @param incidentSysId ServiceNow incident sys_id
     * @return Incident status
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getIncidentStatus(String incidentSysId) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(NAMED_CREDENTIAL + '/api/now/table/incident/' + incidentSysId);
        req.setMethod('GET');
        req.setHeader('Accept', 'application/json');
        req.setTimeout(30000);
        
        try {
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
                return (Map<String, Object>)response.get('result');
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'ServiceNow query error: ' + e.getMessage());
        }
        
        return new Map<String, Object>();
    }
    
    /**
     * @description Sync compliance status to ServiceNow
     * @param auditPackageId Audit package ID
     */
    @future(callout=true)
    public static void syncComplianceStatus(String auditPackageId) {
        Elaro_Audit_Package__c pkg = [
            SELECT Id, Name, Package_Name__c, Framework__c, Status__c
            FROM Elaro_Audit_Package__c
            WHERE Id = :auditPackageId
            LIMIT 1
        ];
        
        // Calculate compliance score
        Map<String, Object> scoreData = ElaroComplianceScorer.calculateComplianceScore();
        Decimal score = (Decimal)scoreData.get('overallScore');
        
        Map<String, Object> complianceStatus = new Map<String, Object>{
            'u_framework' => pkg.Framework__c,
            'u_audit_package_id' => pkg.Id,
            'u_package_name' => pkg.Package_Name__c,
            'u_compliance_score' => score,
            'u_status' => pkg.Status__c,
            'u_last_sync' => Datetime.now()
        };
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(NAMED_CREDENTIAL + '/api/now/table/u_compliance_status');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        req.setBody(JSON.serialize(complianceStatus));
        
        try {
            Http http = new Http();
            http.send(req);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'ServiceNow sync error: ' + e.getMessage());
        }
    }
    
    private static List<Map<String, Object>> getControlsForFramework(String framework) {
        List<Map<String, Object>> controls = new List<Map<String, Object>>();
        
        // Get controls from framework module
        IComplianceModule module = getModuleForFramework(framework);
        if (module != null) {
            for (IComplianceModule.Control ctrl : module.getControls()) {
                controls.add(new Map<String, Object>{
                    'code' => ctrl.code,
                    'name' => ctrl.name,
                    'description' => ctrl.description,
                    'severity' => ctrl.severity,
                    'framework' => framework
                });
            }
        }
        
        return controls;
    }
    
    private static void syncSingleControl(Map<String, Object> control) {
        Map<String, Object> snowControl = new Map<String, Object>{
            'u_control_id' => control.get('code'),
            'name' => control.get('name'),
            'description' => control.get('description'),
            'u_severity' => control.get('severity'),
            'u_framework' => control.get('framework'),
            'u_source' => 'Elaro'
        };
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(NAMED_CREDENTIAL + '/api/now/table/u_compliance_control');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(snowControl));
        
        try {
            Http http = new Http();
            http.send(req);
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Control sync failed: ' + e.getMessage());
        }
    }
    
    private static IComplianceModule getModuleForFramework(String framework) {
        switch on framework {
            when 'HIPAA' { return new HIPAAModule(); }
            when 'SOC2' { return new SOC2Module(); }
            when 'GDPR' { return new GDPRModule(); }
            when 'FINRA' { return new FINRAModule(); }
            when else { return null; }
        }
    }
    
    private static String mapUrgency(String severity) {
        Map<String, String> urgencyMap = new Map<String, String>{
            'CRITICAL' => '1',
            'HIGH' => '2',
            'MEDIUM' => '3',
            'LOW' => '4'
        };
        return urgencyMap.containsKey(severity) ? urgencyMap.get(severity) : '3';
    }
    
    private static String mapImpact(String severity) {
        Map<String, String> impactMap = new Map<String, String>{
            'CRITICAL' => '1',
            'HIGH' => '2',
            'MEDIUM' => '2',
            'LOW' => '3'
        };
        return impactMap.containsKey(severity) ? impactMap.get(severity) : '2';
    }
}
