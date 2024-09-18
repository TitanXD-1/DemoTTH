/**
*@	Name: EDGE_AccountTriggerHelperTest
*@	History                                                            
                                                          
*@	VERSION     AUTHOR           DATE            DETAIL
*@	1.0         Dipanjan Das     21/02/2019      Test Class for EDGE_AccountTriggerHelper
*@	1.1         Saurav Paul     16/04/2019     Test Class for CheckMandatoryFields
*@	1.2			Shivam Chauhan	 18/07/2023		142554 - EDGE static code violation for the classes_SFDC_Tech Debt
**/
@isTest
public class EDGE_AccountTriggerHelperTest{
    
    @isTest
    public static void testCreateFieldChangeRequest(){        
        //Variables
        Id contId;
        User salesRep;
        Pick_Up_Options__c pickupOption;
        Account outletchk;
        Account outlet;
        
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        insert testAdminUser; 
        
        EDGE_UtilityTestClass.createOrgSettings();
        contId = EDGE_UtilityTestClass.setupCountry('AUT'); 
        System.assert(contId != null,'contId should not be null');
        
        //Market_Setting__c newMs = new Market_Setting__c(Name='Australia MS',Geography__c= contId, Status__c='Editable & Mandatory - Sales Manager Approval Required');
        //insert newMs;
        //System.assert(newMs != null);
        
        Market_Cycle__c marCycle = EDGE_UtilityTestClass.getMarketCycle(contId);
        marCycle.Number_of_Week__c = 52;
        marCycle.Start_Date__c = Date.Today(); 
        marCycle.End_Date__c = Date.Today().addDays(360);
        insert marCycle;  

        
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        pickupOption = EDGE_UtilityTestClass.getPickUpOption(contId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AUT]';
        pickupOption.RecordTypeId = pickupRecordType;
        pickupOption.Status__c = 'Active';
        insert pickupOption;
        outlet = EDGE_UtilityTestClass.getOutletRecord();  
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;    
        outlet.Minimum_Activation_Standards__c = 90.00;
        outlet.Minimum_Product_Assortment__c = 40.00;
        outlet.Global_Channel__c = 'Off Trade';
        outlet.Global_Sub_Channel__c ='Retailer';
        outlet.Global_Segment__c = 'Discounter';
        outlet.Global_Sub_Segment__c = 'Modern Discounter';
        outlet.Status__c ='Active';
        outlet.Country__c = contId;
        Test.startTest();
        insert outlet;
        
        system.runAs(testAdminUser){
            User salesManager = EDGE_UtilityTestClass.runAsUser('salesRep1','Sales Representative');
            salesManager.Available_Countries__c = 'AU';
            salesManager.ManagerId = testAdminUser.id;
            insert salesManager;  
            System.assert(salesManager.Id!=null,'SalesManager should not be null');
            
            salesRep = EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
            salesRep.Available_Countries__c = 'AU';
            salesRep.ManagerId = testAdminUser.id;
            insert salesRep; 
            System.assert(salesRep.Id!=null, 'SalesRep should not be null');
            
            AccountTeamMember newAccTeamMember = new AccountTeamMember();
            newAccTeamMember.AccountId = outlet.Id;
            newAccTeamMember.UserId = salesRep.Id;
            newAccTeamMember.AccountAccessLevel = 'Edit';
            newAccTeamMember.OpportunityAccessLevel = 'Edit';
            newAccTeamMember.ContactAccessLevel = 'Edit';
            insert newAccTeamMember;
            System.assert(newAccTeamMember.Id!=null,'Account Team Member record should not be null');
        }
        
        
        
        System.runAs(salesRep){
            EDGE_UtilityClass.stopTriggerToRun = false;
            outletchk =[Select Id,Status__c from Account where Id= :outlet.Id ];      
            outletchk.Status__c ='Closed';
            //update outletchk;
            //Field_Change_Request__c fcrCheck = [Select Id,Status__c from Field_Change_Request__c where Outlet__c =: outletchk.Id];
            //system.assertNotEquals(fcrCheck.Id, '','');
        }
        Test.stopTest();
    }
    
    @isTest
    public static void testupdateAccountGeoCodes(){
        
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AUT');
        EDGE_UtilityTestClass.createOrgSettings();
        
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AUT]';
        pickupOption.RecordTypeId = pickupRecordType;
        pickupOption.Status__c = 'Active';
        insert pickupOption;
        system.assert(pickupOption.Id != null,'PickupOption should not be null');
        
        Account outlet = EDGE_UtilityTestClass.getOutletRecord(); 
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        outlet.Global_Channel__c = 'Off Trade';
        outlet.Global_Sub_Channel__c ='Retailer';
        outlet.Global_Segment__c = 'Discounter';
        outlet.Global_Sub_Segment__c = 'Modern Discounter';
        insert outlet;  
        system.assert(outlet.Id != null, 'Outlet should not be null');
        
        outlet = [SELECT Id FROM Account WHERE Id = :outlet.Id];
        outlet.Geolocation__Latitude__s = 22.7458;
        outlet.Geolocation__Longitude__s = 88.6654;
        update outlet;
        
        outlet = [SELECT Id, BillingLatitude, BillingLongitude, Geolocation__Latitude__s, Geolocation__Longitude__s FROM Account WHERE Id = :outlet.Id];
        
        //system.assertEquals(outlet.BillingLatitude, outlet.Geolocation__Latitude__s);
        //system.assertEquals(outlet.BillingLongitude, outlet.Geolocation__Longitude__s);
        
        delete outlet;
        
        undelete outlet;
    }
    
    @isTest
    public static void testupdateOutletExecutionScore(){
        
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AUT');
        EDGE_UtilityTestClass.createOrgSettings();
        
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AUT]';
        pickupOption.RecordTypeId = pickupRecordType;
        pickupOption.Status__c = 'Active';
        insert pickupOption;
        system.assert(pickupOption.Id != null,'PickupOption should not be null');
        
        Geography__c geo = [SELECT Id FROM Geography__c WHERE Id =:geographyId LIMIT 1];
        geo.Minimum_Product_Assortment__c  = 65.00; 
        geo.Minimum_Activation_Standards__c  = 35.00;
        update geo;
        
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();  
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        outlet.Minimum_Activation_Standards__c = 90.00;
        outlet.Minimum_Product_Assortment__c = 40.00;
        outlet.Global_Channel__c = 'Off Trade';
        outlet.Global_Sub_Channel__c ='Retailer';
        outlet.Global_Segment__c = 'Discounter';
        outlet.Global_Sub_Segment__c = 'Modern Discounter';
        insert outlet;  
        system.assert(outlet.Id != null,'Outlet should not be null');
        outlet = [SELECT Id, Outlet_Execution_Score__c FROM Account WHERE Id = :outlet.Id];
        //system.assertEquals(outlet.Outlet_Execution_Score__c, 57.50);
        
    }
    
    @isTest
    public static void testCheckMandatoryFields(){
        
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AUT');
        EDGE_UtilityTestClass.createOrgSettings();
        
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AUT]';
        pickupOption.RecordTypeId = pickupRecordType;
        pickupOption.Status__c = 'Active';
        insert pickupOption;
        Account prospect = EDGE_UtilityTestClass.getProspectRecord(pickupOption.Id);
        prospect.BillingState = '';
        
        Test.startTest();
        try{
            insert prospect;
        }catch(Exception ex){
            //Checking Primary Supplier Validation Rule
            System.Assert(ex.getMessage()!= null,'exception message should not be null');
        }
        Test.stopTest();
    }
    
    @isTest
    public static void updateTemporaryDateTest(){
        
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
        System.assert(countryId != null,'CountryId should not be null');
        EDGE_UtilityTestClass.createOrgSettings();
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c oultlVstPriPkUp = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
        oultlVstPriPkUp.Name = 'Gold[AUT]';
        oultlVstPriPkUp.RecordTypeId = pickupRecordType;
        oultlVstPriPkUp.Status__c = 'Active';
        insert oultlVstPriPkUp; 
        
        Account accObj = EDGE_UtilityTestClass.getOutletRecord();
        accObj.Outlet_Visit_Prioritisation_Grade__c = oultlVstPriPkUp.Id;
        accObj.Status__c = 'Temporarily Closed';
        accObj.Start_Date__c = System.today();
        accObj.End_Date__c = System.today().addDays(10);
        insert accObj;
        
        Test.startTest();
        accObj.Status__c = 'Active';
        update accObj;
        Test.stopTest();
        
    }
    @isTest
    public static void testUpdateHybridFlag(){
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
        System.assert(countryId != null,'CountryId should not be null');
        EDGE_UtilityTestClass.createOrgSettings();
        
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c oultlVstPriPkUp = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
        oultlVstPriPkUp.Name = 'Gold[AUT]';
        oultlVstPriPkUp.RecordTypeId = pickupRecordType;
        oultlVstPriPkUp.Status__c = 'Active';
        insert oultlVstPriPkUp; 
        
        Account accObj = EDGE_UtilityTestClass.getOutletRecord();       
        accObj.Outlet_Visit_Prioritisation_Grade__c = oultlVstPriPkUp.Id;
        insert accObj;
        accObj.Hybrid__c = true;
        update accObj;
        
        Account chldAccObj = EDGE_UtilityTestClass.getOutletRecord();
        chldAccObj.Name = 'Test Child Outlet';
        chldAccObj.Global_Channel__c = 'On Trade';
        chldAccObj.Global_Sub_Channel__c = 'On Trade';
        chldAccObj.Global_Segment__c = 'Nightclub';
        chldAccObj.Global_Sub_Segment__c = 'Modern Nightclub';
        chldAccObj.Outlet_Visit_Prioritisation_Grade__c = oultlVstPriPkUp.Id;
        chldAccObj.Parent_Outlet__c = accObj.Id;
        chldAccObj.Hybrid__c = False;
        Test.startTest();
        insert chldAccObj;
        //update chldAccObj ;
        Test.stopTest();
        Account chAccobj;
        chAccobj  = [SELECT Id,Hybrid__c FROM Account WHERE Id  = :chldAccObj.Id];  
        //System.assertEquals(chAccobj.Hybrid__c, true);
    }
    @isTest
    public static void testUpdateHybridFlagUpdate(){
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
        System.assert(countryId != null,'CountryId should not be null');
        EDGE_UtilityTestClass.createOrgSettings();
        
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c oultlVstPriPkUp = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
        oultlVstPriPkUp.Name = 'Gold[AUT]';
        oultlVstPriPkUp.RecordTypeId = pickupRecordType;
        oultlVstPriPkUp.Status__c = 'Active';
        insert oultlVstPriPkUp;
        
        Account accObj = EDGE_UtilityTestClass.getOutletRecord();
        accObj.Outlet_Visit_Prioritisation_Grade__c = oultlVstPriPkUp.Id;
        insert accObj;
        
        Account chldAccObj = EDGE_UtilityTestClass.getOutletRecord();
        chldAccObj.Name = 'Test Child Outlet';
        chldAccObj.Global_Channel__c = 'On Trade';
        chldAccObj.Global_Sub_Channel__c = 'On Trade';
        chldAccObj.Global_Segment__c = 'Nightclub';
        chldAccObj.Global_Sub_Segment__c = 'Modern Nightclub';
        chldAccObj.Outlet_Visit_Prioritisation_Grade__c = oultlVstPriPkUp.Id;
        chldAccObj.Parent_Outlet__c = accObj.Id;
        insert chldAccObj;
        
        chldAccObj.Parent_Outlet__c = null;
        Test.startTest();
        update chldAccObj;
        Test.stopTest();
        Account chAccobj  = [SELECT Id,Hybrid__c FROM Account WHERE Id  = :chldAccObj.Id];
        System.assertEquals(chAccobj.Hybrid__c, false,'Hybrid condition doesn\'t match');
    }
    @isTest
    public static void testUpdateReportingUnit(){
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
        System.assert(countryId != null,'CountryId should not be null');
        EDGE_UtilityTestClass.createOrgSettings();
        
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c oultlVstPriPkUp = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
        oultlVstPriPkUp.Name = 'VSTPKUP[AUT]';
        oultlVstPriPkUp.RecordTypeId = pickupRecordType;
        oultlVstPriPkUp.Status__c = 'Active';
        insert oultlVstPriPkUp;
        
        String pickupRecordType1 = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Default Pickup').getRecordTypeId();
        Pick_Up_Options__c respGrpPkUp = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Reporting Unit');
        respGrpPkUp.Name = 'Key Account[AUT]';
        respGrpPkUp.RecordTypeId = pickupRecordType1;
        respGrpPkUp.Status__c = 'Active';
        insert respGrpPkUp;
        
        Account ownerAcc = EDGE_UtilityTestClass.getOwnerOperatorAccount();
        ownerAcc.IsOwner__c = true ;
        ownerAcc.Responsible_Group__c = respGrpPkUp.Id;
        User user = EDGE_UtilityTestClass.runAsUser('NewUser', 'System Administrator');
        insert user;
        ownerAcc.Person_Responsible__c = user.Id;
        insert ownerAcc;
        
        Account accObj = EDGE_UtilityTestClass.getOutletRecord();
        accObj.Outlet_Visit_Prioritisation_Grade__c = oultlVstPriPkUp.Id;
        accObj.ParentId = ownerAcc.Id;
        accObj.Independent_of_Owner__c = false;
        Test.startTest();
        insert accObj;
        Test.stopTest();
        Account accUpdtObj  = [SELECT Id,Reporting_Unit__c FROM Account WHERE Id =: accObj.Id]; //NOPMD
        //System.assert(accUpdtObj.Reporting_Unit__c != null,'No Account Record Present');
    }
    @isTest
    public static void updateReportingUnitTest(){
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        System.assert(countryId != null,'CountryId should not be null');
        EDGE_UtilityTestClass.createOrgSettings();
        
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c oultlVstPriPkUp = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
        oultlVstPriPkUp.Name = 'VSTPKUP[AU]';
        oultlVstPriPkUp.RecordTypeId = pickupRecordType;
        oultlVstPriPkUp.Status__c = 'Active';
        insert oultlVstPriPkUp;
        
        String pickupRecordType1 = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Default Pickup').getRecordTypeId();
        Pick_Up_Options__c respGrpPkUp = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Reporting Unit');
        respGrpPkUp.Name = 'Key Accounts[AU]';
        respGrpPkUp.RecordTypeId = pickupRecordType1;
        respGrpPkUp.Status__c = 'Active';
        insert respGrpPkUp;
        
        User user = EDGE_UtilityTestClass.runAsUser('NewUser1', 'System Administrator');
        insert user;
        
        Account outletParent = EDGE_UtilityTestClass.getOwnerOperatorAccount();
        outletParent.BillingCountry = 'Australia';
        outletParent.Name = 'test operator';
        outletParent.IsOwner__c = true;
        outletParent.Independent_of_Operator__c = true;
        outletParent.Person_Responsible__c = user.Id;
        insert outletParent;
        
        Account outletBulk = EDGE_UtilityTestClass.getOutletRecord();
        outletBulk.Name = 'test Outlet Bulk';
        outletBulk.ParentId = outletParent.Id;
        outletBulk.Hybrid__c = true;
        outletBulk.Global_Channel__c = 'On Trade';
        outletBulk.Global_Sub_Channel__c = 'On Trade';
        outletBulk.Global_Segment__c = 'Bar';
        outletBulk.Global_Sub_Segment__c = 'Modern Bar';
        outletBulk.Independent_of_Owner__c = false;
        outletBulk.Outlet_Visit_Prioritisation_Grade__c = oultlVstPriPkUp.Id;
        Test.startTest();
        insert outletBulk;
        
        Account outletObj = EDGE_UtilityTestClass.getOutletRecord();
        outletObj.Name = 'test Reporting Unit';
        outletObj.ParentId = outletParent.Id;
        outletObj.Hybrid__c = true;
        outletObj.Independent_of_Owner__c = false;
        outletObj.Outlet_Visit_Prioritisation_Grade__c = oultlVstPriPkUp.Id;
        insert outletObj;
        outletObj.Hybrid__c = false;
        update outletObj;
        Test.stopTest();
        
        Account accUpdtObj  = [SELECT Id,Reporting_Unit__c FROM Account WHERE Id =: outletObj.Id];  //NOPMD
        //System.assert(accUpdtObj.Reporting_Unit__c != null);
        
    }
    @isTest 
    public static void testchangeContractAssignment(){
        
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUS');
        System.assert(countryId != null,'CountryId should not be null');
        EDGE_UtilityTestClass.createOrgSettings();
        
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c oultlVstPriPkUp = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
        oultlVstPriPkUp.Name = 'VSTPKUP[AUS]';
        oultlVstPriPkUp.RecordTypeId = pickupRecordType;
        oultlVstPriPkUp.Status__c = 'Active';
        insert oultlVstPriPkUp;
        
        User user = EDGE_UtilityTestClass.runAsUser('NewUser1', 'System Administrator');
        insert user;
        
        Account operatorObj = EDGE_UtilityTestClass.getOwnerOperatorAccount();
        operatorObj.BillingCountry = 'Australia';
        operatorObj.Name = 'test operator';
        operatorObj.IsOperator__c = true;
        operatorObj.Independent_of_Operator__c = false;
        operatorObj.Person_Responsible__c = user.Id;
        insert operatorObj;
        
        Account oprObj = EDGE_UtilityTestClass.getOwnerOperatorAccount();
        oprObj.Name = 'Operator Aus';
        oprObj.IsOperator__c = true;
        oprObj.Independent_of_Operator__c = false;
        oprObj.Person_Responsible__c = user.Id;
        insert oprObj;
        
        Account outletObj = EDGE_UtilityTestClass.getOutletRecord();
        outletObj.Name = 'test Reporting Unit1';
        outletObj.Operator__c = operatorObj.id;
        outletObj.Independent_of_Operator__c = false;
        outletObj.Status__c= 'Active';
        outletObj.Outlet_Visit_Prioritisation_Grade__c = oultlVstPriPkUp.Id;
        insert outletObj;
        
        outletObj.Operator__c = oprObj.id;
        update outletObj;
        
        Test.startTest();
        
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('A&P').getRecordTypeId();
        Contract contobj = EDGE_UtilityTestClass.getContract(outletObj.Id,contractRecordTypeId);
        contobj.AccountId = outletObj.Operator__c;
        contobj.StartDate = System.today()-3;
        insert contobj;
        contobj.Status = 'Active';
        update contobj;
        
        Outlet_Contract__c outletContract = new Outlet_Contract__c();
        outletContract.Contract__c = contObj.id;
        outletContract.Outlet__c = outletObj.Id;
        outletContract.Status__c = 'Active';
        insert outletContract;
        Test.stopTest();
    }
    
/**
*@	Method  : testSegmentDependencyValidation
*@	Purpose : Test method of segmentDependencyValidation
**/
    @isTest
    public static void testSegmentDependencyValidation(){
       
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        Market_Setting__c marketSettings = EDGE_UtilityTestClass.getMarketSetting(countryId);
        marketSettings.Local_Segmentation_Validation__c = true;
        marketSettings.Local_Segmentation2_Validation__c = true;
        insert marketSettings;
        
        EDGE_UtilityTestClass.createOrgSettings();        
        System.assert(countryId != null,'CountryId should not be null');
        
        Market_Cycle__c marCycle = EDGE_UtilityTestClass.getMarketCycle(countryId);
        marCycle.Number_of_Week__c = 52;
        marCycle.Start_Date__c = Date.Today();
        marCycle.End_Date__c = Date.Today().addDays(360);
        insert marCycle;        
        
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c oultlVstPriPkUp = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
        oultlVstPriPkUp.Name = 'VSTPKUP[AU]';
        oultlVstPriPkUp.RecordTypeId = pickupRecordType;
        oultlVstPriPkUp.Status__c = 'Active';
        insert oultlVstPriPkUp;
        
        String pickupRecordType1 = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Local Segment').getRecordTypeId();
        Pick_Up_Options__c localpickup = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Local-Segment1');
        localpickup.Name = 'Mainstream [AU]';
        localpickup.RecordTypeId = pickupRecordType1;
        localpickup.Status__c = 'Active';
        insert localpickup;
        
        String pickupRecordType2 = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Default Pickup').getRecordTypeId();
        Pick_Up_Options__c localpickup1 = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Local-Segment2');
        localpickup1.Name = 'Pub Attached [AU]';
        localpickup1.RecordTypeId = pickupRecordType2;
        localpickup1.Status__c = 'Active';
        insert localpickup1;
        
        String pickupRecordType3 = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Default Pickup').getRecordTypeId();
        Pick_Up_Options__c localpickup2 = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Local-Segment2');
        localpickup2.Name = 'Test[AU]';
        localpickup2.RecordTypeId = pickupRecordType3;
        localpickup2.Status__c = 'Active';
        insert localpickup2;
        
        Account ownerAccount = EDGE_UtilityTestClass.getOutletRecord();
        ownerAccount.Name = 'test operator';
        ownerAccount.Outlet_Visit_Prioritisation_Grade__c = oultlVstPriPkUp.Id;
        ownerAccount.BillingCountryCode = 'AU';
        ownerAccount.Global_Channel__c = 'Off Trade';
        ownerAccount.Global_Sub_Channel__c = 'Retailer';
        ownerAccount.Global_Segment__c = 'Convenience';
        ownerAccount.Global_Sub_Segment__c = 'Modern Convenience';
        ownerAccount.Local_Segment1__c = localpickup.Id;
        ownerAccount.Local_Segment2__c = localpickup1.Id;
        insert ownerAccount;
        
       /* Account ownerAccount1 = EDGE_UtilityTestClass.getOutletRecord();
        ownerAccount1.Name = 'test operator1';
        ownerAccount1.Outlet_Visit_Prioritisation_Grade__c = oultlVstPriPkUp.Id;
        ownerAccount1.BillingCountryCode = 'AU';
        ownerAccount1.Global_Channel__c = 'Off Trade';
        ownerAccount1.Global_Sub_Channel__c = 'Retailer';
        ownerAccount1.Global_Segment__c = 'Convenience';
        ownerAccount1.Global_Sub_Segment__c = 'Modern Convenience';
        //ownerAccount.Local_Segment1__c = localpickup.Id;
        //ownerAccount.Local_Segment2__c = localpickup1.Id;
        insert ownerAccount1;*/
        Test.startTest();
        try{
            ownerAccount.Local_Segment2__c = localpickup2.Id; 
            update ownerAccount;
            ownerAccount.Local_Segment1__c = null; 
            update ownerAccount;
        } catch(Exception ex){
            System.debug(LoggingLevel.debug,ex.getMessage());
        }
        Test.stopTest();
    }
    
/**
*@	Method  : testSegmentDependencyValidation
*@	Purpose : Test method of segmentDependencyValidation
**/
    @isTest
    public static void testSegmentDependencySpain(){
        
        Id countryId = EDGE_UtilityTestClass.setupCountry('ES');
        Market_Setting__c marketSettings = EDGE_UtilityTestClass.getMarketSetting(countryId);
        marketSettings.Local_Segmentation_Validation__c = true;
        insert marketSettings;
        
        EDGE_UtilityTestClass.createOrgSettings();        
        System.assert(countryId != null,'CountryId should not be null');
        
        Market_Cycle__c marCycle = EDGE_UtilityTestClass.getMarketCycle(countryId);
        marCycle.Number_of_Week__c = 52;
        marCycle.Start_Date__c = Date.Today();
        marCycle.End_Date__c = Date.Today().addDays(360);
        insert marCycle;        
        
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c oultlVstPriPkUp = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
        oultlVstPriPkUp.Name = 'VSTPKUP[ES]';
        oultlVstPriPkUp.RecordTypeId = pickupRecordType;
        oultlVstPriPkUp.Status__c = 'Active';
        insert oultlVstPriPkUp;
        
        String pickupRecordType1 = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Local Segment').getRecordTypeId();
        Pick_Up_Options__c localpickup = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Local-Segment1');
        localpickup.Name = 'Nightclub[ES]';
        localpickup.RecordTypeId = pickupRecordType1;
        localpickup.Status__c = 'Active';
        insert localpickup;
        
        String pickupRecordType2 = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Local Segment').getRecordTypeId();
        Pick_Up_Options__c localpickup1 = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Local-Segment1');
        localpickup1.Name = 'Bars[ES]';
        localpickup1.RecordTypeId = pickupRecordType2;
        localpickup1.Status__c = 'Active';
        insert localpickup1;
        
        Account ownerAccount = EDGE_UtilityTestClass.getOutletRecord();
        ownerAccount.Name = 'test operator';
        ownerAccount.Outlet_Visit_Prioritisation_Grade__c = oultlVstPriPkUp.Id;
        ownerAccount.BillingCountryCode = 'AU';
        ownerAccount.Global_Channel__c = 'On Trade';
        ownerAccount.Global_Sub_Channel__c = 'On Trade';
        ownerAccount.Global_Segment__c = 'Nightclub';
        ownerAccount.Global_Sub_Segment__c = 'Modern Nightclub';
        //ownerAccount.Local_Segment1__c = localpickup.Id;
        insert ownerAccount;
        Test.startTest();
        try{
            ownerAccount.Local_Segment1__c = localpickup1.Id; 
            update ownerAccount;
        } catch(Exception ex){
            System.debug(LoggingLevel.debug,ex.getMessage());
        }
        
        Test.stopTest();
        
    }
    
    @isTest
    public static void testprospectApprovalProcess(){
        
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        
        User newUser = new User();
        newUser.Alias = 'testrest';
        newUser.Email = 'test.rest@edgeorg.com';
        newUser.EmailEncodingKey  = 'UTF-8';
        newUser.LastName = 'Test123';
        newUser.FirstName = 'example';
        newUser.LanguageLocaleKey  = 'en_US';
        newUser.LocaleSidKey = 'en_US';
        newUser.ProfileId = [select Id from Profile where Name ='System Administrator' limit 1].Id;
        newUser.TimeZoneSidKey = 'America/Chicago';
        newUser.Username = 'Test123@test' + Math.round(Math.random() * 10000) + '.com'; 
        newUser.Available_Countries__c = 'AU';
        insert newUser;
        
        User newUser1 = new User();    
        newUser1.Alias = 'terest1';
        newUser1.Email = 'test.rest1@edgeorg.com';
        newUser1.EmailEncodingKey  = 'UTF-8';
        newUser1.LastName = 'Test1234';
        newUser1.FirstName = 'example1';
        newUser1.LanguageLocaleKey  = 'en_US';
        newUser1.LocaleSidKey = 'en_US';
        newUser1.ProfileId = [select Id from Profile where Name ='System Administrator' limit 1].Id;
        newUser1.ManagerId = newUser.Id;
        newUser1.TimeZoneSidKey = 'America/Chicago';
        newUser1.Username = 'Test123@test' + Math.round(Math.random() * 10000) + '.com'; 
        newUser1.Available_Countries__c = 'AU';
        insert newUser1;
        
        Market_Setting__c marketSettings = EDGE_UtilityTestClass.getMarketSetting(countryId);
        marketSettings.Local_Segmentation_Validation__c = true;
        marketSettings.Auto_Add_to_Territory__c = True;
        marketSettings.Prospect_Approver__c = 'Sales Manager & MDM Approval Required';
        insert marketSettings;
        
        
        
        
        EDGE_UtilityTestClass.createOrgSettings();
        
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c oultlVstPriPkUp = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
        oultlVstPriPkUp.Name = 'VSTPKUP[AU]';
        oultlVstPriPkUp.RecordTypeId = pickupRecordType;
        oultlVstPriPkUp.Status__c = 'Active';
        insert oultlVstPriPkUp;
        system.assert(oultlVstPriPkUp.id != null,'Outlet Visit Prioritization should not be null');
        
        String outletRecordType = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId(); //NOPMD
        Account prospectAccount = EDGE_UtilityTestClass.getProspectRecord(oultlVstPriPkUp.id);
        prospectAccount.BillingStreet = 'testStreet';
        prospectAccount.Global_Channel__c = 'off Trade';
        prospectAccount.Global_Sub_Channel__c = 'Retailer';
        prospectAccount.Global_Segment__c = 'Hypermarket';
        prospectAccount.Global_Sub_Segment__c = 'Modern Hypermarket';
        prospectAccount.Status__c = 'Active';
        prospectAccount.BillingCity = 'Tasmania';
        prospectAccount.BillingCountry = 'Australia';
        Test.startTest();
        System.runAs(newUser1){
            insert prospectAccount;
            
            prospectAccount.Status__c = 'Approved';
            try{
                update prospectAccount;
            }
            catch(Exception e){
                System.debug(LoggingLevel.debug,e.getMessage());
            }            
        }
        Test.stopTest();
    } 
    
    @isTest
    public static void testAutoAddToTerr(){
        
       // Test.startTest();
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        Market_Setting__c marketSettings = EDGE_UtilityTestClass.getMarketSetting(countryId);
        marketSettings.Local_Segmentation_Validation__c = true;
        marketSettings.Auto_Add_to_Territory__c = True;
        insert marketSettings;
        User user1 = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        user1.FirstName = 'Shahbaz';
        user1.LastName = 'Khan';
        insert user1;
        
        User newUser = new User();
        newUser.Alias = 'testrest';
        newUser.Email = 'test.rest@edgeorg.com';
        newUser.EmailEncodingKey  = 'UTF-8';
        newUser.LastName = 'Test123';
        newUser.FirstName = 'example';
        newUser.LanguageLocaleKey  = 'en_US';
        newUser.LocaleSidKey = 'en_US';
        newUser.ProfileId = [select Id from Profile where Name ='System Administrator' limit 1].Id;
        newUser.TimeZoneSidKey = 'America/Chicago';
        newUser.Username = 'Test123@test' + Math.round(Math.random() * 10000) + '.com'; 
        newUser.Available_Countries__c = 'AU';
        insert newUser;
        
        User newUser1 = new User();    
        newUser1.Alias = 'terest1';
        newUser1.Email = 'test.rest1@edgeorg.com';
        newUser1.EmailEncodingKey  = 'UTF-8';
        newUser1.LastName = 'Test1234';
        newUser1.FirstName = 'example1';
        newUser1.LanguageLocaleKey  = 'en_US';
        newUser1.LocaleSidKey = 'en_US';
        newUser1.ProfileId = [select Id from Profile where Name ='System Administrator' limit 1].Id;
        newUser1.ManagerId = newUser.Id;
        newUser1.TimeZoneSidKey = 'America/Chicago';
        newUser1.Username = 'Test123@test' + Math.round(Math.random() * 10000) + '.com'; 
        newUser1.Available_Countries__c = 'AU';
        insert newUser1;
        
        Org_Setting__c orgSetting = new Org_Setting__c();
        orgSetting.Run_Triggers__c = True;
        orgSetting.Run_Validation_Rules__c = False;
        insert orgSetting;
        
        System.runAs(newUser1){
            
            String outletRecordType = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
            String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
            Pick_Up_Options__c oultlVstPriPkUp = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
            oultlVstPriPkUp.RecordTypeId = pickupRecordType;
            oultlVstPriPkUp.Name = 'VSTPKUP[AU]';
            oultlVstPriPkUp.Status__c = 'Active';
            insert oultlVstPriPkUp;
            system.assert(oultlVstPriPkUp.id != null,'Outlet Visit Prioritization should not be null');
          
            Account prospectAccount = EDGE_UtilityTestClass.getProspectRecord(oultlVstPriPkUp.id);
            prospectAccount.BillingStreet = 'testStreet';
            prospectAccount.Global_Channel__c = 'off Trade';
            prospectAccount.Global_Sub_Channel__c = 'Retailer';
            prospectAccount.Global_Segment__c = 'Hypermarket';
            prospectAccount.Global_Sub_Segment__c = 'Modern Hypermarket';
            prospectAccount.Status__c = 'Active';
            prospectAccount.BillingCity = 'Tasmania';
            prospectAccount.BillingCountry = 'Australia';
            prospectAccount.Add_Outlet_to_Territory__c= True;
            
            insert prospectAccount;
            prospectAccount.RecordTypeId = outletRecordType;
            
            Territory__c terr= EDGE_UtilityTestClass.getTerritoryRec();
            terr.Territory_Type__c = 'Sales';
            terr.Country__c = countryId;
            insert terr;
            
            
            Territory_Member__c  terrMem = EDGE_UtilityTestClass.getPrimaryTerrMemberRec(newUser1.Id, terr.Id);
            terrMem.Start_Date__c = system.today().addDays(1);
            terrMem.Type__c = 'Primary';
            Test.startTest();
            insert terrMem;
            update prospectAccount;
            
            List<Account> lstProspectOutlet = new List<Account>();
            lstProspectOutlet.add(prospectAccount);
            Map<Id,String> mapAccountTerritory = new Map<Id,String>();
            mapAccountTerritory.put(prospectAccount.Id, terr.Name);
            EDGE_AccountTriggerHelper.sendProspectNotification(lstProspectOutlet, mapAccountTerritory);
            
        }
        Test.stopTest();
    }    
    @isTest
    public static void testProspectSharingSalesManager(){        
        
        User salesManager;
        String prospectRecTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AUT');
        EDGE_UtilityTestClass.createOrgSettings();
        
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AUT]';
        pickupOption.RecordTypeId = pickupRecordType;
        pickupOption.Status__c = 'Active';
        insert pickupOption;
        
        
        salesManager = EDGE_UtilityTestClass.runAsUser('salesMngr','Sales Manager');
        salesManager.Available_Countries__c = 'AU';
        insert salesManager; 
        System.assert(salesManager.Id!=null,'saleManager Id should not be null');
        
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        testAdminUser.ManagerId = testAdminUser.id;
        testAdminUser.ManagerId = salesManager.id;
        insert testAdminUser; 
        
        Test.startTest();
        system.runAs(testAdminUser){
            Account prospectAccount = EDGE_UtilityTestClass.getProspectRecord(pickupOption.id);
            prospectAccount.RecordTypeId = prospectRecTypeId;
            prospectAccount.BillingStreet = 'testStreet';
            prospectAccount.Global_Channel__c = 'off Trade';
            prospectAccount.Global_Sub_Channel__c = 'Retailer';
            prospectAccount.Global_Segment__c = 'Hypermarket';
            prospectAccount.Global_Sub_Segment__c = 'Modern Hypermarket';
            prospectAccount.Status__c = 'Active';
            prospectAccount.BillingCity = 'Tasmania';
            prospectAccount.BillingCountry = 'Australia';
            insert prospectAccount;
            System.assert(prospectAccount.Id!=null,'Prospect Account should not be null');
        }
        Test.stopTest();
    }
    
/**
*@	Method  : testValidatePhoneNumber
*@	Purpose : This is used to Validate Phone Number
**/
    @isTest
    public static void testValidatePhoneNumber(){
        Map<Id,Account> accountMapOld = new  Map<Id,Account>();
		List<Account> accountListNew = new List<Account>();  
        
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
        
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AUT]';
        pickupOption.RecordTypeId = pickupRecordType;
        pickupOption.Status__c = 'Active';
        insert pickupOption;
        
        Market_Cycle__c marCycle = EDGE_UtilityTestClass.getMarketCycle(countryId);
        marCycle.Number_of_Week__c = 52;
        marCycle.Start_Date__c = Date.Today();
        marCycle.End_Date__c = Date.Today().addDays(360);
        insert marCycle;
        
        Test.startTest();
        Account operator = EDGE_UtilityTestClass.getOwnerOperatorAccount();
        operator.IsOperator__c = true;
        insert operator;
        Account operator1 = EDGE_UtilityTestClass.getOwnerOperatorAccount();
        operator1.Name = 'Leme';
        operator1.IsOperator__c = true;
        insert operator1;
        Account testoutlet=EDGE_UtilityTestClass.getOutletRecord();
        testoutlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        testoutlet.Independent_of_Operator__c = false;
        testoutlet.Operator__c = operator.Id;
        testoutlet.MobilePrefix__c ='+61';
        testoutlet.Mobile__c = '512 123 123';
        testoutlet.PhonePrefix__c = '+61';
        testoutlet.Phone__c = '1 2222 3333';
        insert testoutlet;
        accountMapOld.put(testoutlet.Id, testoutlet);
        testoutlet.Operator__c = operator1.Id;
        testoutlet.MobilePrefix__c ='+61';
        testoutlet.Mobile__c = '512 123 222';
        testoutlet.PhonePrefix__c = '+61';
        testoutlet.Phone__c = '1 2222 3334';
        update testoutlet;
        System.assert(testoutlet.id != null,'testOutlet Id should not be null');
        accountListNew.add(testoutlet);
        EDGE_AccountTriggerHelper.validateOwner(accountListNew,accountMapOld);
        Test.stopTest();
    }
    
     @isTest
    public static void updateStatusMarkedForDeletion(){
         
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
        System.assert(countryId != null,'Country Id should not be null');
        EDGE_UtilityTestClass.createOrgSettings();
        
        Market_Setting__c newMs = new Market_Setting__c(Name='Australia MS',Geography__c= countryId, Outlet_Closed_Status_Check__c = True);
        insert newMs;

        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c oultlVstPriPkUp = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
        oultlVstPriPkUp.Name = 'VSTPKUP[AUT]';
        oultlVstPriPkUp.RecordTypeId = pickupRecordType;
        oultlVstPriPkUp.Status__c = 'Active';
        insert oultlVstPriPkUp;
        
        
        String pickupRecordType1 = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Default Pickup').getRecordTypeId();
        Pick_Up_Options__c respGrpPkUp = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Reporting Unit');
        respGrpPkUp.Name = 'Key Account[AUT]';
        respGrpPkUp.RecordTypeId = pickupRecordType1;
        respGrpPkUp.Status__c = 'Active';
        insert respGrpPkUp;
        User user = EDGE_UtilityTestClass.runAsUser('NewUser', 'System Administrator');
        insert user;
        Account ownerAcc = EDGE_UtilityTestClass.getOwnerOperatorAccount();
        ownerAcc.Responsible_Group__c = respGrpPkUp.Id;
        ownerAcc.Person_Responsible__c = user.Id;
        ownerAcc.Status__c = 'Active';
        ownerAcc.IsOwner__c = true;
        //accList.add(ownerAcc);
        insert ownerAcc;
        //printGvrLimits('Inserting ownerAcc');
        
        
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Outlet_Visit_Prioritisation_Grade__c = oultlVstPriPkUp.Id;
        outlet.ParentId = ownerAcc.Id;
        outlet.Independent_of_Owner__c = false;
        outlet.Status__c = 'Active';
        insert outlet;
        
        try {
                ownerAcc.Status__c = 'Marked for Deletion'; 
                update ownerAcc;
            }
            catch(Exception ex) {
                Boolean expectedExceptionThrown;
                expectedExceptionThrown =  ex.getMessage().contains(label.EDGE_Status_MarkedForDeletion) ? true : false;
                //System.assertEquals(expectedExceptionThrown, true);
            } 
        Account distAccObj = EDGE_UtilityTestClass.getDistriAccRec();
        distAccObj.Global_Channel__c = 'Off Trade';
        distAccObj.Global_Sub_Channel__c ='Retailer';
        distAccObj.Global_Segment__c = 'Discounter';
        distAccObj.Global_Sub_Segment__c = 'Modern Discounter';
        distAccObj.Status__c = 'Active';
        insert distAccObj;
        Supplier_Outlet__c supplierOutlet1 = EDGE_UtilityTestClass.suppOutletRec(outlet.Id,distAccObj.Id);
        supplierOutlet1.isPrimary__c = false;            
        insert supplierOutlet1;
         try {
                distAccObj.Status__c = 'Marked for Deletion'; 
                update distAccObj;
            }
            catch(Exception ex) {
                Boolean expectedExceptionThrown;
                expectedExceptionThrown =  ex.getMessage().contains(label.EDGE_Status_MarkedForDeletion) ? true : false;
                //System.assertEquals(expectedExceptionThrown, false);
            } 
    }
    @isTest
    public static void testOutletExHistorics(){
        Test.startTest();
        printGvrLimits('Entering');
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        
        EDGE_UtilityTestClass.createOrgSettings();
        
        Market_Cycle__c marCycle = EDGE_UtilityTestClass.getMarketCycle(countryId);
        marCycle.Number_of_Week__c = 52;
        marCycle.Start_Date__c = Date.Today();
        marCycle.End_Date__c = Date.Today().addDays(360);
        insert marCycle;		
		
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c newOultlVstPriPkUp = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
        
        newOultlVstPriPkUp.Name = 'VSTPKUP[AU]';
        newOultlVstPriPkUp.RecordTypeId = pickupRecordType;
        newOultlVstPriPkUp.Status__c = 'Active';
        insert newOultlVstPriPkUp;
        system.assert(newOultlVstPriPkUp.id != null,'new Outlet Vst should not be null');
        
        Account newOutlet = EDGE_UtilityTestClass.getOutletRecord();
        newOutlet.RecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        newOutlet.Outlet_Visit_Prioritisation_Grade__c =  newOultlVstPriPkUp.Id; 
        newOutlet.Minimum_Activation_Standards__c = 90.00;
        newOutlet.Minimum_Product_Assortment__c = 40.00;
        newOutlet.New_Product_Distribution__c = 50.00;
        //newOutlet.Outlet_Execution_Score__c = 60.00;
        newOutlet.Distribution__c = 70.00;
        newOutlet.Last_Update_TRAX__c = System.today();
        newOutlet.Global_Channel__c = 'Off Trade';
        newOutlet.Global_Sub_Channel__c ='Retailer';
        newOutlet.Global_Segment__c = 'Discounter';
        newOutlet.Global_Sub_Segment__c = 'Modern Discounter';
        insert newOutlet;
        
        newOutlet.Last_Update_TRAX__c = newOutlet.Last_Update_TRAX__c.addDays(2);
        newOutlet.Minimum_Activation_Standards__c = 10.00;
        newOutlet.Minimum_Product_Assortment__c = 20.00;
        newOutlet.New_Product_Distribution__c = 30.00;
        //newOutlet.Outlet_Execution_Score__c = 40.00;
        newOutlet.Distribution__c = 50.00;
        update newOutlet;
        printGvrLimits('Exiting');
        Test.stopTest();
	}
    
    private static void printGvrLimits(String placeOfOccuurence){
        
        System.debug(LoggingLevel.debug,placeOfOccuurence +' : Limits.getHeapSize() = ' + Limits.getHeapSize());
        System.debug(LoggingLevel.debug,placeOfOccuurence +' : Limits.getLimitHeapSize() = ' + Limits.getLimitHeapSize());
        System.debug(LoggingLevel.debug,placeOfOccuurence +' : Limits.getQueries() = ' + Limits.getQueries());
        System.debug(LoggingLevel.debug,placeOfOccuurence +' : Limits.getLimitQueries() = ' + Limits.getLimitQueries());
    }
}