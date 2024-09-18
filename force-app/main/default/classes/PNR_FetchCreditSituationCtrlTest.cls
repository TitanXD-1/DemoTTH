/**********************************************************************
  Name: PNR_FetchCreditSituationCtrlTest
=======================================================================
  Purpose: This is the Test Class for PNR_FetchCreditSituationCtrlTest
=======================================================================
    History                                                            
------------------------------------------------------------------------                                                            
    VERSION    AUTHOR            DATE              DETAIL
	1.0        Saurav Paul     12-06-2019        Initial Development
***********************************************************************/
@isTest
public class PNR_FetchCreditSituationCtrlTest {
    //This is for +ve test case
	@isTest
    public static void sendDataTest(){
        //Inserting Account Record
        Account accRec = PNR_TestDataUtility.getDirectCustomerRec();
        accRec.AccountNumber = '12345';
        accRec.KUNNR__c = '12345';
        insert accRec;
        System.assert(accRec.Id != null);
        //Inserting Account Record
        Account accObj = PNR_TestDataUtility.getDirectCustomerRec();
        accObj.AccountNumber = '16543';
        accObj.KUNNR__c = '16543';
        insert accObj;
        System.assert(accObj.Id != null);
        
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
		mock.setStaticResource('customerCreditFetch');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        PNR_FetchCreditSituationCtrl.sendData('16543','DGT1','SalesOrg');
		Test.stopTest();
    }
    //This is for -ve test case
    @isTest
    public static void noConnectionTest(){
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
		mock.setStaticResource('customerCreditFetch');
        mock.setStatusCode(500);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        PNR_FetchCreditSituationCtrl.sendData('16543','DGT1','SalesOrg');
		Test.stopTest();
	}
}