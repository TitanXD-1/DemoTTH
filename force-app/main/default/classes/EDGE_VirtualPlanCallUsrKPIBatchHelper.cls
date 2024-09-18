/**
* @Name: EDGE_VirtualPlanCallUsrKPIBatchHelper

* @Req: Helper class for EDGE_VirtualPlanCallCompUserKPIBatch

* @History                                                            

* @VERSION     AUTHOR              		DATE            DETAIL
*  1.0         Aparajita,Rajarshi      25/05/2022	    ES20-12716,ES20-12717,ES20-12900
*  2.0		   Rajarshi Lahiri		   09/06/2022		ES20-12745
*  3.0         Rajarshi Lahiri		   14/06/2022		ES20-12983
*  4.0         Mayukh SRoy             26/10/2022       ES20-13391
*  4.0         Mayukh SRoy             26/12/2022       ES20-13692 - UAT_Virtual Call getting calculated based on month in User KPI
*  5.0         Mayukh SRoy             12/01/2023       ES20-13717
**/
public with sharing class EDGE_VirtualPlanCallUsrKPIBatchHelper {

    
    public final static String USERKPIRECTYPEID = KPI_Achivement__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('User KPI').getRecordTypeId();
    public final static String PLANCALLCOMPLIANCE = 'Plan Call Compliance';
    public final static String VIRTUALCALLCOMPLIANCE ='Virtual Call Compliance';
    public final static String PLANCALLCOMPLIANCEKEY ='_Plan_Call_Compliance';
	public final static String VIRTUALCALLCOMPLIANCEKEY ='_Virtual_Call_Compliance';    
      /*
* @description: updateCount - Method to count the no. of completed planned calls, virtual calls and total calls
* @parameters: Set<Call__c> callSet, EDGE_CallUserKPIWrapper usrCall,Datetime actvMarketCycleStartDate, Datetime actvMarketCycleEndDate
* @returns: EDGE_CallUserKPIWrapper
**/
    
    public static EDGE_CallUserKPIWrapper updateCount(Set<Call__c> callSet, EDGE_CallUserKPIWrapper usrCall,Datetime actvMarketCycleStartDate, Datetime actvMarketCycleEndDate){
        
        for(Call__c call: callSet){
            
            //Virtual Call block
            if(call.Status__c=='Completed' && call.Call_duration_compliance__c && call.Type_of_Call__c != null
               && call.Type_of_Call__r.Global_Equivalent_Call_Type__c=='Virtual'&& 
             /*(call.End_Date__c != null && call.End_Date__c.month() == date.today().month() && call.End_Date__c.year() == date.today().year())*/
               (call.End_Date__c != null && call.End_Date__c.Date() >= actvMarketCycleStartDate && call.End_Date__c.Date() <= actvMarketCycleEndDate) //ES20-13391,ES20-13692 //ES20-13717 - Added Date in EndDate 
              )
            {
                if((call.Account__r.Record_Type_Name__c=='Prospect' && call.Account__r.Status__c!=null) || (call.Account__r.Record_Type_Name__c=='Outlet' && (call.Account__r.Status__c=='Active' || call.Account__r.Status__c=='Temporarily Closed'))){
                    if(usrCall.noOfVirtualCalls == null){
                    usrCall.noOfVirtualCalls = 1;
                }else{
                    usrCall.noOfVirtualCalls = usrCall.noOfVirtualCalls + 1;
                }
               }
                   
            }
			//Planned Call block
            if(call.callPlanned__c==True){
                
                if((call.Account__r.Record_Type_Name__c=='Prospect' && call.Account__r.Status__c!=null) || (call.Account__r.Record_Type_Name__c=='Outlet' && call.Account__r.Status__c=='Active')){
                    if(usrCall.totalNumPlanCalls == null){
                        usrCall.totalNumPlanCalls = 1;
                    }else{
                        usrCall.totalNumPlanCalls = usrCall.totalNumPlanCalls+1;
                    }       
                    if(call.Status__c=='Completed' && call.Assigned_To__c==call.Call_Performed_By__c 
                       && call.End_Date__c!=null && (call.End_Date__c.Date()>=actvMarketCycleStartDate) 
                       && (call.End_Date__c.Date()<=actvMarketCycleEndDate))
                    {
                        if(usrCall.noOfCompPlanCalls == null){
                            usrCall.noOfCompPlanCalls = 1;
                        }else{
                            usrCall.noOfCompPlanCalls = usrCall.noOfCompPlanCalls+1;
                        }       
                    }
                }
                
            }
        }
        return usrCall;
    }
    
  /*
* @description: managerKPIRollUp - Used to calculate Manager User KPI for planned and Virtual Call Compliance and returns a list of KPI Achievement records of Managers to be upserted - ES20-12745
* @parameters: List<KPI_Achivement__c> newKPIAchievementList,Id countryId,Map<Id,AggregateResult> mgrToRepCountMap
* @returns: List<KPI_Achivement__c>
**/
    public static List<KPI_Achivement__c> managerKPIRollUp(List<KPI_Achivement__c> newKPIAchievementList,Id countryId,Map<Id,AggregateResult> mgrToRepCountMap){
        List<KPI_Achivement__c> planCallList= new List<KPI_Achivement__c>();
        List<KPI_Achivement__c> virtualCallList= new List<KPI_Achivement__c>();
        Set<Id> usersFromPlanCallSet= new Set<Id>();
        Set<Id> usersFromVirtualCallSet= new Set<Id>();
        Map<Id,Id> userManagerMap = new Map<Id,id>();
        Map<Id,List<KPI_Achivement__c>> managerKpiAchivPlanCallMap = new Map<Id,List<KPI_Achivement__c>>();
        Map<Id,List<KPI_Achivement__c>> managerKpiVirtualCallMap = new Map<Id,List<KPI_Achivement__c>>();
        Map<String,KPI_Achivement__c> managerKpiMap = new Map<String,KPI_Achivement__c>();
        Map<String,KPI_Achivement__c> keyManagerKpiMap = new Map<String,KPI_Achivement__c>();      
        List<KPI_Achivement__c> masterUpsertList = new List<KPI_Achivement__c>(); 
        List<String> kpiTypesList = new List<String>();
        String kpiTypesStr = Label.EDGE_UserKPITypes;
        
        if(kpiTypesStr != null){
            kpiTypesList = kpiTypesStr.split(','); 
        }
        
        //Separating the newItems according to KPI Type
        if(newKPIAchievementList != null && newKPIAchievementList.Size()>0){
            for(KPI_Achivement__c kpiAchievement: newKPIAchievementList){
                if(kpiAchievement.KPI_Type__c == PLANCALLCOMPLIANCE){
                    planCallList.add(kpiAchievement);
                    usersFromPlanCallSet.add(kpiAchievement.User__c);
                }
                else if(kpiAchievement.KPI_Type__c == VIRTUALCALLCOMPLIANCE ){
                    virtualCallList.add(kpiAchievement);
                    usersFromVirtualCallSet.add(kpiAchievement.User__c);
                }
            }
        }
        //User(Reps) to Manager Map
        if(usersFromPlanCallSet != null && usersFromPlanCallSet.Size()> 0 || usersFromVirtualCallSet != null && usersFromVirtualCallSet.Size()> 0){
            for(User userObj:[SELECT Id,Name,ManagerId FROM User WHERE (Id IN: usersFromPlanCallSet OR Id IN: usersFromVirtualCallSet) AND ManagerId!=null WITH SECURITY_ENFORCED]){
                
                userManagerMap.put(userObj.Id,userObj.ManagerId);
            }
        }

        //Creation of existing manager kpi achievement records as managerKey to Manager KPI record Id Map
        for(KPI_Achivement__c managerKpiObj : [SELECT Id,Name,User__c,country__c,KPI_Type__c,Actual_Numerator__c,Total_Denominator__c,LastModifiedDate,Manager_Count_Reset__c  
                                               FROM KPI_Achivement__c
                                               WHERE User__c IN:userManagerMap.values() AND KPI_Type__c IN:kpiTypesList AND country__c=:countryId]){
                                                   
                                                   if(managerKpiObj.KPI_Type__c == PLANCALLCOMPLIANCE ){
                                                       string managerKpiPlanRecordKey = managerKpiObj.User__c+ PLANCALLCOMPLIANCEKEY;
                                                       managerKpiMap.put(managerKpiPlanRecordKey,managerKpiObj);
                                                   }else if(managerKpiObj.KPI_Type__c == VIRTUALCALLCOMPLIANCE ){
                                                       string managerKpiVirtualRecordKey = managerKpiObj.User__c+ VIRTUALCALLCOMPLIANCEKEY;
                                                       managerKpiMap.put(managerKpiVirtualRecordKey,managerKpiObj);
                                                   }
                                                   
                                                   
                                               }
        
        
        //Creation Or Update of Manager KPI Achievement Records for KPI TYPE Plan Call Compliance
        if(planCallList !=null && planCallList.Size()>0 && usersFromPlanCallSet!= null && usersFromPlanCallSet.Size()>0){
            for(KPI_Achivement__c kpiPlanObj:planCallList){
                if(usersFromPlanCallSet.contains(kpiPlanObj.User__c) && kpiPlanObj.User__r.ManagerId!=null){
                    if(!managerKpiAchivPlanCallMap.ContainsKey(kpiPlanObj.User__r.ManagerId)){
                        managerKpiAchivPlanCallMap.put(kpiPlanObj.User__r.ManagerId, new List<KPI_Achivement__c>{kpiPlanObj});
                    }
                    else{
                        managerKpiAchivPlanCallMap.get(kpiPlanObj.User__r.ManagerId).add(kpiPlanObj);
                    }
                    
                }
                
            }
        }

        if(managerKpiAchivPlanCallMap != null && managerKpiAchivPlanCallMap.Size()>0){
            keyManagerKpiMap.putAll(upsertMapCreation(managerKpiMap,managerKpiAchivPlanCallMap,countryId,PLANCALLCOMPLIANCE,mgrToRepCountMap));
        }
        
        //Creation Or Update of Manager KPI Achievement Records for KPI TYPE Virtual Call Compliance
        if(virtualCallList != null && virtualCallList.Size()>0 && usersFromVirtualCallSet!= null && usersFromVirtualCallSet.Size()>0){
            for(KPI_Achivement__c kpiVirtualObj:virtualCallList){
                if(usersFromVirtualCallSet.contains(kpiVirtualObj.User__c)&& kpiVirtualObj.User__r.ManagerId!=null){
                    if(!managerKpiVirtualCallMap.ContainsKey(kpiVirtualObj.User__r.ManagerId)){
                        managerKpiVirtualCallMap.put(kpiVirtualObj.User__r.ManagerId, new List<KPI_Achivement__c>{kpiVirtualObj});
                    }
                    else{
                        managerKpiVirtualCallMap.get(kpiVirtualObj.User__r.ManagerId).add(kpiVirtualObj);
                    }
                    
                }
                
            }
        }

        if(managerKpiVirtualCallMap != null && managerKpiVirtualCallMap.Size()>0){
            
            keyManagerKpiMap.putAll(upsertMapCreation(managerKpiMap,managerKpiVirtualCallMap,countryId,VIRTUALCALLCOMPLIANCE,mgrToRepCountMap));
            
        }
        
        if(keyManagerKpiMap!= null && keyManagerKpiMap.Size()>0){
            masterUpsertList = keyManagerKpiMap.values();            
        }
        System.debug(LoggingLevel.DEBUG,'@@masterUpsertList'+masterUpsertList);
        return masterUpsertList;
    }
    /*
* @description: upsertMapCreation - Used to calculate Manager User KPI for planned and Virtual Call Compliance and prepare a map of KPI Achievement records of Managers as keys to be upserted - ES20-12745
* @parameters: Map<String,KPI_Achivement__c> managerKpiMap,Map<Id,List<KPI_Achivement__c>> managerKpiAchivMap,Id countryId,string kpiType,Map<Id,AggregateResult> mgrToRepCountMap
* @returns: Map<String,KPI_Achivement__c>
**/
    private static Map<String,KPI_Achivement__c> upsertMapCreation(Map<String,KPI_Achivement__c> managerKpiMap,Map<Id,List<KPI_Achivement__c>> managerKpiAchivMap,Id countryId,string kpiType,Map<Id,AggregateResult> mgrToRepCountMap){
        String managerKey;
        
        Map<String,KPI_Achivement__c> keyManagerKpiMap = new Map<String,KPI_Achivement__c>();
        if(managerKpiAchivMap != null && managerKpiAchivMap.Size()>0){
            List<KPI_Achivement__c> repKpiList = new List<KPI_Achivement__c>();
            
            for(Id managerId : managerKpiAchivMap.keyset()){
                Decimal totalActualNumerator = 0;
                Decimal totalDenominator = 0;
                Decimal repCount=0;
                if(managerKpiAchivMap.containskey(managerId)){
                    repKpiList = managerKpiAchivMap.get(managerId);
                    repCount=(Decimal)mgrToRepCountMap.get(managerId).get('repcount');//for denominator of Virtual Call KPI
                }
                for(KPI_Achivement__c kpiRecords: repKpiList){
                    
                    if(kpiRecords.Actual_Numerator__c != null && totalActualNumerator >= 0){
                        totalActualNumerator = totalActualNumerator + kpiRecords.Actual_Numerator__c;
                    }
                    if(kpiRecords.KPI_Type__c == PLANCALLCOMPLIANCE && kpiRecords.Total_Denominator__c != null && totalDenominator >= 0){
                        totalDenominator = totalDenominator + kpiRecords.Total_Denominator__c;
                    }   
                }
                if(kpiType == PLANCALLCOMPLIANCE){
                    managerKey = managerId+ PLANCALLCOMPLIANCEKEY;
                }else if(kpiType == VIRTUALCALLCOMPLIANCE){
                    managerKey = managerId+ VIRTUALCALLCOMPLIANCEKEY;
                }
                if(!managerKpiMap.containsKey(managerKey)){//Creating new KPI Achievement records
                    KPI_Achivement__c kpiAchive = new KPI_Achivement__c();
                    kpiAchive.User__c = managerId;
                    kpiAchive.Country__c = countryId;
                    kpiAchive.RecordTypeId = USERKPIRECTYPEID;
                    kpiAchive.Actual_Numerator__c = totalActualNumerator;
                    if(kpiType == PLANCALLCOMPLIANCE){
                        kpiAchive.Total_Denominator__c = totalDenominator;
                        kpiAchive.Achievement__c=kpiAchive.Total_Denominator__c>0?(kpiAchive.Actual_Numerator__c*100/kpiAchive.Total_Denominator__c):0;//ES20-12983
                    }
                    else{
                        kpiAchive.Total_Denominator__c =repCount;
                    	kpiAchive.Achievement__c=kpiAchive.Total_Denominator__c>0?(kpiAchive.Actual_Numerator__c/kpiAchive.Total_Denominator__c):0;//ES20-12983
                    }
                    kpiAchive.KPI_Type__c = kpiType;
                    keyManagerKpiMap.put(managerKey,kpiAchive);
                }
                else{//Updating existing KPI Achievement records of Managers
                    KPI_Achivement__c existingKpiAchive = managerKpiMap.get(managerKey);
                    
                    if(!existingKpiAchive.Manager_Count_Reset__c){//Does not contain Manager's contribution in KPI
                        existingKpiAchive.Actual_Numerator__c = totalActualNumerator; 
                        if(kpiType == PLANCALLCOMPLIANCE){
                            existingKpiAchive.Total_Denominator__c = totalDenominator;
                            existingKpiAchive.Achievement__c=existingKpiAchive.Total_Denominator__c>0?(existingKpiAchive.Actual_Numerator__c*100/existingKpiAchive.Total_Denominator__c):0;//ES20-12983
                        }
                        else{
                            existingKpiAchive.Total_Denominator__c =repCount;
                            existingKpiAchive.Achievement__c=existingKpiAchive.Total_Denominator__c>0?(existingKpiAchive.Actual_Numerator__c/existingKpiAchive.Total_Denominator__c):0;//ES20-12983
                        }
                    }
                    else{//Contains Manager's contribution in KPI so adding Reps contribution as well
                        Decimal existingNumerator=existingKpiAchive.Actual_Numerator__c;
                        Decimal existingDenominator = existingKpiAchive.Total_Denominator__c;
                        existingKpiAchive.Actual_Numerator__c = existingNumerator+totalActualNumerator;
                        System.debug(LoggingLevel.DEBUG,'@@KPIType'+kpiType);
                        if(kpiType == PLANCALLCOMPLIANCE){
                            existingKpiAchive.Total_Denominator__c =existingDenominator+totalDenominator;
                            existingKpiAchive.Achievement__c=existingKpiAchive.Total_Denominator__c>0?(existingKpiAchive.Actual_Numerator__c*100/existingKpiAchive.Total_Denominator__c):0;//ES20-12983
                        }
                        else{
                            existingKpiAchive.Total_Denominator__c =repCount;
                            existingKpiAchive.Achievement__c=existingKpiAchive.Total_Denominator__c>0?(existingKpiAchive.Actual_Numerator__c/existingKpiAchive.Total_Denominator__c):0;//ES20-12983
                        }
                        existingKpiAchive.Manager_Count_Reset__c=false;
                    }
                    
                    keyManagerKpiMap.put(managerKey,existingKpiAchive);
                }
            }
        }
        return keyManagerKpiMap;
    }
}