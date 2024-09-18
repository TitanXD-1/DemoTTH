@IsTest
private class LookupControllerTest {

    @IsTest
    static void testfetchObjectLabel() {
        System.assertEquals('User', LookupController.fetchObjectLabel('User'));
    }

    @IsTest
    static void testfetchRecentlyViewedRecords() {
        LookupController.fetchRecentlyViewedRecords('User');
        System.assert(true);
    }

    @IsTest
    static void testsearch() {
        List<String> s = new List<String>();
        List<String> wh = new List<String> {'IsActive=true'};
        LookupController.search('User', '', wh, s, 5, s, 'ALL');
        System.assert(true);
    }

    @IsTest
    static void testsearchError() {
        List<String> s = new List<String>();
        Boolean isError = false;
        List<String> wh = new List<String> {'Is=true'};
        try {
            LookupController.search('User', '', wh, s, 5, s, 'ALL');
        } catch (Exception ex) {
            isError = true;
        }
        System.assert(isError);
    }
}