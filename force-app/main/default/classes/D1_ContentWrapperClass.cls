/*
 @name : D1_ContentWrapperClass
 @description : D1_ContentWrapperClass Class for D1_ContentController class
 @history
VERSION     AUTHOR           DATE       DETAIL
1.0        Sudipta Nandi    08/29/20   Created
 **/
public with sharing class D1_ContentWrapperClass {
    @AuraEnabled public String headerValue {get;set;} 
    @AuraEnabled public String subHeaderValue {get;set;} 
    @AuraEnabled public String imageUrl {get;set;} 
    @AuraEnabled public String externalLink1 {get;set;} 
    @AuraEnabled public String externalLink2 {get;set;} 
    @AuraEnabled public String externalLinkText1 {get;set;} 
    @AuraEnabled public String externalLinkText2 {get;set;}
    @AuraEnabled public String errorMessage {get;set;} 
    @AuraEnabled public String bodyText {get;set;} 
    @AuraEnabled public String excerptText {get;set;} 
    @AuraEnabled public String signUpUrl {get;set;}
    @AuraEnabled public String contentSlugText {get;set;}
    @AuraEnabled public String contentkeyText {get;set;}
    @AuraEnabled public String contentType {get;set;}
    @AuraEnabled public String content_URL {get;set;}
    @AuraEnabled public Boolean isExternalUrl {get;set;}
    
    @AuraEnabled public String DirectCustomer1stCTALabel {get;set;}
    @AuraEnabled public String DirectCustomers1stCTAURL {get;set;}
    @AuraEnabled public String IndirectCustomers1stCTALabel {get;set;}
    @AuraEnabled public String IndirectCustomers1stCTAURL {get;set;}
    @AuraEnabled public String DirectCustomer2ndCTALabel {get;set;}
    @AuraEnabled public String DirectCustomers2ndCTAURL {get;set;}
    @AuraEnabled public String IndirectCustomers2ndCTALabel {get;set;}
    @AuraEnabled public String IndirectCustomers2ndCTAURL {get;set;}

    @AuraEnabled public String DirectCustomerCTALabel {get;set;}
    @AuraEnabled public String DirectCustomersCTAURL {get;set;}
    @AuraEnabled public String IndirectCustomersCTALabel {get;set;}
    @AuraEnabled public String IndirectCustomersCTAURL {get;set;}

    public D1_ContentWrapperClass (){
     System.debug(LoggingLevel.INFO, 'EmptyBlock');
    }
    public D1_ContentWrapperClass (String headerValue, String subHeaderValue,
                                   String imageUrl, String externalLink1, String externalLink2,
                                   String externalLinkText1, String externalLinkText2,String errorMessage, 
                                   String bodyText, String excerptText,String contentSlugText,String contentkeyText,
                                   string contentType,string content_URL,Boolean isExternalUrl,
                                   string DirectCustomer1stCTALabel,string DirectCustomers1stCTAURL,
                                   string IndirectCustomers1stCTALabel,string IndirectCustomers1stCTAURL,
                                   string DirectCustomer2ndCTALabel,string DirectCustomers2ndCTAURL,
                                   string IndirectCustomers2ndCTALabel,string IndirectCustomers2ndCTAURL,
                                   String DirectCustomerCTALabel,String DirectCustomersCTAURL,
                                   String IndirectCustomersCTALabel,String IndirectCustomersCTAURL ){
                                        this.headerValue = headerValue;
                                        this.subHeaderValue = subHeaderValue;
                                        this.imageUrl = imageUrl;
                                        this.externalLink1 = externalLink1;
                                        this.externalLink2 = externalLink2;
                                        this.externalLinkText1 = externalLinkText1;
                                        this.externalLinkText2 = externalLinkText2;
                                        this.errorMessage = errorMessage;
                                        this.bodyText=bodyText;
                                        this.excerptText=excerptText;
                                        this.contentSlugText=contentSlugText;
                                        this.contentkeyText=contentkeyText;
                                        this.contentType=contentType;
                                        this.content_URL=content_URL;
                                        this.isExternalUrl= isExternalUrl;
                                        this.DirectCustomer1stCTALabel = DirectCustomer1stCTALabel;
                                        this.DirectCustomers1stCTAURL = DirectCustomers1stCTAURL;
                                        this.IndirectCustomers1stCTALabel = IndirectCustomers1stCTALabel;
                                        this.IndirectCustomers1stCTAURL = IndirectCustomers1stCTAURL;
                                        this.DirectCustomer2ndCTALabel = DirectCustomer2ndCTALabel;
                                        this.DirectCustomers2ndCTAURL = DirectCustomers2ndCTAURL;
                                        this.IndirectCustomers2ndCTALabel = IndirectCustomers2ndCTALabel;
                                        this.IndirectCustomers2ndCTAURL = IndirectCustomers2ndCTAURL;
                                        
                                        
                                        this.DirectCustomerCTALabel  = DirectCustomerCTALabel;
                                        this.DirectCustomersCTAURL  = DirectCustomersCTAURL;
                                        this.IndirectCustomersCTALabel  = IndirectCustomersCTALabel;
                                        this.IndirectCustomersCTAURL  = IndirectCustomersCTAURL;
                                        
                                   }


}