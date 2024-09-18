/**
* @description EDGE_SupplierOutletTriggerTest
* @purpose Test class for EDGE_SupplierOutletTriggerHelper
* @history
                                                         
VERSION   AUTHOR             DATE              DETAIL
1.0       Saurav Paul      11-Mar-2019         ES20-408
2.0      Sagar Barman      23-APR-2019    Added Outlet visitpriotisation 
3.0     Monalisa Halder    24/02/2022       ES20-11303
4.0     Joshraj Sen/Sakshi Shah 01/04/2024  152305
**/


@isTest
public with sharing class EDGE_SupplierOutletTriggerTest {
   /* @isTest
    public static void testFCRInsert(){
        
        //Variables
        Id contId;
        Pick_Up_Options__c pickupOption,pickupOptionReg;
        List<Account> distAccList = new List<Account>();
        User salesRep;
        Account outlet;
        Supplier_Outlet__c prmrySubRecObj1;
        
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        insert testAdminUser; 
        EDGE_UtilityTestClass.createOrgSettings();
        contId = EDGE_UtilityTestClass.setupCountry('AU'); 
        System.assert(contId != null, 'contId should not be null');
        
        Market_Setting__c newMs = new Market_Setting__c(Name='Australia MS',Geography__c= contId, Status__c='Editable & Mandatory - Manager Approval Required');
        insert newMs;
        System.assert(newMs != null, 'newMs should not be null');
        
        Field_Permission_set__c fieldperSet = new Field_Permission_set__c();
        fieldperSet.Market_Setting__c = newMs.Id;
        fieldperSet.Type__c = 'Outlet';
        insert fieldperSet;
        
        
		Field_Permission__c fieldPermission = new Field_Permission__c();
        fieldPermission.Field_Permission_Set__c = fieldperSet.Id;
        fieldPermission.Field__c = 'isPrimary__c';
        fieldPermission.Related_Object__c = 'Supplier_Outlet__c';
        fieldPermission.Permission__c = 'Editable & Mandatory - Manager Approval Required';
        insert fieldPermission;
        
        Business_Role__c bRole = new Business_Role__c();
        bRole.Field_Permission_Set_Outlet__c = fieldperSet.Id;
        bRole.Name = 'Sales Rep';
        bRole.Global_Equivalent__c = 'Sales Rep';
        bRole.Call_Type__c = 'Measure and Sell';
        bRole.Country__c = contId;
        bRole.My_accounts_Fields_Display__c = 'Outlet_Execution_Score__c;Minimum_Product_Assortment__c;Minimum_Activation_Standards__c;WPA__c;New_Product_Distribution__c;Volume_YOY_uplift__c;#of Kegs;OPPS OPEN;OPPS CLOSED;Last_Visit_Sales__c;Outlet_Visit_Compliance__c;Actual_Physical_Call_Market_Cycle__c;Total_Virtual_Calls__c;Primary_Sales_Territory__r.Name;Primary_Sales_Rep__r.name';
        insert bRole;
        
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        pickupOption = EDGE_UtilityTestClass.getPickUpOption(contId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AU]';
        pickupOption.RecordTypeId = pickupRecordType;
        insert pickupOption;
        
        outlet = EDGE_UtilityTestClass.getOutletRecord(); 
        outlet.Status__c = 'Active'; 
        outlet.BillingCity = 'Austria';
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        outlet.Global_Channel__c = 'Off Trade';
        outlet.Global_Sub_Channel__c ='Retailer';
        outlet.Global_Segment__c = 'Discounter';
        outlet.Global_Sub_Segment__c = 'Modern Discounter'; 
        outlet.Country__c = contId;
        distAccList.add(outlet);
        
        //outlet.Last_Modify_Data_Master__c = system.today();
        //update outlet;
       
        Account distAccObj1 = EDGE_UtilityTestClass.getDistriAccRec();
        distAccObj1.Global_Channel__c = 'Off Trade';
        distAccObj1.Global_Sub_Channel__c ='Retailer';
        distAccObj1.Global_Segment__c = 'Discounter';
        distAccObj1.Global_Sub_Segment__c = 'Modern Discounter';
        distAccList.add(distAccObj1);
        
        test.startTest();
        Account distAccObj2 = EDGE_UtilityTestClass.getDistriAccRec();
        distAccObj2.Global_Channel__c = 'Off Trade';
        distAccObj2.Global_Sub_Channel__c ='Retailer';
        distAccObj2.Global_Segment__c = 'Discounter';
        distAccObj2.Global_Sub_Segment__c = 'Modern Discounter';
        distAccList.add(distAccObj2);
        insert distAccList;
        System.assert(distAccList.Size() != null,'distAccList size should not be null');
        
        //test.startTest();
        prmrySubRecObj1 = EDGE_UtilityTestClass.suppOutletRec(outlet.Id,distAccObj1.Id);
        insert prmrySubRecObj1;
        delete prmrySubRecObj1;
        undelete prmrySubRecObj1 ; 
        System.assert(prmrySubRecObj1.Id != null,'prmrySubRecObj1 Id should not be null');
        
        system.runAs(testAdminUser){
            salesRep = EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
            salesRep.Available_Countries__c = 'AU';
            salesRep.ManagerId = testAdminUser.Id;
            insert salesRep; 
            System.assert(salesRep.Id!=null,'salesRep Id should not be null');
            
            User_Business_Role__c userBRole = new User_Business_Role__c();
            userBRole.Business_Role__c = bRole.Id;
            userBRole.User__c = salesRep.Id;
            insert userBRole;
            
            Geography__Share geoShare = new Geography__Share();
            geoShare.ParentId = contId;
            geoShare.UserOrGroupId = salesRep.Id;
            geoShare.AccessLevel = 'Read';
            Database.SaveResult sr1 = Database.insert(geoShare,false);
            
            Business_Role__Share brs = new Business_Role__Share();
            brs.ParentId = bRole.Id;
            brs.UserOrGroupId = salesRep.Id;
            brs.AccessLevel = 'Read';
            Database.SaveResult sr = Database.insert(brs,false);
            
            AccountTeamMember newAccTeamMember = new AccountTeamMember();
            newAccTeamMember.AccountId = outlet.Id;
            newAccTeamMember.UserId = salesRep.Id;
            newAccTeamMember.AccountAccessLevel = 'Edit';
            newAccTeamMember.OpportunityAccessLevel = 'Edit';
            newAccTeamMember.ContactAccessLevel = 'Edit';
            insert newAccTeamMember;
            System.assert(newAccTeamMember.Id!=null,'newAccTeamMember Id should not be null');
        } 
        System.runAs(salesRep){
            EDGE_UtilityClass.stopTriggerToRun = false;
            Supplier_Outlet__c testSO1 = [Select ID,isPrimary__c from Supplier_Outlet__c where ID =: prmrySubRecObj1.Id Limit 1];
            testSO1.isPrimary__c = true;
            update testSO1;
        }
        test.stopTest();
        
    }*/
    /********
    Name : testIsPrimaryInsert
    Description : Test Class for insert
    ********/
    @isTest
    public static void testIsPrimaryInsert(){
        List<Account> distAccList = new List<Account>();
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AUT');
        
        EDGE_UtilityTestClass.createOrgSettings(); 
        
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pickupOption.RecordTypeId = pickupRecordType;
        insert pickupOption;
        
        //Creating market setting
        Market_Setting__c newMs = new Market_Setting__c(Name='Australia MS',Geography__c= geographyId,License_Number__c='Editable & Mandatory - Manager Approval Required');
        newMs.Centrally_Managed__c = 'Editable - Manager Approval Required';
        newMs.Centrally_Managed_Note__c = 'Editable - Manager Approval Required';
        newMs.Primary_Distributor__c = 'Editable - Manager Approval Required';
        newMs.Website__c = 'Editable - MDM Approval Required';
        insert newMs;
        
        Account outlet = EDGE_UtilityTestClass.getOutletRecord(); 
        outlet.Status__c = 'Active';
        outlet.Global_Channel__c = 'Off Trade';
        outlet.Global_Sub_Channel__c ='Retailer';
        outlet.Global_Segment__c = 'Discounter';
        outlet.Global_Sub_Segment__c = 'Modern Discounter';  
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        distAccList.add(outlet); 
       
        Account distAccObj1 = EDGE_UtilityTestClass.getDistriAccRec();
        distAccObj1.Global_Channel__c = 'Off Trade';
        distAccObj1.Global_Sub_Channel__c ='Retailer';
        distAccObj1.Global_Segment__c = 'Discounter';
        distAccObj1.Global_Sub_Segment__c = 'Modern Discounter';
        distAccList.add(distAccObj1);
        
        Account distAccObj2 = EDGE_UtilityTestClass.getDistriAccRec();
        distAccObj2.Global_Channel__c = 'Off Trade';
        distAccObj2.Global_Sub_Channel__c ='Retailer';
        distAccObj2.Global_Segment__c = 'Discounter';
        distAccObj2.Global_Sub_Segment__c = 'Modern Discounter';
        distAccList.add(distAccObj2);
        
        insert distAccList;
        System.assert(distAccList.Size() != null,'distAccList Size should not be null');
        
        Supplier_Outlet__c prmrySubRecObj1 = EDGE_UtilityTestClass.suppOutletRec(outlet.Id,distAccObj1.Id);
        prmrySubRecObj1.isPrimary__c = true;            
        insert prmrySubRecObj1;
        prmrySubRecObj1.isPrimary__c = false; 
        update prmrySubRecObj1;
        System.assert(prmrySubRecObj1.Id != null,'prmrySubRecObj1 Id should not be null');
        
        Supplier_Outlet__c prmrySubRecObj2 = EDGE_UtilityTestClass.suppOutletRec(outlet.Id,distAccObj2.Id);
        prmrySubRecObj2.isPrimary__c = true;
        Test.startTest();
        
        //Creating Sales Manager
        User salesManager=EDGE_UtilityTestClass.runAsUser('salesRep1','System Administrator');
        salesManager.Available_Countries__c = 'AU';
        insert salesManager;
        System.assert(salesManager.Id!=null,'salesManager Id should not be null');
        //Creating Sales Rep 
        User salesRep= EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
        salesRep.Available_Countries__c = 'AU';
        salesRep.ManagerId = salesManager.Id;
        insert salesRep;
        System.assert(salesRep.Id!=null,'(salesRep Id should not be null');
        
        
        try{
            insert prmrySubRecObj2;         
        }catch(Exception ex){
            //Checking Primary Supplier Validation Rule
            System.Assert(ex.getMessage().contains(Label.Primary_Supplier_Outlet_Error),'Exception message should contain the Primary Supplier Outlet Error');
        }
        
        Test.stopTest();
       // System.assertEquals(prmrySubRecObj2.Id,null,'prmrySubRecObj2 Id should be null');
    }
    
    @isTest
    public static void testIsPrimaryUpdateData(){
        List<Account> distAccList = new List<Account>();
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AUT');
        
        EDGE_UtilityTestClass.createOrgSettings(); 
        
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pickupOption.RecordTypeId = pickupRecordType;
        insert pickupOption;
        
                
        //Creating Sales Manager
        User salesManager=EDGE_UtilityTestClass.runAsUser('salesRep1','System Administrator');
        salesManager.Available_Countries__c = 'AU';
        insert salesManager;
        System.assert(salesManager.Id!=null,'salesManager Id should not be null');
        //Creating Sales Rep 
        User salesRep= EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
        salesRep.Available_Countries__c = 'AU';
        salesRep.ManagerId = salesManager.Id;
        insert salesRep;
        System.assert(salesRep.Id!=null,'salesRep Id should not be null');
        
        //Creating market setting
        Market_Setting__c newMs = new Market_Setting__c(Name='Australia MS',Geography__c= geographyId,License_Number__c='Editable & Mandatory - Manager Approval Required');
        newMs.Centrally_Managed__c = 'Editable - Manager Approval Required';
        newMs.Centrally_Managed_Note__c = 'Editable - Manager Approval Required';
        newMs.Primary_Distributor__c = 'Editable - Manager Approval Required';
        newMs.Website__c = 'Editable - MDM Approval Required';
        insert newMs;
        
        Account outlet = EDGE_UtilityTestClass.getOutletRecord(); 
        outlet.Status__c = 'Active';
        outlet.Global_Channel__c = 'Off Trade';
        outlet.Global_Sub_Channel__c ='Retailer';
        outlet.Global_Segment__c = 'Discounter';
        outlet.Global_Sub_Segment__c = 'Modern Discounter';  
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        //outlet.Region__c =  pickupOptionReg.Id;      
        insert outlet;  
        System.assert(outlet.Id != null,'outlet Id should not be null');
        
        Account distAccObj1 = EDGE_UtilityTestClass.getDistriAccRec();
        distAccObj1.Global_Channel__c = 'Off Trade';
        distAccObj1.Global_Sub_Channel__c ='Retailer';
        distAccObj1.Global_Segment__c = 'Discounter';
        distAccObj1.Global_Sub_Segment__c = 'Modern Discounter';
        distAccList.add(distAccObj1);
        
        Account distAccObj2 = EDGE_UtilityTestClass.getDistriAccRec();
        distAccObj2.Global_Channel__c = 'Off Trade';
        distAccObj2.Global_Sub_Channel__c ='Retailer';
        distAccObj2.Global_Segment__c = 'Discounter';
        distAccObj2.Global_Sub_Segment__c = 'Modern Discounter';
        distAccList.add(distAccObj2);
        
        insert distAccList;
        System.assert(distAccList.Size() != null,'distAccList Size should not be null');
        
                
        List<AccountShare> accsToBeShared = new List<AccountShare>();     
        
        AccountShare accShr  = new AccountShare();
        accShr.AccountId = outlet.Id;
        accShr.UserOrGroupId = salesRep.Id;
        accShr.AccountAccessLevel = 'Edit';
        accShr.OpportunityAccessLevel = 'Edit';
        accShr.RowCause = Schema.AccountShare.RowCause.Manual;
        accsToBeShared.add(accShr);
        
        AccountShare accShr1  = new AccountShare();
        accShr1.AccountId = distAccObj2.Id;
        accShr1.UserOrGroupId = salesRep.Id;
        accShr1.AccountAccessLevel = 'Edit';
        accShr1.OpportunityAccessLevel = 'Edit';
        accShr1.RowCause = Schema.AccountShare.RowCause.Manual;
        accsToBeShared.add(accShr1);
        
        insert accsToBeShared;
        
        Supplier_Outlet__c prmrySubRecObj1 = EDGE_UtilityTestClass.suppOutletRec(outlet.Id,distAccObj1.Id);
        prmrySubRecObj1.isPrimary__c = true;            
        insert prmrySubRecObj1;
        System.assert(prmrySubRecObj1.Id != null,'prmrySubRecObj1 Id should not be null');
        
        Supplier_Outlet__c prmrySubRecObj2 = EDGE_UtilityTestClass.suppOutletRec(outlet.Id,distAccObj2.Id);
        prmrySubRecObj2.isPrimary__c = true;
        Test.startTest();

        
        
        try{
            System.runAs(salesRep){ 
              insert prmrySubRecObj2;
              prmrySubRecObj2.isPrimary__c = false;   
                update prmrySubRecObj2; 
            }
        }catch(Exception ex){
            //Checking Primary Supplier Validation Rule
            System.Assert(ex.getMessage().contains(Label.Primary_Supplier_Outlet_Error),'Exception message should contain the Primary Supplier Outlet Error');
        }
        
        Test.stopTest();
        System.assertEquals(prmrySubRecObj2.Id,null,'prmrySubRecObj2 Id should be null');
    }
    /********
    Name : testIsPrimaryUpdate
    Description : Test Class for update
    ********/
    @isTest
    public static void testIsPrimaryUpdate(){
        List<Account> distAccList = new List<Account>();
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AUT');
        Boolean isVRuleFired = false;
        EDGE_UtilityTestClass.createOrgSettings(); 
        
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pickupOption.RecordTypeId = pickupRecordType;
        insert pickupOption;            
        /*Pick_Up_Options__c pickupOptionReg = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Consumer Segmentation');
        insert pickupOptionReg;*/
        
        Account outlet = EDGE_UtilityTestClass.getOutletRecord(); 
        outlet.Status__c = 'Active'; 
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        outlet.Global_Channel__c = 'Off Trade';
        outlet.Global_Sub_Channel__c ='Retailer';
        outlet.Global_Segment__c = 'Discounter';
        outlet.Global_Sub_Segment__c = 'Modern Discounter'; 
        // outlet.Region__c =  pickupOptionReg.Id;      
        insert outlet;  
        System.assert(outlet.Id != null,'outlet Id should not be null');
        
        Account distAccObj1 = EDGE_UtilityTestClass.getDistriAccRec();
        distAccObj1.Global_Channel__c = 'Off Trade';
        distAccObj1.Global_Sub_Channel__c ='Retailer';
        distAccObj1.Global_Segment__c = 'Discounter';
        distAccObj1.Global_Sub_Segment__c = 'Modern Discounter';
        distAccList.add(distAccObj1);
        
        Account distAccObj2 = EDGE_UtilityTestClass.getDistriAccRec();
        distAccObj2.Global_Channel__c = 'Off Trade';
        distAccObj2.Global_Sub_Channel__c ='Retailer';
        distAccObj2.Global_Segment__c = 'Discounter';
        distAccObj2.Global_Sub_Segment__c = 'Modern Discounter';
        distAccList.add(distAccObj2);
        insert distAccList;
        System.assert(distAccList.Size() != null,'distAccList Size should not be null');
        
        Supplier_Outlet__c prmrySubRecObj1 = EDGE_UtilityTestClass.suppOutletRec(outlet.Id,distAccObj1.Id);
        prmrySubRecObj1.isPrimary__c = true;            
        insert prmrySubRecObj1;
        System.assert(prmrySubRecObj1.Id != null,'prmrySubRecObj1 Id should not be null');
        prmrySubRecObj1.isPrimary__c = false ;
        update prmrySubRecObj1;
        Market_Setting__c newMs = new Market_Setting__c(Name='Australia MS',Geography__c= geographyId,Primary_Distributor__c='Editable & Mandatory - Manager Approval Required');
        insert newMs;
        
        Supplier_Outlet__c prmrySubRecObj2 = EDGE_UtilityTestClass.suppOutletRec(outlet.Id,distAccObj2.Id);
        prmrySubRecObj2.isPrimary__c = false;
        insert prmrySubRecObj2;
        prmrySubRecObj2.isPrimary__c = true;
        Test.startTest();
        try{
            update prmrySubRecObj2;
        }catch(Exception ex){
            //Checking Primary Supplier Validation Rule
            System.Assert(ex.getMessage().contains(Label.Primary_Supplier_Outlet_Error),'Exception message should contain the Primary Supplier Outlet Error');
            isVRuleFired = true;
        }
        Test.stopTest();
        //System.assertEquals(isVRuleFired,true);
        
    }
    @isTest
    public static void testInsertAndDeleteAccountTeamMember(){
        List<Account> distAccList = new List<Account>();
        User adminUser= EDGE_UtilityTestClass.runAsUser('sysadminuser','System Administrator');
        adminUser.Default_Country__c = 'AU';
        adminUser.Available_Countries__c = 'AU';
        insert adminUser;
        
         Id countryId  = EDGE_UtilityTestClass.setupCountry('AU');
        
        EDGE_UtilityTestClass.createOrgSettings();
        User ddmUser;
        User ddmNewUser;
        System.runAs(adminUser){
          //Creating Distributor Data Manager 
            ddmUser= EDGE_UtilityTestClass.runAsUser('DDM1','Distributor Data Manager');
            ddmUser.Available_Countries__c = 'AU';
            insert ddmUser;
            System.assert(ddmUser.Id!=null,'ddmUser Id should not be null'); 
            
            ddmNewUser= EDGE_UtilityTestClass.runAsUser('DDM2','Distributor Data Manager');
            ddmNewUser.Available_Countries__c = 'AU';
            insert ddmNewUser;
            System.assert(ddmNewUser.Id!=null,'ddmNewUser Id should not be null'); 
        }
        //Creating  Pick Up Option
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold [AU]';
        pickupOption.RecordTypeId = pickupRecordType;
        pickupOption.Status__c = 'Active';
        insert pickupOption;
        
        Account outlet = EDGE_UtilityTestClass.getOutletRecord(); 
        outlet.Status__c = 'Active'; 
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        outlet.Global_Channel__c = 'Off Trade';
        outlet.Global_Sub_Channel__c ='Retailer';
        outlet.Global_Segment__c = 'Discounter';
        outlet.Global_Sub_Segment__c = 'Modern Discounter'; 
        insert outlet;  
        System.assert(outlet.Id != null,'outlet Id should not be null');
        
        Account distAccObj1 = EDGE_UtilityTestClass.getDistriAccRec();
        distAccObj1.Global_Channel__c = 'Off Trade';
        distAccObj1.Global_Sub_Channel__c ='Retailer';
        distAccObj1.Global_Segment__c = 'Discounter';
        distAccObj1.Global_Sub_Segment__c = 'Modern Discounter';
        distAccObj1.Person_Responsible__c = ddmUser.Id;
        distAccObj1.Person_Responsible_2__c = ddmNewUser.Id;
        distAccList.add(distAccObj1);
        Account distAccObj2 = EDGE_UtilityTestClass.getDistriAccRec();
        distAccObj2.Global_Channel__c = 'Off Trade';
        distAccObj2.Global_Sub_Channel__c ='Retailer';
        distAccObj2.Global_Segment__c = 'Discounter';
        distAccObj2.Global_Sub_Segment__c = 'Modern Discounter';
        distAccObj2.Person_Responsible__c = ddmUser.Id;
        distAccList.add(distAccObj2);
        insert distAccList;
        
        Supplier_Outlet__c supplierOutletRecd1 = EDGE_UtilityTestClass.suppOutletRec(outlet.Id,distAccObj1.Id);
        supplierOutletRecd1.isPrimary__c = true;
        insert supplierOutletRecd1;
        
        Supplier_Outlet__c supplierOutletRecd2 = EDGE_UtilityTestClass.suppOutletRec(outlet.Id,distAccObj2.Id);
        supplierOutletRecd2.isPrimary__c = false;
        insert supplierOutletRecd2;
        delete supplierOutletRecd1;
        
    }

    @isTest
    public static void testFCRLookupFieldUpdate(){
        
        //Variables
        Id contId;
        Pick_Up_Options__c pickupOption;
        Pick_Up_Options__c pickupOptionReg;
        pickupOptionReg = null;
        List<Account> distAccList = new List<Account>();
        User salesRep;
        Account outlet;
        Supplier_Outlet__c prmrySubRecObj1;
        
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        insert testAdminUser; 
        EDGE_UtilityTestClass.createOrgSettings();
        contId = EDGE_UtilityTestClass.setupCountry('AU'); 
        System.assert(contId != null,'contId should not be null');
        
        Market_Setting__c newMs = new Market_Setting__c(Name='Australia MS',Geography__c= contId, Status__c='Editable & Mandatory - Manager Approval Required');
        insert newMs;
        System.assert(newMs != null,'newMs should not be null');
        
        Field_Permission_set__c fieldperSet = new Field_Permission_set__c();
        fieldperSet.Market_Setting__c = newMs.Id;
        fieldperSet.Type__c = 'Outlet';
        insert fieldperSet;
        
        
		Field_Permission__c fieldPermission = new Field_Permission__c();
        fieldPermission.Field_Permission_Set__c = fieldperSet.Id;
        fieldPermission.Field__c = 'Distributor_Wholesaler__c';
        fieldPermission.Related_Object__c = 'Supplier_Outlet__c';
        fieldPermission.Permission__c = 'Editable & Mandatory - Manager Approval Required';
        insert fieldPermission;
        
        Business_Role__c bRole = new Business_Role__c();
        bRole.Field_Permission_Set_Outlet__c = fieldperSet.Id;
        bRole.Name = 'Sales Rep';
        bRole.Global_Equivalent__c = 'Sales Rep';
        bRole.Call_Type__c = 'Measure and Sell';
        bRole.Country__c = contId;
        bRole.My_accounts_Fields_Display__c = 'Outlet_Execution_Score__c;Minimum_Product_Assortment__c;Minimum_Activation_Standards__c;WPA__c;New_Product_Distribution__c;Volume_YOY_uplift__c;#of Kegs;OPPS OPEN;OPPS CLOSED;Last_Visit_Sales__c;Actual_Physical_Call_Market_Cycle__c;Total_Virtual_Calls__c;Primary_Sales_Territory__r.Name;Primary_Sales_Rep__r.name';
        insert bRole;
        
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        pickupOption = EDGE_UtilityTestClass.getPickUpOption(contId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AU]';
        pickupOption.RecordTypeId = pickupRecordType;
        insert pickupOption;
        
        outlet = EDGE_UtilityTestClass.getOutletRecord(); 
        outlet.Status__c = 'Active'; 
        outlet.BillingCity = 'Austria';
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        outlet.Global_Channel__c = 'Off Trade';
        outlet.Global_Sub_Channel__c ='Retailer';
        outlet.Global_Segment__c = 'Discounter';
        outlet.Global_Sub_Segment__c = 'Modern Discounter'; 
        outlet.Country__c = contId;
        distAccList.add(outlet);
        
        //outlet.Last_Modify_Data_Master__c = system.today();
        //update outlet;
       
        Account distAccObj1 = EDGE_UtilityTestClass.getDistriAccRec();
        distAccObj1.Global_Channel__c = 'Off Trade';
        distAccObj1.Global_Sub_Channel__c ='Retailer';
        distAccObj1.Global_Segment__c = 'Discounter';
        distAccObj1.Global_Sub_Segment__c = 'Modern Discounter';
        distAccList.add(distAccObj1);
        
        test.startTest();
        Account distAccObj2 = EDGE_UtilityTestClass.getDistriAccRec();
        distAccObj2.Global_Channel__c = 'Off Trade';
        distAccObj2.Global_Sub_Channel__c ='Retailer';
        distAccObj2.Global_Segment__c = 'Discounter';
        distAccObj2.Global_Sub_Segment__c = 'Modern Discounter';
        distAccList.add(distAccObj2);
        insert distAccList;
        System.assert(distAccList.Size() != null,'distAccList Size should not be null');
        
        //test.startTest();
        prmrySubRecObj1 = EDGE_UtilityTestClass.suppOutletRec(outlet.Id,distAccObj1.Id);
        insert prmrySubRecObj1;
        delete prmrySubRecObj1;
        undelete prmrySubRecObj1 ; 
        System.assert(prmrySubRecObj1.Id != null,'prmrySubRecObj1 Id should not be null');
        
        system.runAs(testAdminUser){
            salesRep = EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
            salesRep.Available_Countries__c = 'AU';
            salesRep.ManagerId = testAdminUser.Id;
            insert salesRep; 
            System.assert(salesRep.Id!=null,'salesRep Id should not be null');
            
            User_Business_Role__c userBRole = new User_Business_Role__c();
            userBRole.Business_Role__c = bRole.Id;
            userBRole.User__c = salesRep.Id;
            insert userBRole;
            
            Geography__Share geoShare = new Geography__Share();
            geoShare.ParentId = contId;
            geoShare.UserOrGroupId = salesRep.Id;
            geoShare.AccessLevel = 'Read';
            Database.SaveResult sr1 = null;
            sr1 = Database.insert(geoShare,false);
            
            Business_Role__Share brs = new Business_Role__Share();
            brs.ParentId = bRole.Id;
            brs.UserOrGroupId = salesRep.Id;
            brs.AccessLevel = 'Read';
            Database.SaveResult sr = null;
            sr = Database.insert(brs,false);
            
            AccountTeamMember newAccTeamMember = new AccountTeamMember();
            newAccTeamMember.AccountId = outlet.Id;
            newAccTeamMember.UserId = salesRep.Id;
            newAccTeamMember.AccountAccessLevel = 'Edit';
            newAccTeamMember.OpportunityAccessLevel = 'Edit';
            newAccTeamMember.ContactAccessLevel = 'Edit';
            insert newAccTeamMember;
            System.assert(newAccTeamMember.Id!=null,'newAccTeamMember Id should not be null');
        } 
        System.runAs(salesRep){
            EDGE_UtilityClass.stopTriggerToRun = false;
            Supplier_Outlet__c testSO1 = [Select ID,Distributor_Wholesaler__c  from Supplier_Outlet__c where ID =: prmrySubRecObj1.Id Limit 1];
            testSO1.Distributor_Wholesaler__c  = distAccObj2.Id;
            update testSO1;
        }
        test.stopTest();
        
    }

}