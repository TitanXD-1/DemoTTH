/*
 * @Name: ECM_AddendumConDepletionCreateHelper
 * @Description: This is the Helper class for ECM_AddendumConDepletionCreateBatch
 * @Parameters:  ECM_VolumeInputScreenControllerA map With Child Id & ECM_Contract_Item__c's List
 * @History                         
                                                         
VERSION    AUTHOR                     DATE              DETAIL
1.0        Suvendu Roy	        	  25/10/2022        Initial Development (ECM-6220)
*/ 

public class ECM_AddendumConDepletionCreateHelper {
    public static void addendumCreate(Map<Id,Id> parChilConMap ){
        Map<Id,List<Id>> parentConConItmMap = new Map<Id,List<Id>>();
        Map<Id,Map<Id,List<Id>>> childConConItmMap = new Map<Id,Map<Id,List<Id>>>();
        List<Id> conIdList = new List<Id>();
        List<Id> prodtIdList = new List<Id>();
        List<Depletions__c> depInsertList = new List<Depletions__c>();
        for(ECM_Contract_Item__c parConObj : [SELECT Id,ECM_Contract__c,ECM_Product__r.Product__c FROM ECM_Contract_Item__c WHERE ECM_Contract__c IN : parChilConMap.keySet()]){
            if(parentConConItmMap.containsKey(parConObj.ECM_Contract__c)){
                parentConConItmMap.get(parConObj.ECM_Contract__c).add(parConObj.ECM_Product__r.Product__c);
            }else{
                parentConConItmMap.put(parConObj.ECM_Contract__c,new List<Id>{parConObj.ECM_Product__r.Product__c});
            }
        }
        for(ECM_Contract_Item__c chilConObj : [SELECT Id,ECM_Contract__c,ECM_Contract__r.ECM_Parent_Contract__c,ECM_Product__r.Product__c  FROM ECM_Contract_Item__c WHERE ECM_Contract__c IN : parChilConMap.values()]){
            if(childConConItmMap.containsKey(chilConObj.Id)){
                if(childConConItmMap.get(chilConObj.Id).containsKey(chilConObj.ECM_Contract__r.ECM_Parent_Contract__c)){
                    childConConItmMap.get(chilConObj.Id).get(chilConObj.ECM_Contract__r.ECM_Parent_Contract__c).add(chilConObj.ECM_Product__r.Product__c);
                }else{
                    Map<Id,List<Id>> parProductMap = new Map<Id,List<Id>>();
                    parProductMap.put(chilConObj.ECM_Contract__r.ECM_Parent_Contract__c,new List<Id>{chilConObj.ECM_Product__r.Product__c});
                    childConConItmMap.get(chilConObj.Id).putAll(parProductMap);
                }
            }else{
                Map<Id,List<Id>> parProductMap = new Map<Id,List<Id>>();
                parProductMap.put(chilConObj.ECM_Contract__r.ECM_Parent_Contract__c,new List<Id>{chilConObj.ECM_Product__r.Product__c});
                childConConItmMap.put(chilConObj.Id,parProductMap);
            }
        }
        
        //Checking if the child contract is having the product with it
        for(Id childConId : childConConItmMap.keySet()){
            Map<Id,List<Id>> parCom = childConConItmMap.get(childConId);
            if(parCom!= null && !parCom.isEmpty()){
                for(Id parenConId : parCom.keySet()){
                    if(parentConConItmMap.containsKey(parenConId)){
                        for(Id productId : parCom.get(parenConId)){
                            if(parentConConItmMap.get(parenConId).contains(productId)){
                                conIdList.add(parenConId);
                                prodtIdList.add(productId);
                            }
                        }
                    }
                }
            }
        }
        if(!conIdList.isEmpty()){
            for(Depletions__c depObj : [SELECT Id,Contract__c,ECM_End_Period__c,ECM_Geography__c,ECM_Outlet__c,
                                        ECM_Product__c,ECM_Rate_UoM__c,ECM_Start_Period__c,Unique_ID__c,ECM_UoM__c,
                                        Forecast_Volume__c,ECM_Volume__c,ECM_Wholesaler__c
                                       FROM Depletions__c
                                       WHERE Contract__c IN :conIdList
                                       AND ECM_Product__c IN : prodtIdList
                                       AND ECM_Volume__c>0]){
                Depletions__c clonedDep =  depObj.clone(false, true, false, false); 
                if(parChilConMap.containsKey(depObj.Contract__c)){
                    String updatedConId = parChilConMap.get(depObj.Contract__c);
                    String uniqueId = depObj.Unique_ID__c.substringAfter('_');
                    uniqueId = updatedConId + '_'+uniqueId;
                    clonedDep.Contract__c = updatedConId;
                    clonedDep.Unique_ID__c = uniqueId;
                    depInsertList.add(clonedDep);  
                }                           
            }
        }
        system.debug('--->'+depInsertList.size());
        if(!depInsertList.isEmpty()){
            insert depInsertList;
        }
    }
}