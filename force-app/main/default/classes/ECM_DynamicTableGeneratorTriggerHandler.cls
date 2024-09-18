/*
 * Name: ECM_DynamicTableGeneratorTriggerHandler
 * Purpose: This class is used to generate logic for the DTG Trigger
 * 
 * History                                                            
VERSION    		AUTHOR              DATE              DETAIL
			   anivesh 	    	20/10/2021	          Consolidated the code for translation
 */ 
public with sharing class ECM_DynamicTableGeneratorTriggerHandler implements TriggerHandler{
    
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'ECM_DynamicTableTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){                
        return false;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
        for(SObject sobjRec : newItems){ 
            ECM_Dynamic_Table_Generator__c dnymicTableRec =(ECM_Dynamic_Table_Generator__c)sobjRec;
                if(dnymicTableRec.ECM_Dynamic_Fields__c!= null && dnymicTableRec.ECM_Dynamic_Fields__c.split(';').size()<=10){
                    string lisjoin='';
                    Map<String,String> fieldApiNames = ECM_DynamicTableGeneratorController.getFieldApiNames(dnymicTableRec.ECM_Object__c, dnymicTableRec.ECM_Dynamic_Fields__c.split(';'));
                    List<String> selectfields = ECM_DynamicTableGeneratorController.getPickListValuesIntoList(dnymicTableRec.ECM_Dynamic_Fields__c.split(';'));
                    system.debug('===='+fieldApiNames);
                    for(string field: selectfields){
                        if(fieldApiNames.containsKey(field)){
                            lisjoin+=string.isBlank(lisjoin)?fieldApiNames.get(field):','+fieldApiNames.get(field);                            
                        }
                    }
                   //string lisjoin // = String.join(ECM_DynamicTableGeneratorController.getFieldApiNames(dnymicTableRec.ECM_Object__c, dnymicTableRec.ECM_Dynamic_Fields__c.split(';')).values(),',');
                    system.debug('fields='+lisjoin);                        
                    dnymicTableRec.ECM_Field_API_Names__c = lisjoin;
                }else{
                    dnymicTableRec.addError('please check the multi picklist should not be more than 10 values.');
                }
            
        }  
    }
    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
         for(SObject sobjRec : newItems.values()){ 
            ECM_Dynamic_Table_Generator__c dnymicTableRec =(ECM_Dynamic_Table_Generator__c)sobjRec;
                if(dnymicTableRec.ECM_Dynamic_Fields__c!= null && dnymicTableRec.ECM_Dynamic_Fields__c.split(';').size()<=10){                   
                    string lisjoin ='';
                    List<String> selectfields = ECM_DynamicTableGeneratorController.getPickListValuesIntoList(dnymicTableRec.ECM_Dynamic_Fields__c.split(';'));
                    Map<String,String> fieldApiNames = ECM_DynamicTableGeneratorController.getFieldApiNames(dnymicTableRec.ECM_Object__c, dnymicTableRec.ECM_Dynamic_Fields__c.split(';'));
                    system.debug('===='+fieldApiNames);
                    for(string field: selectfields){
                        if(fieldApiNames.containsKey(field)){
                            lisjoin+=string.isBlank(lisjoin)?fieldApiNames.get(field):','+fieldApiNames.get(field);
                        }
                    }
                    system.debug('fields===-'+lisjoin);
                    dnymicTableRec.ECM_Field_API_Names__c = lisjoin;
                }else{
                    dnymicTableRec.addError('please check the multi picklist should not be more than 10 values.');
                }
            
        }  
    }
    
    //Before Delete Trigger Handler   
    public void beforeDelete(Map<Id, SObject> oldItems) {
        
    }   
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
        
         ECM_DynamicTableGenTriggerHelper.checkAndGenerateSharing(newItems.values());
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
         ECM_DynamicTableGenTriggerHelper.validateAndReGenerateSharing(newItems.values(), oldItems); 
        
    }
    
    //After Delete Trigger Handler
    
    public void afterDelete(Map<Id, SObject> oldItems) {
        
    }  
    
    //After Undelete Trigger Handler    
    public void afterUndelete(Map<Id, SObject> oldItems) {
        
        
    }
    
}