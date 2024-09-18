/**
* @Name: EDGE_SearchFieldControllerTest

* @Purpose: This is the test class for the  EDGE_SearchFieldController class.

* @History                                                            
                                                            
* @VERSION    AUTHOR            DATE            DETAIL
*    1.0   Preyanka Ghosh    26/02/2019    Initial Development        
**/
@isTest
public class EDGE_SearchFieldControllerTest {
    
    @isTest
    public static void getFieldDetailsTest(){
        test.startTest();
        Map<String, Map<String, Object>> mapFieldDetails = EDGE_SearchFieldController.getFieldDetails('Account',True);
        System.assert(mapFieldDetails!=null);
        EDGE_SearchFieldController.getFieldDetails('Account',null);
        test.stopTest();
    }
}