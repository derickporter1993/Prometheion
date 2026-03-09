/**
 * Test class for {@link BusinessDayCalculator}. Validates business day
 * calculations including weekend skipping, holiday exclusion, AG delay
 * extensions, and edge cases (null, zero).
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group SEC Cybersecurity
 * @see BusinessDayCalculator
 */
@IsTest
private class BusinessDayCalculatorTest {

    /**
     * Monday determination + 4 business days = Friday (no weekends in between).
     * Using 2026-01-05 (Monday) -> expect 2026-01-09 (Friday).
     */
    @IsTest
    static void testCalculateFilingDeadline_noHolidays_adds4BusinessDays() {
        // Arrange: Monday Jan 5, 2026 at 9:00 AM
        DateTime monday = DateTime.newInstance(2026, 1, 5, 9, 0, 0);

        // Act
        Test.startTest();
        DateTime deadline = BusinessDayCalculator.calculateFilingDeadline(monday, 4);
        Test.stopTest();

        // Assert: Should be Friday Jan 9, 2026 at 9:00 AM
        Assert.isNotNull(deadline, 'Deadline should not be null');
        Assert.areEqual(
            Date.newInstance(2026, 1, 9),
            deadline.date(),
            'Four business days from Monday should be Friday'
        );
        Assert.areEqual(
            Time.newInstance(9, 0, 0, 0),
            deadline.time(),
            'Time component should be preserved from determination date'
        );
    }

    /**
     * Wednesday determination + 4 business days = Tuesday (skips Sat/Sun).
     * Using 2026-01-07 (Wednesday) -> expect 2026-01-13 (Tuesday).
     */
    @IsTest
    static void testCalculateFilingDeadline_crossesWeekend() {
        // Arrange: Wednesday Jan 7, 2026 at 14:30
        DateTime wednesday = DateTime.newInstance(2026, 1, 7, 14, 30, 0);

        // Act
        Test.startTest();
        DateTime deadline = BusinessDayCalculator.calculateFilingDeadline(wednesday, 4);
        Test.stopTest();

        // Assert: Should be Tuesday Jan 13, 2026
        Assert.areEqual(
            Date.newInstance(2026, 1, 13),
            deadline.date(),
            'Four business days from Wednesday should be next Tuesday (skipping weekend)'
        );
    }

    /**
     * Filing deadline calculation should skip holiday dates from Holiday__c.
     * Monday + holiday on Tuesday + 4 business days = next Monday.
     */
    @IsTest
    static void testCalculateFilingDeadline_withHoliday() {
        // Arrange: Create a holiday on Tuesday Jan 6, 2026
        Holiday__c holiday = new Holiday__c(
            Holiday_Date__c = Date.newInstance(2026, 1, 6),
            Country_Code__c = 'US',
            Is_Federal__c = true,
            Year__c = 2026
        );
        insert as user holiday;

        // Monday Jan 5, 2026 at 9:00 AM
        DateTime monday = DateTime.newInstance(2026, 1, 5, 9, 0, 0);

        // Act
        Test.startTest();
        DateTime deadline = BusinessDayCalculator.calculateFilingDeadline(monday, 4);
        Test.stopTest();

        // Assert: Should skip Tuesday (holiday), so Mon->Wed(1)->Thu(2)->Fri(3)->Mon(4)
        // = Monday Jan 12, 2026
        Assert.areEqual(
            Date.newInstance(2026, 1, 12),
            deadline.date(),
            'Should skip the holiday on Tuesday and push deadline to Monday'
        );
    }

    /**
     * AG delay extends the base deadline by additional business days.
     * 4 base + 3 delay = 7 business days total from determination.
     */
    @IsTest
    static void testCalculateWithAGDelay_extendsDeadline() {
        // Arrange: Monday Jan 5, 2026 at 9:00 AM
        DateTime monday = DateTime.newInstance(2026, 1, 5, 9, 0, 0);

        // Act
        Test.startTest();
        DateTime deadline = BusinessDayCalculator.calculateWithAGDelay(monday, 4, 3);
        Test.stopTest();

        // Assert: 7 business days from Monday Jan 5
        // Mon->Tue(1)->Wed(2)->Thu(3)->Fri(4)->Mon(5)->Tue(6)->Wed(7) = Jan 14
        Assert.areEqual(
            Date.newInstance(2026, 1, 14),
            deadline.date(),
            'AG delay of 3 days added to 4-day base should yield 7 business days total'
        );
    }

    /**
     * Null determination date should return null.
     */
    @IsTest
    static void testCalculateFilingDeadline_nullDate_returnsNull() {
        Test.startTest();
        DateTime result = BusinessDayCalculator.calculateFilingDeadline(null, 4);
        Test.stopTest();

        Assert.isNull(result, 'Null determination date should return null');
    }

    /**
     * Zero business days should return the original determination date unchanged.
     */
    @IsTest
    static void testCalculateFilingDeadline_zeroDays_returnsOriginal() {
        DateTime original = DateTime.newInstance(2026, 1, 5, 9, 0, 0);

        Test.startTest();
        DateTime result = BusinessDayCalculator.calculateFilingDeadline(original, 0);
        Test.stopTest();

        Assert.areEqual(
            original,
            result,
            'Zero business days should return the original date'
        );
    }

    /**
     * AG delay with null delay days should return the base deadline.
     */
    @IsTest
    static void testCalculateWithAGDelay_nullDelay_returnsBaseDeadline() {
        DateTime monday = DateTime.newInstance(2026, 1, 5, 9, 0, 0);

        Test.startTest();
        DateTime deadline = BusinessDayCalculator.calculateWithAGDelay(monday, 4, null);
        Test.stopTest();

        Assert.areEqual(
            Date.newInstance(2026, 1, 9),
            deadline.date(),
            'Null delay days should return base 4-day deadline'
        );
    }

    /**
     * countBusinessDaysBetween should count correctly excluding weekends.
     */
    @IsTest
    static void testCountBusinessDaysBetween_excludesWeekends() {
        // Monday Jan 5 to Friday Jan 9 = 4 business days
        Date startDate = Date.newInstance(2026, 1, 5);
        Date endDate = Date.newInstance(2026, 1, 9);

        Test.startTest();
        Integer count = BusinessDayCalculator.countBusinessDaysBetween(startDate, endDate);
        Test.stopTest();

        Assert.areEqual(4, count, 'Monday to Friday should be 4 business days');
    }
}
