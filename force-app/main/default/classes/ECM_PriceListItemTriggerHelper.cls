/*
 * @Name: ECM_PriceListItemTriggerHelper
 * @Description: This is the Helper class for PriceListItem Trigger
 * @History                                                            
                                                         
VERSION    AUTHOR                DATE              DETAIL
1.0        Tanishq	        	01/09/2021         Initial Development for ECM-4763
*/ 
public class ECM_PriceListItemTriggerHelper {
   /*
    * Name : priceListItemValidation (ECM-4763)
	* @description : This method is used to check duplicate price list item
	* @return : void
	* @param : List of PriceListItem
	*/
    public static void priceListItemValidation(List<ECM_Price_List_Item__c> newPriceListItem,Map<Id,sObject> oldMap){
        
        //Variable
        Set<String> baseUOMSet = new Set<String>();
        Set<String> productIdSet = new Set<String>();
        Set<String> priceListIdSet = new Set<String>();
        List<ECM_Price_List_Item__c> priceLstItmList = new List<ECM_Price_List_Item__c>();
        Map<Id,ECM_Price_List_Item__c> oldPLIMap;
        Map<String,ECM_Price_List_Item__c> priceListItemMap = new Map<String,ECM_Price_List_Item__c>();
        
        if(oldMap!= null){
             oldPLIMap = (Map<Id,ECM_Price_List_Item__c>)oldMap;
        }
        for(ECM_Price_List_Item__c pliTrig: newPriceListItem){
            if(oldPLIMap == null 
               || (oldPLIMap!= null && oldPLIMap.containskey(pliTrig.Id) && 
                   (oldPLIMap.get(pliTrig.Id).ECM_Base_UoM__c != pliTrig.ECM_Base_UoM__c
                   || oldPLIMap.get(pliTrig.Id).ECM_Product__c != pliTrig.ECM_Product__c))
              ){
                  priceLstItmList.add(pliTrig);
                  baseUOMSet.add(pliTrig.ECM_Base_UoM__c);
                  productIdSet.add(pliTrig.ECM_Product__c);
                  priceListIdSet.add(pliTrig.ECM_Price_List__c);
            }
            
        }
        if(!priceLstItmList.isEmpty()){
            List<ECM_Price_List_Item__c> existingPLI = [SELECT Name,ECM_Base_UoM__c,ECM_Price_List__c,ECM_Product__c 
                                                        FROM ECM_Price_List_Item__c 
                                                        WHERE ECM_Base_UoM__c IN : baseUOMSet 
                                                        AND ECM_Price_List__c IN : priceListIdSet 
                                                        AND ECM_Product__c IN : productIdSet];
            baseUOMSet.clear();
            productIdSet.clear();
            priceListIdSet.clear();
            if(!existingPLI.isEmpty()){
                for (ECM_Price_List_Item__c pliObj: existingPLI){
                    String cmpKey = String.valueOf(pliObj.ECM_Base_UoM__c)+'_'+String.valueOf(pliObj.ECM_Price_List__c)+'_'+String.valueOf(pliObj.ECM_Product__c);
                    priceListItemMap.put(cmpKey,pliObj);
                }
                for(ECM_Price_List_Item__c pliTrig: priceLstItmList){
                    String cmpKey = String.valueOf(pliTrig.ECM_Base_UoM__c)+'_'+String.valueOf(pliTrig.ECM_Price_List__c)+'_'+String.valueOf(pliTrig.ECM_Product__c);
                    if(priceListItemMap.containsKey(cmpKey)){
                        String errorMsg = Label.ECM_Duplicate_Price_List_Item_Error_Msg ;
                        errorMsg = errorMsg.replace( '@@@@', priceListItemMap.get(cmpKey).Name);
                        plitrig.addError(errorMsg);
                    }  
                }  
            }
        }
     }
}