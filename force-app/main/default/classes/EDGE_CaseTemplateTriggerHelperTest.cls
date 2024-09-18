/**
* @Name: CaseTemplateTriggerHandler

* @Purpose: Trigger Handler Class for CaseTemplateTrigger

* @History                                                            

* @VERSION     AUTHOR             DATE              DETAIL
*   1.0        Anand Uppalapati   10/01/2022        ES20-11891   
**/
@isTest
public class EDGE_CaseTemplateTriggerHelperTest {
    final static String CASETASKTYPERECORDID = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Task Type').getRecordTypeId();
    final static String CASESUBTYPERECORDID = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Sub Type').getRecordTypeId();
    final static String QUALITYCASECONFIGRECTYPEID = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Type').getRecordTypeId();     
    
    @isTest
    public static void createData(){
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        testAdminUser.Available_Countries__c = 'GB';
        insert testAdminUser;
        //Creating Org setting
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryId = EDGE_UtilityTestClass.setupCountryGB('GB');
        Quality_Case_Configuration__c caseType = new Quality_Case_Configuration__c();
        caseType.Name ='Test Case Type';
        caseType.RecordTypeId = QUALITYCASECONFIGRECTYPEID;
        caseType.Active__c= True;
        caseType.Country__c = countryId;
        insert caseType;
        Quality_Case_Configuration__c caseSubType = new Quality_Case_Configuration__c();
        caseSubType.Name ='Test Case Sub Type';
        caseSubType.RecordTypeId = CASESUBTYPERECORDID;
        caseSubType.Active__c= True;
        caseSubType.Case_Type__c=caseType.Id;
        caseSubType.Country__c = countryId;
        insert caseSubType;
        Quality_Case_Configuration__c caseTaskType = new Quality_Case_Configuration__c();
        caseTaskType.Name ='Test Case Task Type';
        caseTaskType.RecordTypeId = CASETASKTYPERECORDID;
        caseTaskType.Active__c= True;
        caseTaskType.Case_Type__c=caseType.Id;
        caseTaskType.Case_Sub_Type__c=caseSubType.Id;
        caseTaskType.Country__c = countryId;
        insert caseTaskType;
        
        Case_Template__c ctempObj = new Case_Template__c();
        ctempObj.Country__c=countryId;
        ctempObj.Case_Sub_Type__c=caseSubType.Id;
        ctempObj.Case_Task_Type__c=caseTaskType.Id;
        ctempObj.Case_Type__c=caseType.Id;
        insert ctempObj;  
        Test.startTest();
        Geography__c country = [SELECT Id, Code__c, Parent_Geography__c FROM Geography__c WHERE Id = :countryId];
        Geography__c secCountry = EDGE_UtilityTestClass.createGeography('Country');
        secCountry.Name = 'Great Britain Country1';
        secCountry.Code__c = 'GB1';
        secCountry.Parent_Geography__c = country.Parent_Geography__c;
        insert secCountry;
        
        
        ctempObj.Country__c = secCountry.Id;
        
        update ctempObj;        
        system.assert(ctempObj.Id != null,'ctempObj Id should not be null');  
        delete ctempObj;
        undelete ctempObj;
        Test.stopTest();
    }
}