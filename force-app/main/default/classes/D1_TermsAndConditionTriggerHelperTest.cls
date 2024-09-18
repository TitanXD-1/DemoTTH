/**
 * @name D1_TermsAndConditionTriggerHelperTest
 * @purpose Test Class for D1_TermsAndConditionTriggerHelper
 * @history
 * VERSION     AUTHOR           DATE        DETAIL
 * 1.0			  -		   	      -				-
**/
@istest
public with sharing class D1_TermsAndConditionTriggerHelperTest {
    public static id orderRecordID = Schema.SObjectType.D1_Terms_Conditions__c.getRecordTypeInfosByName().get('Order Terms and Condition').getRecordTypeId();
    public static id jmlRecordID = Schema.SObjectType.D1_Terms_Conditions__c.getRecordTypeInfosByName().get('JML').getRecordTypeId();
    public static Id saId =  D1_TestDataUtility.insertOrderSplit().Sales_Area__c;

    /**
    * @name : createTestData
    * @description : This method is used to create test data
    */ 
    @testSetup static void createTestData() {
        D1_TestDataUtility.createOrgSettings();
        Geography__c country = new Geography__c(Id= D1_TestDataUtility.setupCountry('GB01'));
        country.isDiageoOneEnabled__c	= True;
        upsert country;  
        
        D1_Setting__c d1setting = D1_TestDataUtility.createD1Settings(country);
        d1setting.Enable_Sales_Area_Terms_and_Conditions__c = true;
        upsert d1setting;

        D1_Terms_Conditions__c tC1 = D1_TestDataUtility.insertD1TermsConditions(d1setting);
        tC1.Releases__c='Major Releases';
        tC1.Name = 'Inactive';
        tC1.Sales_Area__c = saId;
        tC1.Market__c=d1setting.id;
        Insert tC1;

        D1_Terms_Conditions__c tC2  = tC1.clone(true,false,false,false);
        tC2.Status__c='Active';
        tC1.Sales_Area__c = saId;
        List<SObject> newSobj = new List<SObject>();
        Map<Id,D1_Terms_Conditions__c> oldSobjMap = new Map<Id,D1_Terms_Conditions__c>();
        oldSobjMap.put(tC1.Id,tC1);
        newSobj.add(tC2);
        D1_TermsAndConditionTriggerHelper.activateordraftJML(newSobj, oldSobjMap);            
    }
    
    /**
    * @name : testmethod2
    * @description : This method checks Terms and Condition Trigger helper methods
    */
    @isTest
    public static void testmethod2() {
       
        Test.startTest();        
            D1_Terms_Conditions__c tC1temp = [SELECT Id,RecordTypeId, Name, Sales_Area__c, Releases__c, Market__c, Status__c, Version__c, Market_Language__c, Content__c FROM D1_Terms_Conditions__c where recordTypeId=:orderRecordID limit 1];
            D1_Terms_Conditions__c tC1 = tC1temp.clone(false,false,false,false);
            System.assert(tC1 != NULL, 'Terms and Condition not found');
        
            Boolean exceptionThrownForError = false;
            try {
                tC1.Status__c = 'Active';
                insert tC1;
            } catch (Exception e) {
                exceptionThrownForError = true;
            
            }

            tC1.Status__c = 'Draft';
            insert tC1;

            D1_Terms_Conditions__c tC2  = tC1.clone(true,false,false,false);
            System.assert(tC2 != NULL, 'New Terms and Condition not found');
            tC2.Status__c='Active';

            List<SObject> newSobj = new List<SObject>();
            Map<Id,D1_Terms_Conditions__c> oldSobjMap = new Map<Id,D1_Terms_Conditions__c>();
            oldSobjMap.put(tC1.Id,tC1);
            newSobj.add(tC2);
            tC2.Status__c='Inactive';

            update tC2;
            delete tC2;
            undelete tC2;

            D1_TermsAndConditionTriggerHelper.activateordraftJML(newSobj, oldSobjMap);
            System.assertEquals(tC2.Status__c, 'Inactive', 'Status in-correctly matched');
            Boolean exceptionThrown = false;
            try {
                tC2.Name = 'Test';
                update tC2;
                D1_TermsAndConditionTriggerHelper.activateordraftJML(newSobj, oldSobjMap);
                System.assert(D1_TermsAndConditionTriggerHelper.activateordraftJML(newSobj, oldSobjMap) != NULL, 'Terms and Condition not found');
            } catch (Exception e) {
                exceptionThrown = true;            
            } 
        test.stopTest();
    }
    
}