/**

* @Description: EDGE_CaseMilestoneUtils

* @Purpose : Utility class for Quality Cases

* @History:

* @Version     Developer		   Date			     Story/Purpose
*    1.1       Aparajita		17/09/2021		   ES20-11127(Method:sendPushNotification)                

*    1.2       Anamika          20/09/2021         ES20-10781 (Method:updateAchievedSLA )
*    1.3       Joshraj          17/01/2023         ES20-13734 (Failure due to Custom Validation)

*/
public with sharing  class EDGE_QualityCaseMilestoneUtils implements Queueable,Database.AllowsCallouts{
    Set<Id> casesToUpdate = new Set<Id>();
    Boolean isPushNotification = false;
    Boolean isCaseUpdated = false;

    public static Id qualityCaseRecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality').getRecordTypeId();
    

    public EDGE_QualityCaseMilestoneUtils(Set<Id> caseIds, Boolean sendNotification){
        this.casesToUpdate = caseIds;
        this.isPushNotification = sendNotification;
    }
    
    public EDGE_QualityCaseMilestoneUtils(Set<Id> caseIds){
        isCaseUpdated = true;
        this.casesToUpdate = caseIds;
    }
    
    public void execute(QueueableContext bc){
        updateDueDate(casesToUpdate,isPushNotification); 
    }
    
    public static void updateDueDate(Set<Id> caseIds,Boolean isPushNotification) {
        List<Case> casesToUpdate = new List<Case>();
        List<Case> casesToDueDateUpdate = new List<Case>();
        //String closedString='Closed';
        if (caseIds != null && caseIds.Size()>0 ){

            for (CaseMilestone milestone : [select CaseId,Case.AccountId,Case.Status,Case.Manual_SLA_Extension__c,MilestoneType.Name,

                TargetDate
                from CaseMilestone
                where CaseId in :caseIds //and Case.Status!=:closedString//Closed Status Check
            ]) {


                casesToUpdate.add(new Case(Id = milestone.CaseId,Due_Date_Time__c = milestone.TargetDate,AccountId = milestone.Case.AccountId,Status = milestone.Case.Status,Manual_SLA_Extension__c=milestone.Case.Manual_SLA_Extension__c));
            }
            
        }
       
        if (casesToUpdate != null && casesToUpdate.Size()>0) {


            for(Case cse : casesToUpdate){
                if(cse.Manual_SLA_Extension__c == false){
                    casesToDueDateUpdate.add(cse);
                }
            }
            if (casesToDueDateUpdate != null && casesToDueDateUpdate.Size()>0) {
                 Database.update(casesToDueDateUpdate,false);
            }



            if(isPushNotification){
                sendPushNotification(casesToUpdate);
            }
        }
    }
    
    /**

* @description : sendPushNotification - Sends push notification to the applicable users upon case status update

* @return : void

* @param : List<Case>

*/
    public static void sendPushNotification(List<Case> casesToUpdate) 
    {
        //Initialization
        Set<Id> accountIds = new Set<Id>();
        Set<Id> allowedAtmIds = new Set<Id>();
        String allowedRoles = System.label.EDGE_RolesForQualityPushNotification;
        String allowedCountries = System.label.EDGE_CountriesForQualityPushNotification;
        String msg = System.label.EDGE_MsgForQualityPushNotification;
        List<String> listOfRoles = new List<String>();
        List<String> listOfCountries = new List<String>();
        List<String> usersToNotifyList = new List<String>();
        Map<Id,List<Id>> accIdVsUserIdMap = new Map<Id,List<Id>>();
        
        if(!String.isBlank(allowedRoles)){
            listOfRoles = allowedRoles.split(';');
        }
        if(!String.isBlank(allowedCountries)){
            listOfCountries = allowedCountries.split(';');
        }
        
        //Fetching the related account of quality cases
        if(casesToUpdate != null && casesToUpdate.size()>0)
        {
            for(Case caseObj:casesToUpdate)
            {
                if(caseObj.AccountId != null)
                {
                    accountIds.add(caseObj.AccountId);
                }                            
            }
            
            //Fetching AccountTeamMembers with appropriate role and country and mapping AccountTeamMembers' account with the users          
            
            for(AccountTeamMember atm : [SELECT Id, UserId, TeamMemberRole, AccountId FROM AccountTeamMember 
                                         WHERE TeamMemberRole IN : listOfRoles AND Account.Country__r.Code__c 
                                         IN : listOfCountries AND AccountId IN :accountIds LIMIT 50000])
            {
                if(accIdVsUserIdMap.containsKey(atm.AccountId) && accIdVsUserIdMap.get(atm.AccountId)!=null && accIdVsUserIdMap.get(atm.AccountId).size()>0)
                {
                    accIdVsUserIdMap.get(atm.AccountId).add(atm.UserId);
                }
                else
                {
                    accIdVsUserIdMap.put(atm.AccountId, new List<Id>{atm.UserId}); 
            }
        }
        
        //Sending Push-Notification
        for(Case caseObj : casesToUpdate)
        {
            Map<String,Object> custom = new Map<String,Object>();
            if(accIdVsUserIdMap!=null && accIdVsUserIdMap.size()>0)
            {


                    if(caseObj.AccountId != null)
                    {
                        usersToNotifyList = accIdVsUserIdMap.get(caseObj.AccountId);
                        String msgBody = msg.stripHtmlTags();


                String dueDateTime = String.valueOf(caseObj.Due_Date_Time__c);
                custom.put('Case ID', caseObj.Id);
                custom.put('Account ID', caseObj.AccountId);
                custom.put('Status', caseObj.Status);
                custom.put('Manual SLA Extension',caseObj.Manual_SLA_Extension__c);
                custom.put('Due Date & Time', dueDateTime); 


    
                        EDGE_QualityCaseTriggerHelper.pushNotificationMethodforCase(usersToNotifyList, msgBody, custom);

        }
                }
                }
            }
        
    }
}