/*
@Name: CO_CustomerEmailControllerTest

@Purpose: This class is used for CO_CustomerEmailController test coverage

@History  

@VERSION    AUTHOR                DATE              DETAIL
1.0         Abhishek & Anamika    12-07-2023        Initial Development
1.1        Anamika                 24-08-2023        USER STORY 144398
*/

@isTest
public class CO_CustomerEmailControllerTest {
    @isTest
    public static void customerEmailControllerTest(){
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        
        Profile profile = [Select Id From Profile where Name = 'System Administrator' limit 1];
        
        User usr1= new User();
        usr1.ProfileID = profile.Id;
        usr1.Username ='Test@Testemail.com'+ System.currentTimeMillis(); 
        usr1.LastName ='TestLastname';
        usr1.Email ='Test@Testemail.com';
        usr1.Alias ='TestUser';
        usr1.Available_Countries__c='AU';
        usr1.TimeZoneSidKey ='TestCommunityNickname1';
        usr1.CommunityNickname ='TestCommunityNickname1';
        usr1.TimeZoneSidKey ='America/Los_Angeles';
        usr1.LocaleSidKey ='en_US';
        usr1.EmailEncodingKey ='UTF-8';
        usr1.LanguageLocaleKey ='en_US';
        insert usr1;
        
        Sales_Organisation__c sOrg = new Sales_Organisation__c();
        sOrg.RecordTypeId = Schema.sObjectType.Sales_Organisation__c.getRecordTypeInfosByDeveloperName().get('SalesOrg').getRecordTypeId();
        sOrg.Name = 'Test Sales Org';
        sOrg.Description__c = 'Test Sales Org';
        sOrg.Code__c = 'AU01';
        sOrg.Country__c = countryId;
        insert sOrg;
        
        List<Pick_Up_Options__c> pOptionList = new List<Pick_Up_Options__c>();
        Pick_Up_Options__c delOption = new Pick_Up_Options__c();
        delOption.RecordTypeId = Schema.sObjectType.Pick_Up_Options__c.getRecordTypeInfosByDeveloperName().get('Delivering_Plant').getRecordTypeId();
        delOption.Name = 'CO Delivering Plant[AU]';
        delOption.Sales_Organisation__c = sOrg.Id;
        delOption.CO_SAP_Code__c = '1';
        delOption.Geography__c = countryId;
        pOptionList.add(delOption);
        
        Pick_Up_Options__c channelOption = new Pick_Up_Options__c();
        channelOption.RecordTypeId = Schema.sObjectType.Pick_Up_Options__c.getRecordTypeInfosByDeveloperName().get('Channel').getRecordTypeId();
        channelOption.Name = 'CO Channel[AU]';
        channelOption.Sales_Organisation__c = sOrg.Id;
        channelOption.CO_SAP_Code__c = '1';
        channelOption.Geography__c = countryId;
        pOptionList.add(channelOption);
        
        Pick_Up_Options__c salesOption = new Pick_Up_Options__c();
        salesOption.RecordTypeId = Schema.sObjectType.Pick_Up_Options__c.getRecordTypeInfosByDeveloperName().get('Sales_office').getRecordTypeId();
        salesOption.Name = 'CO Sales Office[AU]';
        salesOption.Sales_Organisation__c = sOrg.Id;
        salesOption.CO_SAP_Code__c = '1';
        salesOption.Geography__c = countryId;
        pOptionList.add(salesOption);
        insert pOptionList;
        
        test.startTest();
        Id directRecordTypeId = Customer_Request__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Direct Customer').getRecordTypeId();
        Id indirectRecordTypeId = Customer_Request__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Indirect Customer').getRecordTypeId();
      
        list<Customer_Request__c> custList = new list<Customer_Request__c>();
        Customer_Request__c cr = new Customer_Request__c( 
            RecordTypeId = directRecordTypeId,
            CO_Email__c = 'as@as.com',
            Division__c = '10',
            CO_Credit_Limit__c = '100',
            CO_Last_Internal_Review_Date__c = System.today(),
            CO_Exchange_Rate_Type__c = 'M',
            CO_Customer_Pricing_Procedure__c = 'A',
            CO_Delivery_Priority__c = '02',   
            CO_Terms_of_payment__c = 'CI/0',
            CO_Correspondence__c = '002', 
            CO_Telephone__c = '1029384756',
            Account_group_Customer_Type__c = 'Y001',
            CO_Currency__c = 'AED-Arab Emirates Dirham',
            CO_Customer_Name__c = 'Test Customer',
            CO_Company_Code__c = '1000',
            CO_Language__c = 'EN-English',
            CO_Sales_Organisation__c = sOrg.Id,
            CO_Max_partial_deliveries__c = 5,
            CO_Partial_delivery_per_item__c = 'B',
            CO_Price_Group__c = 'DP-Duty Paid',
            CO_Incoterms_1__c = 'CFR-Costs and freight',
            CO_Special_payment_requests__c = 'None',
            CO_Customer_Name_4__c = 'test',
            CO_Approver__c = usr1.Id,
            CO_Pricing_Approver__c = usr1.Id,
            CO_Additional_Approver__c = usr1.Id,
            CO_Pricing_master_data__c = 'Applicable',
            Delivering_Plant__c = delOption.Id,
            CO_Channel__c = channelOption.id,
            CO_Sales_Office__c = salesOption.id,
            CO_Language_for_SAP__c = 'E - English',
            CO_Address__PostalCode__s = '123456'
        );
        custList.add(cr);
        
        Customer_Request__c cr1 = new Customer_Request__c(
            RecordTypeId = indirectRecordTypeId,
            CO_Email__c = 'as@as.com', 
            Division__c = '10',
            CO_Credit_Limit__c = '100',
            CO_Last_Internal_Review_Date__c = System.today(),
            CO_Exchange_Rate_Type__c = 'M',
            CO_Customer_Pricing_Procedure__c = 'A', 
            CO_Delivery_Priority__c = '02',   
            CO_Terms_of_payment__c = 'CI/0',
            CO_Correspondence__c = '002', 
            CO_Telephone__c = '1029384756',
            Account_group_Customer_Type__c = 'Y001',
            CO_Currency__c = 'AED-Arab Emirates Dirham',
            CO_Customer_Name__c = 'Test Customer',
            CO_Company_Code__c = '1000',
            CO_Language__c = 'EN-English',
            CO_Sales_Organisation__c = sOrg.Id,
            CO_Max_partial_deliveries__c = 5,
            CO_Partial_delivery_per_item__c = 'B',
            CO_Price_Group__c = 'DP-Duty Paid',
            CO_Incoterms_1__c = 'CFR-Costs and freight',
            CO_Special_payment_requests__c = 'None',
            CO_Customer_Name_4__c = 'test',
            CO_Approver__c = usr1.Id,
            CO_Pricing_Approver__c = usr1.Id,
            CO_Additional_Approver__c = usr1.Id,
            CO_Pricing_master_data__c = 'Applicable',
            Delivering_Plant__c = delOption.Id,
            CO_Channel__c = channelOption.id,
            CO_Sales_Office__c = salesOption.id,
            CO_Language_for_SAP__c = 'E - English',
            CO_Address__PostalCode__s = '123456',
            Estimated_annual_total_transaction_value__c = 'Over £20m' 
        );
        custList.add(cr1);
        
        Customer_Request__c cr2 = new Customer_Request__c(
            RecordTypeId = indirectRecordTypeId,
            CO_Email__c = 'as@as.com', 
            Division__c = '10',
            CO_Credit_Limit__c = '100',
            CO_Last_Internal_Review_Date__c = System.today(),
            CO_Exchange_Rate_Type__c = 'M',
            CO_Customer_Pricing_Procedure__c = 'A', 
            CO_Delivery_Priority__c = '02',   
            CO_Terms_of_payment__c = 'CI/0',
            CO_Correspondence__c = '002', 
            CO_Telephone__c = '1029384756',
            Account_group_Customer_Type__c = 'Y001',
            CO_Currency__c = 'AED-Arab Emirates Dirham',
            CO_Customer_Name__c = 'Test Customer',
            CO_Company_Code__c = '1000',
            CO_Language__c = 'EN-English',
            CO_Sales_Organisation__c = sOrg.Id,
            CO_Max_partial_deliveries__c = 5,
            CO_Partial_delivery_per_item__c = 'B',
            CO_Price_Group__c = 'DP-Duty Paid',
            CO_Incoterms_1__c = 'CFR-Costs and freight',
            CO_Special_payment_requests__c = 'None',
            CO_Customer_Name_4__c = 'test',
            CO_Approver__c = usr1.Id,
            CO_Pricing_Approver__c = usr1.Id,
            CO_Additional_Approver__c = usr1.Id,
            CO_Pricing_master_data__c = 'Applicable',
            Delivering_Plant__c = delOption.Id,
            CO_Channel__c = channelOption.id,
            CO_Sales_Office__c = salesOption.id,
            CO_Language_for_SAP__c = 'E - English',
            CO_Address__PostalCode__s = '123456',
            Estimated_annual_total_transaction_value__c = 'Below £10k' 
        );
        custList.add(cr2);
        insert custList;
        
        List<Customer_Request__c> name = [Select Name from Customer_Request__c where Id IN : custList];
        
        
        ID workspaceId = [SELECT Id FROM ContentWorkspace WHERE Name = 'Customer Onboarding'][0].Id;
        
        list<ContentVersion> cvList = new list<ContentVersion>();
        ContentVersion contentVersion = new ContentVersion(
            Title = name+'- Customer Details',
            PathOnClient = 'CustomerDetails.pdf',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true,
            RecordTypeId = Schema.sObjectType.ContentVersion.getRecordTypeInfosByDeveloperName().get('CO_Customer_Request').getRecordTypeId(),
            Content_Type__c = 'Other',
            CO_Document_Type__c = 'Direct'
        );
        cvList.add(contentVersion);   
        
        ContentVersion contentVersion1 = new ContentVersion(
            Title = name+'- Customer Details indirect',
            PathOnClient = 'CustomerDetails.pdf',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true,
            RecordTypeId = Schema.sObjectType.ContentVersion.getRecordTypeInfosByDeveloperName().get('CO_Customer_Request').getRecordTypeId(),
            Content_Type__c = 'Other',
            CO_Document_Type__c = 'Indirect - Over £20m'
        );
        cvList.add(contentVersion1);   
        
        ContentVersion contentVersion2 = new ContentVersion(
            Title = name+'- Customer Details indirect-1',
            PathOnClient = 'CustomerDetails.pdf',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true,
            RecordTypeId = Schema.sObjectType.ContentVersion.getRecordTypeInfosByDeveloperName().get('CO_Customer_Request').getRecordTypeId(),
            Content_Type__c = 'Other',
            CO_Document_Type__c = 'Indirect - Below £10k'
        );
        cvList.add(contentVersion2);   
        insert cvList;
        
        List<ContentDocument> documents = [
            SELECT Id, Title, LatestPublishedVersionId,ParentId
            FROM ContentDocument
        ];
        
        list<ContentDocumentLink> cdList = new list<ContentDocumentLink>();
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = workspaceId; 
        cdl.ContentDocumentId = documents[0].Id;
        cdList.add(cdl);
        
        ContentDocumentLink cd2 = New ContentDocumentLink();
        cd2.LinkedEntityId = workspaceId;
        cd2.ContentDocumentId = documents[1].Id;
        cdList.add(cd2);
        
        ContentDocumentLink cd3 = New ContentDocumentLink();
        cd3.LinkedEntityId = workspaceId;
        cd3.ContentDocumentId = documents[2].Id;
        cdList.add(cd3);
        insert cdList;
        
        Datetime cdCreatedDate = [SELECT CreatedDate FROM ContentVersion WHERE Id =: cvList[0].Id].CreatedDate;
        Datetime crCreatedDate = [SELECT CreatedDate FROM Customer_Request__c WHERE Id =: custList[0].Id].CreatedDate;
        System.assertEquals(crCreatedDate.date(),cdCreatedDate.date(),'Content Document is Created');
        
        
        CO_CustomerEmailController.sendEmailtoCustomerswithAttachment(new List<Customer_Request__c>{cr});
        CO_CustomerEmailController.sendEmailtoCustomerswithAttachment(new List<Customer_Request__c>{cr1});
        CO_CustomerEmailController.sendEmailtoCustomerswithAttachment(new List<Customer_Request__c>{cr2});
        test.stopTest(); 
    }
}