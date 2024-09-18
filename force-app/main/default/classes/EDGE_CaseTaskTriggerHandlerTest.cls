/**


* @description: EDGE_CaseTaskTriggerHandlerTest
* @Purpose : Test Class for CaseTaskTriggerHandler and EDGE_Quality_CaseTaskTriggerHelper
* @history:
* @Version     Developer		     Date			   Story/Purpose
* 1.0          Joshraj               11/08/2021


*/
@isTest
public class EDGE_CaseTaskTriggerHandlerTest {
    final static String TECHNICALISSUERECORDTYPEID = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical Issue').getRecordTypeId();

    final static String QUALITYCASECONFIGRECTYPEID = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Type').getRecordTypeId();     
    final static String QUALITYRECORDTYPEID = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality').getRecordTypeId();
    final static String CASETASKTYPERECORDID = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Task Type').getRecordTypeId();
    final static String CASESUBTYPERECORDID = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Sub Type').getRecordTypeId();


    @isTest
    public static void insertCaseTask(){
       EDGE_UtilityTestClass.createOrgSettings();
        Org_Setting__c orgSetting = Org_Setting__c.getOrgDefaults();
        orgSetting.Run_Triggers__c =false;
        update orgSetting;
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AUT]';
        pickupOption.Status__c = 'Active';
        insert pickupOption;   
        Account testoutlet = EDGE_UtilityTestClass.getOutletRecord();
        testoutlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        insert testoutlet;
        System.assert(testoutlet!=null,'testoutlet should not be null');
        
        Contact primcon = new Contact(FirstName='fname',
                                    LastName = 'lname',
                                    Email = 'email@gmail.com',
                                    Phone = '1234567890',Contact_Type__c='Primary',AccountID=testoutlet.Id); 
        insert primcon;


        Master_Asset__c masObj = new Master_Asset__c();

        masObj.Name = 'Test';
        masObj.Part_Number__c = '123CHSGT';
        masObj.GUID__c = 'TWRFSHJAKSVGG';
        masObj.Short_Description__c = 'short description';
        masObj.Country__c = countryId;

        masObj.Active__c = true;
        masObj.Priority_Assets__c = true;
        
        Insert masObj;

		test.startTest();
        Asset asst = new Asset();
        asst.Name = 'Test';
        asst.GUID__c = 'TWRFSHJAKSVGG';
        asst.Description = 'asset description';
        asst.AccountId = testoutlet.Id;
        asst.ContactId = primcon.Id;
        asst.Country__c = countryId;

        asst.Quantity = 1;
        asst.SerialNumber ='1111';

        asst.Master_Asset__c=masObj.id;

        insert asst;
        orgSetting.Run_Triggers__c =true;
        update orgSetting;

        asst.Description = 'Description';
        
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
        //Insert of Case
        Case cc = new Case();
        cc.AccountId = testoutlet.Id;
        cc.ContactId = primcon.Id;
        //cc.Call__c = callObj.id;

        cc.Case_Type__c = caseType.Id;
        cc.Case_Sub_Type__c = caseSubType.Id;
        cc.Status = 'Open';

        cc.Origin = 'EDGE 365 Global';
        cc.RecordTypeId = TECHNICALISSUERECORDTYPEID;
        insert cc;
        //Insert of Case Task

        Case_Task__c ct = new Case_Task__c();
        ct.Case__c = cc.ID;
        //ct.Achievement_Status__c='Open';
        ct.GUID__c = 'TWRFSHJAKSVGG';
        ct.Case_Task_Type__c = caseTaskType.Id;       
        insert ct;

        test.stopTest();
        //Update Scenario Cover

        update ct;
        delete ct;
        undelete ct;

    }
}