/**
* @Description: ECM_ChangeContractStatusController
* @Purpose : ES20-14083 
* @History:
* @Version     Developer		   	 Date			    Story/Purpose
*	1.0		   Monalisa Halder		30/05/2023			ES20-14083

*/


public with sharing class ECM_ChangeContractStatusController {
    
    
    @AuraEnabled(cacheable=true)
    public static Boolean getContractStatus (Id contractId){
        String contractStatus;
        Boolean statusCheck = false;    
        String statusAllowed = system.label.ECM_ContractStatusCheck;
        List<String> statusAllowedList = new List<String>();
        statusAllowedList = statusAllowed.split(';');
        List<Contract> contractList = [Select Id, Status  from Contract where Id =:contractId WITH SECURITY_ENFORCED];
        if(contractList != null && contractList.size() >0){
           contractStatus = contractList[0].Status; 
        }
        
        for(String statusMatch :statusAllowedList){
            statusCheck = statusAllowedList.contains(contractStatus);
            if(statusCheck == true){
                break;  
            }
        }
        
        return statusCheck;
    }
}