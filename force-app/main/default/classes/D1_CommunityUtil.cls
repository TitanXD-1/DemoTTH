/*
 * @name: D1_CommunityUtil
 * @description : Utility Class for Diageo One Community
 * @history
 * VERSION     AUTHOR      DATE            DETAIL
 * 1.0         Ankit       -               Initial Development
 * 2.0         Ajay        22/03/2021      NCP-2183(Refactored assignPermission function into small functions)
 * 3.0         Gaurav      27/07/2021      NCP-3902(Assign 'B2B_Commerce_Blocked' permission)
 * 4.0         Gaurav      27/07/2021      NCP-3903,NCP-3632(Assign 'B2B_Commerce_Blocked_Ship_To_Sold_To', 'B2B_Commerce_Deleted_Ship_To' permission)
 **/
public without sharing class D1_CommunityUtil {


    final static String B2B_USER_PERMISSION = 'B2B Commerce User';
    final static String ORDER_PERMISSION = 'Ordering';//NCP-2341
    final static String ACCOUNT_SWITCH_PERMISSION = 'Account Switcher User';
    final static String FINANCIAL_DOCUMENTS ='Financial Documents';
    final static String ACCOUNT_BALANCES = 'Account Balances';
    final static String B2B_COMMERCE_BLOCKED_SHIP_TO_SOLD_TO ='B2B Commerce Blocked Ship-To/Sold-To';//NCP-3902,NCP-3903,NCP-3632
    final static String B2B_COMMERCE_DELETED_SHIP_TO ='B2B Commerce Deleted Ship-To';//NCP-3903,NCP-3632

    /**  
    * @userstory : NCP-925
    * @description :  Assign custom permission to user on the basis of D1 Role field value on the AccountContact
    * @param : string
    * @return : Map<String, Object>
    **/
    @AuraEnabled
    public static Map<String,Object> assignPermission(string outletId,Id userId) { 
        
        User currentUser = getCurrentUser(userId);
        Set<String> allAvailablePermissionNames = getAllPermissions();
        Set<String> toAssignPermissionNames = getAssignedPermissions(currentUser.Effective_Account_Id__c, currentUser.ContactId) ;

        Map<String,Id> mapOfPermissionSetNameToId = new Map<String,Id>();
        for(PermissionSet psObj : [SELECT Id,Name,Label FROM PermissionSet WHERE Label IN : allAvailablePermissionNames]) {
            mapOfPermissionSetNameToId.put(psObj.Label,psObj.Id); 
        }
        
        Set<string> alreadyAssignedPermissionNames = new Set<string>();
        Map<String, Id> mapOfPermissionToAssignment = new Map<String, Id>();
        List<PermissionSetAssignment> permissionAssignments = [SELECT PermissionSet.Label,Id 
                                                            FROM PermissionSetAssignment 
                                                            WHERE AssigneeId =:currentUser.Id 
                                                            AND PermissionSetId IN :mapOfPermissionSetNameToId.values()];
        for(PermissionSetAssignment psObj : permissionAssignments) {
            alreadyAssignedPermissionNames.add(psObj.PermissionSet.Label);
            mapOfPermissionToAssignment.put(psObj.PermissionSet.Label, psObj.Id);
        }

        /**
         *  toAssignPermissionNames         --> permissions need to Assign
         *  alreadyAssignedPermissionNames  --> already assigned permissions
         *  mapOfPermissionToAssignment     --> map of Already assigned Permission  -> Permission Assignment Id
         */

        // If Already & to Assign are same 
        if(toAssignPermissionNames.equals(alreadyAssignedPermissionNames)){
            return getAssignedPermissionMap(allAvailablePermissionNames, toAssignPermissionNames, false, currentUser);
        }

        Set<String> commonPermissions = retainAll(toAssignPermissionNames,alreadyAssignedPermissionNames);
        Set<String> permissionsToRemove = removeAll(alreadyAssignedPermissionNames, commonPermissions);
        Set<String> permissionsToAdd = removeAll(toAssignPermissionNames, commonPermissions);

        removePermissions(permissionsToRemove, mapOfPermissionToAssignment);
        addPermissions(permissionsToAdd, currentUser.Id, mapOfPermissionSetNameToId);
        return getAssignedPermissionMap(allAvailablePermissionNames, toAssignPermissionNames, true, currentUser);
    }

    /**
     * @description Get current user information
     * @param [userId] userId
     * @return {User} 
     */
    public static User getCurrentUser(Id userId){
        userId = userId == null ? UserInfo.getUserId() : userId;

        List<User> users = [SELECT id, Effective_Account_Id__c, ContactId, AccountId
                            FROM User
                            WHERE id=: userId];
        if(users.isEmpty()){
            throw new AuraHandledException('Access Denied(User)');
        }
        User currentUser = users[0];

        if(String.isEmpty(currentUser.Effective_Account_Id__c) && !String.isEmpty(currentUser.AccountId)){
            update new User(id = currentUser.id, Effective_Account_Id__c = currentUser.AccountId);
            currentUser.Effective_Account_Id__c = currentUser.AccountId;
        }
        return currentUser;
    }

    /**
     * @description Get to Assign permissions of a user
     * @param {Id} accountId
     * @param {Id} contactId
     * @return {Set<String>}  to Assign Permission Names
     */
    private static Set<String> getAssignedPermissions(Id accountId, Id contactId){
        if(String.isEmpty(accountId) || String.isEmpty(contactId)){
            throw new AuraHandledException('Invalid parameters');
        }

        List<String> permissions = new List<String>();
        for(AccountContactRelation relation: [SELECT id, D1_Roles__c
                                             FROM AccountContactRelation
                                             WHERE D1_Active__c = true
                                             AND accountId =:accountId
                                             AND ContactId =:contactId
                                             LIMIT 1
                                             ]
        ){
            permissions = relation.D1_Roles__c == null ? new List<String>() : relation.D1_Roles__c.split(';');
        }

        Set<String> assignedPermissions = new Set<String>();
        for(String permission: permissions){
            assignedPermissions.add(permission.trim());
        }

        if(assignedPermissions.contains(ORDER_PERMISSION)){
            assignedPermissions.add(B2B_USER_PERMISSION);
            assignedPermissions.add(ACCOUNT_SWITCH_PERMISSION);
        

            //NCP-3902,NCP-3903,NCP-3632
            List<AggregateResult> cpaAgrList = [Select count(id), AddressType adrType, Status__c status
                                                from ContactPointAddress 
                                                where ParentId = :accountId
                                                Group By AddressType,Status__c];
    
            Boolean hasActiveBillingCPA = false;
            Boolean hasActiveShippingCPA = false;
            Boolean hasBlockedShippingCPA = false;
            Boolean hasClosedShippingCPA = false;
            if( !cpaAgrList.isEmpty() ){
                for( AggregateResult agr : cpaAgrList ){
                    if( (String)agr.get('adrType') == 'Billing' ){
                        if( (String)agr.get('status') == D1_AccountTriggerHelper.CONTACT_POINT_ADDRESS_STATUS_ACTIVE ){
                            hasActiveBillingCPA = true;
                        }
                    }else if( (String)agr.get('adrType') == 'Shipping' ){
                        if( (String)agr.get('status') == D1_AccountTriggerHelper.CONTACT_POINT_ADDRESS_STATUS_ACTIVE ){
                            hasActiveShippingCPA = true;
                        }else if( (String)agr.get('status') == D1_AccountTriggerHelper.CONTACT_POINT_ADDRESS_STATUS_BLOCKED ){
                            hasBlockedShippingCPA = true;
                        }else if( (String)agr.get('status') == D1_AccountTriggerHelper.CONTACT_POINT_ADDRESS_STATUS_CLOSED ){
                            hasClosedShippingCPA = true;
                        }
                    }
                }
            }
    
            if( !hasActiveBillingCPA ){
                assignedPermissions.add(B2B_COMMERCE_BLOCKED_SHIP_TO_SOLD_TO);
            }else if( !hasActiveShippingCPA ){
                if( hasClosedShippingCPA ){
                    assignedPermissions.add(B2B_COMMERCE_DELETED_SHIP_TO);
                }else{
                    assignedPermissions.add(B2B_COMMERCE_BLOCKED_SHIP_TO_SOLD_TO);
                }
            }
        }

        return assignedPermissions;
    }

    /**
     * @description Get All permission list
     * @return {Set<String>} all permission names
     */
    private static Set<String> getAllPermissions(){
        Schema.DescribeFieldResult fieldResult = AccountContactRelation.D1_Roles__c.getDescribe();
        List<Schema.PickListEntry> ple = fieldResult.getPickListValues();
        
        Set<string> allPermissionList = new Set<string>();
        for( Schema.PickListEntry f : ple) {
            allPermissionList.add(f.getLabel());
        }

        allPermissionList.add(B2B_USER_PERMISSION);
        allPermissionList.add(ACCOUNT_SWITCH_PERMISSION);
        allPermissionList.add(B2B_COMMERCE_BLOCKED_SHIP_TO_SOLD_TO); //NCP-3902,NCP-3903,NCP-3632
        allPermissionList.add(B2B_COMMERCE_DELETED_SHIP_TO); //NCP-3902,NCP-3903,NCP-3632
        
        return allPermissionList;
    }

    /**
     * @description Get Assigned Permission Map
     * @param {Set} allAvailablePermissions
     * @param {Set} assignedPermissions
     * @param {Boolean} isChanged
     * @param {User} currentUser
     * @return {Map<String, Boolean>} Permission Name -> is Have Permission
     */
    private static Map<String, Object> getAssignedPermissionMap(Set<String> allAvailablePermissions, Set<String> assignedPermissions, Boolean isChanged, User currentUser){
        Map<String, Object> mapOfAssignedPermissions = new Map<String, Object>();

        for(String permission: allAvailablePermissions){
            mapOfAssignedPermissions.put(permission, assignedPermissions.contains(permission));
        }
        mapOfAssignedPermissions.put('isChanged', isChanged);
        mapOfAssignedPermissions.put('effectiveAccountId', currentUser.Effective_Account_Id__c);
        
        return mapOfAssignedPermissions;
    }

    /**
     * @description Delete Permission Assignments
     * @param {Set} permissionsToRemove
     * @param {Set} mapOfPermissionToAssignment   permission Name -> PermissionAssignment Id
     */
    private static void removePermissions(Set<String> permissionsToRemove, Map<String, Id> mapOfPermissionToAssignment){
        if(permissionsToRemove.isEmpty()){
            return;
        }

        List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
        for(String permission: permissionsToRemove){
            assignments.add(new PermissionSetAssignment(Id = mapOfPermissionToAssignment.get(permission)));
        }
        delete assignments;
    }

    /**
     * @description Insert Permission Assignments
     * @param {Set} permissionsToAdd
     * @param {Set} mapOfPermissionSetNameToId   permission Name -> PermissionSet Id
     */
    private static void addPermissions(Set<String> permissionsToAdd, Id userId, Map<String, Id> mapOfPermissionSetNameToId){
        if(permissionsToAdd.isEmpty()){
            return;
        }

        List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
        for(String permission: permissionsToAdd){
            assignments.add(new PermissionSetAssignment(AssigneeId = userId, PermissionSetId = mapOfPermissionSetNameToId.get(permission)));
        }
        insert assignments;
    }

    /**
     * @description Set Retail all
     * Retains items that are in both Set(No Source/ Target change)
     * @param {Set} source
     * @param {Set} target
     * @return {Set} source intersection target
     */
    private static Set<String> retainAll(Set<String> source, Set<String> target){
        Set<String> copy = new Set<String>(source);
        copy.retainAll(target);
        return copy;
    }

    /**
     * @description Set Remove all
     * Remove items from Source if contains target (No Source/ Target change)
     * @param {Set} source
     * @param {Set} target
     * @return {Set} source - target
     */
    private static Set<String> removeAll(Set<String> source, Set<String> target){
        Set<String> copy = new Set<String>(source);
        copy.removeAll(target);
        return copy;
    }
    /**
     * @userstory NCP-3772
     * @description 
     * @return  `List<D1_Menu_Item__mdt>`
     */    
    @AuraEnabled(cacheable = true)
    public static List<D1_Menu_Item__mdt> getMyAccountCards(){
        List<User> userObj = new List<User>();
        userObj = [SELECT Id, Name, LanguageLocaleKey,Available_Countries__c,LocaleSidKey FROM User WHERE Id=:userInfo.getUserId() LIMIT 1];
        return [SELECT Id, IsActive__c, Order__c, Tile_Icon__c, Required_Permission__c, MasterLabel,
                Category__c, D1_Menu_Item_Parent__c, Sub_Title__c, Navigation__c, D1_User_Locale_Setting__c,
                D1_User_Locale_Setting__r.Country_Code__c,D1_User_Locale_Setting__r.LocaleSidKey__c
                FROM D1_Menu_Item__mdt
                WHERE IsActive__c = true
                AND D1_Menu_Item_Parent__c = null AND D1_User_Locale_Setting__r.Country_Code__c =: userObj[0].Available_Countries__c

                AND D1_User_Locale_Setting__r.LanguageLocaleKey__c =: userObj[0].LanguageLocaleKey

                ORDER BY Order__c];
    }
    /**
     * @description 
     * @return  `boolean`
     */    
    @AuraEnabled(cacheable = true)
    public static boolean isMyContractPermissionExist(){
        Set<String> contractRecordTypes = new Set<String>{'Outlet','Group'};
        string allowedConStatus = system.Label.D1_Contract_Status_Lables;
        Set<String> allowedConStatusSet = new Set<String>(new List<String> (allowedConStatus.split(',')));
        List<Outlet_Contract__c> outletContractList = new List<Outlet_Contract__c>();
        Id contactId = [SELECT contactId FROM User WHERE Id = :userInfo.getUserId() LIMIT 1].contactId;
        if(contactId != null){
            outletContractList = [SELECT Contract__c, Contract__r.ContractNumber, 
                                                        Contract__r.Status, Contract__r.StartDate, Contract__r.Contract_End_Date__c 
                                                        FROM Outlet_Contract__c 
                                                        WHERE Contract__r.RecordType.Name IN :contractRecordTypes 
                                                        AND Contract__r.Status IN :allowedConStatusSet 
                                                        AND Outlet__c IN (SELECT AccountId 
                                                                            FROM AccountContactRelation 
                                                                            WHERE ContactId =:contactId)
                                                                            Order By Contract__r.StartDate DESC, Contract__r.Status ASC];
        }
        return (outletContractList.size()>0)?true:false;
    }

}