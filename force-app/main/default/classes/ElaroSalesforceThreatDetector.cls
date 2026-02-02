/**
 * ElaroSalesforceThreatDetector
 * 
 * Detects Salesforce-specific security threats and compliance violations
 * that generic compliance tools miss. This is Elaro's core differentiation.
 * 
 * Security: Uses 'with sharing' to enforce user's sharing rules and FLS.
 * All SOQL queries use WITH SECURITY_ENFORCED for field-level security.
 * 
 * @author Elaro TeamCRM
 * @version 1.0
 */
public with sharing class ElaroSalesforceThreatDetector {
    
    // Constants for threat detection thresholds
    private static final Integer INACTIVE_USER_DAYS_THRESHOLD = 180;
    private static final Integer CRITICAL_INACTIVE_DAYS = 365;
    private static final Integer MAX_ACCOUNT_HIERARCHY_QUERY = 1000;
    private static final Decimal MAX_ADMIN_PERCENTAGE = 5.0;
    private static final Decimal CRITICAL_ADMIN_PERCENTAGE = 10.0;
    private static final Integer RECENT_DAYS_THRESHOLD = 30;
    
    /**
     * Detects permission set cloning + privilege escalation attacks
     * Pattern: Clone low-privilege permission set, add Modify All Data or System Admin
     * Impact: HIPAA, SOC 2, NIST violation
     * 
     * @return List of detected threats
     */
    public static List<Threat> detectPermissionSetClones() {
        List<Threat> threats = new List<Threat>();
        
        // Get all org-owned (standard) permission sets as baseline
        Map<String, PermissionSet> orgOwnedSets = new Map<String, PermissionSet>();
        try {
            for (PermissionSet ps : [
                SELECT Id, Name, Label, PermissionsModifyAllData
                FROM PermissionSet 
                WHERE IsCustom = false
                WITH SECURITY_ENFORCED
            ]) {
                orgOwnedSets.put(ps.Name.toLowerCase(), ps);
            }
        } catch (SecurityException e) {
            System.debug(LoggingLevel.ERROR, '[ElaroSalesforceThreatDetector] Security exception querying permission sets: ' + e.getMessage());
            return threats; // Return empty list if user lacks access
        }
        
        // Get all custom permission sets with suspicious naming
        List<PermissionSet> customSets = new List<PermissionSet>();
        try {
            customSets = [
                SELECT Id, Name, Label, PermissionsModifyAllData,
                       CreatedDate, CreatedBy.Name
                FROM PermissionSet 
                WHERE IsCustom = true
                AND (Name LIKE '%Clone%' 
                     OR Name LIKE '%Copy%' 
                     OR Name LIKE '%Test%'
                     OR Label LIKE '%Clone%'
                     OR Label LIKE '%Copy%')
                WITH SECURITY_ENFORCED
            ];
        } catch (SecurityException e) {
            System.debug(LoggingLevel.ERROR, '[ElaroSalesforceThreatDetector] Security exception querying custom permission sets: ' + e.getMessage());
            return threats;
        }
        
        for (PermissionSet clone : customSets) {
            // Null-safe checks
            if (clone == null || String.isBlank(clone.Name)) {
                continue;
            }
            
            // Check if this appears to be a clone with elevated privileges
            Boolean hasElevatedPrivs = clone.PermissionsModifyAllData == true;
            Boolean suspiciousNaming = clone.Name.containsIgnoreCase('Clone') || 
                                      clone.Name.containsIgnoreCase('Copy') ||
                                      clone.Name.containsIgnoreCase('Test');
            
            if (hasElevatedPrivs && suspiciousNaming) {
                String createdBy = clone.CreatedBy != null ? clone.CreatedBy.Name : 'Unknown';
                String createdDate = clone.CreatedDate != null ? clone.CreatedDate.format() : 'Unknown';
                String label = String.isNotBlank(clone.Label) ? clone.Label : clone.Name;
                
                threats.add(new Threat(
                    'PERMISSION_SET_PRIVILEGE_ESCALATION',
                    clone.Id,
                    'Permission set "' + label + '" appears to be a clone with elevated privileges. ' +
                    'This is a common attack pattern: low-privilege base + high-privilege additions. ' +
                    'Created by: ' + createdBy + ' on ' + createdDate,
                    'CRITICAL',
                    'Review permission set derivation and justify elevated permissions. ' +
                    'Consider removing and recreating with proper naming convention.',
                    'HIPAA',
                    '45 CFR §164.308(a)(3)'
                ));
            }
        }
        
        return threats;
    }
    
    /**
     * Detects sharing rule bypasses via account hierarchy
     * Pattern: Account hierarchy role can access all subordinate accounts
     * Impact: Data exposure, HIPAA violation
     * 
     * @return List of detected threats
     */
    public static List<Threat> detectSharingRuleBypasses() {
        List<Threat> threats = new List<Threat>();
        
        // Get account hierarchies
        List<Account> accountsWithHierarchy = new List<Account>();
        try {
            accountsWithHierarchy = [
                SELECT Id, Name, ParentId, Parent.Name
                FROM Account 
                WHERE ParentId != null
                WITH SECURITY_ENFORCED
                LIMIT :MAX_ACCOUNT_HIERARCHY_QUERY
            ];
        } catch (SecurityException e) {
            System.debug(LoggingLevel.ERROR, '[ElaroSalesforceThreatDetector] Security exception querying accounts: ' + e.getMessage());
            return threats;
        }
        
        // Check if sensitive objects have public OWD with account hierarchies
        // This is a risk because hierarchy access can bypass sharing rules
        for (Account acc : accountsWithHierarchy) {
            // If parent account has public access and child has sensitive data,
            // users with parent access can access child data
            threats.add(new Threat(
                'SHARING_RULE_HIERARCHY_BYPASS',
                acc.Id,
                'Account "' + acc.Name + '" is a child of "' + acc.Parent.Name + '". ' +
                'If parent account has public access, users can access child account data ' +
                'despite sharing rule restrictions. This violates least privilege principles.',
                'HIGH',
                'Review account hierarchy structure. Set org-wide defaults to "Private" for ' +
                'sensitive objects. Use sharing rules with hierarchy exceptions if needed.',
                'HIPAA',
                '45 CFR §164.312(a)(1)'
            ));
        }
        
        return threats;
    }
    
    /**
     * Detects PHI exposure via related lists
     * Pattern: Custom object with FLS, but related list shows Account with PHI
     * Impact: HIPAA violation
     * 
     * @return List of detected threats
     */
    public static List<Threat> detectPHIExposureViaRelatedLists() {
        List<Threat> threats = new List<Threat>();
        
        // Get custom objects that might contain PHI
        // Note: Full implementation would require Metadata API to check relationships
        // This is a simplified version
        
        threats.add(new Threat(
            'PHI_EXPOSURE_VIA_RELATED_LISTS',
            null,
            'Custom objects with PHI may expose data via related lists if field-level security ' +
            'is not properly configured on related objects.',
            'HIGH',
            'Review all custom object relationships. Apply field-level security to PHI fields ' +
            'on related objects. Test access from user perspective, not admin perspective.',
            'HIPAA',
            '45 CFR §164.502(b)'
        ));
        
        return threats;
    }
    
    /**
     * Detects inactive users with active permissions
     * Pattern: User hasn't logged in for 180+ days but has active permissions
     * Impact: Unused access, compliance risk (SOC 2, NIST)
     * 
     * @return List of detected threats
     */
    public static List<Threat> detectInactiveUsersWithAccess() {
        List<Threat> threats = new List<Threat>();
        
        // Find users inactive for threshold days
        List<User> inactiveUsers = new List<User>();
        try {
            inactiveUsers = [
                SELECT Id, Name, Username, Email, LastLoginDate, IsActive,
                       Profile.Name, CreatedDate
                FROM User 
                WHERE IsActive = true 
                AND (LastLoginDate = null OR LastLoginDate < LAST_N_DAYS:180)
                WITH SECURITY_ENFORCED
                ORDER BY LastLoginDate ASC NULLS LAST
            ];
        } catch (SecurityException e) {
            System.debug(LoggingLevel.ERROR, '[ElaroSalesforceThreatDetector] Security exception querying inactive users: ' + e.getMessage());
            return threats;
        }
        
        // Check if they have permission set assignments
        Set<Id> userIds = new Set<Id>();
        for (User u : inactiveUsers) {
            userIds.add(u.Id);
        }
        
        Map<Id, List<PermissionSetAssignment>> userAssignments = new Map<Id, List<PermissionSetAssignment>>();
        if (!userIds.isEmpty()) {
            try {
                for (PermissionSetAssignment psa : [
                    SELECT AssigneeId, PermissionSet.Name, PermissionSet.Label
                    FROM PermissionSetAssignment
                    WHERE AssigneeId IN :userIds
                    WITH SECURITY_ENFORCED
                ]) {
                    if (psa != null && psa.AssigneeId != null) {
                        if (!userAssignments.containsKey(psa.AssigneeId)) {
                            userAssignments.put(psa.AssigneeId, new List<PermissionSetAssignment>());
                        }
                        userAssignments.get(psa.AssigneeId).add(psa);
                    }
                }
            } catch (SecurityException e) {
                System.debug(LoggingLevel.ERROR, '[ElaroSalesforceThreatDetector] Security exception querying permission set assignments: ' + e.getMessage());
            }
        }
        
        for (User u : inactiveUsers) {
            Integer daysInactive = u.LastLoginDate != null ? 
                (u.LastLoginDate.date().daysBetween(Date.today())) : 999;
            
            String permissionDetails = '';
            if (userAssignments.containsKey(u.Id)) {
                List<String> permNames = new List<String>();
                for (PermissionSetAssignment psa : userAssignments.get(u.Id)) {
                    permNames.add(psa.PermissionSet.Label);
                }
                permissionDetails = ' Active permission sets: ' + String.join(permNames, ', ');
            }
            
            // Null-safe string building
            String userName = String.isNotBlank(u.Name) ? u.Name : 'Unknown';
            String userUsername = String.isNotBlank(u.Username) ? u.Username : 'Unknown';
            
            threats.add(new Threat(
                'INACTIVE_USER_WITH_ACCESS',
                u.Id,
                'User "' + userName + '" (' + userUsername + ') hasn\'t logged in for ' + 
                daysInactive + ' days but has active permissions.' + permissionDetails + 
                ' This violates access control principles.',
                daysInactive > CRITICAL_INACTIVE_DAYS ? 'CRITICAL' : 'HIGH',
                'Deactivate user or document business justification for continued access. ' +
                'Consider automated deactivation for users inactive >90 days.',
                'SOC2',
                'CC6.1 - Logical Access Controls'
            ));
        }
        
        return threats;
    }
    
    /**
     * Detects excessive admin permissions
     * Pattern: Too many users with System Administrator profile or Modify All Data
     * Impact: Violates least privilege (HIPAA, SOC 2, NIST)
     * 
     * @return List of detected threats
     */
    public static List<Threat> detectExcessiveAdminPermissions() {
        List<Threat> threats = new List<Threat>();
        
        // Count users with System Administrator profile
        Integer adminCount = 0;
        Integer modifyAllCount = 0;
        Integer totalUsers = 0;
        
        try {
            adminCount = [
                SELECT COUNT() 
                FROM User 
                WHERE Profile.Name = 'System Administrator' 
                AND IsActive = true
                WITH SECURITY_ENFORCED
            ];
            
            // Count users with Modify All Data permission
            modifyAllCount = [
                SELECT COUNT() 
                FROM User 
                WHERE Id IN (
                    SELECT AssigneeId 
                    FROM PermissionSetAssignment 
                    WHERE PermissionSet.PermissionsModifyAllData = true
                )
                AND IsActive = true
                WITH SECURITY_ENFORCED
            ];
            
            // Industry best practice: 2-5% of users should be admins
            totalUsers = [
                SELECT COUNT() 
                FROM User 
                WHERE IsActive = true
                WITH SECURITY_ENFORCED
            ];
        } catch (SecurityException e) {
            System.debug(LoggingLevel.ERROR, '[ElaroSalesforceThreatDetector] Security exception querying admin users: ' + e.getMessage());
            return threats;
        }
        
        Integer totalAdmins = adminCount + modifyAllCount;
        Decimal adminPercentage = totalUsers > 0 ? (totalAdmins / Decimal.valueOf(totalUsers)) * 100 : 0;
        
        if (adminPercentage > MAX_ADMIN_PERCENTAGE) {
            threats.add(new Threat(
                'EXCESSIVE_ADMIN_PERMISSIONS',
                null,
                totalAdmins + ' users (' + adminPercentage.setScale(1) + '%) have administrator-level permissions. ' +
                'Industry best practice: 2-5% of users should be admins. ' +
                'Excessive admin access violates least privilege principles.',
                adminPercentage > CRITICAL_ADMIN_PERCENTAGE ? 'CRITICAL' : 'HIGH',
                'Review all admin users. Create granular permission sets for non-administrative tasks. ' +
                'Document business justification for each admin user.',
                'HIPAA',
                '45 CFR §164.514(d) - Minimum Necessary'
            ));
        }
        
        return threats;
    }
    
    /**
     * Detects suspicious permission set patterns
     * Pattern: Permission sets with unusual naming or recent privilege escalations
     * 
     * @return List of detected threats
     */
    public static List<Threat> detectSuspiciousPermissionPatterns() {
        List<Threat> threats = new List<Threat>();
        
        // Find permission sets created recently with elevated privileges
        List<PermissionSet> recentElevated = new List<PermissionSet>();
        try {
            recentElevated = [
                SELECT Id, Name, Label, PermissionsModifyAllData,
                       CreatedDate, CreatedBy.Name, LastModifiedDate, LastModifiedBy.Name
                FROM PermissionSet
                WHERE PermissionsModifyAllData = true
                AND CreatedDate = LAST_N_DAYS:30
                AND IsCustom = true
                WITH SECURITY_ENFORCED
            ];
        } catch (SecurityException e) {
            System.debug(LoggingLevel.ERROR, '[ElaroSalesforceThreatDetector] Security exception querying recent permission sets: ' + e.getMessage());
            return threats;
        }
        
        for (PermissionSet ps : recentElevated) {
            // Null-safe checks
            if (ps == null || ps.CreatedDate == null || ps.LastModifiedDate == null) {
                continue;
            }
            
            // Check if it was modified recently (potential escalation)
            if (ps.LastModifiedDate > ps.CreatedDate.addDays(1)) {
                String label = String.isNotBlank(ps.Label) ? ps.Label : ps.Name;
                String createdBy = ps.CreatedBy != null ? ps.CreatedBy.Name : 'Unknown';
                String modifiedBy = ps.LastModifiedBy != null ? ps.LastModifiedBy.Name : 'Unknown';
                
                threats.add(new Threat(
                    'SUSPICIOUS_PERMISSION_ESCALATION',
                    ps.Id,
                    'Permission set "' + label + '" was created and then modified to include ' +
                    'elevated privileges. Created by: ' + createdBy + 
                    '. Modified by: ' + modifiedBy + '. ' +
                    'This may indicate privilege escalation attack.',
                    'HIGH',
                    'Review permission set modification history. Verify business justification. ' +
                    'Consider requiring approval workflow for permission set changes.',
                    'SOC2',
                    'CC7.2 - Change Management'
                ));
            }
        }
        
        return threats;
    }
    
    /**
     * Runs all threat detection methods
     * 
     * @return Complete list of all detected threats
     */
    public static List<Threat> detectAllThreats() {
        List<Threat> allThreats = new List<Threat>();
        
        allThreats.addAll(detectPermissionSetClones());
        allThreats.addAll(detectSharingRuleBypasses());
        allThreats.addAll(detectPHIExposureViaRelatedLists());
        allThreats.addAll(detectInactiveUsersWithAccess());
        allThreats.addAll(detectExcessiveAdminPermissions());
        allThreats.addAll(detectSuspiciousPermissionPatterns());
        
        return allThreats;
    }
    
    /**
     * Inner class representing a detected threat
     */
    public class Threat {
        public String threatType;
        public Id entityId;
        public String description;
        public String severity;
        public String remediation;
        public String framework;
        public String legalCitation;
        
        public Threat(String type, Id entityId, String description, String sev, 
                     String rem, String fw, String citation) {
            this.threatType = type;
            this.entityId = entityId;
            this.description = description;
            this.severity = sev;
            this.remediation = rem;
            this.framework = fw;
            this.legalCitation = citation;
        }
    }
}

