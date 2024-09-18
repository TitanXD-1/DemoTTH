/*
@Name: CO_TestDataUtility

@Purpose: This class is used by Customer Onboarding test classes. 

@History                                                            
                                                            
VERSION    AUTHOR            DATE              DETAIL
1.0       Jayashree R       01-25-2022        Initial Development
*/
@isTest
public class CO_TestDataUtility {
    
    public static User runAsUser(String profileName){
        Profile p = [SELECT Id FROM Profile WHERE Name=:profileName]; 
        User usr = new User(Alias = 'standt', Email='standarduser@diageo.com', 
                            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                            LocaleSidKey='en_US', ProfileId = p.Id, 
                            TimeZoneSidKey='America/Los_Angeles', UserName='standarduser1@diageo.com.cons');
        usr.Assigned_Markets__c = 'Europe and Turkey';
        return usr;
    }
    
    public static Sales_Organisation__c createSalesOrg(Id countryId){
        Sales_Organisation__c sOrg = new Sales_Organisation__c();
        sOrg.RecordTypeId = Schema.sObjectType.Sales_Organisation__c.getRecordTypeInfosByDeveloperName().get('SalesOrg').getRecordTypeId();
        sOrg.Name = 'Test Sales Org';
        sOrg.Description__c = 'Test Sales Org';
        sOrg.Code__c = 'AU01';
        sOrg.Country__c = countryId;
        return sOrg;
    }
    
    public static Pick_Up_Options__c createPickUpOption(String recordType,Id countryId, Id sOrgId ){
        Id puRecTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get(recordType).getRecordTypeId();
        Pick_Up_Options__c puOption = new Pick_Up_Options__c();
        if(recordType == 'Channel'){
            puOption.Name = 'CO Channel[AU]';
        }else if(recordType == 'Sales office'){
            puOption.Name = 'CO Sales Office[AU]';
        }
        else if(recordType == 'Delivering Plant'){
            puOption.Name = 'CO Delivering Plant[AU]';
        }
        puOption.RecordTypeId = puRecTypeId;
        puOption.Sales_Organisation__c = sOrgId;
        puOption.CO_SAP_Code__c = '1';
        puOption.Geography__c = countryId;
        return puOption;
    }
    
        
    public static Customer_Request__c createCustomerRequest(Id sOrgId, List<Pick_Up_Options__c> puOptionsList){
        Customer_Request__c cr = new Customer_Request__c();
        cr.CO_Email__c = 'as@as.com';
        //CO_Street_House_number__c = 'test',  
        cr.Division__c = '10';
        cr.CO_Credit_Limit__c = '100';
        cr.CO_Last_Internal_Review_Date__c = System.today(); 
        cr.CO_Exchange_Rate_Type__c = 'M'; 
        cr.CO_Customer_Pricing_Procedure__c = 'A';
        // CO_Customer_Statistics_Group__c = '1', 
        cr.CO_Delivery_Priority__c = '02';   
        cr.CO_Terms_of_payment__c = 'CI/0'; 
        cr.CO_Correspondence__c = '002'; 
        cr.CO_Telephone__c = '1029384756';
        cr.Account_group_Customer_Type__c = 'Y001'; 
        cr.CO_Currency__c = 'AED-Arab Emirates Dirham';
        cr.CO_Customer_Name__c = 'Test Customer';
        cr.CO_Company_Code__c = '1000'; 
        cr.CO_Language__c = 'EN-English';
        cr.CO_Sales_Organisation__c = sOrgId;
        cr.CO_Max_partial_deliveries__c = 5;
        cr.CO_Partial_delivery_per_item__c = 'B';
        //CO_Incoming_Payment_Method__c = '3',
        cr.CO_Price_Group__c = 'DP-Duty Paid';
        cr.CO_Incoterms_1__c = 'CFR-Costs and freight';
        //CO_Credit_Rep_Group__c = 'Test',
        cr.CO_Address__PostalCode__s = '910293';
        //cr.CO_Special_payment_requests__c = 'Payments in currency not used in the customers locations';
        cr.CO_Special_payment_requests__c = 'None';
        cr.CO_Channel__c = puOptionsList[0].id;
        cr.CO_Sales_Office__c = puOptionsList[1].id;
        cr.Delivering_Plant__c = puOptionsList[2].id;
        cr.CO_Customer_Name_4__c = 'test';
        return cr;
    }
        
    
}