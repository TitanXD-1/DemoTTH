/**********************************************************************
Name: EDGE_OutletContractTriggerHelper
=======================================================================
Req: 
ES20-1989 - Populate Contract Lookup in Outlet Execution
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0    Dipanjan Das         21/06/2019      ES20-1989   


***********************************************************************/
public with sharing class EDGE_OutletContractTriggerHelper {
/*******************************************************************    
Purpose: the below method populates the active contract in outlet execution historic records 
********************************************************************/
    public static void updateContractOnOutletExecution(List<Outlet_Contract__c> newItems){   
    
        Set<Id> contractIds = new Set<Id>();
        Map<Id, List<Date>> contractsWithDatesMap = new Map<Id, List<Date>>();
        Map<Id, List<Outlet_Contract__c>> outletWithContractMap = new Map<Id, List<Outlet_Contract__c>>();
        List<Outlet_Execution_Historic__c> outletExHisListToUpdate = new List<Outlet_Execution_Historic__c>(); 
        if(newItems != null && newItems.size()>0){
            for(Outlet_Contract__c outContractObj : newItems){
                contractIds.add(outContractObj.Contract__c);
                if(outletWithContractMap.containsKey(outContractObj.Outlet__c )) {
                    outletWithContractMap.get(outContractObj.Outlet__c ).add(outContractObj);
                    
                } else {
                    outletWithContractMap.put(outContractObj.Outlet__c , new List<Outlet_Contract__c> { outContractObj });
                }
                
            }
            
            for(Contract con : [SELECT Id, StartDate, Contract_End_Date__c FROM Contract WHERE Id IN :contractIds]){
                contractsWithDatesMap.put(con.Id, new List<Date> {con.StartDate, con.Contract_End_Date__c});
            }
                            
            for(Outlet_Execution_Historic__c outletExHistoric :[SELECT Id, Date_of_Execution__c, Outlet__c FROM Outlet_Execution_Historic__c WHERE Contract__c = null AND Outlet__c IN :outletWithContractMap.keySet()]){
                if(outletWithContractMap.containsKey(outletExHistoric.Outlet__c)){
                    for(Outlet_Contract__c outletContract:outletWithContractMap.get(outletExHistoric.outlet__c)){  
                        if(outletExHistoric.Date_of_Execution__c >= contractsWithDatesMap.get(outletContract.contract__c).get(0) && outletExHistoric.Date_of_Execution__c <= contractsWithDatesMap.get(outletContract.contract__c).get(1)){
                            outletExHistoric.contract__c = outletContract.contract__c;
                            outletExHisListToUpdate.add(outletExHistoric);
                        }                       
                    }
                }
            }
            if(outletExHisListToUpdate != null && Schema.sObjectType.Outlet_Execution_Historic__c.isUpdateable() && outletExHisListToUpdate.size() >0){
                update outletExHisListToUpdate;     
            }   
        }         
    }
}