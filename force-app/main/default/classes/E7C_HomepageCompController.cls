public without sharing class E7C_HomepageCompController {
    
    @AuraEnabled
    public static List<String> getActiveSurveyLocations(){
        List<String> activeMarkets = new List<String>();
        List<Survey__c> surveyList = [SELECT Id, Country__r.Name FROM Survey__c
                                          WHERE IsActive__c = true AND RecordType.DeveloperName = 'Guinness_Brand_Survey' ORDER BY Country__r.Name ASC];
        
        for(Survey__c srRec : surveyList){
            activeMarkets.add(srRec.Country__r.Name);
        }
        
        return activeMarkets;
    }

}