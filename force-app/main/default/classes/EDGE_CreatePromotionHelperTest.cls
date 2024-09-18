@isTest
public class EDGE_CreatePromotionHelperTest {

    @isTest
    public static void testGetRecordTypes(){
        
       String recordTypeId = EDGE_CreatePromotionHelper.getRecordTypesAll();
       system.assert(recordTypeId!=null,'recordtype should not be null');
    }
}