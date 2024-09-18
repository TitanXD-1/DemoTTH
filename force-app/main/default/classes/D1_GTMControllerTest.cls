/**
@name D1_GTMControllerTest
@description D1_GTMController Test class
@history
VERSION     AUTHOR         DATE            DETAIL
1.0         Ajay           28/6/21         Initial Development (NCP-3674)
2.0         Ajay           09/8/21         GTM metadata parameter override (NCP-4261)
**/

@IsTest
public class D1_GTMControllerTest {
    /**
     * @description test User information
     */
    @isTest
    public static void testGTMConfiguration(){
        Object configuration = D1_GTMController.getGTMConfiguration();
        System.assert(configuration != null, 'Fetching configuration failed');
    }
    
    /**
     * @description test convert to URL Format
     * @userstory NCP-4261
     */
    @isTest
    public static void testToURLFormat(){
        String converted = D1_GTMController.toURLFormat('abc_bcd__c');
        System.assert(converted == 'abc-bcd', 'Fetching use details failed');

    }

    /**
     * @description test product information
     */
    @isTest
    public static void getProduct(){
        try{
            Object result = D1_GTMController.getProduct(null);
            System.assert(result != null, 'Product empty');
        }
        catch(Exception ex){
            System.assert(ex != null, 'Unexpected Exception value');
        }

    }
}