/**
@name D1_OrderSubmissionController
@description This class is controller class for getting Sales Order Product
@history
VERSION     AUTHOR         DATE            DETAIL
1.0       Manikant Prasad   15/02/2021      NCP-1400
2.0       Praveen           13/08/2021      NCP-3960
**/
@isTest
public class D1_OrderSubmissionControllerTest {
	@IsTest
    public static void testGetSalesOrderDetails(){
        
        try{
            Test.startTest();
            List<Sales_Order__c> salesList = new List<Sales_Order__c>();
        	salesList = D1_OrderSubmissionController.getSalesOrderDetails(UserInfo.getUserId());
            System.assert(salesList != NULL, 'Sales order list not found');
             test.stopTest();
        }catch(Exception ex){
            system.debug(LoggingLevel.ERROR, ex.getMessage());
        }
       
    }
}