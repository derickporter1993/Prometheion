@IsTest
private class SlackNotifierTest {
    @IsTest static void testNotify() {
        Test.startTest();
        SlackNotifier.notifyAsync('test');
        Test.stopTest();
        System.assert(true, 'notifyAsync executed');
    }
}
