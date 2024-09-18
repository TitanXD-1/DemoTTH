/**

* @Description: EDGE_AccountTriggerPersonRespHelper

* @Purpose: 
* @History:                                                            
* @VERSION    AUTHOR               	DATE           		DETAIL
*	1.0      Saurav Paul       		07/03/2022      	ECM-5275-Value Population in the new Fields_Account Report
*/
public without sharing class ECM_AccountTriggerPersonRespHelper {
    /*
    @Description: This methid is used to populated Sales Area and Territory of a Person Resp
	@Param : NewItems, OldItemMap
	*/
    public static void updateSalesAreaAndTerritory(List<SObject> newItems,Map<Id, SObject> oldItems){
        Map<Id,Account> oldAccMap;
        List<Account> newAccounts = (List<Account>)newItems;
        Set<Id> perRespIdSet = new Set<Id>();
        List<Account> accList = new List<Account>();
        Map<Id,Territory__c> terrMap = new Map<Id,Territory__c>();
        if(oldItems != null){
            oldAccMap = (Map<Id,Account>)oldItems;
        }
        for(Account accountRec: newAccounts){
            if((oldItems == null && accountRec.Person_Responsible__c != null)
               ||(oldItems != null && oldAccMap.containsKey(accountRec.Id) 
                  && oldAccMap.get(accountRec.Id).Person_Responsible__c!= accountRec.Person_Responsible__c)){
                perRespIdSet.add(accountRec.Person_Responsible__c);
                accList.add(accountRec);
            }
        }
        if(!perRespIdSet.isEmpty()){
            for(Territory__c terrObj : [SELECT Id,Primary_Sales_Rep__c, Name,Sales_Area__c  
                                        FROM Territory__c 

                                        WHERE RecordType.Name = 'Sales Territory'
                                        AND Primary_Sales_Rep__c IN : perRespIdSet]){

                
                terrMap.put(terrObj.Primary_Sales_Rep__c,terrObj);
            }
        }
        if(!accList.isEmpty()){
            for(Account accObj : accList){
                if(String.isNotBlank(accObj.Person_Responsible__c) && terrMap.containsKey(accObj.Person_Responsible__c)){
                    Territory__c terrObj = terrMap.get(accObj.Person_Responsible__c);
                    accObj.ECM_Person_Responsible_s_Sales_Territory__c = terrObj.Id;
                    accObj.ECM_Person_Responsible_s_Sales_Area__c = terrObj.Sales_Area__c;
                }else if(String.isBlank(accObj.Person_Responsible__c)){
                    accObj.ECM_Person_Responsible_s_Sales_Territory__c = null;
                    accObj.ECM_Person_Responsible_s_Sales_Area__c = null;
                }
            }
        }
    }
    
}