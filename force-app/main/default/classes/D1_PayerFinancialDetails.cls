/**
 * @name D1_PayerFinancialDetails
 * @purpose Get My Financials Balance Details from SAP
 * @history
 * VERSION     AUTHOR           DATE       DETAIL
 * 1.0         Gaurav          12/03/21    NCP-1371
**/
@SuppressWarnings('PMD.TooManyFields')
public with sharing class D1_PayerFinancialDetails {
    public static final String PAYER_FINANCIAL_DETAILS_NAMED_CREDENTIAL = 'D1_PayerFinancialDetails';

    /*
     * @description Wrapper class for Financial Info SAP API request
     */
    public class CustomerFinance_Req_Wrapper{
        public CustomerFinance_Req CustomerFinance_Req; // NOPMD

        public CustomerFinance_Req_Wrapper( String customernumber, String salesorg, String distributionchannel, String division  ){
            CustomerFinance_Req = new CustomerFinance_Req( customernumber, salesorg, distributionchannel, division );
        }
    }

    /*
     * @description Wrapper class for Financial Info SAP API request body inner class
     */
    class CustomerFinance_Req {
		public String salesorg;
		public String distributionchannel;
		public String division;
		public String customernumber;

        public CustomerFinance_Req( String customernumber, String salesorg, String distributionchannel, String division  ){
            this.customernumber = customernumber;
            this.salesorg = salesorg;
            this.distributionchannel = distributionchannel;
            this.division = division;
        }
	}

    /*
     * @description Wrapper class for Financial Info SAP API response
     */
    public class CustomerFinance_Response_Wrapper{
        @AuraEnabled public  CustomerFinance_Response CustomerFinance_Response; // NOPMD
    }

    /*
     * @description Wrapper class for Financial Info SAP API response body inner class
     */
    public class CustomerFinance_Response {
		@AuraEnabled public String salesorg;	//IS01
		@AuraEnabled public String distributionchannel;	//10
		@AuraEnabled public String division;	//10
		@AuraEnabled public String creditcontrolarea;	//
		@AuraEnabled public String customernumber;	//17867757
		@AuraEnabled public String customergroup;	//
		@AuraEnabled public String creditaccountnumber;	//
		@AuraEnabled public String creditlimitamount;	//0.00
		@AuraEnabled public String creditlimitcurrency;	//EUR
		@AuraEnabled public String creditexposureamount;	//0.00
		@AuraEnabled public String openbalanceamount;	//0.00
		@AuraEnabled public String openbalancecurrency;	//
		@AuraEnabled public String overdueamount;	//0.00
		@AuraEnabled public String overduecurrency;	//
		@AuraEnabled public String lastpaymentamount;	//0.00
		@AuraEnabled public String lastpaymentdate;	//
		@AuraEnabled public String lastpaymentcurrency;	//
		@AuraEnabled public CustomerFinance_Status Status; // NOPMD
	}

    /*
     * @description Wrapper class for Financial Info SAP API response body inner class
     */
	public class CustomerFinance_Status {
		@AuraEnabled public String Type; // NOPMD
		@AuraEnabled public String Description; // NOPMD
	}

    /**
     * @description Get Player Financial Info from SAP
     * @param {String} customernumber
     * @param {String} salesorg
     * @param {String} distributionchannel
     * @param {String} division
     * @return {CustomerFinance_Response_Wrapper} response
     */
    public static CustomerFinance_Response_Wrapper getPayerFinancialInfo( String customernumber, String salesorg, String distributionchannel, String division ) {
        HttpRequest httpRequest;
        HttpResponse httpResponse;
        CustomerFinance_Response_Wrapper response;

        try {
            CustomerFinance_Req_Wrapper requestWrapper = new CustomerFinance_Req_Wrapper(customernumber, salesorg, distributionchannel, division);
            
            Map<String, D1_Commerce_SAP_Setting__mdt> commerceSettingMap = new Map<String, D1_Commerce_SAP_Setting__mdt>();
            for(D1_Commerce_SAP_Setting__mdt commerceSetting : [SELECT DeveloperName, Value__c, SF_Instance__c FROM D1_Commerce_SAP_Setting__mdt]){
                commerceSettingMap.put(commerceSetting.DeveloperName, commerceSetting);
            }

            httpRequest = new HttpRequest();
            response = new CustomerFinance_Response_Wrapper();

            httpRequest.setMethod('POST');
            httpRequest.setHeader('Content-Type','application/json');
            httpRequest.setEndpoint('callout:' +PAYER_FINANCIAL_DETAILS_NAMED_CREDENTIAL);
            //httpRequest.setHeader('client_id',commerceSettingMap.get('Payer_Financial_Details_ClientId').Value__c);
            //httpRequest.setHeader('client_secret',commerceSettingMap.get('Payer_Financial_Details_ClientSecret').Value__c);
            httpRequest.setBody( JSON.serialize(requestWrapper) );
            httpRequest.setTimeout( 120000 );
            //httpRequest.setBody('{"CustomerFinance_Req": {"salesorg": "NA01","distributionchannel": "10","division": "10","customernumber": "7000035"}}');
        
            Http http = new Http();
            httpResponse = http.send(httpRequest);
            Integer statusCode = httpResponse.getStatusCode();
            String responseBody = httpResponse.getBody();
            
            if (statusCode == 200) {
                response = (CustomerFinance_Response_Wrapper)JSON.deserialize(responseBody, CustomerFinance_Response_Wrapper.class);
            }else{
                //NCP-3577
                D1_CustomLoggingUtility.logMessageFuture('D1_OrderCheckoutController', 'getPayerFinancialInfo', 'Payer Financial Info API failure', null, 'API Failure', (httpRequest != NULL? httpRequest.toString():''), (response != NULL? JSON.serialize(response):''));
            }
        } catch (Exception ex) {
            //NCP-3577
            D1_CustomLoggingUtility.logMessageFuture('D1_OrderCheckoutController', 'getPayerFinancialInfo', ex.getMessage(), ex.getStackTraceString(), ex.getTypeName(), (httpRequest != NULL? httpRequest.toString():''), (response != NULL? JSON.serialize(response):''));
            return null;
        }
        
        return response;
    }
}