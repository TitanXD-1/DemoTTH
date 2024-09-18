/*
* Class Name: ECM_ApprovalLogWrapper
* Author: 
* Brief Description: This class is used as Wrapper for ECM_ApprovalLogTriggerHelper & ECM_ApprovalLog.
* Created Date: 
* History: 
*VERSION			AUTHOR					DATE					DETAIL
*1.0			Manikandan T									Initial Development
*2.0			Saurav Prasad			08/08/2022				ECM-5867 : Approval flow for Addendum (Prim+Contract)_SFDC_EU
*3.0			Anand Uppalapati		08/08/2022				ECM-5905 : Approval flow for Addendum (SD+Legal)_SFDC_EU
*4.0            Suvendu Roy             02/09/2022              ECM-6074 : Logic for "Type" field on Template Agreement_Addendum_SFDC_EU
*/
public class ECM_ApprovalLogWrapper {

    public  Map<Id,ECM_Contract_type__c> agreementTypeMap{get; set;}
    public  Map<Id,Map<String,Decimal>> ContractSalesDriverItemMap{get; set;}
    public  Map<Id,List<ECM_Sales_Driver_Item_Detail__c>> ContractSalesDriverItemDetailMap{get; set;}
    public  List<ECM_Approval_Log__c> ApprovalLogList{get; set;}
    public  Map<Id,Id> primaryApprovalLogMap{get; set;}
    public  Map<String,Market_Setting__c> marketSettingMap{get; set;}
    public  Map<String,emailTemplate> emailTemplateMap{get; set;}
    public  Map<Id,ContentDocumentLink> contentDocumentLinkMap{get; set;}
    //ECM-6074
    public  Map<Id,ContentDocumentLink> contentDocumentLinkMapAddendum{get; set;}
	public  List<Messaging.SingleEmailMessage> multiuserEmailList{get; set;}
	public  String OrgWideEmailAddressId{get; set;}
	public  String rejectionEmailTemplateId{get; set;}
    //ECM-5905
    public  ECM_Approval_Log__c currentApprovalLog{get;set;}
    public  Map<Id,set<String>> legalApprovalLog{get;set;}
    //ECM-5867
    public Map<String,Decimal> newInvestmentConItemAddendum{get;set;}
    
    public ECM_ApprovalLogWrapper(){
        this.agreementTypeMap= new Map<Id,ECM_Contract_type__c>();
        this.ContractSalesDriverItemMap= new Map<Id,Map<String,Decimal>>();
        this.contentDocumentLinkMapAddendum = new Map<Id, ContentDocumentLink>();
        this.ContractSalesDriverItemDetailMap= new Map<Id,List<ECM_Sales_Driver_Item_Detail__c>>();
        this.ApprovalLogList= new List<ECM_Approval_Log__c>();
        this.primaryApprovalLogMap = new Map<Id,Id>();
        this.marketSettingMap= new Map<String,Market_Setting__c>();
        this.emailTemplateMap= new Map<String,emailTemplate>();
        this.ContentDocumentLinkMap= new Map<Id,ContentDocumentLink>();   
		this.multiuserEmailList= new List<Messaging.SingleEmailMessage>();
        this.currentApprovalLog = new ECM_Approval_Log__c();
        this.newInvestmentConItemAddendum = new Map<String,Decimal>();
        this.legalApprovalLog = new Map<Id,set<String>>();
    }
}