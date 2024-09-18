/**
 * @name D1_UserRegistrationDetailWrapper
 * @description D1_UserRegistrationDetailWrapper Wrapper Class for validating user's registration request.
 * @history
 * VERSION     AUTHOR           DATE           DETAIL
 * 1.0         Sagar Barman     09/07/2020   
 * 2.0         Kapil Baliyan    28/04/2021     NCP-2805 (permissionList)
 * 3.0         Kapil Baliyan    25/08/2021     NCP-
 * 4.0         Kapil Baliyan    02/12/2021     NCP-5517
 * 5.0         Kapil Baliyan    18/08/2022     NCP-7209
**/
public  class D1_UserRegistrationDetailWrapper {    
    
    @AuraEnabled public String accountId{get;set;}
    @AuraEnabled public String firstName{get;set;}
    @AuraEnabled public String lastName{get;set;}
    @AuraEnabled public String email{get;set;}
    @AuraEnabled public String mobile{get;set;}   
    @AuraEnabled public String languageLocaleKey{get;set;}
    @AuraEnabled public String userType{get;set;}
    @AuraEnabled public String userCountryCode{get;set;}
    @AuraEnabled public String mobileCountryCode{get;set;}    
    @AuraEnabled public String primarySalesRepEmail{get;set;}
    @AuraEnabled public String userTypeId{get;set;}
    @AuraEnabled public String subscriptionSource{get;set;}
    @AuraEnabled public String contactId{get;set;}
    @AuraEnabled public String subscriptionValue{get;set;}
    @AuraEnabled public String accountNumber{get;set;}
    @AuraEnabled public String d1SettingId{get;set;} 
	@AuraEnabled public String userPermission{get;set;}
    @AuraEnabled public List<MD_RegistrationREST.RegistrationPermissionInputs> permissionList {get; set;} //NCP-2805
    @AuraEnabled public string outletName {get;set;}
    @AuraEnabled public string street {get;set;}
    @AuraEnabled public string city {get;set;}
    @AuraEnabled public string postalCode {get;set;}
    @AuraEnabled public string countryCode {get;set;}
    @AuraEnabled public string phoneNumberPrefix {get;set;}
    @AuraEnabled public string phoneNumber {get;set;}
    @AuraEnabled public string phone {get;set;}
    @AuraEnabled public string outletRole {get;set;}
    @AuraEnabled public string registrationType {get;set;}
    @AuraEnabled public string uin {get;set;}
    @AuraEnabled public string description {get;set;}
    @AuraEnabled public string customerSAPCode {get;set;}
    @AuraEnabled public string leadType {get; set;}
    @AuraEnabled public string survey {get; set;}

    @AuraEnabled public string area {get; set;}
    @AuraEnabled public string region {get; set;}
    @AuraEnabled public string areaName {get; set;}
    @AuraEnabled public string regionName {get; set;}
    @AuraEnabled public string outletType {get; set;}
    @AuraEnabled public string outletTypeId {get; set;}
    @AuraEnabled public string outletSubType {get; set;}
    @AuraEnabled public string outletSubTypeURL {get; set;}
    @AuraEnabled public string regSource {get; set;}
    @AuraEnabled public Boolean isSecondaryRegistration {get; set;}
}