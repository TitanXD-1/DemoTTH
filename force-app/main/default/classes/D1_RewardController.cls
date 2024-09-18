/**
* @name D1_RewardController
* @description  This Class is used to Reward Details for D1 Partner+ Users
* @history
* VERSION          AUTHOR                   DATE            DETAIL
* 1.0              Kapil Baliyan            14/11/2022      Initial Development (NCP-)
* 2.0			   Swagat Shaw			    15/11/2011 
*/
public with sharing class D1_RewardController {
    
    /**
     * @description 
     * @param userId 
     * @return  `List<RewardWrapper>`
     * @exception 
     */
    @AuraEnabled(cacheable=true)
    public static List<RewardWrapper> getNewRewards(Id userId){
        User currentUser = getCurrentUserInfo(userId);
        AccountContactRelation acrRecord = [SELECT Id, ContactId, AccountId, Account.Country__c, Account.Global_Segment__c, D1_User_Role__c 
                                            FROM AccountContactRelation 
                                            WHERE ContactId =: currentUser.ContactId AND 
                                            AccountId =: currentUser.Effective_Account_Id__c LIMIT 1]; 
        
        if(acrRecord.D1_User_Role__c == 'Member of Staff'){
            acrRecord.D1_User_Role__c = 'Secondary User';
        }
        if(acrRecord.D1_User_Role__c == 'Primary'){
            acrRecord.D1_User_Role__c = 'Primary User';
        }

        //Get Completed SurveyInvitation Id
        Set<Id> surveyInvitationIdSet = getCompletedSurveyInvitationIds(currentUser.Effective_Account_Id__c);
        
        try {
            List<RewardWrapper> rewardWrapperList = new List<RewardWrapper>();
            for(SurveyInvitation surInv : [SELECT Id,Applicable_to__c,Start_Date__c,Segment__c,Reward_Description__c,Survey.Name,Reward_Type__c,SurveyId,InvitationLink,End_Date__c,ResponseStatus,Geography__c 
                                           FROM SurveyInvitation
                                           WHERE Id NOT IN :surveyInvitationIdSet AND 
                                           Applicable_to__c INCLUDES (:acrRecord.D1_User_Role__c) AND
                                           Geography__c != NULL AND
                                           Applicable_to__c != NULL AND
                                           Reward_Description__c != NULL AND
                                           Reward_Type__c != NULL AND
                                           End_Date__c >= TODAY AND
                                           Geography__c =:acrRecord.Account.Country__c AND
                                           (Segment__c INCLUDES (:acrRecord.Account.Global_Segment__c) OR Segment__c = NULL)
                                           ORDER BY Start_Date__c DESC, Survey.Name ASC])
            {                
                RewardWrapper newReward = new RewardWrapper();
                newReward.surveyId = surInv.SurveyId;
                newReward.rewardDescription = surInv.Reward_Description__c;
                newReward.rewardType = surInv.Reward_Type__c;
                newReward.surveyInvitationId = surInv.Id;
                newReward.surveyInvitationURL = surInv.InvitationLink;
                newReward.rewardExpiryDate = String.valueOf(surInv.End_Date__c);
                newReward.rewardCompletionStatus = surInv.ResponseStatus;
                newReward.surveyName = surInv.Survey.Name;
                rewardWrapperList.add(newReward);
            }
            return rewardWrapperList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    /**
     * @description 
     * @param userId 
     * @param filterType 
     * @return  `List<RewardWrapper>`
     * @exception 
     */
    @AuraEnabled(cacheable=true)
    public static List<RewardWrapper> getPastRewards(Id userId, string filterType){
        User currentUser = getCurrentUserInfo(userId);
        try {
            List<RewardWrapper> rewardWrapperList = new List<RewardWrapper>();
            List<SurveySubject> surveySubjectList = new List<SurveySubject>();
            /**
             * Note - We cannot put filter in below queries like SurveyInvitation.Geography__c because its not supported by salesforce 
             * and we receive error as Illegal Filter on Survey Subject that is why we are querying SurveyInvitationId and will use in below queries
             */
            Set<Id> surveyInvitationIdSet = getSurveyInvitationIds(currentUser.Available_Countries__c);

            switch on filterType {
                when 'past1Month' {
                    surveySubjectList = [SELECT Id, Name, SurveyInvitation.Reward_Type__c, SurveyInvitation.Reward_Description__c, SurveyInvitation.InvitationLink, 
                                        SurveyInvitation.ResponseStatus, Survey.Name, LastModifiedDate FROM SurveySubject 
                                        WHERE SubjectId =:currentUser.Effective_Account_Id__c AND SurveyInvitationId IN :surveyInvitationIdSet AND LastModifiedDate = LAST_N_DAYS:30
                                        ORDER BY LastModifiedDate DESC, Survey.Name ASC];
                }
                when 'past6Month' {
                    surveySubjectList = [SELECT Id, Name, SurveyInvitation.Reward_Type__c, SurveyInvitation.Reward_Description__c, SurveyInvitation.InvitationLink, 
                                        SurveyInvitation.ResponseStatus, Survey.Name, LastModifiedDate FROM SurveySubject 
                                        WHERE SubjectId =:currentUser.Effective_Account_Id__c AND SurveyInvitationId IN :surveyInvitationIdSet AND LastModifiedDate = LAST_N_DAYS:180
                                        ORDER BY LastModifiedDate DESC, Survey.Name ASC];
                }
                when 'past1Year' {
                    surveySubjectList = [SELECT Id, Name, SurveyInvitation.Reward_Type__c, SurveyInvitation.Reward_Description__c, SurveyInvitation.InvitationLink, 
                                        SurveyInvitation.ResponseStatus, Survey.Name, LastModifiedDate FROM SurveySubject 
                                        WHERE SubjectId =:currentUser.Effective_Account_Id__c AND SurveyInvitationId IN :surveyInvitationIdSet AND LastModifiedDate = LAST_N_DAYS:365
                                        ORDER BY LastModifiedDate DESC, Survey.Name ASC];
                }
                when else {
                    surveySubjectList = [SELECT Id, Name, SurveyInvitation.Reward_Type__c, SurveyInvitation.Reward_Description__c, SurveyInvitation.InvitationLink, 
                                        SurveyInvitation.ResponseStatus, Survey.Name, LastModifiedDate FROM SurveySubject 
                                        WHERE SubjectId =:currentUser.Effective_Account_Id__c AND SurveyInvitationId IN :surveyInvitationIdSet 
                                        ORDER BY LastModifiedDate DESC, Survey.Name ASC];
                }
            }

            //Create Reward Wrapper
            for(SurveySubject rewards : surveySubjectList){   
                if(String.valueOf(rewards.SurveyInvitation.ResponseStatus) == 'Completed'){
                    RewardWrapper rwp = new RewardWrapper();
                    rwp.rewardDescription = rewards.SurveyInvitation != NULL ? rewards.SurveyInvitation.Reward_Description__c : '';
                    rwp.surveyName = rewards.Survey != NULL ? rewards.Survey.Name : '' ;
                    rwp.rewardCompletedDate = String.valueOf(rewards.LastModifiedDate.date());
                    rwp.rewardCompletionStatus = (rewards.SurveyInvitation != NULL) ? String.valueOf(rewards.SurveyInvitation.ResponseStatus) : '';
                    rwp.rewardType = (rewards.SurveyInvitation != NULL)? String.valueOf(rewards.SurveyInvitation.Reward_Type__c) : '';
                    rwp.surveyInvitationURL = rewards.SurveyInvitation.InvitationLink;
                    rewardWrapperList.add(rwp); 
                }
            }
            return rewardWrapperList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description 
     * @param userId 
     * @return  `RewardFilterWrapper`
     * @exception 
     */
    @AuraEnabled(cacheable=true)
    public static RewardFilterWrapper getPastRewardCount(Id userId){
        try {
            RewardFilterWrapper rewardFilterWrapper = new RewardFilterWrapper();
            User currentUser = getCurrentUserInfo(userId);

            /**
             * Note - We cannot put filter in below queries like SurveyInvitation.Geography__c because its not supported by salesforce 
             * and we receive error as Illegal Filter on Survey Subject that is why we are querying SurveyInvitationId and will use in below queries
             */
            Set<Id> surveyInvitationIdSet = getSurveyInvitationIds(currentUser.Available_Countries__c);
            
            
            //Get Count of Past 30 Days Rewards
            AggregateResult[] pastMonthRewardCount = [SELECT Count(Id)pastRewardCount FROM SurveySubject WHERE SubjectId =:currentUser.Effective_Account_Id__c 
                                                        AND SurveyInvitationId IN :surveyInvitationIdSet AND LastModifiedDate = LAST_N_DAYS:30];

            //Get Count of Past 180 Days Rewards
            AggregateResult[] past6MonthRewardCount = [SELECT Count(Id)pastRewardCount FROM SurveySubject WHERE SubjectId =:currentUser.Effective_Account_Id__c 
                                                        AND SurveyInvitationId IN :surveyInvitationIdSet AND LastModifiedDate = LAST_N_DAYS:180];

            //Get Count of Past 365 Days Rewards
            AggregateResult[] past1YearRewardCount = [SELECT Count(Id)pastRewardCount FROM SurveySubject WHERE SubjectId =:currentUser.Effective_Account_Id__c 
                                                        AND SurveyInvitationId IN :surveyInvitationIdSet AND LastModifiedDate = LAST_N_DAYS:365];

            //Get Count of Past Rewards
            AggregateResult[] pastRewardCount = [SELECT Count(Id)pastRewardCount FROM SurveySubject WHERE SubjectId =:currentUser.Effective_Account_Id__c 
                                                        AND SurveyInvitationId IN :surveyInvitationIdSet];

            //Create Response Wrapper
            rewardFilterWrapper.pastMonthRewardCount = Integer.valueOf(pastMonthRewardCount[0].get('pastRewardCount'));
            rewardFilterWrapper.past6MonthRewardCount = Integer.valueOf(past6MonthRewardCount[0].get('pastRewardCount'));
            rewardFilterWrapper.past1YearRewardCount = Integer.valueOf(past1YearRewardCount[0].get('pastRewardCount'));
            rewardFilterWrapper.pastRewardCount = Integer.valueOf(pastRewardCount[0].get('pastRewardCount'));

            return rewardFilterWrapper;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description 
     * @param accId 
     * @return  `Set<Id>`
     */
    public static Set<Id> getCompletedSurveyInvitationIds(string accId){
        
        Set<Id> surveyInvitationIdSet = new Set<Id>();

        for(SurveySubject sSubject : [SELECT Id, SurveyInvitationId FROM SurveySubject WHERE SubjectId =:accId]){
            surveyInvitationIdSet.add(sSubject.SurveyInvitationId);
        }

        return surveyInvitationIdSet;
    }

    /**
     * @description 
     * @param countryCode 
     * @return  `Set<Id>`
     */
    public static Set<Id> getSurveyInvitationIds(string countryCode){
        
        Set<Id> surveyInvitationIdSet = new Set<Id>();

        for(SurveyInvitation sInvitation : [SELECT Id FROM SurveyInvitation WHERE Geography__r.Code__c =:countryCode AND Reward_Description__c != NULL AND Reward_Type__c != NULL AND Applicable_to__c != NULL]){
            surveyInvitationIdSet.add(sInvitation.Id);
        }

        return surveyInvitationIdSet;
    }
    
	/**
     * @description 
     * @param userId 
     * @return  `User`
     * @exception 
     */
    public static User getCurrentUserInfo(Id userId){
        userId = userId == null ? UserInfo.getUserId() : userId;
        
        List<User> users = [SELECT id, 
                            AccountId,Effective_Account_Id__c, ContactId, D1_User_Type_Id__c, Available_Countries__c,LanguageLocaleKey,D1_User_Type__c
                            FROM User
                            WHERE id=: userId];
        if(users.isEmpty()){
            throw new AuraHandledException('Access Denied(User)');
        }
        
        return users[0];
    }
    
    /**
	 * @description RewardWrapper Class
	*/
    public class RewardWrapper{
        @AuraEnabled public string surveyId {get;set;}  
        @AuraEnabled public string rewardDescription {get;set;} 
        @AuraEnabled public string rewardType {get;set;} 
        @AuraEnabled public string surveyInvitationId {get;set;} 
        @AuraEnabled public string surveyInvitationURL {get;set;} 
        @AuraEnabled public String rewardExpiryDate {get;set;} 
        @AuraEnabled public String rewardCompletedDate {get;set;} 
        @AuraEnabled public string rewardCompletionStatus {get;set;} 
        @AuraEnabled public string surveyName{get;set;} 
    }

    /**
     * @description RewardFilterWrapper Class
     */
    public class RewardFilterWrapper{
        @AuraEnabled public Integer pastMonthRewardCount {get;set;}
        @AuraEnabled public Integer past6MonthRewardCount {get;set;}
        @AuraEnabled public Integer past1YearRewardCount {get;set;}
        @AuraEnabled public Integer pastRewardCount {get;set;}
    }
    
}