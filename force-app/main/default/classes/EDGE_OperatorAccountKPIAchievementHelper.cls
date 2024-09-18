/**********************************************************************
Name: EDGE_OperatorAccountKPIAchievementHelper

=======================================================================

History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0       Juned khan        29/09/2020        ES20-8505
***********************************************************************/
public with sharing class EDGE_OperatorAccountKPIAchievementHelper {
    
    public static void createAccountKPIAchievementWrapList(List<Account> listOFOperators){
        Set<Id> opIdsSet = new Set<Id>();
        Set<Id> pickupOptionIdsSet = new Set<Id>();
        Map<Id,String> pickupOptionMap = new Map<Id,String>();
        Map<Id,Account_KPI_Achievement__c> surveykpisMap = new Map<Id,Account_KPI_Achievement__c>();
        Map<Id,Account_KPI_Achievement__c> activationkpisMap = new Map<Id,Account_KPI_Achievement__c>();
        Map<Id,Account_KPI_Achievement__c> totalActivationkpisMap = new Map<Id,Account_KPI_Achievement__c>();
        List<Account> operatorToUpdate = new List<Account>();
        
        for(Account opRec : listOFOperators){
            opIdsSet.add(opRec.Id);
        }
        if(opIdsSet != null && opIdsSet.size()>0 && Schema.sObjectType.Account_KPI_Achievement__c.isAccessible()){
            for(Account_KPI_Achievement__c accKPIachiv : [SELECT Account__c,Achievement__c,Activation_Survey_KPI__c,Activation_Survey_KPI__r.Name,Actual_Numerator__c,Id,KPI_Type__c,Name,
                                                          Target_Derived__c,Target_Number__c,Target__c,Total_Denominator__c,Unique_Id__c,Actual__c 
                                                          FROM Account_KPI_Achievement__c WHERE Account__c IN :opIdsSet])
            {
                pickupOptionIdsSet.add(accKPIachiv.Activation_Survey_KPI__c);
                if(accKPIachiv.KPI_Type__c == 'Activation Survey KPI'){
                    activationkpisMap.put(accKPIachiv.Id,accKPIachiv);                                    
                } else if(accKPIachiv.KPI_Type__c == 'Survey KPI'){
                    surveykpisMap.put(accKPIachiv.Id,accKPIachiv);
                } else if(accKPIachiv.KPI_Type__c == 'Total Activation'){
                    totalActivationkpisMap.put(accKPIachiv.Id,accKPIachiv);
                }
            }
        }
        
        Map<Id, EDGE_OperatorKPIServiceWrapper> opToOutletsMap = new Map<Id, EDGE_OperatorKPIServiceWrapper>();
        
        if(totalActivationkpisMap != null){
            for(Account_KPI_Achievement__c totalActivationkpiRecd : totalActivationkpisMap.values()){
                EDGE_OperatorKPIServiceWrapper kpiServiceWrapper = new EDGE_OperatorKPIServiceWrapper();
                kpiServiceWrapper.TotalTarget = totalActivationkpiRecd.Target_Number__c;
                kpiServiceWrapper.TotalNumerator = totalActivationkpiRecd.Actual_Numerator__c;
                kpiServiceWrapper.TotalAchievement = totalActivationkpiRecd.Achievement__c;
                opToOutletsMap.put(totalActivationkpiRecd.Account__c,kpiServiceWrapper); 
            }
        }
        if(activationkpisMap != null){
            for(Account_KPI_Achievement__c activationkpiRecd : activationkpisMap.values()){
                EDGE_OperatorKPIServiceWrapper.EDGE_OperatorActivationkpisWrapper activationKPIWrap = new EDGE_OperatorKPIServiceWrapper.EDGE_OperatorActivationkpisWrapper();
                activationKPIWrap.Target = activationkpiRecd.Target__c;
                activationKPIWrap.TargetDerived = activationkpiRecd.Target_Derived__c;
                activationKPIWrap.TargetNumber = activationkpiRecd.Target_Number__c;
                activationKPIWrap.ActualNumerator = activationkpiRecd.Actual_Numerator__c;
                activationKPIWrap.Denominator = activationkpiRecd.Total_Denominator__c;
                activationKPIWrap.ActivationName = activationkpiRecd.Activation_Survey_KPI__r.Name;//pickupOptionMap.containsKey(activationkpiRecd.Activation_Survey_KPI__c) ? pickupOptionMap.get(activationkpiRecd.Activation_Survey_KPI__c): null;
                activationKPIWrap.Actual = activationkpiRecd.Actual__c;
                activationKPIWrap.Achievement = activationkpiRecd.Achievement__c;
                
                if(!opToOutletsMap.containsKey(activationkpiRecd.Account__c)){
                    EDGE_OperatorKPIServiceWrapper kpiServiceWrapper = new EDGE_OperatorKPIServiceWrapper();
                    kpiServiceWrapper.activationkpisList = new List<EDGE_OperatorKPIServiceWrapper.EDGE_OperatorActivationkpisWrapper>();
                    kpiServiceWrapper.activationkpisList.add(activationKPIWrap);
                    opToOutletsMap.put(activationkpiRecd.Account__c,kpiServiceWrapper);                    
                }else{
                    EDGE_OperatorKPIServiceWrapper kpiServiceWrapper = opToOutletsMap.get(activationkpiRecd.Account__c);
                    if(kpiServiceWrapper != null && kpiServiceWrapper.activationkpisList != null && kpiServiceWrapper.activationkpisList.size() >0){
                        kpiServiceWrapper.activationkpisList.add(activationKPIWrap);
                    }else if(kpiServiceWrapper != null && kpiServiceWrapper.activationkpisList == null){
                        kpiServiceWrapper.activationkpisList = new List<EDGE_OperatorKPIServiceWrapper.EDGE_OperatorActivationkpisWrapper>();
                        kpiServiceWrapper.activationkpisList.add(activationKPIWrap);
                        opToOutletsMap.put(activationkpiRecd.Account__c,kpiServiceWrapper);
                    }
                }
            }
        }
        if(surveykpisMap != null){
            for(Account_KPI_Achievement__c surveykpiRecd : surveykpisMap.values()){
                EDGE_OperatorKPIServiceWrapper.EDGE_OperatorSurveykpisWrapper surveykpiWrap = new EDGE_OperatorKPIServiceWrapper.EDGE_OperatorSurveykpisWrapper();
                surveykpiWrap.Target = surveykpiRecd.Target__c;
                surveykpiWrap.TargetDerived = surveykpiRecd.Target_Derived__c;
                surveykpiWrap.TargetNumber = surveykpiRecd.Target_Number__c;
                surveykpiWrap.ActualNumerator = surveykpiRecd.Actual_Numerator__c;
                surveykpiWrap.Denominator = surveykpiRecd.Total_Denominator__c;
                surveykpiWrap.SurveykpiName = surveykpiRecd.Activation_Survey_KPI__r.Name;//pickupOptionMap.containsKey(surveykpiRecd.Activation_Survey_KPI__c) ? pickupOptionMap.get(surveykpiRecd.Activation_Survey_KPI__c): null;
                surveykpiWrap.Actual = surveykpiRecd.Actual__c;
                surveykpiWrap.Achievement = surveykpiRecd.Achievement__c;
                
                if(!opToOutletsMap.containsKey(surveykpiRecd.Account__c)){
                    EDGE_OperatorKPIServiceWrapper kpiServiceWrapper = new EDGE_OperatorKPIServiceWrapper();
                    kpiServiceWrapper.surveykpiList = new List<EDGE_OperatorKPIServiceWrapper.EDGE_OperatorSurveykpisWrapper>();
                    kpiServiceWrapper.surveykpiList.add(surveykpiWrap);
                    opToOutletsMap.put(surveykpiRecd.Account__c,kpiServiceWrapper);
                    
                }else{
                    EDGE_OperatorKPIServiceWrapper kpiServiceWrapper = opToOutletsMap.get(surveykpiRecd.Account__c);
                    if(kpiServiceWrapper != null && kpiServiceWrapper.surveykpiList != null && kpiServiceWrapper.surveykpiList.size() >=0){
                        kpiServiceWrapper.surveykpiList.add(surveykpiWrap);
                    }else if(kpiServiceWrapper != null && kpiServiceWrapper.surveykpiList == null){
                        kpiServiceWrapper.surveykpiList = new List<EDGE_OperatorKPIServiceWrapper.EDGE_OperatorSurveykpisWrapper>();
                        kpiServiceWrapper.surveykpiList.add(surveykpiWrap);
                        opToOutletsMap.put(surveykpiRecd.Account__c,kpiServiceWrapper);
                    }
                }
            }
        }
        
        for(Id opId : opToOutletsMap.keySet()){
            EDGE_OperatorKPIServiceWrapper kpiServiceWrapper =  opToOutletsMap.get(opId);
            if(kpiServiceWrapper != null){
                String finalJSON =JSON.serialize(kpiServiceWrapper);
                Account operator = new Account(Id = opId);
                operator.Activation_Survey_KPI_List__c = finalJSON;
                operatorToUpdate.add(operator);
            }
        }
        if(operatorToUpdate.size() > 0){
            Database.update(operatorToUpdate);
        }
    }
}