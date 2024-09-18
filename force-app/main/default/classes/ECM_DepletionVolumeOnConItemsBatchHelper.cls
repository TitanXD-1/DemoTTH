/*
* Name: ECM_DepletionVolumeOnConItemsBatchHelper
* Purpose: This is a helper class for ECM_DepletionVolumeUpdateOnConItemsBatch Class
* History
              	                                             
VERSION    	AUTHOR                	DATE              	DETAIL
1.0			Rajarshi/Mayukh			31/05/2023			ES20-14043
2.0         Mayukh                  30/06/2023          142290
*/

public with sharing class ECM_DepletionVolumeOnConItemsBatchHelper {
    public static Set<Id> allcontractIdSet = new Set<Id>(); //Set of all Contracts
    public static Set<ID> productListIds = new Set<ID>(); //Set of product Ids for All contracts
    public static Map<String,ECM_Contract_Item__c> productWithConAndConItem = new Map<String,ECM_Contract_Item__c>(); //Unique identifier of CI (product+contract) with CI record
    public static Set<Id> accoutletIdSet = new Set<Id>(); //Actual Outlet Id Set//Not operators
    public static Map<ECM_Contract_Item__c,List<Depletions__c>> conItemWithDepletions = new Map<ECM_Contract_Item__c,List<Depletions__c>>(); //Contract Items with applicable List of depletions

    
    
    /**
	* @description : actualVolumeCTDAUS - This methods used to calculate and update Actual Volume CTD for AU Contracts
	* @return : void
	* @param : List<Contract> conList - List of contracts
	*/
    public static void actualVolumeCTDAUS(List<ECM_Contract_Item__c> scope){
        
        Date minStartDate = scope[0].ECM_Contract__r.StartDate;
        Date maxEndDate = scope[0].ECM_Contract__r.Original_End_Date__c;
        
        Map<ECM_Contract_Item__c,Decimal> conItemWithActualVolumeCTD = new Map<ECM_Contract_Item__c,Decimal>();//Map of contract Items with their Actual Volume CTD
        List<ECM_Contract_Item__c> finalConItem; //List of contract Item to Update
        Map<Id,List<Id>> accountsWithConAll = new Map<Id,List<Id>>();
        
        maxEndDate = setContractItem(scope,maxEndDate);
        

        accountsWithConAll = getoutletContract();
        
        
        
        for(Depletions__c dep : [SELECT Id, ECM_Volume__c, ECM_Product__c, ECM_Outlet__c,ECM_Product__r.Name, ECM_Start_Period__c, ECM_End_Period__c FROM Depletions__c 
                                 WHERE ECM_Start_Period__c >= :minStartDate AND ECM_End_Period__c <= :maxEndDate AND 
                                 ECM_Product__c IN : productListIds AND ECM_Outlet__c IN : accoutletIdSet AND (ECM_Volume__c != 0 OR ECM_Volume__c != NULL) WITH SECURITY_ENFORCED]){
                                     List<Id> conLst = getContractListforOutlet(dep,accountsWithConAll);
                                     if(conLst != NULL && !conLst.isEmpty()){
                                         for(Id con : conLst){
                                             String key = dep.ECM_Product__c + '_' + con;
                                             conItemWithActualVolumeCTD = calculateconItemWithActualVolumeCTD(key,dep,conItemWithActualVolumeCTD);   
                                         }
                                     }
                                 }
        for(ECM_Contract_Item__c conItem : conItemWithActualVolumeCTD.keySet()){
            Decimal volumeCTD = conItemWithActualVolumeCTD.get(conItem);
            conItem.ECM_Actual_Volume_YTD__c = volumeCTD;
        }
        finalConItem = new List<ECM_Contract_Item__c>(conItemWithActualVolumeCTD.keySet());
        if(finalConItem != Null && !finalConItem.isEmpty() && Schema.sObjectType.ECM_Contract_Item__c.isUpdateable()){
            Database.update(finalConItem,false);   
        }
}
    
    
    
    /**
	* @description : actualVolumeCTDEU - This methods used to calculate and update Actual Volume CTD for EU Contracts
	* @return : void
	* @param : List<Contract> conList - List of contracts
	*/
    public static void actualVolumeCTDEU(List<ECM_Contract_Item__c> scope){
        Set<Id> contractIdforPSSet = new Set<Id>();//Contracts with PFs for which approved periods will not be considered
        Set<Id> allcontractIdSet = new Set<Id>();
        Set<Id> conProductSet = new Set<Id>(); //Set of Product Ids from all Contracts
        Map<String,ECM_Contract_Item__c> keyWithContractItems = new Map<String,ECM_Contract_Item__c>(); //Map with Unique identifiers of Contract Items
        Map<String,List<WrapperStartDateEndDatePair>> conWithTimePeriods = new Map<String,List<WrapperStartDateEndDatePair>>(); //Contract with time-periods of it's Approved Payment Summaries
        List<Depletions__c> depList = new List<Depletions__c>(); //List of Depletions required to be filtered out with approved Payment Summary time-periods
        List<ECM_Contract_Item__c> updateContItemList = new List<ECM_Contract_Item__c>(); //List of Contract Items to update with calculated Actual Volume CTD
        
        for(ECM_Contract_Item__c conitem : scope){
            if(!Label.ECM_PFforActualVolumeYTD.split(',').contains(conitem.ECM_Contract__r.ECM_Payment_Frequency__c)){ //ECM_PFforActualVolumeYTD: Payment Frequencies for which Approved Periods will not be considered
            	contractIdforPSSet.add(conitem.ECM_Contract__c); //Contracts with PFs for which approved periods will not be considered
            }
            conProductSet.add(conitem.ECM_Product__r.Product__c);
            keyWithContractItems.put(conitem.ECM_Contract__c+'-'+conitem.ECM_Product__r.Product__c,conitem);
            conItemWithDepletions.put(conitem,new List<Depletions__c>());
			allcontractIdSet.add(conitem.ECM_Contract__c); // All contracts
        }
        
        conWithTimePeriods = ECM_DepletionVolOnConItemsExtendedHelper.setconWithTimePeriods(contractIdforPSSet,conWithTimePeriods);
        
        depList = [SELECT Id,ECM_Start_Period__c,ECM_End_Period__c,Contract__c,Contract__r.ECM_Payment_Frequency__c,ECM_Product__c,ECM_UoM__c,ECM_Volume__c 
                    FROM Depletions__c WHERE Contract__c IN:allcontractIdSet AND ECM_Product__c IN :conProductSet AND (ECM_Volume__c != 0 OR ECM_Volume__c != NULL) WITH SECURITY_ENFORCED];
        
        Map<string,Map<string,Decimal>> productUomMap = ECM_DepletionVolOnConItemsExtendedHelper.getProductUOM(conProductSet);
        
          if(!depList.isEmpty()){
            for(Depletions__c depRec : depList){
                ECM_Contract_Item__c conItemRec = ECM_DepletionVolOnConItemsExtendedHelper.getContractItem(keyWithContractItems,depRec);
                if(conItemRec != NULL){
                    getconItemWithDepletions(conWithTimePeriods,conItemRec,depRec);
                }
            }
        }
        
        updateContItemList = ECM_DepletionVolOnConItemsExtendedHelper.getContItemList(conItemWithDepletions,productUomMap); 
        
        if(!updateContItemList.isEmpty()){
            Database.update(updateContItemList,false);
        } 
    }
    
    

    /**
    * @description : setContractItem - This methods used to get the contract,product and Contract maxenddate against a contractitem
    * @return : Id
    * @param : ECM_Contract_Item__c - Contract Item, Date EndDate
    */
    public static Date setContractItem(List<ECM_Contract_Item__c> scope, Date maxEndDate){
        for(ECM_Contract_Item__c conitem : scope){
            productWithConAndConItem.put(conitem.ECM_Product__r.Product__c + '_' + conitem.ECM_Contract__r.Id,conitem);
            productListIds.add(conitem.ECM_Product__r.Product__c);
            allcontractIdSet.add(conitem.ECM_Contract__c);
            
            if(maxEndDate < conitem.ECM_Contract__r.Original_End_Date__c){
                maxEndDate = conitem.ECM_Contract__r.Original_End_Date__c; 
            }
        }
        return maxEndDate;
    }
    
    

    /**
    * @description : getoutletContract - This methods used to get the contracts mapped to an account
    * @return : Map<Id,List<Id>>
    * @param : 
    */
    public static Map<Id,List<Id>> getoutletContract(){
        Map<Id,List<Id>> accountsWithConAll = new Map<Id,List<Id>>();
        for(Outlet_Contract__c outletCon : [SELECT Id, Outlet__c, Contract__c,Contract__r.RecordType.Name, Outlet__r.Hybrid__c,Outlet__r.Parent_Outlet__c FROM Outlet_Contract__c 
                                            where Contract__c IN :allcontractIdSet WITH SECURITY_ENFORCED]){
                                                Id actualAcc = ECM_DepletionVolOnConItemsExtendedHelper.getOutletId(outletCon);
                                                if(actualAcc != NULL){
                                                    accoutletIdSet.add(actualAcc); //only outlets/parent_outlets not operators
                                                    if(accountsWithConAll.containsKey(actualAcc)){
                                                        accountsWithConAll.get(actualAcc).add(outletCon.Contract__c); 
                                                    }
                                                    else{
                                                        accountsWithConAll.put(actualAcc,new List<Id>{outletCon.Contract__c});
                                                    }
                                                }
                                            }
        return accountsWithConAll;
    }

    

    /**
    * @description : getContractListforOutlet - This methods used to get the List of Contracts against an Outlet
    * @return : List<Id>
    * @param : ECM_Contract_Item__c - Depletions, Account with Contract List
    */
    public static List<Id> getContractListforOutlet(Depletions__c dep,Map<Id,List<Id>> accountsWithConAll){
        return (accountsWithConAll.containsKey(dep.ECM_Outlet__c)) ? accountsWithConAll.get(dep.ECM_Outlet__c):NULL;
    }

    
    /**
    * @description : setconItemWithActualVolumeCTDMap - This methods used to set 
    * @return : Id
    * @param : ECM_Contract_Item__c - Contract Item, depletion,contract Item With Actual Volume CTD Map
    */
    public static Map<ECM_Contract_Item__c,Decimal> setconItemWithActualVolumeCTDMap(ECM_Contract_Item__c conItem,Depletions__c dep,Map<ECM_Contract_Item__c,Decimal> conItemWithActualVolumeCTD){
        if(dep.ECM_Start_Period__c >= conItem.ECM_Contract__r.StartDate && dep.ECM_End_Period__c <= conItem.ECM_Contract__r.Original_End_Date__c){
            if(conItemWithActualVolumeCTD.containsKey(conItem)){
                Decimal existingVolumeCTD = conItemWithActualVolumeCTD.get(conItem);
                conItemWithActualVolumeCTD.put(conItem,existingVolumeCTD+dep.ECM_Volume__c);
            }
            else{
                conItemWithActualVolumeCTD.put(conItem,dep.ECM_Volume__c);
            }
        }
        return conItemWithActualVolumeCTD;
    }


    /**
    * @description : calculateconItemWithActualVolumeCTD - This methods used to calculate ActualVolumeCTD
    * @return : Map<ECM_Contract_Item__c,Decimal>
    * @param : String key, Depletion, ECM_Contract_Item__c - Contract Item
    */
    public static Map<ECM_Contract_Item__c,Decimal> calculateconItemWithActualVolumeCTD(String key,Depletions__c dep,Map<ECM_Contract_Item__c,Decimal> conItemWithActualVolumeCTD){
        if(productWithConAndConItem.containsKey(key)){
            ECM_Contract_Item__c conItem = productWithConAndConItem.get(key);
            conItemWithActualVolumeCTD = setconItemWithActualVolumeCTDMap(conItem,dep,conItemWithActualVolumeCTD);
        }
        return conItemWithActualVolumeCTD;  
    }


    
     /**
    * @description : getconItemWithDepletions - This methods used to get the depletions from contract items
    * @return : void
    * @param : Map<String,List<WrapperStartDateEndDatePair>>,ECM_Contract_Item__c, Depletions
    */
    public static void getconItemWithDepletions(Map<String,List<WrapperStartDateEndDatePair>> conWithTimePeriods,ECM_Contract_Item__c conItemRec,Depletions__c depRec){
        List<Depletions__c> mapValue = conItemWithDepletions.containsKey(conItemRec)?conItemWithDepletions.get(conItemRec): new List<Depletions__c>();
        if(!Label.ECM_PFforActualVolumeYTD.split(',').contains(depRec.Contract__r.ECM_Payment_Frequency__c) &&
           conWithTimePeriods.containsKey(depRec.Contract__c)){ //Snippet for Approved Time Period Check
               for(WrapperStartDateEndDatePair pairOfDates : conWithTimePeriods.get(depRec.Contract__c)){
                   if(depRec.ECM_Start_Period__c >= pairOfDates.startDate && depRec.ECM_End_Period__c <= pairOfDates.endDate){
                       mapValue.add(depRec);
                       break;
                   }
               }
           }
        else{
            mapValue.add(depRec);
        }
        conItemWithDepletions.put(conItemRec,mapValue);
    }
}