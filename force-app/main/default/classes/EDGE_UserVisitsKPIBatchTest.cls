/**
* @description :  EDGE_UserVisitsKPIBatchTest
* @purpose : Test Class for EDGE_UserVisitsKPIBatch
* @history :
* Version   Developer         Date         User Story/Purpose
*  1.1     Joshraj Sen       12/11/2021     ES20-10978
*/
@isTest
private class EDGE_UserVisitsKPIBatchTest {
    @testSetup
    static void setup() {
        //Map<String, List<Call__c>> callUniqueIdMap = new Map<String, List<Call__c>>();
        //Map<Id, Call__c> callMapToUpdate = new Map<Id, Call__c>();
        //Set<String> uniqueIdSet=new Set<String>();
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
        //marketMap.put('Market',market.Id);
        geoMap.put('Market',market.Id);
        Geography__c hub = EDGE_UtilityTestClass.createGeography('Hub');
        hub.Name = 'Great Britain';
        hub.Code__c = 'GBH';
        hub.Parent_Geography__c = market.Id;
        hub.RecordTypeId=EDGE_UtilityTestClass.HubRecTypeId;
        insert hub;
        geoMap.put('Hub',hub.Id);
        Geography__c cluster = EDGE_UtilityTestClass.createGeography('Cluster');
        cluster.Name = 'Great Britain';
        cluster.Code__c = 'GBC';
        cluster.Parent_Geography__c = hub.Id;
        cluster.RecordTypeId=EDGE_UtilityTestClass.ClusterRecTypeId;
        insert cluster;
        geoMap.put('Cluster',cluster.Id);
        Geography__c country = EDGE_UtilityTestClass.createGeography('Country');
        country.Name = 'Great Britain';
        country.Code__c ='GB';
        country.Parent_Geography__c = cluster.Id;
        country.RecordTypeId=EDGE_UtilityTestClass.CountryRecTypeId;
        insert country;
        geoMap.put('Country',country.Id);
        Geography__c area = EDGE_UtilityTestClass.createGeography('Area');
        area.Name = 'Great Britain';
        area.Code__c = 'GBA';
        area.Parent_Geography__c = country.Id;
        area.RecordTypeId=EDGE_UtilityTestClass.AreaRecTypeId;
        insert area;
        geoMap.put('Area',area.Id);        
        Geography__c region = EDGE_UtilityTestClass.createGeography('Region');
        region.Name = 'Central';
        region.Code__c = 'GB05';
        region.Parent_Geography__c = area.Id;
        region.RecordTypeId=EDGE_UtilityTestClass.RegionRecTypeId;
        insert region;
        geoMap.put('Region',region.Id);
        countryId=country.Id; 
        Id userKPIRecordTypeId=Schema.SObjectType.KPI_Achivement__c.getRecordTypeInfosByName().get('User KPI').getRecordTypeId();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        insert pickupOption;
        Account outlet =EDGE_UtilityTestClass.getOutletRecord();
        outlet.Name='Tes outle classs';
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        outlet.Country__c = geoMap.get('Country');
        outlet.Hub__c = geoMap.get('Hub');
        outlet.Region__c=geoMap.get('Region');
        outlet.Area__c=geoMap.get('Area');
        outlet.Market__c = geoMap.get('Market');
        outlet.Cluster__c= geoMap.get('Cluster');
        insert outlet;
        Market_Cycle__c marc = EDGE_UtilityTestClass.getMarketCycle(countryId) ;
        marc.Start_Date__c= System.today();
        marc.End_Date__c=marc.Start_Date__c.addDays(365);
        insert marc;
        User qrep = EDGE_UtilityTestClass.runAsUser('Quality Rep','Quality Representative');
        qrep.Available_Countries__c = 'AU';
        qrep.Email='saleh.khan@testemail.com';
        qrep.Username='saleh.khan@testemail.com';
        insert qrep;   
        //Create Call Rec
        Datetime endDate=System.today();
        Call__c callObj = EDGE_UtilityTestClass.getCallRec(outlet.Id);
        callObj.Last_Visit_from_Mobile__c = true;
        callObj.Trax_Validation__c = 'Pending';
        callObj.Call_Performed_By__c = qrep.Id;
        callObj.End_Date__c = endDate;
        callObj.Account__c = outlet.Id;
        callObj.Status__c='Completed';
        insert callObj;
        System.assert(callObj.Id!= null,'Call Object Inserted');
        //Created Call Rec for ES20-8055
        Call__c callObj1 = EDGE_UtilityTestClass.getCallRec(outlet.Id);
        callObj1.Last_Visit_from_Mobile__c = true;
        callObj1.Trax_Validation__c = 'Pending';
        callObj1.Call_Performed_By__c = qrep.Id;
        callObj1.End_Date__c =endDate.addDays(5);
        callObj1.Account__c = outlet.Id;
        callObj.Status__c='Completed';
        insert callObj1;
        KPI_Achivement__c userkpirecord=new KPI_Achivement__c();
        userkpirecord.RecordTypeId=userKPIRecordTypeId;
        userkpirecord.KPI_Type__c='Number of Visits';
        userkpirecord.User__c=qrep.Id;
        userkpirecord.Achievement__c=1.0;
        insert userkpirecord;
    }
    @isTest 
    static void testUserVisitsKPIBatch() {
        Test.startTest();
        Market_Batch_Setting__mdt batchSetting = [Select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c 
                                                  from Market_Batch_Setting__mdt 
                                                  where Batch_Class__c = 'EDGE_UserVisitsKPIBatch'
                                                  and Country_Code__c ='GB'];
        system.assert(batchSetting.Id != null,'Batch Setting Inserted');
        String className = batchSetting.Batch_Class__c;         
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
        //EDGE_UserVisitsKPIBatch uca = new EDGE_UserVisitsKPIBatch();
        //Id batchId = Database.executeBatch(uca);
        Test.stopTest();      
    }
}