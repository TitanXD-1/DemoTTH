/**
*@Name: EDGE_KPITargetTriggerHelperTest

*@History                                                            
                                                           
*@	VERSION     AUTHOR           DATE            DETAIL
*@	1.0         Dipanjan Das     16/05/2019      Test Class for EDGE_KPITargetTriggerHelper
*@  2.0         Joshraj Sen      10/05/2024      153343
**/
@isTest
public class EDGE_KPITargetTriggerHelperTest{
    
    @isTest
    public static void testpopulateOutletSOSKPIs(){
        createData();
        List<Territory__c> territoryList= [select Id from Territory__c];
        System.assert(territoryList.size()>0,'territory List size greater than 0');
    }
    
    
    public static void createData(){
    
        EDGE_UtilityTestClass.createOrgSettings();
        
         Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');  
         String terrHierBURecordTypeId = Territory_Hierarchy__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Business Unit').getRecordTypeId();
         String terrHierSARecordTypeId = Territory_Hierarchy__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Sales Area').getRecordTypeId();
         String terrHierRGRecordTypeId = Territory_Hierarchy__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Region').getRecordTypeId();
       /* Territory_Hierarchy__c territoryhier=EDGE_UtilityTestClass.getTerritoryHierarchy( countryId, TerritoryhieRecordTypeId );
        insert territoryhier; */
        
        Territory_Hierarchy__c terrHirBU = new Territory_Hierarchy__c();
        terrHirBU.RecordTypeId =terrHierBURecordTypeId;
        terrHirBU.Name = 'Australia Territory Hierarchy';
        terrHirBU.Geography__c = countryId;
        insert terrHirBU;
        
        Territory_Hierarchy__c terrHirSA = new Territory_Hierarchy__c();
        terrHirSA.RecordTypeId =terrHierSARecordTypeId;
        terrHirSA.Name = 'Australia Territory Hierarchy';
        terrHirSA.Geography__c = countryId;
        terrHirSA.Parent_BU__c = terrHirBU.Id;
        insert terrHirSA;
        
        Territory_Hierarchy__c terrHirRG = new Territory_Hierarchy__c();
        terrHirRG.RecordTypeId =terrHierRGRecordTypeId;
        terrHirRG.Name = 'Australia Territory Hierarchy';
        terrHirRG.Geography__c = countryId;
        terrHirRG.Parent_BU__c = terrHirSA.Id;
        insert terrHirRG;
   
        Territory__c territory = EDGE_UtilityTestClass.getTerritoryRec();
        territory.Territory_Type__c = 'Sales';
        territory.Region__c = terrHirRG.id;
		test.startTest();
        insert territory;
        
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        insert pickupOption;                
        
        Account outlet = EDGE_UtilityTestClass.getOutletRecord(); 
        outlet.Global_Segment__c = 'Hypermarket';
        outlet.Global_Sub_Segment__c = 'Modern Hypermarket';
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        outlet.Primary_Sales_Territory__c = territory.Id;
        insert outlet; 
        
        KPIs_Target__c kpiTarget = new KPIs_Target__c();
        kpiTarget.Category__c = 'Beer';
        kpiTarget.Segment__c = 'Hypermarket';
        kpiTarget.Target__c = 74.00;
        kpiTarget.Territory__c = territory.Id;
        insert kpiTarget; 
        
        KPIs_Target__c kpiTarget2 = new KPIs_Target__c();
        kpiTarget2.Category__c = 'Wine';
        kpiTarget2.Segment__c = 'Hypermarket';
        kpiTarget2.Sub_Segment__c = 'Modern Hypermarket';
        kpiTarget2.Target__c = 74.00;
        kpiTarget2.Territory__c = territory.Id;
        insert kpiTarget2; 
        
      
        
		/*
        KPIs_Target__c kpiTarget1 = [SELECT Id FROM KPIs_Target__c LIMIT 1];
        kpiTarget1.Target__c = 76.00;
        update kpiTarget1;
        System.assert(kpiTarget.Id!=null,'kpi Target Id should not be null');
        kpiTarget1.Segment__c = 'Supermarket';
        update kpiTarget1;
        */
        Outlet_KPI_Achievement__c ok =new Outlet_KPI_Achievement__c();
        ok.Target__c=100;
        ok.Category__c='Gin';
        ok.Outlet__c=outlet.Id;
        ok.Unique_Id__c=outlet.Id+'_SoS_Gin';
        insert ok;
        Map<String,Outlet_KPI_Achievement__c> map1=new Map<String,Outlet_KPI_Achievement__c>();
        map1.put(outlet.Id+'_SoS_Gin',ok);
        EDGE_OutletKPIWrapper outletKPIWrapper = new EDGE_OutletKPIWrapper();
        outletKPIWrapper.mapOutletKPI=map1;
        Map<String,String> map2=new Map<String,String>();
        map2.put('Category','Gin');
        EDGE_KPITargetOperations.getOutletKPI(map2,outletKPIWrapper,outlet);
        delete [SELECT Id FROM KPIs_Target__c LIMIT 2];

        test.stopTest();
    }       
}