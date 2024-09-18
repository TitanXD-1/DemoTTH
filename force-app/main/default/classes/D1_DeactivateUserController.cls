/**
@name D1_DeactivateUserController
@description D1_DeactivateUserController
@history
VERSION     AUTHOR           DATE           DETAIL
1.0         Narayana         09/02/2021     NCP-4307
2.0			Subhrojit		 28/04/2021		NCP-6389
3.0         Kapil Baliyan    19/08/2022     NCP-7209
**/
public without sharing class D1_DeactivateUserController {
    /**
     * @description this is used to check if the contact is primary to any account
     * @param contactId 
     * @return  `boolean`
     */    
    @AuraEnabled
    public static Map<String,Boolean> isPrimary(Id contactId){
        Boolean isPrimary = false;
        Boolean isActive = true;
        Boolean isOnlyUser = false; //to check if contact is the only assigned contact in related accounts
        List<AccountContactRelation> acrRecords = [SELECT Id, ContactId, AccountId, D1_Active__c, D1_Roles__c, D1_User_Role__c FROM AccountContactRelation 
                                                    WHERE ContactId = : contactId AND D1_Active__c = true AND D1_User_Role__c = 'Primary'];
        List<User> userRec = [SELECT Id, IsActive , ContactId FROM User WHERE ContactId = :contactId AND IsActive=true];
        List<Id> accIds = new List<Id>();
		for(AccountContactRelation acr : acrRecords)
		{
    		accIds.add(acr.AccountId);
		}
        Integer numberOfContacts = [Select Count() from AccountContactRelation where AccountId IN : accIds AND D1_Active__c = true]; //to check number of active D1 users of the associated accounts of the contact
        if(userRec.size()==0){
            isActive = false;
        }
        if(acrRecords.size()>0){
            isPrimary = true;
        }
        if(numberOfContacts == accIds.size()){
            isOnlyUser = true;
        }
        return new Map<String , Boolean>{
            'isPrimaryContact' => isPrimary,
            'isProfileAccessible' => D1_RegistrationDirectCustomerController.checkProfile(),
            'isActive' => isActive,
            'isOnlyUser' => isOnlyUser
        };
    }

    /**
     * @description This methods deactivates user and disables login to experience
     * @param contactId 
     * @return  `boolean`
     */    
    @AuraEnabled
    public static boolean deactivateUser(Id contactId){
        List<User> userRec = [SELECT Id, IsActive , ContactId FROM User WHERE ContactId = :contactId AND IsActive=true];
        if(userRec.size()>0){
        userRec[0].IsActive = false;
        update userRec; 
        System.enqueueJob(new DeactivateD1UserAsyncExecution(contactId));
        return true;
        }
        return false;
    }

    /* This Queueable class is used to avoid the future method inside future method conflict which occurs as part of
     *  AccountContactRelationTriggerHandler and also to avoid MixedDml Operation */
    public class DeactivateD1UserAsyncExecution implements Queueable {
        public Id contactId;
        public DeactivateD1UserAsyncExecution(Id contactId){
            this.contactId = contactId;
        }
        public void execute(QueueableContext context) {
            List<AccountContactRelation> acrRecords = [SELECT Id, D1_Active__c, D1_Roles__c, D1_User_Role__c FROM AccountContactRelation 

                                                        WHERE ContactId = :contactId AND D1_Active__c = true];

            List<AccountContactRelation> acrRecordsToUpdate = new List<AccountContactRelation>();
            if(acrRecords.size() > 0){
                for(AccountContactRelation acrRecord : acrRecords){
                    acrRecord.D1_Active__c = false;
                    acrRecord.D1_Roles__c = '';
                    acrRecord.D1_User_Role__c='';
                    acrRecordsToUpdate.add(acrRecord);
                }
            }
			update acrRecordsToUpdate;
            
            //NCP-7209
            Set<Id> conIdSet = new Set<Id>{contactId};
            D1_RegistrationUtility.updateDeactivatedContact(conIdSet);
        }
    }
}