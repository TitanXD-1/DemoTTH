/**********************************************************************
Name: EDGE_OpportunityTemplateTriggerHelper
=======================================================================
Req: Test Class for OpportunityTemplateTrigger
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0       Sandeep Sahoo     4-Apr-2019        ES20-812

***********************************************************************/
@isTest
public with sharing class EDGE_OppoTemplateTriggerHelperTest {
    public static Map<String,Id> geoMap = new Map<String,Id>();
    @isTest
    public static void testOpportunityTemplateDuplicate(){
        EDGE_UtilityTestClass.createOrgSettings();        
        Id countryID = EDGE_UtilityTestClass.setupCountry('AUT');
     
       /* Product__c testProd = new Product__c(Name='Johnny Walker Black Label');
        insert testProd;*/
        
           Product__c testProd = EDGE_UtilityTestClass.getProd();
        testProd.Description__c='Johnny Walker1';
        testProd.Type__c = 'Diageo Product';
        testProd.UPIID__c='1234567';
        testProd.Product_Code__c='222222';
        insert testProd;
        
        
        Territory__c terrId =EDGE_UtilityTestClass.getTerritoryRec();
        terrId.Territory_Type__c='Service';
        insert terrId; 
        Geography__c country = [Select Id, Parent_Geography__c from Geography__c where Id =: countryID ];
        Id clusterId = country.Parent_Geography__c;
        Opportunity_Template__c oppoTemp = new Opportunity_Template__c(Territory__c=terrId.Id,Product__c=testProd.Id,Cluster__c=clusterId,Opportunity_Type__c='NPA',Action__c='Test',Closing_Method__c='Order',Start_Date__c=Date.today(),Weight_Type__c='Always on Top',End_Date__c=Date.today().addDays(7));                
        insert oppoTemp;
       
        Opportunity_Template__c oppoTemp2 = new Opportunity_Template__c(Territory__c=terrId.Id,Product__c=testProd.Id,Cluster__c=clusterId,Opportunity_Type__c='NPA',Action__c='Test',Closing_Method__c='Order',Start_Date__c=Date.today(),Weight_Type__c='Always on Top',End_Date__c=Date.today().addDays(7));        
        try{
            insert oppoTemp2;
            //Opportunity_Template__c oppoTempCompNew =[Select ID,Compound_Key__c from Opportunity_Template__c where ID=:oppoTemp2.ID];
        }catch(Exception ex){
            //Checking Duplicate Opportunity Template Validation
            System.Assert(ex.getMessage().contains(Label.Duplicate_Opportunity_Template),'null');
        }
        Test.startTest();
        Opportunity_Template__c oppoTemp1 = [SELECT ID,Compound_Key__c,Action__c,Territory__c FROM Opportunity_Template__c WHERE Id =:oppoTemp.Id];
        Territory__c newTerrId=EDGE_UtilityTestClass.getTerritoryRec();
        newTerrId.Territory_Type__c = 'Service';
        insert newTerrId;
        oppoTemp1.Territory__c=newTerrId.Id;
        update oppoTemp1;
        delete oppoTemp1;
        Test.stopTest();
    }
   /* public static Opportunity_Template__c getOppoTemplateActivation(){ 
        Id clusterId = [Select Id,Code__c from Geography__c where Code__c = 'AU'].Id;
        Id contID= [Select Id,Code__c from Geography__c where Code__c = 'AUS'].Id;
        Id terrId =[Select ID,Name from Territory__c where name = 'Test Territory'].Id;
        Opportunity_Template__c oppoTemp2 = new Opportunity_Template__c(Territory__c=terrId,Cluster__c=clusterId,Country__c=contId,Activation__c='Test Record',Opportunity_Type__c='NPA',Action__c='Test',Closing_Method__c='Order',Start_Date__c=Date.newInstance(2022,1,1),Weight_Type__c='Always on Top');
        return oppoTemp2;
    } */
    
    /*******************************************************************
    Method  : checkSharingTest
    Purpose : To check the sharing of object
    ********************************************************************/
    @isTest
    public static void checkSharingTest(){
         //Creating Org setting
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
      
      /*  Product__c testProd = new Product__c(Name='Johnny Walker Black Label');
        insert testProd;*/
        
           Product__c testProd = EDGE_UtilityTestClass.getProd();
        testProd.Description__c='Johnny Walker1';
        testProd.Type__c = 'Diageo Product';
        testProd.UPIID__c='1234567';
        testProd.Product_Code__c='222222';
        insert testProd;
        
        Territory__c territory =EDGE_UtilityTestClass.getTerritoryRec();
        territory.Territory_Type__c='Service';
        insert territory; 
        Test.startTest();
        Geography__c country = [Select Id, Parent_Geography__c, Parent_Geography__r.Parent_Geography__c from Geography__c where Id =: countryId ];
        Id clusterId = country.Parent_Geography__c;
        
       // Geography__c clusterRec = [Select Id, Parent_Geography__c from Geography__c where Id =: clusterId ];
        
         //Creating Opportunity Template Record
        Opportunity_Template__c  opportunityTemplate = EDGE_UtilityTestClass.getOpportunityTemplate(testProd.Id, territory.Id, countryId);
        opportunityTemplate.Segment__c='';
        opportunityTemplate.Sub_Segment__c = '';
        opportunityTemplate.Cluster__c = clusterId;
        insert opportunityTemplate ;
        system.assert(opportunityTemplate .Id != null,'opportunity template Id should be null');
        
        Geography__c secCluster = EDGE_UtilityTestClass.createGeography('Cluster');
        secCluster.Name = 'Australia Cluster';
        secCluster.Code__c = 'AUC';
        secCluster.Parent_Geography__c = country.Parent_Geography__r.Parent_Geography__c;
        insert secCluster;
        
        country.Parent_Geography__c = secCluster.Id;
        update country; 
        
        opportunityTemplate.Cluster__c = secCluster.Id;
        //opportunityTemplate.Country__c = country.Id; 
        update opportunityTemplate;        
        delete opportunityTemplate;
        undelete opportunityTemplate;
        Test.stopTest();
    }

    
}