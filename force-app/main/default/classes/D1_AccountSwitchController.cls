/**
 * @name : D1_AccountSwitchController
 * @description : Account Switch
 * @history
 * VERSION     AUTHOR         DATE               DETAIL
 * 1.0         Ajay           25/03/2021         Initial Development (NCP-2183)
 * 2.0			Rubeena		   02/06/2021		  NCP-3457 [Changes for Multiple Sold-To for Direct Customer]
 **/
public without sharing class D1_AccountSwitchController {
    
    public class AccountWrapper{
        @AuraEnabled public Id id{get;set;}
        @AuraEnabled public String name{get;set;}
        @AuraEnabled public String accountNumber{get;set;}
        @AuraEnabled public String address{get;set;}
        @AuraEnabled public Boolean isSelected{get;set;}
        @AuraEnabled public Integer slNo{get;set;}

        public AccountWrapper(Account account, Boolean isSelected, Integer slNo){
            this.id = account.id;
            this.name = setDefaultIfNull(account.name);
            this.accountNumber = setDefaultIfNull(account.KUNNR__c);
            this.address = getAddress(account.BillingAddress);
            this.isSelected = isSelected;
            this.slNo = slNo;
        }
        /**
         * @description 
         * @param address 
         * @return  `String`
         */        
        private String getAddress(Address address){
            address = address == null ? new Address() : address;

            String street = address.getStreet();
            String city = address.getCity();
            String country = address.getCountry();

            List<String> addressList = new List<String>();
            if(!String.isEmpty(street)){
                addressList.add(street);
            }
            if(!String.isEmpty(city)){
                addressList.add(city);
            }
            if(!String.isEmpty(country)){
                addressList.add(country);
            }

            return  String.join(addressList,', ');
        }
        /**
         * @description 
         * @param value 
         * @return  `String`
         */        
        private String setDefaultIfNull(String value){
            return value == null ? '' : value;
        }
    }
    
    /**
     * Retrieve related accounts 
     * @param {Id} userId
     */
    @AuraEnabled(cacheable=true)
    public static Object getRelatedAccounts(Id userId){
        User currentUser = getCurrentUserInfo(userId);
        
        final String pfType = 'Sold-To';
		Set<Id> accountIdSet = new Set<Id>();
        List<AccountWrapper> relatedAccounts = new List<AccountWrapper>();
        Integer slNo = 1;
        for(AccountContactRelation relation: [SELECT id,
                                              Account.Id, Account.Name, Account.KUNNR__c, Account.BillingAddress 
                                              FROM AccountContactRelation
                                              WHERE D1_Active__c = true
                                              AND ContactId =: currentUser.ContactId
                                              AND AccountId != null
                                              ORDER BY Account.Name ASC
                                             ]
        ){
            //NCP-3457
            if(currentUser.D1_User_Type__c != 'Direct Buyer'){
                relatedAccounts.add(new AccountWrapper(relation.Account, relation.Account.Id == currentUser.Effective_Account_Id__c, slNo++));
            }
            else{
                accountIdSet.add(relation.Account.Id);
            }
        }

        if(!accountIdSet.isEmpty()){
            Set<Id> soldToIds = new Set<Id>();
            for(PNR_Partner_Function__c pf : [SELECT Id, PNR_Sold_To__c,PNR_Customer_No__c,PNR_Customer_No__r.Name,
                                              		PNR_Customer_No__r.Id,PNR_Customer_No__r.KUNNR__c,PNR_Customer_No__r.BillingAddress
                                             		FROM PNR_Partner_Function__c
                                             		WHERE PNR_Type__c =: pfType
                                             		AND PNR_Sold_To__c IN : accountIdSet
                                             		ORDER BY PNR_Customer_No__r.Name
                                             ])
            {
                if(!soldToIds.contains(pf.PNR_Customer_No__c)){
                    soldToIds.add(pf.PNR_Customer_No__c);
                    relatedAccounts.add(new AccountWrapper(pf.PNR_Customer_No__r, pf.PNR_Customer_No__r.Id == currentUser.Effective_Account_Id__c, slNo++));
                }
            }
        }
        return relatedAccounts;
    }

    /**
     * @description Update Effective Account & Recalculate Permission
     * @param {Id} effectiveAccountId
     * @param {Id} userId
     * @return {Map} permissionMap
     */
    @AuraEnabled
    public static Map<String,Object> updateEffectiveAccountId(Id effectiveAccountId, Id userId){
        userId = String.isEmpty(userId) ? UserInfo.getUserId() : userId;

        try{
            update new User(Id=userId, Effective_Account_Id__c = effectiveAccountId);

            return D1_CommunityUtil.assignPermission(null, userId);
        }catch(Exception ex){
            throw ex;
        }
    }

    /**
     * Get Current User, defaults to logged in user
     * @param [Id] userId
     */
    public static User getCurrentUserInfo(Id userId){
        userId = userId == null ? UserInfo.getUserId() : userId;

        List<User> users = [SELECT id, 
                            AccountId,Effective_Account_Id__c, ContactId, D1_User_Type_Id__c, Available_Countries__c,LanguageLocaleKey,D1_User_Type__c
                            FROM User
                            WHERE id=: userId];
        if(users.isEmpty()){
            throw new AuraHandledException('Access Denied(User)');
        }
        
        return users[0];
    }
    /**
     * @description 
     * @return  `Map<String, String>`
     */    
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getPagePermissions(){
        Map<String, String> pagePermissionMap = new Map<String, String>();
        for(D1_Page_Permission_Setting__mdt d1PagePermission : [SELECT Page_Name__c, Custom_Permission__c FROM D1_Page_Permission_Setting__mdt]){
            pagePermissionMap.put(d1PagePermission.Page_Name__c, d1PagePermission.Custom_Permission__c);
        }
        return pagePermissionMap;
    }
    /**
     * @description 
     * @return  `Map<String, String>`
     */    
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getPageMap(){
        Map<String, String> pageMap = new Map<String, String>();
        for(D1_Community_Page_Map__mdt d1PageMap : [SELECT Page_Name__c, Parent_Page_Name__c FROM D1_Community_Page_Map__mdt]){
            pageMap.put(d1PageMap.Page_Name__c, d1PageMap.Parent_Page_Name__c);
        }
        return pageMap;
    }

    /**
     * @description 
     * @return  `Map<String, Object>`
     */    
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getAccountPermissionData(){
        Map<String, Object> mapOfData = new Map<String, Object>();

        mapOfData.put('permission', getPagePermissions());
        mapOfData.put('pageMap', getPageMap());
        mapOfData.put('categoryId', D1_CustomCommunityThemeController.getProductCategoryId());

        return mapOfData;
    }
}