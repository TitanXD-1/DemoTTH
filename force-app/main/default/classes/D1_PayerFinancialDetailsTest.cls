/*
* @name: D1_PayerFinancialDetailsTest
* @discription: Test Class for D1_PayerFinancialDetails
* @history
* VERSION       AUTHOR              DATE            DETAIL
* 1.0          D1 Dev Team
*/
@isTest
public class D1_PayerFinancialDetailsTest {
    /**
    * @name : getPayerFinancialInfoTestSuccess
    * @description : This method is used to test getPayerFinancialInfo for success case
    */
    @isTest static void getPayerFinancialInfoTestSuccess() {
        D1_PayerFinancialDetails.CustomerFinance_Response_Wrapper responseWrap;
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new D1_PayerFinancialDetailsCalloutMock(true));
            responseWrap = D1_PayerFinancialDetails.getPayerFinancialInfo('Test', 'Test', 'Test', 'Test');
        Test.stopTest();

        System.assert(responseWrap.CustomerFinance_Response.customernumber == '17867757', 'FINANCIAL INFO DOESNOT MATCH');
        Assert.isTrue(responseWrap.CustomerFinance_Response.customernumber == '17867757', 'FINANCIAL INFO DOESNOT MATCH');
    }

    /**
    * @name : getPayerFinancialInfoTestFailure
    * @description : This method is used to test getPayerFinancialInfo for failure case
    */
    @isTest static void getPayerFinancialInfoTestFailure() {
        D1_PayerFinancialDetails.CustomerFinance_Response_Wrapper responseWrap;
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new D1_PayerFinancialDetailsCalloutMock(false));
            
            try{
                responseWrap = D1_PayerFinancialDetails.getPayerFinancialInfo('Test', 'Test', 'Test', 'Test');
            }catch(Exception e){
                System.assertEquals(e.getTypeName(), 'System.CalloutException', 'assertion failed');
            }    
        Test.stopTest();
        Assert.isNull(responseWrap.CustomerFinance_Response, 'FAILED CASE NOT PASSED');
    }
    
    /**
    * @name : D1_PayerFinancialDetailsCalloutMock
    * @description : This method is used to set up the callout for test class
    */
    public class D1_PayerFinancialDetailsCalloutMock implements HttpCalloutMock {
        Boolean isSuccess;
        public D1_PayerFinancialDetailsCalloutMock( Boolean isSuccess ){
            this.isSuccess = isSuccess;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            
            if( isSuccess ){
                String responseBody = '{ "CustomerFinance_Response": { "salesorg": "IS01", "distributionchannel": "10", "division": "10", "creditcontrolarea": "", "customernumber": "17867757", "customergroup": "", "creditaccountnumber": "", "creditlimitamount": "0.00", "creditlimitcurrency": "EUR", "creditexposureamount": "0.00", "openbalanceamount": "0.00", "openbalancecurrency": "", "overdueamount": "0.00", "overduecurrency": "", "lastpaymentamount": "0.00", "lastpaymentdate": "", "lastpaymentcurrency": "", "Status": { "Type": "S", "Description": "Data Found" } } }';
                
                res.setHeader('Content-Type', 'application/json');
                res.setBody(responseBody);
                res.setStatusCode(200);
            }else{
                res.setHeader('Content-Type', 'application/json');
                res.setBody('Failed');
                res.setStatusCode(500);
            }
            
            return res;
        }
    }
}