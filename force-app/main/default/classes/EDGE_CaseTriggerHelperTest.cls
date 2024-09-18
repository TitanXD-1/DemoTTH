/**
 * @description EDGE_CaseTriggerHelperTest 
 * Test Class for case Trigger
 * @history:
 * 1.0      Dinesh Sharma     20/07/2021        Initial Development  
 * */
@isTest
public class EDGE_CaseTriggerHelperTest {
    
    final static String TECHNICALISSUERECORDTYPEID = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical Issue').getRecordTypeId();
    
    
    @isTest
    public static void createSnowTicketTest(){
        
        Pick_Up_Options__c  outletVisit;
        Account outletRec;
        Call__c callobj;
        
        EDGE_UtilityTestClass.createOrgSettings();        
        Id countryId  = EDGE_UtilityTestClass.setupCountry('AU');
        System.assert(countryId!=null,'countryId Inserted');
        
        
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        outletVisit = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        outletVisit.Name='Gold[AU]';
        outletVisit.RecordTypeId = pickupRecordType;
        insert outletVisit ;
        test.startTest();
        outletRec = EDGE_UtilityTestClass.getOutletRecord();
        outletRec.Outlet_Visit_Prioritisation_Grade__c =outletVisit.id;  
        outletRec.Independent_of_Operator__c = true;
        outletRec.Independent_of_Owner__c = true;
        outletRec.Country__c = countryId;
        insert outletRec;              
        callobj = EDGE_UtilityTestClass.getCallRec(outletRec.Id);
        insert callObj;
        
        
        Case cc = new Case();
        cc.Status = 'New';
        cc.Origin = 'EDGE 365 Global';
        cc.RecordTypeId = TECHNICALISSUERECORDTYPEID;
        insert cc;
        
        Map<Id,list<string>> caseResponseMap = new Map<Id,list<string>>();
        caseResponseMap.put(cc.Id, new list<string> {});
        caseResponseMap.get(cc.Id).add('fyhkuhwqiuhjqkhk');
        caseResponseMap.get(cc.Id).add('INC3424676');
        Edge_CaseIntegrationWithSNOW.updateCaseRecord(caseResponseMap);
        
        
        test.stopTest();
    }
    
/**
* @description This is used to cover insertCaseAttachmentToSNowTicket method
*/
    @isTest
    public static void insertCaseAttachmentToSnowOnCaseUpdateTest(){
        EDGE_UtilityTestClass.createOrgSettings();
        Test.startTest();
        //try{
            Case caseRec = new Case();
            caseRec.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical Issue').getRecordTypeId();
            caseRec.Origin = 'EDGE365';
            caseRec.Status = 'New';
            insert caseRec;
            System.assert(caseRec.Id != null,'caseRec Inserted');
            
            CaseComment ccomment = new CaseComment();
            ccomment.parentId = caseRec.id;
            ccomment.CommentBody = 'test comment';
            insert ccomment;
            
            ContentVersion conVerRec = EDGE_UtilityTestClass.gerConVerRec('Test.jpeg');
            conVerRec.Title = 'Test';
            conVerRec.PathOnClient = 'Test.jpeg';
            conVerRec.VersionData = Blob.valueOf('Test Content');
            insert conVerRec;
            System.assert(conVerRec.Id != null,'conVerRec Inserted');           
            
            List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
            System.assertEquals(documents.size(), 1,'Document size should match');
            
            ContentDocumentLink conDocLnkRec = EDGE_UtilityTestClass.getConDocLink (caseRec.Id,documents[0].Id);
            insert conDocLnkRec;
            System.assert(conDocLnkRec.Id != null,'conDocLnkRec Inserted');
            
           
            caseRec.sys_id__c = 'e76583d01b7d3c94e4d4db5be5011288';
            update caseRec;
            
        
        Test.stopTest();
    }


    @isTest
    public static void insertCaseAttachmentToSnowOnCaseUpdateTestNoComments(){
        EDGE_UtilityTestClass.createOrgSettings();
        
        Test.startTest();
        //try{
        Case caseRec = new Case();
        caseRec.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical Issue').getRecordTypeId();
        caseRec.Origin = 'EDGE365';
        caseRec.Status = 'New';
        insert caseRec;
        System.assert(caseRec.Id != null,'caseRec Inserted');
        
            ContentVersion conVerRec = EDGE_UtilityTestClass.gerConVerRec('Test.jpeg');
            conVerRec.Title = 'Test';
            conVerRec.PathOnClient = 'Test.jpeg';
            conVerRec.VersionData = Blob.valueOf('Test Content');
            insert conVerRec;
            System.assert(conVerRec.Id != null,'conVerRec Inserted');           

            List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
            System.assertEquals(documents.size(), 1,'Document Size should match');
        
            ContentDocumentLink conDocLnkRec = EDGE_UtilityTestClass.getConDocLink (caseRec.Id,documents[0].Id);
            insert conDocLnkRec;
            System.assert(conDocLnkRec.Id != null,'conDocLnkRec Inserted');
        
        
            caseRec.sys_id__c = 'e76583d01b7d3c94e4d4db5be5011288';
            update caseRec;
            
            
        Test.stopTest();
    }
        
/**
* @description This is used to cover insertCaseAttachmentToSNowTicket method
*/
    @isTest
    public static void deleteCaseAttachmentTest(){
        EDGE_UtilityTestClass.createOrgSettings();
        Case caseRec = new Case();
        caseRec.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical Issue').getRecordTypeId();
        caseRec.Origin = 'EDGE365';
        caseRec.Status = 'New';
        insert caseRec;
        System.assert(caseRec.Id != null,'caseRec Inserted');

        delete caseRec;
        undelete caseRec;
    }

}