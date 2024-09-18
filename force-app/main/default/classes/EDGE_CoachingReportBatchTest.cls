/**
* @Name: EDGE_CoachingReportBatchTest

* @Purpose: This is the test class for EDGE_CoachingReportBatch

* @History:                                                            
                                                           
* @VERSION		AUTHOR			DATE		     DETAIL
*   1.0		 Preyanka Ghosh	  23/09/2019	Initial Development
*   1.1	     Debolina/Mayukh  13/06/2022    ES20-12774 - To resolve Alignment Issue For Japan Coaching form_SFDC_Tech Debt
**/
@isTest
public class EDGE_CoachingReportBatchTest {
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
    /**
    * @Method  : contractStatusUpdate
    * @Purpose : To cover EDGE_ContractStatusUpdateBatch class
    **/
    @isTest
    public static void coachingReportUpdate(){
        Test.startTest(); 
        createData();
        Test.stopTest();	
        try{ 
            Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                      Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_CoachingReportBatch'
                                                      and Country_Code__c ='AU' ];            
            System.assert(batchSetting.Id !=null,'batch setting Id should not be null');
            
            String className = batchSetting.Batch_Class__c;
            Type t = Type.forName(className);
            BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
            job.getBatchDetails(batchSetting);
            Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
        }catch(Exception ex){
            System.debug(LoggingLevel.Debug,'Error '+ex.getcause());
        }
        
        
    }
    
    @isTest
    public static void coachingVF(){
        Test.startTest(); 
        createData();
        Coaching_Report__c coachingReport = [SELECT Id FROM Coaching_Report__c LIMIT 1];
        system.assert(coachingReport.Id != null,'coaching Report Id should not be null');
        
        PageReference pageRef = Page.EDGE_CoachingReportPDF;
        Test.setCurrentPage(pageRef);
        
        ApexPages.currentPage().getParameters().put('id',coachingReport.Id);
        ApexPages.currentPage().getParameters().put('isUpdate','Yes');
        
        EDGE_CoachingReportPDFController controller;
        controller = new EDGE_CoachingReportPDFController();
        Test.stopTest();
    }
    
    @isTest
    public static void coachingVF2(){
        Test.startTest(); 
        createData2();
        Coaching_Report__c coachingReport = [SELECT Id FROM Coaching_Report__c LIMIT 1];
        system.assert(coachingReport.Id != null,'coaching Report Id should not be null');
        
        PageReference pageRef = Page.EDGE_CoachingReportPDF;
        Test.setCurrentPage(pageRef);
        
        ApexPages.currentPage().getParameters().put('id',coachingReport.Id);
        ApexPages.currentPage().getParameters().put('isUpdate','Yes');
        
        EDGE_CoachingReportPDFController controller;
        controller = new EDGE_CoachingReportPDFController();
        Test.stopTest();
    }
    
    @isTest
    public static void coachingVFService(){
        Test.startTest(); 
        createData();
        Coaching_Report__c coachingReport = [SELECT Id FROM Coaching_Report__c LIMIT 1];
        system.assert(coachingReport.Id != null,'coaching Report Id should not be null');
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        String requri='services/apexrest/CoachingFormService?coachingReportId=';
        
        req.requestUri =requri;
        req.params.put('coachingReportId', coachingReport.Id);        
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        EDGE_CoachingFormService.doGet();
        Test.stopTest();
    }
    
    /**
    * @Method  : createData
    * @Purpose : To create test data
    **/   
    static void createData(){
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AU]';
        insert pickupOption;
        
        User salesManager = EDGE_UtilityTestClass.runAsUser('salesRep1','Sales Manager');
        salesManager.Available_Countries__c = 'AU';
        salesManager.Email = 'abc@test.com';
        insert salesManager;  
        System.assert(salesManager.Id!=null,'sales Manager Id should not be null');
        
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
        salesRep.Available_Countries__c = 'AU';
        salesRep.Email = 'jaghasg@test.com';
        salesRep.ManagerId = salesManager.id;
        insert salesRep; 
        
        EDGE_UtilityTestClass.createOrgSettings();
        Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount.Outlet_Visit_Prioritisation_Grade__c = pickupOption.Id; 
        outletAccount.BillingCountry = 'Australia';
        outletAccount.BillingCountryCode = 'AU';
        outletAccount.BillingState = 'New South Wales';
        outletAccount.Person_Responsible__c = UserInfo.getUserId();
        outletAccount.Country__c = countryId;
        outletAccount.Independent_of_Operator__c = true;
        outletAccount.Independent_of_Owner__c = true;
        outletAccount.ShippingCountry = 'Australia';
        outletAccount.ShippingCountryCode = 'AU';
        outletAccount.ShippingState = 'New South Wales';
        insert outletAccount;
        
        
        Id coachingSurveyId = Survey__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Coaching survey').getRecordTypeId();  
        Survey__c survey = EDGE_UtilityTestClass.getSurvey(countryId);
        survey.RecordTypeId = coachingSurveyId;
        insert survey;
        
        List<Survey_Question__c> lstSurveyQus = new List<Survey_Question__c>();
        Survey_Question__c surveyQuestion = EDGE_UtilityTestClass.getSurveyQuestion(survey.Id);
        surveyQuestion.Response_Type__c = 'Number';
        surveyQuestion.Grouping_1__c = 'INTRO';
        surveyQuestion.Grouping_2__c = 'START OF DAY';
        lstSurveyQus.add(surveyQuestion);
        
        Survey_Question__c surveyQuestion1 = EDGE_UtilityTestClass.getSurveyQuestion(survey.Id);
        surveyQuestion1.Response_Type__c = 'Number';
        surveyQuestion1.Grouping_1__c = 'PLAN';
        surveyQuestion1.Grouping_2__c = 'Plan how to achieve';
        surveyQuestion1.Order_Number__c = 1;
        surveyQuestion1.Grouping1_Sequence_Number__c = 1;
        surveyQuestion1.Grouping2_Sequence_Number__c = 1;
        lstSurveyQus.add(surveyQuestion1);
        
        Survey_Question__c surveyQuestion2 = EDGE_UtilityTestClass.getSurveyQuestion(survey.Id);
        surveyQuestion2.Response_Type__c = 'Number';
        surveyQuestion2.Grouping_1__c = 'PLAN';
        surveyQuestion2.Grouping_2__c = 'Understand the market';
        surveyQuestion2.Order_Number__c = 2;
        surveyQuestion2.Grouping1_Sequence_Number__c = 2;
        surveyQuestion2.Grouping2_Sequence_Number__c = 2;
        
        Survey_Question__c surveyQuestion3 = EDGE_UtilityTestClass.getSurveyQuestion(survey.Id);
        surveyQuestion3.Response_Type__c = 'Number';
        surveyQuestion3.Grouping_1__c = 'PLAN';
        surveyQuestion3.Grouping_2__c = 'Understand the market';
        surveyQuestion3.Order_Number__c = 3;
        surveyQuestion3.Grouping1_Sequence_Number__c = 2;
        surveyQuestion3.Grouping2_Sequence_Number__c = 2;

        lstSurveyQus.add(surveyQuestion3);
        
        insert lstSurveyQus;
        
        List<EDGE_SurveyQuestionWrapper> listWrapper = new List<EDGE_SurveyQuestionWrapper>();
        EDGE_SurveyQuestionWrapper sqWrapper1 = new EDGE_SurveyQuestionWrapper(surveyQuestion1);
        EDGE_SurveyQuestionWrapper sqWrapper2 = new EDGE_SurveyQuestionWrapper(surveyQuestion2);
        listWrapper.add(sqWrapper1);
        listWrapper.add(sqWrapper2);
        listWrapper.sort();
        
        List<EDGE_SurveyQuestionGrpWrapper> listGrpWrapper = new List<EDGE_SurveyQuestionGrpWrapper>();
        EDGE_SurveyQuestionGrpWrapper sqGrpWrapper1 = new EDGE_SurveyQuestionGrpWrapper(surveyQuestion1);
        EDGE_SurveyQuestionGrpWrapper sqGrpWrapper2 = new EDGE_SurveyQuestionGrpWrapper(surveyQuestion2);
        listGrpWrapper.add(sqGrpWrapper1);
        listGrpWrapper.add(sqGrpWrapper2);
        listGrpWrapper.sort();
        
        List<EDGE_SurveyQuestionFirstGrpWrapper> listFrstGrpWrapper = new List<EDGE_SurveyQuestionFirstGrpWrapper>();
        EDGE_SurveyQuestionFirstGrpWrapper sqFrstGrpWrapper1 = new EDGE_SurveyQuestionFirstGrpWrapper(surveyQuestion1.Grouping_1__c, surveyQuestion1.Grouping1_Sequence_Number__c+'');
        EDGE_SurveyQuestionFirstGrpWrapper sqFrstGrpWrapper2 = new EDGE_SurveyQuestionFirstGrpWrapper(surveyQuestion2.Grouping_1__c, surveyQuestion2.Grouping1_Sequence_Number__c+'');
        listFrstGrpWrapper.add(sqFrstGrpWrapper1);
        listFrstGrpWrapper.add(sqFrstGrpWrapper2);
        listFrstGrpWrapper.sort();
        
        
        Date yesterdayDate = (Date.today()).addDays(-1);
        Coaching_Report__c coachingReport = EDGE_UtilityTestClass.getCoachingReport(countryId,survey.Id);
        coachingReport.Report_Date__c = yesterdayDate;
        coachingReport.Sales_Representative__c = salesRep.Id;
        coachingReport.Current_Sales_Manager__c = salesManager.Id;
        insert coachingReport;
        
        Coaching_Survey__c coachingSurvey = EDGE_UtilityTestClass.getCoachingSurvey(coachingReport.Id, survey.Id, outletAccount.id);
        coachingSurvey.Next_Coaching_Objectives__c = 'Tested';
        insert coachingSurvey;
        
        List<Coaching_Survey_Response__c> lstCochingRes = new List<Coaching_Survey_Response__c>();
        for(Survey_Question__c surveyQus : lstSurveyQus){
            Coaching_Survey_Response__c coachingSurveyRsp = EDGE_UtilityTestClass.getCoachingSurveyResponse(coachingSurvey.Id, surveyQus.Id);
            lstCochingRes.add(coachingSurveyRsp);
        }
        insert lstCochingRes;
        
    }
    
    static void createData2(){
        Map <String,Schema.RecordTypeInfo> mapGeographyRecordTypes;
        mapGeographyRecordTypes = Geography__c.sObjectType.getDescribe().getRecordTypeInfosByName();
        Id countryId = EDGE_UtilityTestClass.setupCountry('JP');
        Map<String,Id> geoMap = EDGE_UtilityTestClass.getGeoMap();
        countryId = geoMap.get('Country');
        Geography__c area = EDGE_UtilityTestClass.createGeography('Area');
        area.Name = 'Japan1';
        area.Code__c = 'JAP1';
        area.Parent_Geography__c = countryId;
        area.RecordTypeId=areaRecTypeId;
        insert area;
        
        List<Pick_Up_Options__c> pck = new List<Pick_Up_Options__c>();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[JP]';
        pck.add(pickupOption);
        
        insert pck;
        
        List<User> usrlst = new List<User>();
        
        User salesManager = EDGE_UtilityTestClass.runAsUser('salesRepJP','Sales Manager');
        salesManager.Available_Countries__c = 'JP';
        salesManager.Email = 'abcJP@test.com';
        usrlst.add(salesManager);
        
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep3TW','Sales Representative');
        salesRep.Available_Countries__c = 'JP';
        salesRep.Email = 'jaghasgJP@test.com';
        salesRep.ManagerId = salesManager.id;
        usrlst.add(salesRep);
        
        insert usrlst; 
        
        EDGE_UtilityTestClass.createOrgSettings();
        List<Account> acclst = new List<Account>();
        
        Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount.Outlet_Visit_Prioritisation_Grade__c = pickupOption.Id; 
        outletAccount.BillingCountry = 'Japan';
        outletAccount.BillingCountryCode = 'JP';
        outletAccount.BillingState = '';
        outletAccount.Person_Responsible__c = UserInfo.getUserId();
        outletAccount.Country__c = countryId;
        outletAccount.Independent_of_Operator__c = true;
        outletAccount.Independent_of_Owner__c = true;
        outletAccount.ShippingCountry = 'Japan';
        outletAccount.ShippingCountryCode = 'JP';
        outletAccount.ShippingState = '';
        outletAccount.Area__c = geoMap.get('Area');
        outletAccount.Region__c = geoMap.get('Region');
        outletAccount.Cluster__c = geoMap.get('Cluster');
        outletAccount.Hub__c = geoMap.get('Hub');
        outletAccount.Market__c = geoMap.get('Market');
        acclst.add(outletAccount);
        
        insert acclst;
        
        List<Survey__c> survLst = new List<Survey__c>();
        Id coachingSurveyId = Survey__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Coaching survey').getRecordTypeId();  
        Survey__c survey = EDGE_UtilityTestClass.getSurvey(countryId);
        survey.RecordTypeId = coachingSurveyId;
        survLst.add(survey);
        insert survLst;
        
        List<Survey_Question__c> lstSurveyQus = new List<Survey_Question__c>();
        
        Survey_Question__c surveyQuestion = EDGE_UtilityTestClass.getSurveyQuestion(survey.Id);
        
        surveyQuestion.Response_Type__c = 'Number';
        surveyQuestion.Grouping_1__c = 'INTRO';
        surveyQuestion.Grouping_2__c = 'START OF DAY';
        lstSurveyQus.add(surveyQuestion);
        
        Survey_Question__c surveyQuestion1 = EDGE_UtilityTestClass.getSurveyQuestion(survey.Id);
        surveyQuestion1.Response_Type__c = 'Number';
        surveyQuestion1.Grouping_1__c = 'PLAN';
        surveyQuestion1.Grouping_2__c = 'Plan how to achieve';
        surveyQuestion1.Order_Number__c = 1;
        surveyQuestion1.Grouping1_Sequence_Number__c = 1;
        surveyQuestion1.Grouping2_Sequence_Number__c = 1;
        lstSurveyQus.add(surveyQuestion1);
        
        Survey_Question__c surveyQuestion2 = EDGE_UtilityTestClass.getSurveyQuestion(survey.Id);
        surveyQuestion2.Response_Type__c = 'Number';
        surveyQuestion2.Grouping_1__c = 'PLAN';
        surveyQuestion2.Grouping_2__c = 'Understand the market';
        surveyQuestion2.Order_Number__c = 2;
        surveyQuestion2.Grouping1_Sequence_Number__c = 2;
        surveyQuestion2.Grouping2_Sequence_Number__c = 2;
        lstSurveyQus.add(surveyQuestion2);
        
        Survey_Question__c surveyQuestion3 = EDGE_UtilityTestClass.getSurveyQuestion(survey.Id);
        surveyQuestion3.Response_Type__c = 'Number';
        surveyQuestion3.Grouping_1__c = 'PLAN';
        surveyQuestion3.Grouping_2__c = 'Understand the market';
        surveyQuestion3.Order_Number__c = 3;
        surveyQuestion3.Grouping1_Sequence_Number__c = 2;
        surveyQuestion3.Grouping2_Sequence_Number__c = 2;
        lstSurveyQus.add(surveyQuestion3);
        
        insert lstSurveyQus;
        
        List<EDGE_SurveyQuestionWrapper> listWrapper = new List<EDGE_SurveyQuestionWrapper>();
        EDGE_SurveyQuestionWrapper sqWrapper1 = new EDGE_SurveyQuestionWrapper(surveyQuestion1);
        EDGE_SurveyQuestionWrapper sqWrapper2 = new EDGE_SurveyQuestionWrapper(surveyQuestion2);
        EDGE_SurveyQuestionWrapper sqWrapper3 = new EDGE_SurveyQuestionWrapper(surveyQuestion3);
        listWrapper.add(sqWrapper1);
        listWrapper.add(sqWrapper2);
        listWrapper.add(sqWrapper3);
        listWrapper.sort();
        
        List<EDGE_SurveyQuestionGrpWrapper> listGrpWrapper = new List<EDGE_SurveyQuestionGrpWrapper>();
        EDGE_SurveyQuestionGrpWrapper sqGrpWrapper1 = new EDGE_SurveyQuestionGrpWrapper(surveyQuestion1);
        EDGE_SurveyQuestionGrpWrapper sqGrpWrapper2 = new EDGE_SurveyQuestionGrpWrapper(surveyQuestion2);
        listGrpWrapper.add(sqGrpWrapper1);
        listGrpWrapper.add(sqGrpWrapper2);
        listGrpWrapper.sort();
        
        List<EDGE_SurveyQuestionFirstGrpWrapper> listFrstGrpWrapper = new List<EDGE_SurveyQuestionFirstGrpWrapper>();
        EDGE_SurveyQuestionFirstGrpWrapper sqFrstGrpWrapper1 = new EDGE_SurveyQuestionFirstGrpWrapper(surveyQuestion1.Grouping_1__c, surveyQuestion1.Grouping1_Sequence_Number__c+'');
        EDGE_SurveyQuestionFirstGrpWrapper sqFrstGrpWrapper2 = new EDGE_SurveyQuestionFirstGrpWrapper(surveyQuestion2.Grouping_1__c, surveyQuestion2.Grouping1_Sequence_Number__c+'');
        listFrstGrpWrapper.add(sqFrstGrpWrapper1);
        listFrstGrpWrapper.add(sqFrstGrpWrapper2);
        listFrstGrpWrapper.sort();
        
        
        Date yesterdayDate = (Date.today()).addDays(-1);
        List<Coaching_Report__c> crLst = new List<Coaching_Report__c>();
        Coaching_Report__c coachingReport = EDGE_UtilityTestClass.getCoachingReport(countryId,survey.Id);
        coachingReport.Report_Date__c = yesterdayDate;
        coachingReport.Sales_Representative__c = salesRep.Id;
        coachingReport.Current_Sales_Manager__c = salesManager.Id;
        crLst.add(coachingReport);
        
        insert crLst;
        
        List<Coaching_Survey__c> csLst = new List<Coaching_Survey__c>();
        Coaching_Survey__c coachingSurvey = EDGE_UtilityTestClass.getCoachingSurvey(coachingReport.Id, survey.Id, outletAccount.id);
        coachingSurvey.Next_Coaching_Objectives__c = 'Tested';
        csLst.add(coachingSurvey);
        Coaching_Survey__c coachingSurvey2 = EDGE_UtilityTestClass.getCoachingSurvey(coachingReport.Id, survey.Id, outletAccount.id);
        coachingSurvey2.Next_Coaching_Objectives__c = 'Tested New';
        csLst.add(coachingSurvey2);
        
        insert csLst;
        
        List<Coaching_Survey_Response__c> lstCochingRes = new List<Coaching_Survey_Response__c>();
        for(Survey_Question__c surveyQus : lstSurveyQus){
            Coaching_Survey_Response__c coachingSurveyRsp = EDGE_UtilityTestClass.getCoachingSurveyResponse(coachingSurvey.Id, surveyQus.Id);
            lstCochingRes.add(coachingSurveyRsp);
        }
        for(Survey_Question__c surveyQus : lstSurveyQus){
            Coaching_Survey_Response__c coachingSurveyRsp = EDGE_UtilityTestClass.getCoachingSurveyResponse(coachingSurvey2.Id, surveyQus.Id);
            coachingSurveyRsp.Response__c='';
            coachingSurveyRsp.Comment__c='';
            lstCochingRes.add(coachingSurveyRsp);
        }
        
        insert lstCochingRes;
    }

}