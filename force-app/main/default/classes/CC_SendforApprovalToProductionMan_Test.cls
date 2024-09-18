/**********************************************************************
Name: CC_ApproveOrRejectConcernControllerTest
=======================================================================
Purpose: This Test Class is for CC_SendforApprovalToProductionManager
=======================================================================
History                                                            
-------                                                            
VERSION			AUTHOR			DATE			DETAIL
1.0				Dasarath N      16/04/2021		Test methods
2.0             Saranga Bobade  22-09-2022      CR-3043
***********************************************************************/
@isTest
public class CC_SendforApprovalToProductionMan_Test {
    
  /*  @testSetup static void setup() {
        User u = EDGE_UtilityTestClass.runAsUser('cc_ccc_user','System Administrator');
        insert u;
        
        User u1 = EDGE_UtilityTestClass.runAsUser('cc_cse_user','System Administrator');
        insert u1;
        
        Account a = EDGE_UtilityTestClass.getOutletRecord();
        a.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Market').getRecordTypeId();
        
        a.CC_CCC__c = u.Id;
        a.CC_CSE__c = u1.Id;
        insert a;
        
        Case c = new Case();
        c.CC_Market__c = a.Id;
        c.CC_Production_Manager__c ='test@test.com';
        insert c;
        
        CC_Investigation__c invest = new CC_Investigation__c();
        invest.RecordTypeId = Schema.SObjectType.CC_Investigation__c.getRecordTypeInfosByName().get('Site Investigation').getRecordTypeId();
        invest.CC_Date_arrived_at_lab__c = Date.newInstance(2021, 03, 12);
        invest.CC_Case__c = c.Id;
        invest.CC_TestRunning__c = true;
        insert invest;
    }*/
    
    static testmethod void testsendemailtoManager(){
       
        User u = EDGE_UtilityTestClass.runAsUser('cc_ccc_user','System Administrator');
        insert u;
        User u1 = EDGE_UtilityTestClass.runAsUser('cc_cse_user','System Administrator');
        insert u1;
        
        Account a = EDGE_UtilityTestClass.getOutletRecord();
        a.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Market').getRecordTypeId();
        
        a.CC_CCC__c = u.Id;
        a.CC_CSE__c = u1.Id;
        insert a;
        
        Case c = new Case();
        c.CC_Market__c = a.Id;
        c.CC_Production_Manager__c ='test@test.com';
        insert c;
        
        CC_Investigation__c invest = new CC_Investigation__c();
        invest.RecordTypeId = Schema.SObjectType.CC_Investigation__c.getRecordTypeInfosByName().get('Site Investigation').getRecordTypeId();
        invest.CC_Date_arrived_at_lab__c = Date.newInstance(2021, 03, 12);
        invest.CC_Case__c = c.Id;
        invest.CC_TestRunning__c = true;
        insert invest;
        
		CC_Investigation__c invrec=[Select Id, Name from CC_Investigation__c limit 1];  
        system.debug('invrecmmmmmmm'+invrec);
        CC_SendforApprovalToProdManager.fetchInvestigationrecord(invrec.Id);
        CC_SendforApprovalToProdManager.sendEmailtoProdmanager('test','test@test.com','test1@test.com','test',invrec.Id);
      
    }
    static testmethod void testsendemailtoManager1(){
        
        User u = EDGE_UtilityTestClass.runAsUser('cc_ccc_user','System Administrator');
        insert u;
        User u1 = EDGE_UtilityTestClass.runAsUser('cc_cse_user','System Administrator');
        insert u1;
        
        Account a = EDGE_UtilityTestClass.getOutletRecord();
        a.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Market').getRecordTypeId();
        
        a.CC_CCC__c = u.Id;
        a.CC_CSE__c = u1.Id;
        insert a;
        
        Case c = new Case();
        c.CC_Market__c = a.Id;
        c.CC_Production_Manager__c ='test@test.com';
        insert c;
        
        CC_Investigation__c invest = new CC_Investigation__c();
        invest.RecordTypeId = Schema.SObjectType.CC_Investigation__c.getRecordTypeInfosByName().get('Site Investigation').getRecordTypeId();
        invest.CC_Date_arrived_at_lab__c = Date.newInstance(2021, 03, 12);
        invest.CC_Case__c = c.Id;
        invest.CC_TestRunning__c = true;
        insert invest;
        
        ContentVersion content = new ContentVersion(); 
        content.Title = 'Test'; 
        content.PathOnClient = '/' + content.Title + '.jpg'; 
        Blob bodyBlob = Blob.valueOf('Test ContentVersion Body'); 
        content.VersionData = bodyBlob; 
        insert content;
        
        ContentDocumentLink contentlink = new ContentDocumentLink();
        contentlink.LinkedEntityId = invest.id;
        contentlink.contentdocumentid = [Select contentdocumentid from contentversion where id =: content.id].contentdocumentid;
        contentlink.Visibility = 'AllUsers'; 
        insert contentlink;       

		CC_Investigation__c invrec=[Select Id, Name from CC_Investigation__c limit 1];  
        system.debug('invrecmmmmmmm'+invrec);
        CC_SendforApprovalToProdManager.fetchInvestigationrecord(invrec.Id);
        CC_SendforApprovalToProdManager.sendEmailtoProdmanager('test','test@test.com','test1@test.com','test',invrec.Id);

    } 
}