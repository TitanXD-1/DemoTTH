/**
* @name : EDGE_AccountContactRelnTriggerHelperTest
* @description : Test Class for EDGE_AccountContactRelationTriggerHelper
* @history
* VERSION      AUTHOR          DATE            DETAIL
* 1.0          Sagar Barman    20/03/2019      Initial Development (ES20-461)
* 2.0			Rajarshi Lahiri 06/04/2022		ES20-12341(Added Tes Data for indirect ACR creation of Account )
* 3.0	 		Wribhu Bose		26/04/2022		Removed all references to Contact_Type__c field (ES20-12548 and ES20-12393)
* 4.0			Swaraj Samanta. 07/06/2022		updateDirectContactRoleFields - ES20-12654
* 5.0			Saranya L 		24/06/2022		ES20-13048
*/

@isTest
public class EDGE_AccountContactRelnTriggerHelperTest {
    
    @testSetup
    public static void createData(){
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        
        User admin = EDGE_UtilityTestClass.runAsUser('admin','System Administrator');
        admin.Available_Countries__c = 'AU';
        insert admin;  

        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId ,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AU]';
        insert pickupOption;
        
        System.debug(LoggingLevel.Debug,'Test : 29 : Limits.getQueries() :'+ Limits.getQueries());
        
        Test.startTest();
        
        List<Account> outList=new List<Account>();
        
        Account testoutlet=EDGE_UtilityTestClass.getOutletRecord();
        testoutlet.Name = 'testout00';
        testoutlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        testoutlet.Global_Channel__c = 'Off Trade';
        testoutlet.Global_Sub_Channel__c ='Retailer';
        testoutlet.Global_Segment__c = 'Discounter';
        testoutlet.Global_Sub_Segment__c = 'Modern Discounter';
        testoutlet.Country__c=countryId;
        testoutlet.ShippingStreet = '17 Asian Highway 45';
        testoutlet.ShippingCity = 'Sydney';
        testoutlet.ShippingState = 'Tasmania';
        testoutlet.ShippingPostalCode = '5668';
        testoutlet.ShippingCountry = 'Australia';
        testoutlet.ShippingCountryCode = 'AU';
        
        outList.add(testoutlet); 
        
        Account testoutlet1=EDGE_UtilityTestClass.getOutletRecord();
        testoutlet1.Name = 'testout';
        testoutlet1.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        testoutlet1.Global_Channel__c = 'Off Trade';
        testoutlet1.Global_Sub_Channel__c ='Retailer';
        testoutlet1.Global_Segment__c = 'Discounter';
        testoutlet1.Global_Sub_Segment__c = 'Modern Discounter';
        testoutlet1.Country__c=countryId;
        testoutlet1.ShippingStreet = '17 Asian Highway 45';
        testoutlet1.ShippingCity = 'Sydney';
        testoutlet1.ShippingState = 'Tasmania';
        testoutlet1.ShippingPostalCode = '5668';
        testoutlet1.ShippingCountry = 'Australia';
        testoutlet1.ShippingCountryCode = 'AU';
        
        outList.add(testoutlet1); 
        
        Account testoutlet2=EDGE_UtilityTestClass.getOutletRecord();
        testoutlet2.Name = 'testout1';
        testoutlet2.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        testoutlet2.Global_Channel__c = 'Off Trade';
        testoutlet2.Global_Sub_Channel__c ='Retailer';
        testoutlet2.Global_Segment__c = 'Discounter';
        testoutlet2.Global_Sub_Segment__c = 'Modern Discounter';
        testoutlet2.Country__c=countryId;
        testoutlet2.ShippingStreet = '17 Asian Highway 45';
        testoutlet2.ShippingCity = 'Sydney';
        testoutlet2.ShippingState = 'Tasmania';
        testoutlet2.ShippingPostalCode = '5668';
        testoutlet2.ShippingCountry = 'Australia';
        testoutlet2.ShippingCountryCode = 'AU';
        
        outList.add(testoutlet2); 
        
        insert outList;
        
        System.debug(LoggingLevel.Debug,'Test : 85 : Limits.getQueries() :'+ Limits.getQueries());
        
        //Test.startTest()        
        List<Contact> conList=new List<COntact>();
        
        Contact primcon=new Contact(FirstName='fname',
                                    LastName = 'lname',
                                    Email = 'email@gmail.com',
                                    Phone = '1234567890',AccountID=testoutlet.Id,MD_CurrentRole__c = 'Owner'); 
        conList.add(primcon);
        
        
        Contact primcon1=new Contact(FirstName='fname1',
                                     LastName = 'lname1',
                                     Email = 'email@gmail.com1',
                                     Phone = '1234567890',AccountID=testoutlet.Id); 
        conList.add(primcon1);
        insert conList;
        System.debug(LoggingLevel.Debug,'Test : 103 : Limits.getQueries() :'+ Limits.getQueries());
        Test.stopTest();
    }
    
    @isTest
    public static void testOutletContactInsertUpdate(){
        /*EDGE_UtilityTestClass.createOrgSettings();
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        */
        
        //EDGE_UtilityTestClass.createOrgSettings();
        
        List<Geography__c> countryList = [Select Id from Geography__c where Code__c = 'AU'];
        Id countryId = countryList[0].Id;
        
        User admin = EDGE_UtilityTestClass.runAsUser('admin','System Administrator');
        admin.Available_Countries__c = 'AU';
        insert admin;  
		System.debug(LoggingLevel.Debug,'Test : 124 : Limits.getQueries() :'+ Limits.getQueries());
        
        System.runAs(admin){
            
			System.debug(LoggingLevel.Debug,'Test : 126 : Limits.getQueries() :'+ Limits.getQueries());
            Account testoutlet = [Select Id from Account where Name = 'testout00' LIMIT 1 ];
			Account testoutlet2 = [Select Id from Account where Name = 'testout1' LIMIT 1 ];
            
            List<Contact> conList=new List<COntact>();
            
            Contact primcon=new Contact(FirstName='fname',
            LastName = 'lname',
            Email = 'email@gmail.com',
            Phone = '1234567890',AccountID=testoutlet.Id,MD_CurrentRole__c = 'Owner'); 
            conList.add(primcon);
            
            
            Contact primcon1=new Contact(FirstName='fname1',
            LastName = 'luoname1',
            Email = 'emailTwo@gmail.com1',
            Phone = '1234678908',AccountID=testoutlet.Id); 
            conList.add(primcon1);
            //insert conList;
            insert primcon1;
            System.assert(primcon1.id!=null,'primcon1 should not be null');
            System.debug(LoggingLevel.Debug,'Test : 147 : Limits.getQueries() :'+ Limits.getQueries());
            
            Test.startTest();
            
            //Contact primcon1 = [Select Id from Contact where Email = 'email@gmail.com' LIMIT 1 ];
            //update acr;

            //Create Sales Rep
            User salesRepUser = EDGE_UtilityTestClass.runAsUser('SalesRep','Sales Representative'); 
            salesRepUser.ManagerId = admin.id;
            salesRepUser.Available_Countries__c = 'AU';
            insert salesRepUser;
            
            System.debug(LoggingLevel.Debug,'Test : 158 : Limits.getQueries() :'+ Limits.getQueries());
            
            
            
            //insert Business Role
            Business_Role__c brtest = EDGE_UtilityTestClass.getBusinessRole();
            brtest.Global_Equivalent__c='Sales Rep';
            brtest.My_accounts_Fields_Display__c = 'Outlet_Execution_Score__c;Minimum_Product_Assortment__c;Minimum_Activation_Standards__c;OPPS OPEN;OPPS CLOSED;WPA__c';
            brtest.Country__c = countryId;
            insert brtest;

            System.debug(LoggingLevel.Debug,'Test : 146 : Limits.getQueries() :'+ Limits.getQueries());
            
            User_Business_Role__c ubrtest1 = EDGE_UtilityTestClass.getuserBusinessRole(salesRepUser, brtest);
            insert ubrtest1;
            
            System.debug(LoggingLevel.Debug,'Test : 149 : Limits.getQueries() :'+ Limits.getQueries());
            
            
            
            AccountTeamMember newAccTeamMember = new AccountTeamMember();
            newAccTeamMember.AccountId = testoutlet2.Id;
            newAccTeamMember.UserId = salesRepUser.Id;
            newAccTeamMember.AccountAccessLevel = 'Edit';
            newAccTeamMember.OpportunityAccessLevel = 'Edit';
            newAccTeamMember.ContactAccessLevel = 'Edit';
            insert newAccTeamMember;
            
            AccountContactRelation acrInsert1 = new AccountContactRelation(ContactId=primcon1.Id,AccountId=testoutlet2.Id);   
            insert acrInsert1;
            delete acrInsert1;
            //updateDirectContactRoleFields - ES20-12654
            /*AccountContactRelation acr = [SELECT ID,ContactID,IsDirect FROM AccountContactRelation WHERE ContactId =:primcon.Id AND AccountId =:testoutlet.Id];
            acr.Roles = 'Manager';
            update acr;*/
            Test.stopTest();
        }
    }

}