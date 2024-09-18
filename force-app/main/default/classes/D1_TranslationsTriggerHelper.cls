/**
 * @name: D1_TranslationsTriggerHelper
 * @description: Trigger Helper Class for D1_TranslationsTrigger
 * @history
 * VERSION      AUTHOR              DATE            DETAIL
 * 1.0          Gaurav Singh      18/04/2022        Initial Development
 **/
public class D1_TranslationsTriggerHelper {
	/**
    * @method : validateTranslationLanguage
    * @purpose : validate translation language on D1_Translations
    */
    public static void validatePreferredLanguage(List<sObject> newItems){
        List<D1_Translations__c> listNewData;
        if(newItems != null){
            listNewData = (List<D1_Translations__c>) newItems;
        }
        
        Map<String,Map<String,Set<Id>>> parentIdLangRecIdMap = new Map<String,Map<String,Set<Id>>>();
        Set<String> parentIds = new Set<String>();
        Set<Id> recordIds = new Set<Id>();
        for( D1_Translations__c translation : listNewData ){
            String parentId = translation.ParentId__c;
            
            if( parentId != NULL ){
                parentIds.add(translation.ParentId__c);
                if( translation.Id != NULL) { //US 150154:PMD Fix
                    recordIds.add(translation.Id);
                }
            }
        }
        
        List<D1_Translations__c> existingTranslations = [Select id, Language__c, ParentId__c from D1_Translations__c where ParentId__c IN :parentIds and Id NOT IN :recordIds];
        for( D1_Translations__c translation : existingTranslations ){
            String parentId = translation.ParentId__c;
            
            if( !parentIdLangRecIdMap.containsKey(parentId) ){
                parentIdLangRecIdMap.put(parentId, new Map<String,Set<Id>>());
            }
            
            if( !parentIdLangRecIdMap.get(parentId).containsKey(translation.Language__c) ){
                parentIdLangRecIdMap.get(parentId).put(translation.Language__c, new Set<Id>());
            }
            
            parentIdLangRecIdMap.get(parentId).get(translation.Language__c).add(translation.Id);
        }
        
        for( D1_Translations__c translation : listNewData ){
            String parentId = translation.ParentId__c;
            if( parentId != NULL ){
                if( parentIdLangRecIdMap.containsKey(parentId) 
                   && parentIdLangRecIdMap.get(parentId).containsKey(translation.Language__c)
                  ){
                    translation.addError(Label.D1_TranslationsDuplicateError);
                }
                
                if( !parentIdLangRecIdMap.containsKey(parentId) ){
                    parentIdLangRecIdMap.put(parentId, new Map<String,Set<Id>>());
                }
                
                if( !parentIdLangRecIdMap.get(parentId).containsKey(translation.Language__c) ){
                    parentIdLangRecIdMap.get(parentId).put(translation.Language__c, new Set<Id>());
                }
                
                parentIdLangRecIdMap.get(parentId).get(translation.Language__c).add(translation.Id);
            }
        }
    }
    
    
}