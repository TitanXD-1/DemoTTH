/**
 * @name : D1_BuyerAccountCheckTest
 * @description : Test class for D1_BuyerAccountCheck
 * @history
 * VERSION     	AUTHOR         	   DATE            DETAIL
 * 1.0         D1 DEV Team      	
**/
@isTest
public class D1_BuyerAccountCheckTest {
    /**
    * @name : testmethod1
    * @description : This method is used to test the getBuyerAccountStatus() method
    */
    @istest
    public static void testmethod1(){
        Account acct = PNR_TestDataUtility.getDirectCustomerRec();
        List<String> accountIdList = new List<String>();
        accountIdList.add(acct.Id);
        Test.startTest();
            List<D1_BuyerAccountCheck.Response> responseWrap = new List<D1_BuyerAccountCheck.Response>();
            responseWrap = D1_BuyerAccountCheck.getBuyerAccountStatus(accountIdList);
        Test.stopTest();
        System.assert(responseWrap != NULL, 'Accouunt check status');
    }
}