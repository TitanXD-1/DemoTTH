/**

* @description :  EDGE_TerritoryHierarchySalesMgrBatchTest

* @purpose : This is the test class for EDGE_TerritoryHierarchySalesManagerBatch

* @history :

* Version    Developer         Date             User Story/Purpose

*  1.1      Dipanjan Das     30/07/2019      Initial Development
*  1.2		Shivam Chauhan	 18/07/2023		142554 - EDGE static code violation for the classes_SFDC_Tech Debt

*/

@isTest
public class EDGE_TerritoryHierarchySalesMgrBatchTest{
    @isTest 
    public static void testSalesManagerBatch(){
        Test.startTest(); 
        
        createData();
        
        
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_TerritoryHierarchySalesManagerBatch'
                                                  and Country_Code__c ='AU' LIMIT 1];
        String className = batchSetting.Batch_Class__c;
        Type t = Type.forName(className);
        
        List<Territory_Hierarchy_member__c> terriHierList= [SELECT Id,Name from Territory_Hierarchy_member__c];
        system.assert(terriHierList.size()>0,'terriHierList size should be grater than 0');
        
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
        Test.stopTest();         
        
    }
    
    
    public static void createData(){    
        
        Date currentDate = Date.today();
        Date endDate = currentDate.addDays(10);
        
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        User testMDMUser = EDGE_UtilityTestClass.runAsUser('EDGEMDM','Master Data Manager');    
        insert testMDMUser; 
        system.assert(testMDMUser.Id!=null,'testMDMUser Id should not be null');
        
        User testSalesMgrUser = EDGE_UtilityTestClass.runAsUser('EDGESALESMGR','Sales Manager');    
        insert testSalesMgrUser; 
        system.assert(testSalesMgrUser.Id!=null,'testSalesMgrUser Id should not be null');
        
        User testMDMUser1 = EDGE_UtilityTestClass.runAsUser('EDGEMDM1','Master Data Manager');    
        insert testMDMUser1;        
        
        User testREPUser = EDGE_UtilityTestClass.runAsUser('EDGEREP','Sales Representative');    
        insert testREPUser;     
        //EDGE_UtilityTestClass.createOrgSettings();
        
        Market_Setting__c mktSetting = EDGE_UtilityTestClass.getMarketSetting(countryId);
        mktSetting.Car_Change_Approval__c = 'No Approval Required';
        mktSetting.Display_in_Kilometer__c = True;
        mktSetting.Fleet_Manager__c = 'test@2121.com';
        mktSetting.Threshold_Format__c = 'Percent';
        mktSetting.Last_Travel_Log_Date__c = system.today();
        insert mktSetting;
        Territory_Hierarchy__c terriHierBU = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Business Unit');
        insert terriHierBU;
        
        Territory_Hierarchy__c terriHierSA = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Sales Area');
        terriHierSA.Parent_BU__c = terriHierBU.Id;
        insert terriHierSA;
        
        Territory_Hierarchy__c terriHier = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Region');
        terriHier.Parent_BU__c = terriHierSA.Id;
        insert terriHier;
        
        Territory_Hierarchy_member__c terrHierMem = new Territory_Hierarchy_member__c();
        terrHierMem.Territory_Hierarchy__c = terriHier.Id;
        terrHierMem.User__c= testSalesMgrUser.Id;
        terrHierMem.Start_Date__c = currentDate.addDays(-1);
        terrHierMem.End_Date__c = endDate;
        
        insert terrHierMem;     
        
        Territory_Hierarchy_member__c terrHierMem1 = new Territory_Hierarchy_member__c();
        terrHierMem1.Territory_Hierarchy__c = terriHier.Id;
        terrHierMem1.User__c= testSalesMgrUser.Id;
        terrHierMem1.Start_Date__c = currentDate.addDays(-10);
        terrHierMem1.End_Date__c = currentDate.addDays(-1);
        
        insert terrHierMem1;
        
        Territory__c  territory = EDGE_UtilityTestClass.getTerritoryRec();
        territory.Current_OES_Rank__c= 12.0;
        territory.Country__c = countryId;
        territory.Current_OES_Score__c = 10.0;
        territory.Current_OES_Rank__c = 11.0;
        territory.Territory_Type__c = 'Sales';
        territory.Sales_Area__c = terriHierSA.Id; 
        territory.Region__c = terriHier.Id;
        territory.Status__c = 'Active';     
        
        insert territory;
        
        Territory_Member__c  terrMember = EDGE_UtilityTestClass.getTerrMemberRec();  
        terrMember.User__c = testREPUser.Id;
        terrMember.Territory__c = territory.Id;
        terrMember.End_Date__c = system.today().AddDays(7);
        terrMember.Type__c = 'Primary';
        insert terrMember; 
        
        EDGE_UtilityTestClass.createOrgSettings();      
        
        Territory_Hierarchy_member__c terrHierMem2 = new Territory_Hierarchy_member__c();
        terrHierMem2.Territory_Hierarchy__c = terriHier.Id;
        terrHierMem2.User__c= testMDMUser.Id;
        terrHierMem2.Start_Date__c = currentDate.addDays(-10);
        terrHierMem2.End_Date__c = currentDate.addDays(-1);
        try{
            insert terrHierMem2;        
        }catch(Exception ex){
            System.debug(LoggingLevel.Debug,'excption::::'+ex.getMessage());
            
        }
        
        Coaching_Report__c coachingReport = new Coaching_Report__c();
        coachingReport.Current_Sales_Manager__c = testMDMUser.Id;
        coachingReport.Sales_Representative__c = testREPUser.Id;
        coachingReport.Status__c = 'Draft';
        coachingReport.Report_Date__c = system.today();        
        insert coachingReport;
        
        Personal_Information__c pInfoRec = new Personal_Information__c();
        pInfoRec.user__c = testREPUser.Id;
        pInfoRec.Sales_Manager__c = testMDMUser.Id;
        pInfoRec.Car_Approval_Status__c = 'pending';
        pInfoRec.Car_Model__c = 'Hyndai123';
        insert pInfoRec;
        
        
        travel_log__c tLog = new Travel_Log__c();
         tLog.Personal_Information__c = pInfoRec.id;
        tLog.Start_Date__c = system.today();
        tLog.End_Date__c = system.today().addDays(10);
          tLog.Odometer_End_Reading__c = 123;
        tLog.Odometer_Start_Reading__c = 100;
        insert  tLog;
        
        pInfoRec.New_Car_Model__c = 'BMW i15 Series';
        update pInfoRec;
            
            
        
    }
}