/**
* @name : D1_UtilityClass-
* @description : Utility Class for D1
* @history                                                            -                                                        -
* VERSION      AUTHOR              DATE                DETAIL-
* 1.0          Narayana            22/04/2022          Initial Development [NCP-6450,NCP-6561]
* 2.0          Pratap              27/01/2023          NCP-7884(getAltEffectiveAccountId)
* 3.0          Mayukh/Mukesh        21/08/2023          143985
**/

public with sharing class D1_UtilityClass {
    public static final String OUTLETRETAILER = 'Outlet/Retailers';
    public static final String DIRECTBUYER = 'Direct Buyer';
    public static final String SHIPPING = 'Shipping';
    
    /**
* @description [NCP-6450]
* This method is used to validate the preferred language field. 
* It basically checks what languages are allowed for the country using d1 settings and va;
* @param newItems list of sobject records can passed from TriggerHandler or TriggerHelper
* @param countryLookupField - String - specify the geography country lookup field's api name 
* @param preferredLanuguageField -String - Specify the API name of preferred language field in the object
*/    
    public static void validatePreferredLanguage(List<sObject> newItems, String countryLookupField, String preferredLanuguageField){//NCP-6561
        Map<Id,Set<String>> countryRelevantLanguagemap = new Map<Id,Set<String>>();
        Map<String,String> languageCodeNameMap = getLanguageCodeAndNameMapping();
        Set<Id> countryIds = getCountryIds(newItems, countryLookupField);
        
        //Get Available Language for Markets
        if(!countryIds.isEmpty()){
            countryRelevantLanguagemap = getCountryRelevantLanguagemap(countryIds);
        }
        
        if(!countryRelevantLanguagemap.isEmpty()){
            for(sObject record : newItems){
                if(record.get(countryLookupField) != null){
                    Id countryId = (Id)record.get(countryLookupField);
                    if(record.get(preferredLanuguageField)!=null && (!countryRelevantLanguagemap.containsKey(countryId) || !countryRelevantLanguagemap.get(countryId).contains((String)record.get(preferredLanuguageField)))){
                        String languages = '';
                        for(String lang : countryRelevantLanguagemap.get(countryId)){
                            languages+= languageCodeNameMap.get(lang)+', ';
                        }
                        languages = languages.removeEnd(', ');
                        String errorMsg = System.Label.D1_SelectRelevantLanguage;
                        errorMsg = errorMsg.replace('{0}', languages);
                        if(!Test.isRunningTest()){
                            record.addError(errorMsg);
                        }
                    }
                }
            }
        }
    }
    
    /**
* @description used to fetch the language API names and Labels  Map. example {en_GB => English(GB)} [NCP-6450]
* @param languageCodeAndNameMap - can you as passby reference or normal return .
* @return  `Map<String,String>`
*/    
    public static Map<String, String> getLanguageCodeAndNameMapping(){
        Map<String, String> languageCodeAndNameMap = new Map<String,String>();
        
        for(Schema.PicklistEntry pickListValue : D1_Setting__c.Language__c.getDescribe().getPicklistValues()){
            languageCodeAndNameMap.put(pickListValue.getValue(),pickListValue.getLabel());
        }
        return languageCodeAndNameMap;
    }
    
    /**
* @description To Fetch the Country Ids on the basis of country lookup field passed [NCP-6450]
* @param newItems List<SObject>
* @param countryIds Set<Id>
* @param countryLookupField String
* @param validationField String
* @param expectedValidationValue String
* @return  `Set<Id>`
*/    
    public static Set<Id> getCountryIds(List<SObject> newItems, String countryLookupField){
        Set<Id> countryIds = new Set<Id>();
        
        for(SObject record : newItems){
            countryIds.add((Id)record.get(countryLookupField));
        }
        return countryIds;
    }
    
    /**
* @description used to get relevant/allowed languages for a country on the basis of Country Ids [NCP-6450]
* @param countryIds Set<Id>
* @param countryRelevantLanguagemap Map<Id,Set<String>>
* @return  `Map<Id,Set<String>>`
*/    
    public static Map<Id,Set<String>> getCountryRelevantLanguagemap(Set<Id> countryIds){
        Map<Id,Set<String>> countryRelevantLanguagemap = new Map<Id,Set<String>>();
        
        for(D1_Setting__c d1SettingRec : [SELECT Id, Market__c, Language__c FROM D1_Setting__c WHERE Market__c IN :countryIds ORDER BY Market__c]){
            if(!countryRelevantLanguagemap.containsKey(d1SettingRec.Market__c)){
                countryRelevantLanguagemap.put(d1SettingRec.Market__c, new Set<String>{d1SettingRec.Language__c});
            }
            else{
                countryRelevantLanguagemap.get(d1SettingRec.Market__c).add(d1SettingRec.Language__c);
            }
        }
        return countryRelevantLanguagemap;
    }
    
    /**
* @description : NCP-7884 - returns First Ship-To Id From Contact Point Address of User's Sold To
*                as an alternative of Effective Account Id for ROI Hybrid usage
* @param : {Id} userId 
* @return  `String`
*/
    @AuraEnabled(cacheable=true)
    public static String getAltEffectiveAccountId(Id userId){
        try{
            String altEffectiveAccountId = '';
            
            userId = String.isEmpty(userId) ? UserInfo.getUserId() : userId;
            User user = [SELECT Id, Effective_Account_Id__c, D1_User_Type__c FROM User WHERE Id =: userId LIMIT 1];
            
            if(user.D1_User_Type__c == OUTLETRETAILER){        //For Outlet/Retailers, Use Effective Account Id             
                altEffectiveAccountId = user.Effective_Account_Id__c;
            }
            else if(user.D1_User_Type__c == DIRECTBUYER){
                //From ContactPointAddress get the Ship-To Account's KUNNR and then get the Account Id From KUNNR,
                //if There existis multiple Ship-To consider the first one
                
                List<ContactPointAddress> cpaList = new List<ContactPointAddress>();
                cpaList = [SELECT Id, ParentId, Account_Number__c  
                           FROM ContactPointAddress 
                           WHERE ParentId =: user.Effective_Account_Id__c
                           AND Account_Number__c != null AND AddressType =: SHIPPING AND Status__c =: D1_AccountTriggerHelper.CONTACT_POINT_ADDRESS_STATUS_ACTIVE
                           ORDER BY Name];
                
                if(!cpaList.isEmpty()){
                    altEffectiveAccountId = [SELECT Id FROM Account WHERE KUNNR__c =: cpaList[0].Account_Number__c LIMIT 1].Id;
                }
            }
            return altEffectiveAccountId;        
        }
        catch(Exception ex){
            throw new AuraHandledException(ex.getMessage() + 'line Number '+ex.getLineNumber());
        }
    }
    
    @AuraEnabled
    public static User getUser(String userId){
        try {
            User usr = [SELECT Id, Name, D1_User_Type__c, D1_User_Type_Id__c FROM User WHERE Id =:userId LIMIT 1];
            
            return usr;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static D1_User_Type__c getD1UserType(String userId){
        if(Cache.Session.contains('local.DiageoOne.D1UserType')){
            return (D1_User_Type__c) Cache.Session.get('local.DiageoOne.D1UserType');
        }else{
            try {
                if(String.isEmpty(userId)){
                    userId = UserInfo.getUserId();
                }
                //Get User Details
                User usr = getUser(userId);
                
                //Get D1 User Type
                List<D1_User_Type__c> userTypes = [SELECT Id, D1_Setting__c, Navigation_Menu_Name__c, Registration_Validation_Type__c, Tooltip_Text__c, UIN_Identifier__c, 
                                                   User_Type_Description__c, User_Type__c, Customer_Service_Group__c, Enable_Fault_Fixer__c, Fault_Fixer_Label__c, UIN_Label__c, 
                                                   Visible_for_self_registration__c, Tax_Identification_Number__c, Chat_Button_Id__c, Customer_Service_Contact_Number__c, UIN_Label_In_Review_Page__c, 
                                                   Contact_Us_Description__c, Enable_Contact_Us__c, Email_Domain_Check__c, Enable_Service_Now__c, Redirect_to_Unknown_registration_form__c, UIN_placeholder_text__c, 
                                                   UIN_unmatch_message__c, Account_number_Identifier__c, D1_Auto_Redirection__c, Case_Subtype__c, Case_Type__c 
                                                   FROM D1_User_Type__c WHERE Id =:usr.D1_User_Type_Id__c];
                
                if(userTypes.isEmpty()){
                    throw new AuraHandledException('No User Type Found !!');
                }
                Cache.Session.put('local.DiageoOne.D1UserType',userTypes.get(0));
                return userTypes.get(0);
            } catch (Exception e) {
                throw new AuraHandledException(e.getMessage());
            }
        }
    }
    
    
    /**
* @description To get Market Setting on the basis of userId :143985
* @param userId Id
* @return D1_Setting__c
*/  
    @AuraEnabled(cacheable = true)
    public static D1_Setting__c getD1Setting(Id userId){
        
        if(Cache.Session.contains('local.DiageoOne.D1Setting')){
            return (D1_Setting__c) Cache.Session.get('local.DiageoOne.D1Setting');
        }else{
            if(String.isBlank(userId)){
                userId = UserInfo.getUserId();
            }
            User loggedInUser = [SELECT Id, Available_Countries__c, LanguageLocaleKey FROM User WHERE Id =:userId];
            
            List<String> availableCountry = loggedInUser.Available_Countries__c != NULL ? loggedInUser.Available_Countries__c.split(',') : new List<String>();
            List<D1_Setting__c> d1Settings = [SELECT Id, About_Us__c, About_Us_Hyperlink_Text__c, About_Us_Hyperlink_URL__c, Add_Cases_To_Complete_Layer_Pallet_Msg__c, Asset_Type_Card_Description__c, Asset_Type_Content_Document_Id__c, 
                                              Asset_Type_Content_version_Id__c, Billing_History_Date_Range__c, Blocked_Account_Sold_To_Warning_Message__c, Blocked_Ship_To_Help_Text_Order_History__c, Blocked_Ship_To_Warning_My_Business__c, 
                                              Blocked_Sold_To_Help_Text_Order_History__c, Brand_Card_Description__c, Brand_Content_Document_Id__c, Brand_Content_version_Id__c, Cases_per_pallet__c, CM_Payment_Info_Pop_Up__c, CM_Payment_Info_Visible_Text__c, 
                                              CM_SD_Commitments_Visible_Text__c, CM_Target_Overview_Visible_Text__c, Code_of_Conduct_Link__c, Contact_Us_Email__c, Contact_Us_Phone__c, CS_Instructions_display__c, CS_Notification_email__c, CSV_Ordering_FAQ_Link__c,
                                              Customer_Service_Instructions_Tool_Tip__c, Customer_status_Display__c, D1_Enable_CSV_Ordering__c, D1_Enable_DCH__c, D1_Lite_Version__c, D1_opt_in_reminder_interval__c, D1_Send_Case_Update_Email_to_Customer__c, D1_Speak_To_Sales_Rep_Hyperlink_Text__c,
                                              Default__c, Deleted_Ship_To_Help_Text_Order_History__c, Deleted_Ship_To_Warning_Message__c, Delivery_date_additional_disclaimer__c, Delivery_Instructions__c, Delivery_Instructions_Tool_Tip__c, Direct_Customers_Email_Domain_Check__c, Display_Account_Balance__c,
                                              Display_Account_Due__c, Display_Amount_Due__c, Display_cancelled_invoices__c, Display_Credit_limit__c, Display_Credit_limit_Exposure__c, Display_Last_Payment_Received__c, Duplicate_PO_check__c, Duty_Paid_Label__c, Duty_Suspended_Label__c, Enable_Collect_Keg_Button__c,
                                              Enable_POS_Order_Terms_and_Conditions__c, Enable_Push_Notification__c, Enable_Registration_Survey__c, Enable_Sales_Area_Terms_and_Conditions__c, Enable_Survey_Preference__c, Enable_Transfer_Order_Terms_Conditions__c, FAQ_Hyperlink_Text__c, FAQ_Hyperlink_URL__c,
                                              Geo_Area_Label__c, Geo_Region_Label__c, Glassware_Heading__c, Glassware_Label__c, Glassware_Label_plural__c, Glassware_Sub_Heading__c, Hide_Help_and_Support__c, Hide_Registration_First_Screen__c, Hide_Tax_Identification_Number__c, Is_Delivery_Date_Additional_Disclaimer__c, 
                                              Is_disclaimer_enabled__c, Is_KEG_Return__c, Is_Logged_In_About_Us_On__c, Is_Logged_In_Contact_Us_On__c, Is_Logged_In_FAQ_On__c, Is_Public_About_Us_On__c, Is_Public_Contact_Us_On__c, Is_Public_FAQ_On__c, Language__c, List_Price_info_label__c, Logged_In_About_Us__c, 
                                              Logged_In_About_Us_Hyperlink_Text__c, Logged_In_About_Us_Hyperlink_URL__c, Logged_In_Contact_Us_Email__c, Logged_In_Contact_Us_Phone__c, Logged_In_FAQ_Hyperlink_Text__c, Logged_In_FAQ_Hyperlink_URL__c, Market__c, MAX_Number_of_KEGS_allowed__c, Max_Weight_Error__c,
                                              MOQ_multiple_validation__c, My_Request_Contact_Us__c, Name_2_value__c, Navigation_Menu_Name__c, Next_Available_Delivery_Date_Message__c, Nozzle_Heading__c, Nozzle_Label__c, Nozzle_Label_plural__c, Nozzle_Sub_Heading__c, NPS_Session_Frequeny_Reminder__c, NPS_Survey_Blocker__c,
                                              NPS_Survey_content__c, NPS_survey_Title__c, NPS_Survey_URL__c, Occasion_Card_Description__c, Occasion_Content_Document_Id__c, Occasion_Content_version_Id__c, Order_Acknowledgement_PDF__c, Order_History_Date_Range__c, Order_Limit_Per_Day__c, Order_Limit_Per_Day_Message__c, 
                                              Order_Simulation_enabled__c, Order_Status_Tooltip__c, Partner_OptIn_Reminder_Interval__c, Partner_Plus_Enabled__c, Partner_Plus_Terms_Condition_Link__c, Pioneer_Market__c, PO_Number_mandatory__c, POS_Approval__c, Postal_Code_Setting__c, 
                                              Prepopulate_next_Delivery_Date__c, Product_Scanner_Enabled__c, Proof_Of_Delivery__c, Request_History_Date_Range__c, Self_Registration__c, Show_EDGE_Quality_Cases__c, Split_1_PO_Number_Tool_Tip__c, Split_2_PO_Number_Tool_Tip__c, Stock_Availability_Disabled__c, 
                                              Tax_Identification_Number__c, UIN_Field__c, UIN_Label__c, UIN_Setting__c, Weight_Pallet_Switched__c, Enable_Payment_Terms__c,Calculate_Tax_On_Simulation__c, Show_Estimated_Average_Delivery__c, Show_Delivery__c, Hide_Delivery_Date__c
                                              FROM D1_Setting__c 
                                              WHERE Market__r.Code__c IN :availableCountry AND Language__c =:loggedInUser.LanguageLocaleKey LIMIT 1];
            if(d1Settings.isEmpty()){
                throw new AuraHandledException('Access Denied');
            }
            
            Cache.Session.put('local.DiageoOne.D1Setting',d1Settings[0]);
            return d1Settings[0];  
        }                      
    }
}