/**********************************************************************
Name: EDGE_RebateDetailTriggerHelper
=======================================================================
Req: 
ES20-2984 : SFDC_Rebate record NEW to APPROVED 
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE           DETAIL
1.0     Dipanjan Das     12/07/2019     ES20-2984 : SFDC_Rebate record NEW to APPROVED 
2.0     Manikant Prasad  19/07/2019     ES20-3138 : SFDC_Ad hoc A&P Spend record NEW to APPROVED
***********************************************************************/

public without sharing class EDGE_RebateDetailTriggerHelper {
    
    
    /*******************************************************************
Method  : updateRebateStatus
Purpose : This methods used to Approve Rebate .
********************************************************************/  
    public static void updateRebateStatus(List<Rebate_Detail__c> newItems){
        
        Set<Id> rebateIds = new Set<Id>();
        List<Rebate_Detail__c> rebateListtoUpdate = new List<Rebate_Detail__c>();
        Id outletRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId(); 
        Id ownerRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Owner/Operator').getRecordTypeId();    
        Id rebateRecordTypeId = Rebate_Detail__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Rebate').getRecordTypeId();
        Id apspendRecordTypeId = Rebate_Detail__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('A&P Spend').getRecordTypeId();
                
        
        for(Rebate_Detail__c rebate :newItems){
            rebateIds.add(rebate.Id);
        }
        
        //Setting rebate status to Approved and Updating Contract's Rebate Paid Amount
        for(Rebate_Detail__c rebate : [SELECT Contract__c, Amount__c, Contract__r.Rebate_Paid__c, Contract__r.Account.recordTypeId,recordTypeId, Contract__r.Account.Person_Responsible__c, Contract__r.Contract_Rebate_Outstanding__c, Contract__r.Available_AP_Spend__c, createdById FROM Rebate_Detail__c WHERE Id IN :rebateIds]){          
            if(rebate.recordTypeId == rebateRecordTypeId){
                if(rebate.Contract__r.Contract_Rebate_Outstanding__c < rebate.Amount__c){
                    rebate.Status__c = 'Rejected';
                }else{
                    if(rebate.Contract__r.Account.recordTypeId == ownerRecordTypeId){
                        if(rebate.createdById == rebate.Contract__r.Account.Person_Responsible__c ){
                            rebate.Status__c = 'Approved';
                        }                       
                    }else if(rebate.Contract__r.Account.recordTypeId == outletRecordTypeId){
                        rebate.Status__c = 'Approved';
                    }                   
                }
            }else if(rebate.recordTypeId == apspendRecordTypeId){
                if(rebate.Contract__r.Available_AP_Spend__c < rebate.Amount__c){
                    rebate.Status__c = 'Rejected';
                }else{
                    if(rebate.Contract__r.Account.recordTypeId == ownerRecordTypeId){
                        if(rebate.createdById == rebate.Contract__r.Account.Person_Responsible__c ){
                            rebate.Status__c = 'Approved';
                        }                       
                    }else if(rebate.Contract__r.Account.recordTypeId == outletRecordTypeId){
                        rebate.Status__c = 'Approved';
                    }
                }
            }                
            rebateListtoUpdate.add(rebate);          
        }
        if(rebateListtoUpdate != null && rebateListtoUpdate.size()> 0 && Schema.sObjectType.Rebate_Detail__c.isUpdateable()){
            try{
                update rebateListtoUpdate;  
            }catch(Exception ex){
                throw new EDGE_GenericException(ex, newItems[0]);
            }
            
        }
    }
    /*******************************************************************
Method  : updateContractRebatePaid
Purpose : This methods used to update contract fields.
********************************************************************/  
    public static void updateContractRebatePaid(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){   
        
        Id rebateRecordTypeId = Rebate_Detail__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Rebate').getRecordTypeId();
        Id apspendRecordTypeId = Rebate_Detail__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('A&P Spend').getRecordTypeId();
        
        Set<Id> rebateIds = new Set<Id>();
        List<Contract> contractListToUpdate = new List<Contract>(); 
        for(Id rebateId : newItems.keySet()){
            if(oldItems.get(rebateId).get('Status__c') != 'Approved' && newItems.get(rebateId).get('Status__c') == 'Approved'){
                rebateIds.add(rebateId);   
            }            
        }
        for(Rebate_Detail__c rebate : [SELECT Contract__c, Amount__c, Contract__r.Rebate_Paid__c,contract__r.AP_Spent__c, contract__r.Ad_Hoc_AP_Spent__c, recordTypeId FROM Rebate_Detail__c WHERE Id IN :rebateIds]){
        
            if(rebate.recordTypeId == rebateRecordTypeId){
                Contract con = new Contract(Id = rebate.Contract__c);
                con.Rebate_Paid__c = checkForNull(rebate.Contract__r.Rebate_Paid__c) + rebate.Amount__c;
                contractListToUpdate.add(con);  
            } 
            if(rebate.recordTypeId == apspendRecordTypeId){
                Contract con = new Contract(Id = rebate.Contract__c);
                con.AP_Spent__c = checkForNull(rebate.Contract__r.AP_Spent__c) + rebate.Amount__c;
                con.Ad_Hoc_AP_Spent__c = checkForNull(rebate.Contract__r.Ad_Hoc_AP_Spent__c) + rebate.Amount__c;
                contractListToUpdate.add(con);
            }
        }
        if(contractListToUpdate != null && contractListToUpdate.size()> 0 && Schema.sObjectType.Contract.isUpdateable()){
            update contractListToUpdate;
        } 
    }
    //Return 0 if value is null
    public static Decimal checkForNull(Decimal value){
        return EDGE_UtilityClass.checkForNull(value);
    } 
}