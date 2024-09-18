/*
 * @name: D1_DeliveryController
 * @Discroption : Non Commerce Delivery Address controller
 * @History
 * -
 * VERSION     AUTHOR         DATE       DETAIL
 * 1.0         Ajay           3/1/21     Initial Development (NCP-2068,69)
 * 2.0         Kapil Baliyan  13/02/2023 NCP-7886
 **/
public without sharing class D1_DeliveryController {
    
    public class DeliveryAddress{
        @AuraEnabled public Id addressId{get;set;}
        @AuraEnabled public String addressName{get;set;}
        @AuraEnabled public String shipToNumber{get;set;}
        @AuraEnabled public String address{get;set;}
        @AuraEnabled public Boolean isInDirect {get;set;} //NCP-7886

        DeliveryAddress(Account account, Boolean isName2ValueCheck, Boolean isInDirect){
            account = account == null ? new Account() : account;
            string accountName2 = '';              
            if(isName2ValueCheck){
                accountName2 = account.Name2__c != null ? ', ' +'<br> ' + account.Name2__c : '';                    
            }
            this.addressId = account.id;
            this.addressName = setDefaultIfNull(account.Name) + accountName2;
            this.shipToNumber = setDefaultIfNull(account.KUNNR__c);
            this.address = getAddress(account.BillingAddress);
            this.isInDirect = isInDirect;//NCP-7886
        }
        /**
         * @description 
         * @param deliveryAddressObj 
         * @return  `String`
         */        
        private String getAddress(Address deliveryAddressObj){
            deliveryAddressObj = deliveryAddressObj == null ? new Address() : deliveryAddressObj;

            String street = deliveryAddressObj.getStreet();
            String city = deliveryAddressObj.getCity();
            String country = deliveryAddressObj.getCountry();

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

        private String setDefaultIfNull(String value){
            return value == null ? '' : value;
        }
    }
    /**
     * @description Get Delivered To address
     * if Indirect user -> return current Account
     * else Returns PNR_Partner_Function__c.PNR_Customer_No__c 
     * Where PNR_Sold_To__c= current.Account & Type = Ship-To
     * @param userId 
     * @return  `List<DeliveryAddress>`
     */    
    @AuraEnabled(cacheable = true)
    public static List<DeliveryAddress> getDeliveredTo(Id userId){
        final String type = 'Ship-To';
        
        List<DeliveryAddress> addresses = new List<DeliveryAddress>();
        Account effectiveAccount = getAccountInfo(getCurrentUser(userId).Effective_Account_Id__c);
        boolean isName2ValueCheck = getD1Setting(userId).Name_2_value__c; 

        if(!effectiveAccount.Direct_Customer__c){
            addresses.add(new DeliveryAddress(effectiveAccount, isName2ValueCheck, true));
        }else{
            for(PNR_Partner_Function__c partnerFunction: [ SELECT id, 
                                                       PNR_Customer_No__r.id, PNR_Customer_No__r.Name, PNR_Customer_No__r.Name2__c, PNR_Customer_No__r.Country__c,PNR_Customer_No__r.KUNNR__c, PNR_Customer_No__r.BillingAddress
                                                       FROM  PNR_Partner_Function__c
                                                       WHERE PNR_Type__c =: type
                                                       AND PNR_Sold_To__c =: effectiveAccount.Id 
                                                       AND PNR_Customer_No__c != null]
            ){
                addresses.add( new DeliveryAddress(partnerFunction.PNR_Customer_No__r, isName2ValueCheck, false));
            }
        }

        return addresses;
    }

    /**
     * @description Get Current User, defaults to logged in user
     * @param [Id] userId
     */
    
    @testVisible
    private static User getCurrentUser(Id userId){
        userId = userId == null ? UserInfo.getUserId() : userId;

        List<User> users = [SELECT id, 
                            Effective_Account_Id__c,Available_Countries__c 
                            FROM User
                            WHERE id=: userId];
        
        if(users.isEmpty()){
            throw new AuraHandledException('Access Denied(User)');
        }
        return users[0];
    }
    /**
     * @description Get account details, from effective account id 
     * @param [Id] effectiveAccountId
     */
    @testVisible
    private static Account getAccountInfo(Id effectiveAccountId){
        List<Account> accounts = [SELECT id, Direct_Customer__c, Name,Name2__c,KUNNR__c, BillingAddress , Country__c
                            FROM Account
                            WHERE id= :effectiveAccountId];
        if(accounts.isEmpty()){
            throw new AuraHandledException('Access Denied(Account)');
        }
        return accounts[0];
    }
    
    /**
     * @description Get D1 Settings respective account
     * @param {List<String>} available countries
     * @param {String} language
     */
    @testVisible
    private static D1_Setting__c getD1Setting(Id userId){
        User currentUser = getCurrentUser(userId);
        List<String> availableCountry= currentUser.Available_Countries__c!=Null?currentUser.Available_Countries__c.split(';'):new List<String>();
        List<D1_Setting__c> d1Settings= [ Select id,Name_2_value__c from D1_Setting__c where Market__r.Code__c IN: availableCountry limit 1];

        if(d1Settings.isEmpty()){
            throw new AuraHandledException('Access Denied(D1 settings)');
        }
        return d1Settings[0];
    }
}