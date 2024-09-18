/**********************************************************************
  Name: PNR_FetchCreditSituationCtrl
=======================================================================
  Purpose: This is the Controller class for PNR_CustCreditMgmtDetalTableComponent
=======================================================================
    History                                                            
------------------------------------------------------------------------                                                            
    VERSION    AUTHOR            DATE              DETAIL
	1.0        Saurav Paul     12-06-2019        Initial Development
	2.0        Saurav Paul     12-06-2019        Fetch Customer Credti Exposure Data
    3.0        Anamika Shukla  29-02-2024        EDGE Global: Mulesoft OAuth2 migration-358242
***********************************************************************/
public with sharing class PNR_FetchCreditSituationCtrl {
     public static final String PIONEER_MULESOFT_COMMENT = 'Pioneer_Mulesoft_Customer_Credit_Fetch';//358242
    
    /*******************************************************************
    Method  : CustCrditExpWrapper
    Purpose : This wrapper class is used to send values to SAP
    ***********************************************************************/
    public class CustCrditExpWrapper{
		String salesOrg,custNumber,partnerFunc;
		public CustCrditExpWrapper(String salesOrg, String custNumber, String partnerFunc){
            this.salesOrg = salesOrg;
            this.custNumber = custNumber;
            this.partnerFunc = partnerFunc;
		}
	}
    /*******************************************************************
    Method  : sendData
    Purpose : This method is used to parse JSON Data and add to Wrapper
    ***********************************************************************/
    @AuraEnabled
    public static List<PNR_FetchCreditSituationCtrl.CustCreditMgmtWrapper> sendData(String custNumber,String salsOrg,String custType){
        //Variables
        List<PNR_FetchCreditSituationCtrl.CustCreditMgmtWrapper> wrapperLst = new List<PNR_FetchCreditSituationCtrl.CustCreditMgmtWrapper>();
        Set<String> accExtIdSet = new Set<String>();
        List<Account> accList = new List<Account>();
        Map<String,String> accountMap = new Map<String,String>();
        //Variables
        //CReating JSON Req
        CustCrditExpWrapper wrapDataObj = new CustCrditExpWrapper(salsOrg,custNumber,custType);
        String jsonPayload = JSON.serialize(wrapDataObj);
        //Fetching JSON Response
		String jsonBody = PNR_FetchCreditSituationCtrl.fetchCustCredit(jsonPayload);
        if(String.isNotBlank(jsonBody) && jsonBody != ''){
			try{
                //Parsing JSON Data
				PNR_CustCreditExpWrapper wrapObj = PNR_CustCreditExpWrapper.parse(jsonBody);
                if(wrapObj.status.equalsIgnoreCase('s') && Integer.valueOf(wrapObj.recordCount) >0){
					if(!wrapObj.AccountList.AcountRecord.isEmpty()){
						for(PNR_CustCreditExpWrapper.AcountRecord recObj : wrapObj.AccountList.AcountRecord){
							accExtIdSet.add(recObj.accountNumber);
                            accExtIdSet.add(recObj.customerNumber);
						}
						if(!accExtIdSet.isEmpty() && Schema.SObjectType.Account.isAccessible()
                           && Schema.SObjectType.Account.fields.Name.isAccessible()){
							accList = [SELECT Id,Name,KUNNR__c 
									   FROM Account 
									   WHERE KUNNR__c IN : accExtIdSet];
							if(!accList.isEmpty()){
								for(Account accObj : accList){
									accountMap.put(accObj.KUNNR__c, accObj.Name);
								}
							}
						}
						for(PNR_CustCreditExpWrapper.AcountRecord recObj : wrapObj.AccountList.AcountRecord){
							String accName = '';
                            String creditAccName = '';
							if(!accountMap.isEmpty() && accountMap.containsKey(recObj.accountNumber) ){
								creditAccName = accountMap.get(recObj.accountNumber);
							}else{
								creditAccName = recObj.accountNumber;
							}
                            if(!accountMap.isEmpty() && accountMap.containsKey(recObj.customerNumber) ){
								accName = accountMap.get(recObj.customerNumber);
							}else{
								accName = recObj.customerNumber;
							}
							PNR_FetchCreditSituationCtrl.CustCreditMgmtWrapper wrapData 
								= new PNR_FetchCreditSituationCtrl.CustCreditMgmtWrapper(accName,recObj.customerNumber,creditAccName,recObj.creditLimit.format(),
																			   recObj.creditExposure.format(),recObj.creditLimitUsed.format()+'%',
																			   recObj.currencyVal,recObj.rating,
																			   PNR_FetchCreditSituationCtrl.conDate(recObj.lastReviewDate) ,recObj.riskCategory,
																			   recObj.descriptionOfPaymentTerms,false);
							wrapperLst.add(wrapData);
						}
					}
                }
			}catch(Exception ex){
                PNR_FetchCreditSituationCtrl.createLog(ex.getMessage(),'Customer Credit Fetch' , null, 'Failure', 'Customer');
			}
            
        }else{
            PNR_FetchCreditSituationCtrl.CustCreditMgmtWrapper wrapData 
								= new PNR_FetchCreditSituationCtrl.CustCreditMgmtWrapper(null,null,
                                                                                         null,null,
                                                                                         null,null,
                                                                                         null,null,
                                                                                         null,null,
                                                                                         null,true);
			wrapperLst.add(wrapData);
        }
        
        return wrapperLst;
    }
    /*******************************************************************
    Method  : fetchCustCredit
    Purpose : This method is used to call out and get JSON Data
    ***********************************************************************/
    public static String fetchCustCredit(String jsonPayload){
        String jsonBody = '';
        //String endPoint = Label.EndPoint_Customer_Credit_Fetch;
        //String clientId = Label.X_IBM_Client_Id;
        //String clientSecret = Label.X_IBM_Client_Secret;
        
        HttpRequest request = new HttpRequest();
        HttpResponse res = new HttpResponse();
        Http http = new Http();
        //request.setEndpoint(endPoint);
        request.setEndpoint('callout:' +PIONEER_MULESOFT_COMMENT);
        request.setMethod('POST');
        //request.setHeader('client_id',clientId);
        //request.setHeader('client_secret',clientSecret);
        request.setHeader('Content-Type','application/json');
        request.setTimeout(120000);
        request.setBody(jsonPayload);
        try {
        	res = http.send(request);
            if(res.getStatusCode() == 200){
                jsonBody = res.getBody();
            }else{
                jsonBody ='';
                PNR_FetchCreditSituationCtrl.createLog('Response Status code is : '+String.valueOf(res.getStatusCode()),
                                                       'Customer Credit Fetch' , jsonPayload, 'Failure', 'Customer');
            }
        }catch(Exception ex){
            PNR_FetchCreditSituationCtrl.createLog(ex.getMessage(),'Customer Credit Fetch' , jsonPayload, 'Failure', 'Customer');
        }
        return jsonBody;
    }
    /*******************************************************************
    Method  : CustCreditMgmtWrapper
    Purpose : This wrapper class is used to display Data in UI
    ***********************************************************************/
    public class CustCreditMgmtWrapper {
        //Variables
        @AuraEnabled public String payerName {get;set;}
        @AuraEnabled public String creditAcc {get;set;}
        @AuraEnabled public String creditAccName {get;set;}
        @AuraEnabled public String creditLimit {get;set;}
        @AuraEnabled public String creditExposure {get;set;}
        @AuraEnabled public String creditLimitUsed {get;set;}
        @AuraEnabled public String currencyVal {get;set;}
        @AuraEnabled public String rating {get;set;}
        @AuraEnabled public Date lastReviwDate {get;set;}
        @AuraEnabled public String riskCat {get;set;}
        @AuraEnabled public String paymentTerm {get;set;}
        @AuraEnabled public Boolean isError {get;set;}
        public CustCreditMgmtWrapper(String payerName,String creditAcc,String creditAccName,String creditLimit,
                                         String creditExposure, String creditLimitUsed,
                                         String currencyVal,String rating,
                                         Date lastReviwDate, String riskCat,
                                         String paymentTerm, Boolean isError){
            this.payerName = payerName;
            this.creditAcc = creditAcc;
            this.creditAccName = creditAccName;
            this.creditLimit = creditLimit;
            this.creditExposure = creditExposure;
            this.creditLimitUsed = creditLimitUsed;
            this.currencyVal = currencyVal;
            this.rating = rating;
            this.lastReviwDate = lastReviwDate;
            this.riskCat = riskCat;
            this.paymentTerm = paymentTerm;
            this.isError = isError;
        }
	}
    /*******************************************************************
    Method  : createLog
    Purpose : This method is used to Create Integration log record
    ***********************************************************************/
    public static void createLog(String errMsg, String interfcName, 
                                 String res, String status, String objType){
        Integration_Log__c logObj = new Integration_Log__c();
        logObj.Error_Message__c = errMsg;
        logObj.Interface_Name__c = interfcName;
        logObj.Response__c = res;
        logObj.Status__c = status;
        logObj.Type_of_Object__c = objType;
        if(Schema.SObjectType.Integration_Log__c.isCreateable()){
        	insert logObj;                                 
        }                             
        
    }
    /*******************************************************************
    Method  : conDate
    Purpose : This method is converting a String 'yyyy-mm-dd''yyyymmdd' into a Date
    ***********************************************************************/
    public static Date conDate(String dateString){
        if(dateString.contains('-')){
            Date myDate = Date.valueOf(dateString);
            return myDate;
        }else if(dateString.length()>=8){
            String yearVal = dateString.substring(0, 4);
            String monthVal = dateString.substring(4, 6);
            String dayVal = dateString.substring(6, 8);
            String stringDate = yearVal + '-' + monthVal+ '-' + dayVal;
            Date myDate = Date.valueOf(stringDate);
            return myDate;
        }else{
            return null;
        }
    }
}