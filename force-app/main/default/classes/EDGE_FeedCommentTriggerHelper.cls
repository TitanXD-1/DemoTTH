/*
 * Class Name : EDGE_FeedCommentTriggerHelper
 * @description: User Story : ES20-9704
 * @history
 * VERSION    AUTHOR                DATE              DETAIL
    1.0 -    Amar Deep 	       10/02/2021      Initial Development  
    2.0     Swagat Shaw       10/03/2023      CUS-115    
*/

public class EDGE_FeedCommentTriggerHelper {
  
//Purpose: for sending the Mobile Push notifications  sent to a specific user 

   public static void sendPushNotificationForComment(Map<Id, SObject> newItems){
        
        Map<Id,FeedComment> newRecordMap = (Map<Id,FeedComment>)newItems;
        Map<String, Object> custom = new Map<String, Object>();
        String accountPrefix = Account.sObjectType.getDescribe().getKeyPrefix();
        
        if(newRecordMap!=null){
            for(FeedComment newFeedRec : newRecordMap.values()){
                String parentId = newFeedRec.parentId;
                if(parentId.startsWith(accountPrefix)){
                    List<Account> accountList = [SELECT Id,Name from Account where Id =: newFeedRec.ParentId];
                    List<User> userList = [SELECT Id,Name from User where Id =: newFeedRec.CreatedById];
                    if(accountList != null && accountList.size()>0 && userList != null && userList.size()>0){
                        string chatter = userList[0].Name + ' ' + System.label.Edge_user_mention_outlet + ' ' + accountList[0].Name;
                        System.debug(chatter);
                        string chatterBody = chatter.replaceAll('<[^>]+>','');
                        system.debug('Replace::'+chatterBody.replaceAll('<[^>]+>',''));
                        
                        custom.put('OutletId',newFeedRec.ParentId);
                        custom.put('OutletName',accountList[0].Name);
                        custom.put('CommentId',newFeedRec.Id);
                        custom.put('ChatterId',newFeedRec.FeedItemId);
                        system.debug('custom::'+custom);
                        
                        String communityId = null;
                        String feedCommentId = newFeedRec.Id;
                        String targetUserId = '';
                        if(!Test.isRunningTest()){
                            ConnectApi.Comment  cmmnt = ConnectApi.ChatterFeeds.getComment(communityId, feedCommentId);
                            if(cmmnt != null && cmmnt.body != null){
                                List<ConnectApi.MessageSegment> messageSegments =  cmmnt.body.messageSegments;
                                EDGE_PushNotificationHelper.pushNotificationMethod(messageSegments, chatterBody, custom);
                            }
                        }
                    }
                }
            }
        }
    }
    
    /*CUS-115
* @description : Cannot reply on comment when case is closed.
* @return : void
* @param : List
*/   
    public static void preventCommentOnFeedCaseClosed(List<FeedComment> newItems){
        String curUserProfile = [Select name from Profile where Id = :UserInfo.getProfileId() LIMIT 1].Name;
        Map<String, FeedComment> toCheck = new Map<String, FeedComment>();
        List<String> countryCodes=Label.C360_Ireland_Country_Codes.split(';');
        for(FeedComment fc : newItems){
            if(fc.ParentId != null && 
               (fc.ParentId.getSObjectType() == Case.sObjectType)           
              ){
                  toCheck.put(fc.ParentId, fc);
              }
        }
        if(featuremanagement.checkpermission('C360_Logistics_rep') || featuremanagement.checkpermission('C360_Service_Team') || featuremanagement.checkpermission('C360_Credit_Team_Leader') ||
           curUserProfile == 'Sales Representative' || curUserProfile == 'Quality Representative' ){
               for(Case c : [SELECT Id, C360_Record_Type_Name__c, Account.Country_Code__c FROM Case WHERE Id in :toCheck.keySet() 
                             AND C360_Record_Type_Name__c = 'Diageo One Cases' AND Account.Country_Code__c in :countryCodes AND Status = 'Closed'])
               {
                   if(toCheck.containsKey(c.Id)){
                       toCheck.get(c.Id).addError(Label.Case_Comment_Error_Message);
                   }
               }
           }
    }
    
}