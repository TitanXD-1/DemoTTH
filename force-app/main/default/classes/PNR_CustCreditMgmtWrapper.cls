/**********************************************************************
  Name: PNR_CustCreditMgmtWrapper
=======================================================================
  Purpose: Wrapper Class to hold SAP data for Customer Credit Management Data
=======================================================================
    History                                                            
------------------------------------------------------------------------                                                            
    VERSION    AUTHOR            DATE              DETAIL
	1.0        Saurav Paul     12-06-2019        Initial Development
***********************************************************************/
public class PNR_CustCreditMgmtWrapper {
    //Variables
    @AuraEnabled public String payerName {get;set;}
    @AuraEnabled public String creditLimit {get;set;}
    @AuraEnabled public String creditExposure {get;set;}
    @AuraEnabled public String creditLimitUsed {get;set;}
    @AuraEnabled public String currencyVal {get;set;}
    @AuraEnabled public String rating {get;set;}
    @AuraEnabled public Date lastReviwDate {get;set;}
    @AuraEnabled public String riskCat {get;set;}
    @AuraEnabled public String paymentTerm {get;set;}
    public PNR_CustCreditMgmtWrapper(String payerName,String creditLimit,
                                     String creditExposure, String creditLimitUsed,
                                     String currencyVal,String rating,
                                     Date lastReviwDate, String riskCat,
                                     String paymentTerm){
		this.payerName = payerName;
        this.creditLimit = creditLimit;
        this.creditExposure = creditExposure;
        this.creditLimitUsed = creditLimitUsed;
		this.currencyVal = currencyVal;
        this.rating = rating;
        this.lastReviwDate = lastReviwDate;
        this.riskCat = riskCat;
        this.paymentTerm = paymentTerm;
    }
}