/*
@Name : CO_RDDCToSFUpdateTesy
@Purpose : This is the test class for CO_RDDCToSFUpdate
@History                                                            
@VERSION    AUTHOR                   DATE              DETAIL
*  1.0      Gaurav Singh             12-01-2022        Initial Development
*/
@isTest
private with sharing class CO_RDDCToSFUpdateTest {
    @isTest
    private static void customerRequestRDDCToSFTest(){
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        //  Id credRepGrpRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Credit Rep Group').getRecordTypeId();
        Id channelRecTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Channel').getRecordTypeId();
        Id salesOfficeRecTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Sales office').getRecordTypeId();
        Id deliveringPlantRecTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Delivering Plant').getRecordTypeId();
        
        Sales_Organisation__c sOrg = new Sales_Organisation__c();
        sOrg.RecordTypeId = Schema.sObjectType.Sales_Organisation__c.getRecordTypeInfosByDeveloperName().get('SalesOrg').getRecordTypeId();
        sOrg.Name = 'Test Sales Org';
        sOrg.Description__c = 'Test Sales Org';
        sOrg.Code__c = 'AU01';
        sOrg.Country__c = countryId;
        insert sOrg;
        
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
            //CO_Incoming_Payment_Method__c = '3',
            CO_Price_Group__c = 'DP-Duty Paid',
            CO_Incoterms_1__c = 'CFR-Costs and freight',
            //  CO_Credit_Rep_Group__c = pickOp.Id,
            CO_Address__PostalCode__s = '910293',
            CO_Special_payment_requests__c = 'Payments in currency not used in the customers locations',
            CO_Channel__c = channelId,
            CO_Sales_Office__c = salesOfficeId,
            Delivering_Plant__c = delivPlantId,
            CO_Other_Details_of_payment_request__c = 'Test' 
        );
        insert cr;
        
       
        
        //Test.setMock(HttpCalloutMock.class, new RDDCToSFHttpCalloutMockImpl(200, '{"message":"Success","data":{"customFields":[{"name":"Warehouse Authorization Number","value":"Test"}]}}'));
        Test.setMock(HttpCalloutMock.class, new RDDCToSFHttpCalloutMockImpl(200, '{"message":"Success","name":"Test Customer","riskTier":"Low", "customFields":[{"name":"Bank Information - Bank Location Country","value":"Australia"}]}'));
        
        Test.startTest();
            List<Id> listOfIds = new List<Id>();
            listOfIds.add(cr.Id);
            
            List<CO_RDDCToSFUpdate.Results> output = CO_RDDCToSFUpdate.getDataFromRDDC(listOfIds);
           
        
        Test.stopTest();
        
        Boolean isValid = output[0].isValid;
        system.assertEquals(True, isValid, 'getDataFromRDDC failed');
    }

    public class RDDCToSFHttpCalloutMockImpl implements HttpCalloutMock {
        public Integer reponseStatus;
        public String reponseBody;
        public RDDCToSFHttpCalloutMockImpl(Integer reponseStatus, String reponseBody){
            this.reponseStatus = reponseStatus;
            this.reponseBody = reponseBody;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(reponseBody);
            res.setStatusCode(reponseStatus);
            return res;
        }
    }
}