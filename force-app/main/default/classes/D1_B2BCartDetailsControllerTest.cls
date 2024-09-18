/**
@name: D1_B2BCartDetailsControllerTest
@description : Test Class for D1_B2BCartDetailsController
@history                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0       Ankit Garg       04/01/2021        NCP-1094
**/
@isTest
public class D1_B2BCartDetailsControllerTest {
    
    /**
     * @author Ankit
     * @date 04/01/2021 
     * @description Create Test Data
     * @param  
     * @return 
     */
    @testSetup static void createTestData() {
            
        WebCart webCArtObj;
        
        Account account = D1_TestDataUtility.getDirectCustomer();
        
        D1_TestDataUtility.setUpExternalUser(account, 'Direct Buyer');
        D1_TestDataUtility.insertCartAndCartItems(account);
        
        User userObj = [select Id,AccountId,Account.Name,Effective_Account_Id__c from User where Profile.Name = 'DiageoOne External User' 
                        and Isactive = true  order by lastModifieddate desc limit 1];
        
        D1_TestDataUtility.createOrgSettings();
        system.runAs(userObj){
            D1_TestDataUtility.b2bCommercePermissionset(userObj);

            webCartObj = [SELECT Id from WebCart where Name='TestCart'];
            webCartObj.OwnerId = userInfo.getUserId();
            update webCartObj;
        }
    }
    
    /**
     * @author Ankit
     * @date 04/01/2021 
     * @description First TestMthd
     * @param  
     * @return 
     */
    @isTest
    public static void testB2BCartDetailsController() {
        User userObj = [select Id,AccountId,Account.Name from User where Profile.Name = 'DiageoOne External User' 
                        and Isactive = true  order by lastModifieddate desc limit 1];
        system.runAs(userObj) {
            PermissionSet permissionSetObj = [select Id from PermissionSet where Label = 'B2B Commerce User'];
            List<PermissionSetAssignment> psAssignmentLst = [select Id from PermissionSetAssignment  
                                                             where PermissionSetId = :permissionSetObj.Id and AssigneeId =:userObj.Id];
            if(psAssignmentLst == NULL || psAssignmentLst.size() == 0) {
                PermissionSetAssignment psObj = new PermissionSetAssignment();
                psObj.AssigneeId = userObj.Id;
                psObj.PermissionSetId = permissionSetObj.Id;
                insert psObj;
            }
            
            OrderSplit__c oSpilt = D1_TestDataUtility.insertOrderSplit();
            OrderSplit__c oSpilt2 = D1_TestDataUtility.insertOrderSplit();
            
            ContactPointAddress contactPoint =  D1_TestDataUtility.insertContactPointAddress();
            
            WebCart webCArtObj = [ Select Id,AccountId from WebCart where Name ='TestCart' LIMIT 1 ];
            webCArtObj.AccountId = userObj.AccountId;
            webCArtObj.Order_Split_1__c = oSpilt.Id;
            update  webCArtObj;
            
            D1_B2BCartDetailsController.getCartDetails(webCArtObj.Id);
            D1_B2BCartDetailsController.getDeliverTo();
            D1_B2BCartDetailsController.upDateOrderSplit(webCArtObj.Id,system.Today(),oSpilt.Id);
            D1_B2BCartDetailsController.updateDeliveryAddress(webCArtObj.Id,contactPoint.Id);
            D1_B2BCartDetailsController.upDateDelvryDates(webCArtObj.id);
            string cartDetails = '{"accountId":"'+userObj.AccountId+'","accountMarket":"'+userObj.AccountId+'","accountNumber":"78776", ' +
                ' "cartId":"'+webCArtObj.Id+'","customerServiceInstructions":"test456", ' +
                ' "deliveryInstructions":"test 1234556","deliveryToAddress":"8lW3O0000004CrZUAU", ' +
                ' "split1PONumber":"test po","split2PONumber":"1234"}';
            
            D1_B2BCartDetailsController.callSaveCart(cartDetails); 
            
            WebCart webcartNewObj = [Select Delivery_Instructions__c from WebCart where Id = :webCArtObj.Id limit 1];
            system.assert(webcartNewObj != null, 'webcart details not found');
            
            webCArtObj.Order_Split_2__c = oSpilt2.Id;
            //update webCArtObj;
            D1_B2BCartDetailsController.updateCartDetails(webCArtObj);
            D1_B2BCartDetailsController.getDeliverTodetails(null);
            D1_B2BCartDetailsController.upDateOrderSplit(webCArtObj.Id,system.Today(),oSpilt2.Id);
            
            delete webCArtObj;
            
            D1_B2BCartDetailsController.getPaymentTerm(webCArtObj.AccountId);           
        }
    }
    
    @isTest
    public static void testUserCanOrderToday(){
        User userObj = [select Id from User where Profile.Name = 'DiageoOne External User' 
                        and Isactive = true  order by lastModifieddate desc limit 1];
        
        system.runAs(userObj){
            Integer noOfOrders = D1_B2BCartDetailsController.getNoOfOrdersToday();
            System.assert(noOfOrders == null || noOfOrders == 0, 'Scenario 1');
        }
        
        List<D1_Setting__c> d1Settings =[ Select id, Order_Limit_Per_Day__c, Order_Limit_Per_Day_Message__c from D1_Setting__c];
        for(D1_Setting__c setting: d1Settings){
            setting.Order_Limit_Per_Day__c = 2;
            setting.Order_Limit_Per_Day_Message__c = 'test';
        }
        update d1Settings;
        
        system.runAs(userObj){
            Integer noOfOrders = D1_B2BCartDetailsController.getNoOfOrdersToday();
            System.assert(noOfOrders == null || noOfOrders == 0, 'Scenario 2');
        }
    }
}