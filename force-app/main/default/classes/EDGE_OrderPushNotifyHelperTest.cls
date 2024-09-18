/**
* @Description : EDGE_OrderPushNotifyHelperTest

* @History : Test class for EDGE_OrderPushNotifyHelper                                                           

* @VERSION       AUTHOR           DATE            DETAIL
*  1.0        	 Supriya		  10/05/2022      ES20-12621(Method: OutmemDetailsTest, testpushNotificationMethodforOrder)		   				
*  2.0           Swaraj           05/09/2022      ES20-13284(Test Class Correction due to Failure)
*/
@isTest
public class EDGE_OrderPushNotifyHelperTest {
    
    @isTest
    public static void OutmemDetailsTest()
    {
        
        List<Outlet_Member__c> outMemList = new List<Outlet_Member__c>();
        //Boolean pOSord;
        Id contId;
        Pick_Up_Options__c pickupOption;
        EDGE_UtilityTestClass.createOrgSettings();
        contId = EDGE_UtilityTestClass.setupCountry('AU'); 
        pickupOption = EDGE_UtilityTestClass.getPickUpOption(contId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AU]';
        insert pickupOption;              
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        outlet.Country__c = contId;
        insert outlet;
        System.assert(outlet.id!=null,'outlet Id should not be null');   
        Test.StartTest();
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','Sales Manager');
        insert testAdminUser; 
        User userRec = EDGE_UtilityTestClass.runAsUser('TestDummy' , 'Sales Representative');
        userRec.ManagerId = testAdminUser.Id;
        insert userRec;
        System.assert(userRec.id!=null,'userRec Id should not be null');
        
        Territory_Hierarchy__c buTerHierarchy = EDGE_UtilityTestClass.getTerritoryHierarchy(contId, 'Business Unit');
        insert buTerHierarchy;
        
        Territory_Hierarchy__c saTerHierarchy = EDGE_UtilityTestClass.getTerritoryHierarchy(contId, 'Sales Area');
        saTerHierarchy.Parent_BU__c = buTerHierarchy.Id;
        insert saTerHierarchy;
        
        Territory_Hierarchy__c rgTerHierarchy = EDGE_UtilityTestClass.getTerritoryHierarchy(contId, 'Region');
        rgTerHierarchy.Parent_BU__c = saTerHierarchy.Id;
        insert rgTerHierarchy;
        
        Territory__c primaryTerr = EDGE_UtilityTestClass.getTerritoryRec();
        primaryTerr.Territory_Type__c = 'Sales';
        primaryTerr.Region__c = rgTerHierarchy.Id;
        insert primaryTerr; 
        
        Outlet_Territory__c outlTer = EDGE_UtilityTestClass.getOutltTerritory(outlet.Id, primaryTerr.Id);
        outlTer.Active__c='Active';
        insert outlTer; 
        
        Outlet_Member__c omTest = EDGE_UtilityTestClass.getOutletMemberRecord(outlet.Id, userRec.id, 'Primary');
        Outlet_Member__c omTest1 = EDGE_UtilityTestClass.getOutletMemberRecord(outlet.Id, testAdminUser.id, 'Secondary');
        
        outMemList.add(omTest);
        outMemList.add(omTest1);
        insert outMemList;
        
        
        
        Account wholesaler = EDGE_UtilityTestClass.getDistriAccRec();
        wholesaler.ShippingCountry = 'Australia';
        insert wholesaler;
        
        List<Order__c> orderLst = new List<Order__c>();
        
        Order__c trnsfrOrder = EDGE_UtilityTestClass.getTrnsfrOrder(userRec.id, outlet.Id, wholesaler.Id);
        trnsfrOrder.Status__c = 'Submitted';
        trnsfrOrder.Comments__c = 'hello';
        orderLst.add(trnsfrOrder);
        
        Order__c trnsfrOrder1 = EDGE_UtilityTestClass.getTrnsfrOrder(userRec.id, outlet.Id, wholesaler.Id);
        trnsfrOrder1.Status__c = 'Submitted';
        trnsfrOrder1.Comments__c = 'hello';
        orderLst.add(trnsfrOrder1); 
        insert orderLst;
        
        EDGE_OrderPushNotifHelper.populateOutMemDetails(orderLst,false); 
        Test.StopTest();
        
        
        
    }
    
    @isTest
    public static void testpushNotificationMethodforOrder()
    {
        
        User newUser = EDGE_UtilityTestClass.runAsUser('TestUser', 'Quality Manager');
        
        insert newUser;
        System.assert(newUser.id!=null,'newUser Id should not be null');
        List<Id> userList = new List<Id>();
        userList.add(newUser.Id);
        Map<String,Object> custom = new Map<String,Object>();
        String msgBody = 'Test Message';
        custom.put('User ID', newUser.Id); 
        EDGE_orderPushNotifHelper.pushNotificationMethodforOrder(userList, msgBody, custom);
    }
}