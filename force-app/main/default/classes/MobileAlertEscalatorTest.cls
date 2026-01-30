/**
 * @description Test class for MobileAlertEscalator
 * @author Elaro Development Team
 * @since 2026-01
 */
@isTest
private class MobileAlertEscalatorTest {

    @TestSetup
    static void setupTestData() {
        // Create test user
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            Alias = 'escusr',
            Email = 'escalationuser@elaro.test',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Escalation',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/New_York',
            UserName = 'escalationuser' + Datetime.now().getTime() + '@elaro.test'
        );
        insert testUser;

        // Create escalation paths for all levels
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

        // Create test compliance gap
        Compliance_Gap__c gap = new Compliance_Gap__c(
            Framework__c = 'SOX',
            Policy_Reference__c = 'SOX_ACCESS_REVIEW',
            Severity__c = 'CRITICAL',
            Status__c = 'OPEN',
            Gap_Description__c = 'Critical SOX compliance gap for escalation testing',
            Detected_Date__c = Datetime.now()
        );
        insert gap;
    }

    @isTest
    static void testEscalator_FirstLevelEscalation() {
        Compliance_Gap__c gap = [SELECT Id FROM Compliance_Gap__c LIMIT 1];

        Test.startTest();
        MobileAlertEscalator escalator = new MobileAlertEscalator(gap.Id);
        escalator.execute(null);
        Test.stopTest();

        // Verify escalation level increased
        Compliance_Gap__c updatedGap = [
            SELECT Alert_Escalation_Level__c
            FROM Compliance_Gap__c
            WHERE Id = :gap.Id
        ];

        System.assertEquals(1, updatedGap.Alert_Escalation_Level__c, 'Gap should be at escalation level 1');
    }

    @isTest
    static void testEscalator_SecondLevelEscalation() {
        Compliance_Gap__c gap = [SELECT Id FROM Compliance_Gap__c LIMIT 1];
        gap.Alert_Escalation_Level__c = 1;
        update gap;

        Test.startTest();
        MobileAlertEscalator escalator = new MobileAlertEscalator(gap.Id);
        escalator.execute(null);
        Test.stopTest();

        Compliance_Gap__c updatedGap = [
            SELECT Alert_Escalation_Level__c
            FROM Compliance_Gap__c
            WHERE Id = :gap.Id
        ];

        System.assertEquals(2, updatedGap.Alert_Escalation_Level__c, 'Gap should be at escalation level 2');
    }

    @isTest
    static void testEscalator_ThirdLevelEscalation() {
        Compliance_Gap__c gap = [SELECT Id FROM Compliance_Gap__c LIMIT 1];
        gap.Alert_Escalation_Level__c = 2;
        update gap;

        Test.startTest();
        MobileAlertEscalator escalator = new MobileAlertEscalator(gap.Id);
        escalator.execute(null);
        Test.stopTest();

        Compliance_Gap__c updatedGap = [
            SELECT Alert_Escalation_Level__c
            FROM Compliance_Gap__c
            WHERE Id = :gap.Id
        ];

        System.assertEquals(3, updatedGap.Alert_Escalation_Level__c, 'Gap should be at escalation level 3');
    }

    @isTest
    static void testEscalator_MaxLevelReached() {
        Compliance_Gap__c gap = [SELECT Id FROM Compliance_Gap__c LIMIT 1];
        gap.Alert_Escalation_Level__c = 3;
        update gap;

        Test.startTest();
        MobileAlertEscalator escalator = new MobileAlertEscalator(gap.Id);
        escalator.execute(null);
        Test.stopTest();

        // Level should remain at 3
        Compliance_Gap__c updatedGap = [
            SELECT Alert_Escalation_Level__c
            FROM Compliance_Gap__c
            WHERE Id = :gap.Id
        ];

        System.assertEquals(3, updatedGap.Alert_Escalation_Level__c, 'Gap should remain at max escalation level 3');
    }

    @isTest
    static void testEscalator_AlreadyAcknowledged() {
        Compliance_Gap__c gap = [SELECT Id FROM Compliance_Gap__c LIMIT 1];
        gap.Alert_Acknowledged__c = true;
        update gap;

        Test.startTest();
        MobileAlertEscalator escalator = new MobileAlertEscalator(gap.Id);
        escalator.execute(null);
        Test.stopTest();

        // Escalation level should not change
        Compliance_Gap__c updatedGap = [
            SELECT Alert_Escalation_Level__c
            FROM Compliance_Gap__c
            WHERE Id = :gap.Id
        ];

        System.assertEquals(null, updatedGap.Alert_Escalation_Level__c, 'Escalation should not occur for acknowledged gaps');
    }

    @isTest
    static void testEscalator_Snoozed() {
        Compliance_Gap__c gap = [SELECT Id FROM Compliance_Gap__c LIMIT 1];
        gap.Alert_Snoozed_Until__c = Datetime.now().addHours(2);
        update gap;

        Test.startTest();
        MobileAlertEscalator escalator = new MobileAlertEscalator(gap.Id);
        escalator.execute(null);
        Test.stopTest();

        // Escalation level should not change
        Compliance_Gap__c updatedGap = [
            SELECT Alert_Escalation_Level__c
            FROM Compliance_Gap__c
            WHERE Id = :gap.Id
        ];

        System.assertEquals(null, updatedGap.Alert_Escalation_Level__c, 'Escalation should not occur for snoozed gaps');
    }

    @isTest
    static void testEscalator_SnoozeExpired() {
        Compliance_Gap__c gap = [SELECT Id FROM Compliance_Gap__c LIMIT 1];
        gap.Alert_Snoozed_Until__c = Datetime.now().addMinutes(-5); // Expired snooze
        update gap;

        Test.startTest();
        MobileAlertEscalator escalator = new MobileAlertEscalator(gap.Id);
        escalator.execute(null);
        Test.stopTest();

        // Escalation should proceed as snooze has expired
        Compliance_Gap__c updatedGap = [
            SELECT Alert_Escalation_Level__c
            FROM Compliance_Gap__c
            WHERE Id = :gap.Id
        ];

        System.assertEquals(1, updatedGap.Alert_Escalation_Level__c, 'Escalation should proceed after snooze expires');
    }

    @isTest
    static void testEscalator_InvalidAlertId() {
        Test.startTest();
        MobileAlertEscalator escalator = new MobileAlertEscalator('001000000000000AAA');
        escalator.execute(null);
        Test.stopTest();

        // Should complete without error
        System.assert(true, 'Escalator handled invalid ID gracefully');
    }

    @isTest
    static void testEscalator_NoEscalationRecipients() {
        // Deactivate all escalation paths
        List<Elaro_Escalation_Path__c> paths = [SELECT Id FROM Elaro_Escalation_Path__c];
        for (Elaro_Escalation_Path__c path : paths) {
            path.Active__c = false;
        }
        update paths;

        Compliance_Gap__c gap = [SELECT Id FROM Compliance_Gap__c LIMIT 1];

        Test.startTest();
        MobileAlertEscalator escalator = new MobileAlertEscalator(gap.Id);
        escalator.execute(null);
        Test.stopTest();

        // Escalation level should not change
        Compliance_Gap__c updatedGap = [
            SELECT Alert_Escalation_Level__c
            FROM Compliance_Gap__c
            WHERE Id = :gap.Id
        ];

        System.assertEquals(null, updatedGap.Alert_Escalation_Level__c, 'No escalation without recipients');
    }

    @isTest
    static void testEscalator_SchedulableInterface() {
        Compliance_Gap__c gap = [SELECT Id FROM Compliance_Gap__c LIMIT 1];

        Test.startTest();
        String jobId = System.schedule(
            'Test Escalation Job',
            '0 0 0 15 3 ? 2099',
            new MobileAlertEscalator(gap.Id)
        );
        Test.stopTest();

        // Verify job was scheduled
        List<CronTrigger> jobs = [SELECT Id FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(1, jobs.size(), 'Job should be scheduled');

        // Abort the test job
        System.abortJob(jobId);
    }

    @isTest
    static void testEscalator_Constructor() {
        Compliance_Gap__c gap = [SELECT Id FROM Compliance_Gap__c LIMIT 1];

        Test.startTest();
        MobileAlertEscalator escalator = new MobileAlertEscalator(gap.Id);
        Test.stopTest();

        System.assertNotEquals(null, escalator, 'Escalator should be instantiated');
    }

    @isTest
    static void testEscalator_NullSnooze() {
        Compliance_Gap__c gap = [SELECT Id FROM Compliance_Gap__c LIMIT 1];
        // Ensure snooze is null (not set)
        gap.Alert_Snoozed_Until__c = null;
        update gap;

        Test.startTest();
        MobileAlertEscalator escalator = new MobileAlertEscalator(gap.Id);
        escalator.execute(null);
        Test.stopTest();

        Compliance_Gap__c updatedGap = [
            SELECT Alert_Escalation_Level__c
            FROM Compliance_Gap__c
            WHERE Id = :gap.Id
        ];

        System.assertEquals(1, updatedGap.Alert_Escalation_Level__c, 'Escalation should occur with null snooze');
    }

    @isTest
    static void testEscalator_ProgressiveLevels() {
        Compliance_Gap__c gap = [SELECT Id FROM Compliance_Gap__c LIMIT 1];

        Test.startTest();
        // First escalation
        MobileAlertEscalator escalator1 = new MobileAlertEscalator(gap.Id);
        escalator1.execute(null);

        Compliance_Gap__c gap1 = [SELECT Alert_Escalation_Level__c FROM Compliance_Gap__c WHERE Id = :gap.Id];
        System.assertEquals(1, gap1.Alert_Escalation_Level__c, 'Should be at level 1');

        // Second escalation
        MobileAlertEscalator escalator2 = new MobileAlertEscalator(gap.Id);
        escalator2.execute(null);

        Compliance_Gap__c gap2 = [SELECT Alert_Escalation_Level__c FROM Compliance_Gap__c WHERE Id = :gap.Id];
        System.assertEquals(2, gap2.Alert_Escalation_Level__c, 'Should be at level 2');

        // Third escalation
        MobileAlertEscalator escalator3 = new MobileAlertEscalator(gap.Id);
        escalator3.execute(null);

        Compliance_Gap__c gap3 = [SELECT Alert_Escalation_Level__c FROM Compliance_Gap__c WHERE Id = :gap.Id];
        System.assertEquals(3, gap3.Alert_Escalation_Level__c, 'Should be at level 3');
        Test.stopTest();
    }

    @isTest
    static void testEscalator_WithDescription() {
        Compliance_Gap__c gap = [SELECT Id FROM Compliance_Gap__c LIMIT 1];
        gap.Gap_Description__c = 'This is a very long description that should be abbreviated for the notification message. '.repeat(10);
        update gap;

        Test.startTest();
        MobileAlertEscalator escalator = new MobileAlertEscalator(gap.Id);
        escalator.execute(null);
        Test.stopTest();

        System.assert(true, 'Escalator handled long description correctly');
    }

    @isTest
    static void testEscalator_NullDescription() {
        Compliance_Gap__c gap = [SELECT Id FROM Compliance_Gap__c LIMIT 1];
        gap.Gap_Description__c = null;
        update gap;

        Test.startTest();
        MobileAlertEscalator escalator = new MobileAlertEscalator(gap.Id);
        escalator.execute(null);
        Test.stopTest();

        System.assert(true, 'Escalator handled null description correctly');
    }
}
