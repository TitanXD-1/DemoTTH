/**********************************************************************
Name: CC_ProductionManagerEmailHandler_Test
=======================================================================
Purpose: This Test Class is for CC_ProductionManagerEmailHandler
=======================================================================
History                                                            
-------                                                            
VERSION			AUTHOR			DATE			DETAIL
1.0				Dasarath N      21/04/2021		Test methods
***********************************************************************/
@isTest
public class CC_ProductionManagerEmailHandler_Test {
    @testSetup static void setup() {
        User u = EDGE_UtilityTestClass.runAsUser('cc_user','System Administrator');
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
    }
    
    static testmethod void testemailhandlerReject(){
        CC_Investigation__c invrec=[Select Id, Name from CC_Investigation__c limit 1]; 
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        
        email.subject = 'Sandbox: ['+invrec.Name+']- : Approval request - Rejected';
        email.fromname = 'Test Test';
        env.fromAddress = 'Test@email.com';
        email.plainTextBody = 'Test';
        
        CC_ProductionManagerEmailHandler emailProcess = new CC_ProductionManagerEmailHandler();
        emailProcess.handleInboundEmail(email, env);       
        
    }
    static testmethod void testemailhandlerApprove(){
        CC_Investigation__c invrec=[Select Id, Name from CC_Investigation__c limit 1]; 
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        
        email.subject = 'Sandbox: ['+invrec.Name+']- : Approval request - Approve';
        email.fromname = 'Test Test';
        env.fromAddress = 'Test@email.com';
        email.plainTextBody = 'Test';
        
        CC_ProductionManagerEmailHandler emailProcess = new CC_ProductionManagerEmailHandler();
        emailProcess.handleInboundEmail(email, env);       
        
    }
}