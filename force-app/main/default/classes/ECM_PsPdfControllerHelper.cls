/*
*@Name: ECM_PsPdfControllerHelper
*@Description: This is helper class for Vf page -"ECM_PS_PSFGeneration_Validation.vfp" and Aura component -"ECM_SaveAsInvoice.cmp"
*@History                                                                                                                       

VERSION			AUTHOR					DATE				DETAIL
*1.0		Tanishq Banerjee		  24/02/2023         ECM-6767 : Payment Summary Document_Dynamic fields_SFDC
*/

public with sharing class ECM_PsPdfControllerHelper {

    /** 
* @description	:	ECM-6750 : Validation on Payment Summary Custom Screen
* @return		:	ECM_Payment_Summary__c
* @param event	:	String
**/    
    public static ECM_Payment_Summary__c getPsDetails(String paySumId){
        return [SELECT Id,ECM_Payment_Summary_Status__c,ECM_Type__c,ECM_Contract__r.Account.Country_Code__c,ECM_Contract__r.ECM_Contract_Owner__c,
                ECM_Contract__r.Owner.Email,ECM_Contract__r.Account.ECM_Legal_Name__c,ECM_Contract__r.Account.New_VAT__c,ECM_Contract__r.Account.Legacy_Front_Office_Account_No__c,
                ECM_Contract__r.Account.Phone,ECM_Contract__r.Name,ECM_Contract__r.ContractNumber,ECM_Contract__r.StartDate,ECM_Start_Period__c,
                ECM_End_Period__c,Name,ECM_Contract__r.AccountId,ECM_Contract__r.Account.BillingStreet,ECM_Contract__r.Account.BillingPostalCode,ECM_Contract__r.Account.BillingCity,
                ECM_Contract__r.ECM_Agreement_Type__r.ECM_Language_for_Customer_Email__c,ECM_Invoice_Attachment__c
                FROM ECM_Payment_Summary__c WHERE Id=: paySumId WITH SECURITY_ENFORCED];
    }   
/** 
* @description	:	ECM-6750 : Validation on Payment Summary Custom Screen
* @return		:	List<ECM_Payment_Summary_Item__c>
* @param event	:	Id
**/   
    public static List<ECM_Payment_Summary_Item__c> getPsItems(Id paySumId){
        return [SELECT ECM_Confirmed_Amount_Per_Payment__c,ECM_Confirmed_Volume__c,
                ECM_Contract_Item__r.ECM_UoM__c,ECM_Contract_Item__r.ECM_Product_Name__c,
                ECM_Contract_Item__r.ECM_Brand__c
                FROM ECM_Payment_Summary_Item__c 
                WHERE ECM_Payment_Summary__c =: paySumId WITH SECURITY_ENFORCED];
    }
}