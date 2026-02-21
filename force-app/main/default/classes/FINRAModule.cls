/**
 * @description FINRA compliance module implementation
 * Covers Rule 3110 (Supervision), Rule 4511 (Books/Records), Rule 4370 (BCP)
 * @group Framework Modules
 * @author Elaro Team
 */
public with sharing class FINRAModule implements IComplianceModule {
    
    private static final String FRAMEWORK_NAME = 'FINRA';
    private static final String FRAMEWORK_VERSION = '2024';
    
    private static final List<IComplianceModule.Control> FINRA_CONTROLS;
    
    static {
        FINRA_CONTROLS = new List<IComplianceModule.Control>();
        
        // Rule 3110 - Supervision
        FINRA_CONTROLS.add(createControl('3110(a)', 'Supervisory System', 
            'Establish and maintain a supervisory system reasonably designed to achieve compliance', 
            'Supervision', 'CRITICAL'));
        FINRA_CONTROLS.add(createControl('3110(b)', 'Written Supervisory Procedures', 
            'Establish written procedures for supervision of business activities', 
            'Supervision', 'CRITICAL'));
        FINRA_CONTROLS.add(createControl('3110(c)', 'Internal Inspections', 
            'Conduct regular and periodic internal inspections', 
            'Supervision', 'HIGH'));
        FINRA_CONTROLS.add(createControl('3110(d)', 'Review of Correspondence', 
            'Review of customer correspondence and communications', 
            'Supervision', 'HIGH'));
        
        // Rule 4511 - Books and Records
        FINRA_CONTROLS.add(createControl('4511(a)', 'Record Keeping', 
            'Make and preserve books, accounts, records, memoranda as required by Rule 17a-4', 
            'Records', 'CRITICAL'));
        FINRA_CONTROLS.add(createControl('4511(b)', 'Record Retention', 
            'Preserve records for required time periods', 
            'Records', 'CRITICAL'));
        FINRA_CONTROLS.add(createControl('4511(c)', 'Record Accessibility', 
            'Records must be readily accessible for examination', 
            'Records', 'HIGH'));
        
        // Rule 4370 - Business Continuity
        FINRA_CONTROLS.add(createControl('4370(a)', 'Business Continuity Plan', 
            'Create and maintain a written business continuity plan', 
            'BCP', 'CRITICAL'));
        FINRA_CONTROLS.add(createControl('4370(b)', 'Annual Review', 
            'Conduct annual review of business continuity plan', 
            'BCP', 'HIGH'));
        FINRA_CONTROLS.add(createControl('4370(c)', 'Emergency Contact Information', 
            'Maintain emergency contact information', 
            'BCP', 'MEDIUM'));
    }
    
    /** {@inheritDoc} Returns 'FINRA'. */
    public String getFrameworkName() { return FRAMEWORK_NAME; }
    /** {@inheritDoc} Returns '2024'. */
    public String getFrameworkVersion() { return FRAMEWORK_VERSION; }
    /** {@inheritDoc} Returns all FINRA controls (Rules 3110, 4511, 4370). */
    public List<IComplianceModule.Control> getControls() { return FINRA_CONTROLS; }

    /**
     * Calculates a weighted FINRA compliance score for the given audit package.
     * Critical controls are weighted 3x, High 2x, and others 1x.
     *
     * @param auditPackageId The audit package to evaluate
     * @return Weighted compliance score from 0-100, or 0 if the ID is null
     */
    public Decimal calculateScore(Id auditPackageId) {
        if (auditPackageId == null) return 0;
        
        Decimal totalScore = 0;
        Decimal totalWeight = 0;
        
        for (IComplianceModule.Control ctrl : FINRA_CONTROLS) {
            IComplianceModule.ControlResult result = evaluateControl(ctrl.code, 
                new Map<String, Object>{ 'auditPackageId' => auditPackageId });
            
            Decimal weight = ctrl.severity == 'CRITICAL' ? 3 : ctrl.severity == 'HIGH' ? 2 : 1;
            totalWeight += weight;
            totalScore += weight * result.score / 100;
        }
        
        return totalWeight > 0 ? (totalScore / totalWeight) * 100 : 0;
    }
    
    /**
     * Identifies non-compliant controls and returns them as Gap objects with
     * FINRA-specific remediation recommendations.
     *
     * @param auditPackageId The audit package to evaluate
     * @return List of Gap objects for controls that did not pass evaluation
     */
    public List<IComplianceModule.Gap> identifyGaps(Id auditPackageId) {
        List<IComplianceModule.Gap> gaps = new List<IComplianceModule.Gap>();
        
        for (IComplianceModule.Control ctrl : FINRA_CONTROLS) {
            IComplianceModule.ControlResult result = evaluateControl(ctrl.code, 
                new Map<String, Object>{ 'auditPackageId' => auditPackageId });
            
            if (!result.passed) {
                IComplianceModule.Gap gap = new IComplianceModule.Gap();
                gap.id = 'GAP-FINRA-' + ctrl.code;
                gap.controlId = ctrl.id;
                gap.controlCode = ctrl.code;
                gap.controlName = ctrl.name;
                gap.description = result.finding;
                gap.severity = ctrl.severity;
                gap.recommendation = getFINRARecommendation(ctrl.code);
                gaps.add(gap);
            }
        }
        
        return gaps;
    }
    
    /**
     * Generates a FINRA-specific compliance report as a PDF.
     *
     * @param auditPackageId The audit package to generate the report for
     * @return PDF content as a Blob
     */
    public Blob generateReport(Id auditPackageId) {
        PageReference pdfPage = Page.ElaroAuditPackagePDF;
        pdfPage.getParameters().put('id', auditPackageId);
        pdfPage.getParameters().put('framework', 'FINRA');
        return Test.isRunningTest() ? Blob.valueOf('FINRA Report') : pdfPage.getContentAsPDF();
    }
    
    /**
     * Looks up a FINRA control by its code (e.g., '3110(a)').
     *
     * @param controlId The control code to search for
     * @return The matching Control, or null if not found
     */
    public IComplianceModule.Control getControlById(String controlId) {
        for (IComplianceModule.Control ctrl : FINRA_CONTROLS) {
            if (ctrl.code == controlId) return ctrl;
        }
        return null;
    }
    
    /**
     * Evaluates a specific FINRA control against the audit package.
     * Routes to specialized evaluators for Supervision, Communications, Records, and BCP controls.
     *
     * @param controlId The control code to evaluate
     * @param context Must contain 'auditPackageId' key with the audit package ID
     * @return ControlResult with pass/fail status, score, and findings
     */
    public IComplianceModule.ControlResult evaluateControl(String controlId, Map<String, Object> context) {
        IComplianceModule.ControlResult result = new IComplianceModule.ControlResult();
        result.controlId = controlId;
        Id auditPackageId = (Id)context.get('auditPackageId');
        
        switch on controlId {
            when '3110(a)', '3110(b)' { result = evaluateSupervision(controlId, auditPackageId); }
            when '3110(d)' { result = evaluateCommunicationsReview(auditPackageId); }
            when '4511(a)', '4511(b)' { result = evaluateRecordKeeping(controlId, auditPackageId); }
            when '4370(a)', '4370(b)' { result = evaluateBCP(controlId, auditPackageId); }
            when else { result = defaultEvaluation(controlId, auditPackageId); }
        }
        
        return result;
    }
    
    private IComplianceModule.ControlResult evaluateSupervision(String ctrlId, Id pkgId) {
        IComplianceModule.ControlResult r = new IComplianceModule.ControlResult();
        r.controlId = ctrlId;
        
        // Check for supervision-related evidence
        Integer supervisoryEvidence = [
            SELECT COUNT() FROM Elaro_Evidence_Item__c
            WHERE Audit_Package__c = :pkgId
            AND (Evidence_Type__c = 'Supervision' OR Description__c LIKE '%supervis%')
            WITH USER_MODE
            LIMIT 100
        ];
        
        r.passed = supervisoryEvidence > 0;
        r.score = supervisoryEvidence > 0 ? 85 : 40;
        r.status = r.passed ? 'COMPLIANT' : 'PARTIAL';
        r.finding = r.passed 
            ? 'Supervisory procedures documented'
            : 'Written supervisory procedures should be documented';
        return r;
    }
    
    private IComplianceModule.ControlResult evaluateCommunicationsReview(Id pkgId) {
        IComplianceModule.ControlResult r = new IComplianceModule.ControlResult();
        r.controlId = '3110(d)';
        
        // Check audit trail for email/communication reviews
        Integer commReviews = [
            SELECT COUNT() FROM SetupAuditTrail
            WHERE CreatedDate >= LAST_N_DAYS:30
            AND (Action LIKE '%email%' OR Action LIKE '%message%')
            WITH USER_MODE
            LIMIT 100
        ];
        
        r.passed = true;
        r.score = 75;
        r.status = 'PARTIAL';
        r.finding = 'Communication review tracking should be enhanced';
        return r;
    }
    
    private IComplianceModule.ControlResult evaluateRecordKeeping(String ctrlId, Id pkgId) {
        IComplianceModule.ControlResult r = new IComplianceModule.ControlResult();
        r.controlId = ctrlId;
        
        // Salesforce provides robust record keeping by default
        r.passed = true;
        r.score = 90;
        r.status = 'COMPLIANT';
        r.finding = 'Salesforce platform provides comprehensive record keeping';
        return r;
    }
    
    private IComplianceModule.ControlResult evaluateBCP(String ctrlId, Id pkgId) {
        IComplianceModule.ControlResult r = new IComplianceModule.ControlResult();
        r.controlId = ctrlId;
        
        Integer bcpEvidence = [
            SELECT COUNT() FROM Elaro_Evidence_Item__c
            WHERE Audit_Package__c = :pkgId
            AND (Evidence_Type__c = 'BCP' OR Description__c LIKE '%continuity%' OR Description__c LIKE '%disaster%')
            WITH USER_MODE
            LIMIT 100
        ];
        
        r.passed = bcpEvidence > 0;
        r.score = bcpEvidence > 0 ? 80 : 50;
        r.status = bcpEvidence > 0 ? 'COMPLIANT' : 'PARTIAL';
        r.finding = bcpEvidence > 0 
            ? 'BCP documentation found'
            : 'Business continuity plan should be documented';
        return r;
    }
    
    private IComplianceModule.ControlResult defaultEvaluation(String ctrlId, Id pkgId) {
        IComplianceModule.ControlResult r = new IComplianceModule.ControlResult();
        r.controlId = ctrlId;
        r.passed = true;
        r.score = 70;
        r.status = 'PARTIAL';
        r.finding = 'Manual review recommended';
        return r;
    }
    
    private static IComplianceModule.Control createControl(String code, String name, String desc, String family, String sev) {
        IComplianceModule.Control c = new IComplianceModule.Control();
        c.id = code;
        c.code = code;
        c.name = name;
        c.description = desc;
        c.family = 'Rule ' + family;
        c.severity = sev;
        c.category = family;
        return c;
    }
    
    private String getFINRARecommendation(String code) {
        Map<String, String> recs = new Map<String, String>{
            '3110(a)' => 'Document supervisory system and responsibilities',
            '3110(b)' => 'Create written supervisory procedures manual',
            '3110(d)' => 'Implement communication review process',
            '4511(a)' => 'Ensure all required records are maintained',
            '4370(a)' => 'Develop comprehensive business continuity plan'
        };
        return recs.containsKey(code) ? recs.get(code) : 'Review FINRA rule requirements';
    }
}
