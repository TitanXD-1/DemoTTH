/**
@name D1_OppoTemplateTriggerHelperTest
@description Test Class for D1_OpportunityTemplateTriggerHelper
@history
VERSION     AUTHOR           DATE           DETAIL
1.0		  	Rithika			06/12/21	   NCP-5508
**/
@isTest
public with sharing class D1_OppoTemplateTriggerHelperTest {
    @testSetup
    public static void setup(){
        
        Id countryId = D1_TestDataUtility.setupCountry('GB');
        Pick_Up_Options__c pickupOption1 = D1_TestDataUtility.getPickUpOption(countryId, 'Product Type', 'Product Type', 'Gold[GB]');
        
        Product__c product= D1_TestDataUtility.getProduct(countryId, 'POS', pickupOption1.Id);
        system.assert(product!=null, 'product does not exist');
        
        Territory__c primaryTerr = D1_TestDataUtility.getTerritoryRec();
        system.assert(primaryTerr!=null, 'territory does not exist');
        
        Opportunity_Template__c oppTemplate = D1_TestDataUtility.getOpportunityTemplate(product.Id,primaryTerr.Id,countryId);
        oppTemplate.D1_Content_Reference__c = '';
        oppTemplate.D1_Relevant__c = false;
        
        insert oppTemplate;          
        
    }
    
    @isTest 
    public static void testValidateContentKeyAndType(){   
        
        Test.startTest();
        Opportunity_Template__c oppTemplate = [SELECT Id,D1_Content_Reference__c,Cluster__r.Parent_Geography__c,Cluster__r.Code__c,D1_Relevant__c,Weight_Type__c,End_Date__c,Segment__c,Sub_Segment__c,Channel__c,name from Opportunity_Template__c
                                               WHERE D1_Content_Reference__c='' LIMIT 1];
        
        Opportunity_Template__c oppNewTemplate = [SELECT Id,D1_Content_Reference__c,Cluster__r.Parent_Geography__c,Cluster__r.Code__c,D1_Relevant__c,Weight_Type__c,End_Date__c,Segment__c,Sub_Segment__c,Channel__c,name from Opportunity_Template__c
                                                  WHERE D1_Content_Reference__c='' LIMIT 1];
        oppNewTemplate.D1_Content_Reference__c='1234JGXUZJ5BCPLF627J3';
        update oppNewTemplate;
        
        Opportunity_Template__c oppNewTemplate1 = [SELECT Id,D1_Content_Reference__c,Cluster__r.Parent_Geography__c,Cluster__r.Code__c,D1_Relevant__c,Weight_Type__c,End_Date__c,Segment__c,Sub_Segment__c,Channel__c,name from Opportunity_Template__c
                                                   WHERE D1_Content_Reference__c='1234JGXUZJ5BCPLF627J3' LIMIT 1];
        oppNewTemplate1.D1_Content_Reference__c='KJHHJGFGFDDFTCVBVCBCHHJGFBCV';
        update oppNewTemplate1;
        
        Opportunity_Template__c oppNewTemplate2 = [SELECT Id,D1_Content_Reference__c,Cluster__r.Parent_Geography__c,Cluster__r.Code__c,D1_Relevant__c,Weight_Type__c,End_Date__c,Segment__c,Sub_Segment__c,Channel__c,name from Opportunity_Template__c
                                                   WHERE D1_Content_Reference__c='KJHHJGFGFDDFTCVBVCBCHHJGFBCV' LIMIT 1];
        oppNewTemplate2.D1_Content_Reference__c = null;
        oppNewTemplate2.D1_Relevant__c = true;
        update oppNewTemplate2;
        
        List<Opportunity_Template__c> newObj = new List<Opportunity_Template__c>();
        List<Opportunity_Template__c> newObj1 = new List<Opportunity_Template__c>();
        List<Opportunity_Template__c> newObj2 = new List<Opportunity_Template__c>();
        Map<Id,Opportunity_Template__c> oldObjMap = new Map<Id,Opportunity_Template__c>();
        Map<Id,Opportunity_Template__c> oldObjMap1 = new Map<Id,Opportunity_Template__c>();
        
        newObj.add(oppTemplate);
        newObj1.add(oppNewTemplate);
        newObj2.add(oppNewTemplate2);
        
        oldObjMap.put(oppNewTemplate.Id, oppNewTemplate);
        oldObjMap1.put(oppNewTemplate1.Id, oppNewTemplate1);
        
        
        D1_OpportunityTemplateTriggerHelper.validateContentKeyAndType(newObj, oldObjMap);
        System.assert(D1_OpportunityTemplateTriggerHelper.validateContentKeyAndType(newObj, oldObjMap) == NULL, 'Opportunity does not exist');
        D1_OpportunityTemplateTriggerHelper.validateContentKeyAndType(newObj1, oldObjMap1);
        System.assert(D1_OpportunityTemplateTriggerHelper.validateContentKeyAndType(newObj1, oldObjMap1) == NULL, 'Opportunity does not exist');
        D1_OpportunityTemplateTriggerHelper.sendNotification(newObj, oldObjMap);
        D1_OpportunityTemplateTriggerHelper.sendNotification(newObj2, oldObjMap);
        delete oppNewTemplate2; 
        undelete oppNewTemplate2;
        
        Test.stopTest();
    }   
}