@isTest
public class CC_UpdateLabInvestigationControllerTest {

    @isTest
    public static void getOwnerUpdateTest(){
        Org_Setting__c orgSetting = new Org_Setting__c();
        orgSetting.Run_Triggers__c = true;
        insert orgSetting;
        
        User u = EDGE_UtilityTestClass.runAsUser('cc_ccc_user','System Administrator');
        insert u;
        
        User u1 = EDGE_UtilityTestClass.runAsUser('cc_cse_user','System Administrator');
        insert u1;
        
        EDGE_UtilityTestClass.setupCountry('AU');
        
        Account a = EDGE_UtilityTestClass.getOutletRecord();
        a.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Market').getRecordTypeId();
        a.CC_CCC__c = u.Id;
        a.CC_CSE__c = u1.Id;
        insert a;
        
        Case c = new Case();
        c.CC_Market__c = a.Id;
        c.OwnerId = u.Id;
        insert c;
        
        CC_Investigation__c invest = new CC_Investigation__c();
        invest.RecordTypeId = Schema.SObjectType.CC_Investigation__c.getRecordTypeInfosByName().get('Lab Investigation').getRecordTypeId();
        invest.CC_Date_sent_by_market__c = Date.newInstance(2021, 03, 05);
        invest.CC_Case__c = c.Id;
        invest.OwnerId = UserInfo.getUserId();
        insert invest;
        
        String result = CC_UpdateLabInvestigationOwnerController.getUpdateInvestigationOwner(invest.id);
        System.assertEquals(c.OwnerId, result);
    }
    @isTest
    public static void getOwnerUpdateNullTest(){
        String result = CC_UpdateLabInvestigationOwnerController.getUpdateInvestigationOwner('');
        System.assertEquals(null, result);
    }
}