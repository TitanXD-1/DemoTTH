/*
*@Name: ECM_GetSignedContractDetails
*@description: This class fetches required data for VF components "ECM_SignedContractMailTemplate_EN" and "..._ES"
*@History:  
*@AUTHOR            DATE              DETAIL
*@Wribhu            01/09/2022        Development for ECM-5901
*@Nikhilesh			14/10/2022		  ECM-6248 - Added ECM_Language_for_Customer_Email__c to the conList query
*/
public without sharing class ECM_GetSignedContractDetails {
    
    public Id targetObjectId { get; set; }
    /*public void ECM_GetSignedContractDetails(){
      
    }*/
    @AuraEnabled
    Public Contract getContractDetails() {
        
        Contract conDetails;
        List<Contract> conList = new List<Contract>();
        conList = [SELECT Id, Account.Email_for_contracts_payments__c,
                                   Account.Country_Code__c, Owner.Email, Account.Person_Responsible__c,
                                   RecordType.Name, ContractNumber, Owner.Name, Account.Name,
                                   Owner.IsActive, Owner.Manager.Email, Owner.Manager.IsActive,ECM_Agreement_Type__r.ECM_Language_for_Customer_Email__c
                                   FROM Contract
                                   WHERE Id = :targetObjectId];
        if(!conList.isEmpty()) {
            return conList[0];
        }
        return null;
    }

}