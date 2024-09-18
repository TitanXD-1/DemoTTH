/**
* @Name: EDGE_SearchFieldController

* @Purpose: Controller class of EDGE_SearchFieldCmp 

* @History                                                            
                                                           
* @VERSION      AUTHOR            DATE              DETAIL
*    1.0    Preyanka Ghosh     19/02/2019      Initial Development
*	 2.0    Rajarshi Lahiri	   10/02/2023		ES20-13786
*	 3.0	Mayukh S Roy	   21/03/2023		ES20-13895
**/
public with sharing class EDGE_SearchFieldController {
    
    private static string keyFieldApiName = 'field_name';
    private static string keyFieldLabel = 'field_label';
    private static string keyFieldType = 'field_type';
    private static string keyFieldValues = 'field_values';
    private static string keyFieldReferenceTo = 'field_reference';
    
    /**
	* @Purpose: To get the schema details of all the fields related to provided object                                                          
	**/
    @AuraEnabled
    public static Map<String, Map<String, Object>> getFieldDetails(String objectName, Boolean checkPrimary){
        Map<String, Map<String, Object>> lstFieldDetails = new Map<String, Map<String,Object>>();
        Map<String, Map<String, Object>> mapSortFieldDetails = new Map<String, Map<String,Object>>();
        Map<String, String> mapFieldLabel = new Map<String, String>();
        /**  change for 8282 **/
        Map<String, Schema.SObjectField> objFieldMap = new Map<String, Schema.SObjectField>();
        //ES20-13786
        List<String> excludeFieldsForFilter=Label.EDGE_ExcludeFieldsForFilter.split(';');
        List<String> excludeDataTypesForFilter = Label.EDGE_RestrictDataType.split(';');
        try{
            if(String.isNotBlank(objectName)){
                Schema.sObjectType objType = Schema.getGlobalDescribe().get(objectName);
                /** start change for 8282 **/
                if(objectName == 'User'){
                    Map<String, Schema.SObjectField> objFullFieldMap = objType.getDescribe().fields.getMap();
                    String userSearchFields = Label.EDGE_User_Search_Fields;
                    List<String> userSearchFieldsList = userSearchFields.split(';');
                    for(String s : objFullFieldMap.keySet()){
                        if(userSearchFieldsList.contains(s)){
                        objFieldMap.put(s,objFullFieldMap.get(s));
                        }
                    }
                    
                }else{
                	 objFieldMap = objType.getDescribe().fields.getMap();
                    
                }
                System.debug(LoggingLevel.Debug,'objFieldMap'+objFieldMap);
                
                /** end change for 8282 **/
                
                
                if(objFieldMap != null && objFieldMap.size()>0){
                    for(String fieldName : objFieldMap.keySet()){
                        Map<String, Object> mapFieldDetails = new Map<String, Object>();
                        DescribeFieldResult fieldDescription = objFieldMap.get(fieldName).getDescribe();
                        String fieldType = String.valueOf(fieldDescription.getType());
                        //ES20-13786- To exclude Country_ISO_Code__c for Country Code Label and pickup Country_Code__c instead
                        if(!excludeFieldsForFilter.contains(fieldDescription.getName()) && !excludeDataTypesForFilter.contains(fieldType)){ //Added DataType check to avoid query exception //ES20-13895
                        	mapFieldLabel.put(fieldDescription.getLabel(),fieldDescription.getName());
                        }
                        
                        //To include the lookup field for first time and from second time onwards no need to include as depth is 2 in UI
                        if(fieldType == 'REFERENCE'){
                            if(checkPrimary == true){
                                List<Schema.sObjectType> reference = fieldDescription.getReferenceTo();
                                //Create Field Detail Map
                                mapFieldDetails.put(keyFieldApiName, fieldDescription.getName());
                                mapFieldDetails.put(keyFieldLabel, fieldDescription.getLabel());
                                mapFieldDetails.put(keyFieldType, fieldType);
                                mapFieldDetails.put(keyFieldReferenceTo, String.valueOf(reference[0]));
                                lstFieldDetails.put(fieldDescription.getName(), mapFieldDetails);
                            }
                        }else{
                            //Create Field Detail Map
                            mapFieldDetails.put(keyFieldApiName, fieldDescription.getName());
                            mapFieldDetails.put(keyFieldLabel, fieldDescription.getLabel());
                            mapFieldDetails.put(keyFieldType, fieldType);
                            system.debug(LoggingLevel.DEBUG,'@@mapFieldDetails' +mapFieldDetails);
                            
                            //If the fieldtype is picklist then need to include the List of values for that field
                            if(fieldType == 'PICKLIST'){
                                List<Schema.PicklistEntry> pickVal = fieldDescription.getPicklistValues();
                                if(pickVal != null){
                                    List<Map<String,String>> picklistEntries = new List<Map<String,String>>();
                                    for( Schema.PicklistEntry pickValues : pickVal){
                                        Map<String, String> picklistEntry = new Map<String, String>();
                                        picklistEntry.put(keyFieldLabel,pickValues.getLabel());
                                        picklistEntry.put(keyFieldApiName, pickValues.getValue());
                                        picklistEntries.add(picklistEntry);
                                    }
                                    mapFieldDetails.put(keyFieldValues, picklistEntries);
                                }
                            }else if(fieldType == 'BOOLEAN'){
                                List<Map<String,String>> picklistEntries = new List<Map<String,String>>();
                                Map<String, String> truePicklistEntry = new Map<String, String>();
                                truePicklistEntry.put(keyFieldLabel, 'TRUE');
                                truePicklistEntry.put(keyFieldApiName, 'true');
                                picklistEntries.add(truePicklistEntry);
                                
                                Map<String, String> falsePicklistEntry = new Map<String, String>();
                                falsePicklistEntry.put(keyFieldLabel, 'FALSE');
                                falsePicklistEntry.put(keyFieldApiName, 'false');
                                picklistEntries.add(falsePicklistEntry);
                                
                                mapFieldDetails.put(keyFieldValues, picklistEntries);
                            }
                            
                            lstFieldDetails.put(fieldDescription.getName(), mapFieldDetails);
                        }
                    }
                    
                    //Sort by Map keySet
                    List<String> lstSortFieldDetail = new List<String>();
                    lstSortFieldDetail.addAll(mapFieldLabel.keySet());
                    lstSortFieldDetail.sort();
                    
                    for(String key : lstSortFieldDetail){
                        mapSortFieldDetails.put(mapFieldLabel.get(key), lstFieldDetails.get(mapFieldLabel.get(key)));                                                
                    }
                }
            }             
        }catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
        
        return mapSortFieldDetails;
    }
}