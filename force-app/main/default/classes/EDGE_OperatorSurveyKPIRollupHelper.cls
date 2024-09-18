/**
* @Description: EDGE_OperatorSurveyKPIRollupHelper

* @Purpose: Helper Class for EDGE_OperatorSurveyKPIRollupBatch

* @Version    Developer      	Date         Story
*   1.0		 Shahbaz Khan  	  30/09/2020	 ES20-8503
*   2.0		 Rajarshi Lahiri  23/03/2022	 ES20-12217[Changed the method signature of getOutletSurveyResponse invoked in this class ]
*/

public class EDGE_OperatorSurveyKPIRollupHelper {
    public static double targetDerived = 0;
    public static Set<Id> surveyIdSet = new Set<Id>();
    public static Set<Id> actKpiAchIds = new Set<Id>();
    public static Map<String, Id> existingAccountKPIAch = new Map<String, Id>();
    public static Map<Id, Account_KPI_Achievement__c> existingAccountKPIAchMap = new Map<Id, Account_KPI_Achievement__c>();
    public static Id outletRecTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
    
    public static void populateAccountKPIAch(Map<Id,Account> operatorMap , Market_Cycle__c marketCycle){
        Map<Id, List<Outlet_Survey_Response__c>> outletActKPIResponseMap = new Map<Id, List<Outlet_Survey_Response__c>>();
        Map<Id, Boolean> surveyKPICheckedMap = new Map<Id, Boolean>();
        if(marketCycle!=null && !operatorMap.isEmpty() && operatorMap.size()>0){
            //Get Operator with its associated Outlets Map
            Map<Id,List<Account>> operatorOutletsMap = getOperatorOutlets(operatorMap.values());
            
            //Get Existing Account KPI Achievements
            getAccountKPIAchievements(operatorMap.values());
            System.debug('@@existingAccountKPIAch '+existingAccountKPIAch);
            //Get Outlet Survey Response
            Map<Id, List<Outlet_Survey_Response__c>> outletSurveyResponseMap = EDGE_OutletSurveyKPIRollupBatchHelper.getOutletSurveyResponse(marketCycle, outletActKPIResponseMap,surveyKPICheckedMap, null,null, null, null,null, operatorMap.keySet(), null);
            surveyIdSet = EDGE_OutletSurveyKPIRollupBatchHelper.surveyIdSet;
            system.debug('@@surveyIdSet '+surveyIdSet);
            system.debug('@@outletActKPIResponseMap '+outletActKPIResponseMap);
            
            //Get Survey Response
            Map<Id, String> surveyAnswerMap = EDGE_OutletSurveyKPIRollupBatchHelper.getSurveyQuestionAnswer(surveyIdSet);
            System.debug('@@surveyAnswerMap '+surveyAnswerMap);
            //Create KPI Achievement Records
            Map<String, Account_KPI_Achievement__c> accountKpiAchievementMap = calculateSurveyKPI(operatorOutletsMap, outletSurveyResponseMap, surveyAnswerMap, operatorMap, outletActKPIResponseMap, surveyKPICheckedMap);
            system.debug('@@accountKpiAchievementMap' + accountKpiAchievementMap);
            if(!accountKpiAchievementMap.isEmpty() && accountKpiAchievementMap.size()>0){
                upsert accountKpiAchievementMap.values();
            }
        }
    }
    public static Map<Id,List<Account>> getOperatorOutlets(List<Account> operatorList){
        Map<Id, List<Account>> operatorOutletsMap = new Map<Id, List<Account>>();
        for(Account outlet : [SELECT Id,Operator__c FROM Account WHERE Operator__c IN :operatorList AND Status__c= 'Active' AND RecordTypeId=:outletRecTypeId]){
            if(!operatorOutletsMap.containsKey(outlet.Operator__c)){
                operatorOutletsMap.put(outlet.Operator__c,new List<Account>{outlet});
            }
            else{
                operatorOutletsMap.get(outlet.Operator__c).add(outlet);
            }
        }
        
        return operatorOutletsMap;
    }
    public static void getAccountKPIAchievements(List<Account> operatorList){
        for(Account_KPI_Achievement__c accKPIAch : [SELECT Id,Account__c,KPI_Type__c,Activation_Survey_KPI__c,Target_Derived__c FROM Account_KPI_Achievement__c
                                                    WHERE Account__c IN :operatorList])
        {
            String key = '';
            if(accKPIAch.Activation_Survey_KPI__c!=null){
                key = accKPIAch.Account__c + '_'+accKPIAch.KPI_Type__c+'_'+accKPIAch.Activation_Survey_KPI__c;
            }
            else {
                key = accKPIAch.Account__c + '_'+accKPIAch.KPI_Type__c+'_';
            }
            existingAccountKPIAch.put(key,accKPIAch.Id);
            existingAccountKPIAchMap.put(accKPIAch.Id,accKPIAch);
        }
    }
    
    public static Map<String,Account_KPI_Achievement__c> calculateSurveyKPI(Map<Id, List<Account>> operatorOutletsMap, Map<Id, List<Outlet_Survey_Response__c>> outletSurveyResponseMap, Map<Id, String> surveyAnswerMap, Map<Id, Account> operatorMap, Map<Id, List<Outlet_Survey_Response__c>> outletActKPIResponseMap, Map<Id, Boolean> surveyKPICheckedMap)
    {
        Map<String, Account_KPI_Achievement__c> accountKpiAchievementMap = new Map<String, Account_KPI_Achievement__c>();
        if(!operatorOutletsMap.isEmpty() && (!outletSurveyResponseMap.isEmpty() || !outletActKPIResponseMap.isEmpty())){
            for(Id operatorId : operatorOutletsMap.keySet()){
                Integer numberOfOutlets = operatorOutletsMap.get(operatorId).size();
                targetDerived = 0;
                for(Account outlet : operatorOutletsMap.get(operatorId)){
                    //Block for calculating achievement for Survey KPI type
                    if(outletSurveyResponseMap.containsKey(outlet.Id)){
                        for(Outlet_Survey_Response__c outletResponse : outletSurveyResponseMap.get(outlet.Id)){
                            Id surveyKPIId = outletResponse.Survey_Question__r.Survey_KPI__c;
                            String key = operatorId + '_' + surveyKPIId;
                            Account_KPI_Achievement__c accKpiAch;
                            Double outletResp = EDGE_OutletSurveyKPIRollupBatchHelper.validateResponse(surveyAnswerMap, outletResponse) ? 1 : 0;
                            if(accountKpiAchievementMap.containsKey(key)){
                                accKpiAch = accountKpiAchievementMap.get(key);
                                accKpiAch.Actual_Numerator__c = EDGE_OutletSurveyKPIRollupBatchHelper.validateResponse(surveyAnswerMap, outletResponse) ? accKpiAch.Actual_Numerator__c +1 : accKpiAch.Actual_Numerator__c;
                            	accKpiAch.Actual__c = calculateActual(accKpiAch);
                            	accountKpiAchievementMap.put(key,accKpiAch);
                            }
                            else{
                                accKpiAch = createAccKpiAch(operatorId,surveyKPIId,numberOfOutlets,operatorMap.get(operatorId),null,'Survey KPI');
                            	accKpiAch.Actual_Numerator__c = EDGE_OutletSurveyKPIRollupBatchHelper.validateResponse(surveyAnswerMap, outletResponse) ? 1 : 0;
                            	accKpiAch.Actual__c = calculateActual(accKpiAch);
                                accountKpiAchievementMap.put(key,accKpiAch);
                            }
                            if(accKpiAch!=null && surveyKPICheckedMap!=null && surveyKPICheckedMap.get(surveyKPIId)){
                                calcTotalAcvSrvyKPI(operatorId,accKpiAch,outletResp,accountKpiAchievementMap,numberOfOutlets,operatorMap);
                            }
                        }
                    }
                    //Block for calculating achievement for Activation Survey KPI type
                    if(outletActKPIResponseMap.containsKey(outlet.Id)){
                        for(Outlet_Survey_Response__c outletResponse : outletActKPIResponseMap.get(outlet.Id)){
                            Id actKPIId = outletResponse.Survey_Question__r.Activation_Type__c;
                            String activationKPIKey = operatorId + '_' + actKPIId;
                            Account_KPI_Achievement__c accKpiAch;
                            Decimal outletResp = 0;
                            System.debug('outletResponse.Response__c = '+ outletResponse.Response__c);
                            if(outletResponse.Response__c != null && EDGE_OutletSurveyKPIRollupBatchHelper.isNumeric(outletResponse.Response__c)){
                                outletResp = Decimal.valueOf(outletResponse.Response__c);
                            }
                            
                            if(accountKpiAchievementMap.containsKey(activationKPIKey)){
                               accKpiAch =  accountKpiAchievementMap.get(activationKPIKey);
                               accKpiAch.Actual_Numerator__c = accKpiAch.Actual_Numerator__c + outletResp;
                               accountKpiAchievementMap.put(activationKPIKey,accKpiAch);
                            }
                            else{
                                accKpiAch = createAccKpiAch(operatorId,null,numberOfOutlets,operatorMap.get(operatorId),actKPIId,'Activation Survey KPI');
                                accKpiAch.Actual_Numerator__c = outletResp;
                                accountKpiAchievementMap.put(activationKPIKey,accKpiAch);
                            }
                            if(accKpiAch!=null){
                                accKpiAch.Actual__c = accKpiAch.Actual_Numerator__c;
                                calcTotalAcvSrvyKPI(operatorId,accKpiAch,outletResp,accountKpiAchievementMap,numberOfOutlets,operatorMap);
                            }
                        }
                    }
                } 
            }
        }
        return accountKpiAchievementMap;
    }
    public static Account_KPI_Achievement__c createAccKpiAch(Id operatorId, Id surveyKPIId, Integer numberOfOutlets, Account operator, Id actTypeKPIId, String kpiType){
        Account_KPI_Achievement__c accKpiAch = new Account_KPI_Achievement__c();
        String key = '';
        if(kpiType!=null){
            //Block for populating fields common to both Survey and Activation KPI
            accKpiAch.Account__c = operatorId;
            accKpiAch.Total_Denominator__c = numberOfOutlets;
            if(kpiType == 'Survey KPI' && surveyKPIId!=null){
                key = operatorId+'_'+kpiType+'_'+surveyKPIId;
                accKpiAch.KPI_Type__c = kpiType;
                accKpiAch.Activation_Survey_KPI__c = surveyKPIId;
            }
            else if(kpiType == 'Activation Survey KPI' && actTypeKPIId!=null){
                key = operatorId+'_'+kpiType+'_'+actTypeKPIId;
                accKpiAch.KPI_Type__c = kpiType;
                accKpiAch.Activation_Survey_KPI__c = actTypeKPIId;
            }
            else{
                key = operatorId+'_'+kpiType+'_';
                accKpiAch.KPI_Type__c = kpiType;
            }
            if(!existingAccountKPIAch.isEmpty() && existingAccountKPIAch.containsKey(key)){
                accKpiAch.Id = existingAccountKPIAch.get(key);
            }
        }
        return accKpiAch;
    }
    public static double calculateActual(Account_KPI_Achievement__c accKpiAchievement){
        double actual = 0.0;
        actual = (accKpiAchievement.Actual_Numerator__c/accKpiAchievement.Total_Denominator__c)*100;
        return actual;    
    }
    //Method to calculate Total Activation Survey KPI
    public static void calcTotalAcvSrvyKPI(Id operatorId, Account_KPI_Achievement__c accKpiAchievement, Decimal outletResp, Map<String, Account_KPI_Achievement__c> accountKpiAchievementMap, Integer numberOfOutlets, Map<Id, Account> operatorMap)
    {
        if(accKpiAchievement!=null){
            Account_KPI_Achievement__c accKpiAchievementTotal;
            if(accountKpiAchievementMap.containsKey(operatorId)){
                accKpiAchievementTotal = accountKpiAchievementMap.get(operatorId);
                accKpiAchievementTotal.Actual_Numerator__c = accKpiAchievementTotal.Actual_Numerator__c + outletResp;
                accountKpiAchievementMap.put(operatorId,accKpiAchievementTotal);
            }
            else{
                accKpiAchievementTotal = createAccKpiAch(operatorId,null,numberOfOutlets,operatorMap.get(operatorId),null,'Total Activation');
            	accKpiAchievementTotal.Actual_Numerator__c = outletResp;
                accountKpiAchievementMap.put(operatorId,accKpiAchievementTotal);
            }
            if(accKpiAchievementTotal!=null){
                accKpiAchievementTotal.Actual__c = accKpiAchievementTotal.Actual_Numerator__c;
            }
            if(accKpiAchievement.Id!=null){
                if(!actKpiAchIds.contains(accKpiAchievement.Id) && existingAccountKPIAchMap.containsKey(accKpiAchievement.Id)){
                    targetDerived += existingAccountKPIAchMap.get(accKpiAchievement.Id).Target_Derived__c;
                    accKpiAchievementTotal.Target_Number__c = targetDerived;
                }
                actKpiAchIds.add(accKpiAchievement.Id);
            }
        }
    }
}