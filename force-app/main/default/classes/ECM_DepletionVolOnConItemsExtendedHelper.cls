/*
* Name: ECM_DepletionVolumeOnConItemsBatchHelper
* Purpose: This is a extended helper class for ECM_DepletionVolumeUpdateOnConItemsBatch Class
* History
              	                                             
VERSION    	AUTHOR                	DATE              	DETAIL
1.0			Mayukh			      31/05/2023		    142290
*/

public with sharing class ECM_DepletionVolOnConItemsExtendedHelper {
    
    /**
    * @description : getContItemList - This methods used to get the contractitem list with the actual Volume YTD
    * @return : List<ECM_Contract_Item__c>
    * @param : Map<ECM_Contract_Item__c, List<Depletions__c>> conItemWithDepletions, Map<string,Map<string,Decimal>> productUomMap
    */
    public static List<ECM_Contract_Item__c> getContItemList(Map<ECM_Contract_Item__c,List<Depletions__c>> conItemWithDepletions,Map<string,Map<string,Decimal>> productUomMap){
        List<ECM_Contract_Item__c> updateContItemList = new List<ECM_Contract_Item__c>(); 
        for(ECM_Contract_Item__c contractItems : conItemWithDepletions.keySet()){
            Decimal volumeRate =0;
            if(conItemWithDepletions.get(contractItems) != NULL){
                for(Depletions__c depRec : conItemWithDepletions.get(contractItems)){
                    volumeRate += getActualVolume(contractItems.ECM_Contract__r.ECM_Select_UoM__c,depRec,productUomMap);
               }
        	}
            
            //added below condition for ECM-6315
            if(isValidVolume(contractItems,volumeRate)){
            	continue;
            }
            
            if(contractItems.ECM_Contract__r.ECM_Amended__c && contractItems.ECM_Parent_Actual_Volume_CTD__c != NULL 
               && (contractItems.ECM_Actual_Volume_YTD__c != volumeRate + contractItems.ECM_Parent_Actual_Volume_CTD__c)){
            	contractItems.ECM_Actual_Volume_YTD__c = volumeRate + contractItems.ECM_Parent_Actual_Volume_CTD__c;
            }
            else{
                contractItems.ECM_Actual_Volume_YTD__c = volumeRate;
            }
            updateContItemList.add(contractItems);
        }
        return updateContItemList;
    }
    
    
    
    /**
	* @description : getActualVolume - This methods returns Depletion Volume multiplied by Conversion Factor
	* @return : Decimal
	* @param : String selectedUOM,Depletions__c dplt,Map<string,Map<string,Decimal>> productUomMap
	*/
    public static Decimal getActualVolume(String selectedUOM,Depletions__c dplt,Map<string,Map<string,Decimal>> productUomMap){
        List<string> uomList1 = Label.ECM_ActualVolumeYTDBatchUoMList_1.Split(','); //BTL,PCK,KEG,HL,CAS
        List<string> uomList2 = Label.ECM_ActualVolumeYTDBatchUoMList_2.Split(','); //CEQ,ZUN,LPA,EA,DRM
        Decimal volumeRate = 0.0;
        if(selectedUOM == '9LC EU'){
            if(dplt.ECM_UoM__c == 'CEQ'){
                volumeRate = dplt.ECM_Volume__c;
            }
            else if(uomList1.contains(dplt.ECM_UoM__c) && isValidProductUOM(productUomMap,dplt,'CEQ')){
                volumeRate = dplt.ECM_Volume__c*productUomMap.get(dplt.ECM_Product__c).get('CEQ');
            }
        }
        else if(selectedUOM == 'min UoM'){
            if(uomList1.contains(dplt.ECM_UoM__c)){
                volumeRate = dplt.ECM_Volume__c;
            }
            else if(uomList2.contains(dplt.ECM_UoM__c) && isValidProductUOM(productUomMap,dplt,'BTL')){
                volumeRate = dplt.ECM_Volume__c*productUomMap.get(dplt.ECM_Product__c).get('BTL');
            }
        }
        return volumeRate;
    }
    
    
    
    /**
	* @description : isValidVolume - This methods checks if condition is valid
	* @return : Boolean
	* @param : ECM_Contract_Item__c contractItems,Decimal volumeRate
	*/
    public static Boolean isValidVolume(ECM_Contract_Item__c contractItems,Decimal volumeRate){
        boolean isValid = false;
        isValid = (contractItems.ECM_Contract__r.ECM_Amended__c && contractItems.ECM_Parent_Actual_Volume_CTD__c != NULL 
               && (contractItems.ECM_Actual_Volume_YTD__c == volumeRate + contractItems.ECM_Parent_Actual_Volume_CTD__c));
        return isValid;
    }
    
    
    
    /**
	* @description : isValidProductUOM - This methods checks if condition is valid for volume calculation
	* @return : Boolean
	* @param : ECM_Contract_Item__c contractItems,Decimal volumeRate
	*/
    public static Boolean isValidProductUOM(Map<string,Map<string,Decimal>> productUomMap, Depletions__c dplt, String uom){
        boolean isValid = false;
        isValid = (productUomMap.containsKey(dplt.ECM_Product__c) && productUomMap.get(dplt.ECM_Product__c).containsKey(uom))?True:False;
        return isValid;
    }
    
    
    /**
    * @description : getContractItem - This methods used to get the contractitem from Map
    * @return : ECM_Contract_Item__c
    * @param : Map<String,ECM_Contract_Item__c> keyWithContractItems,Depletions__c depRec
    */
    public static ECM_Contract_Item__c getContractItem(Map<String,ECM_Contract_Item__c> keyWithContractItems,Depletions__c depRec){
        ECM_Contract_Item__c conItemRec = keyWithContractItems.containsKey(depRec.Contract__c + '-' + depRec.ECM_Product__c)?
                            					  keyWithContractItems.get(depRec.Contract__c + '-' + depRec.ECM_Product__c):NULL;
        return conItemRec;
    }
    
    
    /**
    * @description : setconWithTimePeriods - This methods used to get the contract with time periods from PS
    * @return : Map<String,List<WrapperStartDateEndDatePair>> 
    * @param : Set<Id> contractIdforPSSet,Map<String,List<WrapperStartDateEndDatePair>> conWithTimePeriods
    */
    public static Map<String,List<WrapperStartDateEndDatePair>> setconWithTimePeriods(Set<Id> contractIdforPSSet,Map<String,List<WrapperStartDateEndDatePair>> conWithTimePeriods){
        for(ECM_Payment_Summary__c ps : [SELECT ECM_Start_Period__c,ECM_End_Period__c,ECM_Contract__c FROM ECM_Payment_Summary__c WHERE ECM_Type__c = 'Volume-Based' AND 
                                        (ECM_Payment_Summary_Status__c = 'Approved' OR ECM_Payment_Summary_Status__c = 'Completed') AND ECM_Contract__c IN :contractIdforPSSet WITH SECURITY_ENFORCED]){
                        if(conWithTimePeriods.containsKey(ps.ECM_Contract__c)){
                                                             conWithTimePeriods.get(ps.ECM_Contract__c).add(new WrapperStartDateEndDatePair(ps.ECM_Start_Period__c,ps.ECM_End_Period__c));
                                                        }
                                                        else{
                                                            List<WrapperStartDateEndDatePair> approvedPeriods = new List<WrapperStartDateEndDatePair>();
                                                            approvedPeriods.add(new WrapperStartDateEndDatePair(ps.ECM_Start_Period__c,ps.ECM_End_Period__c));
                                                            conWithTimePeriods.put(ps.ECM_Contract__c,approvedPeriods);   
                                                            }
                                        }
        return conWithTimePeriods;
    }
    
    
    /**
	* @description : getProductUOM - This methods used to get the Product UOM value with respect to the products
	* @return : Map<string,Map<string,Decimal>>
	* @param : Set<Id> productIds - IDs of product records
	*/
    public static Map<string,Map<string,Decimal>> getProductUOM(set<Id> productIds){
        Map<string,Map<string,Decimal>> prodUOMConversionRate = new Map<string,Map<string,Decimal>>();
        for(Product_UOM__c prodUom: [Select Id, Conversion_Factor__c,Product__c,Type__c from Product_UOM__c Where Product__c IN:productIds  WITH SECURITY_ENFORCED]){
            if(prodUOMConversionRate.containskey(prodUom.Product__c)){
                if(!prodUOMConversionRate.get(prodUom.Product__c).containskey(prodUom.Type__c)){
                    prodUOMConversionRate.get(prodUom.Product__c).put(prodUom.Type__c,prodUom.Conversion_Factor__c);
                }                
            }
            else{
                prodUOMConversionRate.put(prodUom.Product__c,new Map<string,Decimal>{prodUom.Type__c=>prodUom.Conversion_Factor__c});
            }
        }
        return prodUOMConversionRate;
    }
    
    
    /**
    * @description : getOutletId - This methods used to get the actual outlets for depletions against a contract
    * @return : Id
    * @param : Outlet_Contract__c - outlet Contract
    */
    public static Id getOutletId(Outlet_Contract__c outletContract){
        Id actualAcc;
        if((outletContract.Outlet__r.Hybrid__c) && ( outletContract.Outlet__r.Parent_Outlet__c != null)){
            actualAcc = outletContract.Outlet__r.Parent_Outlet__c;
        }
        else if(!outletContract.Outlet__r.Hybrid__c){
            actualAcc = outletContract.Outlet__c;
        }
        return actualAcc;
    }
}