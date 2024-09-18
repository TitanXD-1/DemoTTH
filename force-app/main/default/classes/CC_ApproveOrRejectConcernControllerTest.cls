/**********************************************************************
Name: CC_ApproveOrRejectConcernControllerTest
=======================================================================
Purpose: This Test Class is for CC_ApproveOrRejectConcernController
=======================================================================
History                                                            
-------                                                            
VERSION			AUTHOR			DATE			DETAIL
1.0				Bhargav S       07/04/2021		Test methods
***********************************************************************/
@isTest
public class CC_ApproveOrRejectConcernControllerTest {
    
    @isTest
    public static void testCheckStatus(){
        Org_Setting__c orgSetting = new Org_Setting__c();
        orgSetting.Run_Triggers__c = true;
        insert orgSetting;
        
        EDGE_UtilityTestClass.setupCountry('AU');
        
        User u = EDGE_UtilityTestClass.runAsUser('cc_user','System Administrator');
        insert u;
        
        User u1 = EDGE_UtilityTestClass.runAsUser('cc_cse_user','System Administrator');
        insert u1;
        
        Account a = EDGE_UtilityTestClass.getOutletRecord();
        a.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Market').getRecordTypeId();
        a.CC_CCC__c = u.Id;
        a.CC_CSE__c = u1.Id;
        insert a;
        
        /*Approver_Matrix__c am = new Approver_Matrix__c();
        am.CC_Market__c = a.Id;
        am.CC_CCC__c = u.Id;
        am.CC_CSE__c = 'diageotest@diageotest.com';
        insert am;*/
        
        Case c = new Case();
        c.CC_Market__c = a.Id;
        insert c;
        
        CC_ApproveOrRejectConcernController.checkStatus(c.Id);
        
        c.Status = 'Approved';
        update c;
        
        CC_ApproveOrRejectConcernController.checkStatus(c.Id);
    }
    
    @isTest
    public static void testApproveOrRejectConcern(){
        Org_Setting__c orgSetting = new Org_Setting__c();
        orgSetting.Run_Triggers__c = true;
        insert orgSetting;
        
        EDGE_UtilityTestClass.setupCountry('AU');
        
        User u = EDGE_UtilityTestClass.runAsUser('cc_user','System Administrator');
        insert u;
        
        User u1 = EDGE_UtilityTestClass.runAsUser('cc_cse_user','System Administrator');
        insert u1;
        
        Account a = EDGE_UtilityTestClass.getOutletRecord();
        a.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Market').getRecordTypeId();
        a.CC_CCC__c = u.Id;
        a.CC_CSE__c = u1.Id;
        insert a;
        
        /*Approver_Matrix__c am = new Approver_Matrix__c();
        am.CC_Market__c = a.Id;
        am.CC_CCC__c = u.Id;
        am.CC_CSE__c = 'diageotest@diageotest.com';
        insert am;*/
        
        Case c = new Case();
        c.CC_Market__c = a.Id;
        insert c;
        
        CC_ApproveOrRejectConcernController.approveOrRejectConcern(c.Id, false, '');
        
        CC_ApproveOrRejectConcernController.approveOrRejectConcern(c.Id, true, 'test');
    }
}