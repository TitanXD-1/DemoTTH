/*
@Name: CO_TaxClassificationWrapper

@Purpose: This class is used by the CO_ApprovalProcessController class to generate customer details pdf and
to send pdf templates emails for the approvers.

@History                                                                   

VERSION    AUTHOR            DATE              DETAIL
1.0        priyanka 		 24-04-2023        CONS-871
*/
public with sharing class CO_TaxClassificationWrapper {
    public List<Tax_Classification__c> tablerows {get; set;}
    public Boolean hasLicense {get; set;}
    public CO_TaxClassificationWrapper(){           
        tablerows = new List<Tax_Classification__c>();
        hasLicense = false;
    }
}