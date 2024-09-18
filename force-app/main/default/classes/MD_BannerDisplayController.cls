public without sharing class MD_BannerDisplayController {
    
    @auraEnabled public static double CustomHeightValue{get;set;}
    
    @auraEnabled
    public static MediaElementWrapperClass GetimageDetails(string ComponentExternalId,string deviceType)
    {
        system.debug('ComponentExternalId:::::'+ComponentExternalId);
        system.debug('deviceType:::::::'+deviceType);
        string UrlType='';
        string ContentId='';
         MediaElementWrapperClass wrapperInstance = new MediaElementWrapperClass();
        DiageoCMS__Component__c GetCustomHeightValue = [select DiageoCMS__CustomHeight__c from DiageoCMS__Component__c where
                                                        DiageoCMS__ExternalId__c=:ComponentExternalId];
        wrapperInstance.CustomHeightValue1 = GetCustomHeightValue.DiageoCMS__CustomHeight__c;
        
        DiageoCMS__TagAssignment__c getAllTags = [select DiageoCMS__Tag__c,DiageoCMS__Tag__r.Name,DiageoCMS__Component__r.Name from DiageoCMS__TagAssignment__c
                                                  where DiageoCMS__Component__r.DiageoCMS__ExternalId__c=:ComponentExternalId];
        system.debug('Tags Query:::::::::'+getAllTags);
        
        list<DiageoCMS__TagAssignment__c> getAllContentTags = [select DiageoCMS__Content__c,DiageoCMS__Tag__r.Name,DiageoCMS__Component__r.Name from DiageoCMS__TagAssignment__c
                                                         where DiageoCMS__Tag__c=:getAllTags.DiageoCMS__Tag__c and DiageoCMS__Content__r.RecordType.Name='Banner'];
        
        system.debug('Content Query:::::::::'+getAllContentTags);
        ContentId = getAllContentTags[0].DiageoCMS__Content__c;
        list <DiageoCMS__MediaElementAssignment__c> getAllMediaElements = [select id,DiageoCMS__Content__c,DiageoCMS__MediaElement__r.Name,DiageoCMS__MediaElement__r.DiageoCMS__FileURLDesktop__c
                                                                           ,DiageoCMS__MediaElement__r.DiageoCMS__FileURLMobile__c,
                                                                           DiageoCMS__MediaElement__r.DiageoCMS__FileURLTablet__c 
                                                                           from DiageoCMS__MediaElementAssignment__c where DiageoCMS__Content__c=:ContentId];
        
        system.debug('media Element Query:::::::::'+getAllContentTags[0].DiageoCMS__Content__c+':::::::::::Media Elements::::::'+getAllMediaElements);
       
        if(deviceType=='DESKTOP')
        {
            wrapperInstance.imageurl=getAllMediaElements[0].DiageoCMS__MediaElement__r.DiageoCMS__FileURLDesktop__c;
            system.debug('Loaded for Desktop::::::::'+UrlType);
        }
        else if(deviceType=='PHONE')
        {
            wrapperInstance.imageurl=getAllMediaElements[0].DiageoCMS__MediaElement__r.DiageoCMS__FileURLMobile__c;
            system.debug('Loaded for phone::::::::'+UrlType);
        }
        else if(deviceType=='TABLET')
        {
            wrapperInstance.imageurl=getAllMediaElements[0].DiageoCMS__MediaElement__r.DiageoCMS__FileURLTablet__c;
            system.debug('Loaded for tablet::::::::'+UrlType);
        }
        return wrapperInstance;
    }
    
    public static double getCustomHeight(string ComponentExternalId)
    {
        DiageoCMS__Component__c GetCustomHeightValue = [select DiageoCMS__CustomHeight__c from DiageoCMS__Component__c where
                                                        DiageoCMS__ExternalId__c=:ComponentExternalId];
        
        if(GetCustomHeightValue.DiageoCMS__CustomHeight__c!=null && GetCustomHeightValue.DiageoCMS__CustomHeight__c >0 )
        {
            GetCustomHeightValue.DiageoCMS__CustomHeight__c=CustomHeightValue;
        }
        
        return CustomHeightValue;
        
    }
      public class MediaElementWrapperClass{
        @AuraEnabled public string imageurl{get;set;}
        @AuraEnabled public double CustomHeightValue1 {get;set;}
    }

    
}