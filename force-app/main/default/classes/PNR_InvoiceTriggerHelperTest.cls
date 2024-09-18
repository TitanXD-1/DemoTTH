/**********************************************************************
    Name: PNR_InvoiceTriggerHelperTest
=======================================================================
    Purpose: Test Class for PNR_InvoiceTriggerHelper
=======================================================================
    History                                                            
    -------                                                            
    VERSION     AUTHOR            DATE              DETAIL
       1.0     Saurav Paul     	  04/09/2019        Initial Development     
***********************************************************************/
@isTest
public class PNR_InvoiceTriggerHelperTest {
	@isTest
    public static void orderPopulateTest(){
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AUS');
        EDGE_UtilityTestClass.createOrgSettings();
        Account accObj  = PNR_TestDataUtility.getDirectCustomerRec();
        accObj.Country_ISO_Code__c = 'AUS';
        insert accObj;
        System.assert(accObj.Id != null);
        Order__c ordrObj = PNR_TestDataUtility.getDirOrder(accObj.Id);
        insert ordrObj;
        System.assert(ordrObj.Id != null);
        Invoice__c invObj = PNR_TestDataUtility.getDirInvoice();
        invObj.SAP_Order_Number__c = '8348946084';
        insert invObj;
        System.assert(invObj.Id != null);
        Invoice__c invUpdate = [SELECT Id,Order__c FROM Invoice__c WHERE Id =: invObj.Id];
        System.assertEquals(ordrObj.Id, invUpdate.Order__c);
    }
    @isTest
    public static void orderPopulateTestUpdt(){
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AUS');
        EDGE_UtilityTestClass.createOrgSettings();
        Account accObj  = PNR_TestDataUtility.getDirectCustomerRec();
        accObj.Country_ISO_Code__c = 'AUS';
        insert accObj;
        System.assert(accObj.Id != null);
        Order__c ordrObj = PNR_TestDataUtility.getDirOrder(accObj.Id);
        insert ordrObj;
        System.assert(ordrObj.Id != null);
        Invoice__c invObj = PNR_TestDataUtility.getDirInvoice();
        invObj.SAP_Order_Number__c = '8348946084';
        insert invObj;
        System.assert(invObj.Id != null);
        Invoice__c invUpdate = [SELECT Id,Order__c FROM Invoice__c WHERE Id =: invObj.Id];
        System.assertEquals(ordrObj.Id, invUpdate.Order__c);
        update invUpdate;
        delete invUpdate;
        undelete invUpdate;
    }
}