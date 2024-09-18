/**
@name EDGE_UpdatePromotionATLBatchTest
@description Test Class for EDGE_UpdatePromotionATLBatch apex class
@history
VERSION     	AUTHOR           DATE           DETAIL
1.0         Monalisa Halder    30/08/2022 		ES20-13220
**/


@isTest
public class EDGE_UpdatePromotionATLBatchTest{
    @isTest
    public static void testUpdatePromotionATLBatch(){
        createData();
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Region__c, Serial_Number__c, Scope__c, Job_Group__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_UpdatePromotionATLBatch' AND Country_Code__c = 'ES' 
                                                  LIMIT 1];
        String className = batchSetting.Batch_Class__c;
        system.assert(batchSetting !=null);
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Test.startTest();  
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
        
        Test.stopTest();
        
    }
    
    public static void createData(){
        
        Map<String,Id> geoMap=new Map<String,Id>();
        Id countryId;
        Geography__c globalRec = EDGE_UtilityTestClass.createGeography('Global');
        globalRec.Name = 'Global3';
        globalRec.Code__c = 'GL3';
        globalRec.RecordTypeId=EDGE_UtilityTestClass.GlobalRecTypeId;
        insert globalRec;
        geoMap.put('Global3',globalRec.Id);
        
        Geography__c market = EDGE_UtilityTestClass.createGeography('Market');
        market.Name = 'Europe and Turkey';
        market.Code__c = 'EU';
        market.Parent_Geography__c = globalRec.Id;
        market.RecordTypeId=EDGE_UtilityTestClass.marketRecTypeId;
        insert market;
        geoMap.put('Market',market.Id);
        
        Geography__c hub = EDGE_UtilityTestClass.createGeography('Hub');
        hub.Name = 'Southern Europe';
        hub.Code__c = 'SEH';
        hub.Parent_Geography__c = market.Id;
        hub.RecordTypeId=EDGE_UtilityTestClass.HubRecTypeId;
        insert hub;
        geoMap.put('Hub',hub.Id);
        
        Geography__c cluster = EDGE_UtilityTestClass.createGeography('Cluster');
        cluster.Name = 'Spain';
        cluster.Code__c = 'SPC';
        cluster.Parent_Geography__c = hub.Id;
        cluster.RecordTypeId=EDGE_UtilityTestClass.ClusterRecTypeId;
        insert cluster;
        geoMap.put('Cluster',cluster.Id);
        
        Geography__c country = EDGE_UtilityTestClass.createGeography('Country');
        country.Name = 'Spain';
        country.Code__c ='ES';
        country.Parent_Geography__c = cluster.Id;
        country.RecordTypeId=EDGE_UtilityTestClass.CountryRecTypeId;
        insert country;
        geoMap.put('Country',country.Id);
        
        Geography__c area = EDGE_UtilityTestClass.createGeography('Area');
        area.Name = 'Spain Canaries';
        area.Code__c = 'ESC';
        area.Parent_Geography__c = country.Id;
        area.RecordTypeId=EDGE_UtilityTestClass.AreaRecTypeId;
        insert area;
        geoMap.put('Area',area.Id);  
        
        Geography__c region = EDGE_UtilityTestClass.createGeography('Region');
        region.Name = 'CANARIAS';
        region.Code__c = 'ES1';
        region.Parent_Geography__c = area.Id;
        region.RecordTypeId=EDGE_UtilityTestClass.RegionRecTypeId;
        insert region;
        geoMap.put('Region',region.Id);
        countryId=country.Id; 
        
        List<Account> outletListToInsert = new List<Account>();
        List<Target_List__c> tlListToInsert = new List<Target_List__c>();
        List<Target_List_Member__c> tlmListToInsert = new List<Target_List_Member__c>();
        List<Activity_Target_List__c> activityTLInsertList = new List<Activity_Target_List__c>();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        insert pickupOption;        
        
        Account outlet1 = EDGE_UtilityTestClass.getOutletRecord();
        outlet1.Name='Two Outlets 2 Two';
        outlet1.BillingCity = 'Kolkata';    
        outletListToInsert.add(outlet1);
        
        Account outlet2 = EDGE_UtilityTestClass.getOutletRecord();
        outlet2.Name='Three Outletz 3 Three';
        outlet2.BillingCity = 'Raipur';
        outletListToInsert.add(outlet2);
        insert outletListToInsert;
        
        Target_List__c targetLst1 =  EDGE_UtilityTestClass.getTargetList(countryId);
        targetLst1.recordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Dynamic_Target_List' LIMIT 1].Id;
        tlListToInsert.add(targetLst1);
        
        insert tlListToInsert;
        
        Target_List_Member__c  targetLstmem = EDGE_UtilityTestClass.getTargetMemList(outlet1.Id, targetLst1.Id);
        targetLstmem.Assignment_Status__c = 'Active';
        tlmListToInsert.add(targetLstmem);
       
        Target_List_Member__c  targetLstmem2 = EDGE_UtilityTestClass.getTargetMemList(outlet2.Id, targetLst1.Id);
        targetLstmem2.Assignment_Status__c = 'Active';
        tlmListToInsert.add(targetLstmem2);
        insert tlmListToInsert;
           
        String promoMasterRecTypeId = Promotion_Master__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Free Product').getRecordTypeId();
        Promotion_Master__c pm = new Promotion_Master__c();
        pm.Start_Date__c = system.today();
        pm.End_Date__c = System.today() +5;
        pm.Country__c = countryId;
        pm.name = 'Test Pm';
        pm.Description__c = 'testing';
        pm.RecordTypeId= promoMasterRecTypeId;
        insert pm;
        
        Promotion_Master__c pm1 = new Promotion_Master__c();
        pm1.Start_Date__c = system.today();
        pm1.End_Date__c = System.today() +10;
        pm1.Country__c = countryId;
        pm1.name = 'Test Pm1';
        pm1.Description__c = 'testing1';
        pm1.RecordTypeId= promoMasterRecTypeId;
        insert pm1;
        
        String promATLRecTypeId = Activity_Target_List__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Promotion').getRecordTypeId();
        Activity_Target_List__c  atLst = new Activity_Target_List__c();
        atLst.Target_List__c = targetLst1.Id;
        atLst.Promotion_Master__c  = pm1.Id;
        atLst.Promotion_Limit__c = 12;
        atLst.Status__c = 'Waiting Activation';
        atLst.RecordTypeId = promATLRecTypeId;
        activityTLInsertList.add(atLst);
        
        Activity_Target_List__c  atLst4 = new Activity_Target_List__c();
        atLst4.Target_List__c = targetLst1.Id;
        atLst4.Promotion_Master__c  = pm.Id;
        atLst4.Promotion_Limit__c = 10;
        atLst4.Status__c = 'Waiting Activation';
        atLst4.RecordTypeId = promATLRecTypeId;
        activityTLInsertList.add(atLst4);
       insert activityTLInsertList;
        
    }
}