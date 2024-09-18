/**
* @Name: EDGE_ManagerUserKpiAchievementHelper

* @Req: 
* 

* @History                                                            

* @VERSION     AUTHOR              DATE            DETAIL
*  1.0         Prasanth T          12/11/2021      ES20-10840
*  1.1         Anand Uppalapati    12/11/2021      ES20-11466
*  1.2		   Sudipta Nandi	   12/11/2021	   ES20-10648
**/

public class EDGE_ManagerUserKpiAchievementHelper {
    public final static String userKpiRecTypeId = KPI_Achivement__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('User KPI').getRecordTypeId();
    public final static String noOfVisits = EDGE_Constant.EDGE_NO_OF_VISITS;
    public final static String caseTaskVsSLA =EDGE_Constant.EDGE_CASETASK_SLA;
    public final static String caseTaskVsTotal = EDGE_Constant.EDGE_CASETASK_TOTAL;
    public final static String uniqueOutlets = EDGE_Constant.EDGE_UNIQUE_OUTLETS;  
    
    public static List<KPI_Achivement__c> managerKPIRollUp(List<KPI_Achivement__c> newKPIAchievementList,Id countryId){
        List<KPI_Achivement__c> noOfVisitsList= new List<KPI_Achivement__c>();
        List<KPI_Achivement__c> caseTaskSLAList= new List<KPI_Achivement__c>();
        List<KPI_Achivement__c> caseTaskTotalList= new List<KPI_Achivement__c>();
        List<KPI_Achivement__c> uniqueOutletsList= new List<KPI_Achivement__c>();
        Set<Id> usersFromNoofVisitsSet= new Set<Id>();
        Set<Id> usersFromCaseTaskSLASet= new Set<Id>();
        Set<Id> usersFromCaseTaskTotalSet= new Set<Id>();
        Set<Id> usersFromuniqueOutletsSet= new Set<Id>();
        Map<Id,Id> userManagerMap = new Map<Id,id>();
        Map<Id,List<KPI_Achivement__c>> managerKpiAchivNoofVisitsMap = new Map<Id,List<KPI_Achivement__c>>();
        Map<Id,List<KPI_Achivement__c>> managerKpiAchivSLAMap = new Map<Id,List<KPI_Achivement__c>>();
        Map<Id,List<KPI_Achivement__c>> managerKpiAchivTotalMap = new Map<Id,List<KPI_Achivement__c>>();
        Map<Id,List<KPI_Achivement__c>> managerKpiAchivUniqueOutletMap = new Map<Id,List<KPI_Achivement__c>>();
        Map<String,KPI_Achivement__c> managerKpiMap = new Map<String,KPI_Achivement__c>();
        Map<String,KPI_Achivement__c> keyManagerKpiMap = new Map<String,KPI_Achivement__c>();      
        List<KPI_Achivement__c> masterUpsertList = new List<KPI_Achivement__c>(); 
        List<String> kpiTypesList = new List<String>();
        String kpiTypesStr = Label.EDGE_ManagerUserKpiTypes;
        
        if(kpiTypesStr != null){
            kpiTypesList = kpiTypesStr.split(','); 
        }
        
        //Separating the newItems according to KPI Type
        if(newKPIAchievementList != null && newKPIAchievementList.Size()>0){
            for(KPI_Achivement__c kpiAchievement: newKPIAchievementList){
                if(kpiAchievement.KPI_Type__c == noOfVisits){
                    noOfVisitsList.add(kpiAchievement);
                    usersFromNoofVisitsSet.add(kpiAchievement.User__c);
                }
                else if(kpiAchievement.KPI_Type__c == caseTaskVsSLA ){
                    caseTaskSLAList.add(kpiAchievement);
                    usersFromCaseTaskSLASet.add(kpiAchievement.User__c);
                }
                else if(kpiAchievement.KPI_Type__c == caseTaskVsTotal){
                    caseTaskTotalList.add(kpiAchievement);
                    usersFromCaseTaskTotalSet.add(kpiAchievement.User__c);
                }
                else if(kpiAchievement.KPI_Type__c == uniqueOutlets){
                    uniqueOutletsList.add(kpiAchievement);
                    usersFromuniqueOutletsSet.add(kpiAchievement.User__c);
                }
            }
        }
        //User(Reps) to Manager Map
        if(usersFromCaseTaskSLASet != null && usersFromCaseTaskSLASet.Size()> 0 || usersFromCaseTaskTotalSet != null && usersFromCaseTaskTotalSet.Size()> 0 ||usersFromNoofVisitsSet != null && usersFromNoofVisitsSet.Size()> 0 || usersFromuniqueOutletsSet != null && usersFromuniqueOutletsSet.Size()> 0){
            for(User userObj:[SELECT Id,Name,ManagerId FROM User WHERE Id IN: usersFromCaseTaskSLASet OR Id IN: usersFromCaseTaskTotalSet OR Id IN: usersFromNoofVisitsSet OR Id IN: usersFromuniqueOutletsSet]){
                
                userManagerMap.put(userObj.Id,userObj.ManagerId);
            }
        }
        
        //Creation of existing manager kpi achievement records as managerKey to Manager KPI record Id Map
        for(KPI_Achivement__c managerKpiObj : [SELECT Id,Name,User__c,country__c,KPI_Type__c,Actual_Numerator_Aggregation_of_Reps__c, Total_Denominator_Aggregation_of_Reps__c, Actual_Aggregation_of_Reps__c 
                                               FROM KPI_Achivement__c
                                               WHERE User__c IN:userManagerMap.values() AND KPI_Type__c IN:kpiTypesList AND country__c=:countryId]){
                                                   
                                                   if(managerKpiObj.KPI_Type__c == NoOfVisits ){
                                                       string managerKpiRecordKey = managerKpiObj.User__c+ EDGE_Constant.EDGE_NO_OF_VISITS_KEY;
                                                       managerKpiMap.put(managerKpiRecordKey,managerKpiObj);
                                                   }else if(managerKpiObj.KPI_Type__c == CaseTaskVsSLA ){
                                                       string managerKpiSLARecordKey = managerKpiObj.User__c+ EDGE_Constant.EDGE_CASETASK_SLA_KEY;
                                                       managerKpiMap.put(managerKpiSLARecordKey,managerKpiObj);
                                                   }else if(managerKpiObj.KPI_Type__c == CaseTaskVsTotal){
                                                       string managerKpiTotalRecordKey = managerKpiObj.User__c+ EDGE_Constant.EDGE_CASETASK_TOTAL_KEY;
                                                       managerKpiMap.put(managerKpiTotalRecordKey,managerKpiObj);
                                                   }else if(managerKpiObj.KPI_Type__c == uniqueOutlets){
                                                       string managerKpiUniqueOutletsRecordKey = managerKpiObj.User__c+ EDGE_Constant.EDGE_UNIQUE_OUTLETS_KEY;
                                                       managerKpiMap.put(managerKpiUniqueOutletsRecordKey,managerKpiObj);
                                                   }
                                                   
                                                   
                                               }
        
        //Creation Or Update of Manager KPI Achievement Records for KPI TYPE No Of Visits
        if(noOfVisitsList != null && noOfVisitsList.size()>0 && usersFromNoofVisitsSet != null && usersFromNoofVisitsSet.size()>0 ){
            for(KPI_Achivement__c KpiObj:noOfVisitsList){
                if(usersFromNoofVisitsSet.contains(KpiObj.User__c)){
                    if(!managerKpiAchivNoofVisitsMap.ContainsKey(KpiObj.user__r.ManagerId)){
                        managerKpiAchivNoofVisitsMap.put(KpiObj.user__r.ManagerId, new List<KPI_Achivement__c>{KpiObj});
                    }
                    else{
                        managerKpiAchivNoofVisitsMap.get(KpiObj.user__r.ManagerId).add(KpiObj);
                    }
                    
                }
                
            }
        }
        if(managerKpiAchivNoofVisitsMap != null && managerKpiAchivNoofVisitsMap.Size()>0){
            keyManagerKpiMap.putAll(upsertMapCreation(managerKpiMap,managerKpiAchivNoofVisitsMap,countryId,noOfVisits));
        }
        
        //Creation Or Update of Manager KPI Achievement Records for KPI TYPE Case Task VS SLA
        if(caseTaskSLAList != null && caseTaskSLAList.Size()>0 && usersFromCaseTaskSLASet!= null && usersFromCaseTaskSLASet.Size()>0){
            for(KPI_Achivement__c KpiSLAObj:caseTaskSLAList){
                if(usersFromCaseTaskSLASet.contains(KpiSLAObj.User__c)){
                    if(!managerKpiAchivSLAMap.ContainsKey(KpiSLAObj.User__r.ManagerId)){
                        managerKpiAchivSLAMap.put(KpiSLAObj.User__r.ManagerId, new List<KPI_Achivement__c>{KpiSLAObj});
                    }
                    else{
                        managerKpiAchivSLAMap.get(KpiSLAObj.User__r.ManagerId).add(KpiSLAObj);
                    }
                    
                }
                
            }
        }        
        if(managerKpiAchivSLAMap != null && managerKpiAchivSLAMap.Size()>0){
            keyManagerKpiMap.putAll(upsertMapCreation(managerKpiMap,managerKpiAchivSLAMap,countryId,caseTaskVsSLA));
        }
        
        //Creation Or Update of Manager KPI Achievement Records for KPI TYPE Case Task VS Total
        if(caseTaskTotalList != null && caseTaskTotalList.Size()>0 && usersFromCaseTaskTotalSet!= null && usersFromCaseTaskTotalSet.Size()>0){
            for(KPI_Achivement__c KpiTotalObj:caseTaskTotalList){
                if(usersFromCaseTaskTotalSet.contains(KpiTotalObj.User__c)){
                    if(!managerKpiAchivTotalMap.ContainsKey(KpiTotalObj.User__r.ManagerId)){
                        managerKpiAchivTotalMap.put(KpiTotalObj.User__r.ManagerId, new List<KPI_Achivement__c>{KpiTotalObj});
                    }
                    else{
                        managerKpiAchivTotalMap.get(KpiTotalObj.User__r.ManagerId).add(KpiTotalObj);
                    }
                    
                }
                
            }
        }
        if(managerKpiAchivTotalMap != null && managerKpiAchivTotalMap.Size()>0){
            keyManagerKpiMap.putAll(upsertMapCreation(managerKpiMap,managerKpiAchivTotalMap,countryId,caseTaskVsTotal));
        }
        
        //Creation Or Update of Manager KPI Achievement Records for KPI TYPE Unique Outlets
        if(uniqueOutletsList != null && uniqueOutletsList.Size()>0 && usersFromuniqueOutletsSet!= null && usersFromuniqueOutletsSet.Size()>0){
            for(KPI_Achivement__c KpiTotalObj:uniqueOutletsList){
                if(usersFromuniqueOutletsSet.contains(KpiTotalObj.User__c)){
                    if(!managerKpiAchivUniqueOutletMap.ContainsKey(KpiTotalObj.User__r.ManagerId)){
                        managerKpiAchivUniqueOutletMap.put(KpiTotalObj.User__r.ManagerId, new List<KPI_Achivement__c>{KpiTotalObj});
                    }
                    else{
                        managerKpiAchivUniqueOutletMap.get(KpiTotalObj.User__r.ManagerId).add(KpiTotalObj);
                    }
                    
                }
                
            }
        }
        if(managerKpiAchivUniqueOutletMap != null && managerKpiAchivUniqueOutletMap.Size()>0){
            
            keyManagerKpiMap.putAll(upsertMapCreation(managerKpiMap,managerKpiAchivUniqueOutletMap,countryId,uniqueOutlets));
            
        }
        
        if(keyManagerKpiMap!= null && keyManagerKpiMap.Size()>0){
            masterUpsertList = keyManagerKpiMap.values();            
        }
        return masterUpsertList;
    }
    
    private static Map<String,KPI_Achivement__c> upsertMapCreation(Map<String,KPI_Achivement__c> managerKpiMap,Map<Id,List<KPI_Achivement__c>> managerKpiAchivMap,Id countryId,string kpiType){
        String managerKey;
        
        Map<String,KPI_Achivement__c> keyManagerKpiMap = new Map<String,KPI_Achivement__c>();
        if(managerKpiAchivMap != null && managerKpiAchivMap.Size()>0){
            List<KPI_Achivement__c> repKpiList = new List<KPI_Achivement__c>();
            
            for(Id managerId : managerKpiAchivMap.keyset()){
                Decimal totalActualNumerator = 0;
                Decimal totalDenominator = 0;
                if(managerKpiAchivMap.containskey(managerId)){
                    repKpiList = managerKpiAchivMap.get(managerId);
                }
                for(KPI_Achivement__c kpiRecords: repKpiList){
                    
                    if(kpiRecords.Actual_Numerator__c != null && totalActualNumerator >= 0){
                        totalActualNumerator = totalActualNumerator + kpiRecords.Actual_Numerator__c;
                    }
                    if((kpiRecords.KPI_Type__c == caseTaskVsSLA || kpiRecords.KPI_Type__c == caseTaskVsTotal ) && (kpiRecords.Total_Denominator__c != null && totalDenominator >= 0)){
                        totalDenominator = totalDenominator + kpiRecords.Total_Denominator__c;
                    }   
                }
                if(kpiType == noOfVisits){
                    managerKey = managerId+ EDGE_Constant.EDGE_NO_OF_VISITS_KEY;
                }else if(kpiType == caseTaskVsSLA){
                    managerKey = managerId+ EDGE_Constant.EDGE_CASETASK_SLA_KEY;
                }else if(kpiType == caseTaskVsTotal){
                    managerKey = managerId+ EDGE_Constant.EDGE_CASETASK_TOTAL_KEY;
                }else if(kpiType == uniqueOutlets){
                    managerKey = managerId+ EDGE_Constant.EDGE_UNIQUE_OUTLETS_KEY;
                }
                if(!managerKpiMap.containsKey(managerKey)){
                    KPI_Achivement__c kpiAchive = new KPI_Achivement__c();
                    kpiAchive.User__c = managerId;
                    kpiAchive.Country__c = countryId;
                    kpiAchive.RecordTypeId = userKpiRecTypeId;
                    kpiAchive.Actual_Numerator__c = 0;
                    kpiAchive.Total_Denominator__c = 0;
                    kpiAchive.Actual_Numerator_Aggregation_of_Reps__c = totalActualNumerator;
                    if(kpiType== uniqueOutlets || kpiType == noOfVisits){
                        kpiAchive.Actual_Aggregation_of_Reps__c = kpiAchive.Actual_Numerator_Aggregation_of_Reps__c;
                    }
                    else if(kpiType== caseTaskVsSLA || kpiType == caseTaskVsTotal){
                        kpiAchive.Total_Denominator_Aggregation_of_Reps__c=  totalDenominator ;
                        
                        if (kpiAchive.Total_Denominator_Aggregation_of_Reps__c != null && kpiAchive.Total_Denominator_Aggregation_of_Reps__c !=0){
                            kpiAchive.Actual_Aggregation_of_Reps__c = (totalActualNumerator*100/totalDenominator);
                        }else{
                            kpiAchive.Actual_Aggregation_of_Reps__c =0;
                        }
                    }
                    
                    kpiAchive.Achievement__c=0;
                    kpiAchive.KPI_Type__c = kpiType;
                    keyManagerKpiMap.put(managerKey,kpiAchive);
                }
                else{
                    KPI_Achivement__c existingKpiAchive = managerKpiMap.get(managerKey);
                    existingKpiAchive.Actual_Numerator_Aggregation_of_Reps__c = totalActualNumerator;
                    if(kpiType == uniqueOutlets || kpiType == noOfVisits){
                        existingKpiAchive.Actual_Aggregation_of_Reps__c = existingKpiAchive.Actual_Numerator_Aggregation_of_Reps__c;
                    }                            else if(kpiType == caseTaskVsSLA || kpiType == caseTaskVsTotal){
                        existingKpiAchive.Total_Denominator_Aggregation_of_Reps__c=  totalDenominator ;
                        
                        if (existingKpiAchive.Total_Denominator_Aggregation_of_Reps__c != null && existingKpiAchive.Total_Denominator_Aggregation_of_Reps__c !=0){
                            existingKpiAchive.Actual_Aggregation_of_Reps__c = (totalActualNumerator*100/totalDenominator);
                        }else{
                            existingKpiAchive.Actual_Aggregation_of_Reps__c =0;
                        }
                    }
                    
                    keyManagerKpiMap.put(managerKey,existingKpiAchive);
                }
            }
        }
        return keyManagerKpiMap;
    }
}