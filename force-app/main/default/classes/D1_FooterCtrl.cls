/*
* @name: D1_FooterCtrl
* @discription: This class is controller class for d1Footer LWC Component
* @history                                                            
* --                                                            
* VERSION   AUTHOR            DATE              DETAIL
* 1.0       Sai Kumar         30/08/2020        Initial Development
* 2.0	    Mukesh Kant       16/02/2021        NCP-
* 3.0       Rubeena Naaz      16/06/2021        NCP- 
* 4.0       Amar Deep         05/07/2021        NCP-3489
* 5.0       Sayan Samaddar    16/05/2022        NCP-6618
* */
public without sharing class D1_FooterCtrl {
    /*
     * Method is call in the d1Footer LWC to pass the Values of follow Details 
     *  About Us 
     *  Contact Us
     *  Support
     * Respect to the Country Passsed from the LWC
     */
    
    @AuraEnabled(cacheable=true)
    public static D1SettingWithUserTypeWrapper getD1SettingDetail(String countryCode, string language){
        D1SettingWithUserTypeWrapper d1SettingWithUserTypeWrapperObj = new D1SettingWithUserTypeWrapper();
        User loggedInUser;
        List<D1_Setting__c> d1SettingList = new List<D1_Setting__c>();
        
        if( UserInfo.getUserType() == 'Guest' ){
            if(string.isNotBlank(countryCode) && string.isNotBlank(language)){
                d1SettingList =[SELECT Id,Language__c,Default__c,About_Us__c,About_Us_Hyperlink_Text__c,About_Us_Hyperlink_URL__c,Is_Public_About_Us_On__c,
                                Contact_Us_Email__c,Contact_Us_Phone__c,Is_Public_Contact_Us_On__c,Is_Public_FAQ_On__c,FAQ_Hyperlink_Text__c,FAQ_Hyperlink_URL__c
                                FROM D1_Setting__c                                
                                WHERE Market__r.isDiageoOneEnabled__c = TRUE AND Market__r.Code__c=:countryCode AND Language__c =:language];
            }else{
                d1SettingList =[SELECT Id,Language__c,Default__c,About_Us__c,About_Us_Hyperlink_Text__c,About_Us_Hyperlink_URL__c,Is_Public_About_Us_On__c,
                                Contact_Us_Email__c,Contact_Us_Phone__c,Is_Public_Contact_Us_On__c,Is_Public_FAQ_On__c,FAQ_Hyperlink_Text__c,FAQ_Hyperlink_URL__c
                                FROM D1_Setting__c 
                                WHERE Market__r.isDiageoOneEnabled__c = TRUE AND Market__r.Code__c =:Label.D1_Footor_Country_Default];
            }
        }else if(UserInfo.getUserType() != 'Guest'){ 
            //Get Logged In User Details
            loggedInUser = getCurrentUser();
            d1SettingList = [SELECT Id,Language__c,Default__c,Logged_In_About_Us__c,Logged_In_About_Us_Hyperlink_URL__c,Logged_In_About_Us_Hyperlink_Text__c,
                             Is_Logged_In_About_Us_On__c,Logged_In_Contact_Us_Email__c,Logged_In_Contact_Us_Phone__c,Is_Logged_In_Contact_Us_On__c,Is_Logged_In_FAQ_On__c,
                             Logged_In_FAQ_Hyperlink_Text__c,Logged_In_FAQ_Hyperlink_URL__c, D1_Speak_To_Sales_Rep_Hyperlink_Text__c
                             FROM D1_Setting__c 
                             WHERE Language__c =: loggedInUser.LanguageLocaleKey 
                             AND Market__r.Code__c = : loggedInUser.Available_Countries__c];
        }
        
        if(UserInfo.getUserType() == 'Guest'){
            if(d1SettingList[0].Is_Public_About_Us_On__c == true){
                d1SettingWithUserTypeWrapperObj.aboutUsVisible = true;
                d1SettingWithUserTypeWrapperObj.aboutUs = d1SettingList[0].About_Us__c;
                d1SettingWithUserTypeWrapperObj.aboutUsHyperlinkURL = d1SettingList[0].About_Us_Hyperlink_URL__c;
                d1SettingWithUserTypeWrapperObj.aboutUsHyperlinkText = d1SettingList[0].About_Us_Hyperlink_Text__c;
            }
            if(d1SettingList[0].Is_Public_FAQ_On__c == true){
                d1SettingWithUserTypeWrapperObj.supportVisible = true;
                d1SettingWithUserTypeWrapperObj.faqHyperlinkURL = d1SettingList[0].FAQ_Hyperlink_URL__c;
                d1SettingWithUserTypeWrapperObj.faqHyperlinkText = d1SettingList[0].FAQ_Hyperlink_Text__c; 
            }
            if(d1SettingList[0].Is_Public_Contact_Us_On__c == true){
                d1SettingWithUserTypeWrapperObj.contactUsVisible = true;
                d1SettingWithUserTypeWrapperObj.contactUsEmail = d1SettingList[0].Contact_Us_Email__c;
                d1SettingWithUserTypeWrapperObj.contactUsPhone = d1SettingList[0].Contact_Us_Phone__c;
            }
            
        }else {
            D1_User_Type__c d1UserType = getD1UserType(loggedInUser);
            if(d1SettingList[0].Is_Logged_In_About_Us_On__c == true){
                d1SettingWithUserTypeWrapperObj.aboutUsVisible = true;
                d1SettingWithUserTypeWrapperObj.aboutUs = d1SettingList[0].Logged_In_About_Us__c;
                d1SettingWithUserTypeWrapperObj.aboutUsHyperlinkURL = d1SettingList[0].Logged_In_About_Us_Hyperlink_URL__c;
                d1SettingWithUserTypeWrapperObj.aboutUsHyperlinkText = d1SettingList[0].Logged_In_About_Us_Hyperlink_Text__c;
            }
            if(d1SettingList[0].Is_Logged_In_FAQ_On__c == true){
                d1SettingWithUserTypeWrapperObj.supportVisible = true;
                d1SettingWithUserTypeWrapperObj.faqHyperlinkURL = d1SettingList[0].Logged_In_FAQ_Hyperlink_URL__c;
                d1SettingWithUserTypeWrapperObj.faqHyperlinkText = d1SettingList[0].Logged_In_FAQ_Hyperlink_Text__c;
                d1SettingWithUserTypeWrapperObj.speakToUs = d1SettingList[0].D1_Speak_To_Sales_Rep_Hyperlink_Text__c;
            }
            if(d1SettingList[0].Is_Logged_In_Contact_Us_On__c == true){
                d1SettingWithUserTypeWrapperObj.contactUsVisible = true;
                d1SettingWithUserTypeWrapperObj.contactUsEmail = d1UserType.Customer_Service_Group__c;
                d1SettingWithUserTypeWrapperObj.contactUsPhone = d1UserType.Customer_Service_Contact_Number__c;
                //150884
                d1SettingWithUserTypeWrapperObj.contactUsWhatsApp = d1UserType.WhatsApp_Number__c;
            }
        } 
        return d1SettingWithUserTypeWrapperObj;
    }
    
    /**
     * Helper Method to get User Type
     */
    public static D1_User_Type__c getD1UserType(User loggedUser){
        D1_User_Type__c d1UserType;
        
        if(loggedUser != null){
            d1UserType = [SELECT Id,Customer_Service_Contact_Number__c,Customer_Service_Group__c,WhatsApp_Number__c
                          FROM D1_User_Type__c 
                          WHERE Id =: loggedUser.D1_User_Type_Id__c
                          LIMIT 1]; 
        }
        return d1UserType != null ? d1UserType : new D1_User_Type__c();
    }
    
    /**
     * Helper Method to get User Detail
     */
    @AuraEnabled
    public static User getCurrentUser(){
        List<User> users = [SELECT Id, Name, LanguageLocaleKey, D1_User_Type__c,D1_User_Type_Id__c, Available_Countries__c
                            FROM User
                            WHERE Id =: UserInfo.getUserId() LIMIT 1];
        if(users.isEmpty()){
            throw new AuraHandledException('Access Denied(User)');
        }
        return users.isEmpty() ? new User() : users[0];
        
    }
    
    //Wrapper Class
    public class D1SettingWithUserTypeWrapper{
        @AuraEnabled
        public string aboutUs{get;set;}
        @AuraEnabled
        public string aboutUsHyperlinkURL{get;set;}
        @AuraEnabled
        public string aboutUsHyperlinkText{get;set;}
        @AuraEnabled
        public string faqHyperlinkURL{get;set;}
        @AuraEnabled
        public string faqHyperlinkText{get;set;}
        @AuraEnabled
        public string contactUsEmail{get;set;}
        @AuraEnabled
        public string contactUsPhone{get;set;}
        @AuraEnabled
        public string speakToUs{get;set;}
        @AuraEnabled
        public boolean aboutUsVisible{get;set;}   
        @AuraEnabled
        public boolean supportVisible{get;set;} 
        @AuraEnabled
        public boolean contactUsVisible{get;set;}
        @AuraEnabled//150884
        public string contactUsWhatsApp{get;set;}
    }
         
}