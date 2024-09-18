/**********************************************************************
* @description EDGE_FieldPermissionTriggerHelper
* @history

VERSION  		AUTHOR             DATE              DETAIL
1.0        Monalisa Halder      27/07/2021       Initial Development(ES20-10866)
2.0         Joshraj Sen         21/02/2022       ES20-12118
***********************************************************************/
public with sharing class EDGE_FieldPermissionTriggerHelper{
    
    /**
    * @description updateParentDependentFields
    * @Purpose : This methods used to update Parent and Dependent Field on Field Permission Records
    */
 
    public static void updateParentDependentFields(List<Field_Permission__c> newItems){
        Map<String,Field_Permission__c> fieldPermissionRecordMap = new Map<String,Field_Permission__c>();
        Map<String,String> mapFieldParentField = new Map<String,String>();
        Map<String,String> mapFieldDependentField = new Map<String,String>();
        List<Field_Permission__c> fieldPermissionListToUpdate = new List<Field_Permission__c>();
        for(Field_Permission_Dependency__mdt fieldDependencySetting : [SELECT Id, MasterLabel,Field_Permission_Type__c , Object__c,Parent_Field__c, 
                                                                       Field__c, Dependent_Fields__c, Permission__c, Show_in_Custom_Screen__c       
                                                                       FROM Field_Permission_Dependency__mdt where Show_in_Custom_Screen__c  = true ORDER BY Field__c ASC]){
         
              if(fieldDependencySetting.Parent_Field__c != null){
                 mapFieldParentField.put(fieldDependencySetting.Field__c,fieldDependencySetting.Parent_Field__c);                                                              
              }
              if(fieldDependencySetting.Dependent_Fields__c != null){
                 mapFieldDependentField.put(fieldDependencySetting.Field__c,fieldDependencySetting.Dependent_Fields__c); 
              }                                                             
        
       }
        for(Field_Permission__c fPerRec :newItems){
            fieldPermissionRecordMap.put(fPerRec.Field__c,fPerRec);
        }
        
        for(String field :fieldPermissionRecordMap.keySet()){
            if(mapFieldParentField.containsKey(field) && !mapFieldDependentField.containsKey(field)){
               fieldPermissionRecordMap.get(field).Parent_Field_PL__c = mapFieldParentField.get(field);
            }
            if(!mapFieldParentField.containsKey(field) && mapFieldDependentField.containsKey(field)){
               fieldPermissionRecordMap.get(field).Dependent_Fields__c = mapFieldDependentField.get(field); 
            }
            if(mapFieldParentField.containsKey(field) && mapFieldDependentField.containsKey(field)){
               fieldPermissionRecordMap.get(field).Parent_Field_PL__c = mapFieldParentField.get(field);
               fieldPermissionRecordMap.get(field).Dependent_Fields__c = mapFieldDependentField.get(field); 
            }
        }
       
    }      
}