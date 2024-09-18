/**********************************************************************
Name: CC_DuplicateCasesControllerTest
=======================================================================
Purpose: This Test Class is for CC_DuplicateCasesController
=======================================================================
History                                                            
-------                                                            
VERSION			AUTHOR			DATE			DETAIL
1.0				Bhargav S       19/03/2021		Test methods
***********************************************************************/
@isTest
public class CC_DuplicateCasesControllerTest {
    
    @isTest
    public static void getDuplicateCasesTest(){
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
        
        Case c = new Case();
        c.CC_Market__c = a.Id;
        c.CC_LOT_Code__c = '12345';
        insert c;
        
        CC_DuplicateCasesController.getDuplicateCases(c.Id);
        
        Case c1 = new Case();
        c1.CC_Market__c = a.Id;
        c1.CC_LOT_Code__c = '12345';
        insert c1;
        
        CC_DuplicateCasesController.getDuplicateCases(c1.Id);
    }
}