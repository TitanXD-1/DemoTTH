/**
 * @name : D1_UnknownOutletRegistrationController
 * @description : Controller Class for Unknown Outlet Registration
 * @history
 * VERSION      AUTHOR          DATE            DETAIL
 * 1.0          Kapil Baliyan   20/08/2021      Initial Development (NCP-)
 * 2.0          Kapil Baliyan   06/10/2021      NCP-4394(createLead)
 * 3.0          Kapil Baliyan   02/12/2021      NCP-5517(createLead)
 */
public without sharing class D1_UnknownOutletRegistrationController{
    
    /**
     * @description : Get D1 Setting
     * @return : D1_Setting__c
     * @param {String} countryCode 
     * @param {String} language
     */
    @AuraEnabled(cacheable=true)
    public static D1_Setting__c getD1Setting(string countryCode, string language) {
        List<D1_Setting__c> d1SettingList = new List<D1_Setting__c>();
        if(string.isNotBlank(countryCode) && string.isNotBlank(language)){
            d1SettingList = [SELECT Id, UIN_Field__c, UIN_Label__c, UIN_Setting__c,
            Geo_Area_Label__c, Geo_Region_Label__c
            FROM D1_Setting__c WHERE Market__r.Code__c =:countryCode AND Language__c =:language LIMIT 1];
        }

        return d1SettingList.isEmpty() ? null : d1SettingList.get(0);
    }

    /**
     * @description : Get D1 Setting
     * @return : Map<String,Object>
     * @param {String} countryCode 
     * @param {String} language
     */
    @AuraEnabled(cacheable=true)
    public static Map<String,Object> getRegistrationDefaultSetting(string d1SettingId) {
        List<D1_Setting__c> d1SettingList = [SELECT Id,Market__c FROM D1_Setting__c WHERE Id =:d1SettingId LIMIT 1];

        Map<String,Object> defaultSetup = new Map<String,Object>();
        if(!d1SettingList.isEmpty()){
            List<Geography__c> areasList = [Select id,Name,(Select id,Name from Geographies__r where RecordType.Name = 'Region') from Geography__c where Parent_Geography__c =:d1SettingList[0].Market__c and RecordType.Name = 'Area'];
            defaultSetup.put('areas',areasList);

            List<D1_Unknown_Outlet_Type__c> outletList = [select id,Outlet_Type__c,Outlet_Sub_Type__c,Content_Document_Id__c,Content_Version_Id__c from D1_Unknown_Outlet_Type__c where Country__c =:d1SettingList[0].Market__c];
            defaultSetup.put('outletTypes',outletList);
        }
        
        return defaultSetup;
    }


    
    @AuraEnabled
    public static List<Account> validateAccount(String uinAPI, String uin, String outletName, String postalCode){
        try{
            List<Account> accList = new List<Account>();
            String queryStr = getQueryString();

            String postalCodeCondition = '';
            if(String.isNotBlank(postalCode)){
                postalCodeCondition = ' AND BillingPostalCode =:postalCode';
            }

            //Validate uin
            if(String.isNotBlank(uin) && String.isNotBlank(uinAPI)){ 
                if(!queryStr.containsIgnoreCase(uinAPI)){
                    queryStr += ', ' + uinAPI;
                }
                queryStr += ' FROM Account WHERE ' + uinAPI + ' =:uin' + postalCodeCondition;
                accList = Database.query(queryStr);
            }
            
            //If there is not Account exist with UIN check for Account in combination of Outlet Name and PostalCode
            if(accList == null || accList.size()==0){
                queryStr = getQueryString();
                queryStr += ' FROM Account WHERE Name =:outletName ' + postalCodeCondition;
                accList = Database.query(queryStr);
            }
            return accList;
        }catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static D1_UserRegistrationValidator.UserValidationResultWrapper createLead(string leadWrapper){
        try {
            D1_UserRegistrationValidator.UserValidationResultWrapper userResultWrapper  = new D1_UserRegistrationValidator.UserValidationResultWrapper();
            Map<String, Object> leadWrapperMap = (Map<String, Object>) JSON.deserializeUntyped(leadWrapper);
            Lead ld = new Lead();
            ld.Company = (string)leadWrapperMap.get('outletName');
            ld.Street = (string)leadWrapperMap.get('street');
            ld.City = (string)leadWrapperMap.get('city');
            ld.CountryCode = (string)leadWrapperMap.get('countryCode');
            ld.Country_ISO_Code__c = (string)leadWrapperMap.get('countryISOCode');
            ld.PostalCode = (string)leadWrapperMap.get('postalCode');
            ld.UIN_Number__c = (string)leadWrapperMap.get('uin');
            ld.PhonePrefix__c = (string)leadWrapperMap.get('phoneNumberPrefix');
            ld.Phone__c = (string)leadWrapperMap.get('phoneNumber');
            ld.Phone = (string)leadWrapperMap.get('phone');
            ld.FirstName = (string)leadWrapperMap.get('firstName');
            ld.LastName = (string)leadWrapperMap.get('lastName');
            ld.Email = (string)leadWrapperMap.get('email');
            ld.D1_CurrentRole__c = (string)leadWrapperMap.get('outletRole');
            ld.Title = (string)leadWrapperMap.get('outletRole');
            ld.MobilePrefix__c = (string)leadWrapperMap.get('mobileNumberPrefix');
            ld.Mobile__c = (string)leadWrapperMap.get('mobileNumber');
            ld.MobilePhone = (string)leadWrapperMap.get('mobile');
            ld.Registration_Type__c = (string)leadWrapperMap.get('registrationType');
            ld.Description = (string)leadWrapperMap.get('description'); //NCP-4394
            ld.LeadSource = 'DiageoOne';
            ld.Customer_SAP_Code__c = (string)leadWrapperMap.get('customerSAPCode'); //NCP-5517
            ld.Lead_Type__c = (string)leadWrapperMap.get('leadType'); //NCP-5517
            ld.Area__c = (string)leadWrapperMap.get('area');
            ld.Region__c = (string)leadWrapperMap.get('region');
            ld.Outlet_Type_Name__c = (string)leadWrapperMap.get('outletTypeId');
            ld.Outlet_Type__c = (string)leadWrapperMap.get('outletType');
            ld.Outlet_Sub_Type__c = (string)leadWrapperMap.get('outletSubType');
            ld.Preferred_Language__c = (string)leadWrapperMap.get('language');//NCP-6212
            ld.LeadSubscriptions__c = (string)leadWrapperMap.get('subscription');//150025

            //Create DML Options
            AssignmentRule ar = new AssignmentRule();
            ar = [SELECT Id FROM AssignmentRule WHERE sObjectType = 'Lead' and Active = True Limit 1];
            Database.DMLOptions dml = new Database.DMLOptions(); 
            //Duplicate Rule DML Options
            dml.DuplicateRuleHeader.allowSave = false;
            dml.DuplicateRuleHeader.runAsCurrentUser = false;
            //Assignment Rule DML Options
            dml.assignmentRuleHeader.assignmentRuleId= ar.id;
            dml.EmailHeader.TriggerUserEmail = true;
            Database.SaveResult sr = Database.insert(ld, dml);
            if (sr.isSuccess()) {
                userResultWrapper.isSuccess = true;
                userResultWrapper.isUnknownOutletSuccess = true;
                userResultWrapper.leadId = sr.getId();
            }else{
                for(Database.Error error : sr.getErrors()){
                    if(error instanceof Database.DuplicateError){
                        Database.DuplicateError duplicateError = (Database.DuplicateError)error;
                        Datacloud.DuplicateResult duplicateResult = duplicateError.getDuplicateResult();
                        userResultWrapper.isSuccess = true;
                        userResultWrapper.isUnknownOutletDuplicate = true;
                    }else {
                        userResultWrapper.isSuccess = false;
                    }
                }
            }
            return userResultWrapper;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled
    public static List<AccountContactRelation> getPrimaryContact(String accountId){
        List<AccountContactRelation> accContactRelationList = [SELECT Id, AccountId, ContactId, D1_Roles__c,Contact_Type__c, IsDirect FROM AccountContactRelation 
                                                               WHERE accountId =:accountId and Contact_Type__c ='Primary' limit 1];
        return  accContactRelationList;                                                  
    }

    public static string getQueryString(){
        String queryStr = 'SELECT Id, Name, BillingStreet, BillingCity, BillingState,BillingPostalCode, PhonePrefix__c, Phone__c, Phone, D1_Registration_Status__c, Primary_Sales_Rep__c, Primary_Sales_Rep__r.Email, Direct_Customer__c, KUNNR__c, SAP_Ship_to__c';

        return queryStr;
    }
	
	public static void sendEmailToPrimaryContact(D1_UserRegistrationDetailWrapper userRegWrap, Contact primaryContact){
		list<Messaging.SingleEmailMessage> maillist = new list<Messaging.SingleEmailMessage>();
		/*Site siteName = [SELECT Id FROM Site WHERE UrlPathPrefix = 'DiageoOne' LIMIT 1];        
        String communityUrl = [SELECT SecureURL FROM SiteDetail WHERE DurableId =: siteName.Id].SecureUrl;
        communityUrl = communityUrl +'s/my-account/my-users'; */
        String communityUrl = System.Label.D1_Community_Link + '/my-account/my-users';
		EmailTemplate emailTemp =[SELECT Id, Subject, Body, HtmlValue FROM EmailTemplate WHERE DeveloperName ='D1_Secondary_User_Registration'];
		String emailBody  = emailTemp.HtmlValue;
		emailbody  	= emailBody.replace('{!$Label.D1_Hi}', System.Label.D1_Hi);
        emailbody  	= emailBody.replace('{!Contact.FirstName}' , primaryContact.FirstName);
		emailbody 	= emailbody.replace('{!Account.Name}', userRegWrap.outletName);
		emailbody 	= emailbody.replace('{!Account.BillingStreet}', userRegWrap.street);
		emailbody 	= emailbody.replace('{!Account.BillingCity}', userRegWrap.city);
		emailbody 	= emailbody.replace('{!Account.BillingPostalCode}', userRegWrap.postalCode);
        emailbody 	= emailbody.replace('{!request.MD_CurrentRole__c}', userRegWrap.outletRole); // ADDED BY SANDEEP FOR 146479
		emailbody 	= emailbody.replace('{!request.FirstName}', userRegWrap.firstName);
		emailbody 	= emailbody.replace('{!request.LastName}', userRegWrap.lastName);
		emailbody 	= emailbody.replace('{!request.Email}', userRegWrap.email);
        String mobileNumber = userRegWrap.mobileCountryCode + ' ' + formatPhone(userRegWrap.mobile);
		emailbody 	= emailbody.replace('{!request.MobilePhone}',mobileNumber);
		emailbody  = emailBody.replace('{!$Label.D1_Community_MyUser_Link}',communityUrl);
		emailbody  = emailBody.replace('{!$Label.D1_Transfer_Order_Email_Body_7}', System.Label.D1_Transfer_Order_Email_Body_7);
		emailbody  = emailBody.replace('{!$Label.D1_Transfer_Order_Footer}', System.Label.D1_Transfer_Order_Footer);
		emailbody  = emailBody.replace('{!$Label.D1_Transfer_Order_Footer_1}', System.Label.D1_Transfer_Order_Footer_1);
		emailbody  = emailBody.replace('{!$Label.D1_Transfer_Order_Footer_2}', System.Label.D1_Transfer_Order_Footer_2);
		emailbody  = emailBody.replace('{!$Label.D1_Transfer_Order_Footer_3}', System.Label.D1_Transfer_Order_Footer_3);
        emailbody  = emailBody.replace('{!$Label.D1_Registration_Request}', System.Label.D1_Registration_Request);
        emailbody  = emailBody.replace('{!$Label.D1_Register_Outlet}', System.Label.D1_Register_Outlet);
        emailbody  = emailBody.replace('{!$Label.D1_Contact_First_Name}', System.Label.D1_Contact_First_Name);
        emailbody  = emailBody.replace('{!$Label.D1_Contact_Last_Name}', System.Label.D1_Contact_Last_Name);
        emailbody  = emailBody.replace('{!$Label.D1_Role_Label}', System.Label.D1_Role_Label);  // ADDED BY SANDEEP FOR 146479
        emailbody  = emailBody.replace('{!$Label.D1_Contact_Email_Id}', System.Label.D1_Contact_Email_Id);
        emailbody  = emailBody.replace('{!$Label.D1_Mobile_And_Country}', System.Label.D1_Mobile_And_Country);
        emailbody  = emailBody.replace('{!$Label.D1_Email_Text}', System.Label.D1_Email_Text);
        emailbody  = emailBody.replace('{!$Label.D1_Copyright_2020_All_rights_reserved_Diageo_PLC}', System.Label.D1_Copyright_2020_All_rights_reserved_Diageo_PLC);
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		mail.setTemplateId(emailTemp.Id);
		String[] sendingTo = new String[]{primaryContact.Email}; //'dipanjan.a.das@diageo.com','amar.deep@diageo.com'
		mail.setToAddresses(sendingTo);
		mail.setHtmlBody(emailBody);
        mail.setSubject(Label.D1_Registration_Request);
        OrgWideEmailAddress orgWideObj = [select DisplayName,Id from OrgWideEmailAddress where DisplayName = 'DiageoOne'];
        mail.setOrgWideEmailAddressId(orgWideObj.Id);
		mailList.add(mail);	
        if (!Test.isRunningTest()) {
            Messaging.sendEmail(mailList);
        }	   
	}

    private static String formatPhone(String phone) {
        string nondigits = '[^0-9]';
        string phoneDigits;
        
        // remove all non numeric
        phoneDigits = phone.replaceAll(nondigits,'');
        
        // 10 digit: reformat with dashes
        if (phoneDigits.length() == 10){
            return '(' + phoneDigits.substring(0,4) + ')' + ' ' + phoneDigits.substring(4,7) + ' ' + phoneDigits.substring(7,10);
        } 
        // 9 digit: if starts with 1, format as 10 digit 
        else if (phoneDigits.length() == 9) {
            return '(' + phoneDigits.substring(0,3) + ')' + ' ' + phoneDigits.substring(3,6) + ' ' + phoneDigits.substring(6,9);
        }
        else{
            return phone;
        }
    }

    @AuraEnabled
    public static List<D1_User_Type__c> getUserType(String countryLang,String country){
        List<D1_User_Type__c> availableUserType = new List<D1_User_Type__c>();
        if(string.isNotBlank(countryLang)){
            //NCP-3670 - added new uin field and email field
            availableUserType = [SELECT Id, D1_Setting__c, Name, User_Type__c, Registration_Validation_Type__c, Customer_Service_Group__c
                                 FROM D1_User_Type__c WHERE D1_Setting__r.Language__c =:countryLang AND D1_Setting__r.Market__r.Code__c =:country];
        }
        return availableUserType;
    }
}