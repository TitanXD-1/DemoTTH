/**
 * @name D1_RegistrationController
 * @purpose D1_RegistrationController Class for registration page 
 * @history
 * VERSION     AUTHOR           DATE       DETAIL
 * 1.0        Sudipta Nandi    08/29/20   Fetch registration Pages Configuration Details
 * 1.0         Ajay            08/29/20    Fetch Mobile configuration (NCP-83)
 * 1.0         Ayush           08/29/20    Fetch Usertype (NCP-21,NCP-80)
 * 2.0         Ajay            10/30/20    Move UserType Image from Contentent document to Static Resource(NCP-849) getUserType() changed
 * 3.0         Ajay            11/11/20    Google Captcha Integration(NCP-702)
 * 3.1         Abhishek        08/04/20    Added Visible_for_self_registration__c in getUserType(NCP-2870)
 * 4.0         Kapil Baliyan   01/08/21    NCP-4204 (getAccountListBasedonUIN)
 * 5.0         Mukesh/Mayukh   09/08/23    Calculate the Channel info from the chosen Tile (143110)
**/
public without sharing class D1_RegistrationController {
    
    class MobileConfig{
        final String contentDownloadUrl = System.Label.D1_CommunityPrefix.replace('/s','') + System.Label.D1_ContentDownloadURL;
        @AuraEnabled public Id id {get;set;}
        @AuraEnabled public String countryCode {get;set;}
        @AuraEnabled public String countryName {get;set;}
        @AuraEnabled public String prefix {get;set;}
        @AuraEnabled public String regex {get;set;}
        @AuraEnabled public String example {get;set;}
        @AuraEnabled public String flagUrl {get;set;}
        
        /**
         * @description MobileConfig
         * @param id 
         * @param countryCode 
         * @param countryName 
         * @param prefix 
         * @param regex 
         * @param example 
         */        
        public MobileConfig(Id id,String countryCode, String countryName,String prefix,String regex, String example){
            this.id = id;
            this.countryCode = countryCode;
            this.countryName = countryName;
            this.prefix = prefix;
            this.regex = regex;
            this.example = String.isBlank(example) ? '' : example;
        }
        
        /**
         * @description setFlagDetails
         * @param flagVersionId 
         */        
        public void setFlagDetails(String flagVersionId){
            flagVersionId = flagVersionId == null ? '': flagVersionId;
            this.flagUrl = flagVersionId=='' ? '': contentDownloadUrl + flagVersionId;
        }
    }

    /**
     * userStory NCP-2725
     * @description To get the Login User Assigned Country 
     * @return  `User`
     */    
    @AuraEnabled(cacheable = true)
    public static User getLogInUserCountry() {
        if(UserInfo.getUserType() != 'Guest') {
            id currentuserId = UserInfo.getUserId();
            User usercountry = [SELECT Id,Available_Countries__c,Effective_Account_Id__c,AccountId FROM User WHERE id =: currentuserId];
            return usercountry;
        }
        return NULL;
    }

    /**
     * @userStory NCP-83
     * @description get mobile configuration (Regex and flag realted to country)
     * @return  `List<Object>`
     * @exception AuraHandledException if any exception  
     */     
    @AuraEnabled(cacheable=true)
    public static List<Object> getMobileConfig(String validationType){
        Map<String, Integer> mapOfCountryCodeIndex = new Map<String, Integer>();
        List<MobileConfig> listOfMobileConfig = new List<MobileConfig>();
        integer index=0;

        try{
            for(Phone_Format__mdt format : [SELECT Id,Country_Code__c,Country_Name__c,Prefix__c,Regular_Expression__c,Example__c
                                            FROM Phone_Format__mdt
                                            WHERE label =: validationType
                                            ORDER BY Country_Name__c ASC])
            {
                listOfMobileConfig.add( new MobileConfig(format.Id, format.Country_Code__c, format.Country_Name__c, format.Prefix__c,format.Regular_Expression__c,format.Example__c));
                mapOfCountryCodeIndex.put(format.Country_Code__c, index++);
            }
            
            for(Geography__c geography : [SELECT Code__c,Flag_Content_Version_Id__c 
                                          FROM Geography__c
                                          WHERE Code__c IN: mapOfCountryCodeIndex.keySet()])
            {
                index = mapOfCountryCodeIndex.get(geography.Code__c);
                if(index!= null){
                    listOfMobileConfig[index].setFlagDetails(geography.Flag_Content_Version_Id__c);
                }
            }
        }catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
        
        return listOfMobileConfig;  
    }

    /**
     * @userStory NCP-702
     * @description Validate UIN page (+Google Captcha)
     * @param marketId 
     * @param uinApiName 
     * @param uinId 
     * @param captchaToken 
     * @return  `List<Object>`
     * @exception AuraHandledException if Captcha failed
     */     
    @AuraEnabled
    public static List<Object> validateUIN(String marketId, String uinApiName, String uinId, String captchaToken, String channel){ //143110 - Added channel as a parameter

        // 1. Validate Captcha
        if(new D1_CaptchaController().validateCaptchaToken(captchaToken) != true){
            throw new AuraHandledException('Captcha Validation Failed');
        }

        // 2. Validate UIN & return related Account
        return getAccountListBasedonUIN(marketId,uinApiName,uinId,channel); //143110 - Added channel as a parameter
    }

    /**
     * @userStory NCP-455, NCP-457
     * @description  Fecthing Account Details Based on Market Id,Unique API Name and UIN Number from Reg UIN Screen
     * @param marketId 
     * @param uinApiName 
     * @param uinId 
     * @return  `List<AccountDetailsWrapper>`
     */     
    @AuraEnabled
    public static List<AccountDetailsWrapper> getAccountListBasedonUIN(String marketId, String uinApiName, String uinId, String channel){
        List<Account> accountlist= new List<Account>();
        List<AccountDetailsWrapper> accountValues = new List<AccountDetailsWrapper>();

        String queryToQuery = 'SELECT Id, Direct_Customer__c, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode,Deletion_Flag_from_SAP__c, ';
        queryToQuery += 'BillingCountry, AccountNumber, Country__c, Market__c, Primary_Sales_Rep__c, Primary_Sales_Rep__r.Email, Global_Channel__c ';
        //NCP-4204 : Checking whether unique field is already exist in query string or not
        if(!queryToQuery.contains(uinApiName)){
            queryToQuery += ',' + uinApiName;
        }
        queryToQuery += ' FROM Account';
        queryToQuery += ' WHERE Country__c  = \'' + marketId + '\' ';
        queryToQuery += ' AND ' + uinApiName + ' = \'' + uinId +  '\' ';
        if(String.isNotBlank(channel)){ //143110 - Checking outlet channel
            queryToQuery += ' AND Global_Channel__c = \'' + channel +  '\' ';
        }

        accountlist = Database.query(queryToQuery); // NOPMD

        if(accountlist.size()>0){
            for(Account acc : accountlist){
                AccountDetailsWrapper accwrapper = new AccountDetailsWrapper();
                accwrapper.id = acc.id;
                accwrapper.name = acc.Name;
                accwrapper.billingStreet = acc.billingStreet;
                accwrapper.tick = false;
                accwrapper.accountNumber = acc.AccountNumber;
                accwrapper.billingStreet = acc.billingStreet;
                accwrapper.billingCity = acc.BillingCity;
                accwrapper.billingState = acc.BillingState;
                accwrapper.prmrySlsRepId = acc.Primary_Sales_Rep__c;
                accwrapper.prmrySlsRepEmail = acc.Primary_Sales_Rep__r.Email;
                accwrapper.directCustomer = acc.Direct_Customer__c;//NCP-2413
                accwrapper.isAccountDeleted = acc.Deletion_Flag_from_SAP__c;//NCP-3799
                accountValues.add(accwrapper);
        	}
        }
        return accountValues;
    }

    /**
     * @userStory NCP-21 || NCP-80
     * @description  Controller for checking UserType in Registration Page
     * @param countryLang 
     * @param country 
     * @return  `List<UserTypeWrapper>`
     */     
    @AuraEnabled
    public static List<UserTypeWrapper> getUserType(String countryLang, String country){ 
        List<D1_User_Type__c> availableUserType = new List<D1_User_Type__c>();
        List<UserTypeWrapper> userTypeValues = new List<UserTypeWrapper>();
        //NCP-2870:Added Visible_for_self_registration__c in available userType query       
        if(String.isNotBlank(countryLang) && String.isNotBlank(country)){
            //NCP-3670 - added new uin field and email field
           availableUserType = [SELECT D1_Setting__c,Id,Name,Tooltip_Text__c,UIN_Identifier__c,User_Type_Description__c,User_Type__c,Registration_Validation_Type__c,
                                D1_Setting__r.Market__c,UIN_Label__c,Customer_Service_Group__c,UIN_Label_In_Review_Page__c,UIN_unmatch_message__c,
                                UIN_placeholder_text__c,Redirect_to_Unknown_registration_form__c,D1_Auto_Redirection__c,Channel__c //143110
                                FROM D1_User_Type__c WHERE D1_Setting__r.Language__c =: countryLang AND D1_Setting__r.Market__r.Code__c =: country
                                AND Visible_for_self_registration__c = true ORDER BY User_Type__c DESC, Channel__c DESC];
                                
            if(availableUserType.size()>0){
                for(D1_User_Type__c userType : availableUserType){
                    UserTypeWrapper utw = new UserTypeWrapper();
                    utw.id = userType.id;
                    utw.name = userType.Name;
                    utw.description = userType.User_Type_Description__c;
                    utw.tick = false;
                    utw.uniqueIdentifierNumber = userType.UIN_Identifier__c;
                    utw.registrationValidationType = userType.Registration_Validation_Type__c;
                    utw.toolTipText = userType.Tooltip_Text__c;
                    utw.market = userType.D1_Setting__r.Market__c;
                    utw.userType = userType.User_Type__c;
                    utw.UINLabel = userType.UIN_Label__c;
                    utw.channel = userType.Channel__c; //143110
                    utw.userTypeRecord = userType;
                    
                    userTypeValues.add(utw);
                }
            }
        }
        return userTypeValues;
    }
    
    @AuraEnabled(cacheable=true)
    public static D1_Setting__c getD1Setting(String countryCode, string language){
        List<D1_Setting__c> d1Settings = [SELECT Self_Registration__c
                                          FROM D1_Setting__c WHERE
                                          Market__r.Code__c =: countryCode AND Language__c =: language];
        return d1Settings[0];
    }
    
    public class UserTypeWrapper {
        @AuraEnabled public String id {get; set;}
        @AuraEnabled public String name {get; set;}
        @AuraEnabled public String description {get; set;}
        @AuraEnabled public String conVerId {get; set;}
        @AuraEnabled public Boolean tick {get; set;}
        @AuraEnabled public String uniqueIdentifierNumber {get; set;}
        @AuraEnabled public String registrationValidationType {get; set;}
        @AuraEnabled public String toolTipText {get; set;}
        @AuraEnabled public String UINLabel {get; set;}
        @AuraEnabled public String market {get; set;}
        @AuraEnabled public String userType {get; set;}
        @AuraEnabled public String channel {get; set;} //143110
        @AuraEnabled public D1_User_Type__c userTypeRecord {get; set;}
    }

    public class AccountDetailsWrapper {
        @AuraEnabled public String id {get; set;}
        @AuraEnabled public String name {get; set;}
        @AuraEnabled public String accountNumber {get; set;}
        @AuraEnabled public String billingStreet {get; set;}
        @AuraEnabled public Boolean tick {get; set;}
        @AuraEnabled public String billingCity {get; set;}
        @AuraEnabled public String billingState {get; set;}
        @AuraEnabled public String prmrySlsRepId {get; set;}
        @AuraEnabled public String prmrySlsRepEmail {get; set;}
        @AuraEnabled public Boolean directCustomer {get; set;}//NCP-2413
        @AuraEnabled public Boolean isAccountDeleted {get; set;}//NCP-3799
    }
}