/**

* @description : EDGE_UtilityTestClass

* @purpose : This is generic class to create sample records. This class will be used in all test classes [EDGE_UtilityTestClass].

* @history :                                                           

*VERSION    AUTHOR            DATE              DETAIL

*1.0     Sagar Barman     13/02/2019      Initial Development
*1.1     Dipanjan Das     21/02/2019      Added Method getOutletRecord, createOrgSettings 
*1.2     Saurav Paul      26/02/2019      Added Method getOutltTerritory
*1.3     Anuja Chatterjee 04/03/2019      Added Method getPrimaryTerrMemberRec,getSecondaryTerrMemberRec
*1.4     Sagar Barman     09/03/2019      Added Method getOutletMemberRecord
*1.5     Saurav Paul      20/03/2019      Added Method callRec,getPromotionRecord,gerConVerRec,getSurveyAnsr
*1.6     Monalisa Halder  05/04/2019      Added Activity Target List, Survey, Outlet Survey, Outlet Survey Response
*1.7     Anuja Chatterjee 07/04/2019      Added Method getMarketCycle
*1.8     Sandeep Sahoo    17/04/2019      Added method for Opportunity Template
*1.9     Preyanka Ghosh   22/04/2019      Added method for Feed Item
*1.10    Monalisa Halder  14/05/2019      Added method for getAccountPromotion
*1.11    Preyanka Ghosh   11/06/2019      Added method for getContract
*1.12    Preyanka Ghosh   17/06/2019      Added method for getDeliveryPartner
*1.13    Preyanka Ghosh   12/07/2019      Added method for getOrder and Order Line Item
*1.14    Sandeep Sahoo    12/08/2019      Added method for getBespoke
*1.15    Saikiran         27/11/2023      Added method for getDirectCustomer
*/

@isTest
public class EDGE_UtilityTestClass{
    
    
    // Get Account Record type Map
    public static Map <String,Schema.RecordTypeInfo> mapAccountRecordTypes = Account.sObjectType.getDescribe().getRecordTypeInfosByName();
    // Get the record type id of from the Map based on the Name
    public static Id outletRecTypeId = mapAccountRecordTypes.get('Outlet').getRecordTypeId();
    public static Id directCustomerRecTypeId = mapAccountRecordTypes.get('Direct Customer').getRecordTypeId();
    public static Id prospectRecTypeId = mapAccountRecordTypes.get('Prospect').getRecordTypeId();
    public static Id ownerRecTypeId = mapAccountRecordTypes.get('Owner/Operator').getRecordTypeId();    
    public static Id distRecTypeId = mapAccountRecordTypes.get('Distributor/Wholesaler').getRecordTypeId(); 
    public static Id shedRecTypeId = mapAccountRecordTypes.get('Shed').getRecordTypeId(); 
    public static Map<String,Id> geoMap = new Map<String,Id>();
    // Get Geography Record type Map
    public static Map <String,Schema.RecordTypeInfo> mapGeographyRecordTypes = Geography__c.sObjectType.getDescribe().getRecordTypeInfosByName();
    // Get the record type id of from the Map based on the Name
    public static Id globalRecTypeId = mapGeographyRecordTypes.get('Global').getRecordTypeId();
    public static Id marketRecTypeId = mapGeographyRecordTypes.get('Market').getRecordTypeId();
    public static Id hubRecTypeId = mapGeographyRecordTypes.get('Hub').getRecordTypeId();    
    public static Id clusterRecTypeId = mapGeographyRecordTypes.get('Cluster').getRecordTypeId();
    public static Id countryRecTypeId = mapGeographyRecordTypes.get('Country').getRecordTypeId();
    public static Id areaRecTypeId = mapGeographyRecordTypes.get('Area').getRecordTypeId();
    public static Id regionRecTypeId = mapGeographyRecordTypes.get('Region').getRecordTypeId();
    public static Id stateRecTypeId = mapGeographyRecordTypes.get('State').getRecordTypeId();
    
    // Get Pickup Option Record type Map
    public static Map <String,Schema.RecordTypeInfo> mapPickupoptionRecordTypes = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName();
    public static Id outletpriorRecTypeId = mapPickupoptionRecordTypes.get('Outlet Prioritization').getRecordTypeId();
    public static Id producttypeRecTypeId = mapPickupoptionRecordTypes.get('Product Type').getRecordTypeId();
    
    //create account with record type Direct Customer
    public static Account getDirectCustomer(){
        Account directCustomer = new Account();
        directCustomer.Name = 'Test Direct Account';
        directCustomer.D1_EDGE_Customer__c = true;
        directCustomer.Direct_Customer__c = true;
        directCustomer.Market__c = geoMap.get('Market');
        directCustomer.Hub__c = geoMap.get('Hub');
        directCustomer.Cluster__c = geoMap.get('Cluster');
        directCustomer.Country__c = geoMap.get('Country');
        directCustomer.BillingCountry = 'United Kingdom';
        directCustomer.BillingCountryCode = 'GB';
        directCustomer.RecordTypeId =  directCustomerRecTypeId;
        return directCustomer;
    }
    //create account with record type Distributor/Wholesaler    
    public static Account getDistriAccRec(){
        Account distAccount = new Account();
        distAccount.Name = 'Test Distributor Account';
        distAccount.Country__c = geoMap.get('Country');
        distAccount.Hub__c = geoMap.get('Hub');
        distAccount.Market__c = geoMap.get('Market');
        distAccount.Cluster__c = geoMap.get('Cluster');
        distAccount.Region__c = geoMap.get('Region');
        distAccount.Area__c = geoMap.get('Area');
        distAccount.RecordTypeId =  distRecTypeId;
        distAccount.Outlet_Email_Address__c = 'test@test.com';
        distAccount.Global_Channel__c = 'Off Trade';
        distAccount.Global_Sub_Channel__c = 'Retailer';
        distAccount.Global_Segment__c = 'Hypermarket';
        distAccount.Global_Sub_Segment__c = 'Modern Hypermarket';
        distAccount.BillingCountry = 'Australia';
        return distAccount; 
    }
    //create account with record type Owner/Operator
    public static Account getOwnerOperatorAccount(){
        Account ownerAccount = new Account();
        ownerAccount.Name = 'Test_OwnerAccount';
        ownerAccount.RecordTypeId =  OwnerRecTypeId;
        ownerAccount.Country__c = geoMap.get('Country');
        ownerAccount.Hub__c = geoMap.get('Hub');
        ownerAccount.Region__c=geoMap.get('Region');
        ownerAccount.Area__c=geoMap.get('Area');
        ownerAccount.Market__c = geoMap.get('Market');
        ownerAccount.Cluster__c= geoMap.get('Cluster');
        ownerAccount.Outlet_Email_Address__c = 'test@test.com';
        ownerAccount.BillingCountry = 'Australia';
        return ownerAccount;    
    }    
    public static Account getOutletRecord(){
        Account outlet = new Account();
        outlet.Name = 'Test_Outlet';
        outlet.RecordTypeId = OutletRecTypeId;
        outlet.BillingStreet = '17 Asian Highway 45';
        outlet.BillingCity = 'Sydney';
        outlet.BillingState = 'Tasmania';
        outlet.BillingPostalCode = '5668';
        outlet.BillingCountry = 'Australia';
        outlet.BillingCountryCode = 'AU';
        outlet.Country__c = geoMap.get('Country');
        outlet.Hub__c = geoMap.get('Hub');
        outlet.Region__c=geoMap.get('Region');
        outlet.Area__c=geoMap.get('Area');
        outlet.Market__c = geoMap.get('Market');
        outlet.Cluster__c= geoMap.get('Cluster');
        outlet.Outlet_Email_Address__c = 'test@test.com';
        outlet.Global_Channel__c = 'Off Trade';
        outlet.Global_Sub_Channel__c = 'Retailer';
        outlet.Global_Segment__c = 'Hypermarket';
        outlet.Global_Sub_Segment__c = 'Modern Hypermarket';
        outlet.Status__c= 'Active';
        outlet.Independent_of_Operator__c = true;
        outlet.Independent_of_Owner__c = true;
        return outlet;  
    }
    
    public static Account getShedRecord(){
        Account outlet = new Account();
        outlet.Name = 'Test_Outlet';
        outlet.RecordTypeId = shedRecTypeId;
        outlet.BillingStreet = '17 Asian Highway 45';
        outlet.BillingCity = 'Sydney';
        outlet.BillingState = 'Tasmania';
        outlet.BillingPostalCode = '5668';
        outlet.BillingCountry = 'Australia';
        outlet.BillingCountryCode = 'AU';
        outlet.Country__c = geoMap.get('Country');
        outlet.Hub__c = geoMap.get('Hub');
        outlet.Region__c=geoMap.get('Region');
        outlet.Area__c=geoMap.get('Area');
        outlet.Market__c = geoMap.get('Market');
        outlet.Cluster__c= geoMap.get('Cluster');
        outlet.Outlet_Email_Address__c = 'test@test.com';
        outlet.Status__c= 'Active';
        //outlet.ShippingCountry = 'Australia';
        return outlet;  
    }
    
    public static Account getProspectRecord(Id pickOptnId){
        Account prospect = new Account();   
        prospect.Name='Prospect Test';
        prospect.RecordTypeId = prospectRecTypeId;
        prospect.Country__c = geoMap.get('Country');
        prospect.Hub__c = geoMap.get('Hub');
        prospect.Market__c = geoMap.get('Market');
        prospect.Cluster__c = geoMap.get('Cluster');
        prospect.Region__c=geoMap.get('Region');
        prospect.Area__c = geoMap.get('Area');
        prospect.Outlet_Visit_Prioritisation_Grade__c = pickOptnId;
        prospect.BillingState ='Tasmania';
        prospect.BillingCountry = 'Australia';
        prospect.Outlet_Email_Address__c ='abcd@test.com';
        prospect.Independent_of_Operator__c = true;
        prospect.Independent_of_Owner__c = true;
        return prospect;
    }
    public static void createOrgSettings(){
        Org_Setting__c orgSetting = new Org_Setting__c();
        orgSetting.Run_Triggers__c = True;
        insert orgSetting;
    }    
    //create Geography Object
    public static Geography__c createGeography(String recordtypeName){
        Geography__c geography = new Geography__c();
        geography.RecordTypeId =  Geography__c.sObjectType.getDescribe().getRecordTypeInfosByName().get(recordtypeName).getRecordTypeId();
        return geography; 
    }
    
    //Setup Global Geography Hierarchy
    public static Geography__c setupGlobalHierarchy(){
        Geography__c globalRec = createGeography('Global');
        globalRec.Name = 'Global';
        globalRec.Code__c = 'GBL';
        insert globalRec;
        return globalRec;
    } 
    
    //Setup Geography Hierarchy
    public static Id setupCountry(string countryCode){
        
        Geography__c globalRec = createGeography('Global');
        globalRec.Name = 'Global';
        globalRec.Code__c = 'GL';
        globalRec.RecordTypeId=GlobalRecTypeId;
        insert globalRec;
        geoMap.put('Global',globalRec.Id);
        
        Geography__c market = createGeography('Market');
        market.Name = 'Asiapac';
        market.Code__c = 'APAT';
        market.Parent_Geography__c = globalRec.Id;
        market.RecordTypeId=marketRecTypeId;
        insert market;
        //marketMap.put('Market',market.Id);
        geoMap.put('Market',market.Id);
        
        Geography__c hub = createGeography('Hub');
        hub.Name = 'Australia Hub';
        hub.Code__c = 'AUHT';
        hub.Parent_Geography__c = market.Id;
        hub.RecordTypeId=HubRecTypeId;
        insert hub;
        geoMap.put('Hub',hub.Id);
        
        
        Geography__c cluster = createGeography('Cluster');
        cluster.Name = 'Australia Cluster';
        cluster.Code__c = 'AUCT';
        cluster.Parent_Geography__c = hub.Id;
        cluster.RecordTypeId=ClusterRecTypeId;
        insert cluster;
        geoMap.put('Cluster',cluster.Id);
        
        Geography__c country = createGeography('Country');
        country.Name = 'Australia';
        country.Code__c = countryCode;
        country.Parent_Geography__c = cluster.Id;
        country.RecordTypeId=CountryRecTypeId;
        country.Extended_Country_Code__c = 'AU-AUS';
        insert country;
        geoMap.put('Country',country.Id);
        
        
        Geography__c area = createGeography('Area');
        area.Name = 'Australia1';
        area.Code__c = 'SAU1';
        area.Parent_Geography__c = country.Id;
        area.RecordTypeId=AreaRecTypeId;
        insert area;
        geoMap.put('Area',area.Id);
        
        
        Geography__c region = createGeography('Region');
        region.Name = 'Australia2';
        region.Code__c = 'SAU2';
        region.Parent_Geography__c = area.Id;
        region.RecordTypeId=RegionRecTypeId;
        insert region;
        geoMap.put('Region',region.Id);
        
        Geography__c state = createGeography('State');
        state.Name = 'Tasmania';
        state.Code__c = 'ABCD';
        state.Parent_Geography__c = country.Id;
        state.RecordTypeId=stateRecTypeId;
        insert state;
        geoMap.put('State',state.Id);
        
        return country.Id;
        
    }
    
    public static Map<String,Id> getGeoMap(){
        return geoMap;
    }
    
    
    //creates a new user by passing the profile name
    public static User runAsUser(String uniqueKey, String sProfileName) {
        User newUser = new User();      
        if(uniqueKey.length() > 8){
            newUser.Alias = uniqueKey.substring(0,4);
        }
        else {
            newUser.Alias = uniqueKey;
        }
        newUser.Email = uniqueKey + '@edgeorg.com';
        newUser.EmailEncodingKey  = 'UTF-8';
        newUser.LastName = 'Test' + uniqueKey;
        newUser.FirstName = uniqueKey;
        newUser.LanguageLocaleKey  = 'en_US';
        newUser.LocaleSidKey = 'en_US';
        newUser.ProfileId = [select Id from Profile where Name =: sProfileName limit 1].Id;
        newUser.TimeZoneSidKey = 'America/Chicago';
        newUser.Username = uniqueKey + '@test' + Math.round(Math.random() * 10000) + '.com'; 
        newUser.Available_Countries__c = 'AU';
        
        
        
        return newUser; 
    }
    
    // create territory record
    public static Territory__c getTerritoryRec(){        
        Territory__c  territory = new Territory__c();
        territory.name = 'Test Territory' ;
        territory.Country__c = geoMap.get('Country'); 
        territory.Territory_Type__c = 'Auxiliary';
        territory.Status__c = 'Active';
        return territory; 
    }
    
    // create territory member record
    public static Territory_Member__c getTerrMemberRec(){
        
        User u  = runAsUser('SalesRep','Sales Representative');
        
        Territory__c terrtry =  getTerritoryRec();
        
        Territory_Member__c terrMember = new Territory_Member__c();
        terrMember.User__c = u.Id ;
        terrMember.Type__c = 'Secondary' ;
        terrMember.Territory__c  = terrtry.Id ;
        terrMember.Start_Date__c = system.today().AddDays(1);
        return terrMember;
    }
    
    //create primary territory member record
    public static Territory_Member__c getPrimaryTerrMemberRec(Id userId,Id territoryId){
        
        Territory_Member__c terrMember = new Territory_Member__c();
        terrMember.User__c = userId ;
        terrMember.Type__c = 'Primary' ;
        terrMember.Territory__c  = territoryId ;
        terrMember.Start_Date__c = system.today().AddDays(1);
        return terrMember;
    }
    
    //create secondary territory member record
    public static Territory_Member__c getSecondaryTerrMemberRec(Id userId,Id territoryId ){
        
        Territory_Member__c terrMember = new Territory_Member__c();
        terrMember.User__c = userId;
        terrMember.Type__c = 'Secondary' ;
        terrMember.Territory__c  = territoryId ;
        terrMember.Start_Date__c = system.today().AddDays(1);
        return terrMember;
    }
    
    
    public static Business_Role__c getBusinessRole(){
        Business_Role__c br = new Business_Role__c();
        br.name = 'Test Role' ;
        br.Call_Type__c='Measure and Sell';
        return br; 
        
    }
    public static User_Business_Role__c getuserBusinessRole(User u, Business_Role__c br){
        
        User_Business_Role__c ubr = new User_Business_Role__c();
        ubr.Business_Role__c= br.Id ;
        ubr.User__c=u.Id;
        return ubr; 
        
    }
    
    //Create Target List
    public static Target_List__c getTargetList(Id countryId){
        Target_List__c objTargetList = new Target_List__c();
        objTargetList.Active__c = True;
        objTargetList.Country__c = countryId;
        objTargetList.Name = 'Target List 1';
        return objTargetList;
    }
    
    //Create Target List Member
    public static Target_List_Member__c getTargetMemList(Id accountId, Id targetListId){
        Target_List_Member__c objTargetListMem = new Target_List_Member__c();
        objTargetListMem.Target_List__c = targetListId;
        objTargetListMem.Outlet__c = accountId;
        return objTargetListMem;
    }
    
    //Create Activity Target List
    public static Activity_Target_List__c getActivityTargetList(Id surveyId, Id targetListId){
        Activity_Target_List__c  atLst = new Activity_Target_List__c();
        atLst.Target_List__c = targetListId;  
        atLst.Survey__c =surveyId; 
        return atLst ;
    }
    //Create Outlet Territory
    public static Outlet_Territory__c getOutltTerritory(Id accountId, Id territoryId){
        Outlet_Territory__c outltTerri = new Outlet_Territory__c();
        outltTerri.Outlet__c = accountId;
        outltTerri.Territory__c = territoryId;
        return outltTerri;
    }
    //Create Document Record
    public static Document getDocument(String docuName){
        Document docuObj = new Document();
        docuObj.Body = Blob.valueOf('Some Text');
        docuObj.IsPublic = true;
        docuObj.Name = docuName;
        docuObj.FolderId = [SELECT Id FROM Folder WHERE Name = 'Public'].Id;
        return docuObj;    
    }
    //create Outlet Member record
    public static Outlet_Member__c getOutletMemberRecord(Id outletId,Id userId,String userRole){
        Outlet_Member__c outlerMember = new Outlet_Member__c();
        outlerMember.Outlet__c = outletId;
        outlerMember.User__c = userId;
        outlerMember.Outlet_Role__c = userRole;        
        return outlerMember;
    }  
    //create Outlet Member record
    public static Supplier_Outlet__c suppOutletRec(Id outletId, Id distributorId){
        Supplier_Outlet__c supOutltObj = new Supplier_Outlet__c();
        supOutltObj.Outlet__c = outletId;
        supOutltObj.Distributor_Wholesaler__c = distributorId;
        return supOutltObj;
    } 
    //Create call record
    public static Call__c getCallRec(Id accId){
        Call__c callObj = new Call__c();
        callObj.Account__c = accId;
        callObj.Start_Date__c = System.today();
        callObj.End_Date__c = System.now();
        callObj.Status__c = 'Completed';
        return callObj;
    }
    //Create Promotion Record
    public static Promotion__c getPromotionRecord(Id countryId){
        Promotion__c promoRec = new Promotion__c();
        promoRec.Country__c = countryId;
        promoRec.Expiration_Date__c = System.today().addDays(6);
        promoRec.Start_Date__c = System.today();
        return promoRec;
    }
    //Create Sales Organisation Record
    public static Sales_Organisation__c getsalesorgRecord(Id countryId){
        Sales_Organisation__c salesorgRec = new Sales_Organisation__c();
        salesorgRec.Country__c = countryId;
        salesorgRec.Code__c = 'SEU' ;
        salesorgRec.Description__c = 'Testing';
       
        return salesorgRec;
    }
    public static Sales_Organisation__c getsalesRecord(Id salesorgId){
        Sales_Organisation__c salesorgRec = new Sales_Organisation__c();
        salesorgRec.Id = salesorgId;
        //salesorgRec.Code__c = 'SEU' ;
       // salesorgRec.Description__c = 'Testing';
       
        return salesorgRec;
    }
    //Creates Claim Record
    public static CST_Claim__c getclaimRecord(Id countryId, Id accountId){
        CST_Claim__c claim = new CST_Claim__c();
        claim.CST_Country__c = countryId;
        claim.CurrencyIsoCode= 'GBP';
        claim.CST_Account__c= accountId;
       
        return claim;
    }
    //Creates Claim Item Record
    public static CST_Claim_Item__c getclaimItemRecord(Id claimId){
        CST_Claim_Item__c claimItem = new CST_Claim_Item__c();
        claimItem.CST_Claim__c = claimId;
        claimItem.CurrencyIsoCode='GBP';
        claimItem.CST_Net_Value__c=2000.00;
       
        return claimItem;
    }
    public static Approver_Matrix__c getApproverMatrixRecord(Id countryId){
        Approver_Matrix__c appmatrix = new Approver_Matrix__c();
        appmatrix.Name='test';
        appmatrix.Approver_User__c=UserInfo.getUserId();
        appmatrix.CurrencyIsoCode='GBP';
        appmatrix.Approval_Category__c ='Customer Spend approval';
        appmatrix.Matrix_Status__c ='Enabled';
       
        return appmatrix;
    }
    //Create ContentVersion Record
    public static ContentVersion gerConVerRec(String fileName){
        ContentVersion conVerObj = new ContentVersion();
        conVerObj.Title = 'Test Title';
        conVerObj.PathOnClient = fileName;
        conVerObj.VersionData = Blob.valueOf('Test Content');
        conVerObj.IsMajorVersion = true;
        return conVerObj;
    }
    //Create ContentDocumentLink Record
    public static ContentDocumentLink  getConDocLink (Id entityId, Id docId){
        ContentDocumentLink  conDocLnkObj = new ContentDocumentLink ();
        conDocLnkObj.LinkedEntityId = entityId;
        conDocLnkObj.ContentDocumentId = docId;
        conDocLnkObj.shareType = 'V';
        return conDocLnkObj; 
    }
    
    //Create Market Setting
    public static Market_Setting__c getMarketSetting(Id countryId){
        List<BusinessHours> bHourList = [select id from BusinessHours];
        Market_Setting__c mktSetting = new Market_Setting__c();
        mktSetting.Name = 'Market Setting';
        mktSetting.Geography__c = countryId;
        mktSetting.Business_Hours__c = bHourList[0].Id;
        mktSetting.Minimum_Product_Assortment__c = 'Binary';
        mktSetting.Minimum_Activation_Standards__c = 'Binary';
        mktSetting.Distribution__c = 'Binary';
        mktSetting.New_Product_Distribution__c = 'Progressive';
        mktSetting.Open_Opportunity__c = 'Calculative';
        mktSetting.Closed_Opportunity__c = 'Calculative';
        mktSetting.Outlet_Execution_Score__c = 'Calculative';
        mktSetting.A_P_Threshold__c=10;
        mktSetting.Prospect_Approver__c = 'Sales Manager & MDM Approval Required' ;
        mktSetting.Display_Transfer_Order_Comments__c = True;
        
        return mktSetting;
    }
    
    //Create Outlet Visit Prioritization Pickup Option
    public static Pick_Up_Options__c getPickUpOption(Id countryId, string type){
        Pick_Up_Options__c pOption = new Pick_Up_Options__c();
        pOption.Name = 'Gold[AUT]';
        pOption.Geography__c = countryId;
        pOption.Type__c = type;
        pOption.RecordTypeId = outletpriorRecTypeId;
        pOption.Days_between_visit__c = 5;
        pOption.Status__c = 'Active';
        return pOption;
    }
    
    public static Pick_Up_Options__c getRBPickUpOption(Id countryId){
        Pick_Up_Options__c pOption = new Pick_Up_Options__c();
        pOption.Name = '[EU]';
        pOption.Geography__c = countryId;
        return pOption;
    }
    
    
    //Create Outlet Visit Prioritization Pickup Option
    public static Pick_Up_Options__c getProdTypePickUpOption(Id countryId, string type){
        Pick_Up_Options__c prodtype = new Pick_Up_Options__c();
        prodtype.Name = 'Gold[AUT]';
        prodtype.Geography__c = countryId;
        prodtype.Type__c = type;
        prodtype.RecordTypeId = producttypeRecTypeId;
        prodtype.Days_between_visit__c = 5;
        prodtype.Status__c = 'Active';
        return prodtype;
    }
    
    //Create Tax Rate Pickup Option
    public static Pick_Up_Options__c getTaxPickUpOption(Id countryId, string type){
        Pick_Up_Options__c prodtype = new Pick_Up_Options__c();
        prodtype.Name = 'Tax Code[SEU]';
        prodtype.Geography__c = countryId;
        prodtype.Type__c = type;
        prodtype.Status__c = 'Active';
        return prodtype;
    }
    
    //Create Survey Record
    public static Survey__c getSurvey(Id countryId){
        Survey__c survey = new Survey__c();
        survey.Start_Date__c = System.today();
        survey.End_Date__c = System.today().addDays(10);
        survey.Country__c = countryId;
        survey.Frequency__c = 5;
        survey.Reccuring_Type__c = 'Recurring with previous response';
        survey.Priority__c = 'Medium';
        survey.Name = 'Test Survey';
        survey.Global_Equivalent_Business_Roles__c = 'Sales Rep';
        return survey;
    }
    
    //Create Outlet Survey Record
    public static Outlet_Survey__c getOutletSurvey(Id surveyId,Id accountId){
        Outlet_Survey__c otSurvey = new Outlet_Survey__c();
        otSurvey.Survey__c = surveyId;
        otSurvey.Achievement_status__c = 'In Progress';
        otSurvey.Survey_Valid_From__c = System.today();
        otSurvey.Outlet__c = accountId;
        return otSurvey;
    }
    
    //Create Survey Question Record
    public static Survey_Question__c getSurveyQuestion(Id surveyId){
        Survey_Question__c surveyQues = new Survey_Question__c();
        surveyQues.Survey__c = surveyId;
        surveyQues.Response_Type__c = 'Number' ;
        surveyQues.Question__c = 'How many days left?' ;
        surveyQues.Answer_Option__c = '10';
        surveyQues.Order_Number__c = 1;
        surveyQues.Active__c = true;
        return surveyQues;
    }
    
    //Create Outlet Survey Response Record
    public static Outlet_Survey_Response__c getOutletSurveyRes(Id otSurveyId,Id surveyQuesId){
        Outlet_Survey_Response__c otSurveyRes = new Outlet_Survey_Response__c();
        otSurveyRes.Outlet_Survey__c = otSurveyId;
        otSurveyRes.Response__c = '5';
        
        otSurveyRes.Survey_Question__c = surveyQuesId;
        return otSurveyRes;
    } 
    
    //Create Batch Job Current Region Custom Setting Records
    public static Batch_Job_Current_Region__c getBatchJobCurrentRegion(){
        Batch_Job_Current_Region__c batchJobRegion = new Batch_Job_Current_Region__c();
        batchJobRegion.Name = 'Current Region';     
        return batchJobRegion;  
    }
    
    //Create Market Cycle Record
    public static Market_Cycle__c getMarketCycle(Id countryId){
        Market_Cycle__c marCycle = new Market_Cycle__c ();
        marCycle.name='Cycle1';
        marCycle.Geography__c=countryId;
        marCycle.Start_Date__c=Date.Today().addDays(5);
        marCycle.End_Date__c=Date.Today().addDays(10);   
        return marCycle ;  
    }
    
    //Create Survey Answer Record
    public static Survey_Answer__c getSurveyAnsr(Id surveyQstnId){
        Survey_Answer__c surveyAnsrObj = new Survey_Answer__c();
        surveyAnsrObj.Option_Value__c = 'Test Sau optnVal';
        surveyAnsrObj.Survey_Question__c = surveyQstnId;
        return surveyAnsrObj;
    }
    //create Product record
    public static Product__c getProd(){
        Product__c testProd = new Product__c(Name='Johnny Walker Black Label');
        testProd.UPIID__c='12345';
        testProd.Product_Full_Name__c = 'New Product';
        testProd.Country__c =  geoMap.get('Country');
        testProd.Diageo_Cost__c = 10;
        testProd.A_P_Cost__c =10;
        testProd.POS_Related_Brand__c='JW';
        testProd.Units_per_POS__c= 10;
        testProd.Outlet_Cost__c=10;
        testProd.Pricing_Type__c = 'By Unit';
        testProd.Limit_Per_Order__c=10;
        testProd.POS_Related_Item__c='JW';
        testProd.Product_Code__c='test234';
        testProd.SAP_IO_Number__c='Sample';
        testProd.POS_Item_Short_Description__c='This is good item';
        testProd.Start_Date__c = system.today();
        return testProd; 
    }
    
    //Create Feed Item Record
    public static Feeditem getFeedItem(String body, String feedType, Id parentId){
    //public static Feeditem getFeedItem(Id feedId,string commentBody){
        FeedItem feedTest = new FeedItem();
        feedTest.Body = body;
        feedTest.ParentId = parentId;

        feedTest.Type = feedType;

        return feedTest;
    }
    
    //Create Feed Item Record
    public static Opportunity getOpportunity(Id outletId){
        Opportunity oppRec = new Opportunity();
        oppRec.Name = 'Test Opportunity';
        oppRec.AccountId = outletId;
        oppRec.StageName = 'Closed' ;
        oppRec.CloseDate = system.today();
        return oppRec;
    }
    
    //Create Feed Comment Record
    public static FeedComment getfeedComment(Id feedId){
        FeedComment feedCommentRec = new FeedComment();
        feedCommentRec.CreatedById = 'Divya Bansal';
        feedCommentRec.Id = feedId;
        feedCommentRec.CommentBody = ' Hi there' ;
        feedCommentRec.CreatedDate = system.today();
        return feedCommentRec;
    }
    
    //Create Feed Item Record
    public static Opportunity getOpportunity(Id outletId, String oppName){
        Opportunity oppRec = new Opportunity();
        oppRec.Name = oppName;
        oppRec.AccountId = outletId;
        oppRec.StageName = 'Open' ;
        oppRec.CloseDate = system.today()+10;
        return oppRec;
    }
    
    //Create Opportunity Template 
    public static Opportunity_Template__c getOpportunityTemplate(Id product, Id territory, Id country){
        Pick_Up_Options__c oultlVstPriPkUp = getPickUpOption(country, 'MAS');
        Opportunity_Template__c oppTem = new Opportunity_Template__c();
        oppTem.Cluster__c = geoMap.get('Cluster');
        oppTem.Opportunity_Type__c = 'Cycle Brief';
        OppTem.Action__c = 'TestAction';
        OppTem.Start_Date__c = System.today();
        oppTem.Closing_Method__c = 'Manual';
        OppTem.Weight_Type__c = 'Manual Value';
        //OppTem.Activation__c = 'Test Activation';
        OppTem.Activation__c = oultlVstPriPkUp.Id;
        OppTem.Product__c = product;
        OppTem.Territory__c = territory;
        //OppTem.Country__c = Country;        
        OppTem.End_Date__c = System.today()+10;        
        OppTem.Segment__c = 'Supermarket';
        OppTem.Sub_Segment__c = 'Reserve Supermarket';        
        OppTem.Channel__c = 'Off Trade';        
        return oppTem;
    }
    public static Outlet_Execution__c getOutletExecution(Id accountId){
        Id prodRecTypeId = Schema.SObjectType.Outlet_Execution__c.getRecordTypeInfosByName().get('Product').getRecordTypeId();
        Outlet_Execution__c outExeObj = new Outlet_Execution__c();
        //outExeObj.RecordTypeId =  distRecTypeId;
        outExeObj.Outlet__c = accountId;
        //outExeObj.Distribution_TRAX__c = 'Yes';
        return outExeObj;
    }
    
    public static KPI_RAG_Threshold__c getOutletKPIRAG(Id countryId){
        KPI_RAG_Threshold__c objKPIRAG = new KPI_RAG_Threshold__c();
        objKPIRAG.Country__c= countryId;
        objKPIRAG.KPI_Type__c= 'OES';
        objKPIRAG.RecordTypeId = Schema.SObjectType.KPI_RAG_Threshold__c.getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        objKPIRAG.Low_Threshold__c = 50;
        objKPIRAG.High_Threshold__c = 80;
        return objKPIRAG;
    }
    
    public static KPI_RAG_Threshold__c getTerritoryKPIRAG(Id countryId){
        KPI_RAG_Threshold__c objKPIRAG = new KPI_RAG_Threshold__c();
        objKPIRAG.Country__c= countryId;
        objKPIRAG.RecordTypeId = Schema.SObjectType.KPI_RAG_Threshold__c.getRecordTypeInfosByName().get('Territory').getRecordTypeId();
        objKPIRAG.Red_Threshold__c = 50;
        objKPIRAG.Amber_Threshold__c = 60;
        objKPIRAG.Green_Threshold__c = 80;
        return objKPIRAG;
    }
    // create Territory_Hierarchy__c
    public static Territory_Hierarchy__c getTerritoryHierarchy( Id countryId,String recType ){       
        Id recTypeId = Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get(recType).getRecordTypeId();
        Territory_Hierarchy__c territoryHierarchy = new Territory_Hierarchy__c();
        territoryHierarchy.Name = 'Australia Territory Hierarchy';
        territoryHierarchy.Geography__c = countryId;
        territoryHierarchy.RecordTypeId=recTypeId;
        return territoryHierarchy ;
    }
    //Create Account Promotion
    public static Account_Promotion__c getAccountPromotion(Id distAccount, Id promotion){
        Account_Promotion__c accPromo = new Account_Promotion__c();
        accPromo.Distributor_Owner__c = distAccount;
        accPromo.Promotion__c = promotion;
        return accPromo;
    }
    //Create Template Weighing 
    public static Template_Weighing__c getTempWeighing(Id oppTempId){
        Template_Weighing__c tempWeiObj = new Template_Weighing__c();
        tempWeiObj.Cluster__c = geoMap.get('Cluster');
        tempWeiObj.Country__c = geoMap.get('Country');
        tempWeiObj.Opportunity_Template__c = oppTempId;
        tempWeiObj.Sub_Segment__c = 'Reserve Supermarket';
        tempWeiObj.Weight__c = 10.20;
        return tempWeiObj;
    }
    
    //Create Call Type
    public static Call_Type__c getCallType(Id countryId){
        Call_Type__c objCallType = new Call_Type__c();
        objCallType.Country__c = countryId;
        objCallType.Notes_Optional__c = true;
        return objCallType;
    }
    
    //Create Category Performance
    public static Category_Performance__c getCategoryPerformance(Id countryId){
        Category_Performance__c objCategory = new Category_Performance__c();
        objCategory.Category__c = 'Beer';
        objCategory.Country__c = countryId;
        objCategory.Diageo_Share__c = 56;
        return objCategory;
    }
    
    //Create Category Performance
    public static Fascia__c getFascia(Id countryId){
        Fascia__c objFascia = new Fascia__c();
        objFascia.IsActive__c = True;
        objFascia.Country__c = countryId;
        return objFascia;
    }
    
    //Create Category Performance
    public static Field_Change_Request__c getFieldChangeRequest(Id countryId){
        Field_Change_Request__c objFieldChangeRequest = new Field_Change_Request__c();
        objFieldChangeRequest.New_Value__c = 'True';
        objFieldChangeRequest.Geography__c = countryId;
        return objFieldChangeRequest;
    }
    
    //Create Contract
    public static Contract getContract(Id accountId, Id recordTypeId){
        Contract objContract = new Contract();
        objContract.AccountId = accountId;
        objContract.Status = 'Draft';
        objContract.StartDate = System.today();
        objContract.Contract_End_Date__c = System.today()+7;
        objContract.UOS_Target__c = 45;
        objContract.UOS_AP_Rate__c = 5;
        objContract.UOS_Rebate_Rate__c = 2;
        objContract.RecordTypeId = recordTypeId;
        objContract.UOS_Earnt__c=10;
        return objContract;
    }  
    
    // create Delivery_Partner__c
    public static Delivery_Partner__c getDeliveryPartner( Id countryId){       
        
        Delivery_Partner__c deliveryPartner = new Delivery_Partner__c();
        deliveryPartner.Name = 'TestDeliveryPartner';
        deliveryPartner.DP_Id__c = 'Aus1';
        deliveryPartner.Country__c = countryId;
        deliveryPartner.Email__c = 'test@asd.com';
        deliveryPartner.Vendor_Number__c = 30;
        deliveryPartner.City__c = 'Sydney';
        deliveryPartner.Postal_Code__c = '456987';
        deliveryPartner.Street__c = 'George Street';
        return deliveryPartner ;
    }
    
    //create POS Order Group
    public static Order__c getPOSOrderGroup(String salesRepId, String accountId, String contractId){
        String posGroupId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS Order Group').getRecordTypeId();
        Order__c posOrderGroup = new Order__c();
        posOrderGroup.RecordTypeId = posGroupId;
        posOrderGroup.Account__c = accountId;
        posOrderGroup.Contract__c = contractId;
        posOrderGroup.Sales_Representative__c = salesRepId;
        posOrderGroup.Status__c = 'Draft';
        posOrderGroup.Order_Type__c = 'Warehouse';
        posOrderGroup.Delivery_Location__c = 'Outlet';
        posOrderGroup.Total_A_P_Cost__c = 20;
        return posOrderGroup;
    }
    
    //create POS Order
    public static Order__c getPOSOrder(String salesRepId, String accountId, String contractId){
        String posId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS Order').getRecordTypeId();
        Order__c posOrder = new Order__c();
        posOrder.RecordTypeId = posId;
        posOrder.Account__c = accountId;
        posOrder.Contract__c = contractId;
        posOrder.Sales_Representative__c = salesRepId;
        posOrder.Status__c = 'Draft';
        posOrder.Order_Type__c = 'Warehouse';
        posOrder.Delivery_Location__c = 'Outlet';
        posOrder.Total_A_P_Cost__c = 10;
        return posOrder;
    }
    //create Transfer Order
    public static Order__c getTrnsfrOrder(String salesRepId, String accountId, String wholeSlrId){
        String trnsfrId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Transfer Order').getRecordTypeId();
        Order__c trnsfrOrder = new Order__c();
        trnsfrOrder.RecordTypeId = trnsfrId;
        trnsfrOrder.Account__c = accountId;
        trnsfrOrder.Sales_Representative__c = salesRepId;
        trnsfrOrder.Status__c = 'Draft';
        trnsfrOrder.Wholesaler__c = wholeSlrId;
        trnsfrOrder.Comments__c = 'hello';
        return trnsfrOrder; 
    } 
    //create Stock Movement Order Group
    public static Order__c getStockMovementOrderGroup(String salesRepId, String accountId){
        String stockMovementGroupId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Stock Movement Group').getRecordTypeId();
        Order__c stockMovementGroup = new Order__c();
        stockMovementGroup.RecordTypeId = stockMovementGroupId;
        stockMovementGroup.Account__c = accountId;
        stockMovementGroup.Sales_Representative__c = salesRepId;
        stockMovementGroup.Status__c = 'Draft';
        stockMovementGroup.Order_Type__c = 'Shed';
        stockMovementGroup.Delivery_Location__c = 'Shed';
        stockMovementGroup.Total_A_P_Cost__c = 20;
        return stockMovementGroup;
    }
    
    //create Stock Movement Order
    public static Order__c getStockMovementOrder(String salesRepId, String accountId){
        String stockMovementId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Stock Movement').getRecordTypeId();
        Order__c stockMovement = new Order__c();
        stockMovement.RecordTypeId = stockMovementId;
        stockMovement.Account__c = accountId;
        stockMovement.Sales_Representative__c = salesRepId;
        stockMovement.Status__c = 'Draft';
        stockMovement.Order_Type__c = 'Shed';
        stockMovement.Delivery_Location__c = 'Shed';
        stockMovement.Total_A_P_Cost__c = 10;
        return stockMovement;
    }
    
    //Create Order Line Item
    public static Order_Item__c getOrderItem(String productId, String orderId){
        Order_Item__c orderItem = new Order_Item__c();
        orderItem.Order__c = orderId;
        orderItem.Product__c = productId;
        orderItem.Quantity__c = 6;
        orderItem.Type__c = 'Warehouse';
        return orderItem;
    }
    
    //Create Stock
    public static Stock__c getStock(String countryId, String productId, String salesRepId){
        Stock__c objStock = new Stock__c();
        objStock.Country__c = countryId;
        objStock.Product__c = productId;
        objStock.Sales_Rep__c = salesRepId;
        objStock.Original_Stock__c = 100;
        objStock.Consumed_Stock__c = 15;
        objStock.Type__c = 'State';
        objStock.State__c = geoMap.get('State');
        objStock.Allocated__c = 18;
        objStock.Unique_Key__c = 'p8uf5';
        return objStock;
    }
    
    //Create Stock
    public static Stock__c getAllocationStock(String countryId, String productId, String salesRepId, String territoryId){
        Stock__c objStock = new Stock__c();
        objStock.Country__c = countryId;
        objStock.Product__c = productId;
        objStock.Sales_Rep__c = salesRepId;
        objStock.Original_Stock__c = 100;
        objStock.Consumed_Stock__c = 15;
        objStock.Type__c = 'Territory/Rep';
        objStock.Territory__c = territoryId;
        objStock.Allocated__c = 18;
        objStock.Unique_Key__c = 'pa8uf5';
        return objStock;
    }
    //Create Bespoke
    public static Bespoke__c getBespoke (String countryId, String objContractId, String salesRepId, String outletId, String deliveryPartnerId, String pOptionId ){
        Bespoke__c objBespoke = new Bespoke__c();
        objBespoke.Account__c = outletId;
        objBespoke.Activity_Objectives__c = pOptionId;
        objBespoke.Contract__c = objContractId;
        objBespoke.Country__c = countryId;
        objBespoke.Sales_Rep__c = salesRepId;
        objBespoke.Delivery_Partner__c = deliveryPartnerId;
        return objBespoke;
    }
   
    //Create Coaching Report
    public static Coaching_Report__c getCoachingReport(Id countryId, Id surveyId){
        Coaching_Report__c coachingReport = new Coaching_Report__c();
        coachingReport.Country__c = countryId;
        coachingReport.Survey__c = surveyId;
        coachingReport.Status__c = 'Draft';
        return coachingReport;
    }
    
    //Create Coaching Survey
    public static Coaching_Survey__c getCoachingSurvey(Id coachingReport, Id surveyId, Id outletId){
        Coaching_Survey__c coachingSurvey = new Coaching_Survey__c();
        coachingSurvey.Coaching_Report__c = coachingReport;
        coachingSurvey.Survey__c = surveyId;
        coachingSurvey.Outlet__c = outletId;
        coachingSurvey.Status__c = 'Draft';
        return coachingSurvey;        
    }
    
    //Create Coaching Survey Response
    public static Coaching_Survey_Response__c getCoachingSurveyResponse(Id coachingSurvey, Id surveyQuestion){
        Coaching_Survey_Response__c coachingSurveyRsp = new Coaching_Survey_Response__c();
        coachingSurveyRsp.Coaching_Survey__c = coachingSurvey;
        coachingSurveyRsp.Survey_Question__c = surveyQuestion;
        coachingSurveyRsp.Response__c = '2';
        coachingSurveyRsp.Comment__c = 'Test';
        return coachingSurveyRsp;        
    } 
    public static Id setupCountryGB(string countryCode){
        Geography__c globalRec = EDGE_UtilityTestClass.createGeography('Global');
        globalRec.Name = 'Global3';
        globalRec.Code__c = 'GL3';
        globalRec.RecordTypeId=EDGE_UtilityTestClass.GlobalRecTypeId;
        insert globalRec;
        geoMap.put('Global3',globalRec.Id);
        
        Geography__c market = EDGE_UtilityTestClass.createGeography('Market');
        market.Name = 'Europe and Turkey';
        market.Code__c = 'EU';
        market.Parent_Geography__c = globalRec.Id;
        market.RecordTypeId=EDGE_UtilityTestClass.marketRecTypeId;
        insert market;
        //marketMap.put('Market',market.Id);
        geoMap.put('Market',market.Id);
        
        Geography__c hub = EDGE_UtilityTestClass.createGeography('Hub');
        hub.Name = 'Great Britain';
        hub.Code__c = 'GBH';
        hub.Parent_Geography__c = market.Id;
        hub.RecordTypeId=EDGE_UtilityTestClass.HubRecTypeId;
        insert hub;
        geoMap.put('Hub',hub.Id);
        
        
        Geography__c cluster = EDGE_UtilityTestClass.createGeography('Cluster');
        cluster.Name = 'Great Britain';
        cluster.Code__c = 'GBC';
        cluster.Parent_Geography__c = hub.Id;
        cluster.RecordTypeId=EDGE_UtilityTestClass.ClusterRecTypeId;
        insert cluster;
        geoMap.put('Cluster',cluster.Id);
        
        Geography__c country = EDGE_UtilityTestClass.createGeography('Country');
        country.Name = 'Great Britain';
        country.Code__c = countryCode;
        country.Parent_Geography__c = cluster.Id;
        country.RecordTypeId=EDGE_UtilityTestClass.CountryRecTypeId;
        insert country;
        geoMap.put('Country',country.Id);
        
        
        Geography__c area = EDGE_UtilityTestClass.createGeography('Area');
        area.Name = 'Great Britain';
        area.Code__c = 'GBA';
        area.Parent_Geography__c = country.Id;
        area.RecordTypeId=EDGE_UtilityTestClass.AreaRecTypeId;
        insert area;
        geoMap.put('Area',area.Id);        
        
        Geography__c region = EDGE_UtilityTestClass.createGeography('Region');
        region.Name = 'Central';
        region.Code__c = 'GB05';
        region.Parent_Geography__c = area.Id;
        region.RecordTypeId=EDGE_UtilityTestClass.RegionRecTypeId;
        insert region;
        geoMap.put('Region',region.Id);
        
        /*Geography__c state = EDGE_UtilityTestClass.createGeography('State');
        state.Name = 'Tasmania1';
        state.Code__c = 'SES';
        state.Parent_Geography__c = country.Id;
        state.RecordTypeId=EDGE_UtilityTestClass.stateRecTypeId;
        insert state;
        geoMap.put('State',state.Id);*/
        
        return country.Id;        
    }
    
    
    public static Id setupCountrySpain(string countryCode){
        Geography__c globalRec = EDGE_UtilityTestClass.createGeography('Global');
        globalRec.Name = 'Global1';
        globalRec.Code__c = 'GL1';
        globalRec.RecordTypeId=EDGE_UtilityTestClass.GlobalRecTypeId;
        insert globalRec;
        geoMap.put('Global1',globalRec.Id);
        
        Geography__c market = EDGE_UtilityTestClass.createGeography('Market');
        market.Name = 'Asiapac';
        market.Code__c = 'EPAT';
        market.Parent_Geography__c = globalRec.Id;
        market.RecordTypeId=EDGE_UtilityTestClass.marketRecTypeId;
        insert market;
        //marketMap.put('Market',market.Id);
        geoMap.put('Market',market.Id);
        
        Geography__c hub = EDGE_UtilityTestClass.createGeography('Hub');
        hub.Name = 'Spain Hub';
        hub.Code__c = 'ESHT';
        hub.Parent_Geography__c = market.Id;
        hub.RecordTypeId=EDGE_UtilityTestClass.HubRecTypeId;
        insert hub;
        geoMap.put('Hub',hub.Id);
        
        
        Geography__c cluster = EDGE_UtilityTestClass.createGeography('Cluster');
        cluster.Name = 'Spain Cluster';
        cluster.Code__c = 'ESCT';
        cluster.Parent_Geography__c = hub.Id;
        cluster.RecordTypeId=EDGE_UtilityTestClass.ClusterRecTypeId;
        insert cluster;
        geoMap.put('Cluster',cluster.Id);
        
        Geography__c country = EDGE_UtilityTestClass.createGeography('Country');
        country.Name = 'Spain';
        country.Code__c = countryCode;
        country.Parent_Geography__c = cluster.Id;
        country.RecordTypeId=EDGE_UtilityTestClass.CountryRecTypeId;
        insert country;
        geoMap.put('Country',country.Id);
        
        
        Geography__c area = EDGE_UtilityTestClass.createGeography('Area');
        area.Name = 'Spain Mindland';
        area.Code__c = 'SES1';
        area.Parent_Geography__c = country.Id;
        area.RecordTypeId=EDGE_UtilityTestClass.AreaRecTypeId;
        insert area;
        geoMap.put('Area',area.Id);        
        
        Geography__c region = EDGE_UtilityTestClass.createGeography('Region');
        region.Name = 'Spain';
        region.Code__c = 'SES2';
        region.Parent_Geography__c = area.Id;
        region.RecordTypeId=EDGE_UtilityTestClass.RegionRecTypeId;
        insert region;
        geoMap.put('Region',region.Id);
        
        Geography__c state = EDGE_UtilityTestClass.createGeography('State');
        state.Name = 'Tasmania1';
        state.Code__c = 'SES';
        state.Parent_Geography__c = country.Id;
        state.RecordTypeId=EDGE_UtilityTestClass.stateRecTypeId;
        insert state;
        geoMap.put('State',state.Id);
        
        return country.Id;        
    }
    
    public static Id setupCountryCO(string countryCode){
        Geography__c globalRec = EDGE_UtilityTestClass.createGeography('Global');
        globalRec.Name = 'Global2';
        globalRec.Code__c = 'GL2';
        globalRec.RecordTypeId=EDGE_UtilityTestClass.GlobalRecTypeId;
        insert globalRec;
        geoMap.put('Global2',globalRec.Id);
        
        Geography__c market = EDGE_UtilityTestClass.createGeography('Market');
        market.Name = 'Latam-Car';
        market.Code__c = 'LATA';
        market.Parent_Geography__c = globalRec.Id;
        market.RecordTypeId=EDGE_UtilityTestClass.marketRecTypeId;
        insert market;
        geoMap.put('Market',market.Id);
        
        Geography__c hub = EDGE_UtilityTestClass.createGeography('Hub');
        hub.Name = 'Colombia';
        hub.Code__c = 'COH';
        hub.Parent_Geography__c = market.Id;
        hub.RecordTypeId=EDGE_UtilityTestClass.HubRecTypeId;
        insert hub;
        geoMap.put('Hub',hub.Id);
        
        
        Geography__c cluster = EDGE_UtilityTestClass.createGeography('Cluster');
        cluster.Name = 'Colombia';
        cluster.Code__c = 'COE';
        cluster.Parent_Geography__c = hub.Id;
        cluster.RecordTypeId=EDGE_UtilityTestClass.ClusterRecTypeId;
        insert cluster;
        geoMap.put('Cluster',cluster.Id);
        
        Geography__c country = EDGE_UtilityTestClass.createGeography('Country');
        country.Name = 'Colombia';
        country.Code__c = countryCode;
        country.Extended_Country_Code__c = 'CO-COT';
        country.Parent_Geography__c = cluster.Id;
        country.RecordTypeId=EDGE_UtilityTestClass.CountryRecTypeId;
        insert country;
        geoMap.put('Country',country.Id);
        
        
        Geography__c area = EDGE_UtilityTestClass.createGeography('Area');
        area.Name = 'Colombia';
        area.Code__c = 'COL';
        area.Parent_Geography__c = country.Id;
        area.RecordTypeId=EDGE_UtilityTestClass.AreaRecTypeId;
        insert area;
        geoMap.put('Area',area.Id);        
        
        Geography__c region = EDGE_UtilityTestClass.createGeography('Region');
        region.Name = 'Caribbean';
        region.Code__c = 'CO07';
        region.Parent_Geography__c = area.Id;
        region.RecordTypeId=EDGE_UtilityTestClass.RegionRecTypeId;
        insert region;
        geoMap.put('Region',region.Id);
        
        return country.Id;        
    }

    public static Id setupCountryPL(string countryCode){
        Geography__c globalRec = EDGE_UtilityTestClass.createGeography('Global');
        globalRec.Name = 'Global2';
        globalRec.Code__c = 'GL2';
        globalRec.RecordTypeId=EDGE_UtilityTestClass.GlobalRecTypeId;
        insert globalRec;
        geoMap.put('Global2',globalRec.Id);
        
        Geography__c market = EDGE_UtilityTestClass.createGeography('Market');
        market.Name = 'Europe and Turkey';
        market.Code__c = 'EU';
        market.Parent_Geography__c = globalRec.Id;
        market.RecordTypeId=EDGE_UtilityTestClass.marketRecTypeId;
        insert market;
        geoMap.put('Market',market.Id);
        
        Geography__c hub = EDGE_UtilityTestClass.createGeography('Hub');
        hub.Name = 'Continental Europe';
        hub.Code__c = 'CE';
        hub.Parent_Geography__c = market.Id;
        hub.RecordTypeId=EDGE_UtilityTestClass.HubRecTypeId;
        insert hub;
        geoMap.put('Hub',hub.Id);
        
        
        Geography__c cluster = EDGE_UtilityTestClass.createGeography('Cluster');
        cluster.Name = 'Central Europe';
        cluster.Code__c = 'CEE';
        cluster.Parent_Geography__c = hub.Id;
        cluster.RecordTypeId=EDGE_UtilityTestClass.ClusterRecTypeId;
        insert cluster;
        geoMap.put('Cluster',cluster.Id);
        
        Geography__c country = EDGE_UtilityTestClass.createGeography('Country');
        country.Name = 'Poland';
        country.Code__c = countryCode;
        country.Parent_Geography__c = cluster.Id;
        country.RecordTypeId=EDGE_UtilityTestClass.CountryRecTypeId;
        country.Extended_Country_Code__c = 'PL-PLX';
        insert country;
        geoMap.put('Country',country.Id);
        
        
        Geography__c area = EDGE_UtilityTestClass.createGeography('Area');
        area.Name = 'Poland';
        area.Code__c = 'PLA';
        area.Parent_Geography__c = country.Id;
        area.RecordTypeId=EDGE_UtilityTestClass.AreaRecTypeId;
        insert area;
        geoMap.put('Area',area.Id);        
        
        Geography__c region = EDGE_UtilityTestClass.createGeography('Region');
        region.Name = 'DOLNOŚLĄSKIE';
        region.Code__c = 'PL02';
        region.Parent_Geography__c = area.Id;
        region.RecordTypeId=EDGE_UtilityTestClass.RegionRecTypeId;
        insert region;
        geoMap.put('Region',region.Id);
        
        /*Geography__c state = EDGE_UtilityTestClass.createGeography('State');
        state.Name = 'Tasmania1';
        state.Code__c = 'SES';
        state.Parent_Geography__c = country.Id;
        state.RecordTypeId=EDGE_UtilityTestClass.stateRecTypeId;
        insert state;
        geoMap.put('State',state.Id);*/
        
        return country.Id;        
    }
    public static Id setupHubGT(string countryCode){
        
		Geography__c globalRec = EDGE_UtilityTestClass.createGeography('Global');
        globalRec.Name = 'Global3';
        globalRec.Code__c = 'GL3';
        globalRec.RecordTypeId=EDGE_UtilityTestClass.GlobalRecTypeId;
        insert globalRec;
        geoMap.put('Global3',globalRec.Id);
        
        Geography__c market = EDGE_UtilityTestClass.createGeography('Market');
        market.Name = 'Asiapac';
        market.Code__c = 'EPGT';
        market.Parent_Geography__c = globalRec.Id;
        market.RecordTypeId=EDGE_UtilityTestClass.marketRecTypeId;
        insert market;
        //marketMap.put('Market',market.Id);
        geoMap.put('Market',market.Id);
        
        Geography__c hub = EDGE_UtilityTestClass.createGeography('Hub');
        hub.Name = 'Global Travel';
        hub.Code__c = countryCode;
        hub.Parent_Geography__c = market.Id;
        hub.RecordTypeId=EDGE_UtilityTestClass.HubRecTypeId;
        insert hub;
        geoMap.put('Hub',hub.Id); 
        
        Geography__c cluster = EDGE_UtilityTestClass.createGeography('Cluster');
        cluster.Name = 'Global Travel Cluster';
        cluster.Code__c = 'GTC';
        cluster.Parent_Geography__c = hub.Id;
        cluster.RecordTypeId=EDGE_UtilityTestClass.ClusterRecTypeId;
        insert cluster;
        geoMap.put('Cluster',cluster.Id);
        
        Geography__c country = EDGE_UtilityTestClass.createGeography('Country');
        country.Name = 'Global Travel Country';
        country.Code__c = 'GTCC';
        country.Parent_Geography__c = cluster.Id;
        country.RecordTypeId=EDGE_UtilityTestClass.CountryRecTypeId;
        insert country;
        geoMap.put('Country',country.Id);
        
        Geography__c area = EDGE_UtilityTestClass.createGeography('Area');
        area.Name = 'Global Travel Area';
        area.Code__c = 'GTA';
        area.Parent_Geography__c = country.Id;
        area.RecordTypeId=EDGE_UtilityTestClass.AreaRecTypeId;
        insert area;
        geoMap.put('Area',area.Id);        
        
        Geography__c region = EDGE_UtilityTestClass.createGeography('Region');
        region.Name = 'Global Travel Region';
        region.Code__c = 'GTR';
        region.Parent_Geography__c = area.Id;
        region.RecordTypeId=EDGE_UtilityTestClass.RegionRecTypeId;
        insert region;
        geoMap.put('Region',region.Id);
        
        return hub.Id;
    }
    
    //Create Coaching Survey Response
    public static maps__Location__c getMapLocation(User Usr){
        maps__Location__c mpsLocation = new maps__Location__c();
        mpsLocation.maps__Longitude__c =11.0;
        mpsLocation.maps__Latitude__c =20.0;
        mpsLocation.maps__User__c = Usr.Id;
        
        return mpsLocation;
    } 
    
    //Create Contact
    public Static Contact getContact(Id outletId){
        Contact contact = new Contact();
        contact.FirstName = 'test';
        contact.LastName = 'Contact';
        contact.AccountId = outletId;
        contact.Email = 'test.test@gmail.com';
        
        return contact;
    }
    
     // create Promotion record
    public static Promotion_Master__c  getPromotionMasterRec(String recordId){
        Promotion_Master__c  promo = new Promotion_Master__c ();
        promo.Country__c = geoMap.get('Country'); 
        promo.Start_Date__c = System.today();
        promo.End_Date__c  = System.today()+7;
        promo.Description__c = 'Test Promotion Description';
        promo.RecordTypeId = recordId;
        return promo; 
    }
   
    // create Outlet Promotion record
    public static Outlet_Promotion__c  getOutletPromotionRec(String promoId,String outletId,Integer used,Integer promolimit){
        Outlet_Promotion__c  outpromo = new Outlet_Promotion__c ();
       	outpromo.Outlet__c = outletId;
        outpromo.Promotion__c  = promoId;
        outpromo.Promotion_Limit__c  = promolimit;
        outpromo.Promotion_Used__c  = used;
        outpromo.Status__c = 'Active';
        return outpromo; 
    }
    // create Territory Promotion record
    public static Territory_Promotion__c  getTerritoryPromotionRec(String promoId,String terrId,Integer used,Integer promolimit){
        Territory_Promotion__c  terrpromo = new Territory_Promotion__c ();
       	terrpromo.Territory__c = terrId;
        terrpromo.Promotion__c  = promoId;
        terrpromo.Promotion_Limit__c  = promolimit;
        terrpromo.Promotion_Used__c  = used;
        terrpromo.Status__c = 'Active';
        return terrpromo; 
    }
    
}