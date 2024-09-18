/*
* Class Name : PNR_SharingUtil
* @description: Custom Sharing - Sharing Util Class for PNR
* @history
* VERSION    AUTHOR                DATE              DETAIL
* 1.0        Pratik Kumar 		   12/01/2022        Initial Development
* 1.1		 Sai Kiran Sagaram     13/01/2022	     PION-1699 Change
* 1.2        Pratik Kumar          22/02/2022        PION-1823
*/
public class PNR_SharingUtil {
    
    /*
	* @description : Add SO public group to RG public group
	* @return : void
	* @param : Map<String, String> soGroupRgGroupMap
	*/
    @future
    public static void addSOGroupToRGGroup(Map<String, String> soGroupRgGroupMap, String operation){
        
        try{
            Map<String, Id> grpNameRecMap = new Map<String, Id>();
            List<GroupMember> gmList = new List<GroupMember>();
            
            for(Group grp: [SELECT Id,DeveloperName FROM Group WHERE DeveloperName IN :soGroupRgGroupMap.keyset() OR DeveloperName IN :soGroupRgGroupMap.values()]){
                grpNameRecMap.put(grp.DeveloperName, grp.Id);
                
            }
            
            if(operation == 'add'){
                for(String soGrpName: soGroupRgGroupMap.keyset()){
                    
                    GroupMember gm = new GroupMember();
                    gm.GroupId = grpNameRecMap.get(soGrpName);
                    gm.UserOrGroupId = grpNameRecMap.get(soGroupRgGroupMap.get(soGrpName));
                    if(gm.GroupId != null && gm.UserOrGroupId != null){
                        gmList.add(gm);
                    }
                }
                if(!gmList.isEmpty())
                {
                    insert gmList;
                }
            }
            
            if(operation == 'remove'){
                List<GroupMember> gmListRemove = new List<GroupMember>();
                Map<Id, Id> soIdRgIdMap = new Map<Id, Id>();
                for(String gName: soGroupRgGroupMap.keyset()){

                    soIdRgIdMap.put(grpNameRecMap.get(gName), grpNameRecMap.get(soGroupRgGroupMap.get(gName)));
                }
                for(GroupMember gm: [SELECT Id, GroupId, UserOrGroupId FROM GroupMember WHERE GroupId IN:grpNameRecMap.values() AND UserOrGroupId IN: grpNameRecMap.values()]){

                    if(soIdRgIdMap.values().contains(gm.UserOrGroupId) && soIdRgIdMap.containsKey(gm.GroupId) && soIdRgIdMap.get(gm.GroupId) != null && gm.UserOrGroupId == soIdRgIdMap.get(gm.GroupId)){
                        gmListRemove.add(gm);
                    }
                }
                if(!gmListRemove.isEmpty()){
                    delete gmListRemove;
                }
            }

            
            } catch(Exception excption){
            System.debug('Exception:::'+excption.getLineNumber()+excption.getCause()+excption.getMessage());
            new EDGE_GenericException(excption, null);
        }
        
    }
	/*
	 * @description: This method used to add an user to a regional group. Added for PION-1699 change.
	 * @retrun: void
	 * @param: Map<Id,sObject> newItems,Map<Id, SObject> oldItems
	 * */
    public static void addUserToPublicGroup(Map<Id,sObject> newItems,Map<Id, SObject> oldItems)
    {
        Map<Id,User> mapOldUser;
        Map<Id,User> mapNewUser = (Map<Id,User>) newItems;
        Map<String, String> mapGroupName = new Map<String, String>();
        Map<String,List<String>> mapUserWithRgGroup = new Map<String,List<String>>();
        Map<String,List<String>> mapDeleteUserWithRgGroup = new Map<String,List<String>>();
        Map<String, List<String>> mapOldUserRgGroup = new Map<String, List<String>>();
        List<GroupMember> lstGroupMember = new List<GroupMember>(); 
        List<GroupMember> lstDeleteGroupMember = new List<GroupMember>(); 
        List<Id> lstGroupId = new List<Id>();
        List<String> lstGroupName = new List<String>();
        Map<Id,String> mapUserWithType = new Map<Id,String>();
        try{
            set<string> profileNames = new set<string>();
            List<String> userProfileVal = Label.PNR_Required_Profiles.split(',');
            for(String val : userProfileVal){
                profileNames.add(val);
            }
            MAP<id,profile> profileMap = new MAP<id,profile>([select id,name from profile where name IN : profileNames]);
            if(oldItems != null && oldItems.size()>0){
                mapOldUser = (Map<Id,User>) oldItems;
                List<String> userSOrg = new List<String>();
                for(User oldUser : mapOldUser.values()){
                    for(String typeObj : profileMap.keySet()){
                        if(oldUser.ProfileId == typeObj){
                            if(String.isNotBlank(oldUser.Regional_Group__c)){
                                userSOrg=oldUser.Regional_Group__c.split(';');
                            }
                            if(userSOrg != null && userSOrg.size()>0){
                                for(String salesOrg : userSOrg){
                                    if(mapOldUserRgGroup.containsKey(oldUser.Id)){
                                        mapOldUserRgGroup.get(oldUser.Id).add(salesOrg);                    
                                    } else{
                                        mapOldUserRgGroup.put(oldUser.Id, new List<String>{salesOrg});
                                    }
                                }
                            }                        
                        }    
                    }
                }
                //System.debug('mapOldUserRgGroup:::*******'+mapOldUserRgGroup);
            }
            
            
            
            if(mapNewUser != null && mapNewUser.size()>0){
                Map<Id,User> mapStandardUser = new Map<Id,User>();
                List<String> newUserRgGroup = new List<String>();
                for(User newUser : mapNewUser.values()){                     
                    if(String.isNotBlank(newUser.Regional_Group__c)){
                        newUserRgGroup = newUser.Regional_Group__c.split(';');
                    }
                    for(String typeObj : profileMap.keySet()){
                        if(newUser.ProfileId == typeObj ){
                            mapStandardUser.put(newUser.Id,newUser);
                            
                            System.debug('newUserRgGroup******'+newUserRgGroup);
                            //List<String> lstNewUserCountry = createListCountryCode(newUser);
                            //Create a MAP which contains only those country code record that is newly added
                            if(newUserRgGroup != null && newUserRgGroup.size()>0){
                                for(String sOrgCode : newUserRgGroup){
                                    lstGroupName.add(sOrgCode);
                                    if(mapOldUser == null || (mapOldUser != null && mapOldUserRgGroup != null && mapOldUserRgGroup.containsKey(newUser.Id) && !(mapOldUserRgGroup.get(newUser.Id)).contains(sOrgCode))
                                       || (newUser.ProfileId != mapOldUser.get(newUser.Id).ProfileId) || (newUser.Regional_Group__c != mapOldUser.get(newUser.Id).Regional_Group__c)){
                                           mapUserWithType.put(newUser.Id,newUser.ProfileId);
                                           if(mapUserWithRgGroup.containsKey(sOrgCode)){
                                               mapUserWithRgGroup.get(sOrgCode).add(newUser.Id);
                                               //System.debug('mapUserWithRgGroup from if:::'+mapUserWithRgGroup);
                                           } else {
                                               mapUserWithRgGroup.put(sOrgCode, new List<Id>{newUser.Id});
                                               //System.debug('mapUserWithRgGroup from else:::'+mapUserWithRgGroup);
                                           }                            
                                       }
                                }
                                System.debug('mapUserWithRgGroup:::'+mapUserWithRgGroup);                    
                            }
                            
                            //Create a MAP which contains only those country code record that is needs to be removed
                            if(mapOldUserRgGroup != null && mapOldUserRgGroup.containsKey(newUser.Id)){
                                List<String> lstOldUserRgGroup = mapOldUserRgGroup.get(newUser.Id);
                                for(String RgGroup : lstOldUserRgGroup){
                                    lstGroupName.add(RgGroup);
                                    if(!newUserRgGroup.contains(RgGroup)){
                                        if(mapDeleteUserWithRgGroup.containsKey(RgGroup)){
                                            mapDeleteUserWithRgGroup.get(RgGroup).add(newUser.Id);
                                        } else {
                                            mapDeleteUserWithRgGroup.put(RgGroup, new List<Id>{newUser.Id});
                                        }                            
                                    }
                                }
                                mapOldUserRgGroup.clear();
                                //System.debug('mapDeleteUserWithRgGroup:::'+mapDeleteUserWithRgGroup);
                            }
                        }
                    }
                }
               // mapNewUser.clear();
              //  mapNewUser = mapStandardUser;
              //  System.debug('mapNewUser::'+mapNewUser);
            }
            if((mapUserWithRgGroup != null && mapUserWithRgGroup.size()>0) || (mapDeleteUserWithRgGroup != null && mapDeleteUserWithRgGroup.size()>0)){
                Id rgRecordTypeId = Schema.SObjectType.Sales_Organisation__c.getRecordTypeInfosByDeveloperName().get('Regional_Group').getRecordTypeId();//1699
            	List<Sales_Organisation__c> sOrgListDetails = [SELECT Id, Name FROM Sales_Organisation__c WHERE Name IN :lstGroupName and recordtypeId =: rgRecordTypeId];//1699
                System.debug('sOrgListDetails:::'+sOrgListDetails);
                
                //Create map of group name and code
                if(sOrgListDetails != null && sOrgListDetails.size()>0){
                    //validateGeographySelection(lstGeographyDetails, mapNewUser);
                    for(Sales_Organisation__c salesOrgDetails : sOrgListDetails){
                        mapGroupName.put('RG_'+salesOrgDetails.Name+'_Read', salesOrgDetails.Name);
                        mapGroupName.put('RG_'+salesOrgDetails.Name+'_Write', salesOrgDetails.Name);
                    }
                }                    
            }
            //System.debug('mapGroupName:::'+mapGroupName); 
            //System.debug('mapUserWithRgGroup:::'+mapUserWithRgGroup); 
            //System.debug('mapUserWithType:::'+mapUserWithType);
            if(mapGroupName != null && mapGroupName.size()>0){
                for(Group groupDetails : [SELECT Id, DeveloperName FROM Group WHERE DeveloperName IN :mapGroupName.keySet()]){
                    //Create List of Group Member that needs to be inserted
                    if(mapGroupName.containsKey(groupDetails.DeveloperName) && mapUserWithRgGroup.containsKey(mapGroupName.get(groupDetails.DeveloperName))){
                        List<String> lstUser = mapUserWithRgGroup.get(mapGroupName.get(groupDetails.DeveloperName));
                        for(String userId : lstUser){
                            if(mapUserWithType!= null && mapUserWithType.containsKey(userId)){
                                GroupMember objGroupMember = new GroupMember();
                                objGroupMember.GroupId = groupDetails.Id;
                                objGroupMember.UserOrGroupId = userId;
                                lstGroupMember.add(objGroupMember);
                            }
                        }
                    } else if(mapGroupName.containsKey(groupDetails.DeveloperName) && mapDeleteUserWithRgGroup.containsKey(mapGroupName.get(groupDetails.DeveloperName))){
                        //Create List of Group Member that needs to be deleted
                        List<String> lstUser = mapDeleteUserWithRgGroup.get(mapGroupName.get(groupDetails.DeveloperName));
                        lstGroupId.add(groupDetails.Id);
                        for(String userId : lstUser){
                            if(mapOldUserRgGroup.containsKey(userId)){
                                mapOldUserRgGroup.get(userId).add(groupDetails.Id);
                            } else {
                                mapOldUserRgGroup.put(userId, new List<Id>{groupDetails.Id});
                            }                               
                        }
                    }                       
                }
                
                //System.debug('lstGroupMember:::'+lstGroupMember); 
                //System.debug('mapOldUserRgGroup:::'+mapOldUserRgGroup); 
                //System.debug('mapGroupName:::'+mapGroupName); 
                
                if(lstGroupId != null && lstGroupId.size()>0 && mapOldUserRgGroup != null && mapOldUserRgGroup.size()>0){
                    //Fetch Group Member details that needs to be deleted
                    for(GroupMember groupMemberDetails : [SELECT ID, GroupId, UserOrGroupId FROM GroupMember WHERE GroupId in :lstGroupId AND UserOrGroupId IN :mapOldUserRgGroup.keySet()]){
                        if(mapOldUserRgGroup.containsKey(groupMemberDetails.UserOrGroupId) && (mapOldUserRgGroup.get(groupMemberDetails.UserOrGroupId)).contains(groupMemberDetails.GroupId)){
                            lstDeleteGroupMember.add(groupMemberDetails);                            
                        }
                    }
                    
                    System.debug('lstDeleteGroupMember:::'+lstDeleteGroupMember); 
                    
                    if(lstDeleteGroupMember != null && lstDeleteGroupMember.size()>0){
                        Database.delete(lstDeleteGroupMember);
                    }
                }
                
                if(lstGroupMember != null && lstGroupMember.size()>0){
                    Database.upsert(lstGroupMember);
                } 
            }
        }            
        catch(Exception excption){
            List<SObject> errorItem = newItems.values();
            System.debug('Exception:::'+excption.getLineNumber()+excption.getCause()+excption.getMessage());
            new EDGE_GenericException(excption, errorItem[0]);            
        }
    }  
   
    
    // PION-1823, 1824 implementation
    //generateSharingFromSalesOrg method to be used to share Case records that do not have a parent account
    public static void generateSharingFromSalesOrg(list<SObject> listObject, String soFieldApiName, String operation)
    {        
        String salesOrg;
        List<String> salesOrgGroupNameList = new List<String>();
        Map<Id, String> recIdSoNameMap = new Map<Id, String>();
        Map<Id, SObject> idRecMap = new Map<Id, SObject>();
        
        Id directRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDevelopername().get('PNR_Direct_Customer').getRecordTypeId();
        List<Id> pnrCaseRecTypeId = new List<Id>();
        

        for(String recType: System.Label.PNR_Case_RecordTypes.split(';')){
            pnrCaseRecTypeId.add(Schema.SObjectType.Case.getRecordTypeInfosByDevelopername().get(recType).getRecordTypeId());
        }

        for(SObject so: listObject){
            Schema.SObjectType ObjectType= so.getSObjectType();
            String objectName=ObjectType.getDescribe().getName();
            idRecMap.put(so.Id, so);
            if(objectName == 'Case' && so.get('AccountId') == null && pnrCaseRecTypeId.contains((Id) so.get('RecordTypeId')))
            {
                salesOrg = (String) so.get(soFieldApiName);
                salesOrgGroupNameList.add('SO_'+salesOrg+'_Read');
                salesOrgGroupNameList.add('SO_'+salesOrg+'_Write');
                recIdSoNameMap.put(so.Id, salesOrg);
            } //added this for Account record sharing, PION-1824 change;
            else if(objectName == 'Account' && so.get('recordtypeid') == directRecTypeId) {
                salesOrg = (String) so.get(soFieldApiName);
                salesOrgGroupNameList.add('SO_'+salesOrg+'_Read');
                salesOrgGroupNameList.add('SO_'+salesOrg+'_Write');
                recIdSoNameMap.put(so.Id, salesOrg);
            }          
        }
		system.debug('111111111'+ salesOrgGroupNameList);
        Map<String, Id> grpNameIdMap = new Map<String, Id>();
        for(Group grp : [SELECT Id, DeveloperName FROM Group WHERE DeveloperName IN :salesOrgGroupNameList])
        {
            grpNameIdMap.put(grp.DeveloperName, grp.Id);
        }
        system.debug('2222222222'+ grpNameIdMap);
        if(operation == 'add'){
            List<SObject> shareRecordtoInsertList = new List<SObject>();
            List<String> caseShareRecListString = new List<String>();
            for(Id recid: idRecMap.keyset()){
                Schema.SObjectType ObjectType= recid.getSObjectType();
                String objectName=ObjectType.getDescribe().getName();
                String shareObjectName = objectName.endsWith('__c') ? (objectName.removeEnd('__c') + '__Share') : (objectName + 'Share');
                Schema.SObjectType shareType = Schema.getGlobalDescribe().get(shareObjectName);
                SObject shareRecord = shareType.newSObject();
                if(shareObjectName.equals('CaseShare') 
                && grpNameIdMap.containsKey('SO_'+idRecMap.get(recId).get(soFieldApiName)+'_Read') 
                && grpNameIdMap.containsKey('SO_'+idRecMap.get(recId).get(soFieldApiName)+'_Write'))
                {
                    system.debug('3333333333'+ grpNameIdMap);
                    shareRecord.put('CaseId', recid);
                    shareRecord.put('UserOrGroupId', grpNameIdMap.get('SO_'+idRecMap.get(recId).get(soFieldApiName)+'_Read'));
                    shareRecord.put('RowCause', 'Manual');
                    shareRecord.put('CaseAccessLevel', 'Read');
                    caseShareRecListString.add(recId+'#;#'+grpNameIdMap.get('SO_'+idRecMap.get(recId).get(soFieldApiName)+'_Read')+'#;#'+'Manual'+'#;#'+'Read');
                    shareRecord = shareType.newSObject(); 
                    shareRecord.put('CaseId', recid);
                    shareRecord.put('UserOrGroupId', grpNameIdMap.get('SO_'+idRecMap.get(recId).get(soFieldApiName)+'_Write'));
                    shareRecord.put('RowCause', 'Manual');
                    shareRecord.put('CaseAccessLevel', 'Edit');
                    caseShareRecListString.add(recId+'#;#'+grpNameIdMap.get('SO_'+idRecMap.get(recId).get(soFieldApiName)+'_Write')+'#;#'+'Manual'+'#;#'+'Edit');
                }
                //Added for Account sharing access PION-1824 change
                else if(shareObjectName.equals('AccountShare')
                && grpNameIdMap.containsKey('SO_'+idRecMap.get(recId).get(soFieldApiName)+'_Read') 
                   && grpNameIdMap.containsKey('SO_'+idRecMap.get(recId).get(soFieldApiName)+'_Write')){
                        shareRecord.put('AccountId', recid);
                        shareRecord.put('UserOrGroupId', grpNameIdMap.get('SO_'+idRecMap.get(recId).get(soFieldApiName)+'_Read'));
                        shareRecord.put('RowCause', 'Manual');
                        shareRecord.put('AccountAccessLevel', 'Read');
                        shareRecord.put('ContactAccessLevel', 'Read');
                        shareRecord.put('CaseAccessLevel', 'Read');
                        shareRecord.put('OpportunityAccessLevel', 'None');
                        shareRecordtoInsertList.add(shareRecord);
                        shareRecord = shareType.newSObject(); 
                        shareRecord.put('AccountId', recid);
                        shareRecord.put('UserOrGroupId', grpNameIdMap.get('SO_'+idRecMap.get(recId).get(soFieldApiName)+'_Write'));
                        shareRecord.put('RowCause', 'Manual');
                        shareRecord.put('AccountAccessLevel', 'Edit');
                        shareRecord.put('ContactAccessLevel', 'Edit');
                        shareRecord.put('CaseAccessLevel', 'Edit');
                        shareRecord.put('OpportunityAccessLevel', 'None');
                        shareRecordtoInsertList.add(shareRecord);
                   }
            }
			system.debug('4444444444'+ shareRecordtoInsertList);
            //PION-2636 starts
            if(caseShareRecListString.size() > 0)
            {
                PNR_SharingUtil.generateCaseSharingAsync(caseShareRecListString);
            }
            //PION-2636 ends
            if(!shareRecordtoInsertList.isEmpty()){
                insert shareRecordtoInsertList;
            }
        }

        if(operation == 'remove'){            
            Schema.SObjectType ObjectType= listObject[0].getSObjectType();
            String objectName=ObjectType.getDescribe().getName();
            List<SObject> shareRecDeleteList = new List<SObject>();
            if(objectName == 'Case'){
                
                for(CaseShare cs: [SELECT Id, CaseId, UserOrGroupId FROM CaseShare WHERE CaseId IN: recIdSoNameMap.keyset() AND UserOrGroupId IN :grpNameIdMap.values()]){
                    if(idRecMap.get(cs.CaseId).get('AccountId') == null 
                        && pnrCaseRecTypeId.contains((Id) idRecMap.get(cs.CaseId).get('RecordTypeId')) 
                        && (
                            cs.UserOrGroupId == grpNameIdMap.get('SO_'+recIdSoNameMap.get(cs.CaseId)+'_Read')
                            || 
                            cs.UserOrGroupId == grpNameIdMap.get('SO_'+recIdSoNameMap.get(cs.CaseId)+'_Write')
                            )
                        ){
                            
                            shareRecDeleteList.add(cs);
                        }
                }

            }
            //Added this Account sharing PION-1824 change;
            else if(objectName == 'Account'){
                for(AccountShare accShare: [SELECT Id, AccountId, UserOrGroupId FROM AccountShare WHERE AccountId IN: recIdSoNameMap.keyset() AND UserOrGroupId IN :grpNameIdMap.values()]){
                    if(idRecMap.get(accShare.AccountId).get('recordtypeid') == directRecTypeId && accShare.UserOrGroupId == grpNameIdMap.get('SO_'+recIdSoNameMap.get(accShare.AccountId)+'_Read')
                        || accShare.UserOrGroupId == grpNameIdMap.get('SO_'+recIdSoNameMap.get(accShare.AccountId)+'_Write')){
                            
                            shareRecDeleteList.add(accShare);
                        }
                }
            }
            if(!shareRecDeleteList.isEmpty()){
                delete shareRecDeleteList;
            }
            
        }
    
    }

    //changes to accomodate PION-2636
    @future
    public static void generateCaseSharingAsync(List<String> csShareUpdateList){
        System.debug('csShareUpdateList:: '+csShareUpdateList);
        List<String> csRecDetSplit = new List<String>();
        CaseShare shareRecord;
        List<CaseShare> shareRecordtoInsertList = new List<CaseShare>();
        for(String cs: csShareUpdateList)
        {
            csRecDetSplit.addAll(cs.split('#;#'));
            shareRecord = new CaseShare();
            shareRecord.put('CaseId', csRecDetSplit[0]);
            shareRecord.put('UserOrGroupId', csRecDetSplit[1]);
            shareRecord.put('RowCause', csRecDetSplit[2]);
            shareRecord.put('CaseAccessLevel', csRecDetSplit[3]);
            System.debug('shareRecord:: '+shareRecord);
            shareRecordtoInsertList.add(shareRecord);
            csRecDetSplit.clear();
        }
        if(shareRecordtoInsertList.size() > 0)
        {
            try{
            	insert shareRecordtoInsertList;
            }catch(Exception ex){
                System.debug(ex.getMessage());
            }
        }
    }
     
}