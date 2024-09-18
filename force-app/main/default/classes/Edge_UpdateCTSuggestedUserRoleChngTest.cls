/**
*  @ Req: This is the test class for Edge_UpdateCTSuggestedUserRoleChng
*  @ Class Name: Edge_UpdateCTSuggestedUserRoleChngTest
*  @ History                    
*  @	Author             Version    				Date           Detail
*  @	Sudipta Nandi      Initial Development	   25-01-2022     Created for ES20-11823
*  @    Swaraj Samanta     2.0                     06-09-2022     Test Class Correction Due to Failure-ES20-13284
**/
@isTest
public class Edge_UpdateCTSuggestedUserRoleChngTest {
    
    final static String qualityAssetRecordTypeId = Asset.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality').getRecordTypeId();
    final static String QualityRecordTypeId = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality Territory').getRecordTypeId();     
    final static String qualityCaseRecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality').getRecordTypeId();
    
    public static Map<String,Id> geoMap = new Map<String,Id>();
    @isTest
    public static void createCaseTask()
    {
        EDGE_UtilityTestClass.createOrgSettings();  
        Id countryId = setupCountryGB('GB');
        //System.debug('Condition 1 '+Limits.getQueries());
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[GB]';
        pickupOption.RecordTypeId = pickupRecordType;
        pickupOption.Status__c = 'Active';
        insert pickupOption;
        //System.debug('Condition 2 '+Limits.getQueries());
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
        insert outlet;
        //System.debug('Condition 3 '+Limits.getQueries());
        List<User> users =new List<User>();
        User useradmin=EDGE_UtilityTestClass.runAsUser('TestAdmin', 'System Administrator');
        users.add(useradmin);
        User usr1 = EDGE_UtilityTestClass.runAsUser('TestSalesRep', 'Quality Representative');
        usr1.Business_Role__c = 'Dispense Rep';
        usr1.Available_Countries__c = 'GB';
        users.add(usr1);
        insert users;   
        //System.debug('Condition 4 '+Limits.getQueries());
        Test.startTest();
        System.runAs(useradmin) {
            Business_Role__c busrole = EDGE_UtilityTestClass.getBusinessRole();
            busrole.Country__c = countryId;
            busrole.Global_Equivalent__c ='Dispense Rep';
            busrole.My_accounts_Fields_Display__c='Outlet_Execution_Score__c; Minimum_Product_Assortment__c; Minimum_Activation_Standards__c; New_Product_Distribution__c;WPA__c; OPPS OPEN; OPPS CLOSED';
            insert busrole;
            //System.debug('Condition 5 '+Limits.getQueries());
            
            User_Business_Role__c ubr = new User_Business_Role__c();
            ubr.Business_Role__c= busrole.Id ;
            ubr.User__c=usr1.Id;
            insert ubr; 
            //System.debug('Condition 6 '+Limits.getQueries());
            Territory__c territory =  EDGE_UtilityTestClass.getTerritoryRec();
            territory.Country__c = countryId;
            territory.RecordTypeId = QualityRecordTypeId;
            territory.Territory_Type__c = 'Quality Dispense';
            territory.Primary_Sales_Rep__c=usr1.Id;
            insert territory;
            //System.debug('Condition 7 '+Limits.getQueries());
            Outlet_Territory__c qoutletTer = EDGE_UtilityTestClass.getOutltTerritory(outlet.Id, territory.Id);
            qoutletTer.Active__c = 'Active';    
            insert qoutletTer; 
            //System.debug('Condition 8 '+Limits.getQueries());
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
            caseTaskConfig.Is_Default_Role_Changed__c = true;
            caseTaskConfig.Default_Business_Role__c ='Dispense Rep';
            caseConfigList.add(caseTaskConfig);            
            Insert caseConfigList;
            //System.debug('Condition 9 '+Limits.getQueries());
            Case caseObj = new Case();
            caseObj.Status = 'New';
            caseObj.RecordTypeId = qualityCaseRecordTypeId;
            caseObj.AccountId = outlet.Id;
            caseObj.Case_Type__c = caseConfigType.Id;
            caseObj.Case_Sub_Type__c = caseConfigSubType.Id;
            insert caseObj;
            //System.debug('Condition 10 '+Limits.getQueries());
            Case_Task__c ct = new Case_Task__c();
            ct.Case__c = caseObj.Id;
            ct.Account__c = outlet.Id;
            ct.Case_Task_Type__c = caseTaskConfig.Id;
            ct.Achievement_Status__c = 'Open';
            ct.Country__c = countryId;
            insert ct;
            //System.debug('Condition 11 '+Limits.getQueries());
            test.stopTest();
            Market_Batch_Setting__mdt batchSetting = [SELECT MasterLabel, Batch_Class__c, Country_Code__c,
                                                      Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'Edge_UpdateTaskSuggestedUserOnRoleChange'
                                                      AND Country_Code__c='GB' LIMIT 1];
            system.assert(batchSetting.Id != null);
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
        upsert globalRec;
        geoMap.put('Global3',globalRec.Id);
        
        Geography__c market = EDGE_UtilityTestClass.createGeography('Market');
        market.Name = 'Europe and Turkey';
        market.Code__c = 'EU';
        market.Parent_Geography__c = globalRec.Id;
        market.RecordTypeId=EDGE_UtilityTestClass.marketRecTypeId;
        upsert market;
        //marketMap.put('Market',market.Id);
        geoMap.put('Market',market.Id);
        
        Geography__c hub = EDGE_UtilityTestClass.createGeography('Hub');
        hub.Name = 'Great Britain Hub';
        hub.Code__c = 'GBH';
        hub.Parent_Geography__c = market.Id;
        hub.RecordTypeId=EDGE_UtilityTestClass.HubRecTypeId;
        upsert hub;
        geoMap.put('Hub',hub.Id);
        
        
        Geography__c cluster = EDGE_UtilityTestClass.createGeography('Cluster');
        cluster.Name = 'Great Britain Cluster';
        cluster.Code__c = 'GBC';
        cluster.Parent_Geography__c = hub.Id;
        cluster.RecordTypeId=EDGE_UtilityTestClass.ClusterRecTypeId;
        upsert cluster;
        geoMap.put('Cluster',cluster.Id);
        
        Geography__c country = EDGE_UtilityTestClass.createGeography('Country');
        country.Name = 'Great Britain Country';
        country.Code__c = countryCode;
        country.Parent_Geography__c = cluster.Id;
        country.RecordTypeId=EDGE_UtilityTestClass.CountryRecTypeId;
        upsert country;
        geoMap.put('Country',country.Id);
        
        
        Geography__c area = EDGE_UtilityTestClass.createGeography('Area');
        area.Name = 'Great Britain Area';
        area.Code__c = 'GBA';
        area.Parent_Geography__c = country.Id;
        area.RecordTypeId=EDGE_UtilityTestClass.AreaRecTypeId;
        upsert area;
        geoMap.put('Area',area.Id);        
        
        Geography__c region = EDGE_UtilityTestClass.createGeography('Region');
        region.Name = 'Central Region';
        region.Code__c = 'GB05';
        region.Parent_Geography__c = area.Id;
        region.RecordTypeId=EDGE_UtilityTestClass.RegionRecTypeId;
        upsert region;
        geoMap.put('Region',region.Id);
        
        return country.Id;       
    }	
    
}