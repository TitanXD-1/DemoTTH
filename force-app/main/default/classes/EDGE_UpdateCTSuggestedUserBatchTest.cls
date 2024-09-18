/**
*  @ Req: This is the test class for EDGE_UpdateCaseTaskSuggestedUserBatch
*  @ Class Name: EDGE_UpdateCTSuggestedUserBatchTest
*  @ History                    
*  @	Author          Version    				Date           Detail
*  @	Saranya L      Initial Development	   25-01-2022     Created for ES20-11815
*  @  Monalisa Halder     	                   29/04/2022      ES20-12520
**/
@isTest
public class EDGE_UpdateCTSuggestedUserBatchTest {
    static String qualityAssetRecordTypeId = Asset.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality').getRecordTypeId();
    static String qualityRecordTypeId = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality Territory').getRecordTypeId();     
    static String qualityCaseRecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality').getRecordTypeId();

    public static Map<String,Id> geoMap = new Map<String,Id>();
    public static Id countryId = setupCountryGB('GB');

    @isTest
    public static void createCaseTask()
    {
        EDGE_UtilityTestClass.createOrgSettings();
        
        
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[GB]';
        pickupOption.RecordTypeId = pickupRecordType;
        pickupOption.Status__c = 'Active';
        insert pickupOption;

        User testadminUser = EDGE_UtilityTestClass.runAsUser('Admin1','System Administrator');    

        insert testadminUser;
        
        //run as MDM user and update Sales Rep user
        System.runAs(testadminUser) {

        List<User> userList = new List<User>();
        User usr1 = EDGE_UtilityTestClass.runAsUser('TestSalesRep1', 'Quality Representative');
        usr1.Business_Role__c = 'Dispense Rep';
        usr1.Available_Countries__c = 'GB';
        userList.add(usr1);
            
        User usr2 = EDGE_UtilityTestClass.runAsUser('TestSalesRep', 'Quality Representative');
        usr2.Business_Role__c = 'Dispense Rep';
        usr2.Available_Countries__c = 'GB';
        userList.add(usr2);
        insert userList;
       

        
        Business_Role__c busrole = EDGE_UtilityTestClass.getBusinessRole();
        busrole.Country__c = countryId;
        busrole.Global_Equivalent__c ='Dispense Rep';
        busrole.My_accounts_Fields_Display__c='Outlet_Execution_Score__c;Minimum_Product_Assortment__c;Minimum_Activation_Standards__c;WPA__c;OPPS OPEN;OPPS CLOSED';
        insert busrole;
        

        List<User_Business_Role__c> userBusinessRoleList = new List<User_Business_Role__c>();
        User_Business_Role__c ubr = new User_Business_Role__c();
        ubr.Business_Role__c= busrole.Id ;
        ubr.User__c=usr1.Id;
        userBusinessRoleList.add(ubr);
        User_Business_Role__c ubr1 = new User_Business_Role__c();
        ubr1.Business_Role__c = busrole.Id ;
        ubr1.User__c = usr2.Id;
        userBusinessRoleList.add(ubr1);   
        insert userBusinessRoleList;
            
        test.startTest();
        List<Territory__c> terrList = new List<Territory__c>();
        Territory__c territory =  EDGE_UtilityTestClass.getTerritoryRec();
        territory.Country__c = countryId;
        territory.RecordTypeId = qualityRecordTypeId;
        territory.Territory_Type__c = 'Quality Dispense';
        territory.Primary_Sales_Rep__c = usr2.Id;

        terrList.add(territory);
        
        Territory__c territory1 =  EDGE_UtilityTestClass.getTerritoryRec();
        territory1.Country__c = countryId;
		territory1.RecordTypeId = qualityRecordTypeId;
        territory1.Territory_Type__c = 'Service Lead';
        terrList.add(territory1);
        insert terrList;
        
        Territory_Member__c  terrMember = EDGE_UtilityTestClass.getTerrMemberRec();  
        terrMember.User__c = usr1.Id;
        terrMember.Territory__c = territory.Id;
        terrMember.End_Date__c = system.today().AddDays(20);
        terrMember.Type__c = 'Primary';
        insert terrMember;
        


        List<Account> accList = new List<Account>();
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Name = 'CaseT Test Outlet';
        outlet.Country__c = countryId;
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        outlet.BillingStreet = 'Street 1';
        outlet.BillingCity = 'London';


        outlet.Country__c = geoMap.get('Country');
        outlet.Hub__c = geoMap.get('Hub');
        outlet.Region__c=geoMap.get('Region');
        outlet.Area__c=geoMap.get('Area');
        outlet.Market__c = geoMap.get('Market');
        outlet.Cluster__c= geoMap.get('Cluster');

        accList.add(outlet);
        

        Account outlet1 = EDGE_UtilityTestClass.getOutletRecord();
        outlet1.Name = 'CaseT Test Outlet';
        outlet1.Country__c = countryId;
        outlet1.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        outlet1.BillingStreet = 'Street 1';
        outlet1.BillingCity = 'London';
		outlet1.Country__c = geoMap.get('Country');
        outlet1.Hub__c = geoMap.get('Hub');
        outlet1.Region__c=geoMap.get('Region');
        outlet1.Area__c=geoMap.get('Area');
        outlet1.Market__c = geoMap.get('Market');
        outlet1.Cluster__c= geoMap.get('Cluster');    
		accList.add(outlet1);
            
        Account outlet2 = EDGE_UtilityTestClass.getOutletRecord();
        outlet2.Name = 'CaseT Test Outlet1';
        outlet2.Country__c = countryId;
        outlet2.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        outlet2.BillingStreet = 'Street ABC';
        outlet2.BillingCity = 'London';
		outlet2.Country__c = geoMap.get('Country');
        outlet2.Hub__c = geoMap.get('Hub');
        outlet2.Region__c=geoMap.get('Region');
        outlet2.Area__c=geoMap.get('Area');
        outlet2.Market__c = geoMap.get('Market');
        outlet2.Cluster__c= geoMap.get('Cluster');    
		accList.add(outlet2);
        
        insert accList;
        

        List<Outlet_Territory__c> outTerrList = new List<Outlet_Territory__c>();
        Outlet_Territory__c qoutletTer = EDGE_UtilityTestClass.getOutltTerritory(accList[0].Id, territory.Id);
        qoutletTer.Active__c = 'Active';
        outTerrList.add(qoutletTer);
        
        
        Outlet_Territory__c qoutletTer1 = EDGE_UtilityTestClass.getOutltTerritory(accList[1].Id, territory1.Id);
        qoutletTer1.Active__c = 'Active';
        outTerrList.add(qoutletTer1);
        insert outTerrList;
        
        List<Quality_Case_Configuration__c> caseConfigList = new List<Quality_Case_Configuration__c>();
        String caseTypeRecTypeId = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Type').getRecordTypeId();
        Quality_Case_Configuration__c caseConfigType = new Quality_Case_Configuration__c();
        caseConfigType.Name = 'Service [GB]';
        caseConfigType.RecordTypeId = caseTypeRecTypeId;
        caseConfigType.Active__c = true;
        caseConfigType.Country__c = countryId;
        caseConfigList.add(caseConfigType);
        
        String caseTaskSubTypeRecTypeId = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Sub Type').getRecordTypeId();
        Quality_Case_Configuration__c caseConfigSubType = new Quality_Case_Configuration__c();
        caseConfigSubType.Name = 'Maintenance [GB]';
        caseConfigSubType.Case_Type__c = caseConfigType.Id;
        caseConfigSubType.RecordTypeId = caseTaskSubTypeRecTypeId;
        caseConfigSubType.Active__c = true;
        caseConfigSubType.Country__c = countryId;
        caseConfigList.add(caseConfigSubType);
        
        String caseTaskTypeRecTypeId = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Task Type').getRecordTypeId();
        Quality_Case_Configuration__c caseTaskConfig = new Quality_Case_Configuration__c();
        caseTaskConfig.Name = 'Clean Lines';
        caseTaskConfig.Description__c = 'Test Case Configuration Record';
        caseTaskConfig.RecordTypeId = caseTaskTypeRecTypeId;
        caseTaskConfig.Active__c = true;
        caseTaskConfig.Country__c = countryId;
        caseTaskConfig.Default_Business_Role__c ='Dispense Rep';
        caseTaskConfig.Is_Default_Role_Changed__c = true;
        caseConfigList.add(caseTaskConfig);
        
        Quality_Case_Configuration__c caseTaskConfig1 = new Quality_Case_Configuration__c();
        caseTaskConfig1.Name = 'Clean Lines';
        caseTaskConfig1.Description__c = 'Test Case Configuration Record';
        caseTaskConfig1.RecordTypeId = caseTaskTypeRecTypeId;
        caseTaskConfig1.Active__c = true;
        caseTaskConfig1.Country__c = countryId;
        caseTaskConfig1.Default_Business_Role__c ='Service Lead';
        caseTaskConfig1.Is_Default_Role_Changed__c = true;
        caseConfigList.add(caseTaskConfig1);
        
        Insert caseConfigList;
		
        List<Case> caseList = new List<Case>();
        Case caseObj = new Case();
        caseObj.Status = 'New';
        caseObj.RecordTypeId = qualityCaseRecordTypeId;
        caseObj.AccountId = outlet.Id;
        caseObj.Case_Type__c = caseConfigType.Id;
        caseObj.Case_Sub_Type__c = caseConfigSubType.Id;
		caseList.add(caseObj);
            
        Case caseObj1 = new Case();
        caseObj1.Status = 'New';
        caseObj1.RecordTypeId = qualityCaseRecordTypeId;
        caseObj1.AccountId = outlet2.Id;
        caseObj1.Case_Type__c = caseConfigType.Id;
        caseObj1.Case_Sub_Type__c = caseConfigSubType.Id;    
		caseList.add(caseObj1); 
        
        Case caseObj2 = new Case();
        caseObj2.Status = 'New';
        caseObj2.RecordTypeId = qualityCaseRecordTypeId;
        caseObj2.AccountId = outlet1.Id;
        caseObj2.Case_Type__c = caseConfigType.Id;
        caseObj2.Case_Sub_Type__c = caseConfigSubType.Id;    
		caseList.add(caseObj2);
        insert caseList;
        
        List<Case_Task__c> caseTaskList = new List<Case_Task__c>();    
        Case_Task__c ct = new Case_Task__c();
        ct.Case__c = caseObj.Id;
        ct.Account__c = outlet.Id;
        ct.Case_Task_Type__c = caseTaskConfig.Id;
        ct.Achievement_Status__c = 'Pending';
        ct.Country__c = countryId;
        ct.Reason_Comments__c= 'test';
        ct.Suggested_User__c = null;
        caseTaskList.add(ct);
        
        Case_Task__c ct1 = new Case_Task__c();
        ct1.Case__c = caseObj.Id;
        ct1.Account__c = outlet.Id;
        ct1.Case_Task_Type__c = caseTaskConfig.Id;
		ct1.Achievement_Status__c = 'Open';
        ct1.Suggested_User__c = usr2.Id;
        ct1.Country__c = countryId;
		caseTaskList.add(ct1);  
            
        Case_Task__c ct2 = new Case_Task__c();
        ct2.Case__c = caseObj1.Id;
        ct2.Account__c = outlet2.Id;
        ct2.Case_Task_Type__c = caseTaskConfig.Id;
        ct2.Achievement_Status__c = 'Open';
        ct2.Country__c = countryId;
        ct2.Reason_Comments__c= 'test';
        ct2.Suggested_User__c = usr2.Id;  
        caseTaskList.add(ct2); 
        
        Case_Task__c ct3 = new Case_Task__c();
        ct3.Case__c = caseObj2.Id;
        ct3.Account__c = outlet1.Id;
        ct3.Case_Task_Type__c = caseTaskConfig1.Id;
        ct3.Achievement_Status__c = 'Open';
        ct3.Country__c = countryId;
        ct3.Reason_Comments__c= 'test';
        ct3.Suggested_User__c = usr2.Id;  
        caseTaskList.add(ct3);
        insert caseTaskList;
            
        territory.Primary_Sales_Rep__c = usr1.Id;
        Update territory;
            

		test.stopTest();
        Market_Batch_Setting__mdt batchSetting = [SELECT MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_UpdateCaseTaskSuggestedUserBatch'
                                                  AND Country_Code__c='GB' LIMIT 1];
        system.assertNotEquals(batchSetting.Id,null,'Batch setting is Null');
        String className = batchSetting.Batch_Class__c;
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
        }
    }



    public static Id setupCountryGB(string countryCode){
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
        
        return country.Id;       
    }



}