/**

* @description :  EDGE_TerritoryProcessRepDeleteBatchTest

* @purpose : Test Class for insert batch 

* @history :

* Version    Developer             Date             User Story/Purpose

* 1.1     Anuja Chattopadhyay     02/03/2019        Initial Development
* 1.2     Mayukh S Roy            28/12/2022        ES20-13681
*/

@isTest
Public  class EDGE_TerritoryProcessRepDeleteBatchTest{
    @isTest
    public static void testCreateData(){
        List<Territory_Member__c> trListMemList = new List<Territory_Member__c>();
        Id country = EDGE_UtilityTestClass.setupCountry('AU');
        User u1  = EDGE_UtilityTestClass.runAsUser('SalesRep','Sales Representative');
        u1.Trax_User__c=True;
        Insert u1;
        
        User u2  = EDGE_UtilityTestClass.runAsUser('SalesRep','Sales Representative');
        Insert u2;
        
        List<Account> accList = new List<Account>();
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Name = 'Test Outlet 1';
        outlet.Country__c = country;
        accList.add(outlet);
        Account outlet2 = EDGE_UtilityTestClass.getOutletRecord();
        outlet2.Name = 'Test Outlet 2';
		outlet2.Country__c = country;        
        insert accList;
        
        Territory__c territoryObj =  EDGE_UtilityTestClass.getTerritoryRec();
        territoryObj.Country__c = country;
        insert territoryObj;
        system.assert(territoryObj.Id!=Null,'TerritoryId Null');
        
        Outlet_Territory__c  outletTerritory  =  EDGE_UtilityTestClass.getOutltTerritory(outlet.Id, territoryObj.Id);
        outletTerritory.Active__c = 'Active';
        insert outletTerritory;
        
        Territory_Member__c trListMemObj1 = EDGE_UtilityTestClass.getPrimaryTerrMemberRec(u1.id,territoryObj.id );
        trListMemObj1.Start_Date__c = Date.today()-10;
        trListMemObj1.End_Date__c = Date.today()-1;
        Territory_Member__c trListMemObj2 = EDGE_UtilityTestClass.getSecondaryTerrMemberRec(u2.id,territoryObj.id);
        trListMemObj2.Start_Date__c = Date.today()-10;
        trListMemObj2.End_Date__c = Date.today()-1;
        trListMemList.add(trListMemObj1);
        trListMemList.add(trListMemObj2);
        
        insert trListMemList;
        
        List<Outlet_Member__c> oMList = new List<Outlet_Member__c>();
        Outlet_Member__c outletmem = EDGE_UtilityTestClass.getOutletMemberRecord(outlet.id, u1.id, 'Primary');
        oMList.add(outletmem);
        Outlet_Member__c outletmem2 = EDGE_UtilityTestClass.getOutletMemberRecord(outlet.id, u2.id, 'Secondary');
        oMList.add(outletmem2);
        
        insert oMList;
        
    }
    @isTest
    public static void testTerritoryProcessBatch(){
        
        testCreateData(); 
        Test.startTest();   
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_TerritoryProcessRepDeleteBatch'
                                                  and Country_Code__c ='AU' ];
        String className = batchSetting.Batch_Class__c;
        
        List<Territory_Member__c> terrMemList= [SELECT Id,Name from Territory_Member__c];
        system.assert(terrMemList.size()>0,'Territory Member present');
        
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
        
        Test.stopTest();
        
    }
    
    
}