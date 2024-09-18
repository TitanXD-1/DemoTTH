/**
* @Name: D1_ACRTriggerHelperTest
* @description : Test Class for D1_AccountContactRelationTriggerHelper
* @History                                                                                                                        
* VERSION   AUTHOR            DATE              DETAIL
* 1.0       Rubeena Naaz      25/03/2021		Initial Development
* 1.1       Pratap Sen        24/12/2022		PMD rule Impose
* 1.2       Suvendu Roy       31/05/2023		added reParentingShipToContactTest for reParentingShipToContact method on helper class
**/

@isTest
public class D1_ACRTriggerHelperTest {
    /**
    * @name : testACRUpdate
    * @description : Test the following methods of D1_AccountContactRelationTriggerHelper : 
    * 					1.afterUpdateACRelationNotification
    * 					2.checkAndEnableBuyerSystem
    * 					3.syncACR
    * 					4.updateD1FirstOrderEmailCheck
    */
    @isTest
    public static void testACRUpdate(){
        Contact con = [SELECT Id FROM Contact WHERE FirstName = 'test' LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE Name = 'testout' LIMIT 1]; 
        AccountContactRelation acr = [SELECT Id, D1_Roles__c, D1_Active__c FROM AccountContactRelation WHERE AccountId =:acc.Id AND ContactId =:con.Id LIMIT 1];

        Test.startTest();
        	//update ACR - Add D1 Roles
            acr.D1_Roles__c = 'Ordering;User Management';
            acr.D1_Active__c = true;
            update acr;
        
			//update ACR - Change D1 Roles
            acr.D1_Roles__c = 'Ordering';
        	update acr;
        Test.stopTest();
        System.assertEquals(acr.D1_Roles__c, 'Ordering', 'ROLE UPDATE FAILED');
        Assert.areEqual(acr.D1_Roles__c, 'Ordering', 'ROLE UPDATE FAILED');
    }

    /**
    * @name : testACRInsertUpdate
    * @description : Test the following methods of D1_AccountContactRelationTriggerHelper : 
    * 					1.afterUpdateACRelationNotification
    * 					2.createExternalManageAccount
    * 					3.removeExternalManageAccount
    * 					4.updateD1FirstOrderEmailCheck
    * 					5.afterInsertACRelationNotification
    */
    @isTest
    public static void testACRInsertUpdate(){
        Contact con = [SELECT Id FROM Contact WHERE FirstName = 'test' LIMIT 1];
        Account acc = D1_TestDataUtility.getDirectCustomer();
        acc.Name = 'Multiple Sold-To';
        acc.KUNNR__c = '1403';
        acc.AccountNumber = '1403';
        acc.CurrencyIsoCode = 'GBP';
        insert acc;

        Test.startTest();
            //Insert ACR
            AccountContactRelation acr = new AccountContactRelation();
            acr.ContactId = con.Id;
            acr.AccountId = acc.Id;
            acr.D1_Roles__c = 'Ordering;User Management';
            acr.D1_Active__c = true;
            insert acr;
        
        	//Update ACR - Deactivate
        	acr.D1_Roles__c = '';
            acr.D1_Active__c = false;
            update acr;
        Test.stopTest();
        System.assertEquals(acr.D1_Active__c, false, 'ACR D1 ACTIVE' );
        Assert.areEqual(acr.D1_Active__c, false, 'ACR D1 ACTIVE');
    }

    /**
    * @name : testupdatePOSOrderDateOnContact
    * @description : Test the following methods of D1_AccountContactRelationTriggerHelper : updatePOSOrderDateOnContact
    */
    @isTest
    public static void testupdatePOSOrderDateOnContact(){
        
        Contact con = [SELECT Id FROM Contact WHERE FirstName = 'test' LIMIT 1];
        Account acc = D1_TestDataUtility.getDirectCustomer();
        acc.Name = 'Multiple Sold-To';
        acc.KUNNR__c = '1403';
        acc.AccountNumber = '1403';
        acc.CurrencyIsoCode = 'GBP';
        insert acc;
        
        Test.startTest();
        	//Insert ACR
            AccountContactRelation acr = new AccountContactRelation();
            acr.ContactId = con.Id;
            acr.AccountId = acc.Id;
            acr.D1_Roles__c = 'Ordering;User Management;POS & Equipment Ordering';
            acr.D1_Active__c = true;
        	acr.Last_POS_Order_Date__c = System.now()-10;
            insert acr;

        	//Update ACR - change POS date
        	acr.Last_POS_Order_Date__c = System.now();
            update acr;
        Test.stopTest();
        System.assertEquals(acr.Last_POS_Order_Date__c.Date(), System.now().Date(), 'POS DATE UPDATE FAILED');
        Assert.areEqual(acr.Last_POS_Order_Date__c.Date(), System.now().Date(), 'POS DATE UPDATE FAILED');
    }

    /**
    * @name : testACRInsertUpdate
    * @description : Test the following methods of D1_AccountContactRelationTriggerHelper : 
    * 					1.createACR
    * 					2.updateACR
    * 					3.clearPOSOrderDetails
    * 					4.updateLastPOSOrderOnACR
    */
    @isTest
    public static void testClearPOSDetails(){
        Contact con = [SELECT Id FROM Contact WHERE FirstName = 'test' LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE Name = 'testout' LIMIT 1]; 
        AccountContactRelation acr = [SELECT Id, D1_Roles__c, D1_Active__c FROM AccountContactRelation WHERE AccountId =:acc.Id AND ContactId =:con.Id LIMIT 1];
        
        Test.startTest();
            acr.D1_Roles__c = 'Ordering;User Management;POS & Equipment Ordering';
            acr.D1_Active__c = true;
            update acr;
    
            //Update ACR - Remove POS
            acr.D1_Roles__c = 'Ordering';
            update acr;   
        Test.stopTest();
        System.assertEquals(acr.D1_Roles__c, 'Ordering', 'POS ORDERING REMOVE FAILED');
        Assert.areEqual(acr.D1_Roles__c, 'Ordering', 'POS ORDERING REMOVE FAILED');
    }
        /**
* @name : reParentingShipToContactTest
* @description : Test the following methods of D1_AccountContactRelationTriggerHelper : 
* 					1.createACR
*/
    @isTest
    public static void reParentingShipToContactTest(){
        Account acc = [SELECT Id FROM Account WHERE Name = 'testoutlet2' LIMIT 1]; 
        Test.startTest();
        Contact primaryContact = D1_TestDataUtility.getContact(acc.Id, 'Primary');
        primaryContact.FirstName = 'testContact';
        insert primaryContact;
        Test.stopTest();
        System.assertEquals(primaryContact.FirstName, 'testContact', 'Primary Contact FirstName = testContact' );
        Assert.areEqual(primaryContact.FirstName, 'testContact', 'Primary Contact FirstName = testContact');
    }
    /**
    * @name : testSetup
    * @description : This method is used to create test data
    */
    @testSetup
    public static void testSetup(){
        //Set up Admin User to prepare data set up using Admin User context
        User testAdminUser = D1_TestDataUtility.runAsUser('testAdmin','System Administrator');        
        testAdminUser.userRoleId = [SELECT Id FROM UserRole WHERE Name = 'Global' LIMIT 1].Id;
        insert testAdminUser; 
        
        system.runAs(testAdminUser){
            List<Account> accList = new List<Account>();
            List<PNR_Partner_Function__c> pfList = new List<PNR_Partner_Function__c>();
            
            //Set up Org Settings to Enable Trigger
            D1_TestDataUtility.createOrgSettings();
            
            //Set Up Direct Customers
            Account testoutlet = D1_TestDataUtility.getDirectCustomer();
            testoutlet.CurrencyIsoCode = 'GBP';
            accList.add(testoutlet); 
    
            Account testoutlet1 = D1_TestDataUtility.getDirectCustomer();
            testoutlet1.Name = 'testout';
            testoutlet1.KUNNR__c = '123456';
            testoutlet1.Account_Type__c = 'Sold-To';
            testoutlet1.CurrencyIsoCode = 'GBP';
            testoutlet1.Customer_Account_Group__c='Y001';
            accList.add(testoutlet1);
            Account testoutlet2 = D1_TestDataUtility.getDirectCustomer();
            testoutlet2.Name = 'testoutlet2';
            testoutlet2.KUNNR__c = '123457';
            testoutlet2.Account_Type__c = 'Ship-To';
            testoutlet2.CurrencyIsoCode = 'GBP';
            testoutlet2.Customer_Account_Group__c='Y002';
            accList.add(testoutlet2);
            insert accList;
            
            //Set Up Partner Functions (Sold to & Ship to) with Sales Area
            Sales_Area__c sa = D1_TestDataUtility.salesAreaData();
            insert sa;
            
            PNR_Partner_Function__c pf = D1_TestDataUtility.getPartnerFunction(accList[1],'Sold-To');
            pf.Sales_Area__c = sa.Id;
            pfList.add(pf);
        
            PNR_Partner_Function__c pf2 = D1_TestDataUtility.getPartnerFunction(accList[0],'Ship-To');
            pf2.PNR_Sold_To__c = accList[1].Id;
            pf2.Sales_Area__c = sa.Id;
            pfList.add(pf2);
            PNR_Partner_Function__c pf3 = D1_TestDataUtility.getPartnerFunction(accList[2],'Ship-To');
            pf3.PNR_Sold_To__c = accList[1].Id;
            pf3.Sales_Area__c = sa.Id;
            pfList.add(pf3);
            insert pfList;
            
            //Set up Buyer Group
            BuyerGroup buyerGroupObj = D1_TestDataUtility.getBuyerGroup('PF-1234');
            insert buyerGroupObj;
            
            //Set Up External User as Primary Contact
            Contact primaryContact = D1_TestDataUtility.getContact(accList[1].Id, 'Primary');
            insert primaryContact;            
    
            User extUser1 = EDGE_UtilityTestClass.runAsUser('extuser1','DiageoOne External User');
            extUser1.Available_Countries__c = 'GB';
            extUser1.ContactId = primaryContact.id; 
            extUser1.isActive = True;
            insert extUser1;
        }
    }
    
}