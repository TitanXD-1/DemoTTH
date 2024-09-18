/**
 * 
 * @name :  D1_RegistrationUtility
 * @description : This is Utility Class to have common methods which is used in Registration/Deactivation Process
 * @history
 * VERSION          AUTHOR              DATE            DETAIL
 * 1.0              Kapil Baliyan       18/08/2022      Initial Development (NCP-7209)
 * 2.0				Rajarshi Lahiri		30/08/2022		ES20-13172  
 * 3.0				Subhrojit Majumdar	07/11/2022		NPS Survey fields cleanup on deactivation(NCP-7386)
 */
public without sharing class D1_RegistrationUtility {

    public static final String DIAGEOONE = 'Diageo One';
    public static final String FRONTEND = 'Frontend';
    
    /**
     * @description : This method is used to update Contact Fields related to Registration
     * @param conId 
     * @param userRegWrapper 
     */
    public static void updateRegisteredContact(Id conId, D1_UserRegistrationDetailWrapper userRegWrapper){
        Contact con = updateRegisteredContactFields(conId, userRegWrapper.regSource, userRegWrapper.subscriptionSource, userRegWrapper.userTypeId, userRegWrapper.d1SettingId, userRegWrapper.languageLocaleKey);
        con.Mobile__c = userRegWrapper.mobile; //NCP-6633
        con.MD_CurrentRole__c = userRegWrapper.outletRole;//NCP-143979
        con.MobilePrefix__c = userRegWrapper.mobileCountryCode; //NCP-6633
        if(userRegWrapper.regSource == DIAGEOONE && userRegWrapper.subscriptionSource == FRONTEND && !userRegWrapper.isSecondaryRegistration){
            con.D1_Last_opt_in_reminder_date__c = System.today(); //NCP-6638
        }
        if(userRegWrapper.subscriptionValue != '' && userRegWrapper.subscriptionValue != NULL){
            if(userRegWrapper.regSource == DIAGEOONE){//ES20-13172
            	con.MD_SubscriptionDate__c = Datetime.now();//NCP-6737
            }
            con.MD_ContactSubscriptions__c = userRegWrapper.subscriptionValue;
        }

        update con;
    }

    /**
     * @description : This method is used to update Contact Fields related to Deactivation
     * @param conIdSet 
     */
    public static void updateDeactivatedContact(Set<Id> conIdSet){
        List<Contact> updateContactList = new List<Contact>();

        for(Id conId : conIdSet){
            Contact con = new Contact();
            con.Id = conId;
            con.D1_Login_Reminder_Status__c = 'Deactivated';
            con.D1_Login_Counter__c = 0;//NCP-6925
            con.D1_Generic_Login_Counter__c = 0; //NCP-7458
            con.MD_SubscriptionDate__c = null;
            con.D1_Invite_sent__c = null;
            con.D1_Contact_Last_Login_Date__c = null;
            con.Next_Action_Date__c =null;
            con.Registration_Source__c = '';
            con.MD_ContactSubscriptions__c = '';
            con.MD_SubscriptionSource__c = '';
            con.D1_Last_opt_in_reminder_date__c = null;//NCP-6760
            con.D1_opt_in_Success_date__c = null;
            con.D1_User__c = FALSE;
            con.D1_NPS_Average_Score__c = null;//NCP-7386
			con.D1_NPS_Survey_Date__c = null;//NCP-7386
			con.D1_NPS_Survey_Name__c = '';//NCP-7386
            updateContactList.add(con);
        }
        
        update updateContactList;
    }

    /**
     * @description : This method is used to create Contact Instance with fields related to Registration
     * @param contactId 
     * @param regSource 
     * @param subSource 
     * @param userTypeId 
     * @param d1SettingId 
     * @param languageLocaleKey 
     * @return  `Contact`
     */
    public static Contact updateRegisteredContactFields(String contactId, String regSource, String subSource, Id userTypeId, Id d1SettingId, String languageLocaleKey){
        Contact con = new Contact();
        con.Id = contactId;
        con.Registration_Source__c = regSource;
        con.MD_SubscriptionSource__c = subSource;
        con.D1_Invite_sent__c = Date.Today();
        con.D1_User_Type__c = userTypeId;
        con.D1_Setting__c = d1SettingId;
        con.Preferred_Language__c = languageLocaleKey; //NCP-6348
        con.D1_Login_Reminder_Status__c = '';
        con.D1_User__c = TRUE;

        return con;
    }
}