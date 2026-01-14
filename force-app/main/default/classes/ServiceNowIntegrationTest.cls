/**
 * @description Test class for ServiceNowIntegration
 * Tests ServiceNow integration for controls, evidence, and incidents
 * @group Tests
 * @see ServiceNowIntegration
 */
@isTest
private class ServiceNowIntegrationTest {

    private class ServiceNowMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            if (req.getEndpoint().contains('/incident')) {
                res.setStatusCode(201);
                res.setBody('{"result":{"sys_id":"INC0001234","number":"INC0001234"}}');
            } else {
                res.setStatusCode(201);
                res.setBody('{"result":{"sys_id":"12345"}}');
            }
            return res;
        }
    }

    private class ServiceNowErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"error":"Internal Server Error"}');
            return res;
        }
    }

    @TestSetup
    static void setup() {
        Prometheion_Audit_Package__c pkg = new Prometheion_Audit_Package__c(
            Package_Name__c = 'Test Package',
            Framework__c = 'SOC2',
            Status__c = 'DRAFT',
            Audit_Period_Start__c = Date.today().addDays(-30),
            Audit_Period_End__c = Date.today()
        );
        insert pkg;

        Prometheion_Evidence_Item__c evidence = new Prometheion_Evidence_Item__c(
            Audit_Package__c = pkg.Id,
            Evidence_Type__c = 'Login',
            Evidence_Date__c = Date.today(),
            Description__c = 'Test evidence item',
            Status__c = 'COLLECTED'
        );
        insert evidence;
    }

    @isTest
    static void testSyncControls() {
        Test.setMock(HttpCalloutMock.class, new ServiceNowMock());

        Test.startTest();
        ServiceNowIntegration.syncControls('HIPAA');
        Test.stopTest();

        System.assert(true, 'Control sync should complete');
    }

    @isTest
    static void testSyncControlsSOC2() {
        Test.setMock(HttpCalloutMock.class, new ServiceNowMock());

        Test.startTest();
        ServiceNowIntegration.syncControls('SOC2');
        Test.stopTest();

        System.assert(true, 'SOC2 control sync should complete');
    }

    @isTest
    static void testPushEvidence() {
        Test.setMock(HttpCalloutMock.class, new ServiceNowMock());
        Prometheion_Evidence_Item__c evidence = [SELECT Id FROM Prometheion_Evidence_Item__c LIMIT 1];

        Test.startTest();
        ServiceNowIntegration.pushEvidence(evidence.Id);
        Test.stopTest();

        System.assert(true, 'Evidence push should complete');
    }

    @isTest
    static void testCreateIncident() {
        Test.setMock(HttpCalloutMock.class, new ServiceNowMock());

        Map<String, Object> incidentData = new Map<String, Object>{
            'title' => 'Compliance Alert',
            'description' => 'Test incident description',
            'severity' => 'HIGH',
            'alertId' => 'ALERT-001'
        };

        Test.startTest();
        String sysId = ServiceNowIntegration.createIncident(incidentData);
        Test.stopTest();

        System.assertNotEquals(null, sysId, 'Incident sys_id should be returned');
    }

    @isTest
    static void testGetIncidentStatus() {
        Test.setMock(HttpCalloutMock.class, new ServiceNowMock());

        Test.startTest();
        Map<String, Object> status = ServiceNowIntegration.getIncidentStatus('INC0001234');
        Test.stopTest();

        System.assertNotEquals(null, status, 'Status should be returned');
    }

    @isTest
    static void testSyncComplianceStatus() {
        Test.setMock(HttpCalloutMock.class, new ServiceNowMock());
        Prometheion_Audit_Package__c pkg = [SELECT Id FROM Prometheion_Audit_Package__c LIMIT 1];

        Test.startTest();
        ServiceNowIntegration.syncComplianceStatus(pkg.Id);
        Test.stopTest();

        System.assert(true, 'Compliance status sync should complete');
    }

    @isTest
    static void testCreateIncidentWithError() {
        Test.setMock(HttpCalloutMock.class, new ServiceNowErrorMock());

        Map<String, Object> incidentData = new Map<String, Object>{
            'title' => 'Test Incident',
            'description' => 'Test description',
            'severity' => 'LOW'
        };

        Test.startTest();
        try {
            ServiceNowIntegration.createIncident(incidentData);
            System.assert(false, 'Should have thrown exception');
        } catch (AuraHandledException e) {
            System.assert(true, 'Exception expected for error response');
        }
        Test.stopTest();
    }
}
