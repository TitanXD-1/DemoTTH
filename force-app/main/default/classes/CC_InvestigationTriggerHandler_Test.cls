/*=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR            DATE              DETAIL
1.0      Deepika Gulati	    28-04-2021        Initial Development
***********************************************************************/
@isTest
public class CC_InvestigationTriggerHandler_Test {
    @testSetup 
    static void setup() 
    {
        Account a = EDGE_UtilityTestClass.getOutletRecord();
        a.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Market').getRecordTypeId();
        a.Name = 'Test Account1';
        a.CC_CSE__c = UserInfo.getUserId();
        a.CC_CCC__c = UserInfo.getUserId();
        insert a;
        
        Case c = new Case();
        c.CC_Market__c = a.Id;
        c.CC_Team_Leader__c = 'test@test.com';
        insert c;        
    }
    
    static testmethod void testMethod1() {
        
        Case c = [SELECT Id FROM Case WHERE CC_Market__r.Name = 'Test Account1'];
        try
        {
            CC_Investigation__c invest = new CC_Investigation__c();
            invest.RecordTypeId = Schema.SObjectType.CC_Investigation__c.getRecordTypeInfosByName().get('Site Investigation').getRecordTypeId();
            invest.CC_Date_sent_by_market__c = Date.newInstance(2021, 03, 05);
            invest.CC_Case__c = c.Id;
            insert invest;
            
            CC_Investigation__c invest1 = new CC_Investigation__c();
            invest1.RecordTypeId = Schema.SObjectType.CC_Investigation__c.getRecordTypeInfosByName().get('Site Investigation').getRecordTypeId();
            invest1.CC_Date_sent_by_market__c = Date.newInstance(2021, 03, 05);
            invest1.CC_Case__c = c.Id;
            insert invest1;
        }  
        catch(Exception e){
            //System.assert(e.getMessage().contains('Duplicate investigation form. Please use the existing investigation form for this case.'));
        }
        
    }
}