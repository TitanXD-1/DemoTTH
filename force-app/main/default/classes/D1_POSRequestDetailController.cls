/*
Project : DiageoOne
Author: Dipanjan Das
Jira Story : NCP-2070 & NCP-2071
Description : Controller Class for  
*/
public without sharing class D1_POSRequestDetailController {
    @AuraEnabled(cacheable=true)
    public static List<Order_Item__c> getOrderItems(Id orderId){
        List<Order_Item__c> orderItems = [  SELECT Id, Product__c, Product__r.Name, Product__r.Description__c,
                                            Product__r.Product_Image_Version_Id__c, Product__r.Product_Sub_Type__r.Card_Layout_Selection__c,
                                            Product__r.Pack_Size_Description__c, Glass_Type__c, Reason_For_Request__r.Name, 
                                            Order__r.Request_Type__c, Quantity__c 
                                            FROM Order_Item__c WHERE Order__c = :orderId Order By Product__r.Name];

        List<Product__c> productList = new List<Product__c>();
        List<Pick_Up_Options__c> options = new List<Pick_Up_Options__c>();
        for (Order_Item__c orderItem : orderItems) {
            if(orderItem.Product__c != NULL ) { //US 150154:PMD Fix
            	productList.add(orderItem.Product__r);
            }
            if(orderItem.Reason_For_Request__c != NULL) { //US 150154:PMD Fix
	            options.add(orderItem.Reason_For_Request__r);
            }
        }

        D1_TranslationsUtility.updateTranslationsInRecords(productList);
        D1_TranslationsUtility.updateTranslationsInRecords(options);

        return orderItems;
    }
    
    
    @AuraEnabled(cacheable = true)
    public static D1_Setting__c getD1Setting(){
        
        Id userId = userInfo.getUserId();
        
        User loggedInUser = [SELECT Available_Countries__c,LanguageLocaleKey FROM User WHERE ID =: userId];
        
        List<String> availableCountry= loggedInUser.Available_Countries__c!=Null?loggedInUser.Available_Countries__c.split(','):new List<String>();
        
        List<D1_Setting__c> d1Settings = [SELECT Id,Logged_In_Contact_Us_Email__c, Logged_In_Contact_Us_Phone__c,My_Request_Contact_Us__c, Name_2_value__c
                                          FROM D1_Setting__c 
                                          WHERE Market__r.Code__c IN: availableCountry 
                                          AND Language__c =: loggedInUser.LanguageLocaleKey];
        if(d1Settings.isEmpty()){
            throw new AuraHandledException('Access Denied');
        }
        return d1Settings[0];                          
    }    
}