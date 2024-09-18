public with sharing class MD_TabsFAQsController {

    @AuraEnabled
    public static String getFAQsTitles(String extIds){
        List<String> externalIds = (List<String>)JSON.deserialize(extIds, List<String>.class);
        Map<String, String> faqsTitles = new Map<String, String>();

        List<DiageoCMS__Component__c> components = [SELECT Id, DiageoCMS__ExternalId__c, DiageoCMS__Title__c 
                                                        FROM DiageoCMS__Component__c 
                                                        WHERE DiageoCMS__ExternalId__c IN :externalIds];

        for(DiageoCMS__Component__c comp : components) {
            DiageoCMS.TranslationUtils.getTranslated(comp, 'es', 'DiageoCMS__Component__c');
            faqsTitles.put(comp.DiageoCMS__ExternalId__c, comp.DiageoCMS__Title__c);
        }

        return JSON.serialize(faqsTitles);
    }
}