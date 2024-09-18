/**********************************************************************************************************
Name: EDGE_NotesServiceHelperClassTest

=========================================================================================================
History                                                            
-------                                                            
VERSION     AUTHOR                  DATE            DETAIL
1.0         Monalisa Halder         22/04/2019      Test Class for EDGE_NotesServiceHelperClass apex class.
                                                    Was Getting Error Message   
                                                    System.UnsupportedOperationException: 
                                                    ConnectApi methods are not supported in data siloed tests.
                                                    Because of this reason had to use 'SeeAllData=true'

2.0        Prasanth T               23/09/2022      Test Class Correction Due to Failure(ES20-13324)

3.0        Joshraj Sen              12/10/2022      Test Class Correction Due to Failure(ES20-13386)
*************************************************************************************************************/

@IsTest(SeeAllData=true)
public class EDGE_NotesServiceHelperClassTest{
    public static User userRec;
    public static Account outlet;
    public static List<ContentVersion> conVerRec;
    public static List<ContentDocument> documents;
   
    
     @isTest
    public static void testNotesCreateService(){
        
        User u  = [Select Id , ProfileId from User where Profile.Name = 'System Administrator' LIMIT 1];

        
        //Test.startTest();
        createData();
        documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument where LatestPublishedVersionId =: conVerRec[0].Id];
        //String contentDocId = conVerRec[0].ContentDocumentId;
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        String requri='services/apexrest/NotesService?userid=';
        requri = requri+ String.valueOf(u.Id);
        req.requestUri =requri;
        req.params.put('userid', u.Id);            
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        system.debug(LoggingLevel.Debug,('@@outletId' +outlet));
        system.debug(LoggingLevel.Debug,('@@documents[0].Id' +documents[0].Id));
        //EDGE_BriefcaseWrapper briefcaseWrapper = EDGE_NotesServiceClass.createNotes(outlet.Id, documents[0].Id, 'Text Message');
        system.assert(documents[0].Id != null,'documents Id should not be null');
        //Test.stopTest();
    }  
    
    @isTest
    public static void testNotesUpdateService(){
        
        User u  = [Select Id , ProfileId from User where Profile.Name = 'System Administrator' LIMIT 1];
        //User u = EDGE_UtilityTestClass.runAsUser('salesRep28', 'Master Data Manager');
        //insert u;
        //Test.startTest();
        createData(); 
        
        documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument where LatestPublishedVersionId =: conVerRec[0].Id];
        //Test.stopTest();
        //String contentDocId = conVerRec[0].ContentDocumentId;
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        String requri='services/apexrest/NotesService?userid=';
        requri = requri+ String.valueOf(u.Id);
        req.requestUri =requri;
        req.params.put('userid', u.Id);            
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        //System.debug('@@Limit 74-'+Limits.getQueries());
        EDGE_NotesServiceHelperClass.createNotes(outlet.Id, documents[0].Id, 'Text Message');
        FeedItem feed = [Select Id from FeedItem where parentId =:outlet.Id Limit 1];
        //System.debug('@@Limit 77-'+Limits.getQueries());
        system.debug(LoggingLevel.Debug,('@@feed' +feed));
        
        
        //List<ContentDocument> documents1 = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument where LatestPublishedVersionId =: conVerRec[1].Id];
        //EDGE_BriefcaseWrapper briefcaseWrapper = EDGE_NotesUpdateServiceClass.updateNotes(feed.Id, documents1[0].Id, 'Text Message');
        system.assert(documents[0].Id != null,'documents Id should not be null');
        
    }    
   
    public static void createData(){
        
        Id geographyId;
        Id clusterId;
        Id hubId;
        Id marketId;
        Id areaId;
        Id regionId;
        string countryCode;
        
        //EDGE_UtilityTestClass.createOrgSettings();
        
        Org_Setting__c orgSetting = Org_Setting__c.getOrgDefaults();
        orgSetting.Run_Triggers__c=false;
        update orgSetting;
        Test.startTest();
        
        List<Geography__c> geoList = [Select Id, Code__c, Parent_Geography__c, Name, RecordTypeId, RecordType.Name from Geography__c];
        
        if(geoList == null || geoList.size()==0){
            geographyId = EDGE_UtilityTestClass.setupCountry('AU');
            geoList = [Select Id, Code__c, Parent_Geography__c, Name, RecordTypeId, RecordType.Name from Geography__c];
        }
        
        for(Geography__c geo : geoList){
            if(geo.Code__c == 'AU'){
                geographyId = geo.Id;
                countryCode = geo.Code__c;
            }else if(geo.Code__c == 'AUCT' || geo.Code__c == 'AUSC'){
                clusterId = geo.Id;
            }else if(geo.Code__c == 'AUHT' || geo.Code__c == 'AUSH'){
                hubId = geo.Id;
            }else if(geo.Code__c == 'APAT' || geo.Code__c == 'APAC'){
                marketId = geo.Id;
            }else if(geo.Code__c == 'SAU1' || geo.Code__c == 'AUA'){
                areaId = geo.Id;
            }else if(geo.Code__c == 'SAU2' || geo.Code__c == 'QLD'){
                regionId = geo.Id;
            }
        }
           
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(geographyId, 'Outlet Visit Prioritization');
        pickupOption.Name = 'GoldTest[' + countryCode + ']';
        pickupOption.Status__c = 'Active';
        insert pickupOption;
        //System.debug('@@Limit 1-'+Limits.getQueries());
        //Creating Content Version Record
        conVerRec=new List<ContentVersion>();
        ContentVersion conVerRec1 = EDGE_UtilityTestClass.gerConVerRec('Test.jpeg');
        conVerRec1.Content_Type__c = 'Notes';
        conVerRec1.RecordTypeId = ContentVersion.sObjectType.getDescribe().getRecordTypeInfosByName().get('Notes').getRecordTypeId();
        conVerRec.add(conVerRec1);
        
        //Creating Content Version Record
        ContentVersion conVerRec2 = EDGE_UtilityTestClass.gerConVerRec('Test1.jpeg');
        conVerRec2.Content_Type__c = 'Notes';
        conVerRec2.RecordTypeId = ContentVersion.sObjectType.getDescribe().getRecordTypeInfosByName().get('Notes').getRecordTypeId();
        conVerRec.add(conVerRec2);
        
        insert conVerRec;
        //System.debug('@@Limit 141-'+Limits.getQueries());
        Test.stopTest();
        outlet = EDGE_UtilityTestClass.getOutletRecord(); 
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        outlet.Global_Channel__c = 'Off Trade';
        outlet.Global_Sub_Channel__c ='Retailer';
        outlet.Global_Segment__c = 'Discounter';
        outlet.Global_Sub_Segment__c = 'Modern Discounter';
        outlet.Market__c = marketId;
        outlet.Hub__c = hubId;
        outlet.Cluster__c = clusterId;
        outlet.Country__c = geographyId;
        outlet.Area__c = areaId;
        outlet.Region__c = regionId;
        
        insert outlet;
        //System.debug('@@Limit 2-'+Limits.getQueries());
        //Creating Call Record
        Call__c callRec = EDGE_UtilityTestClass.getCallRec(outlet.Id);
        system.debug(LoggingLevel.Debug,('@@@callRec' +callRec));
        insert callRec;
        //System.debug('@@Limit 3-'+Limits.getQueries());
        
        
        
        System.assert(conVerRec1.Id != null,'conVer Rec1 Id should not be null');   
    }
}