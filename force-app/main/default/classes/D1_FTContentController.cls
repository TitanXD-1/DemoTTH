/**
 * @name D1_FTContentController
 * @description  This is controller class for Flexible Template LWC Components
 * @history
 * VERSION          AUTHOR                          DATE            DETAIL
 * 1.0              Kapil Baliyan                   01/08/2022      Initial Development
 * 2.0              Kapil Baliyan                   11/11/2022      NCP-7440 
 */
public with sharing class D1_FTContentController {

    @TestVisible private static Id communityId = [
        SELECT Id
        FROM Network
        WHERE Name = 'DiageoOne'
        LIMIT 1
    ].Id;

    @AuraEnabled(cacheable=true)
    public static List<ConnectApi.ManagedContentVersion> getContentDetails(string contentKey, string language){
        try {
            //string communityId = Network.getNetworkId();
            List<String> contentKeys = new List<String>{contentKey};
            //getManagedContentByContentKeys(communityId, contentKeys, pageParam, pageSize, language, managedContentType, showAbsoluteUrl)
            ConnectApi.ManagedContentVersionCollection contentVersionCollection = ConnectApi.ManagedContent.getManagedContentByContentKeys(communityId, contentKeys, 0, 25, language, null, true);
            return contentVersionCollection.items;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static D1_User_Type__c getUserTypeInfo(){

        User userInfo = [SELECT D1_User_Type_Id__c FROM User WHERE id=: UserInfo.getUserId()];
        D1_User_Type__c d1UserType = [SELECT Id, User_Type__c FROM D1_User_Type__c WHERE Id =:userInfo.D1_User_Type_Id__c];
        return d1UserType;
    }

    @AuraEnabled(cacheable=true)
    public static List<ConnectApi.ManagedContentVersion> getContents(List<String> contentKeys, string language){
        try {
            if(contentKeys == null || contentKeys.size()==0){
                throw new AuraHandledException('ContentKeys are null');
            }
            ConnectApi.ManagedContentVersionCollection contentVersionCollection = ConnectApi.ManagedContent.getManagedContentByContentKeys(communityId, contentKeys, 0, 25, language, null, true);
            return contentVersionCollection.items;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}