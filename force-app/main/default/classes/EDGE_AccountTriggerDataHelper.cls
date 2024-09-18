/**
  *@ description : EDGE_AccountTriggerDataHelper
  *@ Req: ES20-6372,8444 : When an outlet is closed, data update in closed outlet, delete/update related contacts, delete account contact relationship
* @History:                                                            
                                                          
* @VERSION   AUTHOR              DATE              DETAIL                                                           

* 1.0		Shahbaz Khan		31/08/2020		 ES20-8444 - method ->manageContactsOfClosedOutlet()
* 1.1		Monalisa Halder		31/08/2020		 ES20-6372- method ->manageContactsOfClosedOutlet()
* 1.2		Monalisa Halder		03/12/2020		 ES20-9080- method ->createAccTeamMemberOnProspectConversion()
* 1.3     Dinesh Sharma       25/01/2021       ES20-9437 -(updateAccountStatusToClose) To Update Account Status to Close once
                                                         Deletion_Flag_from_SAP__c flag is checked
* 1.4     Supriya             20/06/2022       ES20-12974 -(checkAccountContactRel) To assign Outlet to Contact when Parent Outlet is closed and
														  assign ACR role to contact's Current Role
**/

public  without sharing class EDGE_AccountTriggerDataHelper {
    final static String outletRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
    final static String prospectRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Prospect').getRecordTypeId(); 
    final static List<Market_Setting__c> marketSettingsList = [SELECT Id, Geography__c, Geography__r.Code__c, Prospect_Approver__c, Local_Segmentation_Validation__c,Local_Segmentation2_Validation__c, Auto_Add_to_Territory__c, Default_Outlet_Visit_Prioritisation__c,Default_Reserve_Visit_Prioritisation__c,Market_Account_Owner__c FROM Market_Setting__c ];
 
    
    /**
	  *@ Method : manageContactsOfClosedOutlet
	  *@ To manage Contacts and Account Contact Relationship of Closed Outlet
	**/
    public static void manageContactsOfClosedOutlet(List<Account> newItems, Map<Id, SObject> oldItems){
        List<AccountContactRelation> accConRelListToDelete = new List<AccountContactRelation>();
        List<Contact> conListWithNoRel = new List<Contact>();
        List<Contact> conListToUpdate = new List<Contact>();
        List<Contact> sendEmailContactList = new List<Contact>();
        List<Contact> conListToDelete = new List<Contact>();
        Set<Id> outletIdSet = new Set<Id>();
        Set<Id> contactIdSet = new Set<Id>();
        Set<Id> contactIdVSet = new Set<Id>();
        Set<Id> contIdSetWithNoRelVer = new Set<Id>();
        Set<Id> contactIdAccUpdateSet = new Set<Id>();
        Set<Id> contactIdToRemoveSet = new Set<Id>();
        Set<Id> countryIdSet = new Set<Id>();
        Map<Id,Id> contactWithActiveComm = new Map<Id,Id>();
        Map<Id,Contact> contactItemMap = new Map<Id,Contact>();
        Map<Id,Account> oldItemMap = (Map<Id,Account>)oldItems;
        
        
        try{
            if(!EDGE_UtilityClass.stopTriggerToRunOutlet){
                if(!Test.isRunningTest()){
                EDGE_UtilityClass.stopTriggerToRunOutlet = True;
                }
                for(Account accRec : newItems){
                    system.debug('Inside Email loop');
                     system.debug('Map Value: '+oldItemMap);
                    //Updating account fields, when outlet is closed
                    if(oldItemMap!=null && accRec.Status__c == 'Closed' && accRec.Status__c != oldItemMap.get(accRec.Id).Status__c && accRec.RecordTypeId == outletRecordTypeId){
                        system.debug('Inside if Statement : ');
                        accRec.Outlet_Email_Address__c = 'closed@outlet.com';
                        accRec.PhonePrefix__c = '';
                        accRec.Phone__c = '';
                        accRec.Phone = '';
                        accRec.MobilePrefix__c = '';
                        accRec.Mobile__c = '';
                        outletIdSet.add(accRec.Id);
                        countryIdSet.add(accRec.Country__c);
                    }
                }
                
                if(outletIdSet!=null && outletIdSet.size()>0){
                    for(AccountContactRelation accConRel : [SELECT Id,ContactId,Contact.AccountId,AccountId,Contact_Type__c FROM AccountContactRelation WHERE AccountId IN :outletIdSet]){
                        //Preparing list account contact relationship records to be deleted
                        accConRelListToDelete.add(accConRel);                       
                        contactIdSet.add(accConRel.ContactId);                       
                        contactIdVSet.add(accConRel.ContactId);                       
                        //if the outlet which is being closed, is the parent of the contact, putting in a set
                        if(accConRel.Contact.AccountId == accConRel.AccountId){
                            contactIdAccUpdateSet.add(accConRel.ContactId); 
                        }
                    }
                    
                    if(contactIdSet!=null){
                        //changing the contact type and account id in the contacts , if the parent account is being closed
                        contactWithActiveComm = checkForCommUser(contactIdSet);
                        contIdSetWithNoRelVer = checkAccountContactRel(contactIdVSet,outletIdSet,contactIdAccUpdateSet,contactItemMap);
                    } 
                    
                           // Added Schema.sObjectType.Contact.isAccessible() --by Divya            
                    if(contactIdSet!=null || contIdSetWithNoRelVer!= null && Schema.sObjectType.Contact.isAccessible()){
                        
                        //Check if any community user exists
                        conListWithNoRel = [SELECT Id,Name,AccountId,Pending_Deletion__c,Account.Country__c,Account.Name,Contact_Type__c FROM Contact WHERE Id IN :contactIdSet];
                        for(Contact contRec : conListWithNoRel){
                            if(contactWithActiveComm.containsKey(contRec.Id) && contactWithActiveComm.get(contRec.Id)!=null){
                                contRec.Pending_Deletion__c = TRUE;
                                //adding the contact id to remove the related account contact relation records from the accConRelListToDelete list
                                sendEmailContactList.add(contRec);
                                conListToUpdate.add(contRec);
                                if(contactItemMap.get(contRec.Id) != null){
                                    Contact contact = contactItemMap.get(contRec.Id);
                                    contRec.AccountId = contact.AccountId;
                                    //contRec.Contact_Type__c = contact.Contact_Type__c;
                                    contactItemMap.put(contRec.Id, contRec);
                                }
                                else{
                                    contactItemMap.put(contRec.Id, contRec);
                                }
                            }
                            else if(contIdSetWithNoRelVer.contains(contRec.Id)){
                                //adding the contact id to remove the related account contact relation records from the accConRelListToDelete list
                                contactIdToRemoveSet.add(contRec.Id);
                                conListToDelete.add(contRec);                                   
                            }   
                            //To remove contact Ids , where contact with community user associated with single outlet
                            if(contactWithActiveComm.containsKey(contRec.Id) && contIdSetWithNoRelVer.contains(contRec.Id)){
                                contactIdToRemoveSet.add(contRec.Id);                               
                            }
                        }
                        /*remove the contactIdToRemoveSet related account contact relation records from the accConRelListToDelete list - start*/
                        List<AccountContactRelation> accConRelRemoveFromDeleteList = new List<AccountContactRelation>();
                        for(AccountContactRelation accContact : accConRelListToDelete){
                            if(!contactIdToRemoveSet.contains(accContact.ContactId)){                                
                                accConRelRemoveFromDeleteList.add(accContact);                                
                            }    	
                        }
                        accConRelListToDelete = accConRelRemoveFromDeleteList;
                        /* remove the contactIdToRemoveSet related account contact relation records from the accConRelListToDelete list -end*/
                    }
                }
              if(sendEmailContactList!=null && sendEmailContactList.size()>0){
                    sendEmailToMDM(sendEmailContactList,countryIdSet,contactWithActiveComm);  
                }
                
                conListToUpdate = contactItemMap.values();
                
                //update contacts;
                if(conListToUpdate!=null && conListToUpdate.size()>0 && Schema.sObjectType.Contact.isUpdateable()){                    
                    Database.update(conListToUpdate,true);
                }
                
                //delete contacts; 
                if(conListToDelete!=null && conListToDelete.size()>0){
                    system.debug('@@conListToDelete' +conListToUpdate);
                    Database.delete(conListToDelete,true);
                }    
                
                //delete accConRelListToDelete; 
                if(accConRelListToDelete != null && accConRelListToDelete.size()>0 && Schema.sObjectType.AccountContactRelation.isDeletable()){
                    
                    database.delete(accConRelListToDelete,true);    
                }
                
            }
        }catch(Exception ex){
            System.debug('Exception:::'+ex.getLineNumber()+ex.getCause()+ex.getMessage());
            
        }   
    }
    
    //changing the contact type and account id in the contacts , if the parent account is being closed
    public static Set<Id> checkAccountContactRel(Set<Id> contactIdVSet, Set<Id> outletIdSet,Set<Id> contactIdAccUpdateSet,Map<Id,Contact> contactItemMap){
         Set<Id> contIdSetWithNoRel =  contactIdVSet;
         Map<Id,Id> contWithAccIdMap = new Map<Id,Id>();
        
         Set<Id> contIdSetWithOtherRel = new Set<Id>();
        Map<Id,String> contWithRoleMap = new Map<Id,String>(); //ES20-12974
         for(AccountContactRelation accConRel : [SELECT Id,ContactId,AccountId,Contact.AccountId,Roles,CreatedDate FROM AccountContactRelation WHERE ContactId IN :contactIdVSet AND AccountId NOT IN :outletIdSet AND Account.Status__c != 'Closed' ORDER BY CreatedDate DESC]){
                contIdSetWithOtherRel.add(accConRel.ContactId);
          
            contIdSetWithNoRel.remove(accConRel.ContactId); 
            contWithAccIdMap.put(accConRel.ContactId,accConRel.AccountId);
             contWithRoleMap.put(accConRel.ContactId,accConRel.Roles); //ES20-12974
             system.debug('account Role'+accConRel.Roles);
        }
        
        if(contIdSetWithOtherRel!=null && contIdSetWithOtherRel.size()>0){
            for(Contact contRec : [SELECT Id,Name,AccountId,MD_CurrentRole__c FROM Contact WHERE Id IN :contIdSetWithOtherRel]){
               
                if(contactIdAccUpdateSet.contains(contRec.Id) && contWithAccIdMap.containsKey(contRec.Id)){
                    contRec.AccountId = contWithAccIdMap.get(contRec.Id);
                    String roles = contWithRoleMap.get(contRec.Id);
                    //ES20-12974
                    if(String.isNotBlank(roles)) {
                        List<String> acrRoles = roles.split(';'); 
                        contRec.MD_CurrentRole__c = acrRoles[0];
                    } else
                    {
                        contRec.MD_CurrentRole__c = null;
                    }
                }
                contactItemMap.put(contRec.Id, contRec);
            }
            
        }
        return contIdSetWithNoRel;
    } 
    
    //Check if any community user exists
    public static Map<Id,Id> checkForCommUser(Set<Id> contactIdSet){
        Map<Id,Id> contactWithActiveComm = new Map<Id,Id>();
        for(User user : [SELECT Id,ContactId,Contact.AccountId FROM User WHERE ContactId IN :contactIdSet AND IsActive = TRUE AND UserType != 'Standard']){
            contactWithActiveComm.put(user.ContactId,user.Id);
        }
        return contactWithActiveComm;
    }
    
    //sending email to MDM with the list of contact records which is marked true for the field 'Pending for Deletion'
    public static void sendEmailToMDM(List<Contact> conListToSoftDelete,Set<Id> countryIdSet,Map<Id,Id> contactWithActiveComm){
        Set<String> queueStrSet = new Set<String>();
        Set<String> userIdSet = new Set<String>();
        Map<Id,String> countryCodeMap = new Map<Id,String>();
        Map<String,List<Id>> queueUserMap = new Map<String,List<Id>>();
        Map<Id,String> userWithEmailMap = new Map<Id,String>();
        Map<String,List<Contact>> countryWiseContacts = new Map<String,List<Contact>>();
        List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>();
        //Fetching country code from geography
        for(Geography__c country : [SELECT Id,Name,Code__c FROM Geography__c WHERE Id IN :countryIdSet]){
            countryCodeMap.put(country.Id,country.Code__c); 
           
        }
        //Preparing MDM Queue Name using Country Code fetched from above in order to use it for filter
        for(Id countryId : countryCodeMap.keyset()){
            String tempStr ='';
            tempStr += countryCodeMap.get(countryId)+'_MDM' ;
            queueStrSet.add(tempStr);
        }
        system.debug('queueStrSet'+queueStrSet);
        //retrieve the relevant MDM Queue and store in Map of Queue Name along with its list of Users(Queue Members)
        if(queueStrSet.size()>0){
            for(GroupMember grpMem : [SELECT Group.Name,UserOrGroupId FROM GroupMember WHERE Group.type='Queue' AND Group.Name IN: queueStrSet]){
                if(queueUserMap.containsKey(grpMem.Group.Name)){
                    queueUserMap.get(grpMem.Group.Name).add(grpMem.UserOrGroupId);
                }
                else{
                    queueUserMap.put(grpMem.Group.Name,new List<Id>{grpMem.UserOrGroupId});
                }
                //Store the set of User Ids to fetch its email address
                UserIdSet.add(grpMem.UserOrGroupId);
            }
            //Store email ids of Users with respect to its user Id 
            for(User user : [SELECT Id,Name,Email FROM User WHERE Id IN :UserIdSet AND Email!=null]){
                userWithEmailMap.put(user.Id,user.Email);
            } 
        }
        //Align Contact List with respect to their Account's Country hence Map with Queue Name with its list of Contacts framed
        for(Contact contRec : conListToSoftDelete){
            if(!countryWiseContacts.containsKey(countryCodeMap.get(contRec.Account.Country__c)+'_MDM')){
                countryWiseContacts.put(countryCodeMap.get(contRec.Account.Country__c)+'_MDM',new List<Contact>{contRec});
            }else{
                countryWiseContacts.get(countryCodeMap.get(contRec.Account.Country__c)+'_MDM').add(contRec);
            }
        }
        //Send Email to Members of specific queue containing contact details consolidated in a single mail
        if(queueUserMap!=null){
            for(String mdmQueue : queueUserMap.keySet()){
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                List<String> emailIds = new List<String>();
                	//retrieve email ids of all users who are member of this queue
                    for(Id userId : queueUserMap.get(mdmQueue)){
                        if(userWithEmailMap.containsKey(userId) && userWithEmailMap.get(userId)!=null){
                        emailIds.add(userWithEmailMap.get(userId));
                        }
                    }
                
                mail.setToAddresses(emailIds);
                mail.setSubject('Contacts with active community user require deletion');
                if(countryWiseContacts.containsKey(mdmQueue)){
                    //Create Email body by sending list of Contact details belonging to same Country as Queue(Contact details fetched from countryWiseContacts Map)
                    mail.setHtmlBody(EDGE_UtilityClass.getMailBodyForMDM(countryWiseContacts.get(mdmQueue), contactWithActiveComm));
                }
                mailList.add(mail);                
            }
            
           List<Messaging.SendEmailResult> results = Messaging.sendEmail(mailList);
           system.debug('Email Results '+results);
        }    
    }  
    /*******************************************************************
    Method  : createAccTeamMemberOnProspectConversion
    Purpose : To automatically add outlet to sales rep's Territory.
    ********************************************************************/ 
    public static void createAccTeamMemberOnProspectConversion(Map<Id, SObject> newItems, Map<Id, SObject> oldItems, List<AccountTeamMember> exisAccountMembersList){
    	List<AccountTeamMember> accountMembersList = new List<AccountTeamMember>();
		for(AccountTeamMember accTeamMember :exisAccountMembersList){             
            //Create account team member records for the propects converted to outlets
            AccountTeamMember newAccTeamMember = new AccountTeamMember();
            newAccTeamMember.AccountId = accTeamMember.AccountId;
            newAccTeamMember.UserId = accTeamMember.UserId;
            newAccTeamMember.TeamMemberRole = accTeamMember.TeamMemberRole;
            newAccTeamMember.AccountAccessLevel = accTeamMember.AccountAccessLevel;
            newAccTeamMember.OpportunityAccessLevel = accTeamMember.OpportunityAccessLevel;
            newAccTeamMember.ContactAccessLevel = accTeamMember.ContactAccessLevel;
            newAccTeamMember.CaseAccessLevel = accTeamMember.CaseAccessLevel;
            accountMembersList.add(newAccTeamMember);
        }
        //create Account Share
        if(accountMembersList.size() > 0 && Schema.sObjectType.AccountTeamMember.isCreateable()){
            system.debug('@@accountMembersList' +accountMembersList);
            insert accountMembersList;
        }
    }
    
    /**
      *@ Method : updateAccountStatusToClose
      *@ To Update Account Status to Close once Deletion_Flag_from_SAP__c flag is checked
    **/
    public static void updateAccountStatusToClose(List<SObject> newItems,Map<Id,SObject> oldItems){
        list<Account> newRecordList = (list<Account> )newItems;
        Map<id,Account> oldRecordMap = (Map<id,Account>)oldItems;
        
        if(newRecordList.size()>0){
            
            for(Account acc : newRecordList){
                if(acc.RecordTypeId == outletRecordTypeId){
                    if(acc.Deletion_Flag_from_SAP__c == true && oldRecordMap.get(acc.Id).Deletion_Flag_from_SAP__c != acc.Deletion_Flag_from_SAP__c
                       && oldRecordMap.get(acc.Id).Status__c != 'Closed' ){
                           acc.Status__c = 'Closed';
                       }
                }
            }
        }
    }
    
   /** 
    *@  Method : prospectApprovalProcess  
    *@  Req :  ES20-9409
    *@  Based on Market settings it will update Approver 1/2/3 fields and Current/Next approval Steps
    **/    
      public static void prospectApprovalProcess(List<Account> newItems){
        //Variables
        List<Account> lstProspectAccount = new List<Account>();
        Set<Id> setCountryId = new Set<Id>();
        Set<String> setCountryCode = new Set<String>();
        Map<Id,String> mapcountryCode = new Map<Id,String>();
        Map<Id,Market_Setting__c> mapMarketSetting =  new Map<Id,Market_Setting__c>();
        Set<String> setUserId = new Set<String>(); 
        Map<String,List<String>> mapSalesmembers = new Map<String,List<String>>();
        List<String> listActiveUserId = new List<String>();
        Map<string, List<string>> activeQueueMemberMap = new Map<string, List<string>>();
        
        try{
            for(Account newAccount : newItems){
                if(newAccount.RecordTypeId == prospectRecordTypeId){
                    lstProspectAccount.add(newAccount);
                    setCountryId.add(newAccount.Country__c);
                }
            }
            
            if(setCountryId != null && setCountryId.size() > 0){
                for(Geography__c geographyObj : [SELECT Id, MDM_Queue__c, Code__c from Geography__c where Id IN :setCountryId]){
                    setCountryCode.add(geographyObj.MDM_Queue__c);
                    mapcountryCode.put(geographyObj.Id, geographyObj.MDM_Queue__c);
                }
                
                //Fetching respective market settings data
                for(Market_Setting__c marketSettings : marketSettingsList){
                    mapMarketSetting.put(marketSettings.Geography__c, marketSettings);
                }
            }
            
            //Fetching respective queue members
            if(setCountryCode.size() > 0){        
                for(GroupMember sgm : [SELECT Group.Name, UserOrGroupId, GroupId FROM GroupMember WHERE group.name LIKE :setCountryCode and group.type='Queue']){
                    setUserId.add(sgm.UserOrGroupId);
                    if(mapSalesmembers.containsKey(sgm.Group.Name)){
                        List<String> grpMemList = mapSalesmembers.get(sgm.Group.Name);
                        grpMemList.add(sgm.UserOrGroupId);
                        mapSalesmembers.put(sgm.Group.Name, grpMemList);
                    } else {
                        mapSalesmembers.put(sgm.Group.Name, new List<String> {sgm.UserOrGroupId });
                    }
                }  
            } 
            
            //Taking only active users from the list of queue members
            for(User usr :[SELECT Id, isActive FROM User WHERE Id IN :setUserId AND isActive = True]){
                listActiveUserId.add(usr.Id);   
            }
            
            //Iterate over mapSalesmembers to get only active member list
            if(mapSalesmembers.size()>0){
                for(string queueName : mapSalesmembers.keySet()){
                    List<String> approverList =  mapSalesmembers.get(queueName);
                    List<String> activeApproverist = new List<String>();
                    if(listActiveUserId != null && listActiveUserId.size()>0){
                        for(Integer i = 0; i < approverList.size(); i++){
                            if(listActiveUserId.contains(approverList.get(i))){
                                activeApproverist.add(approverList.get(i));
                            } 
                        }
                        activeQueueMemberMap.put(queueName, activeApproverist);
                    }
                }
            }
            
            //Iterating over newly inserted prospect account to populate approver 1/2/3 fields and current/Next approval Steps
            for(Account newAccount : lstProspectAccount){
                if(mapMarketSetting != null && mapMarketSetting.containsKey(newAccount.Country__c)){
                    Market_Setting__c marketSetting = mapMarketSetting.get(newAccount.Country__c);
                    String countryQueueName = '';
                    if(mapcountryCode != null && mapcountryCode.containsKey(newAccount.Country__c)){
                        countryQueueName = mapcountryCode.get(newAccount.Country__c);
                    }
                    
                    if(marketSetting.Prospect_Approver__c != null && 
                       (((marketSetting.Prospect_Approver__c).equalsIgnoreCase(Label.Prospect_MDM_Approval)) ||((marketSetting.Prospect_Approver__c).equalsIgnoreCase(Label.Prospect_MDM_Sales_Approval)))) 
                    {
                        if(activeQueueMemberMap!=null && activeQueueMemberMap.containsKey(countryQueueName)){
                            List<String> activeApproverist =  activeQueueMemberMap.get(countryQueueName);
                            
                            if(activeApproverist != null && activeApproverist.size()>0){
                                newAccount.Approver_1__c = activeApproverist[0];
                                newAccount.Approver_2__c =  activeApproverist[0];
                                newAccount.Approver_3__c =  activeApproverist[0];
                                if(activeApproverist.size() == 2){
                                    newAccount.Approver_2__c =  activeApproverist[1];
                                } else if(activeApproverist.size() > 2){
                                    newAccount.Approver_2__c =  activeApproverist[1];
                                    newAccount.Approver_3__c =  activeApproverist[2];
                                }
                            }
                        }
                        
                        if((marketSetting.Prospect_Approver__c).equalsIgnoreCase(Label.Prospect_MDM_Sales_Approval)){
                            newAccount.Current_Approval_Step__c = 'Sales Manager Approval Required';
                            newAccount.Next_Approval_Step__c = 'MDM Approval Required';
                        } else {
                            newAccount.Current_Approval_Step__c = 'MDM Approval Required';
                        }   
                    } else if(marketSetting.Prospect_Approver__c != null && (marketSetting.Prospect_Approver__c).equalsIgnoreCase(Label.Prospect_Sales_Manager_Approval)){
                        newAccount.Current_Approval_Step__c = 'Sales Manager Approval Required';
                    }
                }
            }
        }
        
        catch(Exception accountException){
            new EDGE_GenericException(accountException, newItems[0]);
        }
      }
    
}