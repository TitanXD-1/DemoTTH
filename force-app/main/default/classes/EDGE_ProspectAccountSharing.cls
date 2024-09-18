/**********************************************************************
Name: EDGE_ProspectAccountSharing 

=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0    Monalisa Halder 03/09/2019      ES20-4241 Sales force Sharing Rules for Prospect- Technical
***********************************************************************/
public without sharing class EDGE_ProspectAccountSharing {

    /*******************************************************************
    Method  : prospectSharingSalesManager
    Purpose : This methods used to create Prospect Sharing for Sales Manager
    ********************************************************************/  
    public static void prospectSharingSalesManager(List<Account> newItems){
        String prospectRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
        Set<Id> createdByUserIdSet = new Set<Id>();
        List<User> createdByUserList = new List<User>();
        Map<Id,Id> userManagerIdMap = new Map<Id,Id>();
        List<Outlet_Member__c> outletMemberList = new List<Outlet_Member__c>();
        List<AccountTeamMember> accountMembersList = new List<AccountTeamMember>();
        
        try{
            system.debug('@@newItems' +newItems);
            if(newItems != null && newItems.size()>0){
                for(Account newAccount : newItems){
                    if(newAccount.RecordTypeId == prospectRecordTypeId){
                        createdByUserIdSet.add(newAccount.CreatedById);
                     }
                }
            }
            //added isAccessible check for User object by Vikas
            if(Schema.SObjectType.User.isAccessible()){
            	createdByUserList = [Select Id, ManagerId from User where ManagerId != null AND Id IN :createdByUserIdSet];
            }
            if(createdByUserList != null && createdByUserList.size()>0){
                for(User u :createdByUserList){
                    userManagerIdMap.put(u.Id,u.ManagerId);
                }  
            }
            
            //Create outlet member records with outlet role 'Sales Manager'
            for(Account objAccount : newItems){
                if(objAccount.RecordTypeId == prospectRecordTypeId && !userManagerIdMap.isEmpty()){
                    Outlet_Member__c outletMemberRec = new Outlet_Member__c();
                    outletMemberRec.Outlet__c = objAccount.Id;
                    outletMemberRec.User__c = userManagerIdMap.get(objAccount.CreatedById);
                    outletMemberRec.Outlet_Role__c = 'Sales Manager'; 
                    outletMemberRec.OutletUser__c = userManagerIdMap.get(objAccount.CreatedById) + '-' + objAccount.Id;
                    outletMemberList.add(outletMemberRec);
                }
            }
            
            if(outletMemberList != null && outletMemberList.size()>0){
                system.debug('@@outletMemberList' +outletMemberList);
                Database.insert(outletMemberList,false);
                
            }
            //Create account team member records for each user in outlet member and create Account Share
            if(outletMemberList.size()>0 ){
                EDGE_OutletMemberAccountTeamSync.createAccountTeamMembers(outletMemberList);
            }
            
            
          
        } catch (Exception prospectException){
            System.debug('Exception:::'+prospectException.getLineNumber()+prospectException.getMessage()+prospectException.getCause());
            new EDGE_GenericException(prospectException, newItems[0]);
        }
    }
}