/**
 * @name : D1_PartnerPlusPopUpController
 * @description : Controller for Partner Plus Confirmation Pop Up
 * @history
 * VERSION     	AUTHOR         	   DATE            DETAIL
 * 1.0         Pratap Sen      	16/11/2022        NCP-7427
 * 1.1         Pratap Sen       06/12/2022        NCP-7458
**/
public without sharing class D1_PartnerPlusPopUpController {
    /**
    * @description : updates Partner Plus joining info in account and permission at ACR when user joins partner plus
    * @param : {Id} userId 
    * @return : void
    */ 
    @AuraEnabled
    public static void updateJoiningInfo(Id userId){
        userId = String.isEmpty(userId) ? UserInfo.getUserId() : userId;
        List<AccountContactRelation> accConRelList = new List<AccountContactRelation>(); //List to update with new D1 Roles
        String pickLstValToAdd = Label.D1_ManagePartnerPlusVal;//Label value : Manage Partner Plus
        try{
            User currUsr = [SELECT Effective_Account_Id__c FROM USER WHERE Id =: userId LIMIT 1];
            for(AccountContactRelation acrRecs : [SELECT Id,D1_Roles__c FROM AccountContactRelation
                         						  WHERE AccountId =: currUsr.Effective_Account_Id__c 
                         						  AND D1_Active__c = true])
            {
                if(!acrRecs.D1_Roles__c.contains(pickLstValToAdd)){
                    acrRecs.D1_Roles__c = acrRecs.D1_Roles__c + ';' + pickLstValToAdd;
                    accConRelList.add(acrRecs);
                }
            }
            if(!accConRelList.isEmpty()){
                update accConRelList;
            }
            Account accRec = new Account(Id = currUsr.Effective_Account_Id__c);
            accRec.Partner_Plus_Joining_Date__c = System.today();
            accRec.Partner_Plus_Enabled__c = true;
            update accRec;
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
    * @description : returns true if user is primary
    * @param : {Id} userId 
    * @return : Boolean
    */ 
    @AuraEnabled(cacheable=true)
    public static Boolean isPrimary(Id userId){
        User userRec = [SELECT Id, IsActive , Effective_Account_Id__c, ContactId 
                        FROM User WHERE Id = :userId AND IsActive = true LIMIT 1];
        
        List<AccountContactRelation> acrRecords = new List<AccountContactRelation>();
        acrRecords = [SELECT Id, ContactId, AccountId, D1_Active__c, D1_User_Role__c FROM AccountContactRelation 
                        WHERE ContactId =:userRec.ContactId
                        AND D1_Active__c = true 
                        AND D1_User_Role__c = 'Primary'
                        AND AccountId =:userRec.Effective_Account_Id__c];
        return (acrRecords.isEmpty() == false);
    }

    /**
    * @description : updates D1_Partner_Reminder_Display_Login_Count__c field of Account
    * @param : {Id} userId 
    * @return : void
    */
    @AuraEnabled
    public static void updateLastReminderLoginCount(Id userId){
        userId = String.isEmpty(userId) ? UserInfo.getUserId() : userId;
        User currUsr = [SELECT Effective_Account_Id__c,Contact.D1_Generic_Login_Counter__c
                        FROM User
                        WHERE Id =: userId LIMIT 1];
        Account acc = [SELECT Id,D1_Partner_Reminder_Display_Login_Count__c 
                       FROM Account 
                       WHERE Id =: currUsr.Effective_Account_Id__c LIMIT 1];
        acc.D1_Partner_Reminder_Display_Login_Count__c = currUsr.Contact.D1_Generic_Login_Counter__c;
        update acc;
    } 

}