/********************************************************************************************
Class Name: EDGE_DistributorPersonRespBatchTest

Author              Version       Date           Detail
Shahbaz Khan        V1.0        10/11/2020     Test Class for EDGE_DistributorPersonRespBatch
*********************************************************************************************/
@isTest
public class EDGE_DistributorPersonRespBatchTest {

    @isTest
    public static void testDistResp(){
         // added setupCountryCO by Anamika
        Id countryId = EDGE_UtilityTestClass.setupCountryCO('CO');
        User newUser = EDGE_UtilityTestClass.runAsUser('TestUser', 'Distributor Data Manager');
        insert newUser;
        User newUser2 = EDGE_UtilityTestClass.runAsUser('TestUser2', 'Distributor Data Manager');
        insert newUser2;
        Test.startTest();
        Pick_Up_Options__c pickOp = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
        pickOp.Name = 'Gold [CO]';
        insert pickOp;
        System.assert(pickOp.Name!=null,'pickOp Name should not be null'); //added by divya
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Outlet_Visit_Prioritisation_Grade__c = pickOp.Id;
        outlet.Country__c = countryId;
        insert outlet;
        system.assert(outlet.Id!=null,'Outlet Id should be null');
        Account distAcc = EDGE_UtilityTestClass.getDistriAccRec();
        distAcc.Person_Responsible__c = newUser.Id;
        distAcc.Pending_for_Distributor_Batch__c = true;
        insert distAcc;
        
        Supplier_Outlet__c suppOut = EDGE_UtilityTestClass.suppOutletRec(outlet.Id,distAcc.Id);
        insert suppOut;
        testOutletInventoryBatch();
        
        AccountTeamMember teamMem = new AccountTeamMember();
        teamMem.AccountId = outlet.Id;
        teamMem.UserId = newUser2.Id;
        teamMem.TeamMemberRole = 'Distributor Responsible';
        insert teamMem;
        
        Test.stopTest();
        
    }
    
    public static void testOutletInventoryBatch(){
        
        Market_Batch_Setting__mdt batchSetting = [Select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c 
                                                  from Market_Batch_Setting__mdt 
                                                  where Batch_Class__c = 'EDGE_DistributorPersonRespBatch'
                                                  and Country_Code__c ='CO'];
        system.assert(batchSetting.Id != null,'batchSetting ID should not be null');
        String className = batchSetting.Batch_Class__c;         
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c)); 
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
        supplierOutletRecd1.isPrimary__c = false;
        insert supplierOutletRecd1;
        
        Supplier_Outlet__c supplierOutletRecd2 = EDGE_UtilityTestClass.suppOutletRec(outlet.Id,distAccObj2.Id);
        supplierOutletRecd2.isPrimary__c = false;
        insert supplierOutletRecd2;
        delete supplierOutletRecd1;
        
    }

}