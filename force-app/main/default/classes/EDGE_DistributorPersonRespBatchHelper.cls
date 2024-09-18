/********************************************************************************************
Class Name: EDGE_DistributorPersonRespBatchHelper

Author              Version       Date           Detail
Shahbaz Khan        V1.0        10/11/2020     [ES20-8661]
Monalisa Halder     V1.1        13-Nov-2020     ES20-8662 
*********************************************************************************************/
public without sharing class EDGE_DistributorPersonRespBatchHelper {
    public static void createAndDeleteTeamMembers(List<Account> distList){
        Set<Id> outletIds = new Set<Id>();
        Map<Id,Account> distributorMap = new Map<Id,Account>();
        Map<Id,Set<Id>> distributorWithUserIdMap = new Map<Id,Set<Id>>();
        Map<Id,List<Id>> distributorWithOutletsIdMap = new Map<Id,List<Id>>();
        Map<Id,Set<AccountTeamMember>> outletWithAccTeamMap = new Map<Id,Set<AccountTeamMember>>();
        Map<Id,Set<Id>> outletWithdistributorRespIdMap = new Map<Id,Set<Id>>();
        List<AccountTeamMember> accountMembersList = new List<AccountTeamMember>();
        List<AccountTeamMember> accTeamMemberToDelete = new List<AccountTeamMember>();
        
        system.debug('@@distList '+distList);
        for(Account accObj : distList){
            accObj.Pending_for_Distributor_Batch__c = false;
            distributorMap.put(accObj.Id,accObj);
            Set<Id> userSetId = addValues(accObj.Person_Responsible__c,accObj.Person_Responsible_2__c,accObj.Person_Responsible_3__c);
            distributorWithUserIdMap.put(accObj.Id,userSetId);
        }
        
        for(Supplier_Outlet__c suppOutlet : [SELECT Id,Distributor_Wholesaler__c,Outlet__c FROM Supplier_Outlet__c WHERE Distributor_Wholesaler__c IN:distributorMap.keySet() AND Outlet__r.Status__c = 'Active']){
            outletIds.add(suppOutlet.Outlet__c);
            if(!distributorWithOutletsIdMap.containsKey(suppOutlet.Distributor_Wholesaler__c)){
                distributorWithOutletsIdMap.put(suppOutlet.Distributor_Wholesaler__c,new List<Id>{suppOutlet.Outlet__c});
            }
            else{
                distributorWithOutletsIdMap.get(suppOutlet.Distributor_Wholesaler__c).add(suppOutlet.Outlet__c);
            }
        }
        system.debug('@@distributorWithOutletsIdMap '+distributorWithOutletsIdMap);
        //store users of distributors related to specific outlet
        for(Supplier_Outlet__c suppOutlet : [SELECT Id,Distributor_Wholesaler__c,Outlet__c,Distributor_Wholesaler__r.Person_Responsible__c,Distributor_Wholesaler__r.Person_Responsible_2__c,
                                             Distributor_Wholesaler__r.Person_Responsible_3__c FROM Supplier_Outlet__c WHERE Outlet__c IN:outletIds AND Outlet__r.Status__c = 'Active'])
        {
            Set<Id> userSetId = addValues(suppOutlet.Distributor_Wholesaler__r.Person_Responsible__c,suppOutlet.Distributor_Wholesaler__r.Person_Responsible_2__c,
                                              suppOutlet.Distributor_Wholesaler__r.Person_Responsible_3__c);
            if(!outletWithdistributorRespIdMap.containsKey(suppOutlet.Outlet__c)){                
                outletWithdistributorRespIdMap.put(suppOutlet.Outlet__c,userSetId);
            }
            else{
                outletWithdistributorRespIdMap.get(suppOutlet.Outlet__c).addAll(userSetId);
            }
        }
        //store existing team members outlet wise
        for(AccountTeamMember accTeamMem : [SELECT Id,UserId,AccountId FROM AccountTeamMember WHERE AccountId IN:outletIds AND TeamMemberRole = 'Distributor Responsible']){
            if(!outletWithAccTeamMap.containsKey(accTeamMem.AccountId)){
                outletWithAccTeamMap.put(accTeamMem.AccountId,new Set<AccountTeamMember>{accTeamMem});
            }
            else{
                outletWithAccTeamMap.get(accTeamMem.AccountId).add(accTeamMem);
            }
        }//create New Team Member
        accountMembersList = createAccountTeamMember(distributorMap.keySet(), distributorWithOutletsIdMap, distributorWithUserIdMap);
       
        //to remove previous Team Member
        for(Id outletId : outletWithAccTeamMap.keySet()){
            for(AccountTeamMember existingTeamMember : outletWithAccTeamMap.get(outletId)){
                if(outletWithdistributorRespIdMap.containsKey(outletId)){
                    if(!outletWithdistributorRespIdMap.get(outletId).contains(existingTeamMember.UserId)){
                        accTeamMemberToDelete.add(existingTeamMember);
                    }
                    
                }
            }
            
        }
        system.debug('accTeamMemberToDelete '+accTeamMemberToDelete);
        if(accTeamMemberToDelete!=null && accTeamMemberToDelete.size()>0){
            Database.delete(accTeamMemberToDelete);
        }
        if(accountMembersList!=null && accountMembersList.size()>0){
            Database.insert(accountMembersList);
            
        }
        Database.update(distributorMap.values());
        
    }
    
    /*******************************************************************
	Method  : insertAccountTeamMember
	Purpose : ES20-8662(Added by Amar)
********************************************************************/  
    public static void insertAccountTeamMember(List<Supplier_Outlet__c> suppOutltList){
        Set<Id> distributorSetIds = new set<Id>();
        Map<Id,List<Id>> outletDistributorMap = new Map<Id,List<Id>>();
        Map<Id,Set<Id>> distributorUserMap = new Map<Id,set<Id>>();
        List<AccountTeamMember> accountMembersList = new List<AccountTeamMember>();
        
        for(Supplier_Outlet__c suppOutObj : suppOutltList){
            if(suppOutObj.Distributor_Wholesaler__c != null && suppOutObj.Outlet__c != null){
                distributorSetIds.add(suppOutObj.Distributor_Wholesaler__c);
                if(!outletDistributorMap.containsKey(suppOutObj.Distributor_Wholesaler__c)){
                    outletDistributorMap.put(suppOutObj.Distributor_Wholesaler__c,new List<Id>{suppOutObj.Outlet__c});
                }else{
                    outletDistributorMap.get(suppOutObj.Distributor_Wholesaler__c).add(suppOutObj.Outlet__c);
                }
            }
        }
        for( Account distributorAccount : [SELECT Id,Person_Responsible__c,Person_Responsible_2__c,Person_Responsible_3__c FROM Account WHERE ID IN :outletDistributorMap.keyset()]){
            distributorUserMap.put(distributorAccount.ID,new set<Id>{distributorAccount.Person_Responsible__c,distributorAccount.Person_Responsible_2__c,distributorAccount.Person_Responsible_3__c});
        }
        accountMembersList = createAccountTeamMember(distributorSetIds,outletDistributorMap,distributorUserMap);
        
        if(accountMembersList!=null && accountMembersList.size()>0){
            Database.insert(accountMembersList);
        }
    }
    /*******************************************************************
	Method  : createAccountTeamMember
	Purpose : ES20-8662(Added by Amar)
********************************************************************/  
    public static List<AccountTeamMember> createAccountTeamMember(Set<Id> distributorIds,Map<Id,List<Id>> outletDistributorMap,Map<Id,Set<Id>> distributorUserMap){
        List<AccountTeamMember> accountMembersList = new List<AccountTeamMember>();
        for(Id distributorId : distributorIds){
            if(outletDistributorMap != null && outletDistributorMap.containskey(distributorId)){
                for(Id outletId : outletDistributorMap.get(distributorId)){
                    if(distributorUserMap != null && distributorUserMap.containskey(distributorId) && distributorUserMap.get(distributorId) != null){
                        for( Id userId :distributorUserMap.get(distributorId)){
                            if(userId!=null && !String.isBlank(userId)){
                                AccountTeamMember newAccTeamMember = new AccountTeamMember();
                                newAccTeamMember.AccountId = outletId;
                                newAccTeamMember.UserId = userId;
                                newAccTeamMember.TeamMemberRole = 'Distributor Responsible';
                                newAccTeamMember.AccountAccessLevel = 'Edit';
                                newAccTeamMember.OpportunityAccessLevel = 'Edit';
                                newAccTeamMember.ContactAccessLevel = 'Edit';
                                newAccTeamMember.CaseAccessLevel = 'Read';
                                accountMembersList.add(newAccTeamMember);
                            }
                        }
                    }
                }
            }
        }
        return accountMembersList;
    }
    /*******************************************************************
	Method  : deleteAccountTeamMember
	Purpose : ES20-8662
	********************************************************************/  
    public static void deleteAccountTeamMember(Map<Id, SObject> oldItems){
        List<AccountTeamMember> accountTeamMembersToBeDeletedList = new List<AccountTeamMember>();
        List<Supplier_Outlet__c> supplierOutletDeleteList = new List<Supplier_Outlet__c>();
        List<Id> supOutTobeDeletedIdList = new List<Id>();
        Set<Id> outletIdSet = new Set<Id>();
        Set<Id> distributorIdSet = new Set<Id>();
        Map<Id,Supplier_Outlet__c> oldSupplierOutletMap = (Map<Id,Supplier_Outlet__c>) oldItems;
        Map<Id, List<Id>> outletDistributorIdTobeDeletedMap = new Map<Id, List<Id>>();
        Map<Id, List<Id>> otherOutletDistributorIdMap = new Map<Id, List<Id>>();
        Map<Id, Set<Id>> outletPersonRespIdTobeDeletedMap = new Map<Id, Set<Id>>();
        Map<Id, Set<Id>> otherOutletPersonRespIdMap = new Map<Id, Set<Id>>();
        Map<Id, Set<Id>> finalOutletPersonRespIdTobeDeletedMap = new Map<Id, Set<Id>>();
        List<Supplier_Outlet__c> supplierOutletList = new List<Supplier_Outlet__c>();
            
        try{
            if(oldItems!=null){
                for(Supplier_Outlet__c supplierOutletRec : oldSupplierOutletMap.values()){
                    Supplier_Outlet__c oldsupplierOutletRec = oldSupplierOutletMap.get(supplierOutletRec.id); 
                    outletIdSet.add(oldsupplierOutletRec.Outlet__c);
                    supOutTobeDeletedIdList.add(supplierOutletRec.id);
                    //to get the supplier outlet records which are getting deleted
                    supplierOutletDeleteList.add(oldsupplierOutletRec);
                    
                }
                //Querying the list of supplier outlets related to outletIdSet
                for(Supplier_Outlet__c supplierOutletRec : [Select Id, Outlet__c, Distributor_Wholesaler__c from Supplier_Outlet__c where Outlet__c IN :outletIdSet]){
                    populateDistributorMaps(supOutTobeDeletedIdList, distributorIdSet, outletDistributorIdTobeDeletedMap, 
                                           otherOutletDistributorIdMap, supplierOutletRec);
                 }
                
                //To populate the maps - outletDistributorIdTobeDeletedMap,otherOutletDistributorIdMap for the supplier outlet getting deleted
                for(Supplier_Outlet__c supplierOutletRec : supplierOutletDeleteList){
                    populateDistributorMaps(supOutTobeDeletedIdList, distributorIdSet, outletDistributorIdTobeDeletedMap, 
                                           otherOutletDistributorIdMap, supplierOutletRec);
                }
                //querying the distributor records to get Person_Responsible__c,Person_Responsible_2__c,Person_Responsible_3__c values
                List<Account> distributorDeleteList = [Select Id,Person_Responsible__c,Person_Responsible_2__c,Person_Responsible_3__c from Account where Id IN :distributorIdSet];
                for(Account distAccount :distributorDeleteList){
                    for(Id id :outletDistributorIdTobeDeletedMap.keyset()){
                        //creating a map of outlet id and related person responsible to be deleted
                        if(outletDistributorIdTobeDeletedMap.get(id).indexOf(distAccount.Id) != -1){
                            Set<Id> personRespIdSet = outletPersonRespIdTobeDeletedMap.get(id);
                            personRespIdSet = populatePerRespSet(personRespIdSet, distAccount);
                            outletPersonRespIdTobeDeletedMap.put(id, personRespIdSet);
                        }
                        else{
                            //creating a map of outlet id and related person responsible should remain in the system
                            Set<Id> personRespIdSet = otherOutletPersonRespIdMap.get(id);
                            personRespIdSet = populatePerRespSet(personRespIdSet, distAccount);
                            otherOutletPersonRespIdMap.put(id, personRespIdSet); 
                        }
                    }
                }
                //creating the final list of person responsible to be deleted from AccountTeamMember per outlet and putting in a map
                for(Id id :outletPersonRespIdTobeDeletedMap.keyset()){
                    Set<Id> personRepIdTobeDeleted = outletPersonRespIdTobeDeletedMap.get(id); 
                    Set<Id> otherPersonRespIdSet = otherOutletPersonRespIdMap.get(id);
                    if(otherPersonRespIdSet != null){
                    	personRepIdTobeDeleted.removeAll(otherPersonRespIdSet);    
                    }
                    if(personRepIdTobeDeleted != null){
                    	finalOutletPersonRespIdTobeDeletedMap.put(id,personRepIdTobeDeleted);    
                    }
                }
                
                //quering the account team member to be deleted
                for(AccountTeamMember acctmemRec :[Select Id,AccountId, UserId from AccountTeamMember where AccountId IN :finalOutletPersonRespIdTobeDeletedMap.keyset()]){
                    if(finalOutletPersonRespIdTobeDeletedMap.get(acctmemRec.AccountId).contains(acctmemRec.UserId)){
                        accountTeamMembersToBeDeletedList.add(acctmemRec);    
                    }    
                }
                //delete AccountTeamMembers
                if(accountTeamMembersToBeDeletedList !=null && accountTeamMembersToBeDeletedList.size()>0){
                    Database.delete(accountTeamMembersToBeDeletedList,true);
                }
            }
        }catch(Exception ex){
            System.debug('Exception:::'+ex.getLineNumber()+ex.getCause()+ex.getMessage());
        }
    }
    
    /**********************************************************************
    Name        : populateDistributorMaps
    Description : This method will populate otherOutletDistributorIdMap and outletDistributorIdTobeDeletedMap.
    **********************************************************************/

	private static void populateDistributorMaps(List<Id> supOutTobeDeletedIdList, Set<Id> distributorIdSet, Map<Id, List<Id>> outletDistributorIdTobeDeletedMap, 
                                           Map<Id, List<Id>> otherOutletDistributorIdMap,Supplier_Outlet__c supplierOutletRec)
    {
        // indexof returns -1 , if the id doesnot exist
        if(supOutTobeDeletedIdList.indexOf(supplierOutletRec.Id) != -1){
            // creating a map of outlet id and set of distributor ids to be deleted
            List<Id> distributorList = outletDistributorIdTobeDeletedMap.get(supplierOutletRec.Outlet__c);
            distributorList = processDistDetails(distributorList, distributorIdSet, supplierOutletRec);
            outletDistributorIdTobeDeletedMap.put(supplierOutletRec.Outlet__c, distributorList);
         }
        else{
            // creating a map of outlet id and other set of distributor ids linked
            List<Id> distributorList = otherOutletDistributorIdMap.get(supplierOutletRec.Outlet__c);
            distributorList = processDistDetails(distributorList, distributorIdSet, supplierOutletRec);
            otherOutletDistributorIdMap.put(supplierOutletRec.Outlet__c, distributorList);
         }
    }
    
    /**********************************************************************
    Name        : processDistDetails
    Description : This method will populate distributorList and distributorIdSet.
    **********************************************************************/
    private static List<Id> processDistDetails(List<Id> distributorList, Set<Id> distributorIdSet,Supplier_Outlet__c supplierOutletRec){
        if(distributorList != null){
            distributorList.add(supplierOutletRec.Distributor_Wholesaler__c);
            distributorIdSet.add(supplierOutletRec.Distributor_Wholesaler__c);
        }
        else{
            distributorList = new List<Id>();
            distributorList.add(supplierOutletRec.Distributor_Wholesaler__c);
            distributorIdSet.add(supplierOutletRec.Distributor_Wholesaler__c);
        }
        return distributorList;
    }
    
    /**********************************************************************
    Name        : populatePerRespSet
    Description : This method will populate personRespIdSet.
    **********************************************************************/
    private static Set<Id> populatePerRespSet(Set<Id> personRespIdSet, Account distAccount){
        if(personRespIdSet != null){
            personRespIdSet.addAll(EDGE_DistributorPersonRespBatchHelper.addValues(distAccount.Person_Responsible__c,distAccount.Person_Responsible_2__c,distAccount.Person_Responsible_3__c));
        }
        else{
            personRespIdSet = addValues(distAccount.Person_Responsible__c,distAccount.Person_Responsible_2__c,distAccount.Person_Responsible_3__c);
        }
        return personRespIdSet;
    }
    /**********************************************************************
    Name        : addValues
    Description : This method will check person responsible null or not.
    **********************************************************************/
    public static Set<Id> addValues(Id perResp1,Id perResp2,Id perResp3){
        Set<Id> userSetId = new Set<Id>();
        if(perResp1!=null){
            userSetId.add(perResp1);
        }
        if(perResp2!=null){
            userSetId.add(perResp2);
        }
        if(perResp3!=null){
            userSetId.add(perResp3);
        }
        return userSetId;
    }
    
}