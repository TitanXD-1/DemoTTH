@isTest
public class PNR_CustCreditMgmtWrapperTest {
    @isTest
    public static void validateWrap(){
        Test.startTest();
        PNR_CustCreditMgmtWrapper wrap = new PNR_CustCreditMgmtWrapper('payerName','creditLimit',
                                                                       'creditExposure', 'creditLimitUsed',
                                                                       'currencyVal', 'rating',
                                                                       Date.today() ,  'riskCat',
                                                                       'paymentTerm');
        System.assert(wrap!= null);
        Test.stopTest();
    }
}