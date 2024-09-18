/**********************************************************************
Name: EDGE_AccountPromotionTriggerHelper
=======================================================================
Req: 
ES20-9225 - 
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0      Aparajita        01/02/2021      Initial Development

***********************************************************************/
public with sharing class EDGE_FieldPermissionSetTriggerHelper{
    /*******************************************************************
Method  : fetchFieldPermissionSets
Purpose : This methods used to validate that there's only one Field-Permission-Set record each for Type, Default-Outlet/Prospect
********************************************************************/ 
    
    public static void fetchFieldPermissionSets(List<Field_Permission_Set__c> newItems){ 
        
        set<Id> marketSetIds = new set<Id>();
        Map<String,Field_Permission_Set__c> fieldPermissionsetKey = new Map<String,Field_Permission_Set__c>();
        if(newItems != null){
            for(Field_Permission_Set__c fieldPermissionSet : newItems){
                marketSetIds.add(fieldPermissionSet.Market_Setting__c);
            }
        }
        
        if(marketSetIds != null && Schema.sObjectType.Field_Permission_Set__c.isAccessible()){
            for(Field_Permission_Set__c fieldPermissionRecd :[SELECT Type__c,Market_Setting__c,Market_Setting__r.Geography__c FROM Field_Permission_Set__c WHERE Market_Setting__c =: marketSetIds AND (Type__c='Default Outlet' OR Type__c='Default Prospect')]){
                string key = fieldPermissionRecd.Market_Setting__c +'_'+ fieldPermissionRecd.Type__c;
                fieldPermissionsetKey.put(key,fieldPermissionRecd);
                
            }
        }
        if(newItems != null){
            for(Field_Permission_Set__c newRecod : newItems){
                string key = newRecod.Market_Setting__c +'_'+ newRecod.Type__c;
                if(fieldPermissionsetKey.containsKey(key)){
                    newRecod.addError(System.Label.EDGE_FieldPermissionSetErrorMsg); 
                }
            }
        }
    }      
}