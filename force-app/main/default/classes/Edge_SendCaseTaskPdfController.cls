/*
Class name : Edge_SendCaseTaskPdfController

Author              Version         Date                Detail
Debolina Saha       V1.0            03/12/2021          ES20-11518 - Case Task PDF Body generator
Swaraj Samanta   	V2.0			18/02/2022     		ES20-11832 - Addition of Account Unique Record Id


*/
public class Edge_SendCaseTaskPdfController {
    Public String caseTaskId {get; set;}
    Public String ContractorName {get; set;}
    Public String accountName {get; set;}
    Public String address1 {get; set;}
    Public String address2 {get; set;}
    Public String address3 {get; set;}
    Public String address4 {get; set;}
    Public String address5 {get; set;}
    Public String phone {get; set;}
    Public String legfrntnum {get; set;}
    Public String caseTypeName {get; set;}
    Public String caseSubTypeName {get; set;}
    Public String caseTaskType {get; set;}
    Public String productName {get; set;}
    Public String Case_Notes {get; set;}
    Public String CaseCreatedDate {get; set;}
    Public String CaseDueDateTime {get; set;}
    Public String TaskName {get; set;}
    Public String uniqueRecordId {get; set;}
    
    public Edge_SendCaseTaskPdfController(){
        caseTaskId = ApexPages.currentPage().getParameters().get('taskId');
        Case_Task__c caseTaskInfo = new Case_Task__c();
        if(Schema.sObjectType.Case_Task__c.isAccessible()){
            caseTaskInfo = [SELECT Case_Task__c.Account__r.Unique_Record_ID__c,Account__c,Achievement_Status__c,Actioned_Within_SLA__c,Asset__c,Call__c,
                            Case_Task_Notes__c,Case_Task_Type__r.Name,Case__c,Line_Cleaning_Due_Date__c,
                            Case__r.Case_Type__r.Name,Case__r.Case_Sub_Type__r.Name,
                            Case__r.Due_Date_Time__c,Case_Task__c.Account__r.Name,Case_Task__c.Account__r.BillingAddress,Case_Task__c.Account__r.Phone__c,
                            Case_Task__c.Account__r.legacy_Front_Office_Account_No__c,Case__r.Case_Notes__c,
                            Contractor_Name__c,Contractor_Name__r.Name,Country__c,Id,Name,Product_Name_MAP__c,
                            Product__c,Quantity_Cleaned__c,Quantity__c,Reason_Code__c,Reason_Comments__c,
                            Resolution_Code__c,User_Assigned_To__c,User_Assigned_To__r.Name,CreatedDate
                            FROM Case_Task__c WHERE Id = :caseTaskId];
        }
        System.debug('caseTaskInfo'+caseTaskInfo);
        if(caseTaskInfo.Contractor_Name__c !=null){
            ContractorName = caseTaskInfo.Contractor_Name__r.Name;
        }
        if(caseTaskInfo.Account__c !=null){
            accountName = caseTaskInfo.Account__r.Name;
        }
        if(caseTaskInfo.Account__r.BillingAddress !=null){
            Address addr=caseTaskInfo.Account__r.BillingAddress;
            address1 = addr.getStreet();
            address2 = addr.getPostalCode();
            address3 = addr.getCity();
            address4 = addr.getState();
            address5 = addr.getCountry();
        }
        if(caseTaskInfo.Account__r.Phone__c !=null){
            phone = caseTaskInfo.Account__r.Phone__c;
        }
        if(caseTaskInfo.Account__r.legacy_Front_Office_Account_No__c !=null){
            legfrntnum = caseTaskInfo.Account__r.legacy_Front_Office_Account_No__c;
        }
        if(caseTaskInfo.Case__r.Case_Type__c !=null){
            caseTypeName = caseTaskInfo.Case__r.Case_Type__r.Name;
        }
        if(caseTaskInfo.Case__r.Case_Sub_Type__c !=null){
            caseSubTypeName = caseTaskInfo.Case__r.Case_Sub_Type__r.Name;
        }
        if(caseTaskInfo.Case_Task_Type__r.Name !=null){
            caseTaskType = caseTaskInfo.Case_Task_Type__r.Name;
        }
        if(caseTaskInfo.Product_Name_MAP__c !=null){
            productName = caseTaskInfo.Product_Name_MAP__c;
        }
        if(caseTaskInfo.Case__r.Case_Notes__c !=null){
            Case_Notes = caseTaskInfo.Case__r.Case_Notes__c;
        }
        if(caseTaskInfo.CreatedDate != null){
            datetime cd = caseTaskInfo.CreatedDate;
           // CaseCreatedDate = cd.day() + '/' + cd.month() + '/'+ cd.year() + ' ' + cd.hour() + ':' + cd.minute(); 
           CaseCreatedDate = cd.format();
        }
        if(caseTaskInfo.Case__r.Due_Date_Time__c != null){
            datetime cd1 = caseTaskInfo.Case__r.Due_Date_Time__c;
            //CaseDueDateTime = cd1.day() + '/' + cd1.month() + '/'+ cd1.year() + ' ' + cd1.hour() + ':' + cd1.minute();
            CaseDueDateTime = cd1.format();
        }
        if(caseTaskInfo.Name !=null){
            TaskName = caseTaskInfo.Name;
        }
         if(caseTaskInfo.Account__r.Unique_Record_ID__c  !=null){
            uniqueRecordId = caseTaskInfo.Account__r.Unique_Record_ID__c;
        }
    }
}