/**********************************************************************
Name: EDGE_RAGThresholdTriggerHelperTest
=======================================================================
Req: This is the test class for RAGThresholdTrigger,RAGThresholdTriggerHandler,
EDGE_RAGThresholdTriggerHelper
=======================================================================
History                                                            
-------                                                            
VERSION       AUTHOR            DATE              DETAIL
1.0   		  Preyanka Ghosh     30/04/2019      Initial Development
***********************************************************************/
@isTest
public class EDGE_RAGThresholdTriggerHelperTest {
    
    /*******************************************************************
    Method  : testCheckDuplicateEntry
    Purpose : 
    ********************************************************************/
    @isTest
    public static void testCheckDuplicateEntry(){
        
        EDGE_UtilityTestClass.createOrgSettings();
        
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
        
        KPI_RAG_Threshold__c objKPIRAG = EDGE_UtilityTestClass.getOutletKPIRAG(countryId);
        insert objKPIRAG;
        system.assert(objKPIRAG.Id != null,'objKPIRAG should not be null');
        objKPIRAG.High_Threshold__c = 90;
        update objKPIRAG;
        
        
        KPI_RAG_Threshold__c objKPIRAGTerritory = EDGE_UtilityTestClass.getTerritoryKPIRAG(countryId);
        objKPIRAGTerritory.KPI_Type__c = 'MAS';
        insert objKPIRAGTerritory;
        system.assert(objKPIRAGTerritory.Id != null,'objKPIRAGTerritory should not be null');
        
        objKPIRAGTerritory.KPI_Type__c = 'OES';
        update objKPIRAGTerritory;
        
        delete objKPIRAGTerritory;
        delete objKPIRAG;
        
    }
    
    /*******************************************************************
    Method  : checkSharingTest
    Purpose : To check the sharing of object
    ********************************************************************/
    @isTest
    public static void checkSharingTest(){
         //Creating Org setting
        EDGE_UtilityTestClass.createOrgSettings();
        Test.startTest();
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
         //Creating Business Role Record
        KPI_RAG_Threshold__c objKPIRAG = EDGE_UtilityTestClass.getOutletKPIRAG(countryId);
        insert objKPIRAG;
        system.assert(objKPIRAG.Id != null,'objKPIRAG should not be null');
        
        Geography__c country = [SELECT Id, Code__c, Parent_Geography__c FROM Geography__c WHERE Id = :countryId];
        Geography__c secCountry = EDGE_UtilityTestClass.createGeography('Country');
        secCountry.Name = 'Australia Country1';
        secCountry.Code__c = 'AU1';
        secCountry.Parent_Geography__c = country.Parent_Geography__c;
        insert secCountry;
        
        
        objKPIRAG.Country__c = secCountry.Id;
        update objKPIRAG;        
        delete objKPIRAG;
        undelete objKPIRAG;
        Test.stopTest();
    }
    
}