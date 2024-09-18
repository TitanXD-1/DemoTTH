/**
* @description :  Edge_UniqueoutletUserKPIBatchTest
* @purpose : This is the test class for Edge_UniqueoutletUserKPIBatchTest
* @history :
* Version   Developer         Date         User Story	         Purpose
*  1.0     	Sudipta Nandi      11/13/2020   Initial Development   This is the test class for Edge_UniqueoutletUserKPIBatch
*  2.0      Swaraj Samanta     05/09/2022   ES20-13284            Test Class Correction due to Failure
*/
@isTest
public class Edge_UniqueoutletUserKPIBatchTest {
    final static String outletRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();  
    final static String caseTaskTypeRecTypeId = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Task Type').getRecordTypeId();
    final static String caseTypeRecTypeId = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Type').getRecordTypeId();
    final static String caseTaskSubTypeRecTypeId = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Sub Type').getRecordTypeId();
    final static String qualityRecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality').getRecordTypeId();
    
    static Map<String,Id> geoMap=new Map<String,Id>();
    //static Id countryId;
    
    private static Id setupCountry(String countryCode){
        //Id countryId;
        
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
        country.Code__c = countryCode;
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
        
        //countryId=country.Id;
        return country.Id;
    }
    
    @isTest
    public static void testKPIFieldsCalcAtOutletLevel(){
        //Id geographyId = EDGE_UtilityTestClass.setupCountryGB('GB');
        Id geographyId = setupCountry('GB');
        //System.debug('Condition 1 '+Limits.getQueries());
        EDGE_UtilityTestClass.createOrgSettings();
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[GB]';
        pickupOption.RecordTypeId = pickupRecordType;
        pickupOption.Status__c = 'Active';
        insert pickupOption;
        //System.debug('Condition 2 '+Limits.getQueries());
        User qrep = EDGE_UtilityTestClass.runAsUser('Quality Rep','Quality Representative');
        qrep.Available_Countries__c = 'GB';
        qrep.Email='test.test2567@testemail.com';
        qrep.Username='test.test2567@testemail.com';
        insert qrep;
        //System.debug('Condition 3 '+Limits.getQueries());
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        outlet.Area__c = geoMap.get('Area');
        outlet.Cluster__c = geoMap.get('Cluster');
        outlet.Country__c = geoMap.get('Country');
        outlet.Hub__c = geoMap.get('Hub');
        outlet.Market__c = geoMap.get('Market'); 
        outlet.Region__c = geoMap.get('Region');
        insert outlet;
        //System.debug('Condition 4 '+Limits.getQueries());
        Market_Cycle__c marc = EDGE_UtilityTestClass.getMarketCycle(geographyId) ;
        marc.Start_Date__c= System.today();
        marc.End_Date__c=marc.Start_Date__c.addDays(365);
        insert marc;
        //System.debug('Condition 5 '+Limits.getQueries());
        Call_Type__c callType = EDGE_UtilityTestClass.getCallType(geographyId);
        callType.Global_Equivalent_Call_Type__c = 'Virtual';
        callType.Name = 'Unique Outlet';
        insert callType;
         //System.debug('Condition 6 '+Limits.getQueries());
        Test.startTest();
        Business_Role__c brtest2 = EDGE_UtilityTestClass.getBusinessRole();
        brtest2.My_accounts_Fields_Display__c = 'Outlet_Execution_Score__c;Minimum_Product_Assortment__c;Minimum_Activation_Standards__c;WPA__c;OPPS OPEN;OPPS CLOSED';
        brtest2.Country__c = geographyId;
        insert brtest2;
        //System.debug('Condition 7 '+Limits.getQueries());
        User_Business_Role__c ubrtest2 = EDGE_UtilityTestClass.getuserBusinessRole(qrep, brtest2);
        insert ubrtest2;
        //System.debug('Condition 8 '+Limits.getQueries());
        
        Role_Call__c roleCallRec = new Role_Call__c();
        roleCallRec.Business_Role__c = brtest2.Id;
        roleCallRec.Call_Type__c = callType.Id;
        roleCallRec.KPIs_Active__c = 'Unique Outlets';
        insert roleCallRec;
        //System.debug('Condition 9 '+Limits.getQueries());
        
        //Create Call Rec
        List<Call__c> calls=new List<Call__c>();
        Datetime endDate=System.today();
        Call__c callObj = EDGE_UtilityTestClass.getCallRec(outlet.Id);
        callObj.Type_of_Call__c = callType.Id;
        callObj.Call_Completed_in_Mobile__c = true;
        callObj.Trax_Validation__c = 'Pending';
        callObj.Call_Performed_By__c = qrep.Id;
        callObj.End_Date__c = endDate;
        callObj.Account__c = outlet.Id;
        callObj.Status__c='Completed';
        calls.add(callObj);
        
        //Created Call Rec for ES20-8055
        Call__c callObj1 = EDGE_UtilityTestClass.getCallRec(outlet.Id);
        callObj1.Call_Completed_in_Mobile__c = true;
        callObj1.Trax_Validation__c = 'Pending';
        callObj1.Call_Performed_By__c = qrep.Id;
        callObj1.End_Date__c =endDate.addDays(5);
        callObj1.Account__c = outlet.Id;
        callObj.Status__c='Completed';
        calls.add(callObj1);
        insert calls;
        //System.debug('Condition 10 '+Limits.getQueries());
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Region__c, Serial_Number__c, Scope__c, Job_Group__c from Market_Batch_Setting__mdt 
                                                  where Batch_Class__c = 'Edge_UniqueoutletUserKPIBatch' AND Country_Code__c ='GB'];
        String className = batchSetting.Batch_Class__c;
        system.assert(batchSetting !=null);
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);    
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
        Test.stopTest();
        
    }
}