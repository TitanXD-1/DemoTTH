/*
@Name: CO_ApprovalProcessControllerTest
@Purpose: This class is used for CO_ApprovalProcessController and
CO_RecallApprovalProcess test coverage
@History                                                                                                                       
@VERSION    AUTHOR            DATE              DETAIL
1.0       Jayashree R       11-25-2022        Initial Development
1.1		   Aparajita        21-08-2023		   143268
*/
@isTest
public class CO_ApprovalProcessControllerTest {
    @isTest
    public static void approvalProcessControllerTest(){
        
        // EDGE_UtilityTestClass.createOrgSettings();
        
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        
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
        
        Pick_Up_Options__c taxOption = new Pick_Up_Options__c();
        taxOption.RecordTypeId = Schema.sObjectType.Pick_Up_Options__c.getRecordTypeInfosByDeveloperName().get('Tax_Classification').getRecordTypeId();
        taxOption.Name = 'CO Tax classification[AU]';
        taxOption.Sales_Organisation__c = sOrg.Id;
        taxOption.CO_SAP_Code__c = '1';
        taxOption.Geography__c = countryId;
        pOptionList.add(TaxOption);
        
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
        
        Customer_Request__c cr = new Customer_Request__c(
            CO_Email__c = 'test@diageo.com',
            Division__c = '10',
            CO_Credit_Limit__c = '100',
            CO_Last_Internal_Review_Date__c = System.today(),
            CO_Exchange_Rate_Type__c = 'M',
            CO_Customer_Pricing_Procedure__c = 'A',
            CO_Delivery_Priority__c = '02',   
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
            CO_Routing_Approver__c = usr1.Id,
            CO_Pricing_master_data__c = 'Applicable',
            CO_Routing__c = 'Applicable',
            Delivering_Plant__c = delOption.Id,
            CO_Channel__c = channelOption.id,
            CO_Sales_Office__c = salesOption.id,
            CO_Language_for_SAP__c = 'E - English',
            CO_Address__PostalCode__s = '123456',
            CO_VAT_Reg_Number_1__c = '1234'
        );
        insert cr;
        
        String name = [Select Name from Customer_Request__c where Id =: cr.Id].Name;
        System.assert(cr.Id!=null, 'customer request should exist');
        
        ContentVersion contentVersion = new ContentVersion(
            Title = name+'- Customer Details',
            PathOnClient = 'CustomerDetails.pdf',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true,
            RecordTypeId = Schema.sObjectType.ContentVersion.getRecordTypeInfosByDeveloperName().get('CO_Customer_Request').getRecordTypeId(),
            Content_Type__c = 'Pricing master data'
        );
        insert contentVersion;    
        List<ContentDocument> documents = [
            SELECT Id, Title, LatestPublishedVersionId 
            FROM ContentDocument
        ];
        
        //create ContentDocumentLink  record 
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = cr.id;
        cdl.ContentDocumentId = documents[0].Id;
        cdl.shareType = 'V';
        insert cdl;
        
        Tax_Classification__c tx = new Tax_Classification__c();
        tx.Tax_Category__c  = taxOption.Id;
        tx.Tax_Classification__c = '1 - Taxable';
        tx.Customer_Request__c = cr.Id;
        tx.CO_Enter_License_Details__c = false;
        insert tx;
        
        tx.CO_Enter_License_Details__c = true;
        tx.CO_License_Number__c = '5678';
        tx.CO_Valid_From__c = Date.newInstance(2023, 08, 9);
        tx.CO_Valid_To__c = Date.newInstance(2023, 08, 11);
        update tx;
        
        System.assert(cr.Id!=null, 'customer request should exist');
        cr.CO_Status__c = 'IN REVIEW';
        Update cr;
        test.startTest();
        sendApprovalMail(cr);
        cr.CO_Status__c = 'IN REVIEW';
        Update cr;
        test.stopTest(); 
    }
    
    @isTest
    public static void approvalProcessControllerTestCE01(){
        Id countryId = EDGE_UtilityTestClass.setupCountry('NL');
        
        Sales_Organisation__c sOrg = new Sales_Organisation__c();
        sOrg.RecordTypeId = Schema.sObjectType.Sales_Organisation__c.getRecordTypeInfosByDeveloperName().get('SalesOrg').getRecordTypeId();
        sOrg.Name = 'Test SO CE01';
        sOrg.Description__c = 'Test SO CE01';
        sOrg.Code__c = 'CE01';
        sOrg.Country__c = countryId;
        insert sOrg;
        
        List<Pick_Up_Options__c> pOptionList = new List<Pick_Up_Options__c>();
        Pick_Up_Options__c delOption = new Pick_Up_Options__c();
        delOption.RecordTypeId = Schema.sObjectType.Pick_Up_Options__c.getRecordTypeInfosByDeveloperName().get('Delivering_Plant').getRecordTypeId();
        delOption.Name = 'CO Delivering Plant[NL]';
        delOption.Sales_Organisation__c = sOrg.Id;
        delOption.CO_SAP_Code__c = '1';
        delOption.Geography__c = countryId;
        pOptionList.add(delOption);
        
        Pick_Up_Options__c channelOption = new Pick_Up_Options__c();
        channelOption.RecordTypeId = Schema.sObjectType.Pick_Up_Options__c.getRecordTypeInfosByDeveloperName().get('Channel').getRecordTypeId();
        channelOption.Name = 'CO Channel[NL]';
        channelOption.Sales_Organisation__c = sOrg.Id;
        channelOption.CO_SAP_Code__c = '1';
        channelOption.Geography__c = countryId;
        pOptionList.add(channelOption);
        
        Pick_Up_Options__c salesOption = new Pick_Up_Options__c();
        salesOption.RecordTypeId = Schema.sObjectType.Pick_Up_Options__c.getRecordTypeInfosByDeveloperName().get('Sales_office').getRecordTypeId();
        salesOption.Name = 'CO Sales Office[NL]';
        salesOption.Sales_Organisation__c = sOrg.Id;
        salesOption.CO_SAP_Code__c = '1';
        salesOption.Geography__c = countryId;
        pOptionList.add(salesOption);
        insert pOptionList;
        
        Profile profile = [Select Id From Profile where Name = 'System Administrator' limit 1];
        
        User usr1= new User();
        usr1.ProfileID = profile.Id;
        usr1.Username ='Test@Testemail.com'+ System.currentTimeMillis(); 
        usr1.LastName ='TestLastname';
        usr1.Email ='Test@Testemail.com';
        usr1.Alias ='TestUser';
        usr1.Available_Countries__c='NL';
        usr1.TimeZoneSidKey ='TestCommunityNickname1';
        usr1.CommunityNickname ='TestCommunityNickname1';
        usr1.TimeZoneSidKey ='America/Los_Angeles';
        usr1.LocaleSidKey ='en_US';
        usr1.EmailEncodingKey ='UTF-8';
        usr1.LanguageLocaleKey ='en_US';
        insert usr1;
        
        Customer_Request__c cr = new Customer_Request__c(
            CO_Email__c = 'test@diageo.com',
            Division__c = '10',
            CO_Credit_Limit__c = '100',
            CO_Last_Internal_Review_Date__c = System.today(),
            CO_Exchange_Rate_Type__c = 'M',
            CO_Customer_Pricing_Procedure__c = 'A',
            CO_Delivery_Priority__c = '02',   
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
            CO_DBBV_Finance__c = usr1.Id,
            CO_International_Trade_Team__c = usr1.Id,
            CO_Market_Finance_Delegate__c = usr1.Id,
            Delivering_Plant__c = delOption.Id,
            CO_Channel__c = channelOption.id,
            CO_Sales_Office__c = salesOption.id,
            CO_Language_for_SAP__c = 'E - English',
            CO_Address__PostalCode__s = '123456',
            CO_VAT_Reg_Number_1__c = '1234'
        );
        insert cr;
        System.assert(cr.Id!=null, 'customer request should exist');
        cr.CO_Status__c = 'IN REVIEW';
        Update cr;
        test.startTest();
        sendApprovalMail(cr);
        cr.CO_Status__c = 'IN REVIEW';
        Update cr;
        test.stopTest(); 
    }
    
    @isTest
    public static void approvalProcessControllerTestBR01(){
        Id countryId = EDGE_UtilityTestClass.setupCountry('NL');
        
        Sales_Organisation__c sOrg = new Sales_Organisation__c();
        sOrg.RecordTypeId = Schema.sObjectType.Sales_Organisation__c.getRecordTypeInfosByDeveloperName().get('SalesOrg').getRecordTypeId();
        sOrg.Name = 'Test SO BR01';
        sOrg.Description__c = 'Test SO BR01';
        sOrg.Code__c = 'BR01';
        sOrg.Country__c = countryId;
        insert sOrg;
        
        List<Pick_Up_Options__c> pOptionList = new List<Pick_Up_Options__c>();
        Pick_Up_Options__c delOption = new Pick_Up_Options__c();
        delOption.RecordTypeId = Schema.sObjectType.Pick_Up_Options__c.getRecordTypeInfosByDeveloperName().get('Delivering_Plant').getRecordTypeId();
        delOption.Name = 'CO Delivering Plant[NL]';
        delOption.Sales_Organisation__c = sOrg.Id;
        delOption.CO_SAP_Code__c = '1';
        delOption.Geography__c = countryId;
        pOptionList.add(delOption);
        
        Pick_Up_Options__c channelOption = new Pick_Up_Options__c();
        channelOption.RecordTypeId = Schema.sObjectType.Pick_Up_Options__c.getRecordTypeInfosByDeveloperName().get('Channel').getRecordTypeId();
        channelOption.Name = 'CO Channel[NL]';
        channelOption.Sales_Organisation__c = sOrg.Id;
        channelOption.CO_SAP_Code__c = '1';
        channelOption.Geography__c = countryId;
        pOptionList.add(channelOption);
        
        Pick_Up_Options__c salesOption = new Pick_Up_Options__c();
        salesOption.RecordTypeId = Schema.sObjectType.Pick_Up_Options__c.getRecordTypeInfosByDeveloperName().get('Sales_office').getRecordTypeId();
        salesOption.Name = 'CO Sales Office[NL]';
        salesOption.Sales_Organisation__c = sOrg.Id;
        salesOption.CO_SAP_Code__c = '1';
        salesOption.Geography__c = countryId;
        pOptionList.add(salesOption);
        insert pOptionList;
        
        Profile profile = [Select Id From Profile where Name = 'System Administrator' limit 1];
        
        User usr1= new User();
        usr1.ProfileID = profile.Id;
        usr1.Username ='Test@Testemail.com'+ System.currentTimeMillis(); 
        usr1.LastName ='TestLastname';
        usr1.Email ='Test@Testemail.com';
        usr1.Alias ='TestUser';
        usr1.Available_Countries__c='NL';
        usr1.TimeZoneSidKey ='TestCommunityNickname1';
        usr1.CommunityNickname ='TestCommunityNickname1';
        usr1.TimeZoneSidKey ='America/Los_Angeles';
        usr1.LocaleSidKey ='en_US';
        usr1.EmailEncodingKey ='UTF-8';
        usr1.LanguageLocaleKey ='en_US';
        insert usr1;
        
        Customer_Request__c cr = new Customer_Request__c(
            CO_Email__c = 'test@diageo.com',
            Division__c = '10',
            CO_Credit_Limit__c = '100',
            CO_Last_Internal_Review_Date__c = System.today(),
            CO_Exchange_Rate_Type__c = 'M',
            CO_Customer_Pricing_Procedure__c = 'A',
            CO_Delivery_Priority__c = '02',   
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
            CO_Brand_Homes_Senior_Finance_Manager__c = usr1.Id,
            Delivering_Plant__c = delOption.Id,
            CO_Channel__c = channelOption.id,
            CO_Sales_Office__c = salesOption.id,
            CO_Language_for_SAP__c = 'E - English',
            CO_Address__PostalCode__s = '123456',
            CO_VAT_Reg_Number_1__c = '1234'
        );
        insert cr;
        System.assert(cr.Id!=null, 'customer request should exist');
        cr.CO_Status__c = 'IN REVIEW';
        Update cr;
        test.startTest();
        sendApprovalMail(cr);
        cr.CO_Status__c = 'IN REVIEW';
        Update cr;
        test.stopTest(); 
    }
    
    public static void sendApprovalMail(Customer_Request__c cr){
        CO_ApprovalProcessController.getRecord(cr.Id);
        CO_ApprovalProcessController.getChildRecords(cr.Id);
        CO_ApprovalProcessController.getTaxClassificationRecords(cr.Id);
        
        ProcessInstance objProcessInstance = [SELECT Id,TargetObjectId, CreatedDate FROM ProcessInstance WHERE TargetObjectId = :cr.Id];
        Datetime crCreatedDate = [SELECT CreatedDate FROM Customer_Request__c WHERE Id =: cr.Id].CreatedDate;
        System.assertEquals(crCreatedDate.date(),objProcessInstance.CreatedDate.date(),'Approval Process Created');
        
        cr.CO_Status__c = 'IN QUERY';
        Update cr;
        CO_RecallApprovalProcess.recallApproval(new List<Id>{cr.Id});
        List<ProcessInstanceWorkitem> piwi = [SELECT Id, ProcessInstanceId, ProcessInstance.TargetObjectId FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId =: cr.id];
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env    = new Messaging.InboundEnvelope();
        email.subject = '{\"sAction\" : \"mApprovalRecallActionWithAdminPermissions\", \"sApprovalID\" : \"'+piwi.get(0).Id +'\"}';
        email.plainTextBody = '{\"sAction\" : \"mApprovalRecallActionWithAdminPermissions\", \"sApprovalID\" : \"'+piwi.get(0).Id +'\"}';
        email.fromAddress = 'test@test.com';
        List<String> toStr= new List<String>{'gb.qa@diageo.com'};
            email.toAddresses = toStr;
        email.ccAddresses = toStr;
        CO_RecallApprovalProcess.handleInboundEmail(email,env);
    }
}