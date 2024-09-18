/**
* @Name : GT_AssetTriggerHelper
* @Purpose: Helper for AssetTriggerHandler
* @Test Class: GT_AssetTriggerHelperTest
* 
* @History
* Version  Author          Date        Description
* 1.0      Wribhu Bose     08/08/2023  143681 :  Last TRAX Outbound data Updated Date field logic in Global Travel Asset
* 1.1      Tanishq Banerjee 04/09/2023  145245 :  Adding null check

*/
public with sharing class GT_AssetTriggerHelper {
    
    public static String gtAssetRecordTypeId = Asset.sObjectType.getDescribe().getRecordTypeInfosByName().get('Global Travel Asset').getRecordTypeId();
    
    /**
* @name: populateLastTRAXOutboundDate
     * @description : Populate Date and Time in the field 'Last TRAX Outbound Data Updated Date' after creation and updation of GT Asset record
     * @return : void
     * @param : List<SObject> and Map<Id, SObject>
     */ 
    public static void populateLastTRAXOutboundDate(List<SObject> newItems, Map<Id, SObject> oldItems){
        List<Asset> gtAstList = (List<Asset>)newItems;
        Map<Id, Asset> oldGTAstMap;
        if(oldItems!=null){
            oldGTAstMap = (Map<Id, Asset>) oldItems;
        }  
        List<FieldSetMember> fieldsToCheck = Schema.SObjectType.Asset.FieldSets.GT_TRAX_Update_Fields.getFields();
        if(!gtAstList.isEmpty()){
            for(Asset ast: gtAstList){ 
                if(fieldsToCheck!=null && !fieldsToCheck.isEmpty() && ast.RecordTypeId == gtAssetRecordTypeId){//145245
                    traxDateUpdate(ast,oldGTAstMap,fieldsToCheck); 
                }
            }
        }
        AssetTriggerHandler.isFirstTime = false;
    }   
    
   /**
* @name: traxDateUpdate
* @description : To update GT_Last_TRAX_Outbound_data_Updated_Date__c field
* @return : void
* @param : Asset ast and Map<Id, Asset> oldGTAstMap
*/   
    public static void traxDateUpdate(Asset ast, Map<Id, Asset> oldGTAstMap,List<FieldSetMember> fieldsToCheck){
        
        for(FieldSetMember member : fieldsToCheck) {
            String field = member.getFieldPath();
            if (oldGTAstMap == null || (oldGTAstMap !=null  && ast.get(field) != (oldGTAstMap.get(ast.Id).get(field)))) //145245
            {
                ast.GT_Last_TRAX_Outbound_data_Updated_Date__c = system.now();
                break;
            }  
        }  
        
    } 
}