/**
* @description EDGE_CaseCommentTriggerHelper
* @purpose WHEN a case comment has been added to a case,then this case comment needs to be converted to a chatter comment.
User Story : ES20-9663
* @history :
Version  			Developer           Date               Purpose
* 1.0 				Juned khan		  19/03/2021        Initial Development
* 2.0				Kapil Baliyan	  05/05/2021		NCP-3064
* 3.0				Prasanth T		  02/08/2021		ES20-9673 (To send Sys id and Case to SNOW)
* 4.0               Kapil Baliyan       13/10/2021          NCP-5029
*/

public with sharing class EDGE_CaseCommentTriggerHelper {
    
     public static List<CaseComment> caseCommentList = new List<CaseComment>();
     
    /**
* @description : createChatterFeeds- The below method checks if there is any case comment created for any case
			 then chatter comment will get created.
* @return : void
* @param : Map<Id,SObject>
*/
    public static void createChatterFeeds(Map<Id,SObject> newItems){
        String userProfileLabel = System.Label.EDGE_Integration_User;
        List<String> userProfiles = new List<String>();
        Map<Id, CaseComment> caseCommentRecords = (Map<Id, caseComment>)newItems;
        List<FeedItem> caseFeedItemList= new List<FeedItem>();
        String casePrefix = Case.sObjectType.getDescribe().getKeyPrefix();
        String currUserProfileName =  EDGE_CaseFeedtoCaseCommentTriggerHelper.getCurrentUserProfileName(userInfo.getProfileId());
        Pattern MyPattern = Pattern.compile(currUserProfileName);
        String allEligibleProfilesStr = '';
        String allEligibleCaseStatusStr = '';
        String caseStatus = System.label.EDGE_Case_Status; 
        List<String> listOfStatus = new List<String>();
        Set<Id> parentCaseIds = new Set<Id>();
        Map<Id,Case> caseIdToCaseMap = new Map<Id,Case>();
        Id d1RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Diageo_One_Cases').getRecordTypeId(); //NCP-3064
        
        for(CaseComment caseComment: caseCommentRecords.values()){
            parentCaseIds.add(caseComment.ParentId);
        }
        
        if(userProfileLabel != null){
            List<String> userProfilesList = userProfileLabel.split(',');
            allEligibleProfilesStr = String.join(userProfilesList, '|');
        }
        
        if(caseStatus != null){
            listOfStatus = caseStatus.split(';');
            allEligibleCaseStatusStr = String.join(listOfStatus, '|');
        }
        
        if(Schema.sObjectType.Case.isAccessible() && !parentCaseIds.isEmpty()){
            //NCP-3064
            for(Case caseRec : [Select Id, RecordTypeId, RecordType.Name,Status,CreatedDate from Case where 
                                (RecordType.Name=: Label.EDGE_Technical_Issue OR RecordTypeId = :d1RecordTypeId) 
                                and Status IN : listOfStatus and Id in :parentCaseIds])
            {
                caseIdToCaseMap.put(caseRec.Id,caseRec);   
            }
        }
        
        if(Schema.sObjectType.CaseComment.isAccessible()){
            for(CaseComment caseComment :caseCommentRecords.values()){ 
                if(caseIdToCaseMap.keySet().contains(caseComment.ParentId)){
                    Case parentCase = caseIdToCaseMap.get(caseComment.ParentId);
                    Pattern caseStatusPattern = Pattern.compile(parentCase.status);
                    String caseFeedParentIdStr = (String)caseComment.ParentId;
                    
                    if(caseFeedParentIdStr.startsWith(casePrefix) && MyPattern.matcher(allEligibleProfilesStr).find()
                       && caseStatusPattern.matcher(allEligibleCaseStatusStr).find()
                       && (parentCase.Recordtype.Name == Label.EDGE_Technical_Issue || parentCase.RecordTypeId == d1RecordTypeId))
                    {  
                        String commentBody = (String)caseComment.CommentBody;
                        if( String.isNotBlank(commentBody) && commentBody.containsIgnoreCase('(Additional comments)') ){
                            commentBody = commentBody.substringAfter('(Additional comments)').trim();
                        }

                        FeedItem feedItemRec = new FeedItem();
                        feedItemRec.ParentId = (Id)caseComment.ParentId; 
                        feedItemRec.Body = commentBody;
                        feedItemRec.Type = 'TextPost';
                        feedItemRec.Visibility = 'AllUsers'; //NCP-5029
                        caseFeedItemList.add(feedItemRec);
                    }
                }  
            }
        }
        if(Schema.sObjectType.FeedItem.isCreateable() && caseFeedItemList.size() > 0){
            Database.insert(caseFeedItemList);
        }   
    }

    /**
* @description : createCaseCommentSnowTicket - created to send Sys id from Case object and Comment from CaseComment to SNOW(ES20-9673)
* @return : void
* @param : Map<Id,SObject>
*/

    public static void createCaseCommentSnowTicket(Map<Id,SObject> newItems){
        String userProfile = [Select id, Profile.Name from User where id = :UserInfo.getUserId()].Profile.Name;
        if( userProfile != 'Integration User Profile' ){
            Map<Id, CaseComment> caseCommentRecords = (Map<Id, caseComment>)newItems;
            Set<Id> parentCaseIds = new Set<Id>();
            Map<Id,List<String>> caseCommentMap = new Map<Id,List<String>>();
            
            //Extraction of ParentIds(ID of case) from CaseComment Object 
            if(caseCommentRecords != null && caseCommentRecords.size()>0){
                for(CaseComment idCaseComments: caseCommentRecords.values()){
                    parentCaseIds.add(idCaseComments.ParentId);
                } 
            }
            
            //Extraction of Sys_Id__c for the ParentIds(Case Id) with Technical Issue Record Type
            if(Schema.sObjectType.Case.isAccessible() && !parentCaseIds.isEmpty()){
                for(Case caseRec : [SELECT Id,RecordType.Name,Status,CreatedDate,Sys_id__c FROM Case WHERE 
                                    RecordType.Name= :Label.EDGE_Technical_Issue and Id in :parentCaseIds])
                {
                    caseCommentMap.put(caseRec.Id,new List<String> {caseRec.Sys_id__c});
                }
            }
            //Creation of Map to send it to SNOW with ParentID(Case ID) as key and SysId and Comment as List of Values
            if(caseCommentMap != null && caseCommentMap.size()>0){
                for(CaseComment commentCaseId : caseCommentRecords.values()){                    
                    if(caseCommentMap.keySet().contains(commentCaseId.ParentId)){
                        if(caseCommentMap.get(commentCaseId.ParentId) != null && commentCaseId.CommentBody != null){
                            String commentBody = (String)(commentCaseId.CommentBody).StripHtmlTags();
                            caseCommentMap.get(commentCaseId.ParentId).add(commentBody);

                            System.enqueueJob(new EDGE_CaseCommentIntegrationWithSNOW(caseCommentMap,null,false));
                        }
                    }
                }
            }
        }
    }
}