/**
 * @name D1_UserTriggerHelperTest
 * @description User Trigger Helper for DiageoOne
 * @history                                                                                                                        
 * VERSION   AUTHOR            DATE              DETAIL
 * 1.0
 * 2.0       Rithika           13/07/2021       Test Class Refactor(NCP-3800)
**/
@istest
public class D1_UserTriggerHelperTest {

    /**
     * @description testmethod1
     */    
    @istest
    public static void testmethod1(){
        User testAdminUser ;
        User thisUser =  [ select Id from User where Id = :UserInfo.getUserId() ];
        Geography__c country ;
        Pick_Up_Options__c pickupOption ;
        D1_User_Type__c d1UserType;
        D1_Setting__c d1setting;
        
        System.runAs(thisUser){            
            UserRole ur = [Select Id From UserRole Where Name = 'Global' Limit 1];
            
            testAdminUser = D1_TestDataUtility.runAsUser('testAdmin','System Administrator');        
            testAdminUser.userRoleId = ur.id;
            insert testAdminUser;
            
            Id countryId = D1_TestDataUtility.setupCountry('ES');
            country = new Geography__c(Id= countryId);
            upsert country;
            
            pickupOption = D1_TestDataUtility.getPickUpOption(countryId,'Outlet Prioritization','Outlet Visit Prioritization','Gold[ES]');
            insert pickupOption;
            
            String language = D1_Setting__c.Language__c.getDescribe().getPicklistValues()[0].getValue();
            d1setting = D1_TestDataUtility.createD1Settings(country);
            d1setting.Name = 'ES setting';
            d1setting.Unique_ID__c = 'test ES';
            d1setting.Language__c = language;
            insert d1setting;
            
            d1UserType = D1_TestDataUtility.getD1UserType('Outlet Owner', 'Direct Buyer', d1setting.Id);
            insert d1UserType;   
        }        
        system.runAs(testAdminUser){
            
            Account testoutlet=D1_TestDataUtility.getD1Customer();
            testoutlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
            upsert testoutlet;
            
          	Account testoutlet1=D1_TestDataUtility.getD1Customer();
            testoutlet1.Name = 'Test Customer Account 2';
            testoutlet1.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
            testoutlet1.Products_Enabled__c = 'MyDiageo';
            testoutlet1.KUNNR__c = '98986';
            upsert testoutlet1;
            
            Contact primcon1 = D1_TestDataUtility.getContact(testoutlet.Id,'Primary');
        	insert primcon1;
           
        	Contact primcon2 = D1_TestDataUtility.getContact(testoutlet1.Id,'Primary');
            primcon2.FirstName='fname123';
            primcon2.LastName = 'lname123';
            primcon2.Email = 'email145@gmail.com';
            primcon2.Phone = '123456789';
        	insert primcon2;
             
            PNR_Partner_Function__c pf = D1_TestDataUtility.getPartnerFunction(testoutlet,'Sold-To');
            pf.CurrencyIsoCode = 'EUR';
            insert pf; 
            PNR_Partner_Function__c pf1 = D1_TestDataUtility.getPartnerFunction(testoutlet1,'Sold-To');
            pf1.CurrencyIsoCode = 'EUR';
            insert pf1;
            
            List<Contact> conList=[select id from Contact where accountId=:testoutlet.Id ];
            system.assert(conList.size() > 0, 'contact list not found');
            
            List<user> userList = new List<User>();
            
           	User externalUser1 = D1_TestDataUtility.runAsUser('extuser1','DiageoOne External User');
            externalUser1.Username = 'email123@gmail.com';
            externalUser1.Available_Countries__c = 'ES';
            externalUser1.ContactId = primcon1.id; 
            externalUser1.D1_User_Type_Id__c = d1UserType.id;
            userList.add(externalUser1);
            User externalUser2 = D1_TestDataUtility.runAsUser('extuser2','DiageoOne External User');
            externalUser2.Username = 'email1235@gmail.com';
            externalUser2.Available_Countries__c = 'ES';
            externalUser2.ContactId = primcon2.id; 
            externalUser2.D1_User_Type_Id__c = d1UserType.id;
            userList.add(externalUser2);
            
            insert userList;
            system.assert(userList.size() > 0, 'user list not found');
            
            Test.startTest();
            D1_UserTriggerHelper.updateCurrency(userList);
            
            List<User> userlist1 = [Select id,accountId,CurrencyIsoCode,account.Products_Enabled__c,account.CurrencyIsoCode from User where Username = 'email1235@gmail.com'];
            Map<Id, User> usersMap = new Map<Id, User>(userlist1);
            D1_UserTriggerHelper.updateAccountCurrency(usersMap);
            
            Account acc = [Select id,isBuyer from Account where ID =: testoutlet.id LIMIT 1];
            system.assertEquals(acc.id,testoutlet.id, 'id does not match');
            Test.stopTest();
        }
    }
}