/*
@Name: CO_CustomerRequestTriggerHelper

@Purpose: This class is a helper for CustomerRequestTrigger

@History                                                            

VERSION    AUTHOR            	DATE              DETAIL
1.0        Venkatesh Varma      22-12-2022        Initial Development

*/
public with sharing class CO_CustomerRequestTriggerHelper {
    public static Boolean triggerDisabled = false;
    private static Set<String> salesOrgList;
    private static Set<String> accountGroupList;
    public static Map<Id, Sales_Organisation__c> salesOrgMap;
    public static Map<String,List<CO_Market_Specific_Field_Mapping__mdt>> marketSpecificMap;
    public static Map<String,String> dependentFieldMap;
    private static Map<String, Schema.SObjectField> fieldMap = Customer_Request__c.getSObjectType().getDescribe().fields.getMap(); 
    
    public static void checkMarketSpecificFieldsbeforeUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap){
        Map<Id, Customer_Request__c> mapnewItems = (Map<Id, Customer_Request__c>) newMap;
        Map<Id, Customer_Request__c> mapoldItems = (Map<Id, Customer_Request__c>) oldMap;
        List<Customer_Request__c> newItems = mapnewItems.values();
        List<Customer_Request__c> newItemsFiltered = new List<Customer_Request__c>();
        
        for(Customer_Request__c cr : newItems){
            Boolean filterCheck = filterConditionsforMarketSpecificValidations(cr, mapoldItems);
            if( filterCheck || triggerDisabled ){
                triggerDisabled=true;
                continue;
            }else{
                newItemsFiltered.add(cr);
            }
        }
        if(!newItemsFiltered.isEmpty()){
            checkMarketSpecificFields(newItemsFiltered);
        }
    }
    
    private static Boolean filterConditionsforMarketSpecificValidations(Customer_Request__c cr, Map<Id, Customer_Request__c> mapoldItems){
        Boolean filterCheck = ((cr.CO_Status__c!=mapoldItems.get(cr.Id).CO_Status__c && ((cr.CO_Status__c=='IN REVIEW' && mapoldItems.get(cr.Id).CO_Status__c=='KYC-APPROVED') || cr.CO_Status__c=='IN QUERY')) || 
                               cr.Status_Code__c!=mapoldItems.get(cr.Id).Status_Code__c || cr.CO_Error_Message__c!=mapoldItems.get(cr.Id).CO_Error_Message__c || 
                               cr.CO_Response_received_from_SAP__c!=mapoldItems.get(cr.Id).CO_Response_received_from_SAP__c || cr.CO_KYC_Record_Number__c!=mapoldItems.get(cr.Id).CO_KYC_Record_Number__c || 
                               cr.CO_KYC_StatusCode__c!=mapoldItems.get(cr.Id).CO_KYC_StatusCode__c || cr.CO_KYC_Error_Message__c!=mapoldItems.get(cr.Id).CO_KYC_Error_Message__c);
        return filterCheck;
    }
    
    public static void checkMarketSpecificFields(List<SObject> newItems){
        List<CO_Market_Specific_Field_Mapping__mdt> marketSettingRecords = getMarketSpecificMappingRecords(newItems);
        checkFields(newItems,marketSettingRecords);
    }
    
    private static void checkFields(List<Customer_Request__c> crItems, List<CO_Market_Specific_Field_Mapping__mdt> marketSettingRecords){
        if(marketSettingRecords!=Null && !marketSettingRecords.isEmpty()){
            CO_CustomerRequestTriggerHelperExtension.createMarketSpecificMap(marketSettingRecords);
            String profileName = CO_CustomerRequestTriggerHelperExtension.getProfileInfo();
            for(Customer_Request__c cr :crItems){
                if( marketSpecificMap.containsKey(salesOrgMap.get(cr.CO_Sales_Organisation__c).Code__c+':'+cr.Account_group_Customer_Type__c) ){
                    setDefaultValues(cr,profileName);
                }
            }
        }
    }
    
    private static void setDefaultValues(Customer_Request__c cr, String profileName){
        String errorMessage = '';
        for(CO_Market_Specific_Field_Mapping__mdt marketSetng :marketSpecificMap.get(salesOrgMap.get(cr.CO_Sales_Organisation__c).Code__c+':'+cr.Account_group_Customer_Type__c)){
            if(String.isBlank(String.valueOf(cr.get(marketSetng.API_Name__c))) && String.isNotBlank(marketSetng.Default_Value__c)){
                CO_CustomerRequestTriggerHelperExtension.setFieldValues(cr, marketSetng);
            }else if(marketSetng.Is_Mandatory__c && String.isBlank(marketSetng.Default_Value__c) && String.isBlank(String.valueOf(cr.get(marketSetng.API_Name__c))) && marketSetng.Access_Level__c == profileName){
                String fieldLabel = fieldMap.get(marketSetng.API_Name__c).getDescribe().getLabel();
                errorMessage += String.isBlank(errorMessage)? fieldLabel : ', '+fieldLabel;
            }
        }
        setErrorMessage(errorMessage, cr);
    }
    
    private static void setErrorMessage(String errorMessage, Customer_Request__c cr){
        if(String.isNotBlank(errorMessage)){
            errorMessage = Label.CO_MarketSpecific_ErrorMessage.replace('errorFields', errorMessage).replace('salesOrg', salesOrgMap.get(cr.CO_Sales_Organisation__c).Name);
            cr.addError(errorMessage);
        }
    }
    
    private static List<CO_Market_Specific_Field_Mapping__mdt> getMarketSpecificMappingRecords(List<Customer_Request__c> crList){
        CO_CustomerRequestTriggerHelperExtension.getSalesOrgMap(crList);
        salesOrgList = new Set<String>();
        accountGroupList = new Set<String>();
        for(Customer_Request__c cr : crList){
            if( cr.CO_Sales_Organisation__c != NULL && !salesOrgMap.IsEmpty()){
                salesOrgList.add(salesOrgMap.get(cr.CO_Sales_Organisation__c).Code__c);
            }
            if( cr.Account_group_Customer_Type__c != NULL ){
                accountGroupList.add(cr.Account_group_Customer_Type__c);
            }
        }
        if(salesOrgList.isEmpty() || accountGroupList.isEmpty()){
            return null;
        }
        else{
            return getMarketSpecificRecords(salesOrgList, accountGroupList);
        }
        
    }
    
    private static List<CO_Market_Specific_Field_Mapping__mdt> getMarketSpecificRecords(Set<String> salesOrgs, Set<String> accountGroup){
        return [Select Id, DeveloperName, API_Name__c, Is_Mandatory__c, Is_Dependent__c, Data_Type__c, Default_Value__c, Account_Group__c, 
                Access_Level__c, Sales_Organisation__c, Controlling_Object__c, Controlling_Record_Type__c, Controlling_Field__c, 
                Controlling_Field_Value__c, Dependency_Field__c, Dependency_Field_Value__c, Dependency_Field_Check__c  
                from CO_Market_Specific_Field_Mapping__mdt where Sales_Organisation__c IN :salesOrgs 
                and Account_Group__c IN :accountGroup WITH SECURITY_ENFORCED ORDER BY Sales_Organisation__c, Account_Group__c];
    }
    
    public static void checkAndGenerateSharing(List<Customer_Request__c> newItems){
        CST_SharingUtil.generateSharingFromSalesOrg(newItems, 'CO_Sales_Organisation__c', 'Read');
    }
    
    /**
* @description validateAndReGenerateSharing
* Modify, Validate sharing record on update
* @param List,Map    
*/
    
    public static void validateAndReGenerateSharing(List<Customer_Request__c> newItems,Map<Id, SObject> oldItems){
        Map<Id, Customer_Request__c> mapOldItems;
        List<Customer_Request__c> lstNewChangeSalesOrg = new List<Customer_Request__c>();
        List<Customer_Request__c> lstOldChangeSalesOrg = new List<Customer_Request__c>();
        
        
        if(oldItems != null){
            mapOldItems = (Map<Id, Customer_Request__c>)oldItems;
        }
        
        for(Customer_Request__c objSales : newItems){
            if(mapOldItems.containsKey(objSales.Id) && objSales.CO_Sales_Organisation__c != mapOldItems.get(objSales.Id).CO_Sales_Organisation__c){
                lstNewChangeSalesOrg.add(objSales);
                lstOldChangeSalesOrg.add(mapOldItems.get(objSales.Id));
            }
        }
        
        if(lstNewChangeSalesOrg != null && lstNewChangeSalesOrg.size()>0){
            CST_SharingUtil.updateSharingRecords(lstNewChangeSalesOrg, lstOldChangeSalesOrg, 'CO_Sales_Organisation__c');
            CST_SharingUtil.generateSharingFromSalesOrg(lstNewChangeSalesOrg, 'CO_Sales_Organisation__c', 'Read');
        } 
    }
}