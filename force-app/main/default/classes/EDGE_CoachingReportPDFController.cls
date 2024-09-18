/*
* @Description: EDGE_CoachingReportPDFController

* @Purpose: 

* @History:                                                            

* @VERSION          AUTHOR                 DATE              DETAIL
*    1.0         Preyanka Ghosh         17/09/2019        Intial Development
*    2.0		 Sagar barman			15/11/2019		  Changed the score logic
*    3.0         Divya Bansal			29/01/2021		  ES20-9513 Added Translation Language Logic
*    4.0         Debolina/Mayukh        13/06/2022        ES20-12774 - To resolve Alignment Issue For Japan Coaching form_SFDC_Tech Debt
*    5.0         Rajarshi/Mayukh        10/04/2023        ES20-13970 - UAT_Coaching Report Issue for Blank Responses
**/
public with sharing class EDGE_CoachingReportPDFController {
    public static String isUpdate;
    public static Map<String, String> firstGroupSegToFrstGrpName;
    public static Map<Id,List<Coaching_Survey_Response__c>> mapSurveyResponses;
    public static Map<Id,List<Id>> mapSurveyQuestions;
    public String labelLang {get;set;}
    public static Coaching_Report__c coachingReport {get;set;}
    public static String reportDate {get;set;}
    public static Map<Id,Coaching_Survey__c> mapCoachingSurvey {get;set;}   
    public static Map<String, Integer> mapFirstGroupSize{get;set;}
    public static Map<Id, String> mapQuestionName {get;set;}
    public static Map<String, List<Coaching_Survey_Response__c>> mapOutletSurveyResponse {get;set;}
    public static Map<String, String> mapOutletSurveyTextResponse {get;set;}
    public static Map<String, Decimal> mapScoreGroup {get;set;}
    public static Map<String, String> mapSecondGroupComments {get;set;}   
    public static Decimal finalSurveyScore {get;set;}
    public static Map<Id,Decimal> mapOutletScore {get;set;}
    public static String comments {get;set;}
    public static String nextCoachingObjectives {get;set;}
    public static Decimal totalWidth{get;set;}
    public static Decimal totaldownWidth{get;set;}
    public static Map<String, Set<EDGE_SurveyQuestionGrpWrapper>> mapFirstGroupLevel {get;set;}
    public static Map<EDGE_SurveyQuestionFirstGrpWrapper, Set<EDGE_SurveyQuestionGrpWrapper>> mapFirstGroupLevelWrapper {get;set;}
    public static Map<String, Set<EDGE_SurveyQuestionWrapper>> mapSecondGroupLevel {get;set;}
    public static Map<String, Map<String,EDGE_SurveyQuestionWrapper>> mapSecondGroupLevelNested{get;set;}
    public static Integer outletSize{get;set;}
    public static Map<Id,OutletNameWrapper> outletWrapperMap {get;set;}

    /**
	* @Method  : EDGE_CoachingReportPDFController
	* @Purpose : Constructor to get the ID and get related data 
	**/
    public EDGE_CoachingReportPDFController(){
        String coachingReportId = ApexPages.currentPage().getParameters().get('id').escapeHtml4();
        isUpdate = ApexPages.currentPage().getParameters().get('isUpdate'); 
        labelLang = ApexPages.currentPage().getParameters().get('label_lang');//ES20-9513
        //Apexpages.currentPage().getHeaders().put('Content-Type', 'application/pdf; charset="UTF-8"');
        
        fetchCoachingData(coachingReportId);        
        
        // ES20-9513
        if(Test.isRunningTest()){
            labelLang = 'MX';
        }
        System.debug(LoggingLevel.DEBUG,'coachingReportId = '+ coachingReportId);
    }
    /**
	* @Method  : updateReportingScore
	* @Purpose : Update score in Reporting Survey 
	**/
    public static void updateReportingScore(){
        if(isUpdate != null && isUpdate.containsIgnoreCase('Yes') && Schema.sObjectType.Coaching_Report__c.isUpdateable()){
            if(finalSurveyScore!=null){
                coachingReport.Score__c = finalSurveyScore;    
            }
            coachingReport.Status__c = 'Report Generated';
            update coachingReport; 
        }
    }
    
    
    /**
	* @Method  : fetchCoachingData
	* @Purpose : Retrieve all related data attached with a Reporting Survey 
	**/
    public static void fetchCoachingData(Id coachingReportId){        
        List<String> spacedCountry = Label.EDGE_Coaching_Country.split(';');
        Boolean isspacedCountry = false;
        if(coachingReportId != null && Schema.sObjectType.Coaching_Report__c.isAccessible() && Schema.sObjectType.Coaching_Survey__c.isAccessible() && Schema.sObjectType.Survey__c.isAccessible() && Schema.sObjectType.User.isAccessible()){
            coachingReport = [SELECT Id, Current_Sales_Manager__c, Current_Sales_Manager__r.Name, Report_Date__c, Score__c, Sales_Representative__c, Sales_Representative__r.Name,Survey__c,Survey__r.Country__r.Code__c FROM Coaching_Report__c WHERE ID =:coachingReportId];
            if(spacedCountry.contains(coachingReport.Survey__r.Country__r.Code__c)){
                isspacedCountry = true;
            }
            reportDate = String.valueOf((coachingReport.Report_Date__c).day())+'/'+String.valueOf((coachingReport.Report_Date__c).month())+'/'+String.valueOf((coachingReport.Report_Date__c).year());
            mapCoachingSurvey = new Map<Id,Coaching_Survey__c>([SELECT Id, Coaching_Report__c, Completion_Date__c, Status__c,Outlet__c,Outlet__r.Name,Next_Coaching_Objectives__c FROM Coaching_Survey__c WHERE Coaching_Report__c = :coachingReportId AND Status__c NOT IN ('Report Generated')]);            
        }
        outletSize = 0;
        outletWrapperMap = new Map<Id,OutletNameWrapper>();
        for(Coaching_Survey__c csObj : mapCoachingSurvey.values()){
            if(!outletWrapperMap.containsKey(csObj.Outlet__c)){
                if(isspacedCountry){
                    outletWrapperMap.put(csObj.Outlet__c, new OutletNameWrapper(csObj.Outlet__c,getWhitespacedChar(csObj.Outlet__r.Name,35/mapCoachingSurvey.size()),1));
                }
                else{
                    outletWrapperMap.put(csObj.Outlet__c, new OutletNameWrapper(csObj.Outlet__c,getWhitespacedChar(csObj.Outlet__r.Name,50/mapCoachingSurvey.size()),1));
                }
            }
            else{
                outletWrapperMap.get(csObj.Outlet__c).outletNo += 1;
            }
            outletSize+=1;
        }
        
        if(mapCoachingSurvey != null && !mapCoachingSurvey.isEmpty()){
            mapFirstGroupLevel = new Map<String, Set<EDGE_SurveyQuestionGrpWrapper>>();
            mapSecondGroupLevel = new Map<String, Set<EDGE_SurveyQuestionWrapper>>();
            mapFirstGroupSize = new Map<String, Integer>();
            mapQuestionName = new Map<Id, String>();
            mapOutletSurveyResponse = new Map<String, List<Coaching_Survey_Response__c>>();
            mapOutletScore = new Map<Id,Decimal>();
            mapSecondGroupComments = new Map<String,String>();
            Map<String, Decimal> mapScorePerGroup = new Map<String, Decimal>();
            Map<String, Decimal> mapTotalQusPergroup = new Map<String, Decimal>();
            Map<Id,String> mapSurveyNextObjective = new Map<Id,String>();
            mapOutletSurveyTextResponse = new Map<String, String>();
            Decimal totalQus = 0.00;
            //Decimal totalQusPoints = 0.00;
            Decimal score = 0.00;            
            comments = '';
            nextCoachingObjectives = '';
            firstGroupSegToFrstGrpName = new Map<String, String>();            
            mapSurveyResponses = new Map<Id,List<Coaching_Survey_Response__c>>();
            mapSurveyQuestions = new Map<Id,List<Id>>();
            
            //getting the Survey Questions against the survey
            Map<Id,Survey_Question__c> sqMap = new Map<Id,Survey_Question__c>([SELECT Id,Survey__c,Question__c,Order_Number__c,Grouping2_Sequence_Number__c,Response_Type__c,Grouping_1__c,Grouping_2__c,Grouping1_Sequence_Number__c FROM Survey_Question__c WHERE Survey__c =:coachingReport.Survey__c]);            
            //Retrive all Coaching Survey Response 
            if( Schema.sObjectType.Coaching_Survey_Response__c.isAccessible() && Schema.sObjectType.Coaching_Survey__c.isAccessible() && Schema.sObjectType.Account.isAccessible() && Schema.sObjectType.Survey_Question__c.isAccessible() ) {         
                List<Coaching_Survey_Response__c> coachSurveyRspList = [SELECT Id, Coaching_Survey__c, Survey_Question__r.Grouping1_Sequence_Number__c,Survey_Question__r.Grouping2_Sequence_Number__c,Coaching_Survey__r.Outlet__c, Coaching_Survey__r.Outlet__r.Name, Comment__c, Response__c, Survey_Question__c, 
                                                                        Survey_Question__r.Grouping_1__c, Survey_Question__r.Grouping_2__c, Survey_Question__r.Question__c, Survey_Question__r.Response_Type__c, 
                                                                        Survey_Question__r.Order_Number__c, Survey_Question__r.Mandatory__c, Coaching_Survey__r.Next_Coaching_Objectives__c
                                                                        FROM Coaching_Survey_Response__c WHERE Coaching_Survey__c IN :mapCoachingSurvey.keySet() ORDER BY Coaching_Survey__r.Outlet__c,Survey_Question__r.Grouping1_Sequence_Number__c,Survey_Question__r.Grouping2_Sequence_Number__c,Survey_Question__r.Order_Number__c];
                //the below code is to populate blank responses for questions which are not answered,
                // need to add these blank responses for the alignment of pdf
                for(Coaching_Survey_Response__c coachSurveyRsp : coachSurveyRspList){
                    if(mapSurveyResponses.containsKey(coachSurveyRsp.Coaching_Survey__c)){
                        mapSurveyResponses.get(coachSurveyRsp.Coaching_Survey__c).add(coachSurveyRsp) ; 
                    }else{
                        mapSurveyResponses.put(coachSurveyRsp.Coaching_Survey__c,new List<Coaching_Survey_Response__c>{coachSurveyRsp});        
                    }
                    if(mapSurveyQuestions.containsKey(coachSurveyRsp.Coaching_Survey__c)){
                        mapSurveyQuestions.get(coachSurveyRsp.Coaching_Survey__c).add(coachSurveyRsp.Survey_Question__c) ; 
                    }else{
                        mapSurveyQuestions.put(coachSurveyRsp.Coaching_Survey__c,new List<Id>{coachSurveyRsp.Survey_Question__c});        
                    }                
                }
            }
            
            System.debug(LoggingLevel.DEBUG,'mapSurveyQuestions size'+mapSurveyQuestions.keyset().size());
            //check if the CSRs have all the questions
            if(null != mapSurveyQuestions && !mapSurveyQuestions.isEmpty() && null !=sqMap && !sqMap.isEmpty()){
                for(Id cSurveyId : mapSurveyQuestions.keySet()){
                    for(Id qid : sqMap.keySet()){
                        if(!mapSurveyQuestions.get(cSurveyId).contains(qid)){
                            mapSurveyResponses.get(cSurveyId).add(new Coaching_Survey_Response__c(Survey_Question__r=sqMap.get(qid),Survey_Question__c= qid,Response__c='',Coaching_Survey__r=mapCoachingSurvey.get(cSurveyId)));	    
                        }    
                    } 
                }    
            } 
            
            //make the final list for Coaching_Survey_Response__c
            List<Coaching_Survey_Response__c> finalCSRList = new List<Coaching_Survey_Response__c>();
            for(List<Coaching_Survey_Response__c> tempList : mapSurveyResponses.values()){
                for(Coaching_Survey_Response__c csr : tempList){
                    if(isspacedCountry){
                        csr.Response__c = getWhitespacedChar(csr.Response__c,30/outletSize);
                    }
                    else{
                        csr.Response__c = getWhitespacedChar(csr.Response__c,65/outletSize);
                    }
                    finalCSRList.add(csr);
                }
            }
            System.debug(LoggingLevel.DEBUG,'final list size at the end'+finalCSRList.size());                
            
            for(Coaching_Survey_Response__c coachSurveyRsp : finalCSRList)
            {
                String seqNum = coachSurveyRsp.Survey_Question__r.Grouping1_Sequence_Number__c+'';
                if(!firstGroupSegToFrstGrpName.containsKey(seqNum)){
                    firstGroupSegToFrstGrpName.put(seqNum, coachSurveyRsp.Survey_Question__r.Grouping_1__c);
                }
                //This map will contains the Total response per outlet
                //ES20-13970//Added String Blank check in decision statements to prevent empty String error
                if(String.isNotBlank(coachSurveyRsp.Response__c) && coachSurveyRsp.Response__c!= null && coachSurveyRsp.Response__c !='' && mapOutletScore.containsKey(coachSurveyRsp.Coaching_Survey__r.Outlet__c) && (coachSurveyRsp.Survey_Question__r.Response_Type__c).containsIgnoreCase('Number')){
                    Decimal response = Decimal.valueOf(coachSurveyRsp.Response__c);                        
                    response = response + mapOutletScore.get(coachSurveyRsp.Coaching_Survey__r.Outlet__c);
                    mapOutletScore.put(coachSurveyRsp.Coaching_Survey__r.Outlet__c, response);    
                }
                else if((String.isBlank(coachSurveyRsp.Response__c) || coachSurveyRsp.Response__c == null || coachSurveyRsp.Response__c =='') && mapOutletScore.containsKey(coachSurveyRsp.Coaching_Survey__r.Outlet__c) && (coachSurveyRsp.Survey_Question__r.Response_Type__c).containsIgnoreCase('Number')){
                    Decimal response = 0.0;
                    response = mapOutletScore.get(coachSurveyRsp.Coaching_Survey__r.Outlet__c)+0;            
                    mapOutletScore.put(coachSurveyRsp.Coaching_Survey__r.Outlet__c, response);
                }                    
                else if(String.isNotBlank(coachSurveyRsp.Response__c) && coachSurveyRsp.Response__c!= null && coachSurveyRsp.Response__c !='' && (coachSurveyRsp.Survey_Question__r.Response_Type__c).containsIgnoreCase('Number')){                       
                    Decimal response = 0.0;                    
                    response = Decimal.valueOf(coachSurveyRsp.Response__c);  
                    mapOutletScore.put(coachSurveyRsp.Coaching_Survey__r.Outlet__c, response);                    
                }
                else if((String.isNotBlank(coachSurveyRsp.Response__c) && coachSurveyRsp.Response__c== null && coachSurveyRsp.Response__c =='') && (coachSurveyRsp.Survey_Question__r.Response_Type__c).containsIgnoreCase('Number')){
                    mapOutletScore.put(coachSurveyRsp.Coaching_Survey__r.Outlet__c, 0);     
                }              
                //Get comments and append
                if(String.isNotBlank(coachSurveyRsp.Comment__c)){
                    comments = comments + ' ' + coachSurveyRsp.Comment__c;
                }
                //Get 'Next Coaching Objectives' and append
                if(String.isNotBlank(coachSurveyRsp.Coaching_Survey__r.Next_Coaching_Objectives__c)){
                    //nextCoachingObjectives = nextCoachingObjectives + ' ' + coachSurveyRsp.Coaching_Survey__r.Next_Coaching_Objectives__c;
                    if(isspacedCountry){
                        mapSurveyNextObjective.put(coachSurveyRsp.Coaching_Survey__c,getWhitespacedChar(coachSurveyRsp.Coaching_Survey__r.Next_Coaching_Objectives__c,53));  //added for comments
                    }
                    else{
                        mapSurveyNextObjective.put(coachSurveyRsp.Coaching_Survey__c,getWhitespacedChar(coachSurveyRsp.Coaching_Survey__r.Next_Coaching_Objectives__c,110));  //added for comments
                    }
                }
                
                //This map will containg Question Id and Name of Quesion
                if(!mapQuestionName.containsKey(coachSurveyRsp.Survey_Question__c)){
                    if(isspacedCountry){
                        coachSurveyRsp.Survey_Question__r.Question__c = getWhitespacedChar(coachSurveyRsp.Survey_Question__r.Question__c,12);   //added for questions
                    }
                    else{
                        coachSurveyRsp.Survey_Question__r.Question__c = getWhitespacedChar(coachSurveyRsp.Survey_Question__r.Question__c,26);   //added for questions
                    }
                    mapQuestionName.put(coachSurveyRsp.Survey_Question__c, coachSurveyRsp.Survey_Question__r.Question__c);    
                }             
                Survey_Question__c surveyQs = new Survey_Question__c(Id=coachSurveyRsp.Survey_Question__r.Id,
                                                                     Question__c = coachSurveyRsp.Survey_Question__r.Question__c,
                                                                     Order_Number__c= coachSurveyRsp.Survey_Question__r.Order_Number__c,
                                                                     Grouping_1__c	= coachSurveyRsp.Survey_Question__r.Grouping_1__c,
                                                                     Grouping_2__c	= coachSurveyRsp.Survey_Question__r.Grouping_2__c,
                                                                     Grouping1_Sequence_Number__c = coachSurveyRsp.Survey_Question__r.Grouping1_Sequence_Number__c,
                                                                     Grouping2_Sequence_Number__c = coachSurveyRsp.Survey_Question__r.Grouping2_Sequence_Number__c
                                                                    );
                EDGE_SurveyQuestionGrpWrapper sqGrp2Wrapper = new EDGE_SurveyQuestionGrpWrapper(surveyQs);
                
                //This map will contains the Group 1 and Group 2 mapping
                if(mapFirstGroupLevel.containsKey(coachSurveyRsp.Survey_Question__r.Grouping_1__c)){
                    mapFirstGroupLevel.get(coachSurveyRsp.Survey_Question__r.Grouping_1__c).add(sqGrp2Wrapper);
                } else {
                    mapFirstGroupLevel.put(coachSurveyRsp.Survey_Question__r.Grouping_1__c, new Set<EDGE_SurveyQuestionGrpWrapper>{sqGrp2Wrapper});
                }                
                EDGE_SurveyQuestionWrapper sqWrapper = new EDGE_SurveyQuestionWrapper(surveyQs);
                //This map will contains Group 2 and Account Mapping
                if(mapSecondGroupLevel.containsKey(coachSurveyRsp.Survey_Question__r.Grouping_2__c)){                   
                    mapSecondGroupLevel.get(coachSurveyRsp.Survey_Question__r.Grouping_2__c).add(sqWrapper);
                } else {
                    mapSecondGroupLevel.put(coachSurveyRsp.Survey_Question__r.Grouping_2__c, new Set<EDGE_SurveyQuestionWrapper>{sqWrapper});
                }
                //ES20-13970//Added String Blank check in decision statements to prevent empty String error
                if(String.isNotBlank(coachSurveyRsp.Response__c) && coachSurveyRsp.Response__c!= null && coachSurveyRsp.Response__c !='' && (coachSurveyRsp.Survey_Question__r.Response_Type__c).containsIgnoreCase('Number') && mapTotalQusPergroup!=null && mapTotalQusPergroup.containsKey(coachSurveyRsp.Survey_Question__r.Grouping_1__c)){
                    totalQus = mapTotalQusPergroup.get(coachSurveyRsp.Survey_Question__r.Grouping_1__c)+4;                    
                    score =  mapScorePerGroup.get(coachSurveyRsp.Survey_Question__r.Grouping_1__c)+ handleBlankString(coachSurveyRsp.Response__c);//Decimal.valueOf(coachSurveyRsp.Response__c);
                    mapScorePerGroup.put(coachSurveyRsp.Survey_Question__r.Grouping_1__c, score);
                    mapTotalQusPergroup.put(coachSurveyRsp.Survey_Question__r.Grouping_1__c,totalQus);
                }else if((String.isBlank(coachSurveyRsp.Response__c) && coachSurveyRsp.Response__c== null || coachSurveyRsp.Response__c == '') && (coachSurveyRsp.Survey_Question__r.Response_Type__c).containsIgnoreCase('Number') && mapTotalQusPergroup!=null && mapTotalQusPergroup.containsKey(coachSurveyRsp.Survey_Question__r.Grouping_1__c)){
                    totalQus = mapTotalQusPergroup.get(coachSurveyRsp.Survey_Question__r.Grouping_1__c)+0;                    
                    score =  mapScorePerGroup.get(coachSurveyRsp.Survey_Question__r.Grouping_1__c)+0;
                    mapScorePerGroup.put(coachSurveyRsp.Survey_Question__r.Grouping_1__c, score);
                    mapTotalQusPergroup.put(coachSurveyRsp.Survey_Question__r.Grouping_1__c,totalQus);	    
                }else if(String.isNotBlank(coachSurveyRsp.Response__c) && coachSurveyRsp.Response__c!= null  && coachSurveyRsp.Response__c !='' && (coachSurveyRsp.Survey_Question__r.Response_Type__c).containsIgnoreCase('Number')){
                    mapTotalQusPergroup.put(coachSurveyRsp.Survey_Question__r.Grouping_1__c, 4);//put it in label
                    score =  handleBlankString(coachSurveyRsp.Response__c);  //ES20-13970                      
                    mapScorePerGroup.put(coachSurveyRsp.Survey_Question__r.Grouping_1__c, score);                        
                }else if((String.isBlank(coachSurveyRsp.Response__c) || coachSurveyRsp.Response__c== null || coachSurveyRsp.Response__c == '') && (coachSurveyRsp.Survey_Question__r.Response_Type__c).containsIgnoreCase('Number')){
                    mapTotalQusPergroup.put(coachSurveyRsp.Survey_Question__r.Grouping_1__c, 0);//put it in label
                    mapScorePerGroup.put(coachSurveyRsp.Survey_Question__r.Grouping_1__c, 0);       
                }
                //get the comments on the second group level-- not added in UI
                if(String.isNotBlank(coachSurveyRsp.Response__c) && coachSurveyRsp.Response__c!= null && (coachSurveyRsp.Survey_Question__r.Response_Type__c).containsIgnoreCase('Text') && mapSecondGroupComments.containsKey(coachSurveyRsp.Survey_Question__r.Grouping_2__c)){
                    //comments concatenate
                    String tempComments =  mapSecondGroupComments.get(coachSurveyRsp.Survey_Question__r.Grouping_2__c);
                    mapSecondGroupComments.put(coachSurveyRsp.Survey_Question__r.Grouping_2__c,tempComments+' '+coachSurveyRsp.Response__c);
                }
                else if(String.isNotBlank(coachSurveyRsp.Response__c) && coachSurveyRsp.Response__c!= null && (coachSurveyRsp.Survey_Question__r.Response_Type__c).containsIgnoreCase('Text')){
                    mapSecondGroupComments.put(coachSurveyRsp.Survey_Question__r.Grouping_2__c,coachSurveyRsp.Response__c);     
                }                
                //This map will contain outlet and Coaching survey response mapping
                if(mapOutletSurveyResponse.containsKey(coachSurveyRsp.Survey_Question__c)){                    
                    mapOutletSurveyResponse.get(coachSurveyRsp.Survey_Question__c).add(coachSurveyRsp); 
                } else {
                    mapOutletSurveyResponse.put(coachSurveyRsp.Survey_Question__c, new List<Coaching_Survey_Response__c> {coachSurveyRsp});
                }                
            }//the big for
            System.debug(LoggingLevel.DEBUG,'mapOutletSurveyResponse=='+mapOutletSurveyResponse.keySet().size());
            
            if(mapSurveyNextObjective!=null){
                for(String obj : mapSurveyNextObjective.values()){
                    nextCoachingObjectives += obj + '<br/>' ;                    
                }    
            }
            
            if(outletWrapperMap.keySet() != null){     
                if(outletSize!=0){
                    totalWidth = 420/outletSize;// ui related
                    totaldownWidth = 392/outletSize;//ui related
                }
            }
            mapScoreGroup = new Map<String, Decimal>();           
            Decimal totalOutletScore = 0.0; 
            Decimal maxResponseTotal = 0.0; 
            //Integer count = 0;
            finalSurveyScore = 0.00; 
            if(mapScorePerGroup != null && !mapScorePerGroup.IsEmpty()){
                for(String firstGroup : mapScorePerGroup.keySet()){
                    if(mapScorePerGroup.get(firstGroup) != null && mapTotalQusPergroup.get(firstGroup) !=null && mapTotalQusPergroup.get(firstGroup)!=0){
                        score = (mapScorePerGroup.get(firstGroup)/mapTotalQusPergroup.get(firstGroup)); 
                        mapScoreGroup.put(firstGroup,(score*100.00).setscale(2));    
                    }
                    else{
                        score = 0; 
                        mapScoreGroup.put(firstGroup,0);        
                    }
                }      
            }        
            //get sum of all oulet score for this survey
            for(Decimal decVal : mapOutletScore.values()){
                totalOutletScore += decVal;     
            }            
            //get sum of all responses with maximum value possible
            for(Decimal decVal : mapTotalQusPergroup.values()){
                maxResponseTotal += decVal;    
            }   
            if(maxResponseTotal!=0){
                finalSurveyScore = ((totalOutletScore/maxResponseTotal)*100.00).setscale(2);     
            }
            mapFirstGroupLevelWrapper = new Map<EDGE_SurveyQuestionFirstGrpWrapper, Set<EDGE_SurveyQuestionGrpWrapper>>();
            for(String firstGroupSeg : firstGroupSegToFrstGrpName.keySet()){
                String firstGroupName = firstGroupSegToFrstGrpName.get(firstGroupSeg);
                if(mapFirstGroupLevel.containsKey(firstGroupName)){ 
                    EDGE_SurveyQuestionFirstGrpWrapper sqGrp1Wrapper = new EDGE_SurveyQuestionFirstGrpWrapper( firstGroupName, firstGroupSeg);
                    mapFirstGroupLevelWrapper.put(sqGrp1Wrapper, mapFirstGroupLevel.get(firstGroupName));
                }
            }
            mapSecondGroupLevelNested = new Map<String, Map<String,EDGE_SurveyQuestionWrapper>>();
            Set<EDGE_SurveyQuestionWrapper> surveyQsWrapperSet = new Set<EDGE_SurveyQuestionWrapper>();
            
            for(String secondGrpName : mapSecondGroupLevel.keySet()){
                surveyQsWrapperSet = mapSecondGroupLevel.get(secondGrpName);
                Map<String,EDGE_SurveyQuestionWrapper> orderNosqWrapperMap =
                    new Map<String,EDGE_SurveyQuestionWrapper>();
                for(EDGE_SurveyQuestionWrapper sqWrapper : surveyQsWrapperSet){
                    orderNosqWrapperMap.put(sqWrapper.surveyQuestion.Order_Number__c+'', sqWrapper);
                }
                mapSecondGroupLevelNested.put(secondGrpName,orderNosqWrapperMap);
            }
            //updateReportingScore
            
        }
    } // end fetchCoachingData
    
    /**
	* @Method  : getWhitespacedChar
	* @Purpose : This methods is used to add whitespaces so that they can be broken down to fit td width
	**/     
    public static String getWhitespacedChar(String value,Integer width){
        String formattedQs='';
        //Integer i=0;
        List<String> stringList2 = new List<String>();
        if(String.isNotBlank(value) && value != Null && !value.isNumeric()){
            {
                stringList2 =  value.split(' ',0);
            }
            String formattedChar2;
            //Boolean space=false;
            for(String str : stringList2){
                if(str.length()>width){
                    if(formattedChar2== Null){
                        formattedChar2 = formattedChar(str,width);
                    }
                    else{
                        formattedChar2 += formattedChar(str,width);
                    }
                }
                else{
                    if(formattedChar2!=Null){
                        formattedChar2+=str;
                    }
                    else{
                        formattedChar2 = str;
                    }
                }
                formattedChar2+=' ';
                System.debug(LoggingLevel.DEBUG,'formattedChar-: '+formattedChar2);
            }
            formattedQs = formattedChar2;
        }
        else if(String.isNotBlank(value) && value!=Null && value.isNumeric()){
            formattedQs = value;
        }
        return formattedQs;
    }
    
    public static String formattedChar(String value,Integer width){
        String formattedChar;
        Integer i = 0;
        do{
            if(i<value.length()){
                if(formattedChar == Null){
                    formattedChar = value.substring(i,i+1);
                }
                else if(math.mod(i, width)==0 && i!=value.length()-1){
                    formattedChar = formattedChar + value.substring(i,i+1) + '-\n'; 
                }
                else{
                    formattedChar = formattedChar + value.substring(i,i+1);  
                }
            }
            i=i+1;
        }while(i < value.length());	
        return formattedChar;
    }
    
    Public class OutletNameWrapper{
        public String outletId{get;set;}
        public string outletName{get;set;}
        public Integer outletNo{get;set;}
        
        
        Public OutletNameWrapper(String oid,String name, Integer no)
        {
            this.outletId = oid;
            this.outletName = name;
            this.outletNo = no;
        }
    }
    
    //ES20-13970
    public static Decimal handleBlankString(String coachingSurveyRespStr){
        String coachingSurveryRespTxt = coachingSurveyRespStr.trim();
        return coachingSurveryRespTxt != '' ? Decimal.valueOf(coachingSurveyRespStr): 0.0;  
    }
}