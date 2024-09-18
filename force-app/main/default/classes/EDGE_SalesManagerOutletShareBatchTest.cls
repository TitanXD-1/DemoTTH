/**

* @description :  EDGE_SalesManagerOutletShareBatchTest

* @purpose : This is the test class for EDGE_SalesManagerOutletShareBatch

* @history :

* Version    Developer         Date           User Story/Purpose

*  1.1      Sandip Ghosh      11/03/2019      Initial Development
*  1.2      Mayukh S Roy      30/01/2023      ES20-13558

*/
@istest
public class EDGE_SalesManagerOutletShareBatchTest {
    
    final static String SALESTERRITORYRECORDTYPEID = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Sales Territory').getRecordTypeId();     
    final static String QUALITYTERRITORYRECORDTYPEID = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality Territory').getRecordTypeId();
    public static Id countryId;
    public static Date currentDate = Date.today();
    @istest
    public static void testSalesManagerSharing(){
        
        
        createtestData();
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_SalesManagerOutletShareBatch'
                                                  and Country_Code__c ='AU' LIMIT 1];
        String className = batchSetting.Batch_Class__c;
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        system.assert(batchSetting.id != null,'Batch Setting Preset');
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));            
    }
    
    public static void createtestData(){
        countryId = EDGE_UtilityTestClass.setupCountry('AU');
        
        EDGE_UtilityTestClass.createOrgSettings();
        updateOrgSettings();
		        
        Test.startTest();
        List<User> usrList = new List<User>();
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('Admin','System Administrator');
        usrList.add(testAdminUser);
        User testMDMUser = EDGE_UtilityTestClass.runAsUser('testAdmin','Sales Manager');
        usrList.add(testMDMUser);
        User testQualityUser = EDGE_UtilityTestClass.runAsUser('testAdmin','Quality Manager');
        usrList.add(testQualityUser);
        insert usrList;
        
        System.runAs(testAdminUser){
        
        Map<String,Territory_Hierarchy__c> setHierarchyMap = setHierarchy();
        Territory_Hierarchy__c terriHier = setHierarchyMap.get('Region');
       	Territory_Hierarchy__c terriHier1 = setHierarchyMap.get('Quality Territory Hierarchy');
            
        List<Business_Role__c> brList = new List<Business_Role__c>();
        brList.add(getBR(testQualityUser,'Dispense Manager'));
        brList.add(getBR(testMDMUser,'Sales Manager'));
        
        List<Territory_Hierarchy_Member__c> members=new List<Territory_Hierarchy_Member__c>();
        Territory_Hierarchy_Member__c terrHierMem = createthmember(testMDMUser.Id,terriHier.Id);
        terrHierMem.Start_Date__c = currentDate;
        terrHierMem.End_Date__c = currentDate.addDays(10);
        members.add(terrHierMem);
        
        Territory_Hierarchy_Member__c terrHierMem1 = createthmember(testMDMUser.Id,terriHier.Id);
        terrHierMem1.Start_Date__c = currentDate;
        terrHierMem1.End_Date__c = currentDate.addDays(1);        
        members.add(terrHierMem1);
            
        // Quality Territory Hierarchy member 
        Territory_Hierarchy_Member__c terrHieMem1 = createthmember(testQualityUser.Id,terriHier1.Id);
        terrHieMem1.Start_Date__c = Date.today();
        members.add(terrHieMem1);
        insert members;

        
        Territory__c terr = EDGE_UtilityTestClass.getTerritoryRec();
        terr.Territory_Type__c ='Sales';
        terr.Region__c=terriHier.Id;
        terr.RecordTypeId = SALESTERRITORYRECORDTYPEID; 
        insert terr;
        
        Territory__c terr1 = EDGE_UtilityTestClass.getTerritoryRec();
        terr1.Territory_Type__c ='Quality Dispense';
        terr1.Region__c=terriHier1.Id;
        terr1.RecordTypeId = QUALITYTERRITORYRECORDTYPEID;
        insert terr1;

        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AU]';
        insert pickupOption;
        Test.stopTest();
        
        List<Account> outletList = new List<Account>();
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Name = 'test Out 2554';
        setAddress(outlet);
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        outletList.add(outlet);
        
        //Quality Outlets 
        Account outlet1 = EDGE_UtilityTestClass.getOutletRecord();   
        outlet1.Name = 'test Out 123';
        setAddress(outlet1);
        outlet1.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        outletList.add(outlet1);
        insert outletList;
        
        List<Outlet_Territory__c> otList = new List<Outlet_Territory__c>();
        Outlet_Territory__c outTerr1 = EDGE_UtilityTestClass.getOutltTerritory(outlet1.Id, terr1.Id);
        outTerr1.Active__c ='Active';
        otList.add(outTerr1);
        
        Outlet_Territory__c outTerr2 = EDGE_UtilityTestClass.getOutltTerritory(outlet1.Id, terr.Id);
        outTerr2.Active__c ='Active';
        otList.add(outTerr2);
        insert otList;
        
        Outlet_Member__c om = new Outlet_Member__c();
        om.User__c = testMDMUser.Id;
        om.Outlet__c = outlet1.Id;
        insert om;
        }
    }
    
    public static Account setAddress(Account outlet){
        outlet.BillingStreet = '95 Malasian Lowway 1';
        outlet.BillingCity = 'Tasmania';
        outlet.BillingCountry = 'Australia';
        outlet.BillingState = 'Tasmania';
        outlet.BillingPostalCode = '5668';
        outlet.BillingCountryCode = 'AU';
        return outlet;
    }
  

    public static Territory_Hierarchy_Member__c createthmember(Id user,Id terriHier){ 
        Territory_Hierarchy_Member__c terrHieMem1 = new Territory_Hierarchy_Member__c();
        terrHieMem1.User__c = user;
        terrHieMem1.Territory_Hierarchy__c = terriHier;
        return terrHieMem1;
    }
    
    public static void updateOrgSettings(){
        Org_Setting__c orgSetting = Org_Setting__c.getOrgDefaults();
        orgSetting.Run_Validation_Rules__c=false;
        orgSetting.Run_Triggers__c =false;
        update orgSetting;
    }
    
    public static Map<String,Territory_Hierarchy__c> setHierarchy(){
        Map<String,Territory_Hierarchy__c> setHierarchyMap = new Map<String,Territory_Hierarchy__c>();
        Territory_Hierarchy__c terriHierBU = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Business Unit');
        insert terriHierBU;
        
        Territory_Hierarchy__c terriHierSA = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Sales Area');
        terriHierSA.Parent_BU__c = terriHierBU.Id;
        insert terriHierSA;
        
        Territory_Hierarchy__c terriHier = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Region');
        terriHier.Parent_BU__c = terriHierSA.Id;
        insert terriHier;
        setHierarchyMap.put('Region',terriHier);
            
        //Quality Territory Hierarchy
        Territory_Hierarchy__c terriHier1 = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Quality Territory Hierarchy');
        terriHier1.Parent_BU__c = terriHierSA.Id;
        terriHier1.Territory_Hierarchy_Type__c = 'Dispense Manager';
        insert terriHier1;
        setHierarchyMap.put('Quality Territory Hierarchy',terriHier1);
        return setHierarchyMap;
    }
    
    public static Business_Role__c getBR(User user,String equivalent){
        Business_Role__c businessRoleObj = EDGE_UtilityTestClass.getBusinessRole();
        businessRoleObj.My_accounts_Fields_Display__c = 'Outlet_Execution_Score__c;Minimum_Product_Assortment__c;Minimum_Activation_Standards__c;OPPS OPEN;OPPS CLOSED';
        businessRoleObj.Country__c = countryId;
        businessRoleObj.Global_Equivalent__c = equivalent;
        insert businessRoleObj;
        insert (EDGE_UtilityTestClass.getuserBusinessRole(user,businessRoleObj));
        return businessRoleObj;
    }
}