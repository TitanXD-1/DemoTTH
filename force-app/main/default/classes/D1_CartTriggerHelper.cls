/*
 * @Name: D1_CartTriggerHelper
 * @discription: Trigger Helper Class for WebCart
 * @History                                                            
 * --                     
 * VERSION      AUTHOR              DATE                DETAIL
 * 1.0          Darshi Arpitha      11/01/2021          NCP-1701
 * 2.0          Dipanjan D          03/06/2021          Added updateDeliveryAddress for NCP-3336(Defect)    
 * 3.0          Mukesh Kant         11/12/2023          148646
 **/
public without sharing class D1_CartTriggerHelper {
    /**
     * @description 
     * @param newCarts 
     */    
    public static void updateCartSalesArea(List<WebCart> newCarts){

        Set<Id> accountIds = new Set<Id>(); 
        Map<Id,PNR_Partner_Function__c> accountIdPartnerFnMap = new Map<Id,PNR_Partner_Function__c>();
        //Start:Added for US 148646
        Id userId = UserInfo.getUserId();
        User loggedInUser = [SELECT Id, Available_Countries__c, LanguageLocaleKey FROM User WHERE Id =:userId];
        List<String> availableCountry = loggedInUser.Available_Countries__c != NULL ? loggedInUser.Available_Countries__c.split(',') : new List<String>();
        List<D1_Setting__c> d1Settings = [SELECT Id, Enable_Payment_Terms__c FROM D1_Setting__c 
                                                WHERE Market__r.Code__c IN :availableCountry AND Language__c =:loggedInUser.LanguageLocaleKey LIMIT 1];
        //End: Added for US 148646
        for(WebCart cart : newCarts){
            if(cart.Accountid != null) {
                accountIds.add(cart.Accountid);
            }
        }
      
        
        if(!accountIds.isEmpty()){
            for(PNR_Partner_Function__c partnerFunction : [SELECT Sales_Area__c, PNR_Sold_To__c,PNR_Sold_To__r.KUNNR__c, 
                                                            PNR_Sold_To__r.BillingCity,
                                                            PNR_Sold_To__r.BillingCountry,
                                                            PNR_Sold_To__r.BillingPostalCode,
                                                            PNR_Sold_To__r.BillingState,
                                                            PNR_Sold_To__r.BillingStateCode,
                                                            PNR_Sold_To__r.BillingStreet,
                                                            PNR_Sold_To__r.BillingCountryCode,
                                                            Terms_of_Payment__c,Description_of_the_Payment_Term__c //Added for US 148646
                                                            FROM PNR_Partner_Function__c 
                                                            WHERE PNR_Sold_To__c IN :accountIds AND PNR_Type__c = 'Sold-To']) 
            {                
               accountIdPartnerFnMap.put(partnerFunction.PNR_Sold_To__c,partnerFunction);                                              
            }
            
            if(!accountIdPartnerFnMap.isEmpty()){
                for(WebCart cart : newCarts){
                    if(accountIdPartnerFnMap.get(cart.AccountId) != NULL && accountIdPartnerFnMap.get(cart.AccountId).Sales_Area__c != null ){
                        PNR_Partner_Function__c partnerObj=accountIdPartnerFnMap.get(cart.AccountId);
                        cart.Sales_Area__c = partnerObj.Sales_Area__c;
                        cart.Soldto_Party__c=partnerObj.PNR_Sold_To__r.KUNNR__c;
                        cart.BillingCity=partnerObj.PNR_Sold_To__r.BillingCity;
                        cart.BillingCountry=partnerObj.PNR_Sold_To__r.BillingCountry;
                        cart.BillingPostalCode=partnerObj.PNR_Sold_To__r.BillingPostalCode;
                        cart.BillingState=partnerObj.PNR_Sold_To__r.BillingState;
                        cart.BillingStateCode=partnerObj.PNR_Sold_To__r.BillingStateCode;
                        cart.BillingStreet=partnerObj.PNR_Sold_To__r.BillingStreet;
                        cart.BillingCountryCode=partnerObj.PNR_Sold_To__r.BillingCountryCode;
                        //Added for US 148646
                        if(d1Settings !=null && d1Settings.size() > 0 && d1Settings.get(0).Enable_Payment_Terms__c){
                            cart.Payment_Term_Code__c=partnerObj.Terms_of_Payment__c;
                            cart.Payment_Term_Description__c=partnerObj.Description_of_the_Payment_Term__c;
                        }
                    }
                }
            }
        }
    }

    /**
     * @description 
     * @param newItems 
     */    
    public static void updateDeliveryAddress(List<WebCart> newItems){
        User userRec = [SELECT Effective_Account_Id__c FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];
        List<ContactPointAddress> cpaList = [SELECT Id  
                                            FROM ContactPointAddress 
                                            WHERE ParentId =: userRec.Effective_Account_Id__c AND AddressType = 'Shipping'
                                            ORDER BY Status__c,Name asc LIMIT 1];
        if (!cpaList.isEmpty()) {
            for (WebCart cart : newItems) {
                cart.Delivery_Address__c = cpaList[0].Id;
            }
        }
    }
}