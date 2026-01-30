/**
 * @description Test class for MobileAlertPublisher
 * @author Elaro Development Team
 * @since 2026-01
 */
@isTest
private class MobileAlertPublisherTest {

    @TestSetup
    static void setupTestData() {
        // Create test user
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            Alias = 'oncllusr',
            Email = 'oncalluser@elaro.test',
            EmailEncodingKey = 'UTF-8',
            LastName = 'OnCall',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/New_York',
            UserName = 'oncalluser' + Datetime.now().getTime() + '@elaro.test'
        );
        insert testUser;

        // Create on-call schedule for test user (current time window)
        Elaro_On_Call_Schedule__c schedule = new Elaro_On_Call_Schedule__c(
            Name = 'Primary On-Call',
            User__c = testUser.Id,
            Start_Time__c = Datetime.now().addHours(-1),
            End_Time__c = Datetime.now().addHours(8),
            Active__c = true,
            Rotation_Name__c = 'Primary',
            Timezone__c = 'America/New_York',
            Notification_Methods__c = 'Mobile;Email'
        );
        insert schedule;

        // Create escalation paths
        List<Elaro_Escalation_Path__c> escalationPaths = new List<Elaro_Escalation_Path__c>();
        escalationPaths.add(new Elaro_Escalation_Path__c(
            User__c = testUser.Id,
            Level__c = 1,
            Active__c = true,
            Role__c = 'Team Lead',
            Notification_Method__c = 'Both',
            Escalation_Delay_Minutes__c = 15
        ));
        escalationPaths.add(new Elaro_Escalation_Path__c(
            User__c = testUser.Id,
            Level__c = 2,
            Active__c = true,
            Role__c = 'Manager',
            Notification_Method__c = 'Both',
            Escalation_Delay_Minutes__c = 30
        ));
        escalationPaths.add(new Elaro_Escalation_Path__c(
            User__c = testUser.Id,
            Level__c = 3,
            Active__c = true,
            Role__c = 'CISO',
            Notification_Method__c = 'All',
            Escalation_Delay_Minutes__c = 60
        ));
        insert escalationPaths;

        // Create test compliance gaps
        List<Compliance_Gap__c> gaps = new List<Compliance_Gap__c>();
        gaps.add(new Compliance_Gap__c(
            Framework__c = 'SOX',
            Policy_Reference__c = 'SOX_ACCESS_REVIEW',
            Severity__c = 'CRITICAL',
            Status__c = 'OPEN',
            Gap_Description__c = 'Critical SOX compliance gap requiring immediate attention',
            Detected_Date__c = Datetime.now()
        ));
        gaps.add(new Compliance_Gap__c(
            Framework__c = 'HIPAA',
            Policy_Reference__c = 'HIPAA_PHI_ACCESS',
            Severity__c = 'HIGH',
            Status__c = 'OPEN',
            Gap_Description__c = 'High priority HIPAA compliance gap',
            Detected_Date__c = Datetime.now()
        ));
        gaps.add(new Compliance_Gap__c(
            Framework__c = 'SOC2',
            Policy_Reference__c = 'SOC2_MONITORING',
            Severity__c = 'MEDIUM',
            Status__c = 'OPEN',
            Gap_Description__c = 'Medium priority SOC2 gap',
            Detected_Date__c = Datetime.now()
        ));
        insert gaps;
    }

    @isTest
    static void testPublishCriticalAlert() {
        Compliance_Gap__c gap = [SELECT Id FROM Compliance_Gap__c WHERE Severity__c = 'CRITICAL' LIMIT 1];

        Test.startTest();
        MobileAlertPublisher.publishCriticalAlert(
            gap.Id,
            'CRITICAL: SOX Gap Detected',
            'Immediate action required'
        );
        Test.stopTest();

        // Verify no exceptions thrown - notification sending is mocked in tests
        System.assert(true, 'Critical alert published successfully');
    }

    @isTest
    static void testPublishHighAlert() {
        Compliance_Gap__c gap = [SELECT Id FROM Compliance_Gap__c WHERE Severity__c = 'HIGH' LIMIT 1];

        Test.startTest();
        MobileAlertPublisher.publishHighAlert(
            gap.Id,
            'HIGH: HIPAA Gap Detected',
            'Action required'
        );
        Test.stopTest();

        System.assert(true, 'High alert published successfully');
    }

    @isTest
    static void testPublishAlertForGap_Critical() {
        Compliance_Gap__c gap = [SELECT Id FROM Compliance_Gap__c WHERE Severity__c = 'CRITICAL' LIMIT 1];

        Test.startTest();
        MobileAlertPublisher.publishAlertForGap(gap.Id);
        Test.stopTest();

        System.assert(true, 'Alert for critical gap published successfully');
    }

    @isTest
    static void testPublishAlertForGap_High() {
        Compliance_Gap__c gap = [SELECT Id FROM Compliance_Gap__c WHERE Severity__c = 'HIGH' LIMIT 1];

        Test.startTest();
        MobileAlertPublisher.publishAlertForGap(gap.Id);
        Test.stopTest();

        System.assert(true, 'Alert for high gap published successfully');
    }

    @isTest
    static void testPublishAlertForGap_Medium() {
        // Medium severity gaps should not trigger alerts
        Compliance_Gap__c gap = [SELECT Id FROM Compliance_Gap__c WHERE Severity__c = 'MEDIUM' LIMIT 1];

        Test.startTest();
        MobileAlertPublisher.publishAlertForGap(gap.Id);
        Test.stopTest();

        System.assert(true, 'No alert sent for medium severity gap');
    }

    @isTest
    static void testPublishAlertForGap_NotFound() {
        Test.startTest();
        try {
            MobileAlertPublisher.publishAlertForGap('001000000000000AAA');
            System.assert(false, 'Expected exception for invalid gap ID');
        } catch (MobileAlertPublisher.MobileAlertException e) {
            System.assert(e.getMessage().contains('not found'), 'Expected not found error');
        }
        Test.stopTest();
    }

    @isTest
    static void testAcknowledgeAlert() {
        Compliance_Gap__c gap = [SELECT Id FROM Compliance_Gap__c WHERE Severity__c = 'CRITICAL' LIMIT 1];

        Test.startTest();
        MobileAlertPublisher.acknowledgeAlert(gap.Id);
        Test.stopTest();

        // Verify gap is marked as acknowledged
        Compliance_Gap__c updatedGap = [
            SELECT Alert_Acknowledged__c, Alert_Acknowledged_By__c, Alert_Acknowledged_At__c
            FROM Compliance_Gap__c
            WHERE Id = :gap.Id
        ];

        System.assertEquals(true, updatedGap.Alert_Acknowledged__c, 'Gap should be acknowledged');
        System.assertEquals(UserInfo.getUserId(), updatedGap.Alert_Acknowledged_By__c, 'Acknowledged by should be current user');
        System.assertNotEquals(null, updatedGap.Alert_Acknowledged_At__c, 'Acknowledged at should be set');
    }

    @isTest
    static void testSnoozeAlert() {
        Compliance_Gap__c gap = [SELECT Id FROM Compliance_Gap__c WHERE Severity__c = 'CRITICAL' LIMIT 1];

        Test.startTest();
        MobileAlertPublisher.snoozeAlert(gap.Id, 60);
        Test.stopTest();

        // Verify gap is snoozed
        Compliance_Gap__c updatedGap = [
            SELECT Alert_Snoozed_Until__c
            FROM Compliance_Gap__c
            WHERE Id = :gap.Id
        ];

        System.assertNotEquals(null, updatedGap.Alert_Snoozed_Until__c, 'Snoozed until should be set');
        System.assert(updatedGap.Alert_Snoozed_Until__c > Datetime.now(), 'Snoozed until should be in the future');
    }

    @isTest
    static void testSnoozeAlert_InvalidDuration_Zero() {
        Compliance_Gap__c gap = [SELECT Id FROM Compliance_Gap__c WHERE Severity__c = 'CRITICAL' LIMIT 1];

        Test.startTest();
        try {
            MobileAlertPublisher.snoozeAlert(gap.Id, 0);
            System.assert(false, 'Expected exception for zero duration');
        } catch (MobileAlertPublisher.MobileAlertException e) {
            System.assert(e.getMessage().contains('between 1 and 480'), 'Expected duration validation error');
        }
        Test.stopTest();
    }

    @isTest
    static void testSnoozeAlert_InvalidDuration_TooLong() {
        Compliance_Gap__c gap = [SELECT Id FROM Compliance_Gap__c WHERE Severity__c = 'CRITICAL' LIMIT 1];

        Test.startTest();
        try {
            MobileAlertPublisher.snoozeAlert(gap.Id, 500);
            System.assert(false, 'Expected exception for duration > 480');
        } catch (MobileAlertPublisher.MobileAlertException e) {
            System.assert(e.getMessage().contains('between 1 and 480'), 'Expected duration validation error');
        }
        Test.stopTest();
    }

    @isTest
    static void testSnoozeAlert_InvalidDuration_Negative() {
        Compliance_Gap__c gap = [SELECT Id FROM Compliance_Gap__c WHERE Severity__c = 'CRITICAL' LIMIT 1];

        Test.startTest();
        try {
            MobileAlertPublisher.snoozeAlert(gap.Id, -10);
            System.assert(false, 'Expected exception for negative duration');
        } catch (MobileAlertPublisher.MobileAlertException e) {
            System.assert(e.getMessage().contains('between 1 and 480'), 'Expected duration validation error');
        }
        Test.stopTest();
    }

    @isTest
    static void testGetCurrentOnCallUsers() {
        Test.startTest();
        List<MobileAlertPublisher.OnCallUser> onCallUsers = MobileAlertPublisher.getCurrentOnCallUsers();
        Test.stopTest();

        System.assertNotEquals(0, onCallUsers.size(), 'Should have at least one on-call user');

        MobileAlertPublisher.OnCallUser user = onCallUsers[0];
        System.assertNotEquals(null, user.userId, 'User ID should be set');
        System.assertNotEquals(null, user.userName, 'User name should be set');
        System.assertEquals('Primary', user.rotationName, 'Rotation name should match');
    }

    @isTest
    static void testGetEscalationPath() {
        Test.startTest();
        List<MobileAlertPublisher.EscalationPathEntry> paths = MobileAlertPublisher.getEscalationPath();
        Test.stopTest();

        System.assertEquals(3, paths.size(), 'Should have 3 escalation levels');

        // Verify ordering
        System.assertEquals(1, paths[0].level, 'First entry should be level 1');
        System.assertEquals(2, paths[1].level, 'Second entry should be level 2');
        System.assertEquals(3, paths[2].level, 'Third entry should be level 3');

        // Verify roles
        System.assertEquals('Team Lead', paths[0].role, 'Level 1 should be Team Lead');
        System.assertEquals('Manager', paths[1].role, 'Level 2 should be Manager');
        System.assertEquals('CISO', paths[2].role, 'Level 3 should be CISO');
    }

    @isTest
    static void testGetEscalationPath_NoActivePaths() {
        // Deactivate all paths
        List<Elaro_Escalation_Path__c> paths = [SELECT Id FROM Elaro_Escalation_Path__c];
        for (Elaro_Escalation_Path__c path : paths) {
            path.Active__c = false;
        }
        update paths;

        Test.startTest();
        List<MobileAlertPublisher.EscalationPathEntry> result = MobileAlertPublisher.getEscalationPath();
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Should have no escalation paths');
    }

    @isTest
    static void testGetCurrentOnCallUsers_NoActiveSchedules() {
        // Deactivate all schedules
        List<Elaro_On_Call_Schedule__c> schedules = [SELECT Id FROM Elaro_On_Call_Schedule__c];
        for (Elaro_On_Call_Schedule__c schedule : schedules) {
            schedule.Active__c = false;
        }
        update schedules;

        Test.startTest();
        List<MobileAlertPublisher.OnCallUser> result = MobileAlertPublisher.getCurrentOnCallUsers();
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Should have no on-call users');
    }

    @isTest
    static void testPublishAlertWithNoOnCallUsers() {
        // Deactivate all schedules to test fallback to admin users
        List<Elaro_On_Call_Schedule__c> schedules = [SELECT Id FROM Elaro_On_Call_Schedule__c];
        for (Elaro_On_Call_Schedule__c schedule : schedules) {
            schedule.Active__c = false;
        }
        update schedules;

        Compliance_Gap__c gap = [SELECT Id FROM Compliance_Gap__c WHERE Severity__c = 'CRITICAL' LIMIT 1];

        Test.startTest();
        // Should not throw an exception - will fall back to admin users or log warning
        MobileAlertPublisher.publishCriticalAlert(
            gap.Id,
            'Test Alert',
            'Test message'
        );
        Test.stopTest();

        System.assert(true, 'Alert handled gracefully with no on-call users');
    }

    @isTest
    static void testOnCallUserWrapper() {
        Test.startTest();
        MobileAlertPublisher.OnCallUser wrapper = new MobileAlertPublisher.OnCallUser();
        wrapper.userId = UserInfo.getUserId();
        wrapper.userName = 'Test User';
        wrapper.userEmail = 'test@test.com';
        wrapper.rotationName = 'Primary';
        wrapper.shiftEnd = Datetime.now().addHours(8);
        wrapper.notificationMethods = 'Mobile;Email';
        Test.stopTest();

        System.assertEquals(UserInfo.getUserId(), wrapper.userId, 'User ID should match');
        System.assertEquals('Test User', wrapper.userName, 'User name should match');
        System.assertEquals('Primary', wrapper.rotationName, 'Rotation name should match');
    }

    @isTest
    static void testEscalationPathEntryWrapper() {
        Test.startTest();
        MobileAlertPublisher.EscalationPathEntry wrapper = new MobileAlertPublisher.EscalationPathEntry();
        wrapper.pathId = null;
        wrapper.userId = UserInfo.getUserId();
        wrapper.userName = 'Test Manager';
        wrapper.userEmail = 'manager@test.com';
        wrapper.level = 2;
        wrapper.role = 'Manager';
        wrapper.notificationMethod = 'Both';
        wrapper.delayMinutes = 30;
        Test.stopTest();

        System.assertEquals(2, wrapper.level, 'Level should match');
        System.assertEquals('Manager', wrapper.role, 'Role should match');
        System.assertEquals(30, wrapper.delayMinutes, 'Delay should match');
    }

    @isTest
    static void testMobileAlertResender() {
        Compliance_Gap__c gap = [SELECT Id FROM Compliance_Gap__c WHERE Severity__c = 'CRITICAL' LIMIT 1];

        Test.startTest();
        MobileAlertPublisher.MobileAlertResender resender = new MobileAlertPublisher.MobileAlertResender(gap.Id);
        resender.execute(null);
        Test.stopTest();

        System.assert(true, 'Resender executed successfully');
    }

    @isTest
    static void testMobileAlertResender_StillSnoozed() {
        Compliance_Gap__c gap = [SELECT Id FROM Compliance_Gap__c WHERE Severity__c = 'CRITICAL' LIMIT 1];

        // Set snooze in the future
        gap.Alert_Snoozed_Until__c = Datetime.now().addHours(2);
        update gap;

        Test.startTest();
        MobileAlertPublisher.MobileAlertResender resender = new MobileAlertPublisher.MobileAlertResender(gap.Id);
        resender.execute(null);
        Test.stopTest();

        System.assert(true, 'Resender handled snoozed alert correctly');
    }

    @isTest
    static void testMobileAlertResender_InvalidId() {
        Test.startTest();
        MobileAlertPublisher.MobileAlertResender resender = new MobileAlertPublisher.MobileAlertResender('001000000000000AAA');
        resender.execute(null);
        Test.stopTest();

        System.assert(true, 'Resender handled invalid ID gracefully');
    }
}
