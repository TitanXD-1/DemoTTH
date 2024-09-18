public with sharing class LookupController {
    /* Method to query records using SOSL*/
    @AuraEnabled
    public static String search(
        String objectAPIName,
        String searchText,
        List<String> whereClause,
        List<String> extrafields,
        Integer lim,
        List<String> selectedIds,
        String sOSLSearch
    ) {
        String searchQuery = '';
        try {
            objectAPIName = String.escapeSingleQuotes(objectAPIName);
            searchText = String.escapeSingleQuotes(searchText);

            Set<String> filedsToSearchInSet = new Set<String>();
            filedsToSearchInSet.add('Id');
            filedsToSearchInSet.add('Name');
            if (extrafields != null && !extrafields.isEmpty()) {
                for (String additionalFieldToUseInSearch : extrafields) {
                    filedsToSearchInSet.add(additionalFieldToUseInSearch);
                }
            }

            String searchFieldsString = '(' + String.join(new List<String>(filedsToSearchInSet), ',');
            searchQuery = 'FIND \'' + searchText + '*\' IN ' + sOSLSearch + ' FIELDS RETURNING ' + objectAPIName + searchFieldsString.removeEnd(',');
            System.debug('searchQuery' + searchQuery);

            system.debug(whereClause);
            if (!whereClause.isEmpty() || !selectedIds.isEmpty()) {
                searchQuery = searchQuery + ' WHERE ' ;
            }
            if (!selectedIds.isEmpty()) {
                searchQuery = searchQuery + 'id NOT IN :selectedIds';
            }
            if (!whereClause.isEmpty() && !selectedIds.isEmpty()) {
                searchQuery = searchQuery + ' AND ' ;
            }
            if (!whereClause.isEmpty()) {
                searchQuery = searchQuery + String.join(whereClause, 'AND') ;
            }
            searchQuery = searchQuery + ' LIMIT ' + lim + ' ) ';
            system.debug(searchQuery);
            return JSON.serializePretty(search.query(searchQuery)) ;
        } catch (Exception ex) {
            throw new AuraHandledException('Search exception ' + ex.getMessage() + ' query =>' + searchQuery);

        }
    }
    
    @AuraEnabled
    public static String fetchObjectLabel(String objectAPIName){
        return Schema.getGlobalDescribe().get(objectAPIName).getDescribe().getLabel();
    }
    
    @AuraEnabled
    public static List<RecentlyViewed> fetchRecentlyViewedRecords(String objectAPIName){
        List<RecentlyViewed> recentlyViewedRecords = new List<RecentlyViewed>();
        if(Schema.SObjectType.RecentlyViewed.isAccessible()){
        					  recentlyViewedRecords = [SELECT Id, Name
                                                      FROM RecentlyViewed 
                                                      WHERE Type = :objectAPIName
                                                      ORDER BY LastViewedDate DESC LIMIT 2];
        }
        return recentlyViewedRecords.size() > 0 ? recentlyViewedRecords : null;
    }
}