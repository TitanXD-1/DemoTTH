/**
 * @name : D1_AccountTriggerHelperTest-
 * @description : Test Class for D1_AccountTriggerHelper-
 * @history                                                            -                                                        -
 * VERSION     AUTHOR            DATE              DETAIL-
 * 1.0      Saurav Paul       14/01/2021        NCP-1582-
 * 2.0      Abhishek Jethi	   15/02/2021        NCP-1584-
 **/
@isTest
public class D1_AccountTriggerHelperTest {
    @testsetup
    public static void setup(){
        User u = new User(
            profileid = [Select ID from profile where name ='System Administrator'].id,
            LastName = 'lastabhitest',
            Email = 'puser000@amamama.com',
            Username = 'puser000@amamama.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
        insert u;
        
        PermissionSet ps= [Select id from PermissionSet where name= 'D1_MDMs'];
        insert new PermissionSetAssignment(Assigneeid = u.Id, PermissionSetId= ps.id);
        
    }
    /**
     * @description 
     */    
    @isTest
    public static void populateConvDateTest(){
        String directCustRecTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Direct Customer').getRecordTypeId();
        
        Org_Setting__c orgSetting = new Org_Setting__c();
        orgSetting.Run_Triggers__c = True;
        orgSetting.Run_Validation_Rules__c = false;
        insert orgSetting;
        
        //Create Country
        final Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES');
        
        //Create Pickup Option
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[ES]';
        pickupOption.Status__c = 'Active';
        insert pickupOption;
        
        //Create Outlet record 
        Account testoutlet=EDGE_UtilityTestClass.getOutletRecord();
        testoutlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        
        Test.startTest();
        insert testoutlet;
        testoutlet.RecordTypeId = directCustRecTypeId;
        update testoutlet;
        
        String outletRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        
        Account newAcc = testoutlet;
        List<SObject> newSobj = new List<SObject>();
        newSobj.add(newAcc);
        newAcc.RecordTypeId = outletRecordTypeId;
        
        update newAcc;  
        Map<Id,sObject> newObj = new Map<Id,sObject>();
        Map<Id,sObject> oldObj = new Map<Id,sObject>();
        newObj.put(testoutlet.Id, testoutlet);
        oldObj.put(newAcc.Id, newAcc);
        D1_AccountTriggerHelper.populateConvDate(newObj,oldObj);
        D1_AccountTriggerHelper.preventAccountDelete(oldObj);
        D1_AccountTriggerHelper.setDirectCustomer(newObj,oldObj);
        D1_AccountTriggerHelper.setDirectCustomer(newSobj);
        
        Date accConvDate = Date.newInstance(1997, 08, 07);
        accConvDate = [SELECT Id,Conversion_Date__c FROM Account Limit 1].Conversion_Date__c;
        System.assertEquals(accConvDate, Date.today(), 'Date not populated');
        Test.stopTest();
    }
    /**
     * @description 
     */    
    @isTest
    public static void preventAccountDeleteTest(){
        String outletRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        
        Org_Setting__c orgSetting = new Org_Setting__c();
        orgSetting.Run_Triggers__c = True;
        orgSetting.Run_Validation_Rules__c = false;
        insert orgSetting;
        
        //Create Country
        final Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES');
        
        //Create Pickup Option
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[ES]';
        pickupOption.Status__c = 'Active';
        insert pickupOption;
        
        //Create Outlet record 
        Account testoutlet=EDGE_UtilityTestClass.getOutletRecord();
        testoutlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        testoutlet.RecordTypeId = outletRecordTypeId ;
        
            Test.startTest();
        	insert testoutlet;
            try {
                delete testoutlet; 
            }
            catch( DmlException e){  
                system.assertequals(e.getDmlStatusCode(0), 'FIELD_CUSTOM_VALIDATION_EXCEPTION', 'assertion failed');
            }
            Test.stopTest();
             
    }
    /**
     * @description 
     */    
    @isTest
    public static void deactivateContactOnCustomerDeleteTest(){
        User testAdminUser ;
        Geography__c country ;
        Pick_Up_Options__c pickupOption ;
        D1_Setting__c d1setting ;
        
        Org_Setting__c orgSetting = new Org_Setting__c();
        orgSetting.Run_Triggers__c = False;
        orgSetting.Run_Validation_Rules__c = false;
        insert orgSetting;
        
        User thisUser =  [select Id from User where Id = :UserInfo.getUserId()];
        System.runAs(thisUser){
            UserRole ur = [Select Id From UserRole Where Name = 'Global' Limit 1];
            testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');        
            testAdminUser.userRoleId = ur.id;
            insert testAdminUser;
            
            Id countryId = EDGE_UtilityTestClass.setupCountry('ES');
            country = new Geography__c(Id= countryId);
            country.isDiageoOneEnabled__c	= True;
            country.Code__c ='ES';
            upsert country;  
            
            pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
            pickupOption.Name = 'Gold[AU]';
            pickupOption.Status__c = 'Active';
            insert pickupOption;
            
            d1setting = new D1_Setting__c();
            d1setting.Name = 'ES';
            d1setting.Unique_ID__c = 'test ES';
            d1setting.Language__c = D1_Setting__c.Language__c.getDescribe().getPicklistValues()[0].getValue();
            d1setting.Market__c = country.id;
            d1setting.Default__c = true;
            insert d1setting;
            
            D1_User_Type__c indirectType = new D1_User_Type__c();
            indirectType.D1_Setting__c = d1setting.Id;
            indirectType.User_Type__c = 'Outlet/Retailers';
            insert indirectType;
            
            D1_User_Type__c directType = new D1_User_Type__c();
            directType.D1_Setting__c = d1setting.Id;
            directType.User_Type__c = 'Direct Buyer';
            insert directType;
            
            //Insert User Role
            List<D1_User_Role__c> userRoleList = new List<D1_User_Role__c>();
            userRoleList.add(new D1_User_Role__c(Access_Type__c = 'User Management'));
            userRoleList.add(new D1_User_Role__c(Access_Type__c = 'User Management'));
            userRoleList.add(new D1_User_Role__c(Access_Type__c = 'Account Balances'));
            userRoleList.add(new D1_User_Role__c(Access_Type__c = 'Ordering'));
            
            insert userRoleList;
        }
        
        system.runAs(testAdminUser){
            D1_User_Type__c d1UserType=[select id,User_Type__c from D1_User_Type__c where User_Type__c = 'Direct Buyer' ];
            
            Account testoutlet =EDGE_UtilityTestClass.getOutletRecord();
            testoutlet.Direct_Customer__c = true;            
            testoutlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
            
            Account testoutlet2 = testoutlet.clone(false,false,false,false);
            testoutlet2.Name = 'Test_Outlet 2';
            insert new List<Account>{testoutlet,testoutlet2};
                
            PNR_Partner_Function__c pf1 = new PNR_Partner_Function__c(
            	PNR_Customer_No__c = testoutlet.Id,
                PNR_Sold_To__c = testoutlet.Id,
                PNR_Type__c = 'Sold-To'
            );
            
            PNR_Partner_Function__c pf2 = new PNR_Partner_Function__c(
            	PNR_Customer_No__c = testoutlet2.Id,
                PNR_Sold_To__c = testoutlet2.Id,
                PNR_Type__c = 'Sold-To'
            );
            insert new List<PNR_Partner_Function__c>{pf1,pf2};
                
            Contact primcon1 = new Contact(FirstName='fname1',
                                         LastName = 'lname',
                                         Email = 'email1P@gmail.com',
                                         Phone = '12345672890',Contact_Type__c='Primary',AccountID=testoutlet.Id); 
            
            Contact primcon2 = new Contact(FirstName='fname1',
                                          LastName = 'lname',
                                          Email = 'emaildd1@gmail.com',
                                          Phone = '12345672890',Contact_Type__c='Secondary',AccountID=testoutlet.Id); 
            
                
           	Contact primcon3 = new Contact(FirstName='notactive',
                                         LastName = 'lname',
                                         Email =  'primcon5@gmail.com',
                                         Phone = '12345672890',Contact_Type__c='Secondary',AccountID=testoutlet2.Id); 
            
            Contact primcon4 = new Contact(FirstName='notactive',
                                         LastName = 'lname',
                                         Email =  'NOusercon6@gmail.com',
                                         Phone = '12345672890',Contact_Type__c='Secondary',AccountID=testoutlet2.Id); 
            
            insert new List<Contact>{primcon1,primcon2,primcon3,primcon4};
            List<AccountContactRelation> acrAll = [Select id from AccountContactRelation];
            for( AccountContactRelation objAC : acrAll ){
                objAC.D1_User_Role__c ='Primary';
                objAC.D1_Roles__c='Default Access;User Management';
                objAC.D1_Active__c = true;
            }
            update acrAll;
                
            AccountContactRelation objAC = new AccountContactRelation();
            objAC.D1_User_Role__c ='Primary';
            objAC.D1_Roles__c='Default Access;User Management';
            objAC.D1_Active__c = true;
            objAC.ContactId = primcon1.Id;
            objAC.AccountId = testoutlet2.Id; 
            insert objAC;
            
            List<User> userList = new List<User>();

            User externalUser3 = EDGE_UtilityTestClass.runAsUser('extuser3','DiageoOne External User');
            externalUser3.Username = 'email1234@gmail.com';
            externalUser3.Email='email12345@gmail.com';
            externalUser3.CommunityNickname = 'Mania.Test2';
            externalUser3.Available_Countries__c = 'ES';
            externalUser3.ContactId = primcon1.id; 
            externalUser3.isActive = true;
            externalUser3.LanguageLocaleKey = 'es';
            externalUser3.Effective_Account_Id__c = testoutlet.Id;
            //insert externalUser3;
            userList.add(externalUser3);
            
            User externalUser1 = EDGE_UtilityTestClass.runAsUser('extuser1','DiageoOne External User');
            externalUser1.Username = 'email123@gmail.com';
            externalUser1.Email='email1P@gmail.com';
            externalUser1.CommunityNickname = 'Mania.Test';
            externalUser1.Available_Countries__c = 'ES';
            externalUser1.ContactId = primcon2.id; 
            externalUser1.isActive = true;
            externalUser1.LanguageLocaleKey = 'es';
            externalUser1.D1_User_Type__c = d1UserType.User_Type__c;
            externalUser1.Effective_Account_Id__c =testoutlet.Id;
            //insert externalUser1;
            userList.add(externalUser1);
            
            User externalUser2 = EDGE_UtilityTestClass.runAsUser('extuser1','DiageoOne External User');
            externalUser2.Username =  primcon4.email;
            externalUser2.Email=primcon4.email;
            externalUser2.CommunityNickname = primcon4.email;
            externalUser2.Available_Countries__c = 'ES';
            externalUser2.ContactId = primcon3.id; 
            externalUser2.isActive = false;
            externalUser2.LanguageLocaleKey = 'es';
            //insert externalUser2;
            userList.add(externalUser2);
            
            User externalUser4 = EDGE_UtilityTestClass.runAsUser('extuser4','DiageoOne External User');
            externalUser4.Username = 'emaildd13@gmail.com';
            externalUser4.Email='emaildd13@gmail.com';
            externalUser4.CommunityNickname = 'Mania4.Test';
            externalUser4.Available_Countries__c = 'ES';
            externalUser4.ContactId = primcon4.id; 
            externalUser4.isActive = true;
            externalUser4.LanguageLocaleKey = 'es';
            //NCP-2042 Change: added Effective_Account_Id__c for multiple sold to
            //externalUser4.Effective_Account_Id__c =testoutlet.Id;
            //insert externalUser4;
            userList.add(externalUser4);

            insert userList;
        }
        
        system.runAs(thisUser){
            orgSetting = Org_Setting__c.getOrgDefaults();
            orgSetting.Run_Triggers__c = True;
            update orgSetting;
            Account outlet1Old = [Select id,Deletion_Flag_from_SAP__c from Account where Name = 'Test_Outlet' limit 1];
            
            Account outlet1New = [Select id, Deletion_Flag_from_SAP__c from Account where Name = 'Test_Outlet' limit 1];
            outlet1New.Deletion_Flag_from_SAP__c = true;
            
            Test.startTest();
            update outlet1New;
            
            Map<Id,sObject> newObj = new Map<Id,sObject>();
            Map<Id,sObject> oldObj = new Map<Id,sObject>();
            newObj.put(outlet1New.Id, outlet1New);
            oldObj.put(outlet1Old.Id, outlet1Old);
            Account valueNew = (Account)newObj.get(outlet1New.Id);
            Account valueOld = (Account)oldObj.get(outlet1Old.Id);
            System.assertEquals(valueNew.Deletion_Flag_from_SAP__c, True, 'assertion failed');
            System.assertEquals(valueOld.Deletion_Flag_from_SAP__c, False, 'assertion failed');
            D1_AccountTriggerHelper.deactivateContactOnCustomerDelete(newObj,oldObj);
            Test.stopTest();
        }
    }
    /**
     * @description 
     */    
    @isTest
    public static void updateContactPointAddressesTest(){
        Org_Setting__c orgSetting = new Org_Setting__c();
        orgSetting.Run_Triggers__c = True;
        orgSetting.Run_Validation_Rules__c = false;
        insert orgSetting;
        
        //Create Country
        D1_TestDataUtility.setupCountry('GB');
        Account testoutlet = D1_TestDataUtility.getDirectCustomer();
        insert testoutlet;
        
        ContactPointAddress cpa = new ContactPointAddress(
            Name = 'CPA1',
        	ParentId = testoutlet.Id,
            Account_Number__c = '12345',
            Source__c = 'Diageo One',
            AddressType = 'Billing'
        );
     	insert cpa;
        
        user u =[select id from user where lastname ='lastabhitest' limit 1];
        System.runas(u){
            Test.startTest();
            
            testoutlet.Central_Order_Block__c = 'Blocked';
            update testoutlet;
            
            ContactPointAddress cpaResult = [Select id, Status__c from ContactPointAddress where Account_Number__c = :testoutlet.KUNNR__c limit 1];
            system.assertEquals(D1_AccountTriggerHelper.CONTACT_POINT_ADDRESS_STATUS_BLOCKED, cpaResult.Status__c, 'conatct point address not updated');
            testoutlet.Central_Order_Block__c = 'Live';
            update testoutlet;
            
            cpaResult = [Select id, Status__c from ContactPointAddress where Account_Number__c = :testoutlet.KUNNR__c limit 1];
            system.assertEquals(D1_AccountTriggerHelper.CONTACT_POINT_ADDRESS_STATUS_ACTIVE, cpaResult.Status__c, 'conatct point address not updated');
            
            Test.stopTest();
        }     
    }
    
    /**
     * @description 
     */    
    @isTest
    public static void removeOrdersForDeletedFromSAPTest(){
        Org_Setting__c orgSetting = new Org_Setting__c();
        orgSetting.Run_Triggers__c = True;
        orgSetting.Run_Validation_Rules__c = false;
        insert orgSetting;
        
        //Create Country
        D1_TestDataUtility.setupCountry('GB');
        Account testoutlet = D1_TestDataUtility.getDirectCustomer();
        insert testoutlet;
        
        user u =[select id from user where lastname ='lastabhitest' limit 1];
        System.runas(u){
            Test.startTest();
            
            testoutlet.Deletion_Flag_from_SAP__c = true;
            update testoutlet;
            System.assertEquals(testoutlet.Deletion_Flag_from_SAP__c, true, 'order removal failed');
            
            Test.stopTest();
        }     
    }
    
}