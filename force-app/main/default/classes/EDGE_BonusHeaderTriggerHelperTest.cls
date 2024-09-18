/**********************************************************************
Name: EDGE_BonusHeaderTriggerHelperTest
=======================================================================
Purpose: This is to handle EDGE_BonusHeaderTriggerHelper
=======================================================================
History                                                            
-------                                                            
VERSION  AUTHOR            DATE              DETAIL
1.0      Shahbaz Khan     20/01/2020      Initial Development
***********************************************************************/
@isTest
public class EDGE_BonusHeaderTriggerHelperTest {
    
    @isTest
    public static void bonusHeaderTriggerHelperTest(){
        Id countryid= EDGE_UtilityTestClass.setupCountry('AU');

        Map<String,Id> geoMap = EDGE_UtilityTestClass.getGeoMap();
        Id clusterId = geoMap.get('Cluster');
        Geography__c country = createGeography('Country');
        country.Name = 'Australia1';
        country.Code__c = 'AUT1';
        country.Parent_Geography__c = clusterId;
        insert country;
        
        EDGE_UtilityTestClass.createOrgSettings();
        
        Territory__c territoryObj = EDGE_UtilityTestClass.getTerritoryRec();
        territoryObj.Territory_Type__c = 'Service';
        territoryObj.Country__c = countryId;
        insert territoryObj;
        
        Market_Cycle__c markCycle = new Market_Cycle__c();
        markCycle.Geography__c = countryid;
        markCycle.Start_Date__c = system.today();
        markCycle.End_Date__c = system.today() + 2;
        insert markCycle;
        
        Territory_Cycle__c terrCycle = new Territory_Cycle__c();
        terrCycle.Market_Cycle__c = markCycle.Id;
        terrCycle.Territory__c = territoryObj.Id;
        insert terrCycle;
        
        
        Bonus_Header__c bonusHeader = new Bonus_Header__c();
        bonusHeader.Country__c = countryid;
        bonusHeader.Status__c = 'Draft';
        bonusHeader.Max_Cap_total_Bonus__c = 52;
        insert bonusHeader;
        system.assert(bonusHeader.Id!=null,'bonusheader Id should not be null');
        
        Bonus_Assignment__c bonusAssignment1 = new Bonus_Assignment__c();
        bonusAssignment1.Bonus_Header__c = bonusHeader.Id;
        bonusAssignment1.Territory__c = territoryObj.Id;
        bonusAssignment1.Global_Percentage__c = 60;
        bonusAssignment1.Territory_Percentage__c = 30;
        bonusAssignment1.Total__c = 90;
        insert bonusAssignment1;
        
        Bonus_Cycle__c bonusCycle = new Bonus_Cycle__c();
        bonusCycle.Bonus_Header__c = bonusHeader.Id;
        bonusCycle.Market_Cycle__c = markCycle.Id;
        insert bonusCycle;
        
       
        bonusHeader.Country__c = country.Id;
        bonusHeader.Status__c = 'Active';
        update bonusHeader;
        
        
        
        delete bonusHeader;
        undelete bonusHeader;
        
        
    }
     public static Geography__c createGeography(String recordtypeName){
        Geography__c geography = new Geography__c();
        geography.RecordTypeId =  Geography__c.sObjectType.getDescribe().getRecordTypeInfosByName().get(recordtypeName).getRecordTypeId();
        return geography;
    }
    
    
}