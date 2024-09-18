/**********************************************************************
Name: EDGE_TargetListMemberTriggerHelper
=======================================================================
Description : This is the Helper class for Target List Member Object
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0       Saurav Paul       8th-Mar-2019      Country Validation

***********************************************************************/

public with sharing class EDGE_TargetListMemberTriggerHelper {
    /************************************
    Name : validateCountry
    Description : This will validate country value
    *************************************/
    public static void validateCountry(Boolean isUpdate, List<SObject> newList, Map<Id,SObject> oldMap){
        //Variables
        Set<Id> outletIdSet = new Set<Id>();
        Set<Id> trgtLstIdSet = new Set<Id>();
        Map<Id,Target_List__c> trgtLstMap ;
        Map<Id,Account> accountMap;
        //Variables
        for(SObject sObj : newList){
            Target_List_Member__c trgtLstMemObj = (Target_List_Member__c)sObj;
            if(isUpdate && oldMap!= null && oldMap.containsKey(trgtLstMemObj.Id)){
                Target_List_Member__c oldTrgtLstMemObj = (Target_List_Member__c)oldMap.get(trgtLstMemObj.Id);
                if(oldTrgtLstMemObj.Outlet__c != trgtLstMemObj.Outlet__c && oldTrgtLstMemObj.Target_List__c != trgtLstMemObj.Target_List__c){
                    outletIdSet.add(trgtLstMemObj.Outlet__c);
                    trgtLstIdSet.add(trgtLstMemObj.Target_List__c);
                }
                
            }else if(!isUpdate && 
                     String.isNotBlank(trgtLstMemObj.Target_List__c)
                     && String.isNotBlank(trgtLstMemObj.Outlet__c)){
                outletIdSet.add(trgtLstMemObj.Outlet__c);
                trgtLstIdSet.add(trgtLstMemObj.Target_List__c);         
            }
        }
        if(!outletIdSet.isEmpty() && !trgtLstIdSet.isEmpty()){
            if(Schema.sObjectType.Account.isAccessible()){
                accountMap =  new Map<Id,Account>([SELECT Id,Country__c FROM Account WHERE Id IN : outletIdSet]);
            }
            if(Schema.sObjectType.Target_List__c.isAccessible()){
                trgtLstMap =  new Map<Id,Target_List__c>([SELECT Id,Country__c FROM Target_List__c WHERE Id IN : trgtLstIdSet]);
            }
        }
        for(SObject sObj : newList){
            Target_List_Member__c trgtLstMemObj = (Target_List_Member__c)sObj;
            if(trgtLstMap!= null && trgtLstMap.containsKey(trgtLstMemObj.Target_List__c)
              && accountMap != null && accountMap.containsKey(trgtLstMemObj.Outlet__c)){
               
                  if(accountMap.get(trgtLstMemObj.Outlet__c).Country__c != trgtLstMap.get(trgtLstMemObj.Target_List__c).Country__c){
                      trgtLstMemObj.addError(Label.Country_Mismatch_Issue_TargetList);
                  }
                
            }
        }
    }
    
}