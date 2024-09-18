/**
@name D1_CustomCommunityThemeController
@description D1_CustomCommunityThemeController Class for populating User details.
@history
VERSION     AUTHOR           DATE       DETAIL
1.0        Saurav Paul    09/25/2020   
2.0        Sai Kumar      10/30/2020    NCP-660
3.0        Ajay        `  12/7/2020     NCP-1145
4.0        Manikant       29/07/2021    NCP-1334 added method (isCollectKegs)
5.0        Sai Kumar      08/02/2021    NCP-1983 added method (updateContactforPardot-update contact to pass data to pardot). 
6.0        Ajay           23/03/2021    NCP-2183(Multi Sold to)
7.0        Rubeena        16/07/2021    NCP-3739(HomePage Optimization)
8.0		   Subhrojit	  12/05/2022	NCP-6643(Customer Opt In)
9.0        Rithika        25/05/2022    NCP-6758(sign up)
10.0       Swagat         13/06/2022    NCP-6838(POS Order Email Trigger for New user registered Via BE or a secondary user)
11.0       Kapil Baliyan  15/07/2022    NCP-7124
12.0       Pratap Sen     08/12/2022    NCP-7458
13.0	   Subhrojit      25/01/2023    NCP-7889
14.0       Prasanth T     20/03/2024    151925- Created method to send current contact subscriptions.
15.0       Mukesh Kanth   22/05/2024    152907- Updated Region Selector, Profile Drop Down (User initials, Account Name)
**/
@SuppressWarnings('PMD.TooManyFields')
public without sharing class D1_CustomCommunityThemeController {
    
    //This wrapper haas been used to get User detail and Account Name
    public class UserWrapper{
        final String contentDownloadUrl = System.Label.D1_CommunityPrefix.replace('/s','') + System.Label.D1_ContentDownloadURL;
        @AuraEnabled public string countryFullName; // Great Britain
        @AuraEnabled public string countryName; // GB
        @AuraEnabled public String languageLocale; // en_GB
        @AuraEnabled public String countryLang; // GB (en)
        @AuraEnabled public String flagUrl; // /sfc/servlet.shepherd/version/download/0687Z0000015qp5QAA
        @AuraEnabled public string targetUrl; // gb.diageo-one.com
        @AuraEnabled public String userName; // KAPIL BALIYAN
        @AuraEnabled public String accName;  // DUMMY GB ACCOUNT
        @AuraEnabled public Boolean isSubscribed; // true
        @AuraEnabled public Boolean showOptInPopup; //NCP-6643
        @AuraEnabled public Double counter;
        @AuraEnabled public String npsSurveyUrl;
        @AuraEnabled public String npsSurveyContent;
        @AuraEnabled public String npsSurveyTitle;
        @AuraEnabled public Boolean displayNpsSurvey;
        @AuraEnabled public Boolean displayPartnerPlusReminder;//NCP-7458
        @AuraEnabled public String contactSubscription;//151925
        @AuraEnabled public String firstName;//152907
        @AuraEnabled public String lastName;//152907

        //Constructor
        UserWrapper(){
            System.debug(LoggingLevel.INFO, 'EmptyBlock');
        }

        //Constructor
        UserWrapper(User user, D1_Setting__c d1Settings, Account effectiveAccount){  
            String  countryLanguage =  d1Settings.Market__r.Code__c + ' (' + d1Settings.Language__c.left(2) +')';
            String  targetUrl = d1Settings.Market__r.Domain__c;
            this.targetUrl = targetUrl;
            String flagVersionId = d1Settings.Market__r.Flag_Content_Version_Id__c;
            this.countryFullName = d1Settings.Market__r.Name;
            this.countryName = d1Settings.Market__r.Code__c;
            this.languageLocale = user.LanguageLocaleKey;
            
            if(flagVersionId!=null){
                this.flagUrl = contentDownloadUrl + flagVersionId;
            }
            //152907
            this.countryLang = flagVersionId != null ? ' (' + d1Settings.Language__c.left(2) +')': countryLanguage;
            this.firstName = user.FirstName;
            this.lastName = user.LastName;
            this.userName = user.Name;
            this.accName = effectiveAccount != null ? effectiveAccount.Name : '';
            this.isSubscribed = user.ContactId != null ? user.Contact.MD_SubscriptionDate__c != null : true;
            this.counter = user.Contact.D1_Login_Counter__c;
            this.npsSurveyContent = d1Settings.NPS_Survey_content__c;
            this.npsSurveyTitle = d1Settings.NPS_survey_Title__c;
            this.npsSurveyURL = d1Settings.NPS_Survey_URL__c;
            this.showOptInPopup = showOptInPopup(user, d1Settings, effectiveAccount);
            this.displayPartnerPlusReminder = displayPartnerPlusReminder(user, d1Settings, effectiveAccount);
            this.displayNpsSurvey = displayNpsSurvey(user, d1Settings, effectiveAccount);
            this.contactSubscription = user.contact.MD_ContactSubscriptions__c;//151925
        }
    }
    
    @TestVisible
    private static Boolean showOptInPopup(User user, D1_Setting__c d1Settings, Account effectiveAccount){
        Boolean doesShowPopup = false;
        if(user.Contact.MD_SubscriptionDate__c != null){                
            if(((String.isBlank(user.Contact.MD_ContactSubscriptions__c) 
                    && user.Contact.D1_Last_opt_in_reminder_date__c==null)) || // existing user scenario NCP-6640
                ((String.isBlank(user.Contact.MD_ContactSubscriptions__c)) && //NCP-6643
                    (d1Settings.D1_opt_in_reminder_interval__c !=null && user.Contact.D1_Last_opt_in_reminder_date__c != null &&
                    user.Contact.D1_Last_opt_in_reminder_date__c.addDays(Integer.valueOf(d1Settings.D1_opt_in_reminder_interval__c)) <= System.today()))) { //NCP-6643 
                        doesShowPopup = true;
            }
        } 
        return doesShowPopup;
    }

    @TestVisible
    private static Boolean displayPartnerPlusReminder(User user, D1_Setting__c d1Settings, Account effectiveAccount){     
        Boolean displayPartnerPlusReminder = false;
        List<AccountContactRelation> accConRel = new List<AccountContactRelation>();
        accConRel = [SELECT Id FROM AccountContactRelation WHERE AccountId =: effectiveAccount.Id
                     AND ContactId =: user.ContactId 
                     AND D1_Active__c = true
                     AND D1_User_Role__c = 'Primary'
                     AND Account.Direct_Customer__c = false];
        if(!accConRel.isEmpty() && !effectiveAccount.Partner_Plus_Enabled__c && d1Settings.Partner_Plus_Enabled__c && d1Settings.Partner_OptIn_Reminder_Interval__c != null && d1Settings.Partner_OptIn_Reminder_Interval__c.intValue() != 0){            
            if(effectiveAccount.D1_Partner_Reminder_Display_Login_Count__c == null ||
               ((user.Contact.D1_Generic_Login_Counter__c.intValue() != effectiveAccount.D1_Partner_Reminder_Display_Login_Count__c.intValue())
                && (Math.mod(user.Contact.D1_Generic_Login_Counter__c.intValue() - effectiveAccount.D1_Partner_Reminder_Display_Login_Count__c.intValue(),d1Settings.Partner_OptIn_Reminder_Interval__c.intValue()) == 0))){
                displayPartnerPlusReminder = true; 
            } 
        }
        return displayPartnerPlusReminder;
    }

    @TestVisible
    private static Boolean displayNpsSurvey(User user, D1_Setting__c d1Settings, Account effectiveAccount){
        Boolean displayNpsSurvey = false;
        if(!String.isBlank(d1Settings.NPS_Survey_URL__c) && user.Contact.D1_Login_Counter__c != null && user.Contact.D1_Login_Counter__c != 0 && user.Contact.D1_Login_Counter__c != 999){
            if(user.Contact.D1_Login_Counter__c == 1){
                displayNpsSurvey = true; 
            }
            else if(d1Settings.NPS_Session_Frequeny_Reminder__c != null && d1Settings.NPS_Session_Frequeny_Reminder__c.intValue() != 0 && (math.mod(user.Contact.D1_Login_Counter__c.intValue(),d1Settings.NPS_Session_Frequeny_Reminder__c.intValue()) == 0)){
                displayNpsSurvey = true;
            }
        } 
        return displayNpsSurvey;
    }

    /**
     * @Name : npsBlockHandler
	 * @Description : This method is used to block NPS Popup for current logged-in User (NCP-7889)
	 */
    @AuraEnabled
    public static void npsBlockHandler(String userId){
        try {
            userId = (userId == null) ? UserInfo.getUserId() : userId;
            if(System.UserInfo.getUserType() != 'Guest'){
                List<User> loggedInUser = [SELECT Id, ContactId FROM User WHERE Id =:userId];
                if(!loggedInUser.isEmpty() && loggedInUser[0].ContactId != null){
                    Contact contactRecord = new Contact(Id = loggedInUser[0].ContactId, D1_Login_Counter__c = 999);
                    update contactRecord;
                }
            }
        }catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }



    //This method is used to populate the Userinfo and AccountName
    //Updated part of NCP-2183
    @AuraEnabled
    public static UserWrapper getUserAndAcc(String userId){
        userId = (userId == null) ? UserInfo.getUserId() : userId;
        if(System.UserInfo.getUserType() == 'Guest'){
            return null;
        }else{
            //152907
            List<User> loggedInUser = [SELECT Id, Name, FirstName, LastName, Available_Countries__c, Effective_Account_Id__c,Contact.MD_SubscriptionDate__c, Contact.MD_ContactSubscriptions__c, Contact.D1_Last_opt_in_reminder_date__c,
                                        ContactId, Contact.Registration_Source__c, Contact.D1_Login_Counter__c, D1_User_Type_Id__c, LanguageLocaleKey, Contact.D1_Generic_Login_Counter__c
                                        FROM User 
                                        WHERE Id =:userId LIMIT 1];

            if(loggedInUser.isEmpty()){
                return new UserWrapper();
            }
            
            User loggedUser = loggedInUser[0];
            
            List<D1_Setting__c> d1SettingObj = [SELECT Id, Market__r.Name, Market__r.Code__c, Language__c, Market__r.Flag_Content_Version_Id__c, Market__r.Domain__c,
                                                D1_opt_in_reminder_interval__c, NPS_Survey_URL__c, NPS_Survey_content__c, NPS_survey_Title__c, NPS_Session_Frequeny_Reminder__c, 
                                                Partner_Plus_Enabled__c, Partner_OptIn_Reminder_Interval__c
                                                FROM D1_Setting__c 
                                                WHERE Language__c =:loggedUser.LanguageLocaleKey
                                                AND Market__r.Code__c = :loggedUser.Available_Countries__c];

            if(d1SettingObj.isEmpty()){
                return new UserWrapper();
            }

            Account effectiveAccount = new Account();
            //NCP-2183 : Get Effective Account Details
            if(String.isNotBlank(loggedUser.Effective_Account_Id__c)){
                effectiveAccount = getEffectiveAccountInfo(loggedUser.Effective_Account_Id__c);

                //Update Account Source Status
                if(effectiveAccount != null){
                    //effectiveAccName = effectiveAccount.Name;
                    updateAccountSource(effectiveAccount, loggedUser);
                }   
            }    

            UserWrapper usWrapObj = new UserWrapper(loggedUser, d1SettingObj[0], effectiveAccount);
            return usWrapObj;
        }
    }

    //To remove My Diageo Profile and Permission Set  
    @AuraEnabled(cacheable = true)   
    public static void removeMyDiageoPermissionSet(String userId){
        List<AccountContactRelation> accConRelationList = new   List<AccountContactRelation> ();
        List<Contact> contactList = new   List<Contact> ();
        List<String> mdPermissionSetName = new List < String > { 'MD - MyDiageo User', 'MD - Community Manager', 'CMS User'};  
        List<User> loggedInUser = [SELECT Id, Name,ProfileId,ContactId,Profile.Name, LanguageLocaleKey ,Contact.AccountId, Contact.Account.Name,Available_Countries__c,D1_User_Type__c,
                                    Contact.Account.D1_Registration_Status__c,Contact.Registration_Source__c 
                                    FROM User 
                                    WHERE Id =:userId];
        // Map<ID, PermissionSet> permSetId =   new Map<ID, PermissionSet>([SELECT Id FROM PermissionSet WHERE Label IN: mdPermissionSetName ]);
        List< PermissionSet> permSetId = [SELECT Id FROM PermissionSet WHERE Label IN: mdPermissionSetName];
        
        List<PermissionSetAssignment> listPermissionSetAssignment = new List<PermissionSetAssignment>();
        if(loggedInUser!= null && !loggedInUser.isEmpty()){
            if(loggedInUser[0].Profile.Name =='DiageoOne External User' ){
                listPermissionSetAssignment=[SELECT Id from PermissionSetAssignment WHERE PermissionSetId IN: permSetId AND AssigneeId = : loggedInUser[0].Id];
                                
                accConRelationList = [SELECT Id,ContactId,Contact_Type__c,D1_Roles__c,MD_AssignedPermissions__c,D1_User_Role__c,D1_Active__c 
                                      FROM AccountContactRelation WHERE accountId =:loggedInUser[0].Contact.accountId
                                      AND Contactid =: loggedInUser[0].ContactId];
                
                contactList =[SELECT Id,D1_Pardot_Is_Log_in__c from Contact where Id =: loggedInUser[0].ContactId and D1_Pardot_Is_Log_in__c =:False];
            }                                                                                                                                                             
            
        }
        
        if(listPermissionSetAssignment.size()>0){
            delete listPermissionSetAssignment;
            if(accConRelationList.size()>0){ 
                string accConRelationrecord = JSON.Serialize(accConRelationList[0]);
                updateAccountContact(accConRelationrecord);
            }
        }
        if(contactList.size()>0){
            string stringContact = JSON.Serialize(contactList[0]);
            updateContactforPardot(stringContact);
        }  
    }

    //Helper Method for updating ACR Permission while user is navigating from MD to D1
    @future
    public static void updateAccountContact(string stringaccountContactReln){
        AccountContactRelation accountContactReln = (AccountContactRelation) JSON.deserialize(stringaccountContactReln, SObject.class);
        accountContactReln.D1_Active__c = true;
        accountContactReln.D1_Roles__c = 'Default Access';//'My Account Management;Content Management';
        if(accountContactReln.MD_AssignedPermissions__c != null && accountContactReln.MD_AssignedPermissions__c.contains('Manage Users')){
            accountContactReln.D1_Roles__c = accountContactReln.D1_Roles__c + ';User Management;';
        }
        if(accountContactReln.MD_AssignedPermissions__c != null && accountContactReln.MD_AssignedPermissions__c.contains('Order')){
            accountContactReln.D1_Roles__c = accountContactReln.D1_Roles__c + ';Ordering';
        }
        update accountContactReln;
    }

    /*******************************************************************  
    * Story: NCP-1983
    * Purpose:  Update contact to pass data to Pardot for Onboard Process 
    * Parameters:Contact JSON string
    * Returns: null
    * Called from removeMyDiageoPermissionSet method
    ********************************************************************/

    @future
    public static void updateContactforPardot(string stringContact){
        Contact contactRecord = (Contact) JSON.deserialize(stringContact, SObject.class);
        contactRecord.D1_Pardot_Is_Log_in__c=True;
        update contactRecord;
    }
        
    /*******************************************************************  
    * Story: NCP-1145
    * Purpose:  Place order link creation
    * Parameters:Nil
    * Returns: Id procust id
    * Throws: AuraHandledException if any exception   
    *REFACTOR*
    ********************************************************************/
    @AuraEnabled
    public static String getProductCategoryId(){
       
        List<ProductCategory> categories = [SELECT id  
                                            FROM ProductCategory  
                                            WHERE ParentCategoryId =null
                                            AND IsNavigational = true
                                            AND CatalogId IN(
                                                SELECT ProductCatalogId 
                                                FROM WebStoreCatalog
                                                WHERE ProductCatalog.name =: System.Label.D1_Commerse_CatalogName
                                                AND SalesStore.name =: System.Label.D1_Commerse_StoreName
                                            )];
        if(!categories.isEmpty()){
            return categories[0].id;
        }

        return null;
    }
    
    //Sai to Move Cart methods once tested
    //Move this to Cart Related Class
    public class CartWrapper{
        @AuraEnabled
        public List<String> datesArray{get;set;}
        @AuraEnabled
        public List<String> oSplitArray{get;set;}
        @AuraEnabled
        public List<String> shipToNumber{get;set;}
    }

    /* Commented out this method since it not used anywhere
    //Move this to Cart Related Class
    @AuraEnabled 
    public static Boolean IsDeliveryDatesValid(CartWrapper cartWrap){
        Boolean flag =false;
        List < User > usrList = new List < user > ();
        Map<Id,OrderSplit__c> mapOsplit = new Map<Id,OrderSplit__c>([SELECT Sales_Area__c, Delivery_Day_Series__c, Delivery_day_holiday_shift_ripple__c, 
                                                                     Description__c, Exempt_From_Weight_Validation__c, Is_lead_time_in_business_days__c, 
                                                                     Lead_Time_in_day__c, Max_future_order_days__c, SAP_OrderSplit_ID__c, Use_Plant_Exception_Calendar__c, 
                                                                     Cut_Off_Time__c, Market_Description__c, Name, Id 
                                                                     FROM OrderSplit__c 
                                                                     WHERE  Id=:cartWrap.oSplitArray]);
        usrList = [Select Id, ContactId, Contact.AccountId, Contact.Account.Salesforce_Delivery_Days_Keg__c,Effective_Account_Id__c 
                   FROM User where id =: UserInfo.getUserId()];
        //if one order split found. Then check if date is valid
        if(cartWrap.oSplitArray.size() == 1){
            return(checkCutOffTime(usrList,mapOsplit.get(Id.valueOf(cartWrap.oSplitArray[0])),cartWrap.datesArray[0],cartWrap.shipToNumber[0]));            
        }
        else if(cartWrap.oSplitArray.size() == 2){//if 2 order splits found.
            String deliveryDate0;
            String orderSplit0='';
            String shipToNumber0 = '' ;
            deliveryDate0 = cartWrap.datesArray[0];
            orderSplit0 = cartWrap.oSplitArray[0];
            shipToNumber0 = cartWrap.shipToNumber[0];
            // check if 1st orderSplit.date is valid.
            if(checkCutOffTime(usrList,mapOsplit.get(Id.valueOf(orderSplit0)),deliveryDate0,shipToNumber0)){
                String deliveryDate1;
                String orderSplit1='';
                String shipToNumber1 = '' ;
                deliveryDate1 = cartWrap.datesArray[1]; 
                orderSplit1 = cartWrap.oSplitArray[1];
                shipToNumber1 = cartWrap.shipToNumber[1];
                //If not then check for 2nd orderSplit.date
                return(checkCutOffTime(usrList,mapOsplit.get(Id.valueOf(orderSplit1)),deliveryDate1,shipToNumber1));
            }else{ 
                return false;
            }
        }
        return flag;
    }
     */


     /* Commented out this method since it not used anywhere
    //Move this to Cart Related Class
    public static boolean checkCutOffTime(List<User> usrList, OrderSplit__c oSplit, String delivery_date, String shipToNumber ){
        List < D1_OrderdeliverdatesCntrl.DeliveryDatesWrapper > deliveryDatesList1 = new List < D1_OrderdeliverdatesCntrl.DeliveryDatesWrapper > ();
        if (usrList[0].Effective_Account_Id__c != null) {
            if(oSplit !=null && oSplit.Id != null){                              
                deliveryDatesList1 =D1_OrderdeliverdatesCntrl.getDeliveryDates(oSplit.Id, usrList[0].Effective_Account_Id__c, shipToNumber);
                if(deliveryDatesList1!=null){
                    for(D1_OrderdeliverdatesCntrl.DeliveryDatesWrapper dObj: deliveryDatesList1){
                        if(dObj.deliveryDates.contains(Date.valueOf(delivery_date))){
                            return true;
                        }
                    }
                }
            }
        }
        return false;
    }
    */

    /**
     * Get effective account
     * @userStory NCP-2183 
     * @param {Id} effectiveAccountId
     * @return {Account}
     */
    private static Account getEffectiveAccountInfo(Id effectiveAccountId){
        List<Account> accounts = [SELECT id,Name,D1_Registration_Status__c,Partner_Plus_Enabled__c,D1_Partner_Reminder_Display_Login_Count__c
                                  FROM Account 
                                  WHERE id=:effectiveAccountId];
        return accounts.isEmpty() ? new Account() : accounts[0]; 
    }

    //Method to Get User Details
    /*REFACTOR*/
    @AuraEnabled(cacheable = true)
    public static List<D1_User_Type__c> getUserDetails(string userId){
        try {
            List<D1_User_Type__c> userTypeList = new List<D1_User_Type__c>();
            User loggedInUser = [SELECT  D1_User_Type_Id__c FROM User WHERE Id =:userId LIMIT 1];
            if(string.isNotBlank(loggedInUser.D1_User_Type_Id__c)){
                userTypeList = [SELECT Id, Chat_Button_Id__c,WhatsApp_Number__c FROM D1_User_Type__c WHERE Id =:loggedInUser.D1_User_Type_Id__c];
            }
            return userTypeList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    //Method to Update Account Source
    private static void updateAccountSource(Account acc, User usr){
        String registrationStatus = acc.D1_Registration_Status__c;
        String registrationSource = usr.Contact.Registration_Source__c;
        if(registrationStatus == 'AppInvited' && (registrationSource == 'EDGE 365' || registrationSource == 'Diageo One')){
            Account account = new Account(Id = acc.Id, D1_Registration_Status__c = 'AppSubscribed');
            update account;
        }
    }
    
    //Method to get User Type
    @AuraEnabled
    public static string getUserType(){
        return UserInfo.getUserType();
    }

    //Method to populate selected Subcription source on Contact Record from the D1_ConsentPopup
    @AuraEnabled
    public  static void  setSubscription(String allSubscriptionString){
        List<User> usrList = new List<user>(); 
        Set<Id> accIdSet = new Set<Id>();
        Map<Id, Datetime> acrDateMap = new Map<Id, Datetime>();
        List<AccountContactRelation> acrToUpdate = new List<AccountContactRelation>(); //NCP-6838
        usrList = [Select Id, ContactId, Contact.MD_SubscriptionDate__c,Contact.MD_ContactSubscriptions__c,Contact.D1_opt_in_Success_date__c, Contact.D1_Last_opt_in_reminder_date__c FROM User where id =:UserInfo.getUserId()];
        Contact conRec = new Contact(ID =usrList[0].ContactId);
        if( allSubscriptionString != null){            
            conRec.MD_ContactSubscriptions__c = allSubscriptionString;
            conRec.MD_SubscriptionDate__c = Datetime.now();
            conRec.D1_Last_opt_in_reminder_date__c = System.today();//NCP-6640
            update conRec;
        }//NCP - 6638

        List<AccountContactRelation> acrList = [SELECT Id, Last_POS_Order_Date__c, AccountId FROM AccountContactRelation WHERE ContactId =:conRec.Id 
                                                AND D1_Active__c = True 
                                                AND D1_Roles__c INCLUDES ('POS & Equipment Ordering')];
                               
        //Create Account Id Set for Logged In User                     
        for(AccountContactRelation acr : acrList){
            accIdSet.add(acr.AccountId);
        }

        //Get Existing ACR for accIdSet where Contact is other than Logged In User                                  
        for(AccountContactRelation acr : [SELECT Id, Last_POS_Order_Date__c, AccountId, Account.Last_POS_Order_Date__c FROM AccountContactRelation
                                            WHERE ContactId !=:conRec.Id AND AccountId IN :accIdSet
                                            AND D1_Active__c = True 
                                            AND D1_Roles__c INCLUDES ('POS & Equipment Ordering') 
                                            AND Account.Last_POS_Order_Date__c != NULL ORDER BY AccountId, Account.Last_POS_Order_Date__c ASC])
        {
            if(acrDateMap.containsKey(acr.AccountId)){
                if(acrDateMap.get(acr.AccountId) > acr.Last_POS_Order_Date__c){
                    acrDateMap.put(acr.AccountId, acr.Account.Last_POS_Order_Date__c);
                }
            }
            else{
                acrDateMap.put(acr.AccountId, acr.Account.Last_POS_Order_Date__c);
            }
        }

        //Iterate over acrList and update Last POS Order Date
        for(AccountContactRelation acr : acrList){
            if(acrDateMap != null && acrDateMap.size()>0 && acrDateMap.containsKey(acr.AccountId)){
                acr.Last_POS_Order_Date__c = acrDateMap.get(acr.AccountId);
            }else{
                acr.Last_POS_Order_Date__c = System.Now();
            }
            acrToUpdate.add(acr);
        }
        if(!acrToUpdate.isEmpty()){
            update acrToUpdate;
        }
    }
    
    //Method to populate selected Subcription source on Contact Record from the d1CustomerOptIn (NCP-6643)
    @AuraEnabled
    public  static void  setOptInSubscription(String allSubscriptionString){
        List<User> usrList = new List<user>();
        usrList = [Select Id, ContactId, Contact.MD_SubscriptionDate__c,Contact.MD_ContactSubscriptions__c,Contact.D1_opt_in_Success_date__c, Contact.D1_Last_opt_in_reminder_date__c FROM User where id =:UserInfo.getUserId()];
        Contact conRec = new Contact(ID =usrList[0].ContactId);
        if( allSubscriptionString != null && allSubscriptionString != ''){
            conRec.MD_ContactSubscriptions__c = allSubscriptionString;
            conRec.D1_opt_in_Success_date__c = System.today();
            conRec.D1_Last_opt_in_reminder_date__c = System.today();//NCP-6643
            update conRec;
        }else{ //NCP-7124
            conRec.D1_Last_opt_in_reminder_date__c = System.today();
            update conRec;
        }
    }
    
    @AuraEnabled(cacheable = true)//NCP-6758
    public static D1_Setting__c getD1Setting(String countryCode,string languageCode) {
        list < D1_Setting__c > d1Setting = new list <D1_Setting__c> ();
        d1Setting = [select Self_Registration__c from D1_Setting__c 
                      where Language__c=:languageCode and Market__r.Code__c =:countryCode];
        return d1Setting[0];
    }
}