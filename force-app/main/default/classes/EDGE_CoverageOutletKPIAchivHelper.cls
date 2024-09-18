/**
* @Name: EDGE_CoverageOutletKPIAchivHelper
* @Req:  
* @History                                                            
* @VERSION     AUTHOR              DATE            DETAIL
*  1.0         Prasanth T       26/11/2021      ES20-10678
*  2.0         Prasanth T		24/12/2021		ES20-11803
*  3.0         Anand U          24/02/2022      ES20-12280(assignTerritorytoOKA)
*  4.0		   Swaraj Samanta   26/05/2022		ES20-12675
*  5.0         Swaraj Samanta   18/07/2022      ES20-13150
**/
public class EDGE_CoverageOutletKPIAchivHelper {
    
    final static String SALES_KPI_TYPE= EDGE_Constant.SALES_KPI_TYPE ;
    final static String QUALITY_KPI_TYPE= EDGE_Constant.QUALITY_KPI_TYPE;
    final static String ACTIVATION_KPI_TYPE = EDGE_Constant.ACTIVATION_KPI_TYPE;
    final static String COVERAGE_COMPLIANCE_STR = EDGE_Constant.COVERAGE_COMPLIANCE_STR;
    
    public static List<Outlet_KPI_Achievement__c> coverageComplianceOutletKPIMethod(List<Call__c> callsList, String countryCode){
        
        List<String> outletKPITypeList = new List<String>();
        Set<Id> callTypeSet = new Set<Id>();
        Set<Id> accountIdSet = new Set<Id>();
        Set<Id> performedbySet = new Set<Id>();
        Map<String,Market_Cycle__c> marketCycleMap = new Map<String,Market_Cycle__c>();
        Map<String,Outlet_KPI_Achievement__c> keyExistingOutletKpiMap = new Map<String,Outlet_KPI_Achievement__c>();
        Map<String,String> callTypeKpiActiveMap = new Map<String,String>();
        Map<Id,List<Id>> territoryAccountMap = new Map<Id,List<Id>>();
        Map<Id,Id> userTerritoryMap = new Map<Id,Id>();
        Map<String,Outlet_KPI_Achievement__c> keyOutletKPIMap = new Map<String,Outlet_KPI_Achievement__c>();
        List<Outlet_KPI_Achievement__c> outletKPIReturnList = new List<Outlet_KPI_Achievement__c>();
        
        outletKPITypeList.add(SALES_KPI_TYPE);
        outletKPITypeList.add(QUALITY_KPI_TYPE);
        outletKPITypeList.add(ACTIVATION_KPI_TYPE);
        
        //Market Cycle Map for Country
        if(Schema.SObjectType.Market_Cycle__c.isAccessible()){
            for(Market_Cycle__c marketCycle : [SELECT Id, Geography__r.Code__c, Start_Date__c, End_Date__c 
                                               FROM Market_Cycle__c 
                                               WHERE Geography__r.Code__c =:countryCode and Active__c = TRUE])
            {
                
                marketCycleMap.put(marketCycle.Geography__r.Code__c, marketCycle);
            }
        }
        //collecting Call type , Account Id, Performed By User
        if(callsList != null && callsList.size()>0){
            for(Call__c callObj : callsList){
                
                if(callObj.Type_of_Call__c != null){
                    callTypeSet.add(callObj.Type_of_Call__c);
                }
                accountIdSet.add(callObj.Account__c);
                if(callObj.Call_Performed_By__c != null){
                    performedbySet.add(callObj.Call_Performed_By__c);
                }
            }
        }
      
        //Existing Outlet KPI Achievement Records
        if(accountIdSet != null && accountIdSet.size()>0 && outletKPITypeList != null && outletKPITypeList.size()>0){
            for(Outlet_KPI_Achievement__c outletKPIobj: [SELECT Id,Unique_Id__c,Valid__c,Territory__c,Outlet__c,
                                                         Last_Compliant_Call_Date__c,
                                                         KPI_Type__c
                                                         FROM Outlet_KPI_Achievement__c
                                                         WHERE Outlet__c IN :accountIdSet
                                                         AND KPI_Type__c IN :outletKPITypeList])
            {
                keyExistingOutletKpiMap.put(outletKPIobj.Unique_Id__c, outletKPIobj);   
            }
        }
        //Calltype and KPI Actives Map
        if(callTypeSet != null && callTypeSet.size()>0){
            for(Role_Call__c roleCallObj: [SELECT Id,Name,Business_Role__c,Call_Type__c,KPIs_Active__c 
                                           FROM Role_Call__c 
                                           WHERE Call_Type__c IN:callTypeSet])
            {
                if(roleCallObj.KPIs_Active__c != null){
                    //ES20-11803
                    callTypeKpiActiveMap.put(roleCallObj.Call_Type__c+'_'+roleCallObj.Business_Role__c,roleCallObj.KPIs_Active__c);
                }
            }
        }
         List<String> outletStatus = new List<String>{EDGE_Constant.ACTIVE,EDGE_Constant.TEMPORARILYCLOSED};//ES20-12675
        //Creating a Territory to List of Accounts Map
        if(accountIdSet != null && accountIdSet.size()>0){
            for(Outlet_Territory__c outletObj: [SELECT Id,Territory__c,Territory__r.RecordTypeId,Outlet__c 
                                                FROM Outlet_Territory__c WHERE Outlet__c IN :accountIdSet 
                                                AND Outlet__r.Status__c IN:outletStatus])
            {
                if(!territoryAccountMap.containsKey(outletObj.Territory__c)){
                    territoryAccountMap.put(outletObj.Territory__c,new List<Id>{outletObj.Outlet__c});
                }else{
                    territoryAccountMap.get(outletObj.Territory__c).add(outletObj.Outlet__c);
                }
            }
        }
        //Primary Users to Territory Map
        if(performedbySet != null && performedbySet.size()>0){
            Date currentDate=System.today();
            for(Territory_Member__c terMemberObj: [SELECT Id,Territory__c,User__c,Type__c,End_Date__c FROM Territory_Member__c 
                                                   WHERE User__c IN:performedbySet AND Type__c ='Primary' and (End_Date__c =null or End_Date__c >= :currentDate)])
            {
                userTerritoryMap.put(terMemberObj.User__c,terMemberObj.Territory__c); 
            }
        }
        //Creation of New Outlet KPI Achievement records.
        if(callsList != null && callsList.size()>0){
            for(Call__c callObj : callsList){
                if(callObj.End_Date__c <= marketCycleMap.get(countryCode).End_Date__c){
                    String kpiType='';
                    //ES20-11803
                    String callTypeKey = callObj.Type_of_Call__c+'_'+callObj.Call_Performed_By__r.Business_Role_Id__c;
                    String kpisActive = callTypeKpiActiveMap.get(callTypeKey);
                    List<String> kpisActiveList = new List<String>();
                    if(kpisActive != null){
                        kpisActiveList = kpisActive.split(';');
                    }
                   
                    if(kpisActiveList.contains(COVERAGE_COMPLIANCE_STR)){
                        if(callObj.Call_Performed_By__r.Profile.Name=='Sales Representative'){
                            kpiType = SALES_KPI_TYPE;
                        }
                        else if(callObj.Call_Performed_By__r.Profile.Name=='Distributor Sales Representative'){
                            kpiType = SALES_KPI_TYPE;
                        }
                        else if(callObj.Call_Performed_By__r.Profile.Name=='Quality Representative'){
                            kpiType = QUALITY_KPI_TYPE;
                        }
                        else if(callObj.Call_Performed_By__r.Profile.Name=='Activation Specialist'){
                            kpiType = ACTIVATION_KPI_TYPE;   
                        }
                       
                        String uniqueKey = callObj.Account__c +'_'+kpiType;
                        // To Check if Outlet Kpi Achievement record already exists
                        if(!keyExistingOutletKpiMap.containsKey(uniquekey)){
                            //Check if two calls has outlet then territory and Latest of last compliance date has to be picked
                            if(keyOutletKPIMap.containsKey(uniqueKey)){
                                Outlet_KPI_Achievement__c secondaryOutletKPIobj = keyOutletKPIMap.get(uniqueKey);
                                if(secondaryOutletKPIobj.Last_Compliant_Call_Date__c < callObj.End_Date__c ){
                                    secondaryOutletKPIobj.Last_Compliant_Call_Date__c = date.newinstance(callObj.End_Date__c.year(), callObj.End_Date__c.month(), callObj.End_Date__c.day());
                                }
                                assignTerritorytoOKA(secondaryOutletKPIobj.KPI_Type__c,uniqueKey,callObj,secondaryOutletKPIobj,territoryAccountMap,userTerritoryMap,keyOutletKPIMap);
                            }  //Creation of new Outlet KPI records
                            else{
                                Outlet_KPI_Achievement__c primaryOutletKPIobj = createOutletKpiRecords(callObj.Account__c,kpiType);
                                primaryOutletKPIobj.Last_Compliant_Call_Date__c = date.newinstance(callObj.End_Date__c.year(), callObj.End_Date__c.month(), callObj.End_Date__c.day());                                
                                assignTerritorytoOKA(kpiType,uniqueKey,callObj,primaryOutletKPIobj,territoryAccountMap,userTerritoryMap,keyOutletKPIMap);
                            }
                        }//Update scenario to update Last Compliance Date
                        else{
                            Outlet_KPI_Achievement__c existingOutletKPIobj = keyExistingOutletKpiMap.get(uniquekey);
                            if(existingOutletKPIobj.Last_Compliant_Call_Date__c < callObj.End_Date__c){
                                existingOutletKPIobj.Last_Compliant_Call_Date__c = date.newinstance(callObj.End_Date__c.year(), callObj.End_Date__c.month(), callObj.End_Date__c.day());
                            }
                            keyOutletKPIMap.put(uniquekey,existingOutletKPIobj);
                        }                                    
                    }
                } 
            }
        }
        if(keyOutletKPIMap != null && keyOutletKPIMap.Size()>0){
            outletKPIReturnList = keyOutletKPIMap.values();
        }
        return outletKPIReturnList;
    }
    /**
* @description : assignTerritorytoOKA - Creates a new Outlet KPI Achievement Records
* @return : Void
* @param : OutletId,KPIType
*/
    public static Outlet_KPI_Achievement__c createOutletKpiRecords(Id outletId,String kpiType){
        Outlet_KPI_Achievement__c outletKPIobj = new Outlet_KPI_Achievement__c();
        outletKPIobj.Outlet__c= outletId;
        outletKPIobj.Valid__c= True;
        outletKPIobj.KPI_Type__c= kpiType;
        return outletKPIobj;             
    }
    /**
* @description : assignTerritorytoOKA - Assigns the Territory Id to Territory Field of Outlet KPI Achievement Record
* @return : Void
* @param : KPIType,UniqueKey,Callobj,Outlet_KPI_Achievement__c,Map<Id,List<Id>>,Map<String,Outlet_KPI_Achievement__c>
*/
    public static void assignTerritorytoOKA(String KpiType,String uniquekey,Call__c callObj,Outlet_KPI_Achievement__c primaryOutletKPIobj,Map<Id,List<Id>> territoryAccountMap,Map<Id,Id> userTerritoryMap,Map<String,Outlet_KPI_Achievement__c> keyOutletKPIMap){
        //Added Activation KPI type Check ES20-12280
        if(kpiType == SALES_KPI_TYPE ||  kpiType == QUALITY_KPI_TYPE || kpiType == ACTIVATION_KPI_TYPE){
            if(userTerritoryMap.containskey(callObj.Call_Performed_By__c)){
                if(territoryAccountMap.containskey(userTerritoryMap.get(callObj.Call_Performed_By__c))){
                    List<Id> accountsList= new List<Id>();
                    if(userTerritoryMap.get(callObj.Call_Performed_By__c) != null){
                        accountsList= territoryAccountMap.get(userTerritoryMap.get(callObj.Call_Performed_By__c));
                    }
                    if(accountsList != null && accountsList.contains(callObj.Account__c)){
                        primaryOutletKPIobj.Territory__c = userTerritoryMap.get(callObj.Call_Performed_By__c);
                    }
                }
                keyOutletKPIMap.put(uniquekey,primaryOutletKPIobj);
            }
        }
    }
}