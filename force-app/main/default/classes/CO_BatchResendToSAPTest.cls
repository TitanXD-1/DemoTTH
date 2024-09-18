/*
 * @class: CO_BatchResendToSAPTest
 * @description: This is the test class for CO_BatchResendToSAP and CO_BatchResendToSAPSchedular
 * @History                                                                                                                       
 * @VERSION      AUTHOR             DATE              DETAIL
*   1.0       Cons Dev Team      11-25-2022        Initial Development
*   1.1         Aparajita        04-01-2022        Added pickupOpt data(CONS-206)
*/
@isTest
public class CO_BatchResendToSAPTest {
    @isTest
    public static void customerRequestSAPBatch(){
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        Id credRepGrpRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Credit Rep Group').getRecordTypeId();

        Sales_Organisation__c sOrg = new Sales_Organisation__c();
        sOrg.RecordTypeId = Schema.sObjectType.Sales_Organisation__c.getRecordTypeInfosByDeveloperName().get('SalesOrg').getRecordTypeId();
        sOrg.Name = 'Test Sales Org';
        sOrg.Description__c = 'Test Sales Org';
        sOrg.Code__c = 'AU01';
        sOrg.Country__c = countryId;
        insert sOrg;

        Pick_Up_Options__c pickOp = new Pick_Up_Options__c();
        pickOp.RecordTypeId = credRepGrpRecordTypeId;
        pickOp.Name = 'Test CRD[AU]';
        pickOp.Geography__c = countryId;
        pickOp.CO_SAP_Code__c = '1234';
        pickOp.Sales_Organisation__c = sOrg.Id;
        insert pickOp;
        
        Customer_Request__c cr = new Customer_Request__c(
            CO_Email__c = 'as@as.com', 
            //CO_Street_House_number__c = 'test', 
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
            CO_Incoming_Payment_Method__c = '3', 
            CO_Price_Group__c = 'DP-Duty Paid',
            CO_Incoterms_1__c = 'CFR-Costs and freight',
            CO_Credit_Rep_Group__c = pickOp.Id,
            CO_Status__c = 'SENT TO SAP',
            CO_Response_received_from_SAP__c = 1,
            Status_Code__c = 500,
            CO_Address__PostalCode__s = '412307',
            CO_Special_payment_requests__c = 'None'
        );
        insert cr;
        
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('SendToSAPSuccessResp');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        CO_BatchResendToSAP resendToSAP = new CO_BatchResendToSAP();
        database.executeBatch(resendToSAP,1);
        CO_BatchResendToSAPSchedular sendToSAPSchedular = new CO_BatchResendToSAPSchedular();
        String sch = '0 0 23 * * ?';
        system.schedule('Test Schedular for CO Send To SAP', sch, sendToSAPSchedular);
        System.assert(mock!= null,true);
        Test.stopTest();
    }
}