/**
* @Name: D1_AccountContactRelationTriggerHelper
* @description : Trigger Helper Class for AccountContactRelationTrigger
* @History                                                            
* --                                                            
* VERSION   AUTHOR            DATE              DETAIL
* 1.0       Rubeena Naaz      25/03/2021		Initial Development[NCP-2781 - createExternalManageAccount]
* 2.0       Rubeena Naaz      19/04/2021		NCP-2803 (removeExternalManageAccount)
* 3.0       Vikas Panwar      01/08/2021        NCP-3819 (afterInsertACRelationNotification)
* 4.0       Vikas Panwar      01/08/2021        NCP-3820, NCP-3821 (afterUpdateACRelationNotification)
* 5.0       Kapil Baliyan     11/10/2021        NCP-4935
* 6.0       Kapil Baliyan     12/10/2021        NCP-5021 (createExternalManageAccount, )
* 7.0       PriyankaVinumarthi 25/10/2021		NCP-5027 (afterInsertACRelationNotification,afterUpdateACRelationNotification)
* 8.0       Kapil Baliyan     03/01/2022        NCP-5143 (syncACR, createACR, updateACR)
* 9.0       Rubeena Naaz      11/05/2022		NCP-6710 (updateD1FirstOrderEmailCheck)
* 10.0      Rubeena Naaz      10/06/2022		NCP-6835 (updatePOSOrderDateOnContact, clearPOSOrderDetails)
* 11.0      Suvendu Roy       26/05/2023		CUS-212 (reParentingShipToContact)
**/
public without sharing class D1_AccountContactRelationTriggerHelper {
    
    /**
* @description 
* @param newItems 
* @param oldItems 
*/    
    public static void createExternalManageAccount(Map<ID,SObject> newItems, Map<ID,SObject> oldItems){
        final String d1ProfileName = 'DiageoOne External User';
        Map<Id,AccountContactRelation> newACRItems = (Map<Id,AccountContactRelation>) newItems;
        Map<Id,AccountContactRelation> oldACR;
        List<DelegatedAccount> delegatedAccountList = new List<DelegatedAccount>();
        List<AccountContactRelation> acrList = new List<AccountContactRelation>();
        List<Id> contactIdList = new List<Id>();
        Map<Id,Id> userContactMap = new Map<Id,Id>();
        Set<Id> accIdSet = new Set<Id>(); //NCP-5021
        Set<String> existingDelegatedAccSet = new Set<String>(); //NCP-5021
        Set<Id> accountIds = new Set<Id>();
        
        //check oldItems for update scenario
        if(oldItems != null){
            oldACR =(Map<Id,AccountContactRelation>) oldItems;
        }
        for(AccountContactRelation acc: newACRItems.values()){
            accountIds.add(acc.AccountId);
        }
        List<Account> accounts = [SELECT Id, AccountNumber,Name, Account_Type__c FROM Account WHERE Id IN :accountIds];
        Map<Id, Account> accountNumberByAccountId = new Map<Id, Account>(); 
        for(Account acc: accounts){
            accountNumberByAccountId.put(acc.Id, acc);
        }
        for(AccountContactRelation acr : newACRItems.values()){
            AccountContactRelation oldACRItems;
            if(oldACR != null){
                oldACRItems = oldACR.get(acr.Id); 
            }
            Account accRecd = accountNumberByAccountId.containsKey(acr.AccountId) ? accountNumberByAccountId.get(acr.AccountId) : null;
            List<String> accountTypevalue = accRecd.Account_Type__c == null ? new List<String>() : accRecd.Account_Type__c.split(';');
            Boolean isShiptoPresent = true;
            if( !accountTypevalue.isEmpty()  && accountTypevalue.size() < 2){
                for(String str : accountTypevalue){
                    if(str == 'Ship-To'){
                        isShiptoPresent = false;
                    }else{
                        isShiptoPresent = true;
                    }
                }
            }
            if(((acr.IsDirect == false && acr.D1_Active__c == true && oldACRItems == null) || 
                (oldACRItems != null && (oldACRItems.D1_Active__c != acr.D1_Active__c) 
                 && acr.D1_Active__c == true && acr.IsDirect == false))  && isShiptoPresent == true)
            {
                contactIdList.add(acr.ContactId);
                acrList.add(acr);
                accIdSet.add(acr.AccountId); //NCP-5021
            }
        }
        
        //Fetching User associated with the contact
        if(contactIdList != null && !contactIdList.isEmpty()){
            for(User user: [SELECT Id,ContactId FROM User WHERE ContactId IN :contactIdList AND IsActive=true AND Profile.Name =: d1ProfileName]){
                userContactMap.put(user.ContactId,user.Id);
            }
        }
        
        //Get Existing DelegatedAccount - NCP-5021
        if(userContactMap.size()>0){
            for(DelegatedAccount delegatedAcc : [SELECT Id, TargetId, ManagedById FROM DelegatedAccount WHERE TargetId IN :accIdSet AND ManagedById IN :userContactMap.values()]){
                existingDelegatedAccSet.add(delegatedAcc.TargetId + '_' + delegatedAcc.ManagedById);
            }
        }
        if(!acrList.isEmpty()){
            for(AccountContactRelation acr : acrList){
                if(userContactMap.containsKey(acr.ContactId)){
                    string key = acr.AccountId + '_' + userContactMap.get(acr.ContactId); //NCP-5021
                    //Create DelegatedAccount only if they dont exist
                    if(!existingDelegatedAccSet.contains(key)){
                        DelegatedAccount delegateAcc = new DelegatedAccount();
                        delegateAcc.Name = acr.Account_Contact_Name__c;
                        delegateAcc.TargetId = acr.AccountId;
                        delegateAcc.ManagedById = userContactMap.get(acr.ContactId);
                        delegateAcc.AccessBuyFor = true;
                        delegatedAccountList.add(delegateAcc);
                    }
                }
            }
        }
        if(!delegatedAccountList.isEmpty() && delegatedAccountList != null){
            //NCP-5021 : Used Database.Insert so that in case of any exception system still process other data and dont impact D1 Registration process
            Database.insert(delegatedAccountList, false);
        }
    }
    
    /**
* @description 
* @param newItems 
* @param oldItems 
*/    
    public static void removeExternalManageAccount(Map<ID,SObject> newItems, Map<ID,SObject> oldItems){
        final String d1ProfileName = 'DiageoOne External User';
        Map<Id,AccountContactRelation> newACRItems = (Map<Id,AccountContactRelation>) newItems;
        Map<Id,AccountContactRelation> oldACR;
        List<DelegatedAccount> toRemoveDelegatedAccountList = new List<DelegatedAccount>();
        Map<Id,Id> accountContactMap = new Map<Id,Id>();
        List<Id> contactIdList = new List<Id>();
        Map<Id,Id> userContactMap = new Map<Id,Id>();
        
        if(oldItems != null){
            oldACR =(Map<Id,AccountContactRelation>) oldItems;
        }
        
        for(AccountContactRelation acr: newACRItems.values()){
            AccountContactRelation oldACRItems;
            if(oldACR != null){
                oldACRItems = oldACR.get(acr.Id); 
            }
            if((oldACRItems.D1_Active__c != acr.D1_Active__c) && !acr.D1_Active__c){
                accountContactMap.put(acr.AccountId, acr.ContactId);
                contactIdList.add(acr.ContactId);
            }
        }
        
        if(contactIdList != null && !contactIdList.isEmpty()){
            for(User user: [SELECT Id,ContactId FROM User WHERE ContactId IN:contactIdList AND Profile.Name =:d1ProfileName]){ // AND IsActive=true
                userContactMap.put(user.ContactId,user.Id);
            }
        }
        
        if(accountContactMap != null){
            for(DelegatedAccount deledatedAcc : [SELECT Id,TargetId,ManagedById FROM DelegatedAccount WHERE TargetId IN :accountContactMap.keyset()]){
                if(accountContactMap.containsKey(deledatedAcc.TargetId) && 
                   deledatedAcc.ManagedById == userContactMap.get(accountContactMap.get(deledatedAcc.TargetId)))
                {
                    toRemoveDelegatedAccountList.add(deledatedAcc);
                }
            }
        }
        
        if(!toRemoveDelegatedAccountList.isEmpty()){
            
            //NCP-5021 : Used Database.Delete so that in case of any exception system still process other data and dont impact D1 Registration process
            Database.delete(toRemoveDelegatedAccountList, false);
        }
    }
    
    /**
* @description This methods is used to send notification to community users when new account access is given.
* @param newItems 
* @param oldItems 
*/  
    public static void afterInsertACRelationNotification(Map<ID,SObject> newItems, Map<ID,SObject> oldItems){
        String body;
        String title;
        String targetPageRef;
        String notificationType='D1_Permission_Center';
        Map<Id,AccountContactRelation> newACRItems = (Map<Id,AccountContactRelation>) newItems;
        Set<Id> accountIds = new Set<Id>();
        Set<String> contactIds;
        List<String> labelParams;
        for(AccountContactRelation acc: newACRItems.values()){
            accountIds.add(acc.AccountId);
        }
        
        List<Account> accounts = [SELECT Id, AccountNumber,Name,Account_Type__c FROM Account WHERE Id IN :accountIds];
        Map<Id, Account> accountNumberByAccountId = new Map<Id, Account>(); 
        for(Account acc: accounts){
            accountNumberByAccountId.put(acc.Id, acc);
        }
        
        for(AccountContactRelation acr: newACRItems.values()){
            labelParams = new List<String>(); //NCP-4935
            contactIds = new Set<String>(); //NCP-4935
            //Send Notification when user's access is granted for account\
            Account accRecd = accountNumberByAccountId.containsKey(acr.AccountId) ? accountNumberByAccountId.get(acr.AccountId) : null;
            List<String> accountTypevalue = accRecd.Account_Type__c == null ? new List<String>() : accRecd.Account_Type__c.split(';');
            Boolean isShiptoPresent = true;
            if( !accountTypevalue.isEmpty()  && accountTypevalue.size() < 2){
                for(String str : accountTypevalue){
                    if(str == 'Ship-To'){
                        isShiptoPresent = false;
                    }else{
                        isShiptoPresent = true;
                    }
                }
            }
            if(acr.D1_Active__c && String.isNotBlank(acr.D1_Roles__c) && isShiptoPresent == true){
                targetPageRef = System.Label.D1_My_Account_Page; 
                body = 'D1_ACR_Create_Notification';
                title = 'D1_Access_Granted_Notification';
                if(accountNumberByAccountId != null && accountNumberByAccountId.get(acr.AccountId).AccountNumber!= null){
                    body = 'D1_ACR_Create_Notification_2';
                    String  accountNumber = String.valueOf(accountNumberByAccountId.get(acr.AccountId).AccountNumber);
                    String accName = String.valueOf(accountNumberByAccountId.get(acr.AccountId).Name);
                    labelParams.add(accName);
                    labelParams.add(accountNumber);
                }
                else{
                    String accountNumber= String.valueOf(accountNumberByAccountId.get(acr.AccountId).Name);
                    labelParams.add(accountNumber);
                }
                
                contactIds.add(acr.ContactId);
                if(!Test.isRunningTest() && !System.isBatch()){
                    
                    D1_CustomNotificationUtility.notifyUsers(contactIds, notificationType, title, body, null, targetPageRef, labelParams, null);
                    
                }
                
            }
        }
    }
    /**
* @description This methods is used to send notification to community users when there is a change in permission.
* @param newItems 
* @param oldItems 
*/  
    public static void afterUpdateACRelationNotification(Map<ID,SObject> newItems, Map<ID,SObject> oldItems){
        String body;
        String title;
        String targetPageRef;
        String notificationType='D1_Permission_Center';
        Map<Id,AccountContactRelation> newACRItems = (Map<Id,AccountContactRelation>) newItems;
        Map<Id,AccountContactRelation> oldACR;
        if(oldItems != null){
            oldACR =(Map<Id,AccountContactRelation>) oldItems;
        }
        
        Set<Id> accountIds = new Set<Id>();
        for(AccountContactRelation acr: newACRItems.values()){
            accountIds.add(acr.AccountId);
        }
        List<Account> accounts = [SELECT Id, AccountNumber, Name, Account_Type__c FROM Account WHERE Id IN: accountIds ];
        Map<Id, Account> accountNumberByAccountId = new Map<Id, Account>();
        List<String> labelParams = new List<String>();
        
        for(Account acc: accounts){
            accountNumberByAccountId.put(acc.Id, acc);
            
        }
        
        Set<String> contactIds; //NCP-4935
        List<String> titleLabelParam = new List<String>(); 
        
        for(AccountContactRelation acr: newACRItems.values()){
            AccountContactRelation oldACRItems;
            labelParams = new List<String>();
            contactIds = new Set<String>(); //NCP-4935
            if(oldACR != null){
                oldACRItems = oldACR.get(acr.Id); 
            }
            Account accRecd = accountNumberByAccountId.containsKey(acr.AccountId) ? accountNumberByAccountId.get(acr.AccountId) : null;
            List<String> accountTypevalue = accRecd.Account_Type__c == null ? new List<String>() : accRecd.Account_Type__c.split(';');
            Boolean isShiptoPresent = true;
            if( !accountTypevalue.isEmpty()  && accountTypevalue.size() < 2){
                for(String str : accountTypevalue){
                    if(str == 'Ship-To'){
                        isShiptoPresent = false;
                    }else{
                        isShiptoPresent = true;
                    }
                    
                }
            }
            
            
            if(acr.D1_Active__c == true && oldACRItems.D1_Roles__c != acr.D1_Roles__c && String.isNotBlank(acr.D1_Roles__c) && isShiptoPresent == true ){
                targetPageRef = System.Label.D1_My_Account_Page;
                body = 'D1_Update_Permission_Notification';
                title = 'D1_Access_Changes_Notification'; 
                
                if(accountNumberByAccountId != null && accountNumberByAccountId.get(acr.AccountId).AccountNumber!= null){
                    body = 'D1_Update_Permission_Notification_2';
                    String  accountNumber = String.valueOf(accountNumberByAccountId.get(acr.AccountId).AccountNumber);
                    String accName = String.valueOf(accountNumberByAccountId.get(acr.AccountId).Name);
                    labelParams.add(accName);
                    labelParams.add(accountNumber);
                }
                else{
                    String accountPermissionChange= String.valueOf(accountNumberByAccountId.get(acr.AccountId).Name);
                    labelParams.add(accountPermissionChange);
                }
                
                contactIds.add(acr.ContactId);
                
                if(!Test.isRunningTest() && !System.isBatch()){ //NCP-4935
                    
                    D1_CustomNotificationUtility.notifyUsers(contactIds, notificationType, title, body,'',targetPageRef,labelParams, titleLabelParam);
                    
                }
                
            }
            
            //Send Notification when user's access is revoked from account
            if(oldACRItems.D1_Active__c != acr.D1_Active__c && !acr.D1_Active__c  &&  isShiptoPresent == true){
                targetPageRef = System.Label.D1_My_Account_Page; 
                body = 'D1_Revoke_Permission_Notification';
                title = 'D1_Access_Revoked_Notification';
                
                if(accountNumberByAccountId != null && accountNumberByAccountId.get(acr.AccountId).AccountNumber!= null){
                    body = 'D1_Revoke_Permission_Notification_2';
                    String  accountNumber = String.valueOf(accountNumberByAccountId.get(acr.AccountId).AccountNumber);
                    String accName = String.valueOf(accountNumberByAccountId.get(acr.AccountId).Name);
                    labelParams.add(accName);
                    labelParams.add(accountNumber);
                }
                else{
                    String accountPermissionRevoke= String.valueOf(accountNumberByAccountId.get(acr.AccountId).Name);
                    labelParams.add(accountPermissionRevoke);
                }
                contactIds.add(acr.ContactId);
                
                if(!Test.isRunningTest() && !System.isBatch()){ //NCP-4935
                    
                    D1_CustomNotificationUtility.notifyUsers(contactIds, notificationType, title, body,'',targetPageRef,labelParams, titleLabelParam);
                    
                }
                
            }
        }
    }
    
    /**
* @description : To check account is buyer enable or not if not add it to buyer account and add it buyer group member.
* @param newItems
* @param oldItems 
* User Story : NCP -4527
*/
    public static void checkAndEnableBuyerSystem(Map<ID,SObject> newItems, Map<ID,SObject> oldItems){
        Map<Id,AccountContactRelation> newACRItems = (Map<Id,AccountContactRelation>) newItems;
        Map<Id,AccountContactRelation> oldACRItems = (Map<Id,AccountContactRelation>) oldItems;
        Map<Id,User> acrUserMap = new Map<Id,User>();
        Map<Id,Account> acrAccountMap = new Map<Id,Account>();
        Map<Id,PNR_Partner_Function__c> pnrAccountMap = new Map<Id,PNR_Partner_Function__c>();
        Map<string,string> portfolioVsSoldTo = new Map<string,string>();
        Map<Id,BuyerGroup> accbuyergroupMap = new Map<Id,BuyerGroup>();        
        Map<Id,AccountContactRelation> contactIdACR = new Map<Id,AccountContactRelation>();
        Map<Id,AccountContactRelation> accountIdACR = new Map<Id,AccountContactRelation>();
        List<BuyerAccount> buyerAccList = new List<BuyerAccount>(); 
        List<BuyerGroupMember> buyerGrpMemberList = new List<BuyerGroupMember>();        
        List<Account> accList = new List<Account>(); 
        Set<AccountContactRelation> newACR =  new Set<AccountContactRelation>();
        
        For(AccountContactRelation acr : newACRItems.values()){             
            if((oldACRItems == null && acr.D1_Active__c == true )|| (oldACRItems != null 
                                                                     && acr.D1_Active__c != oldACRItems.get(acr.Id).D1_Active__c && acr.D1_Active__c == true))
            {
                contactIdACR.put(acr.ContactId,acr);
                accountIdACR.put(acr.AccountId,acr);  
            }            
        }
        
        if(!contactIdACR.keyset().isEmpty()){
            For(User us : [SELECT Id,IsActive,ContactId FROM User WHERE ContactId IN :contactIdACR.keyset() AND IsActive = true]){
                acrUserMap.put(us.ContactId,us);
                newACR.add(contactIdACR.get(us.ContactId));
            }  
        }        
        
        if(!accountIdACR.keyset().isEmpty()){            
            for(Account acc : [SELECT Id,IsBuyer,Name,CurrencyIsoCode FROM Account WHERE 
                               Id IN : accountIdACR.keyset() AND IsBuyer = false and Direct_Customer__c = true and D1_EDGE_Customer__c = true])
            {               
                acrAccountMap.put(acc.Id,acc); 
                newACR.add(accountIdACR.get(acc.Id));
            }  
        }
        
        if(!acrAccountMap.isEmpty()){
            for(PNR_Partner_Function__c pnrPartnerFunction: [SELECT Id, PNR_Customer_No__c, PNR_Type__c,Item_Proposal__c,CurrencyIsoCode,PNR_Customer_No__r.D1_Registration_Status__c
                                                               FROM PNR_Partner_Function__c 
                                                               WHERE PNR_Customer_No__c in: acrAccountMap.keyset()
                                                               AND PNR_Type__c = 'Sold-To' and Item_Proposal__c != null])
            {
                pnrAccountMap.put(pnrPartnerFunction.PNR_Customer_No__c,pnrPartnerFunction);                                                                
                portfolioVsSoldTo.put(pnrPartnerFunction.Item_Proposal__c,pnrPartnerFunction.PNR_Customer_No__c);
            }
        }
        
        if(!portfolioVsSoldTo.isEmpty()){
            for(BuyerGroup buyergrp : [SELECT Id,Name,PortfolioID__c FROM BuyerGroup WHERE PortfolioID__c IN : portfolioVsSoldTo.keyset()]){
                accbuyergroupMap.put(portfolioVsSoldTo.get(buyergrp.PortfolioID__c),buyergrp);
            }  
        }
        
        if(!newACR.isEmpty()){
            for(AccountContactRelation acr : newACR){                
                if(String.isNotBlank(acr.D1_Roles__c) && !acrAccountMap.isEmpty() && !acrUserMap.isEmpty() && !accbuyergroupMap.isEmpty() && !pnrAccountMap.isEmpty()){
                    Boolean isOrderingPresent = acr.D1_Roles__c.split(';').contains('Ordering');            
                    if(acr.D1_Active__c == true && acr.IsDirect == false && isOrderingPresent == true
                       && acrAccountMap.get(acr.AccountId).IsBuyer == false && acrUserMap.get(acr.ContactId).IsActive == true)
                    {
                        if(acrAccountMap.containsKey(acr.AccountId)){
                            BuyerAccount buyerAccountObj = new BuyerAccount();
                            buyerAccountObj.Name = acrAccountMap.get(acr.AccountId).Name;
                            buyerAccountObj.BuyerId = acrAccountMap.get(acr.AccountId).Id;
                            buyerAccountObj.isActive = true;
                            buyerAccountObj.BuyerStatus = 'Active';
                            buyerAccList.add(buyerAccountObj);
                        }
                        
                        if(accbuyergroupMap.containsKey(acr.AccountId)){
                            BuyerGroupMember buyerGrpMemberObj = new BuyerGroupMember();
                            buyerGrpMemberObj.BuyerId = acr.AccountId;
                            buyerGrpMemberObj.BuyerGroupId = accbuyergroupMap.get(acr.AccountId).Id;
                            buyerGrpMemberList.add(buyerGrpMemberObj);
                        }
                        
                        if(pnrAccountMap.get(acr.AccountId).CurrencyIsoCode != acrAccountMap.get(acr.AccountId).CurrencyIsoCode || 
                           (pnrAccountMap.get(acr.AccountId).PNR_Customer_No__r.D1_Registration_Status__c == null || 
                            pnrAccountMap.get(acr.AccountId).PNR_Customer_No__r.D1_Registration_Status__c == '')){
                                Account acc =  new account();
                                acc.id = acr.AccountId;
                                if(pnrAccountMap.get(acr.AccountId).CurrencyIsoCode != acrAccountMap.get(acr.AccountId).CurrencyIsoCode){
                                    acc.CurrencyIsoCode = pnrAccountMap.get(acr.AccountId).CurrencyIsoCode;
                                }
                                if(pnrAccountMap.get(acr.AccountId).PNR_Customer_No__r.D1_Registration_Status__c == null || 
                                   pnrAccountMap.get(acr.AccountId).PNR_Customer_No__r.D1_Registration_Status__c == '') {
                                       acc.D1_Registration_Status__c = 'AppInvited';
                                   }
                                accList.add(acc); 
                            }                       
                    }
                }
            } 
        }
        if(buyerAccList != null && buyerAccList.size()>0) {
            insert buyerAccList;
        }
        
        if(buyerGrpMemberList != null && buyerGrpMemberList.size()>0) {
            insert buyerGrpMemberList;
        }
        
        if(accList != null && accList.size()>0) {
            update accList;
        }
    }
    
    /**
* @description : Method to SYNC Sold-To ACR with SHip-To ACR
* NCP-5143
*/
    public static void syncACR(Map<Id,SObject> newItems, Map<Id,SObject> oldItems){
        Set<Id> accIdSet = new Set<Id>();
        Map<Id, List<AccountContactRelation>> conSoldToMap = new Map<Id, List<AccountContactRelation>>();
        Map<Id, Set<Id>> soldToShipToMap = new Map<Id, Set<Id>>();
        Set<Id> shipToIdSet = new Set<Id>();
        Map<String, AccountContactRelation> existingShipToACRMap = new Map<String, AccountContactRelation>();
        List<AccountContactRelation> acrList = new List<AccountContactRelation>();
        Map<Id, AccountContactRelation> newACRItems = (Map<Id, AccountContactRelation>) newItems;
        Map<Id, AccountContactRelation> oldACRItems;
        if(oldItems != null){
            oldACRItems = (Map<Id,AccountContactRelation>) oldItems;
        }
        
        //Check which ACR is changed
        for(AccountContactRelation acr : newACRItems.values()){
            if((oldACRItems == null && acr.D1_Active__c && String.isNotBlank(acr.D1_Roles__c)) || 
               (oldACRItems != null && ((acr.D1_Active__c != oldACRItems.get(acr.Id).D1_Active__c) || (acr.D1_Roles__c != oldACRItems.get(acr.Id).D1_Roles__c)))){
                   accIdSet.add(acr.AccountId);
                   if(conSoldToMap.containsKey(acr.ContactId)){
                       conSoldToMap.get(acr.ContactId).add(acr);
                   }else{
                       conSoldToMap.put(acr.ContactId, new List<AccountContactRelation>{acr});
                   }
               }
        }
        
        //Get Related Ship-To
        if(!accIdSet.isEmpty()){
            for(PNR_Partner_Function__c pnr : [SELECT Id, PNR_Sold_To__c, PNR_Customer_No__c, PNR_Type__c FROM PNR_Partner_Function__c 
                                               WHERE PNR_Sold_To__c IN :accIdSet AND PNR_Type__c = 'Ship-To' ORDER BY PNR_Sold_To__c])
            {
                if(soldToShipToMap.containsKey(pnr.PNR_Sold_To__c)){
                    soldToShipToMap.get(pnr.PNR_Sold_To__c).add(pnr.PNR_Customer_No__c);
                }else{
                    soldToShipToMap.put(pnr.PNR_Sold_To__c, new Set<Id>{pnr.PNR_Customer_No__c});
                }
                shipToIdSet.add(pnr.PNR_Customer_No__c);
            }
        }
        
        if(!shipToIdSet.isEmpty()){
            //Get Existing ACR for Ship-To's 
            for(AccountContactRelation acr : [SELECT Id, ContactId, AccountId, D1_Active__c, D1_Roles__c, D1_User_Role__c FROM AccountContactRelation WHERE ContactId IN :conSoldToMap.keySet() AND AccountId IN :shipToIdSet]){
                string key = acr.ContactId + '_' + acr.AccountId;
                existingShipToACRMap.put(key, acr);
            }
            
            //sync ACR Details from Sold-To to Ship-To
            for(Id conId : conSoldToMap.keySet()){
                List<AccountContactRelation> soldToIdACRList = conSoldToMap.get(conId);
                
                //Get related Ship-To from soldToShipToMap where key is sold-to id
                for(AccountContactRelation acr : soldToIdACRList){
                    if(!soldToShipToMap.isEmpty() && soldToShipToMap.containsKey(acr.AccountId)){
                        Set<Id> shipToIds = soldToShipToMap.get(acr.AccountId);
                        
                        for(Id shipToId : shipToIds){
                            //If Sold-To & Ship-To are different than only sync ACR otherwise skip bcoz its same Account, Contact, ACR
                            if(acr.AccountId != shipToId){
                                //if ACR exist than update, else create new ACR
                                string key = conId + '_' + shipToId;
                                if(existingShipToACRMap != null && existingShipToACRMap.containsKey(key)){
                                    acrList.add(updateACR(existingShipToACRMap.get(key), acr));
                                }else{
                                    acrList.add(createACR(acr, shipToId));
                                }
                            }
                        }
                    }
                }
            }
        }
        
        if(!acrList.isEmpty()){
            upsert acrList;
        }
    }
    
    /**
* @description : Method to create instance of AccountContactRelation
* NCP-5143
*/
    public static AccountContactRelation createACR(AccountContactRelation acr, Id shipToId){
        AccountContactRelation newACR = new AccountContactRelation();
        newAcr.ContactId = acr.ContactId;
        newACR.AccountId = shipToId;
        newACR.D1_Active__c = acr.D1_Active__c;
        newACR.D1_Roles__c = acr.D1_Roles__c;
        newACR.D1_User_Role__c = acr.D1_User_Role__c;
        
        return newACR;
    }
    
    /**
* @description : Method to update instance of AccountContactRelation
* NCP-5143
*/
    public static AccountContactRelation updateACR(AccountContactRelation existingACR, AccountContactRelation acr){
        existingACR.D1_Active__c = acr.D1_Active__c;
        existingACR.D1_Roles__c = acr.D1_Roles__c;
        existingACR.D1_User_Role__c = acr.D1_User_Role__c;
        
        return existingACR;
    }
    
    /**
* @description : Method to update D1 First order email check on contact
* @userStory NCP-6710
* @param newItems 
* @param oldItems 
*/
    public static void updateD1FirstOrderEmailCheck(Map<ID,SObject> newItems, Map<ID,SObject> oldItems){
        Map<Id,AccountContactRelation> newACRItems = (Map<Id,AccountContactRelation>) newItems;
        Map<Id,AccountContactRelation> oldACR;
        Set<Id> contactIdSet = new Set<Id>();
        Set<Id> orderAddedcontactIdSet = new Set<Id>();
        Set<Id> orderRemovedcontactIdSet = new Set<Id>();
        Set<Id> existingContact = new Set<Id>();
        Map<Id,Boolean> contactRoleMap = new Map<Id,Boolean>();
        List<Contact> toUpdateContact = new List<Contact>();
        
        //check oldItems for update scenario
        if(oldItems != null){
            oldACR =(Map<Id,AccountContactRelation>) oldItems;
        }
        
        for(AccountContactRelation acr : newACRItems.values()){
            AccountContactRelation oldACRItems;
            if(oldACR != null){
                oldACRItems = oldACR.get(acr.Id); 
            }
            
            if(((oldACRItems == null) || (oldACRItems!=null && oldACRItems.D1_Roles__c != acr.D1_Roles__c))){
                
                contactIdSet.add(acr.ContactId);
                
                Boolean isOrdering = (acr.D1_Roles__c != null && acr.D1_Roles__c.split(';').contains('Ordering')) ? TRUE : FALSE; 
                
                if(isOrdering){
                    orderAddedcontactIdSet.add(acr.ContactId);
                }
                
                if(oldACRItems != null && oldACRItems.D1_Roles__c!= null && (oldACRItems.D1_Roles__c.split(';').contains('Ordering'))){
                    if(!isOrdering ){
                        orderRemovedcontactIdSet.add(acr.contactId);
                    }
                }
            }
        }
        
        if(!contactIdSet.isEmpty()){
            for(AccountContactRelation acr : [SELECT ID,AccountId,D1_Roles__c,ContactId FROM AccountContactRelation WHERE ContactId IN : contactIdSet AND ID NOT IN : newACRItems.keyset() ORDER BY ContactId ]){
                Boolean isOrderingPresent = (acr.D1_Roles__c != null && acr.D1_Roles__c.split(';').contains('Ordering')) ? TRUE : FALSE;
                if(!existingContact.contains(acr.ContactId) && isOrderingPresent){
                    existingContact.add(acr.ContactId);
                }
            }
        }
        
        if(!orderRemovedcontactIdSet.isEmpty()){
            for(AccountContactRelation acr : [SELECT ID,AccountId,D1_Roles__c,ContactId FROM AccountContactRelation WHERE ContactId IN : orderRemovedcontactIdSet]){
                if(!existingContact.contains(acr.ContactId)){
                    contactRoleMap.put(acr.ContactId,FALSE);
                }
            }
        }
        
        if(!orderAddedcontactIdSet.isEmpty()){
            for(AccountContactRelation acr : [SELECT ID,AccountId,D1_Roles__c,ContactId FROM AccountContactRelation WHERE ContactId IN : orderAddedcontactIdSet]){
                if(!existingContact.contains(acr.ContactId)){
                    contactRoleMap.put(acr.ContactId,TRUE);
                }
            }
        }
        
        if(!contactRoleMap.isEmpty()){
            for(Contact con : [SELECT ID, D1_First_order_email_required__c FROM Contact WHERE ID IN : contactRoleMap.keyset()]){
                
                con.D1_First_order_email_required__c = contactRoleMap.get(con.Id);
                toUpdateContact.add(con);
                
            }
        }
        
        
        if(!toUpdateContact.isEmpty()){
            update toUpdateContact;
        }
        
    }
    
    /**
* @userStory : NCP-6835
* @description : Updates POS Order date on related Contact 
* @param newItems 
* @param oldItems 
*/    
    public static void updatePOSOrderDateOnContact(Map<ID,SObject> newItems, Map<ID,SObject> oldItems){
        Map<Id,AccountContactRelation> newACRMap =  (Map<Id,AccountContactRelation>) newItems;
        Set<Id> contactIdSet = new Set<Id>();
        Map<Id,AccountContactRelation> contactACRMap = new Map<Id,AccountContactRelation>();
        List<Contact> toUpdateContact = new List<Contact>();
        Map<Id,List<AccountContactRelation>> contactAllACRMap = new Map<Id,List<AccountContactRelation>>();
        
        
        Map<Id,AccountContactRelation> oldACRMap;
        if(oldItems != null){
            oldACRMap = (Map<Id,AccountContactRelation>) oldItems;
        }
        
        for(AccountContactRelation newACRItem : newACRMap.values()){
            AccountContactRelation oldACRItems;
            if(oldACRMap != null){
                oldACRItems = oldACRMap.get(newACRItem.Id); 
            }
            
            if(oldACRItems.Last_POS_Order_Date__c != newACRItem.Last_POS_Order_Date__c){
                contactIdSet.add(newACRItem.ContactId);
            }
        }
        
        if(!contactIdSet.isEmpty()){
            //Fetch all ACR related to Contact and sort asc with Account.Last_POS_Order_Date__c and keep the least value
            for(AccountContactRelation acr : [SELECT Id,Last_POS_Order_Date__c,AccountId,Account.name,Account.Last_POS_Order_Date__c,ContactId 
                                              FROM AccountContactRelation 
                                              WHERE ContactId IN : contactIdSet AND Last_POS_Order_Date__c != null
                                              AND D1_Roles__c INCLUDES('POS & Equipment Ordering') AND D1_Active__c = True
                                              ORDER BY ContactId ,Last_POS_Order_Date__c ASC]){
                                                  if(!contactACRMap.containsKey(acr.ContactId)){
                                                      contactACRMap.put(acr.ContactId,acr);
                                                  }
                                                  
                                                  if(contactAllACRMap.containsKey(acr.ContactId)){
                                                      contactAllACRMap.get(acr.ContactId).add(acr);
                                                  }
                                                  else{
                                                      contactAllACRMap.put(acr.ContactId,new List<AccountContactRelation>{acr});
                                                  }                                  
                                                  
                                              }
        }
        
        if(!contactACRMap.isEmpty()){
            for(Contact con : [SELECT Id, POS_Order_Date__c, POS_Order_Account_Name__c, POS_Order_Account_Id__c FROM Contact WHERE ID IN :contactACRMap.keySet()]){
                if(contactAllACRMap.containsKey(con.Id)){ 
                    if(contactAllACRMap.get(con.Id).size() == 1){
                        con.POS_Order_Date__c = contactACRMap.get(con.Id).Last_POS_Order_Date__c;
                        con.POS_Order_Account_Name__c = contactACRMap.get(con.Id).Account.Name;
                        con.POS_Order_Account_Id__c = contactACRMap.get(con.Id).AccountId;
                    }
                    else{
                        DateTime accountMinOrderDate = contactACRMap.get(con.Id).Last_POS_Order_Date__c;
                        //If the there exists any least order date on Account populate same on contact 
                        con.POS_Order_Date__c = accountMinOrderDate;
                        con.POS_Order_Account_Name__c = contactACRMap.get(con.Id).Account.Name;
                        con.POS_Order_Account_Id__c = contactACRMap.get(con.Id).AccountId;
                    }
                    toUpdateContact.add(con); 
                }                 
            }
        }
        
        if(!toUpdateContact.isEmpty()){
            Update toUpdateContact;
        }
    }
    
    /**
* @userStory : NCP-6835
* @description : Removal of POS related order details if POS permission removed
* @param newItems 
* @param oldItems 
*/ 
    public static void clearPOSOrderDetails(Map<ID,SObject> newItems, Map<ID,SObject> oldItems){
        Map<Id,AccountContactRelation> newACRItems = (Map<Id,AccountContactRelation>) newItems;
        Map<Id,AccountContactRelation> oldACR;
        Set<Id> posRemovedcontactIdSet = new Set<Id>();
        
        List<Contact> toUpdateContact = new List<Contact>();
        List<AccountContactRelation> toUpdateACR = new List<AccountContactRelation>();
        Map<Id,List<AccountContactRelation>> conACRMap = new Map<Id,List<AccountContactRelation>>();
        //Map<Id,Id> conAccountMap = new Map<Id,Id>();
        
        //check oldItems for update scenario
        if(oldItems != null){
            oldACR =(Map<Id,AccountContactRelation>) oldItems;
        }
        
        for(AccountContactRelation acr : newACRItems.values()){
            AccountContactRelation oldACRItems;
            if(oldACR != null){
                oldACRItems = oldACR.get(acr.Id); 
            }
            
            Boolean isPOSOrdering = (acr.D1_Roles__c != null && acr.D1_Roles__c.split(';').contains('POS & Equipment Ordering')) ? TRUE : FALSE; 
            
            if(oldACRItems != null && oldACRItems.D1_Roles__c!= null && (oldACRItems.D1_Roles__c.split(';').contains('POS & Equipment Ordering'))){
                if(!isPOSOrdering ){
                    posRemovedcontactIdSet.add(acr.contactId);
                    //Update Related ACR
                    AccountContactRelation acrRec = new AccountContactRelation(Id=acr.Id);
                    acrRec.Last_POS_Order_Date__c = null;
                    toUpdateACR.add(acrRec);
                }
            }
        }
        
        //For Fetching related ACR of contact to check if any other relation remains with POS permission
        if(!posRemovedcontactIdSet.isEmpty()){
            for(AccountContactRelation acr : [SELECT ID,Last_POS_Order_Date__c FROM AccountContactRelation 
                                              WHERE ID IN : posRemovedcontactIdSet 
                                              AND D1_Roles__c INCLUDES('POS & Equipment Ordering') 
                                              AND D1_Active__c = True]){
                                                  if(conACRMap.containsKey(acr.ContactId)){
                                                      conACRMap.get(acr.ContactId).add(acr);
                                                  }
                                                  else{
                                                      conACRMap.put(acr.ContactId,new List<AccountContactRelation>{acr});
                                                  }
                                              }
        }
        
        if(!posRemovedcontactIdSet.isEmpty()){
            for(Id conId : posRemovedcontactIdSet){
                if(!conACRMap.containsKey(conId)){
                    Contact con = new Contact(Id=conId);
                    con.POS_Order_Date__c = null;
                    con.POS_Order_Account_Name__c = '';
                    con.POS_Order_Account_Id__c = '';
                    toUpdateContact.add(con);
                }
            }
        }
        
        
        if(!toUpdateContact.isEmpty()){
            update toUpdateContact;
        }
        
        if(!toUpdateACR.isEmpty()){
            update toUpdateACR;
        }
        
    }
    
    public static void updateLastPOSOrderOnACR(Map<ID,SObject> newItems, Map<ID,SObject> oldItems){
        Map<Id,AccountContactRelation> newACRMap =  (Map<Id,AccountContactRelation>) newItems;
        Map<Id,AccountContactRelation> oldACRMap;
        if(oldItems != null){
            oldACRMap = (Map<Id,AccountContactRelation>) oldItems;
        }
        
        for(AccountContactRelation newACRItem : newACRMap.values()){
            AccountContactRelation oldACRItems;
            if(oldACRMap != null){
                oldACRItems = oldACRMap.get(newACRItem.Id); 
            }
            
            //Checking if earlier POS permission was not present
            Boolean isPOSOrdering = (oldACRItems.D1_Roles__c != null && oldACRItems.D1_Roles__c.split(';').contains('POS & Equipment Ordering')) ? TRUE : FALSE; 
            
            if(newACRItem != null && newACRItem.D1_Roles__c!= null && (newACRItem.D1_Roles__c.split(';').contains('POS & Equipment Ordering'))){ //Checking if POS is provided
                if(!isPOSOrdering && newACRItem.Last_POS_Order_Date__c == null ){
                    
                    newACRItem.Last_POS_Order_Date__c = System.now();
                }
            }
        }
        
    }
    /**
    * @userStory : CUS-212
    * @description : Reparenting of Ship-to account Contact with its sold-to account.
    * @param newItems 
    */ 
    public static void reParentingShipToContact(Map<ID,SObject> newItems){
        Map<Id,AccountContactRelation> newACRMap =  (Map<Id,AccountContactRelation>) newItems;
        Set<Id> accountIds = new  Set<Id>();
        Map<Id, String> contactAccountMap = new Map<Id, String>();
        Map<Id, Id > shipToSoldToMap = new Map<Id, Id >();
        List<Contact> contactListToUpdate = new List<Contact>();
        
        for(AccountContactRelation newACRItem : newACRMap.values()){
            if(newACRItem.IsDirect){
                accountIds.add(newACRItem.AccountId);
            }
        }
        for(Account acc : [SELECT Id, Direct_Customer__c, Account_Type__c FROM Account WHERE Id IN :accountIds]){
            if(acc.Direct_Customer__c){
                List<String> accountType = acc.Account_Type__c == null ? new List<String>() : acc.Account_Type__c.split(';');
                if(accountType.size() == 1 && accountType.contains('Ship-To')){
                    contactAccountMap.put(acc.Id , acc.Account_Type__c);
                }                     
            }
        }
        
        if(contactAccountMap != null){
            for(PNR_Partner_Function__c pf : [SELECT Id, PNR_Sold_To__c, PNR_Sold_To__r.D1_Account_Last_Login_Date__c, PNR_Sold_To__r.D1_Registration_Status__c, PNR_Customer_No__c FROM PNR_Partner_Function__c 
                                              WHERE PNR_Customer_No__c IN :contactAccountMap.keySet() AND PNR_Type__c = 'Ship-To'])
            {
                shipToSoldToMap.put(pf.PNR_Customer_No__c, pf.PNR_Sold_To__c);
            }
        }
        
       	for(AccountContactRelation newACRItem : newACRMap.values()){
            Contact contactRecd = new Contact(Id = newACRItem.ContactId );
            if(shipToSoldToMap != null && shipToSoldToMap.containsKey(newACRItem.AccountId) && newACRItem.IsDirect){
                contactRecd.AccountId = shipToSoldToMap.get(newACRItem.AccountId);
                contactListToUpdate.add(contactRecd);
            }
            
        } 
        if(contactListToUpdate.size()>0  && Schema.sObjectType.Contact.isUpdateable()){
            Database.update(contactListToUpdate,false);
        }
        
    }

   
}