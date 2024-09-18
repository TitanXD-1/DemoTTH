/**********************************************************************
Name: PNR_AccountTriggerHelperTest
=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR           DATE            DETAIL
1.0         Saurav Paul     16/04/2019       Test Class for Update Product Enabled
***********************************************************************/
@isTest
public class PNR_AccountTriggerHelperTest {
    @isTest
    public static void testUpdateProductEnabled(){ 
        Id contId;
        EDGE_UtilityTestClass.createOrgSettings();
        contId = EDGE_UtilityTestClass.setupCountry('AD');
        System.assert(contId != null);
        Account acct = PNR_TestDataUtility.getDirectCustomerRec();
        acct.AccountSource = 'SAP - Pioneer';
        acct.Country_ISO_Code__c = 'AD';
        Test.startTest();
        insert acct;
        Test.stopTest();
        Account acc = [SELECT Id,Products_Enabled__c,Pioneer_Enabled__c FROM Account WHERE Id =: acct.Id];
        System.assertEquals('Pioneer', acc.Products_Enabled__c);
        System.assert(acc.Pioneer_Enabled__c);
    }

}