/**
* @description :  EDGE_VirtualPlanCallCompUserKPIBatchTest
* @purpose : This is the test class for EDGE_VirtualPlanCallCompUserKPIBatch
* @history :
* Version   Developer        		   Date         User Story	         Purpose
*  1.0     	Aparajita,Rajarshi      26/05/2022   Initial Development   This is the test class for EDGE_VirtualPlanCallCompUserKPIBatch
*  2.0      Joshraj Sen             08/04/2024   152305 Fixed SCA
*/
@isTest
public class EDGE_VirtualPlanCallCompUserKPIBatchTest {
    
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
        EDGE_UtilityTestClass.createOrgSettings();
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[GB]';
        pickupOption.RecordTypeId = pickupRecordType;
        pickupOption.Status__c = 'Active';
        insert pickupOption;
        
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        outlet.Area__c = geoMap.get('Area');
        outlet.Cluster__c = geoMap.get('Cluster');
        outlet.Country__c = geoMap.get('Country');
        outlet.Hub__c = geoMap.get('Hub');
        outlet.Market__c = geoMap.get('Market'); 
        outlet.Region__c = geoMap.get('Region');
        insert outlet;
        
        Market_Cycle__c marc = EDGE_UtilityTestClass.getMarketCycle(geographyId) ;
        marc.Start_Date__c= System.today()-10;
        marc.End_Date__c=marc.Start_Date__c.addDays(90);
        insert marc;
        
        User testadminUser = EDGE_UtilityTestClass.runAsUser('Admin','System Administrator');    
        insert testadminUser;
        
        List<User> usr = new List<User>();
        User srep = EDGE_UtilityTestClass.runAsUser('Sales Rep','Sales Representative');
        srep.Available_Countries__c = 'GB';
        srep.Email='test.test25@testemail.com';
        srep.Username='test.test25@testemail.com';
        usr.add(srep);
        User srep1 = EDGE_UtilityTestClass.runAsUser('Sales Rep','Sales Representative');
        srep1.Available_Countries__c = 'GB';
        srep1.Email='test.test12225@testemail.com';
        srep1.Username='test.test12225@testemail.com';
		usr.add(srep1);      
        
        insert usr;  
        
        System.debug(LoggingLevel.debug,'--117--'+Limits.getQueries()); 
        Call_Type__c callType = EDGE_UtilityTestClass.getCallType(geographyId);
        callType.Global_Equivalent_Call_Type__c = 'Virtual';
        callType.Name = 'Virtual Call';
        insert callType;
        
        System.debug(LoggingLevel.debug,'--123--'+Limits.getQueries()); 
        Business_Role__c brtest2 = EDGE_UtilityTestClass.getBusinessRole();
        brtest2.My_accounts_Fields_Display__c = 'Outlet_Execution_Score__c;Minimum_Product_Assortment__c;Minimum_Activation_Standards__c;WPA__c;OPPS OPEN;OPPS CLOSED';
        brtest2.Country__c = geographyId;
        insert brtest2;
        System.debug(LoggingLevel.debug,'--128--'+Limits.getQueries());
        List<Call__c> callList=new List<Call__c>();
        
        Test.StartTest();
        //Create Call Rec
        Datetime endDate=System.today();
        Call__c callObj = EDGE_UtilityTestClass.getCallRec(outlet.Id);
        callObj.Type_of_Call__c = callType.Id;
        callObj.Call_Completed_in_Mobile__c = true;
        callObj.Trax_Validation__c = 'Pending';
        callObj.Call_Performed_By__c = srep.Id;
        callObj.End_Date__c = endDate;
        callObj.Account__c = outlet.Id;
        callObj.Status__c='Completed';
        callList.add(callObj);
        
        //Created Call Rec for ES20-8055
        Call__c callObj1 = EDGE_UtilityTestClass.getCallRec(outlet.Id);
        callObj.Type_of_Call__c = callType.Id;
        callObj1.Call_Completed_in_Mobile__c = true;
        callObj1.Trax_Validation__c = 'Pending';
        callObj1.Call_Performed_By__c = srep.Id;
        callObj1.End_Date__c =endDate.addDays(5);
        callObj1.Account__c = outlet.Id;
        callObj.Status__c='Completed';
        callList.add(callObj1);
        
        Call__c callObj2 = EDGE_UtilityTestClass.getCallRec(outlet.Id);
        callObj2.Call_Completed_in_Mobile__c = true;
        callObj2.Trax_Validation__c = 'Pending';
        callObj2.Assigned_To__c=srep.Id;
        callObj2.Plan_Start_Date__c =endDate.addDays(5);
        callObj2.Plan_End_Date__c =endDate.addDays(10);
        callObj2.Account__c = outlet.Id;
        callObj2.Status__c='Planned';
        callList.add(callObj2);
        
        Call__c callObj3 = EDGE_UtilityTestClass.getCallRec(outlet.Id);
        callObj3.Call_Completed_in_Mobile__c = true;
        callObj3.Trax_Validation__c = 'Pending';
        callObj3.Assigned_To__c=srep.Id;
        callObj3.Plan_Start_Date__c =endDate.addDays(9);
        callObj3.Plan_End_Date__c =endDate.addDays(15);
        callObj3.Account__c = outlet.Id;
        callObj3.Status__c='Planned';
        callList.add(callObj3);
        
        Call__c callObj4 = EDGE_UtilityTestClass.getCallRec(outlet.Id);
        callObj.Type_of_Call__c = callType.Id;
        callObj4.Call_Completed_in_Mobile__c = true;
        callObj4.Trax_Validation__c = 'Pending';
        callObj4.Call_Performed_By__c = srep1.Id;
        callObj4.End_Date__c =endDate.addDays(5);
        callObj4.Account__c = outlet.Id;
        callObj4.Status__c='Completed';
        callList.add(callObj4);
        
        insert callList;
        
        List<Call__c> upcall = new List<Call__c>();
        callList[2].Status__c='Completed';
        callList[2].Call_Performed_By__c = srep.Id;
        callList[2].End_Date__c =endDate.addDays(6);
        upcall.add(callList[2]);
        
        callList[3].Status__c='Completed';
        callList[3].Call_Performed_By__c = srep.Id;
        callList[3].End_Date__c =endDate.addDays(10);
        upcall.add(callList[3]);
        
        update upcall;
        
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Region__c, Serial_Number__c, Scope__c, Job_Group__c from Market_Batch_Setting__mdt 
                                                  where Batch_Class__c = 'EDGE_VirtualPlanCallCompUserKPIBatch' AND Country_Code__c ='GB'];
        String className = batchSetting.Batch_Class__c;
        system.assert(batchSetting !=null,'Batch is Added');
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);    
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
        Test.stopTest();
        
    }
}