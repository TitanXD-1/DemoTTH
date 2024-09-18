/*
@Name : CO_CustomerRequestTriggerHelperTest
@Purpose : This is the test class for CO_CustomerRequestTriggerHelper
@History                                                            
@VERSION    AUTHOR            DATE              DETAIL
 1.0        Gaurav Singh      1-4-2023         Initial Development
*/
@isTest
public with sharing class CO_CustomerRequestTriggerHelperTest {
    @isTest
    public static void checkMarketSpecificFieldsTest(){
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        
        Sales_Organisation__c sOrg = new Sales_Organisation__c();
        sOrg.RecordTypeId = Schema.sObjectType.Sales_Organisation__c.getRecordTypeInfosByDeveloperName().get('SalesOrg').getRecordTypeId();
        sOrg.Name = 'Test Sales Org';
        sOrg.Description__c = 'Test Sales Org';
        sOrg.Code__c = 'GB01';
        sOrg.Country__c = countryId;
        insert sOrg;
        
        Map<String,Schema.RecordTypeInfo> mapPickupoptionRecordTypes = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName();
        Id channelRecTypeId = mapPickupoptionRecordTypes.get('Channel').getRecordTypeId();
        Id salesOfficeRecTypeId = mapPickupoptionRecordTypes.get('Sales office').getRecordTypeId();
        Id deliveringPlantRecTypeId = mapPickupoptionRecordTypes.get('Delivering Plant').getRecordTypeId();
        
        List<Pick_Up_Options__c> listOfOptions = new List<Pick_Up_Options__c>();
        Pick_Up_Options__c channelOption = EDGE_UtilityTestClass.getRBPickUpOption(countryId);
        channelOption.Name = 'CO Channel[AU]';
        channelOption.RecordTypeId = channelRecTypeId;
        channelOption.Sales_Organisation__c = sOrg.Id;
        channelOption.CO_SAP_Code__c = '01';
        listOfOptions.add(channelOption);
        //upsert channelOption;
        
        Pick_Up_Options__c salesOfficeOption = EDGE_UtilityTestClass.getRBPickUpOption(countryId);
        salesOfficeOption.Name = 'CO Sales Office[AU]';
        salesOfficeOption.RecordTypeId = salesOfficeRecTypeId;
        salesOfficeOption.Sales_Organisation__c = sOrg.Id;
        salesOfficeOption.CO_SAP_Code__c = '1';
        listOfOptions.add(salesOfficeOption);
        //upsert salesOfficeOption;
        
        Pick_Up_Options__c deliveringPlantOption = EDGE_UtilityTestClass.getRBPickUpOption(countryId);
        deliveringPlantOption.Name = 'CO Deliverin Plant[AU]';
        deliveringPlantOption.RecordTypeId = deliveringPlantRecTypeId;
        deliveringPlantOption.Sales_Organisation__c = sOrg.Id;
        deliveringPlantOption.CO_SAP_Code__c = '1';
        listOfOptions.add(deliveringPlantOption);
        //upsert deliveringPlantOption;
        
        upsert listOfOptions;
        
        Id channelId;
        Id salesOfficeId;
        Id delivPlantId ;
        for(Pick_Up_Options__c pO : listOfOptions){
            if(pO.RecordTypeId == channelRecTypeId){
                channelId = pO.Id;
            }else if(pO.RecordTypeId == salesOfficeRecTypeId){
                salesOfficeId = pO.Id;
            }else if(pO.RecordTypeId == deliveringPlantRecTypeId){
                delivPlantId = pO.Id;
            }
        }
        
        Customer_Request__c cr = new Customer_Request__c(
            CO_Sales_Organisation__c = sOrg.Id,
            Account_group_Customer_Type__c = 'Y001',
            CO_Email__c = 'as@as.com', 
            CO_Telephone__c = '1029384756',
            CO_Max_partial_deliveries__c = 5,
            CO_Partial_delivery_per_item__c = 'B',
            CO_Address__PostalCode__s = '910293',
            CO_Cash_management_group__c = 'I5-AR Pay method- Cash',
            CO_Special_payment_requests__c = 'None',
            //CO_Other_Details_of_payment_request__c = 'Test',
            //CO_Planning_Account_Number__c = 1234567890,
            CO_Language_for_SAP__c = 'E - English',
            CO_Channel__c = channelId,
            CO_Sales_Office__c = salesOfficeId,
            Delivering_Plant__c = delivPlantId,
            CO_Incoterms_1__c = 'DAP-Delivered at place'
        );
        
        
        Test.startTest();
        List<Customer_Request__c> newCRList = new List<Customer_Request__c>();
        newCRList.add(cr);
        CO_CustomerRequestTriggerHelper.checkMarketSpecificFields(newCRList);

        insert cr;
        Test.stopTest();
        
        System.assertEquals('I5-AR Pay method- Cash', cr.CO_Cash_management_group__c, 'Default value for CO_Cash_management_group__c not set.');
    }

    @isTest
    public static void customerRequestNewTest(){
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        
        Sales_Organisation__c sOrg = new Sales_Organisation__c();
        sOrg.RecordTypeId = Schema.sObjectType.Sales_Organisation__c.getRecordTypeInfosByDeveloperName().get('SalesOrg').getRecordTypeId();
        sOrg.Name = 'Test Sales Org';
        sOrg.Description__c = 'Test Sales Org';
        sOrg.Code__c = 'GB01';
        sOrg.Country__c = countryId;
        insert sOrg;
        
        Map<String,Schema.RecordTypeInfo> mapPickupoptionRecordTypes = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName();
        Id channelRecTypeId = mapPickupoptionRecordTypes.get('Channel').getRecordTypeId();
        Id salesOfficeRecTypeId = mapPickupoptionRecordTypes.get('Sales office').getRecordTypeId();
        Id deliveringPlantRecTypeId = mapPickupoptionRecordTypes.get('Delivering Plant').getRecordTypeId();
        
        List<Pick_Up_Options__c> listOfOptions = new List<Pick_Up_Options__c>();
        Pick_Up_Options__c channelOption = EDGE_UtilityTestClass.getRBPickUpOption(countryId);
        channelOption.Name = 'CO Channel[AU]';
        channelOption.RecordTypeId = channelRecTypeId;
        channelOption.Sales_Organisation__c = sOrg.Id;
        channelOption.CO_SAP_Code__c = '01';
        listOfOptions.add(channelOption);
        //upsert channelOption;
        
        Pick_Up_Options__c salesOfficeOption = EDGE_UtilityTestClass.getRBPickUpOption(countryId);
        salesOfficeOption.Name = 'CO Sales Office[AU]';
        salesOfficeOption.RecordTypeId = salesOfficeRecTypeId;
        salesOfficeOption.Sales_Organisation__c = sOrg.Id;
        salesOfficeOption.CO_SAP_Code__c = '1';
        listOfOptions.add(salesOfficeOption);
        //upsert salesOfficeOption;
        
        Pick_Up_Options__c deliveringPlantOption = EDGE_UtilityTestClass.getRBPickUpOption(countryId);
        deliveringPlantOption.Name = 'CO Deliverin Plant[AU]';
        deliveringPlantOption.RecordTypeId = deliveringPlantRecTypeId;
        deliveringPlantOption.Sales_Organisation__c = sOrg.Id;
        deliveringPlantOption.CO_SAP_Code__c = '1';
        listOfOptions.add(deliveringPlantOption);
        //upsert deliveringPlantOption;
        
        upsert listOfOptions;
        
        Id channelId;
        Id salesOfficeId;
        Id delivPlantId ;
        for(Pick_Up_Options__c pO : listOfOptions){
            if(pO.RecordTypeId == channelRecTypeId){
                channelId = pO.Id;
            }else if(pO.RecordTypeId == salesOfficeRecTypeId){
                salesOfficeId = pO.Id;
            }else if(pO.RecordTypeId == deliveringPlantRecTypeId){
                delivPlantId = pO.Id;
            }
        }
        Customer_Request__c cr = new Customer_Request__c(
            CO_Email__c = 'as@as.com', 
            CO_Account_Statement__c = '8',  
            Division__c = '10', 
            CO_Credit_Limit__c = '100', 
            CO_Last_Internal_Review_Date__c = System.today(), 
            //CO_Exchange_Rate_Type__c = 'M', 
            CO_Customer_Pricing_Procedure__c = 'A', 
            CO_Customer_Statistics_Group__c = 1, 
            CO_Delivery_Priority__c = '02',   
            CO_Terms_of_payment__c = 'CI/0', 
            CO_Correspondence__c = '002', 
            CO_Telephone__c = '1029384756',
            Account_group_Customer_Type__c = 'Y001', 
            CO_Currency__c = 'AED-Arab Emirates Dirham', 
            CO_Customer_Name__c = 'Test', 
            CO_Company_Code__c = '1000', 
            CO_Language__c = 'EN-English',
            CO_Sales_Organisation__c = sOrg.Id,
            CO_Max_partial_deliveries__c = 5,
            CO_Partial_delivery_per_item__c = 'B', 
            CO_Price_Group__c = 'DP-Duty Paid',
            CO_Incoterms_1__c = 'CFR-Costs and freight',
            CO_Address__PostalCode__s = '910293',
            CO_Special_payment_requests__c = 'None',
            CO_Other_Details_of_payment_request__c = 'Test',
            //CO_Planning_Account_Number__c = 1234567890,
            CO_Language_for_SAP__c = 'E - English',
            CO_Channel__c = channelId,
            CO_Sales_Office__c = salesOfficeId,
            Delivering_Plant__c = delivPlantId
        );
        insert cr;
        
        
        Test.startTest();
        update cr;
        List<Tax_Classification__c> taxClass = [SELECT Id,Customer_Request__c FROM Tax_Classification__c WHERE Customer_Request__c =:cr.Id];
        delete taxClass;
        delete cr;
        Test.stopTest();
        
        System.assertEquals('10', cr.Division__c, 'Default value for Division__c not set.');
    }
}