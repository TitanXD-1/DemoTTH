/**********************************************************************
Name: EDGE_OutletExHistoricTriggerHelper
=======================================================================
Req: 
ES20-1966 - Roll-up Outlet Execution Historic Data To Contract
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0    Anuja Chattopadhyay  12/06/2019      Initial Development

***********************************************************************/
public with sharing class EDGE_OutletExHistoricTriggerHelper {
    /*******************************************************************    
Purpose: the below method populates the active contract in outlet execution historic records 
********************************************************************/
    public static void updateContract(List<Outlet_Execution_Historic__c> newItems){
        Set<Id> outletSetToUpdate = new Set<Id>();
        Map<Id, List<Outlet_Contract__c>> contrctAccountMap = new Map<Id, List<Outlet_Contract__c>>();
        String contractvolRecordTypeId = Outlet_Execution_Historic__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Contract Volume').getRecordTypeId();
        
        //Preparing the outlet set for new outlet execution historic records
        if(newItems != null){
            for(Outlet_Execution_Historic__c newOutletExHistoric:newItems ){
                if(newOutletExHistoric.Outlet__c!=null && newOutletExHistoric.RecordTypeId == contractvolRecordTypeId && Schema.sObjectType.Outlet_Contract__c.isAccessible()){
                    outletSetToUpdate.add(newOutletExHistoric.Outlet__c);
                }
            }
        }
        
        System.debug('@@outletSetToUpdate' +outletSetToUpdate);
        //Fetching the list of account contracts for associated outlets and preparing contract-account map
        if(Schema.sObjectType.Outlet_Contract__c.isAccessible()){
            //made cchanges for ECM-2202
            List<Outlet_Contract__c> outContractList = [Select Id,Outlet__c,Contract__c,Contract__r.StartDate,
                                                        Contract__r.Contract_End_Date__c from Outlet_Contract__c where
                                                        Outlet__c in :outletSetToUpdate and Status__c = 'Active'  AND Contract__r.Status ='Active'];
            
            if(outContractList != null && outContractList.size()>0){
                for(Outlet_Contract__c outContractObj : outContractList){
                    if(contrctAccountMap.containsKey(outContractObj.Outlet__c )) {
                        contrctAccountMap.get(outContractObj.Outlet__c ).add(outContractObj);
                    } else {
                        contrctAccountMap.put(outContractObj.Outlet__c , new List<Outlet_Contract__c> { outContractObj });
                    }
                }
            } 
        }   
        
        for(Outlet_Execution_Historic__c newOutletExHistoric: newItems){
            if(contrctAccountMap!=null && contrctAccountMap.containsKey(newOutletExHistoric.outlet__c)){
                for(Outlet_Contract__c outletContract : contrctAccountMap.get(newOutletExHistoric.outlet__c)){
                    newOutletExHistoric.contract__c = outletContract.contract__c;     
                }
            }
        }
    }
    
    /*******************************************************************    
    Purpose: the below method rolls up Volume UoS to outlet execution historic records 
    ********************************************************************/
    public static void updateUoSErntOnContract(List<Outlet_Execution_Historic__c> newItems){
        
        //variables    
        Set<Id> contractSet = new Set<Id>();
        Map<Id, List<Outlet_Execution_Historic__c>> contrctOutletExHistoricMap = new Map<Id, List<Outlet_Execution_Historic__c>>();
        Map<Id, Decimal> contrctUOSEarntMap = new Map<Id, Decimal>();
        List<Contract> contractList = new List<Contract>();
        String contractvolRecordTypeId = Outlet_Execution_Historic__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Contract Volume').getRecordTypeId();
        //Fetching the associated contract 
        if(newItems!=null){
            for(Outlet_Execution_Historic__c newOutletExHistoric : newItems){
                if(newOutletExHistoric.Contract__c != null && newOutletExHistoric.RecordTypeId == contractvolRecordTypeId){
                    contractSet.add(newOutletExHistoric.Contract__c);
                }
            }
        }
        
        if(contractSet.size() > 0){
            //made cchanges for ECM-2202
            for(Contract contractObj : [Select Id, UOS_Earnt__c, Initial_UOS_Earnt__c from Contract where Id in :contractSet AND ECM_isTBPContract__c = false]){
                Decimal initialUOSEarnt = 0.0;
                if(contractObj.Initial_UOS_Earnt__c!=null){
                	initialUOSEarnt = contractObj.Initial_UOS_Earnt__c;                   
                }
                contrctUOSEarntMap.put(contractObj.Id, initialUOSEarnt);  
            }
            
            //Preparing contract and outlet execution historic map to get the realed outlet execution historic
            //made cchanges for ECM-2202
            for(Outlet_Execution_Historic__c outExHisObj : [Select Id,Outlet__c, Contract__c, Volume_UoS__c from Outlet_Execution_Historic__c 
                                                            where Contract__c = :contractSet AND Contract__r.ECM_isTBPContract__c = false]){
                                                                
                if(contrctOutletExHistoricMap.containsKey(outExHisObj.Contract__c)) {
                    List<Outlet_Execution_Historic__c> outletExHistoricList = contrctOutletExHistoricMap.get(outExHisObj.Contract__c);
                    outletExHistoricList.add(outExHisObj);
                    contrctOutletExHistoricMap.put(outExHisObj.Contract__c, outletExHistoricList);
                } else {
                    contrctOutletExHistoricMap.put(outExHisObj.Contract__c, new List<Outlet_Execution_Historic__c> {outExHisObj});
                }                
            }
        }
                
        
        if(contrctOutletExHistoricMap!=null){
            for(Id contrctObj : contrctOutletExHistoricMap.keySet()){
                Contract tempCntrct = new Contract(Id=contrctObj);
                Decimal sum = 0.0;  
                
                for(Outlet_Execution_Historic__c outHistrcObj : contrctOutletExHistoricMap.get(contrctObj) ){ 
                    if(outHistrcObj.Volume_UoS__c != null){
                        sum = sum + outHistrcObj.Volume_UoS__c;
                    }
                }
                
                if(contrctUOSEarntMap != null && contrctUOSEarntMap.containsKey(contrctObj)){
                    tempCntrct.UOS_Earnt__c = sum + contrctUOSEarntMap.get(contrctObj);    
                }
                else{
                    tempCntrct.UOS_Earnt__c = sum;   
                }
                contractList.add(tempCntrct);
            }
        }
        System.debug('@@contractList' +contractList);
        if(contractList != null && contractList.size()>0 && Schema.sObjectType.Contract.isUpdateable()){
            system.debug('inside update');
            update contractList;
        }
    }   
    
    
}