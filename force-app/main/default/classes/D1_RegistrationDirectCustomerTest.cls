/**
@name D1_RegistrationDirectCustomerControllerTest
@description Test Class for D1_RegistrationDirectCustomerTest
@history
VERSION     AUTHOR           DATE           DETAIL
1.0        Sudipta  Nandi   09/11/2020
2.0        Rithika          12/07/2021   Test Class Refactor(NCP-3800)
**/
@isTest
public class D1_RegistrationDirectCustomerTest {
    
    @isTest
    public static void testDirectCustomerCheck()
    {
        
        User testAdminUser;
        testAdminUser = D1_TestDataUtility.runAsUser('testAdmin','System Administrator'); 
        testAdminUser.Email = 'abc@diageo.com';
        insert testAdminUser;
       
        Id countryId = D1_TestDataUtility.setupCountry('GB');
        Geography__c geog = new Geography__c(Id= countryId);
        upsert geog;
        
        D1_Setting__c d1setting = D1_TestDataUtility.createD1Settings(geog);
        upsert d1setting;
        
        D1_User_Type__c d1UserType = D1_TestDataUtility.getD1UserType('Outlet Owner', 'Direct Buyer', d1setting.Id); 
        d1UserType.Customer_Service_Group__c = 'abc@diageo.com';
        upsert d1UserType;
        
        
        Map<Id, Set<Id>> accContactMap = new Map<Id, Set<Id>>();
        set<string> contactIdSet = new set<string>();
        
        Account distAccount = D1_TestDataUtility.getDirectCustomer();
        distAccount.KUNNR__c = '98678';
        distAccount.Primary_Sales_Rep__c = testAdminUser.id;
        insert distAccount;
        
        Contact primcon1 = D1_TestDataUtility.getContact(distAccount.Id,'Primary');
        insert primcon1;
        
        accContactMap.put(distAccount.Id,new set<Id>{primcon1.Id});
        contactIdSet.add(primcon1.Id);
        List<AccountContactRelation> acrList = new List<AccountContactRelation>();
        AccountContactRelation acrnList = D1_TestDataUtility.returnACR(distAccount.id,primcon1.id);
        acrList.add(acrnList);
        system.assert(acrList.size()>0, 'acr list not found');
        
        List<String> contactList = new List<String>();
        contactList.add(primcon1.Id);
        
        Account distAccount1 = D1_TestDataUtility.getDirectCustomer();
        distAccount1.Name = 'Test Customer Account1';
        distAccount1.AccountNumber = '104831';
        distAccount1.VAT_Number__c = '1234';
        distAccount1.KUNNR__c='98786';
        insert distAccount1;
        
        Contact primcon2 = D1_TestDataUtility.getContact(distAccount1.Id,'Primary');
        primcon2.FirstName='faname1';
        primcon2.LastName = 'laname';
        primcon2.Email = 'email1@dieo.com';
        primcon2.Phone = '123456789';
        insert primcon2;
        
        accContactMap.put(distAccount1.Id,new set<Id>{primcon2.Id});
        contactIdSet.add(primcon2.Id);
        List<AccountContactRelation> acrList1 = new List<AccountContactRelation>();
        AccountContactRelation acrnList1 = D1_TestDataUtility.returnACR(distAccount1.id,primcon2.id);
        acrList1.add(acrnList1);
        system.assert(acrList1.size()>0, 'acr list not found');
        
        contactList.add(primcon2.Id);
        
        Account distAccount2 = D1_TestDataUtility.getDirectCustomer();
        distAccount2.Name = 'Test Customer3 Account';
        distAccount2.AccountNumber = '1048311';
        distAccount2.KUNNR__c='987868';
        distAccount1.VAT_Number__c = '1234';
        insert distAccount2;
        
     	Contact primcon3 = D1_TestDataUtility.getContact(distAccount2.Id,'Primary');
        primcon3.FirstName='name1';
        primcon3.LastName = 'name';
        primcon3.Email = 'email1@abc.com';
        primcon3.Phone = '768549773';
        insert primcon3;
       
        List<AccountContactRelation> acrList2 = new List<AccountContactRelation>();
        AccountContactRelation acrnList3 = D1_TestDataUtility.returnACR(distAccount2.id,primcon3.id);
        acrList2.add(acrnList3);
        system.assert(acrList2.size()>0, 'acr list not found');
        
        contactList.add(primcon3.Id);
        
        Account distAccount3 = D1_TestDataUtility.getDirectCustomer();
        distAccount3.Name = 'Test Customer4 Account';
        distAccount3.AccountNumber = '101311';
        distAccount3.KUNNR__c = '98769';
        distAccount3.VAT_Number__c = '1234';
        upsert distAccount3;
        
        Contact primcon4 = D1_TestDataUtility.getContact(distAccount3.Id,'Primary');
        primcon4.FirstName='name1';
        primcon4.LastName = 'name';
        primcon4.Email = 'email1@xyz.com';
        primcon4.Phone = '9876543210';
        insert primcon4;
        
        PNR_Partner_Function__c pf = D1_TestDataUtility.getPartnerFunction(distAccount3,'Payer');
        pf.PNR_Sold_To__c = distAccount1.Id;
        pf.PNR_Customer_No__c = distAccount3.Id;
        insert pf;
        
        List<AccountContactRelation> acrList3 = new List<AccountContactRelation>();
        AccountContactRelation acrnList2 = D1_TestDataUtility.returnACR(distAccount3.id,primcon4.id);
        acrList3.add(acrnList2);
        system.assert(acrList3.size()>0, 'acr list not found');
        List<String> acIds  = new List<String>();
        List<String> userRoleList  = new List<String>();
            userRoleList.add('Primary'); 
        
        contactList.add(primcon4.Id);
        system.assert(contactList.size()==4,'size is 4');
       	
        //Validate Contacts
        Test.startTest();
        Boolean profileReturn = D1_RegistrationDirectCustomerController.checkProfile();
      	system.assertEquals(profileReturn,true, 'profile not updated');
        
        D1_RegistrationDirectCustomerController.processContacts(contactList,false);
        D1_RegistrationDirectCustomerController.checkDuplicates(contactList[0]);
        
        Map<Id, D1_RegistrationDirectCustomerController.DirectRegistrationWrapper> directRegistrationWrapperMap = D1_RegistrationDirectCustomerController.processContacts(contactList, true);
        system.assert(directRegistrationWrapperMap!=null,'processContacts failed');
        
        Map<Id, D1_RegistrationDirectCustomerController.DirectRegistrationWrapper> directRegistrationWrapperMapp = D1_RegistrationDirectCustomerController.setupD1Users(acIds, null);
            directRegistrationWrapperMap.putAll(directRegistrationWrapperMapp);
        system.assert(directRegistrationWrapperMapp!=null,'setupD1Users failed');
        
        D1_RegistrationDirectCustomerController.DirectRegistrationWrapper rdWrapper = D1_RegistrationDirectCustomerController.createDirectRegistrationWrapper(acrnList2);
      	system.assertEquals(rdWrapper.accountContactId,acrnList2.Id, 'Id in-correct'); 
        
        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        
        User userObj = D1_TestDataUtility.runAsUser('extuser1','DiageoOne External User');
            userObj.Username = 'email123@gmail.com';
            userObj.Available_Countries__c = 'ES';
            userObj.ContactId = primcon1.id; 
            userObj.D1_User_Type_Id__c = d1UserType.id;
           // userObj.userRoleId = [Select Id From UserRole Where Name = 'Global' Limit 1].Id;
        System.runAs ( thisUser ) {
            insert userObj;
        }
        	
        DateTime myDateTime = DateTime.newInstance(1993, 6, 6, 3, 3, 3);
       // Id shipTo = '12345';
		
        
        D1_RegistrationDirectCustomerController.DirectRegistrationWrapper rdUserWrapper = D1_RegistrationDirectCustomerController.createDirectRegistrationWrapper(userObj);
 		system.assertEquals(rdUserWrapper.contactId,userObj.contactId, 'contact id not equal');

        D1_RegistrationDirectCustomerController.sendEmail(directRegistrationWrapperMap.values());
        D1_RegistrationDirectCustomerController.processBulkRegistration(contactList);
        D1_RegistrationDirectCustomerController.checkProfile();
        D1_RegistrationDirectCustomerController.checkPrimary(primcon1.Id);
        D1_RegistrationDirectCustomerController.updateShipToAccount(distAccount3.Id,'AppSubscribed',myDateTime);
        
        String tempRoles = D1_RegistrationDirectCustomerController.removeDuplicateRoles('A;B','A');
        system.assertEquals(tempRoles,'A;B','removing duplicates failed');
        
        Test.stopTest();
    
    }
    @isTest
    public static void testDirectCustomerCheckDeletion(){
        Id countryId = D1_TestDataUtility.setupCountry('GB');
        Geography__c geog = new Geography__c(Id= countryId);
        upsert geog;
        
        D1_Setting__c d1setting = D1_TestDataUtility.createD1Settings(geog);
        upsert d1setting;
        
        D1_User_Type__c d1UserType = D1_TestDataUtility.getD1UserType('Outlet Owner', 'Direct Buyer', d1setting.Id); 
        d1UserType.Customer_Service_Group__c = 'abc@diageo.com';
        upsert d1UserType;
        
        Account distAccount = D1_TestDataUtility.getDirectCustomer();
        distAccount.KUNNR__c = '98678';
        distAccount.Deletion_Flag_from_SAP__c = true;
        insert distAccount;
        
        Contact primcon1 = D1_TestDataUtility.getContact(distAccount.Id,'Primary');
        insert primcon1;
        System.assert(primcon1 != NULL, 'conatct not found');
        //Validate Contact
        Map<String,Object> result = new Map<String,Object>();
        result = D1_RegistrationDirectCustomerController.validateContact(String.valueOf(primcon1.Id));
    }
}