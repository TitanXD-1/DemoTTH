/*
* @name D1_OpportunityController
* @description D1_OpportunityController Class for Opportunity related lwc
* @history
* VERSION     AUTHOR              DATE              DETAIL
* 1.0         SaiKumar            14/12/2021        NCP-5597,NCP-5600
* 1.1         Amar                14/12/2021        NCP-5596
* 
* */
public without sharing class D1_OpportunityController {
    
    
    public static User getUserDetails(Id userId){
        if(string.isEmpty(userId)){
            userId = userInfo.getUserId();
        }
        List<User> userList = [SELECT Id, Effective_Account_Id__c, LanguageLocaleKey,Available_Countries__c,D1_User_Type__c FROM User WHERE Id =:userId LIMIT 1]; //'0051w000006XdQdAAK' :UserInfo.getUserId()
        if(userList.isEmpty()){
            throw new AuraHandledException('Access denied(User)');
        }  
      return userList[0];
    }
    @AuraEnabled(cacheable=true)
    public static List<OpportunityContentDetail> getOpportunityRecords(String pageName){
        //List<String> contentKeys = new List<String>();
        List<Opportunity> oppRecords = new  List<Opportunity> ();
        Map<String,String> contentIdwithOpptunityMap = new Map<String,String>();
        User currentUser = getUserDetails(null);
        String language = currentUser.LanguageLocaleKey;
        Boolean d1RelevantCheck;
        d1RelevantCheck = true;
        //Boolean limitCheck = true;
        Id accountId;
        accountId = currentUser.Effective_Account_Id__c;
        String oppStatus;
        oppStatus = 'Open';
        if(accountId !=null){
            String queryStr = 'SELECT id,StageName,Opportunity_Template__c,Type,Opportunity_Template__r.D1_Content_Reference__c FROM Opportunity';
            queryStr +=	' WHERE  Opportunity_Template__r.D1_Relevant__c =:d1RelevantCheck';// dynamic query doesn't support direct true value so we use variable d1RelevantCheck to  access 
            queryStr += ' AND Opportunity_Template__r.D1_Content_Reference__c != null AND Opportunity_Template__c != null';
            queryStr += ' AND AccountId =:accountId AND StageName =:oppStatus ORDER BY LastModifiedDate DESC';
            if(pageName == 'Home'){
                queryStr += ' LIMIT 3';//OFFSET 0 need to remove 
            }/*else{
                queryStr += ' OFFSET 3';
            }    */       
            oppRecords = Database.query(queryStr);
        }
        if(oppRecords.size()>0){
            for(Opportunity oppRec:oppRecords){
                contentIdwithOpptunityMap.put(oppRec.Id,oppRec.Opportunity_Template__r.D1_Content_Reference__c);
            }
        }        
        List<OpportunityContentDetail> listContentDetails = contentDetails(language, contentIdwithOpptunityMap, currentUser);
        return listContentDetails;
    }
    
    public static List<OpportunityContentDetail> contentDetails(String language, Map<String,String> contentIdwithOpptunityMap, User currentUser){
        
        string communityId = [SELECT id FROM Network WHERE Name = 'DiageoOne' LIMIT 1][0].Id;
        List<String> topics = currentUser?.Available_Countries__c == null ? new List<String>() : currentUser?.Available_Countries__c.split(';');
        
        String managedContentType = 'Selling_Stories';
        List<OpportunityContentDetail> oppContentDetails= new List<OpportunityContentDetail>();
        if(Test.isRunningTest() || contentIdwithOpptunityMap.size()>0){
            ConnectApi.ManagedContentVersionCollection collection = connectApi.ManagedContent.getManagedContentByContentKeys(communityId, contentIdwithOpptunityMap.values(), null, 250, language, managedContentType, false);
            
            Map<String, ConnectApi.ManagedContentVersion> mapOfContentIdItem = new Map<String, ConnectApi.ManagedContentVersion>();
            for (ConnectApi.ManagedContentVersion item : collection.items) {
                mapOfContentIdItem.put(item.contentKey, item);
            }
            for (String oppids: contentIdwithOpptunityMap.keyset()) {
                ConnectApi.ManagedContentVersion item = mapOfContentIdItem.get(contentIdwithOpptunityMap.get(oppids));
                if(item == null){
                    continue;
                }
                Map<String, ConnectApi.ManagedContentNodeValue> contentNodes = item.contentNodes;
                addToOpportunityContentDetail(
                    oppContentDetails,contentNodes,currentUser,
                    item.contentKey,oppIds
                );           
            }
        }
        Set<String> contentkeyfromOpp = new Set<String>();
        contentkeyfromOpp.addAll(contentIdwithOpptunityMap.values());
        ConnectApi.ManagedContentVersionCollection contentList = connectApi.ManagedContent.getManagedContentByTopics(communityId, topics, null, null, language, managedContentType);
        List<ConnectApi.ManagedContentVersion> items = contentList.items;
        for(Integer i = 0;i<items.size();i++){
            Map<String, ConnectApi.ManagedContentNodeValue> contentNodes = items[i].contentNodes;
            if(!contentkeyfromOpp.contains(items[i].contentkey)){
                addToOpportunityContentDetail(
                    oppContentDetails, contentNodes , currentUser,
                    items[i].contentkey,Null
                ); 
            }
        }
        return oppContentDetails;
    }
     /**
     * @description Helper method adds Opportunity content details to source if content have value
     * @author 
     * @param source
     * @param nodetitle
     * @param nodesubHeading
     * @param nodeimageurl
     * @param containsKey
     * @param opportunityId
     * @return List<OpportunityContentDetail> source
     */
    @TestVisible
    private static List<OpportunityContentDetail> addToOpportunityContentDetail(
        List<OpportunityContentDetail> source,
        Map<String, ConnectApi.ManagedContentNodeValue> contentNodes ,user currentUser,
        string containsKey,
        string opportunityId
    ){
        OpportunityContentDetail contentDetails= new OpportunityContentDetail();
        contentDetails.title =((ConnectApi.ManagedContentTextNodeValue) contentNodes.get('Title'))?.value;
        contentDetails.subHeading =((ConnectApi.ManagedContentTextNodeValue) contentNodes.get('Excerpt'))?.value.stripHtmlTags();
        contentDetails.bannerImageUrl =((ConnectApi.ManagedContentMediaNodeValue) contentNodes.get('BannerImage'))?.url;
        contentDetails.contentKey =containsKey;
        contentDetails.opportunityId =opportunityId;
        if(currentUser.D1_User_Type__c=='Direct Buyer'){
        contentDetails.ctaLabel =((ConnectApi.ManagedContentTextNodeValue) contentNodes.get('DirectCustomerCTALabel'))?.value;
        contentDetails.ctaUrl =((ConnectApi.ManagedContentTextNodeValue) contentNodes.get('DirectCustomersCTAURL'))?.value;
        }
        else{
        contentDetails.ctaLabel =((ConnectApi.ManagedContentTextNodeValue) contentNodes.get('IndirectCustomersCTALabel'))?.value;
        contentDetails.ctaUrl =((ConnectApi.ManagedContentTextNodeValue) contentNodes.get('IndirectCustomersCTAURL'))?.value;
        }
      
        if(!String.isEmpty(contentDetails.contentKey) || !String.isEmpty(contentDetails.bannerImageUrl) || !String.isEmpty(contentDetails.title) || !String.isEmpty(contentDetails.subHeading)){
            source.add(contentDetails);
        }
        return source;
    }

     
    public class OpportunityContentDetail{
        @AuraEnabled public String title{get;set;}
        @AuraEnabled public String subHeading{get;set;}
        @AuraEnabled public String bannerImageUrl{get;set;}
        @AuraEnabled public String opportunityId{get;set;}
        @AuraEnabled public String contentKey{get;set;}
        @AuraEnabled public String ctaLabel{get;set;}
        @AuraEnabled public String ctaUrl{get;set;}
       }
}