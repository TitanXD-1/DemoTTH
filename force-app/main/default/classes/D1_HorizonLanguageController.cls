/*
* @name: D1_HorizonLanguageController
* @discription: Horizon Language selector
* @history
* VERSION     AUTHOR      DATE    DETAIL
* 1.0         Ajay       8/20     Initial Development(NCP-1102)
*/
public without sharing class D1_HorizonLanguageController {
    final static String DEFAULT_CODE = System.Label.D1_DefaultHorizonLanguageCode;
    @AuraEnabled 
    public String horizonLanguageCode{get;set;}
    public D1_HorizonLanguageController() {
        String countryCode = findCountryCode();
        String horizonCode;
        List<String> countryCodeSplit = countryCode.split(';');
        List<D1_HorizonLanguageMapping__mdt> mappingRecords = [SELECT Country_Code__c,salesforceLanguageCode__c,horizonLanguageCode__c
                                                                FROM D1_HorizonLanguageMapping__mdt WHERE Country_Code__c =: countryCodeSplit[0]
                                                                ]; 
        if(mappingRecords.size()>1){ // added additional filter to handle scenario like single country having multiple language NCP-6217
            for(D1_HorizonLanguageMapping__mdt mapping: [SELECT Country_Code__c,salesforceLanguageCode__c,horizonLanguageCode__c
                                                         FROM D1_HorizonLanguageMapping__mdt
                                                         WHERE Country_Code__c =: countryCodeSplit[0] and salesforceLanguageCode__c=:countryCodeSplit[1]
                                                         LIMIT 1]){
                horizonCode = mapping.horizonLanguageCode__c;
            }
        }
        else{ //if single country-single language then using old flow , we can't merge these  two conditions                    NCP-6217
            // because IE,NIR have en_IE,en_ie as salesforceLanguageCode en_ie as added as lower case to bypass duplicate rule on custom metadata
            //(where as salesforce has only en_IE added en_ie) and since soql is case sensitive we can't fetch en_ie record .
            if(mappingRecords.size()>0){
                horizonCode = mappingRecords[0].horizonLanguageCode__c;
            }
        }
        
        this.horizonLanguageCode = String.isBlank(horizonCode) ? DEFAULT_CODE: horizonCode;
    }

    public String findCountryCode(){

        String countryCode = ApexPages.currentPage().getParameters().get('country')+';'+ApexPages.currentPage().getParameters().get('language');

        if(String.isBlank(countryCode)){ //Authenticated user language will not be send from URL
            User usr = [SELECT Available_Countries__c,LanguageLocaleKey from user where id =:UserInfo.getUserId() limit 1];
            countryCode = usr.Available_Countries__c+';'+usr.LanguageLocaleKey;//NCP-6217
        }
        countryCode = String.isEmpty(countryCode) ?'GB;en_GB':countryCode;
        return String.escapeSingleQuotes(countryCode);

    } 
    @AuraEnabled(cacheable = true)
    public static String getHorizonLanguageCode(String countryCode){
        String horizonCode;
        User usr = [SELECT Available_Countries__c,LanguageLocaleKey from user where id =:UserInfo.getUserId() limit 1];
        countryCode = usr.Available_Countries__c;
        List<D1_HorizonLanguageMapping__mdt> mappingRecords = [SELECT Country_Code__c,salesforceLanguageCode__c,horizonLanguageCode__c
                                                                FROM D1_HorizonLanguageMapping__mdt WHERE Country_Code__c =: usr.Available_Countries__c
                                                                ]; 
        if(mappingRecords.size()>1){    
            for(D1_HorizonLanguageMapping__mdt mapping: [SELECT Country_Code__c,salesforceLanguageCode__c,horizonLanguageCode__c
                                                         FROM D1_HorizonLanguageMapping__mdt
                                                         WHERE Country_Code__c =: usr.Available_Countries__c and salesforceLanguageCode__c =: usr.LanguageLocaleKey
                                                         LIMIT 1]){
                horizonCode = mapping.horizonLanguageCode__c;
            }
        }
        else{
            if(mappingRecords.size()>0){
                horizonCode = mappingRecords[0].horizonLanguageCode__c;
            }
            
        }                                                       
        return String.isBlank(horizonCode) ? DEFAULT_CODE: horizonCode;  

    } 
   @AuraEnabled(cacheable = true)
    public static String getHorizonCode(String countryCode,String languageCode){//NCP-6331
        String horizonCode;
        List<D1_HorizonLanguageMapping__mdt> mappingRecords = [SELECT Country_Code__c,salesforceLanguageCode__c,horizonLanguageCode__c
                                                                FROM D1_HorizonLanguageMapping__mdt
                                                                WHERE Country_Code__c =: countryCode and salesforceLanguageCode__c=:languageCode
                                                                LIMIT 1]; 
        if(mappingRecords.size()>0){ 
                horizonCode = mappingRecords[0].horizonLanguageCode__c;
        }
        return String.isBlank(horizonCode) ? DEFAULT_CODE: horizonCode;  
    }
}