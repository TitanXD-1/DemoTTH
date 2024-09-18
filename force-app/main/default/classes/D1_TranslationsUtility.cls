/**********************************************************************
Name: D1_TranslationsUtility

=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR            DATE            DETAIL
1.0         Gaurav Singh      11/03/2022      Class for Translation utility
***********************************************************************/
public class D1_TranslationsUtility {
    public static Map<String,List<D1_Translations_Field_Mapping__mdt>> objectTypeTranslationMapping = new Map<String,List<D1_Translations_Field_Mapping__mdt>>();
    
    public static List<sObject> updateTranslationsInRecords(List<sObject> recordsToTranslate){
        if( recordsToTranslate != NULL && !recordsToTranslate.isEmpty() ){
            Schema.SObjectType objectType = recordsToTranslate[0].getSObjectType();
            
            List<D1_Translations_Field_Mapping__mdt> translationMappings = getTranslationsMappings(objectType);
            Map<Id,D1_Translations__c> translations = queryTranslations(recordsToTranslate, translationMappings);
            
            for( sObject objectRec : recordsToTranslate){
                Id recordId = (Id)objectRec.get('Id');
                
                if( translations.containsKey(recordId) ){
                    D1_Translations__c translation = translations.get(recordId);
                    for( D1_Translations_Field_Mapping__mdt translationMapping : translationMappings ){
                        String translatedValue = (String)translation.get(translationMapping.Translation_Field__c);
                        String fieldToTranslate = translationMapping.sObject_Field_To_Translate__r.QualifiedApiName;
                        
                        if( String.isNotBlank(translatedValue) ){
                            objectRec.put(fieldToTranslate, translatedValue);
                        }
                    }
                }
            }
        }
        
        return recordsToTranslate;
    }
    
    public static List<D1_Translations_Field_Mapping__mdt> getTranslationsMappings( Schema.SObjectType objectType ){
        List<D1_Translations_Field_Mapping__mdt> translationMappings = new List<D1_Translations_Field_Mapping__mdt>();
        
        if( !objectTypeTranslationMapping.containsKey(objectType.getDescribe().getName()) ){
            translationMappings = [Select id, sObject_To_Translate__r.QualifiedApiName, sObject_Field_To_Translate__r.QualifiedApiName, 
                                  Translation_Parent_Relation_Field__c, Translation_Field__c   
                                  from D1_Translations_Field_Mapping__mdt 
                                  where sObject_To_Translate__r.QualifiedApiName = :objectType.getDescribe().getName()];
                                  objectTypeTranslationMapping.put(objectType.getDescribe().getName(), translationMappings);
        }else{
            translationMappings = objectTypeTranslationMapping.get(objectType.getDescribe().getName());
        }
        
        return translationMappings;
    }
    
    public static Map<Id,D1_Translations__c> queryTranslations( List<sObject> recordsToTranslate, List<D1_Translations_Field_Mapping__mdt> translationMappings ){
        String fields = 'Id,';
        String parentRelationField;
        for( D1_Translations_Field_Mapping__mdt translationMapping : translationMappings ){
            fields += translationMapping.Translation_Field__c+',';
            parentRelationField = translationMapping.Translation_Parent_Relation_Field__c;
        }
        fields = fields+parentRelationField;
        
        List<Id> parentIds = new List<Id>();
        for( sObject objectRec : recordsToTranslate){
            parentIds.add( (Id)objectRec.get('Id') );
        }
        
        String query = 'Select '+fields+' from D1_Translations__c where '+parentRelationField+' IN :parentIds and Language__c = \''+UserInfo.getLanguage()+'\''; 
        
        Map<Id,D1_Translations__c> translationsMap = new Map<Id,D1_Translations__c>();
        List<D1_Translations__c> translations = (List<D1_Translations__c>)Database.query(query);
        if( translations != NULL ){
            for( D1_Translations__c translation : (List<D1_Translations__c>)Database.query(query) ){
                translationsMap.put( (Id)translation.get(parentRelationField), translation);
            }
        }
        
        return translationsMap;
    }
}