/*
Project : DiageoOne
Author: Dipanjan Das
Jira Story : NCP-273
Description : Country Option in Header Public Landing Page
@history
VERSION     AUTHOR           DATE           DETAIL
1.0         Mukesh Kanth     22/05/2024     152907- Updated Region Selector, Profile Drop Down (User initials, Account Name)
*/
public without sharing class D1_LocationSelectorController {
   
    
    @AuraEnabled(cacheable=true)
    public static List<LanguageWrapper> getLocationWithLanguage() {
        List<LanguageWrapper> languageWrapList = new List<languageWrapper>();

        for(D1_Setting__c d1Setting : [ SELECT Market__r.Name, Market__r.Code__c, Market__r.Domain__c, Market__r.Flag_Content_Version_Id__c, Market__r.DiageoOne_Default__c, Language__c,Default__c
                                        FROM D1_Setting__c 
                                        WHERE Market__r.isDiageoOneEnabled__c = True 
                                        AND Market__r.RecordType.Name = 'Country' Order by Market__r.Code__c]){
            if(String.isNotBlank(d1Setting.Language__c)){
                languageWrapList.add(new LanguageWrapper(d1Setting));
            }                   
        }
        return languageWrapList;
    }

    public class LanguageWrapper{
        final String contentDownloadUrl = System.Label.D1_ContentDownloadURL;
        @AuraEnabled public String countryFullName;
        @AuraEnabled public String countryName;
        @AuraEnabled public String languageCode;
        @AuraEnabled public String countryWIthLanguage;
        @AuraEnabled public Boolean isDefault; 
        @AuraEnabled public string targetUrl;
        @AuraEnabled public string flagUrl;
        @AuraEnabled public Boolean diageoOneDefault; 

        LanguageWrapper(D1_Setting__c d1Setting){
            this.countryFullName = d1Setting.Market__r.Name;
            this.countryName = d1Setting.Market__r.Code__c;
            this.languageCode = d1Setting.Language__c;
            this.isDefault = d1Setting.Default__c;
            this.diageoOneDefault = d1Setting.Market__r.DiageoOne_Default__c;
            if(d1Setting.Market__r.Flag_Content_Version_Id__c!=null){
                this.flagUrl=contentDownloadUrl + d1Setting.Market__r.Flag_Content_Version_Id__c;
            }   
            //152907
            this.countryWIthLanguage = d1Setting.Market__r.Flag_Content_Version_Id__c != null? ' (' + d1Setting.Language__c.left(2) +')': countryName + ' (' +languageCode.left(2)+ ')';
            this.targetUrl = d1Setting.Market__r.Domain__c;   
        }
               
    }
}