public class E7C_SurveyIntroController {
    
    @AuraEnabled
    public static void deletePhotoApex(Id documentId){
        try{
            delete [SELECT Id FROM ContentDocument WHERE Id=:documentId];
        }catch(Exception e){
            System.debug('Exception>>>'+e.getStackTraceString());            
        }
    }
    
    @AuraEnabled
    public static Map<String, Id> getSurveyResId(String location){
        try{
            Map<String, Id> resultMap = new Map<String, Id>();
            System.debug('UserInfo>>>'+UserInfo.getUserId());
            Id srId = E7C_Utility.getSurveyId(location);
            Id surResId = E7C_Utility.getSurveyResponseId(srId);
            resultMap.put('surResId',surResId);
            ContentDocumentLink[] cdls = [SELECT ContentDocumentId, LinkedEntityId 
                                          FROM ContentDocumentLink WHERE LinkedEntityId = :surResId];
            if(cdls.size() > 0){
                resultMap.put('condocId',cdls[0].ContentDocumentId);
            }
            return resultMap;
        }catch(Exception e){
            System.debug('Exception>>>'+e.getStackTraceString());
            return null;
        }
    }
    
    @AuraEnabled
    public static void updateConVersion(String documentId, String pintType){
        try{
            contentVersion conVer = [SELECT E7C_Pint_Type__c FROM ContentVersion 
                                     WHERE ContentDocumentId = :documentId AND IsLatest = true];
            conVer.E7C_Pint_Type__c = pintType;
            System.debug('conVer>>>'+conVer);
            update conVer;
        }catch(Exception e){
            System.debug('Exception>>>'+e.getStackTraceString());            
        }
    }
}