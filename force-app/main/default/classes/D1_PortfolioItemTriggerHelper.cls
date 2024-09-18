/**
 * @name D1_PortfolioItemTriggerHelper
 * @purpose Trigger Helper Class for PorfolioItem
 * @history                                                                                                                       
 * VERSION       AUTHOR            DATE              DETAIL
 * 1.0        Darshi Arpitha    08/02/2021          NCP-1881
 * 1.0		  Rubeena/Ankit	    22/02/2021		    NCP-2004
 * 2.0		  Rubeena			30/09/2021			NCP-3886		
**/
public without sharing class D1_PortfolioItemTriggerHelper {

    /**
     * @userStory NCP-1881
     * @description updateEntitlementPolicy
     * @param {Map<Id,SObject>} newpfItems
     * @param {Map<Id,SObject>} oldpfItems
     * */
    public static void updateEntitlementPolicy(Map<Id,SObject> newpfItems,Map<Id,SObject> oldpfItems){
        Map<Id,Portfolio_Item__c> oldItems;
        Map<Id,Portfolio_Item__c> newItems = (Map<Id,Portfolio_Item__c>) newpfItems;
        
        if(oldpfItems != null)
        {
            oldItems = (Map<Id,Portfolio_Item__c>) oldpfItems;
        }
        
        List<CommerceEntitlementProduct> deleteProductList = new  List<CommerceEntitlementProduct>();
        
        set<string> portfolioItemSet= new set<string>();
        
        set<string> deleteEntitlementPolicy= new set<string>();
        
        //NCP-3886
        Map <String,String> portfolioItemProductMap = new Map<String,String>();
        List<PricebookEntry> toDeletePricebookEntry= new List<PricebookEntry>();
        
        
        for(Portfolio_Item__c newItem : newItems.values()){
            Portfolio_Item__c oldItem;
            //if it is update event
            if(oldItems != null){
                oldItem = oldItems.get(newItem.Id);
            }    
            
            if((oldItem != null && oldItem.Inactive__c != newItem.Inactive__c && newItem.Inactive__c == true)) {
                
                portfolioItemSet.add(newItem.Portfolio_Item_ID__c);
                deleteEntitlementPolicy.add(newItem.Portfolio_Item_ID__c);
                portfolioItemProductMap.put(newItem.Portfolio_Item_ID__c,newItem.Product__c);
                
            }
        }      
        
        for(CommerceEntitlementProduct policyProduct: [Select Id,ProductId,PolicyId,Portfolio_Item_ID__c from CommerceEntitlementProduct where Portfolio_Item_ID__c in :portfolioItemSet]){
            
            
            if(	deleteEntitlementPolicy.contains(policyProduct.Portfolio_Item_ID__c)){
                deleteProductList.add(policyProduct);
            }
        }        
        
        //NCP-3886
        for(PricebookEntry pbe : [Select Id,Portfolio_Item_ID__c,Product2Id FROM PricebookEntry where Portfolio_Item_ID__c IN :portfolioItemSet]){
            if(portfolioItemProductMap.containsKey(pbe.Portfolio_Item_ID__c) && pbe.Product2Id == portfolioItemProductMap.get(pbe.Portfolio_Item_ID__c)){
                toDeletePricebookEntry.add(pbe);
            }
        }
        
        if(!deleteProductList.isEmpty()){
            delete deleteProductList;
        }
        
        //NCP-3886
        if(!toDeletePricebookEntry.isEmpty()){
            delete toDeletePricebookEntry;
        }
        
    }
    
 	/**
 	  * @userStory NCP-2004
	  * @description Used to create Pricebook entry records if the Portfolio Item is created or updated with Unit Price 0.
      * @param {Map<Id,SObject>} newpfItems
      * @param {Map<Id,SObject>} oldpfItems
 	  **/
    
     public static void createPricebookEntry(Map<Id,SObject> newpfItems , Map<Id,SObject> oldpfItems){
        List<PricebookEntry> pricebookEntryList = new List<PricebookEntry>();
        List<Id> pricebookList = new List<Id>();
        Map<string,PricebookEntry> existingPricebookEntryMap = new Map<string,PricebookEntry>();
        Map<Id,Portfolio_Item__c> oldItems;
        Map<Id,Portfolio_Item__c> newItems = (Map<Id,Portfolio_Item__c>) newpfItems;
        Map<string,Portfolio_Item__c> portfolioItemMap = new Map<string,Portfolio_Item__c>();
        Map<String,Pricebook2> portfolioPricebookMap = new Map<String,Pricebook2>();
        Set<String> portfolioIdList = new Set<String>();
        Set<String> portfolioItemIdList = new Set<String>();
        Set<String> productIdList = new Set<String>();
        
                
        if(oldpfItems != null) {
            oldItems = (Map<Id,Portfolio_Item__c>) oldpfItems;
        }
		
        for(Portfolio_Item__c portfolioItems : newItems.values()) {
            Portfolio_Item__c oldPortfolioItems;
            if(oldItems != null) {
                oldPortfolioItems = oldItems.get(portfolioItems.Id);
            }
            //NCP-3886
            if((portfolioItems.UnitPrice__c == 0 && portfolioItems.Inactive__c == false) && (oldPortfolioItems == null || 
                (oldPortfolioItems != null && (oldPortfolioItems.UnitPrice__c != portfolioItems.UnitPrice__c 
				|| oldPortfolioItems.Inactive__c != portfolioItems.Inactive__c)))){
                portfolioIdList.add(portfolioItems.Portfolio_ID__c);
                productIdList.add(portfolioItems.Product__c);
                portfolioItemIdList.add(portfolioItems.Portfolio_Item_ID__c);
            }
        }
        Map<string,string> portfolioItemIdToPortforlioId = new Map<string,string>();
        if(portfolioIdList != NULL && !portfolioIdList.isEmpty()) {
            for(Portfolio_Item__c portFolioItemObj : [select Order_Split__r.Sales_Area__r.CurrencyIsoCode,Portfolio_Item_ID__c,
                                                       Product__c, UnitPrice__c,Portfolio_ID__c
                                                       from Portfolio_Item__c where Portfolio_ID__c IN :portfolioIdList]) {
                portfolioItemMap.put(portFolioItemObj.Portfolio_Item_ID__c,portFolioItemObj); 
                portfolioItemIdToPortforlioId.put(portFolioItemObj.Portfolio_Item_ID__c,portFolioItemObj.Portfolio_ID__c);                                      
            }
        }
        
         //Fetching Pricbooks which has PortfolioId similar to that of Portfolio Item
         if(!portfolioIdList.isEmpty() && portfolioIdList!= NULL) {
             for(Pricebook2 pb : [Select PortfolioID__c From Pricebook2 where isActive = true and PortfolioID__c IN : portfolioIdList]){
                portfolioPricebookMap.put(pb.PortfolioID__c, pb);
                pricebookList.add(pb.Id); 
             } 
            
            if(pricebookList != NULL && !pricebookList.isEmpty() && productIdList != NULL && !productIdList.isEmpty()) {
                for(PriceBookEntry pbEntry : [Select CurrencyIsoCode, Pricebook2Id, UnitPrice,Product2Id from PriceBookEntry 
                                                where Pricebook2Id IN : pricebookList and Product2Id IN : productIdList]){
                    string keyStr =  pbEntry.Product2Id + '' +  pbEntry.CurrencyIsoCode;                         
                    existingPricebookEntryMap.put(keyStr,pbEntry);
                }
            }
         }
                 
        for(Portfolio_Item__c portfolioItems : newItems.values()) {
            if(portfolioPricebookMap != NULL && portfolioPricebookMap.containsKey(portfolioItemIdToPortforlioId.get(portfolioItems.Portfolio_Item_ID__c))) {
                string strKey = portfolioItems.Product__c + '' + portfolioItemMap.get(portfolioItems.Portfolio_Item_ID__c).Order_Split__r.Sales_Area__r.CurrencyIsoCode;
                if(existingPricebookEntryMap == NULL || !existingPricebookEntryMap.containsKey(strKey)) {
                    PricebookEntry pbe = new PricebookEntry();
                    pbe.isActive = true;
                    pbe.CurrencyIsoCode = portfolioItemMap.get(portfolioItems.Portfolio_Item_ID__c).Order_Split__r.Sales_Area__r.CurrencyIsoCode;
                    pbe.UnitPrice = portfolioItems.UnitPrice__c;
                    pbe.Portfolio_Item_ID__c = portfolioItems.Portfolio_Item_ID__c;
                    pbe.Pricebook2Id = portfolioPricebookMap.get(portfolioItemIdToPortforlioId.get(portfolioItems.Portfolio_Item_ID__c)).Id;
                    pbe.Product2Id = portfolioItems.Product__c;
                    pricebookEntryList.add(pbe);
                } 
            }
        }
        if(!pricebookEntryList.isEmpty()){ 
        	insert pricebookEntryList; 
        }    
    }    
}