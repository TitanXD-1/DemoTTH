/*
@Name: CO_CustomerRequestTriggerHelperExtension

@Purpose: This class is a Extension for CO_CustomerRequestTriggerHelper

@History                                                            

VERSION    AUTHOR            	DATE              DETAIL
1.0        Venkatesh Varma      04-01-2023        Initial Development

*/
public with sharing class CO_CustomerRequestTriggerHelperExtension {
    
    public static void createMarketSpecificMap(List<CO_Market_Specific_Field_Mapping__mdt> marketSettingRecords){
        CO_CustomerRequestTriggerHelper.marketSpecificMap = new Map<String,List<CO_Market_Specific_Field_Mapping__mdt>>();
        for(CO_Market_Specific_Field_Mapping__mdt marketSetting :marketSettingRecords){
            if(CO_CustomerRequestTriggerHelper.marketSpecificMap.containsKey(marketSetting.Sales_Organisation__c+':'+marketSetting.Account_Group__c)){
                CO_CustomerRequestTriggerHelper.marketSpecificMap.get(marketSetting.Sales_Organisation__c+':'+marketSetting.Account_Group__c).add(marketSetting);
            }else{
                CO_CustomerRequestTriggerHelper.marketSpecificMap.put(marketSetting.Sales_Organisation__c+':'+marketSetting.Account_Group__c, new List<CO_Market_Specific_Field_Mapping__mdt>{marketSetting});
            }
        }
        System.debug(System.LoggingLevel.INFO, 'marketSpecificMap - '+CO_CustomerRequestTriggerHelper.marketSpecificMap);
    }
    
	public static void setFieldValues(Customer_Request__c cr, CO_Market_Specific_Field_Mapping__mdt marketSetng){
        String dataType = marketSetng.Data_Type__c.toLowerCase();
        String defaultValue = marketSetng.Default_Value__c;
        Boolean validDependentField = false;
        validDependentField = marketSetng.Is_Dependent__c && ((String)cr.get(marketSetng.Dependency_Field__c)==marketSetng.Dependency_Field_Value__c || (String.isBlank((String)cr.get(marketSetng.Dependency_Field__c)) && marketSetng.Dependency_Field_Check__c=='Empty') || (String.isNotBlank((String)cr.get(marketSetng.Dependency_Field__c)) && marketSetng.Dependency_Field_Check__c=='Non Empty'));
        
        if(validDependentField){
            defaultValue = defaultValue;
        }else if(marketSetng.Is_Dependent__c){
            return;
        }
        switch on dataType {
            when 'string' {
                cr.put(marketSetng.API_Name__c, String.valueOf(defaultValue));
            }
            when 'boolean' {
                cr.put(marketSetng.API_Name__c, Boolean.valueOf(defaultValue));
            }	
            when 'integer' {
                cr.put(marketSetng.API_Name__c, Integer.valueOf(defaultValue));
            }
            when 'decimal' {
                cr.put(marketSetng.API_Name__c, Decimal.valueOf(defaultValue));
            }
            when 'picklist' {
                cr.put(marketSetng.API_Name__c, ( validDependentField || String.isBlank((String)cr.get(marketSetng.API_Name__c)) ) ? String.valueOf(defaultValue) : (String)cr.get(marketSetng.API_Name__c));
            }
            when else {
                cr.put(marketSetng.API_Name__c, defaultValue);
            }
        }
    }
    
    public static String getProfileInfo()
    {
        Id profileId = userinfo.getProfileId();
        String profileName = [Select Id,Name from Profile where Id=:profileId].Name;
        
        Boolean hasRequestorCustomPermission = FeatureManagement.checkPermission('CO_Requestor_Permission');
        Boolean hasMDMCustomPermission = FeatureManagement.checkPermission('CO_Data_Manager_Permission');
        if(hasRequestorCustomPermission || hasMDMCustomPermission){
            return hasRequestorCustomPermission?Label.CO_Requestor_Profile:Label.CO_Data_Manager_Profile;
        }
        return profileName;
    }
    
    public static void getSalesOrgMap(List<Customer_Request__c> crList){
        Set<String> salesOrgSet= new Set<String>();
        for(Customer_Request__c cr : crList){
            if( cr.CO_Sales_Organisation__c != NULL ){
                salesOrgSet.add(cr.CO_Sales_Organisation__c);
            }
        }
        if(!salesOrgSet.isEmpty()){
            CO_CustomerRequestTriggerHelper.salesOrgMap = new Map<Id, Sales_Organisation__c>([SELECT Id, Name, Code__c from Sales_Organisation__c where Id IN :salesOrgSet WITH SECURITY_ENFORCED]);
        }
        System.debug(System.LoggingLevel.INFO, 'salesOrgMap - '+CO_CustomerRequestTriggerHelper.salesOrgMap);
    }
}