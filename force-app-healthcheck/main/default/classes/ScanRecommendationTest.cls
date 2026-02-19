/**
 * Tests for {@link ScanRecommendation} covering parameterized construction,
 * default construction, priority-based comparison/sorting, field access,
 * and null priority handling.
 *
 * @author Elaro Team
 * @since v1.0.0 (Spring '26)
 * @group Health Check
 * @see ScanRecommendation
 */
@IsTest(testFor = ScanRecommendation.class)
private class ScanRecommendationTest {

    @IsTest
    static void shouldConstructWithAllFields() {
        Test.startTest();
        ScanRecommendation rec = new ScanRecommendation(
            'Enable MFA for All Users',
            'Deploy multi-factor authentication across the entire org',
            'SecuritySession/home',
            1,
            'MFA'
        );
        Test.stopTest();

        Assert.areEqual('Enable MFA for All Users', rec.title,
            'title should match constructor argument');
        Assert.areEqual('Deploy multi-factor authentication across the entire org',
            rec.description,
            'description should match constructor argument');
        Assert.areEqual('SecuritySession/home', rec.setupMenuPath,
            'setupMenuPath should match constructor argument');
        Assert.areEqual(1, rec.priority,
            'priority should match constructor argument');
        Assert.areEqual('MFA', rec.category,
            'category should match constructor argument');
    }

    @IsTest
    static void shouldConstructWithDefaultConstructor() {
        Test.startTest();
        ScanRecommendation rec = new ScanRecommendation();
        Test.stopTest();

        Assert.isNull(rec.title,
            'Default constructor should leave title null');
        Assert.isNull(rec.description,
            'Default constructor should leave description null');
        Assert.isNull(rec.setupMenuPath,
            'Default constructor should leave setupMenuPath null');
        Assert.isNull(rec.priority,
            'Default constructor should leave priority null');
        Assert.isNull(rec.category,
            'Default constructor should leave category null');
    }

    @IsTest
    static void shouldCompareByPriorityAscending() {
        ScanRecommendation critical = new ScanRecommendation(
            'Critical Fix', 'Fix immediately', 'Setup/home', 1, 'SecurityHealthCheck'
        );
        ScanRecommendation medium = new ScanRecommendation(
            'Medium Fix', 'Fix when convenient', 'Setup/home', 3, 'Session'
        );

        Test.startTest();
        Integer comparison = critical.compareTo(medium);
        Test.stopTest();

        Assert.isTrue(comparison < 0,
            'Priority 1 should sort before priority 3 (negative result), got: ' + comparison);
    }

    @IsTest
    static void shouldReturnZeroForEqualPriorities() {
        ScanRecommendation first = new ScanRecommendation(
            'First', 'Description A', 'Setup/a', 2, 'MFA'
        );
        ScanRecommendation second = new ScanRecommendation(
            'Second', 'Description B', 'Setup/b', 2, 'Session'
        );

        Test.startTest();
        Integer comparison = first.compareTo(second);
        Test.stopTest();

        Assert.areEqual(0, comparison,
            'Equal priorities should return 0');
    }

    @IsTest
    static void shouldSortHigherPriorityNumberAfterLower() {
        ScanRecommendation low = new ScanRecommendation(
            'Low Priority', 'Not urgent', 'Setup/home', 3, 'AuditTrail'
        );
        ScanRecommendation high = new ScanRecommendation(
            'High Priority', 'Urgent', 'Setup/home', 1, 'SecurityHealthCheck'
        );

        Test.startTest();
        Integer comparison = low.compareTo(high);
        Test.stopTest();

        Assert.isTrue(comparison > 0,
            'Priority 3 should sort after priority 1 (positive result), got: ' + comparison);
    }

    @IsTest
    static void shouldDefaultNullPriorityTo99InComparison() {
        ScanRecommendation withPriority = new ScanRecommendation(
            'Has Priority', 'Description', 'Setup/home', 2, 'MFA'
        );
        ScanRecommendation noPriority = new ScanRecommendation();

        Test.startTest();
        Integer comparison = noPriority.compareTo(withPriority);
        Test.stopTest();

        // null defaults to 99, so 99 - 2 = 97 (positive)
        Assert.isTrue(comparison > 0,
            'Null priority (defaulting to 99) should sort after priority 2, got: ' + comparison);
    }

    @IsTest
    static void shouldSortListOfRecommendationsByPriority() {
        List<ScanRecommendation> recs = new List<ScanRecommendation>{
            new ScanRecommendation('Medium', 'Desc', 'Setup/m', 2, 'MFA'),
            new ScanRecommendation('Critical', 'Desc', 'Setup/c', 1, 'SecurityHealthCheck'),
            new ScanRecommendation('Low', 'Desc', 'Setup/l', 3, 'AuditTrail')
        };

        Test.startTest();
        recs.sort();
        Test.stopTest();

        Assert.areEqual(1, recs[0].priority,
            'First element after sort should have priority 1');
        Assert.areEqual(2, recs[1].priority,
            'Second element after sort should have priority 2');
        Assert.areEqual(3, recs[2].priority,
            'Third element after sort should have priority 3');
        Assert.areEqual('Critical', recs[0].title,
            'Critical recommendation should sort first');
    }

    @IsTest
    static void shouldSerializeToJsonAndDeserialize() {
        ScanRecommendation original = new ScanRecommendation(
            'Reduce Session Timeout',
            'Set session timeout to 2 hours or less',
            'SecuritySession/home',
            2,
            'Session'
        );

        Test.startTest();
        String jsonString = JSON.serialize(original);
        ScanRecommendation deserialized = (ScanRecommendation) JSON.deserialize(
            jsonString, ScanRecommendation.class
        );
        Test.stopTest();

        Assert.isNotNull(deserialized,
            'Deserialized recommendation should not be null');
        Assert.areEqual(original.title, deserialized.title,
            'title should survive serialization round-trip');
        Assert.areEqual(original.priority, deserialized.priority,
            'priority should survive serialization round-trip');
        Assert.areEqual(original.setupMenuPath, deserialized.setupMenuPath,
            'setupMenuPath should survive serialization round-trip');
        Assert.areEqual(original.category, deserialized.category,
            'category should survive serialization round-trip');
    }

    @IsTest
    static void shouldAllowFieldMutationAfterConstruction() {
        ScanRecommendation rec = new ScanRecommendation(
            'Original Title', 'Original Desc', 'Setup/orig', 3, 'MFA'
        );

        Test.startTest();
        rec.title = 'Updated Title';
        rec.priority = 1;
        rec.category = 'SecurityHealthCheck';
        Test.stopTest();

        Assert.areEqual('Updated Title', rec.title,
            'title should be mutable after construction');
        Assert.areEqual(1, rec.priority,
            'priority should be mutable after construction');
        Assert.areEqual('SecurityHealthCheck', rec.category,
            'category should be mutable after construction');
    }
}
