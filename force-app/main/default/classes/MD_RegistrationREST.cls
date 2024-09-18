/*
Apex Class Name  :  MD_RegistrationREST 
Version          :  1.0
Created Date     :  28/08/2019
Release          :  R1
Function         :
Modification Log :

* Developer                   Date                   Description
* 
* Elena Schwarzbock           28/08/2019             Original Version
* Sagar Barman                12/11/2019             DiageoOne NCP-920  
* Kapil Baliyan               23/04/2021             NCP-2805   
* Kapil Baliyan				  11/05/2021			 NCP-2273
* Kapil Baliyan               04/04/2022             NCP-6506
* Rajarshi Lahiri             30/08/2022			 ES20-13172
* Mukesh/Mayukh               09/08/2023             143281 - Calculate the Channel info during D1 Registration
*/ 
@RestResource(urlMapping='/myDiageoRegistration/')
global with sharing class MD_RegistrationREST  {

    global class RegistrationInputs{
        global Map<Id,Set<Id>> contactsMap {get;set;}
        global String countryCode {get;set;}
        global Boolean caseHandling {get;set;} 
        global Boolean allOrNone {get;set;}
        global String source {get;set;}
        global String subscriptionSource {get;set;} //optional, default value is "Backend"
        global String userProfile {get;set;} //optional, default value is "Primary"
        global String languageLocaleKey {get;set;}//ES20-13172
        global String subscriptionValue {get;set;}//ES20-13172
        global List<RegistrationPermissionInputs> permissionList {get; set;} //optional, required for sending user permission from edge
    }

    //NCP-2805
    global class RegistrationPermissionInputs {
        global String permissionName {get; set;}
        global Boolean accessLevel {get;set;}
    }

    /*
        Workbench: /services/apexrest/myDiageoRegistration/
        Request Body Example:
        {             
           "contactsMap":{  
              "003X XXXXXXXXXXXXX":[  
                 "001XXXXXXXXXXXXXX"
              ],
              "003XXXXXXXXXXXXXX":[  
                 "001XXXXXXXXXXXXXX",
                 "001XXXXXXXXXXXXXX"
              ]
           },
           "countryCode":"GB",
           "caseHandling":false,
           "allOrNone":false,
           "languageLocaleKey" : "en_GB",
           "subscriptionValue" : "Email",
           "source":"Other",
           "subscriptionSource":"FrontendApp",
           "userProfile":"Secondary",
           "permissionList":[
               {
                   "permissionName" : "My Contracts",
                   "accessLevel" : true
               }
           ]
        } 

        {             
           "contactsMap":{  
              "0033W000004S8JLQA0":[  
                 "0013W000004iVRpQAM"
              ]
           },
           "countryCode":"ES",
           "caseHandling":false,
           "allOrNone":false,
           "source":"Other",
           "subscriptionSource":"FrontendApp",
           "userProfile":"Secondary"
        } 
    */
    
    @HttpPost
    global static void registerContacts(){
        
        RestRequest request = RestContext.request;
        RegistrationInputs inputData = (RegistrationInputs) JSON.deserialize(request.requestBody.toString(),RegistrationInputs.class);
        RestResponse resp = RestContext.response;
        resp.addHeader('Accept', 'application/json');
        resp.addHeader('Content-Type', 'application/json');
        try{ 
            if(inputData.subscriptionSource == 'Frontend'){//call MyDiageo
                Map<Id,Map<Id,String>> responseMap = MD_RegistrationUtil.registerContacts(inputData.contactsMap, inputData.countryCode, inputData.caseHandling, inputData.allOrNone, inputData.source, inputData.subscriptionSource, inputData.userProfile);            
                resp.statusCode = resolveStatusCode(responseMap);
                resp.responseBody = Blob.valueOf(JSON.serialize(responseMap));                
            } 
            else if(inputData.subscriptionSource == 'FrontendApp'){//call DiageoOne                
                String accountId='';
                String contactId = '';
                Set<Id> accountIds = new Set<Id>();  
                Set<Id> contactIds = new Set<Id>();     
                for(Id conId: inputData.contactsMap.keySet()){
                    accountIds.addAll(inputData.contactsMap.get(conId));
                    contactIds.add(conId);
                }                
                contactId = (new List<Id>(contactIds))[0];//currently sending only single contact from EDGE 365 
                accountId = (new List<Id>(accountIds))[0];                
                Contact registeringContact = [SELECT Id,AccountId,FirstName,Lastname,Email,Mobile__c,MobilePrefix__c,Account.Direct_Customer__c,Preferred_Language__c,Account.Global_Channel__c FROM Contact WHERE Id =:contactId]; //143281 - Added channel
                D1_UserRegistrationValidator.UserValidationResultWrapper userResultWrapper = checkDirectCustomer(registeringContact,inputData);
                system.debug(Logginglevel.DEBUG, userResultWrapper);
                Map<Id,String> resultStatusMap = new Map<Id,String>();
                if(userResultWrapper.isSuccess == true && userResultWrapper.isAutomaticRegistration != null && userResultWrapper.isAutomaticRegistration){
                    resultStatusMap.put(accountId,Label.D1_Successful_Registration);    
                }else if(userResultWrapper.isSuccess == false && userResultWrapper.isUserExists != null && userResultWrapper.isUserExists){
                    resultStatusMap.put(accountId,Label.D1_User_registration_From_EDGE_365_already_have_account);
                }else if(userResultWrapper.isSuccess == false && userResultWrapper.isNoPrimaryContact != null && userResultWrapper.isNoPrimaryContact){
                    resultStatusMap.put(accountId,Label.D1_User_registration_primary_contact_not_exist);
                }else if(userResultWrapper.isSuccess == true && userResultWrapper.isManualRegistration != null && userResultWrapper.isManualRegistration){
                    resultStatusMap.put(accountId,Label.D1_EDGE365_Direct_Customer_Registration);
                }else if(userResultWrapper.isSuccess == false && userResultWrapper.isEmailDiageoDomain != null && userResultWrapper.isEmailDiageoDomain){ //Added NCP-2273
                    resultStatusMap.put(accountId,Label.D1_Invalid_Email_Domain_Self);
                }else{
                    resultStatusMap.put(accountId,Label.D1_Registration_Unsuccess_Message_1);
                }
                Map<Id,Map<Id,String>> responseMap = new Map<Id,Map<Id,String>>();
                responseMap.put(contactId,resultStatusMap);
                resp.statusCode = resolveStatusCode(responseMap);
                resp.responseBody = Blob.valueOf(JSON.serialize(responseMap));
                system.debug(Logginglevel.DEBUG, resp);
            }
        }catch(Exception e){
            resp.statusCode = 500;
            resp.responseBody = Blob.valueOf(e.getMessage());
        }
    }

    //Method: 
    @TestVisible
    private static Integer resolveStatusCode(Map<Id,Map<Id,String>> responseMap) {
        Boolean hadRegistrationSuccess = false;
        Integer statusCode = 400;
        for(String accId : responseMap.keySet()) {
            Map<Id,String> accContactsMap = responseMap.get(accId);
            for(String conId : accContactsMap.keySet()) {
                String contactResult = accContactsMap.get(conId);
                if(contactResult == Label.MD_RegistrationAPI_Success || 
                   contactResult == Label.D1_Successful_Registration || 
                   contactResult == Label.D1_User_registration_From_EDGE_365_already_have_account || 
                   contactResult == Label.D1_User_registration_primary_contact_not_exist ||
                   contactResult == Label.D1_EDGE365_Direct_Customer_Registration ||
                   contactResult == Label.D1_Invalid_Email_Domain_Self ||
                   contactResult == Label.D1_Registration_Unsuccess_Message_1) //NCP-2273 
                {
                    hadRegistrationSuccess = true;
                    break;
                }
            }
            if(hadRegistrationSuccess) {
                break;
            }
        }
        if(hadRegistrationSuccess) {
            statusCode = 200;
        }
        System.debug(Logginglevel.DEBUG, statusCode);
        return statusCode;
    }

    //Method: 
    public static D1_UserRegistrationValidator.UserValidationResultWrapper checkDirectCustomer(Contact registeringContact,RegistrationInputs inputData){
        D1_UserRegistrationValidator.UserValidationResultWrapper userResultWrapper  = new D1_UserRegistrationValidator.UserValidationResultWrapper();
        if(registeringContact.Account.Direct_Customer__c){            
            D1_UserRegistrationDetailWrapper caseWrap  = new D1_UserRegistrationDetailWrapper();
            caseWrap.accountId = registeringContact.AccountId;
            caseWrap.firstName = registeringContact.firstName;
            caseWrap.lastName = registeringContact.lastName;
            caseWrap.mobileCountryCode = registeringContact.MobilePrefix__c;
            caseWrap.mobile = registeringContact.Mobile__c;
            caseWrap.subscriptionSource = inputData.subscriptionSource;
            caseWrap.userCountryCode = inputData.countryCode;  
            caseWrap.email =  registeringContact.Email;
            userResultWrapper = D1_UserRegistrationValidator.createCase(caseWrap);      
        }else{
            //Get D1 Setting - NCP-6506
            D1_Setting__c d1Setting = D1_UserRegistrationValidator.getD1Setting(inputData.countryCode, registeringContact.Preferred_Language__c);

            //Get D1 User Type - NCP-6506 //143281 - Added Account as a parameter to check Channel 
            D1_User_Type__c d1UserType = D1_UserRegistrationValidator.getD1UserType(d1Setting.Id, 'Outlet/Retailers',registeringContact.Account.Global_Channel__c);

            //Create Wrapper
            D1_UserRegistrationDetailWrapper userRegWrapper  = new D1_UserRegistrationDetailWrapper();
            userRegWrapper.accountId = registeringContact.AccountId;
            userRegWrapper.firstName = registeringContact.FirstName;
            userRegWrapper.lastname = registeringContact.LastName;
            userRegWrapper.email = registeringContact.Email;
            userRegWrapper.mobile = registeringContact.Mobile__c;
            userRegWrapper.userCountryCode = inputData.countryCode;
            userRegWrapper.mobileCountryCode = registeringContact.MobilePrefix__c;
            userRegWrapper.subscriptionSource = inputData.subscriptionSource;
            userRegWrapper.languageLocaleKey = (String.isNotBlank(inputData.languageLocaleKey) ? inputData.languageLocaleKey : d1Setting.Language__c); //ES20-13172
            userRegWrapper.contactId = registeringContact.Id; 
            userRegWrapper.permissionList = inputData.permissionList;
            userRegWrapper.d1SettingId = d1Setting.Id; //NCP-6506
            userRegWrapper.userType = d1UserType.User_Type__c; //NCP-6506
            userRegWrapper.userTypeId = d1UserType.Id; //NCP-6506
            userRegWrapper.subscriptionValue=inputData.subscriptionValue;//ES20-13172
            userResultWrapper = D1_UserRegistrationValidator.validateUser(userRegWrapper);  
            
        }
        return userResultWrapper;     
    }
}