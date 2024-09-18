public with sharing class PNR_AutocompleteController {
   
    @AuraEnabled(cacheable=true)
    public static List<SObject> getRecords(String searchString, String objectApiName, String idFieldApiName, String valueFieldApiName, String extendedWhereClause, Integer maxRecords){
        /*searchString = String.escapeSingleQuotes(searchString);
        objectApiName = String.escapeSingleQuotes(objectApiName);
        idFieldApiName = String.escapeSingleQuotes(idFieldApiName);
        valueFieldApiName = String.escapeSingleQuotes(valueFieldApiName);
        
        if(extendedWhereClause == null){
            extendedWhereClause = '';
        }
        
        String query = 'SELECT '+idFieldApiName+', '+valueFieldApiName+' FROM '+objectApiName+' WHERE '+valueFieldApiName+' LIKE \'%'+searchString+'%\' '+extendedWhereClause+' LIMIT '+maxRecords;
        System.debug(query);
        String query = 'SELECT '+idFieldApiName+', '+valueFieldApiName+' FROM '+objectApiName;*/
        
        return null;
        
    
}

}