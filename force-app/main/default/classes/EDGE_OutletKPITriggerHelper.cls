/*
* @Name: EDGE_OutletKPITriggerHelper

* @Req: 
* @ES20-6944 : SFDC SOS Target update

* @History                                                            

* @VERSION   AUTHOR            DATE              DETAIL
1.0       Preyanka Ghosh	20/02/2020		  Initial Development
2.0		  Shahbaz Khan		20/02/2020		  method - populateAchievementField
3.0       Manikant p        16/04/2020        method - updatePendingForBatch
4.0       Amar Deep         16/04/2020        method - populateUniqueIdField
4.1		  Supriya Galinde   23/11/2021        method- updatePendingForBatch
5.0       Prasanth T		24/12/2021		  ES20-11803//To avoid duplicate ids to DML
6.0		  Wribhu Bose		21/03/2022		  ES20-12298; modified method updatePendingForBatch() for including AT
7.0       Shivam/Rajarshi   05/02/2022	      ES20-14005,ES20-13960
8.0		  Raghavendra		20/09/2023		  145738
*/
public with sharing class EDGE_OutletKPITriggerHelper {
    
    /*
* @Method  : updateOutletKPITargets
* @Purpose : This methods used to update SOS KPI Target fields in outlet from KPIs Target Object.
*/    
    public static void updateOutletKPITargets(List<Outlet_KPI_Achievement__c> newItems, Map<Id, SObject> oldItems){        
        Set<Id> territoryIdSet = new Set<Id>();
        Set<Id> setAccountId = new Set<Id>();
        Set<String> setSegment = new Set<String>();
        Set<String> setCategory = new Set<String>();
        List<Account> lstAccount = new List<Account>();
        List<KPIs_Target__c> kpiTargetList = new List<KPIs_Target__c>();
        Map<Id, Outlet_KPI_Achievement__c> mapOutletKPIAchv;
        
        if(oldItems != null){
            mapOutletKPIAchv = (Map<Id, Outlet_KPI_Achievement__c>) oldItems;
        }
        
        //Get Account Id to retrieve Account Details
        for(Outlet_KPI_Achievement__c outletKPI : newItems) {
            if(mapOutletKPIAchv.containsKey(outletKPI.Id) && outletKPI.Target__c != mapOutletKPIAchv.get(outletKPI.Id).Target__c){
                setAccountId.add(outletKPI.Outlet__c); 
                setCategory.add(outletKPI.Category__c);                
            }            
        }
        
        //Create Segment and Territory set 
        if(setAccountId != null && setAccountId.size()>0){
            //ES20-14005,ES20-13960
            for(Account accountObj : [SELECT Id, Primary_Sales_Territory__c,Country__c,Global_Channel__c, Global_Segment__c,Global_Sub_Segment__c FROM Account WHERE Id IN :setAccountId]){//145738 - added Country__c and Global_Channel__c
                territoryIdSet.add(accountObj.Primary_Sales_Territory__c);
                setSegment.add(accountObj.Global_Segment__c);
                lstAccount.add(accountObj);
            }
        }
        
        //Get the KPI target details
        if(territoryIdSet != null && Schema.sObjectType.KPIs_Target__c.isAccessible()&& territoryIdSet.size() > 0){
            //ES20-14005,ES20-13960
            kpiTargetList = [SELECT Id, Category__c, Segment__c,Sub_Segment__c, Target__c, Territory__c FROM KPIs_Target__c WHERE Territory__c IN :territoryIdSet AND Category__c IN :setCategory AND Segment__c =:setSegment];                    
            EDGE_KPITargetOperations.populateOutletKPIs(kpiTargetList, lstAccount, newItems);
        }            
    }
    
    /*
* @Method  : populateAchievementField
* @Purpose : This method is used to populate Achievement field in Outlet KPI Achievement
*/ 
    
    public static void populateAchievementField(List<Outlet_KPI_Achievement__c> newItems){
        for(Outlet_KPI_Achievement__c outKpiAch : newItems){
            if(outKpiAch.KPI_Type__c!=null && outKpiAch.KPI_Type__c =='SoS'){
                Decimal numerator = EDGE_UtilityClass.checkForNull(outKpiAch.Actual_Numerator__c);
                Decimal denominator = EDGE_UtilityClass.checkForNull(outKpiAch.Total_Denominator__c);
                outKpiAch.Achievement__c = denominator!=0 ? (numerator/denominator)*100 : 0;
            }
        }
    }
    
    /*
* @Method  : updatePendingForBatch
* @Purpose : This method used to enable the Pending for Batch field in territory and territory hierarchy when Date of Execution field changed
Enable pending of batch when there is change in Valid and Last Compliant Call date fields(ES20-11173)
*/  
    
    public static void updatePendingForBatch(List<Outlet_KPI_Achievement__c> newItems, Map<Id, SObject> oldItems){
        
        Set<Id> accountIdSet = new Set<Id>();
        Set<Id> outletKpiAchRecAlreadyExecutedSet = new Set<Id>();
        Map<Id, Outlet_KPI_Achievement__c>  oldOutletKpiAchvMap = (Map<Id,Outlet_KPI_Achievement__c>) oldItems;
        //ES20-11803
        Map<Id,Territory__c> territoryMap = new Map<Id,Territory__c>();
        Map<Id,Territory_Hierarchy__c> territoryHierarchyMap = new Map<Id,Territory_Hierarchy__c>();
        //ES20-11803
        List<Schema.FieldSetMember> fieldSetMemberList=SObjectType.Outlet_KPI_Achievement__c.FieldSets.Pending_For_Batch_Field_Set.getFields();
        
        //ES20-11173
        
        Map<Id,Id> terrHMap = new Map<Id,Id>();
        Map<Id, boolean> terrPendingBatchMap = new  Map<Id, boolean>();
        Map<Id,boolean> terrHiePendingBatchMap = new  Map<Id, boolean>();
        //Map<Id,boolean> actTerrHiePendingBatchMap = new  Map<Id, boolean>();
        //Map<Id,Id> actTerrHMap = new Map<Id,Id>();
        Map<Id,Territory_Hierarchy__c> actTerritoryHierarchyMap = new Map<Id,Territory_Hierarchy__c>();
        
        if(oldItems != Null){
            oldOutletKpiAchvMap = (Map<Id, Outlet_KPI_Achievement__c>) oldItems;
        }
        
        for(Outlet_KPI_Achievement__c outletKpiAchv : newItems){
            Outlet_KPI_Achievement__c oldOutletKpiAchRec = null;
            If(oldOutletKpiAchvMap != null){
                oldOutletKpiAchRec = oldOutletKpiAchvMap.get(outletKpiAchv.id);
                
            }
            for(Schema.FieldSetMember fsm : fieldSetMemberList){
                
                if(oldOutletKpiAchRec!=null){//Update scenario
                    if(!outletKpiAchRecAlreadyExecutedSet.contains(outletKpiAchv.id) 
                       && (outletKpiAchv.get(fsm.getFieldPath()) != oldOutletKpiAchRec.get(fsm.getFieldPath())))
                    {
                        if(outletKpiAchv.Outlet__c!=null){
                            accountIdSet.add(outletKpiAchv.Outlet__c);
                        }
                        outletKpiAchRecAlreadyExecutedSet.add(outletKpiAchv.Id);     
                    }
                }else{//Insert scenario
                    if(outletKpiAchv.get(fsm.getFieldPath()) != null){
                        if(outletKpiAchv.Outlet__c!=null){
                            accountIdSet.add(outletKpiAchv.Outlet__c);
                        }
                        outletKpiAchRecAlreadyExecutedSet.add(outletKpiAchv.Id);
                    }
                }
                
            }
        }
        //getting Territory id and Territory Hierarchy id putting it in the respective set
        if(Schema.sObjectType.Account.isAccessible() && accountIdSet != Null && accountIdSet.Size()> 0){
            for (Outlet_Territory__c oterr : [Select Id, Outlet__c, Territory__c,Territory__r.Region__c, 
                                              Territory__r.Pending_For_Batch__c,Territory__r.Region__r.Pending_For_Batch__c from Outlet_Territory__c 
                                              where Outlet__c IN :accountIdSet])
            {
                terrPendingBatchMap.put(oterr.Territory__c,oterr.Territory__r.Pending_For_Batch__c);//terr to peding batch map
                if(oterr.Territory__r.Region__c != null){
                    terrHiePendingBatchMap.put(oterr.Territory__r.Region__c, oterr.Territory__r.Region__r.Pending_For_Batch__c);
                    terrHMap.put(oterr.Territory__c,oterr.Territory__r.Region__c);//terr to terr hie map
                    // Removed for ES20-12298
                    //actTerrHiePendingBatchMap.put(oterr.Territory__r.Activation_Territory__c, oterr.Territory__r.Activation_Territory__r.Pending_For_Batch__c);
                    //actTerrHMap.put(oterr.Territory__c,oterr.Territory__r.Activation_Territory__c);//terr to act. terr hie map
                }                  
            }
        }
        
        if(terrPendingBatchMap != null && !terrPendingBatchMap.isEmpty()){
            for(Id terrId : terrPendingBatchMap.keySet()){
                Territory__c territoryObj = new Territory__c();
                territoryObj.Id = terrId;
                territoryObj.Pending_for_Batch__c = true;
                territoryMap.put(terrId,territoryObj);
                Id terrHieId = terrHMap.get(terrId);
                // Removed for ES20-12298
                //Id actTerrHieId = actTerrHMap.get(terrId);
                
                if(terrHieId != null && terrHiePendingBatchMap.get(terrHieId)== false){
                    Territory_Hierarchy__c territoryHierarchyObj = new Territory_Hierarchy__c();
                    territoryHierarchyObj.Id = terrHieId;
                    territoryHierarchyObj.Pending_for_Batch__c = true;
                    territoryHierarchyMap.put(terrHieId,territoryHierarchyObj);
                }//end of territory hierarchy
                
                // Removed for ES20-12298
                /*if(actTerrHieId != null && actTerrHiePendingBatchMap.get(actTerrHieId)== false){
                    Territory_Hierarchy__c actTerritoryHierarchyObj = new Territory_Hierarchy__c();
                    actTerritoryHierarchyObj.Id = actTerrHieId;
                    actTerritoryHierarchyObj.Pending_for_Batch__c = true;
                    actTerritoryHierarchyMap.put(actTerrHieId,actTerritoryHierarchyObj);
                }//end of Activation Territory*/
            }
            
        }//end of territory
        //updating the territory List
        List<Territory__c> territoryList = new List<Territory__c>();
        territoryList.addAll(territoryMap.values());
        if(Schema.sObjectType.Territory__c.isUpdateable() && territoryList != Null && territoryList.Size()>0){
            Database.update(territoryList); 
        }
        
        //updating the territory Hierarchy List from Territory
        List<Territory_Hierarchy__c> territoryHierarchyList = new List<Territory_Hierarchy__c>();
        territoryHierarchyList.addAll(territoryHierarchyMap.values());
        if(Schema.sObjectType.Territory_Hierarchy__c.isUpdateable() && territoryHierarchyList != Null && territoryHierarchyList.Size()>0){
            Database.update(territoryHierarchyList); 
        }
        //updating the territory Hierarchy List
        List<Territory_Hierarchy__c> actTerritoryHierarchyList = new List<Territory_Hierarchy__c>();
        actTerritoryHierarchyList.addAll(actTerritoryHierarchyMap.values());
        if(Schema.sObjectType.Territory_Hierarchy__c.isUpdateable() && actTerritoryHierarchyList != Null && actTerritoryHierarchyList.Size()>0){
            Database.update(actTerritoryHierarchyList); 
        }
        
        
    }
    
    
    
    /**
* @Method  : populateUniqueIdField
* @Purpose : This method is used to populate Unique Id field in Outlet KPI Achievement
*/ 
    
    public static void populateUniqueIdField(List<Outlet_KPI_Achievement__c> newItems){
        string unique = null;
        for(Outlet_KPI_Achievement__c outKpiAch : newItems){
            If(outKpiAch.KPI_Type__c == 'Volume'){
                unique = outKpiAch.Outlet__c;
                If(outKpiAch.KPI_Type__c != null){
                    unique += '_'+ outKpiAch.KPI_Type__c;
                }
                If(outKpiAch.Volume_Category__c != null){
                    unique += '_'+ outKpiAch.Volume_Category__c;
                }
                outKpiAch.Unique_Id__c = unique;
            }
            else If(outKpiAch.KPI_Type__c == 'SoS'){
                unique = outKpiAch.Outlet__c;
                If(outKpiAch.KPI_Type__c != null){
                    unique += '_'+ outKpiAch.KPI_Type__c;
                }
                If(outKpiAch.Category__c != null){
                    unique += '_'+ outKpiAch.Category__c;
                }
                outKpiAch.Unique_Id__c = unique;  
            }else If(outKpiAch.KPI_Type__c == 'Coverage for Sales'){
                unique = outKpiAch.Outlet__c;
                If(outKpiAch.KPI_Type__c != null){
                    unique += '_'+ outKpiAch.KPI_Type__c;
                }
                If(outKpiAch.Category__c != null){
                    unique += '_'+ outKpiAch.Category__c;
                }
                outKpiAch.Unique_Id__c = unique;  
            }else If(outKpiAch.KPI_Type__c == 'Coverage for Quality'){
                unique = outKpiAch.Outlet__c;
                If(outKpiAch.KPI_Type__c != null){
                    unique += '_'+ outKpiAch.KPI_Type__c;
                }
                If(outKpiAch.Category__c != null){
                    unique += '_'+ outKpiAch.Category__c;
                }
                outKpiAch.Unique_Id__c = unique;  
            }else If(outKpiAch.KPI_Type__c == 'Coverage for Activation Specialist'){
                unique = outKpiAch.Outlet__c;
                If(outKpiAch.KPI_Type__c != null){
                    unique += '_'+ outKpiAch.KPI_Type__c;
                }
                If(outKpiAch.Category__c != null){
                    unique += '_'+ outKpiAch.Category__c;
                }
                outKpiAch.Unique_Id__c = unique;  
            }
        }
    }  
}