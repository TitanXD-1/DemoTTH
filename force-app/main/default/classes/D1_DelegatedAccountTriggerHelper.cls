/*
 * @name: D1_DelegatedAccountTriggerHelper
 * @Discription: Trigger Handler Class for DelegatedAccountTriggerHelper
 * @History                                                            
 * -                                                            
 * VERSION   AUTHOR            DATE              DETAIL
 * 1.0       Rubeena Naaz      25/03/2021        Initial Development[NCP-2781 - createAccountShare]
 * 2.0       Rubeena Naaz      19/04/2021        NCP-2803(removeAccountShare)
 * 3.0       Kapil Baliyan     12/10/2021        NCP-5021(createAccountShare)  
 * 4.0       Kapil Baliyan     21/12/2021        NCP-5777 (createAccountShare)
 **/
public without sharing class D1_DelegatedAccountTriggerHelper {
    
    /*
    @name  : createAccountShare
    @description : This methods used to create manual sharing for community user to target accounts
    */  
    public static void createAccountShare(Map<Id,SObject> newItems){
        Map<Id,DelegatedAccount> newAccItems = (Map<Id,DelegatedAccount>) newItems;
        List<AccountShare> accShareList = new List<AccountShare>();
        Set<Id> accIdSet = new Set<Id>(); //NCP-5021
        Set<Id> userIdSet = new Set<Id>(); //NCP-5021
        Set<String> existingAccountShareSet = new Set<String>(); //NCP-5021

        //Create AccountId & UserId Set
        for(DelegatedAccount delegateAcc : newAccItems.values()){
            accIdSet.add(delegateAcc.TargetId);
            userIdSet.add(delegateAcc.ManagedById);
        }

        //Get Existing AccountShare Records - NCP-5021
        if(accIdSet.size()>0 && userIdSet.size()>0){
            for(AccountShare accShare : [SELECT Id, AccountId, UserOrGroupId FROM AccountShare WHERE AccountId IN :accIdSet AND UserOrGroupId IN :userIdSet]){
                existingAccountShareSet.add(accShare.AccountId + '_' + accShare.UserOrGroupId);
            }
        }

        //Create AccountShare Record
        for(DelegatedAccount delegateAcc : newAccItems.values()){
            if(delegateAcc.TargetId != null && delegateAcc.ManagedById != null){
                String key = delegateAcc.TargetId + '_' + delegateAcc.ManagedById;
                //Create AccountShare Record if they dont exist
                if(!existingAccountShareSet.contains(key)){
                    AccountShare accShare = new AccountShare();
                    accShare.AccountId = delegateAcc.TargetId;
                    accShare.AccountAccessLevel = 'Read';
                    accShare.CaseAccessLevel = 'Read';
                    accShare.ContactAccessLevel = 'Edit'; //NCP-5777
                    accShare.OpportunityAccessLevel = 'Read';
                    accShare.RowCause = Schema.AccountShare.RowCause.Manual;
                    accShare.UserOrGroupId = delegateAcc.ManagedById;
                    accShareList.add(accShare);
                }
            }
        }
        
        //Insert Account Share
        if(accShareList != null && !accShareList.isEmpty()){
            //NCP-5021 : Used Database.Insert so that in case of any exception system still process other data and dont impact D1 Registration process
            Database.insert(accShareList, false);
        }
    }
    
    /*
    @userStory: NCP-2803
    @Description : This methods used to remove manual sharing for community user to target accounts
    */
    public static void removeAccountShare(Map<Id,SObject> oldItems){
        Map<Id,DelegatedAccount> oldDelegatedAcc = (Map<Id,DelegatedAccount>) oldItems;
        List<AccountShare> todeleteAccShareList = new List<AccountShare>();
        Map<Id,Id> deleteDelegatedAccMap = new Map<Id,Id>();

        for(DelegatedAccount delegateAcc : oldDelegatedAcc.values()){
            deleteDelegatedAccMap.put(delegateAcc.TargetId,delegateAcc.ManagedById);
        }

        //Get Account Share Records
        for(AccountShare accShare : [SELECT Id,AccountId, UserOrGroupId FROM AccountShare WHERE AccountId IN :deleteDelegatedAccMap.keySet()]){
            if(deleteDelegatedAccMap.containsKey(accShare.AccountId) 
               && accShare.UserOrGroupId == deleteDelegatedAccMap.get(accShare.AccountId))
            {
                todeleteAccShareList.add(accShare);
            }
        }
        
        //Delete Account Share
        if(todeleteAccShareList != null && !todeleteAccShareList.isEmpty()){
            //NCP-5021 : Used Database.Delete so that in case of any exception system still process other data and dont impact D1 Registration process
            Database.delete(todeleteAccShareList, false);
        }
    }
}