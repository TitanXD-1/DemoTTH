/**********************************************************************
Name: EDGE_TemplateWeighingTriggerHelperTest
=======================================================================
Req: This 
User Story : ES20-1324 - To check if any duplicate Template Weighing record present in the system 
with the combination of Country Opportunity_Template and Sub_Segment.
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0       Saurav Paul      17/05/2019       US : ES20-1324
***********************************************************************/
@isTest
public class EDGE_TemplateWeighingTriggerHelperTest {
    @isTest
    public static void validateDuplicateRecordTest(){
        //Creating Org setting
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
        
        Product__c prod = EDGE_UtilityTestClass.getProd();
        insert prod;
        
        Territory__c terr = EDGE_UtilityTestClass.getTerritoryRec();
        terr.Territory_Type__c = 'Service';
        insert terr;
        
        Opportunity_Template__c oppTem  = EDGE_UtilityTestClass.getOpportunityTemplate(prod.Id, terr.Id, countryId);
        oppTem.Weight_Type__c = 'MAS or MPA Weight';
        insert oppTem;
        //Creating Template Weighing Record
        Template_Weighing__c tempWeg = EDGE_UtilityTestClass.getTempWeighing(oppTem.Id);
        insert tempWeg;
        //Creating duplicate Template Weighing Record
        Template_Weighing__c tempWeg1 = EDGE_UtilityTestClass.getTempWeighing(oppTem.Id);
        Test.startTest();
        try{
            insert tempWeg1; 
        }catch(Exception ex){
            //Checking Duplicate Rule
            System.Assert(ex.getMessage().contains(Label.Duplicate_Template_Weighing_Error));
        }
        Test.stopTest();
    }
     @isTest
    public static void validateDeleteAndUpdateTest(){
        //Creating Org setting
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
        
        Product__c prod = EDGE_UtilityTestClass.getProd();
        insert prod;
        
        Territory__c terr = EDGE_UtilityTestClass.getTerritoryRec();
        terr.Territory_Type__c = 'Service';
        insert terr;
        
        Opportunity_Template__c oppTem  = EDGE_UtilityTestClass.getOpportunityTemplate(prod.Id, terr.Id, countryId);
        oppTem.Weight_Type__c = 'MAS or MPA Weight';
          
        Test.startTest();
        insert oppTem;
        //Creating Template Weighing Record
        Template_Weighing__c tempWeg = EDGE_UtilityTestClass.getTempWeighing(oppTem.Id);
        insert tempWeg;
        System.assert(tempWeg.Id!= null);
        tempWeg.Sub_Segment__c = 'Airlines';
        update tempWeg;
        delete tempWeg;
        undelete tempWeg;
        Test.stopTest();
        }    
}