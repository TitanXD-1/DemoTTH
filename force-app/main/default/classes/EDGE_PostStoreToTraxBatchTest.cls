/**
* @description EDGE_PostStoreToTraxBatchTest
* @history                                                            
                                                          
VERSION     AUTHOR              DATE            DETAIL
1.0         Monalisa Halder     04/06/2019      Test Class for EDGE_PostStoreToTraxBatch
1.1         Debolina Saha       06/04/2022      ES20-12406 - Disable IsDeleted Attribute in the Trax Inbound API_SFDC

**/
@isTest
public class EDGE_PostStoreToTraxBatchTest {
    @isTest
    public static void testPostStoreToTraxBatch(){

        Test.startTest();
        createData();
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_PostStoreToTraxBatch'
                                                  and Country_Code__c ='JP' LIMIT 1];
        System.assert(batchSetting.id != null,'batchSetting should not be null');
        String className = batchSetting.Batch_Class__c;
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
        Test.stopTest();
    }
    
    
    @isTest
    public static void testPostStoreToTraxWS(){
        
        Test.setMock(HttpCalloutMock.class, new EDGE_MockTraxResponse());
        Test.startTest();
        List<Account> outlets = new List<Account>();
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        //outlet.Outlet_Visit_Prioritisation_Grade__c = pOption.Id;
        outlet.Last_Modify_Data_Master__c = System.now();
        outlet.Send_To_Trax__c = true;
        outlets.add(outlet);
        
        system.assert(outlets != null,'outlets should not be null');
        
        	EDGE_TraxLinkConnector.uploadFile(JSON.serializePretty(outlets), 'JP', 'Outlet File','store');  

        Test.stopTest();
    }
    
    @isTest
    public static void createData(){
        
        Id countryId = EDGE_UtilityTestClass.setupCountry('JP');
        
         User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        insert testAdminUser;
        
        User testMDMUser = EDGE_UtilityTestClass.runAsUser('MDMuser','System Administrator');
        testMDMUser.ManagerId = testAdminUser.id;
        testMDMUser.Available_Countries__c = 'JP';
        testMDMUser.Trax_User__c = true;
        insert testMDMUser;
        system.assert(testMDMUser.Id != null,'testMDMUser should not be null');
        
        EDGE_UtilityTestClass.createOrgSettings();
        
        Pick_Up_Options__c pOption = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
        pOption.Name = 'Gold[JP]';
        insert pOption;
		
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Outlet_Visit_Prioritisation_Grade__c = pOption.Id;
        outlet.Last_Modify_Data_Master__c = System.now();
        outlet.Send_To_Trax__c = true;
        outlet.Local_Segment_Advanced_Analytics__c = 'Rurals';
        insert outlet;
        
        system.assert(outlet.Id != null,'outlet should not be null');
             
        Account distAccount = EDGE_UtilityTestClass.getDistriAccRec();
        distAccount.BillingCountry = 'Japan';
        insert distAccount;
        system.assert(distAccount.Id != null,'distAccount should not be null');
        
        Supplier_Outlet__c so = EDGE_UtilityTestClass.suppOutletRec(outlet.Id,distAccount.Id);
        so.isPrimary__c = true;
        insert so;
        
        EDGE_GenerateStoreAdditionalAttribute  att;
        att= new EDGE_GenerateStoreAdditionalAttribute('TestGlobalSubChannel', 'GlobalSegment','ConsumerSegmentation[JP]', 'OutletVisitPrioritization[JP]', 'TestFascia','LocalSegment2[JP]', 'distAccountName','LocalSegment1[JP]','12[JP]' ,'TestGlobalSubSegment', 'Rurals', 'JP');
    	
        Outlet_Member__c member = EDGE_UtilityTestClass.getOutletMemberRecord(outlet.Id, testMDMUser.Id, 'Primary');
        insert member;
        system.assert(member.Id != null,'member should not be null');
        
    }
}