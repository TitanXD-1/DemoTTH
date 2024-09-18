/**********************************************************************
Name: CC_CreateCaseFromConcern
=======================================================================
Purpose: Apex Class to create Case from Customer Concern
=======================================================================
History                                                            
-------                                                            
VERSION         AUTHOR          DATE            DETAIL
1.0             Bhargav S       06/05/2021      Initial Development
***********************************************************************/
public class CC_CreateCaseFromConcern {
        
    public static void createCase(List<SObject> items){
        
        //fetch all custom fields on Concern
        Schema.DescribeSObjectResult r = CC_Customer_Concern__c.sObjectType.getDescribe();
        List<String> apiNames =  new List<String>();
        for(String apiName : r.fields.getMap().keySet()){
            if(apiName.startsWith('cc_') && apiName!='cc_case__c' && apiName!='cc_rejected_comments__c'
               && apiName!='CC_Case_Reference_ID__c' && apiName!='CC_Record_Type_Formula__c'
              )
                apiNames.add(apiName);
        }
        
        //fetch record types of both objects
        Id caseConsumerId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Consumer Concern').getRecordTypeId();
        Id caseCustomerId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Customer Concern').getRecordTypeId();
        Id directDisputeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Direct Disputes').getRecordTypeId();
        Id concernConsumerId = Schema.SObjectType.CC_Customer_Concern__c.getRecordTypeInfosByName().get('Consumer Concern').getRecordTypeId();
        Id concernCustomerId = Schema.SObjectType.CC_Customer_Concern__c.getRecordTypeInfosByName().get('Customer Concern').getRecordTypeId();
        Id concernConsumerCreationId = Schema.SObjectType.CC_Customer_Concern__c.getRecordTypeInfosByName().get('Consumer Concern Creation').getRecordTypeId();
        Id concernCustomerCreationId = Schema.SObjectType.CC_Customer_Concern__c.getRecordTypeInfosByName().get('Customer Concern Creation').getRecordTypeId();
        
        Map<Id,CC_Customer_Concern__c> ccIdccRecordMap = new Map<Id,CC_Customer_Concern__c>();
        Map<Id,Case> ccIdCaseRecordMap = new Map<Id,Case>();
        
        for(SObject o : items){
            CC_Customer_Concern__c cc = (CC_Customer_Concern__c)o;
            ccIdccRecordMap.put(cc.Id,cc);
            Case c = new Case();
            for(String apiName : apiNames){
                
                //handle fields where api names are different
                if(apiName == 'cc_details_of_concern__c')
                    c.Description = cc.CC_Details_of_Concern__c;
                else if(apiName == 'cc_priority__c')
                    c.Priority = cc.CC_Priority__c;
                else if(apiName == 'cc_fault_category__c')
                    c.CC_Fault_Category_1__c = cc.CC_Fault_Category__c;
                else if(apiName == 'cc_status__c')
                    c.Status = cc.CC_Status__c;
                else if(apiName == 'cc_email_address__c')
                    c.SuppliedEmail = cc.CC_Email_Address__c;
                //all other fields to go to respective api names on case
                else
                    c.put(apiName,cc.get(apiName));
                
                //record type assignment
                if(cc.RecordTypeId == concernConsumerCreationId)
                    c.RecordTypeId = caseConsumerId;
                else
                    c.RecordTypeId = caseCustomerId;
                
                //setting boolean to true to avoid recursion
                c.CC_Is_Customer_Concern_Created__c = true;
                //PION-2494 Change; This is to create a DD Case based on the Concern Type
                if(cc.CC_Concern_Type__c =='Dispute – Delivery' || cc.CC_Concern_Type__c =='Dispute – Pricing' || cc.CC_Concern_Type__c =='Dispute – Unknown'){
                    c.AccountId = cc.Account_Name__c;
                    c.type = cc.CC_Concern_Type__c;
                    c.RecordTypeId = directDisputeId;
                    c.Sales_Org__c = cc.Account_Name__r.Sales_Org__c;
                    
                }//PION-2494 Change end;
            }
            
            ccIdCaseRecordMap.put(cc.Id,c);
            
        }
        insert ccIdCaseRecordMap.values();
        
        //return case list to capture case ids and case numbers on concern
        Map<Id,Id> ccIdCaseIdMap = new Map<Id,Id>();
        for(Id i : ccIdCaseRecordMap.keySet())
            ccIdCaseIdMap.put(i,ccIdCaseRecordMap.get(i).Id);
        Map<Id,Case> caseIdcaseRecordMap = new Map<Id,Case>([SELECT Id, CaseNumber FROM Case WHERE Id IN : ccIdCaseIdMap.values()]);
        
        List<CC_Customer_Concern__c> ccList = new List<CC_Customer_Concern__c>();
        for(Id i : ccIdccRecordMap.keySet()){
            CC_Customer_Concern__c cc = new CC_Customer_Concern__c();
            cc.Id = i;
            cc.Name = caseIdcaseRecordMap.get(ccIdCaseIdMap.get(i)).CaseNumber;
            cc.CC_Case__c = caseIdcaseRecordMap.get(ccIdCaseIdMap.get(i)).Id;
            ccList.add(cc);
        }
        update ccList;
    }
    
    public static void updateCaseStatus(List<CC_Customer_Concern__c> ccList){
        Set<Id> caseIds = new Set<Id>();
        Map<Id,CC_Customer_Concern__c> caseIdConcernMap = new Map<Id,CC_Customer_Concern__c>();
        for(CC_Customer_Concern__c cc : ccList){
            caseIds.add(cc.CC_Case__c);
            caseIdConcernMap.put(cc.CC_Case__c,cc);
        }
        
        List<Case> caseList = [SELECT Id, Status, CC_CoQ_Management_time_failure_analysis__c,
                               CC_Cost_of_Quality_Additional_Inspection__c, CC_Cost_of_Quality_In_process_waste__c,
                               CC_Cost_of_Quality_Rework_reprocessing__c, CC_Cost_of_Quality_Scrap__c,
                               CC_Cost_of_Quality_Cost_of_Reclaims__c, CC_Is_it_a_regulatory_issue__c, CC_Comments__c
                               FROM Case WHERE Id IN : caseIds];
        for(Case c : caseList){
            c.Status = caseIdConcernMap.get(c.Id).CC_Status__c;
            if(caseIdConcernMap.get(c.Id).CC_Status__c == 'Closed'){
                c.CC_CoQ_Management_time_failure_analysis__c = caseIdConcernMap.get(c.Id).CC_CoQ_Management_time_failure_analysis__c;
                c.CC_Cost_of_Quality_Additional_Inspection__c = caseIdConcernMap.get(c.Id).CC_Cost_of_Quality_Additional_Inspection__c;
                c.CC_Cost_of_Quality_In_process_waste__c = caseIdConcernMap.get(c.Id).CC_Cost_of_Quality_In_process_waste__c;
                c.CC_Cost_of_Quality_Rework_reprocessing__c = caseIdConcernMap.get(c.Id).CC_Cost_of_Quality_Rework_reprocessing__c;
                c.CC_Cost_of_Quality_Scrap__c = caseIdConcernMap.get(c.Id).CC_Cost_of_Quality_Scrap__c;
                c.CC_Cost_of_Quality_Cost_of_Reclaims__c = caseIdConcernMap.get(c.Id).CC_Cost_of_Quality_Cost_of_Reclaims__c;
                //c.CC_Is_it_a_regulatory_issue__c = caseIdConcernMap.get(c.Id).CC_Is_it_a_regulatory_issue__c;
            }
            if(caseIdConcernMap.get(c.Id).CC_Status__c == system.label.CC_Concern_Status_Under_Investigation){
                 c.CC_Comments__c = caseIdConcernMap.get(c.Id).CC_Rejected_Comments__c;
            }
        }
        update caseList;
    }
}