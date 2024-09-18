/**
* @description EDGE_CaseFeedtoCaseCommentTriggerHelper
* @purpose Trigger Handler Class for FeedItemTrigger
* @history 
* Version      Developer            Date           User Story/Purpose	     
* 1.0          Sandip Ghosh 	   30/03/2021      Initial Development(ES20-9661)


* 2.0          Kapil Baliyan       05/05/2021      NCP-3064



*/

public without sharing class EDGE_CaseFeedtoCaseCommentTriggerHelper {
    
    public static List<FeedItem> feedItemList = new List<FeedItem>();
        //Creation of case comment from case chatter comment 
    //case feed--> case comment
    public static void convertCaseFeedtoComments(Map<Id,SObject> newItems){
     
        String userProfileLabel = System.Label.EDGE_userProfiles;
        Map<Id, FeedItem> feedItemRecords = (Map<Id, FeedItem>)newItems;
        List<CaseComment> caseCommentList= new  List<CaseComment>();
        String casePrefix = Case.sObjectType.getDescribe().getKeyPrefix();
        String currUserProfileName =  getCurrentUserProfileName(userInfo.getProfileId());
        Pattern MyPattern = Pattern.compile(currUserProfileName);
        String allEligibleProfilesStr = '';
        String allEligibleCaseStatusStr = '';
        Set<Id> parentCaseIds = new Set<Id>();
        Map<Id,Case> caseIdToCaseMap = new Map<Id,Case>();
        String caseStatus = System.label.EDGE_Case_Status;
        String FeedItemType = System.label.EDGE_Feed_Item_Type;
        List<String> listOfStatus = new List<String>();
        List<String> FeedItemTypeList = new List<String>();

        Id d1RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Diageo_One_Cases').getRecordTypeId(); //NCP-3064        

        if(caseStatus != null && FeedItemType != null){
            listOfStatus = caseStatus.split(';');
            allEligibleCaseStatusStr = String.join(listOfStatus, '|');
            FeedItemTypeList = FeedItemType.split(';');


        }
        
        for(FeedItem feedItemRec: feedItemRecords.values()){
            parentCaseIds.add(feedItemRec.ParentId);
        }
        
        if(Schema.sObjectType.Case.isAccessible() && !parentCaseIds.isEmpty()){


            for(Case caseRec : [Select Id,RecordTypeId,RecordType.Name,Status,CreatedDate,Type  from Case where 
                (RecordType.Name =:Label.EDGE_Technical_Issue OR RecordTypeId = :d1RecordTypeId)
                                and Status IN : listOfStatus and Id in :parentCaseIds]){


                caseIdToCaseMap.put(caseRec.Id,caseRec);   
            }
        }

        if(userProfileLabel != null){
            List<String> userProfilesList = userProfileLabel.split(',');
            allEligibleProfilesStr = String.join(userProfilesList, '|');
        }
              
        if(Schema.sObjectType.FeedItem.isAccessible()){
            for(FeedItem feedItemRec :feedItemRecords.values())
            {
                system.debug('attachment'+feedItemRec.Type);
                if(caseIdToCaseMap.keySet().contains(feedItemRec.ParentId)){
                    
                    Case parentCase = caseIdToCaseMap.get(feedItemRec.ParentId);
                    Pattern caseStatusPattern = Pattern.compile(parentCase.status);
                    String caseFeedParentIdStr = (String)feedItemRec.ParentId;

                    if(caseFeedParentIdStr.startsWith(casePrefix) && MyPattern.matcher(allEligibleProfilesStr).find()
                       && (feedItemRec.Type == 'TextPost' || feedItemRec.Type == 'LinkPost') && FeedItemTypeList != null && FeedItemTypeList.contains(feedItemRec.Type)&& caseStatusPattern.matcher(allEligibleCaseStatusStr).find()
                       && (parentCase.Recordtype.Name == Label.EDGE_Technical_Issue || (parentCase.RecordtypeId == d1RecordTypeId && 'Quality & Equipment Issues'.equalsIgnoreCase(parentCase.Type)))) //NCP-3064

                    {  
                        CaseComment casecmt = new CaseComment();
                        casecmt.ParentId = (Id)feedItemRec.ParentId;

                        casecmt.CommentBody =  ((String)feedItemRec.Body).stripHtmlTags();//(String)(feedItemRec.Body).StripHtmlTags();
                        casecmt.IsPublished = true; //NCP-3064


                        caseCommentList.add(casecmt);
                    }
                }
            }
        }
        if(Schema.sObjectType.CaseComment.isCreateable() && caseCommentList.size() > 0){
            Database.insert(caseCommentList);
        }
        
    }
    
    public static String getCurrentUserProfileName(String profileUserId){
        String currentUserProfileName = 'Partner Network Profile'; //NCP-3064 Hardcoded for EDGE --> Intouch Integration
        List<Profile> profiles = [Select Name from Profile where Id = :profileUserId LIMIT 1];
        if(!profiles.isEmpty()){
        currentUserProfileName = profiles[0].Name;
        }
        return currentUserProfileName;
    }
}