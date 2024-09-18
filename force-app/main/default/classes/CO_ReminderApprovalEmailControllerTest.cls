/*
@Name: CO_ReminderApprovalEmailControllerTest
@Purpose: This class is used for CO_ReminderApprovalEmailController test coverage
@History                                                            
@VERSION     AUTHOR              DATE              DETAIL
1.0        Jayashree R       11-25-2022        Initial Development
1.1        Aparajita         21-08-2023		    143268
*/
@isTest
public class CO_ReminderApprovalEmailControllerTest {
    @isTest
    public static void approvalProcessControllerTest(){
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        
        Profile profile = [Select Id From Profile where Name = 'System Administrator' limit 1];
        
        List<User> usrlist = new List<User>();
        
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
        usrlist.add(usr1);
        
        User usr2= new User();
        usr2.ProfileID = profile.Id;
        usr2.Username ='Test1@Testemail.com'+ System.currentTimeMillis(); 
        usr2.LastName ='TestLastname1';
        usr2.Email ='Test1@Testemail.com';
        usr2.Alias ='TestUsr1';
        usr2.Available_Countries__c='AU';
        usr2.TimeZoneSidKey ='TestCommunityNickname2';
        usr2.CommunityNickname ='TestCommunityNickname2';
        usr2.TimeZoneSidKey ='America/Los_Angeles';
        usr2.LocaleSidKey ='en_US';
        usr2.EmailEncodingKey ='UTF-8';
        usr2.LanguageLocaleKey ='en_US';
        usrlist.add(usr2);
        
        User usr3= new User();
        usr3.ProfileID = profile.Id;
        usr3.Username ='Test3@Testemail.com'+ System.currentTimeMillis(); 
        usr3.LastName ='TestLastname3';
        usr3.Email ='Test3@Testemail.com';
        usr3.Alias ='TestUsr3';
        usr3.Available_Countries__c='AU';
        usr3.TimeZoneSidKey ='TestCommunityNickname3';
        usr3.CommunityNickname ='TestCommunityNickname3';
        usr3.TimeZoneSidKey ='America/Los_Angeles';
        usr3.LocaleSidKey ='en_US';
        usr3.EmailEncodingKey ='UTF-8';
        usr3.LanguageLocaleKey ='en_US';
        usrlist.add(usr3);
        
        User usr4= new User();
        usr4.ProfileID = profile.Id;
        usr4.Username ='Test4@Testemail.com'+ System.currentTimeMillis(); 
        usr4.LastName ='TestLastname4';
        usr4.Email ='Test4@Testemail.com';
        usr4.Alias ='TestUsr4';
        usr4.Available_Countries__c='AU';
        usr4.TimeZoneSidKey ='TestCommunityNickname4';
        usr4.CommunityNickname ='TestCommunityNickname4';
        usr4.TimeZoneSidKey ='America/Los_Angeles';
        usr4.LocaleSidKey ='en_US';
        usr4.EmailEncodingKey ='UTF-8';
        usr4.LanguageLocaleKey ='en_US';
        usrlist.add(usr4);
        insert usrlist;
        
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
        
        Customer_Request__c cr = new Customer_Request__c(
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
            CO_Pricing_Approver__c = usr2.Id,
            CO_Additional_Approver__c = usr3.Id,
            CO_Routing_Approver__c = usr4.Id,
            CO_Pricing_master_data__c = 'Applicable',
            CO_Routing__c = 'Applicable',
            Delivering_Plant__c = delOption.Id,
            CO_Channel__c = channelOption.id,
            CO_Sales_Office__c = salesOption.id,
            CO_Language_for_SAP__c = 'E - English',
            CO_Address__PostalCode__s = '123456',
            CO_VAT_Reg_Number_1__c = '1234',
            CO_Contact_Person_Email__c = usr1.Email,
            CO_First_Name__c = 'abc',
            CO_Surname_Name__c = 'def'
        );
        insert cr;
        String name = [Select Name from Customer_Request__c where Id =: cr.Id].Name;
        
        List<ContentVersion> cvlist = new List<ContentVersion>();
        ContentVersion contentVersion = new ContentVersion(
            Title = name+'- Customer Details',
            PathOnClient = 'CustomerDetails.pdf',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true,
            RecordTypeId = Schema.sObjectType.ContentVersion.getRecordTypeInfosByDeveloperName().get('CO_Customer_Request').getRecordTypeId(),
            Content_Type__c = 'Pricing master data'
        );
        cvlist.add(contentVersion); 
        
        ContentVersion contentVersion1 = new ContentVersion(
            Title = name+'- Customer Details',
            PathOnClient = 'CustomerDetails.pdf',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true,
            RecordTypeId = Schema.sObjectType.ContentVersion.getRecordTypeInfosByDeveloperName().get('CO_Customer_Request').getRecordTypeId(),
            Content_Type__c = 'Routing'
        );
        cvlist.add(contentVersion1);   
        insert cvlist;
        
        List<ContentDocument> documents = [
            SELECT Id, Title, LatestPublishedVersionId 
            FROM ContentDocument
        ];
        
        List<ContentDocumentLink> cdlist = new List<ContentDocumentLink>();
        
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = cr.id;
        cdl.ContentDocumentId = documents[0].Id;
        cdl.shareType = 'V';
        cdlist.add(cdl);
        
        ContentDocumentLink cdl1 = New ContentDocumentLink();
        cdl1.LinkedEntityId = cr.id;
        cdl1.ContentDocumentId = documents[1].Id;
        cdl1.shareType = 'V';
        cdlist.add(cdl1);
        insert cdlist;
        
        System.assert(cr.Id!=null, 'customer request should exist');
        cr.CO_Status__c = 'IN REVIEW';
        Update cr;
        sendReminderEmail(cr);
        test.stopTest(); 
    }
    
    @isTest
    public static void approvalProcessControllerTestCE01(){
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryId = EDGE_UtilityTestClass.setupCountry('NL');
        
        Profile profile = [Select Id From Profile where Name = 'System Administrator' limit 1];
        
        List<User> usrlist = new List<User>();
        
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
        usrlist.add(usr1);
        
        User usr2= new User();
        usr2.ProfileID = profile.Id;
        usr2.Username ='Test1@Testemail.com'+ System.currentTimeMillis(); 
        usr2.LastName ='TestLastname1';
        usr2.Email ='Test1@Testemail.com';
        usr2.Alias ='TestUsr1';
        usr2.Available_Countries__c='NL';
        usr2.TimeZoneSidKey ='TestCommunityNickname2';
        usr2.CommunityNickname ='TestCommunityNickname2';
        usr2.TimeZoneSidKey ='America/Los_Angeles';
        usr2.LocaleSidKey ='en_US';
        usr2.EmailEncodingKey ='UTF-8';
        usr2.LanguageLocaleKey ='en_US';
        usrlist.add(usr2);
        
        User usr3= new User();
        usr3.ProfileID = profile.Id;
        usr3.Username ='Test3@Testemail.com'+ System.currentTimeMillis(); 
        usr3.LastName ='TestLastname3';
        usr3.Email ='Test3@Testemail.com';
        usr3.Alias ='TestUsr3';
        usr3.Available_Countries__c='NL';
        usr3.TimeZoneSidKey ='TestCommunityNickname3';
        usr3.CommunityNickname ='TestCommunityNickname3';
        usr3.TimeZoneSidKey ='America/Los_Angeles';
        usr3.LocaleSidKey ='en_US';
        usr3.EmailEncodingKey ='UTF-8';
        usr3.LanguageLocaleKey ='en_US';
        usrlist.add(usr3);
        
        User usr4= new User();
        usr4.ProfileID = profile.Id;
        usr4.Username ='Test4@Testemail.com'+ System.currentTimeMillis(); 
        usr4.LastName ='TestLastname4';
        usr4.Email ='Test4@Testemail.com';
        usr4.Alias ='TestUsr4';
        usr4.Available_Countries__c='NL';
        usr4.TimeZoneSidKey ='TestCommunityNickname4';
        usr4.CommunityNickname ='TestCommunityNickname4';
        usr4.TimeZoneSidKey ='America/Los_Angeles';
        usr4.LocaleSidKey ='en_US';
        usr4.EmailEncodingKey ='UTF-8';
        usr4.LanguageLocaleKey ='en_US';
        usrlist.add(usr4);
        
        insert usrlist;
        
        Sales_Organisation__c sOrg = new Sales_Organisation__c();
        sOrg.RecordTypeId = Schema.sObjectType.Sales_Organisation__c.getRecordTypeInfosByDeveloperName().get('SalesOrg').getRecordTypeId();
        sOrg.Name = 'Sales Org CE01';
        sOrg.Description__c = 'Sales Org CE01';
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
        
        test.startTest();
        
        Customer_Request__c cr = new Customer_Request__c(
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
            CO_DBBV_Finance__c = usr1.Id,
            CO_International_Trade_Team__c = usr2.Id,
            CO_Market_Finance_Delegate__c = usr3.Id,
            Delivering_Plant__c = delOption.Id,
            CO_Channel__c = channelOption.id,
            CO_Sales_Office__c = salesOption.id,
            CO_Language_for_SAP__c = 'E - English',
            CO_Address__PostalCode__s = '123456',
            CO_VAT_Reg_Number_1__c = '1234',
            CO_Contact_Person_Email__c = usr1.Email,
            CO_First_Name__c = 'abc',
            CO_Surname_Name__c = 'def',
            CO_GTME_or_Non_GTME__c = 'Non GTME',
            CO_Customer_Model__c = 'Model 10',
            CO_Customer_Located_in_EU__c = 'No'
        );      
        insert cr; 
        System.assert(cr.Id!=null, 'customer request should exist');
        cr.CO_Status__c = 'IN REVIEW';
        Update cr;
        sendReminderEmail(cr);
        test.stopTest(); 
    }
    
    @isTest
    public static void approvalProcessControllerTestBR01(){
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryId = EDGE_UtilityTestClass.setupCountry('NL');
        
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
        
        Sales_Organisation__c sOrg = new Sales_Organisation__c();
        sOrg.RecordTypeId = Schema.sObjectType.Sales_Organisation__c.getRecordTypeInfosByDeveloperName().get('SalesOrg').getRecordTypeId();
        sOrg.Name = 'Sales Org BR01';
        sOrg.Description__c = 'Sales Org BR01';
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
        
        test.startTest();
        
        Customer_Request__c cr = new Customer_Request__c(
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
            CO_Brand_Homes_Senior_Finance_Manager__c = usr1.Id,
            Delivering_Plant__c = delOption.Id,
            CO_Channel__c = channelOption.id,
            CO_Sales_Office__c = salesOption.id,
            CO_Language_for_SAP__c = 'E - English',
            CO_Address__PostalCode__s = '123456',
            CO_VAT_Reg_Number_1__c = '1234',
            CO_Contact_Person_Email__c = usr1.Email,
            CO_First_Name__c = 'abc',
            CO_Surname_Name__c = 'def',
            CO_GTME_or_Non_GTME__c = 'Non GTME',
            CO_Customer_Model__c = 'Model 10',
            CO_Customer_Located_in_EU__c = 'No'
        );
        insert cr;       
        System.assert(cr.Id!=null, 'customer request should exist');
        cr.CO_Status__c = 'IN REVIEW';
        Update cr;
        sendReminderEmail(cr);
        test.stopTest(); 
    }
    
    public static void sendReminderEmail(Customer_Request__c cr){      
        ProcessInstance objProcessInstance = [SELECT Id,TargetObjectId, CreatedDate FROM ProcessInstance WHERE TargetObjectId = :cr.Id];
        Datetime crCreatedDate = [SELECT CreatedDate FROM Customer_Request__c WHERE Id =: cr.Id].CreatedDate;
        System.assertEquals(crCreatedDate.date(),objProcessInstance.CreatedDate.date(),'Approval Process Created');
        
        Customer_Request__c crReq = [Select Id,Name 
                                     from Customer_Request__c where id =: cr.id];
        CO_ReminderApprovalEmailController.sendReminderEmail(new List<Customer_Request__c>{cr});
        EmailServicesAddress oEmailServiceAddress = [
            SELECT e.SystemModstamp, e.RunAsUserId, e.LocalPart, e.LastModifiedDate, e.LastModifiedById, e.IsActive, e.Id, e.FunctionId, e.EmailDomainName, e.CreatedDate, e.CreatedById, e.AuthorizedSenders 
            FROM EmailServicesAddress e
            WHERE e.IsActive = true and developerName= 'ReminderApprovalResponse'
        ].get(0);
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env    = new Messaging.InboundEnvelope();
        email.subject = 'Request Number- '+crReq.Name+'sent for approval process';
        email.plainTextBody = 'Approved \n'+'Comments';
        email.fromAddress = 'Test@Testemail.com';
        List<String> toStr= new List<String>{oEmailServiceAddress.LocalPart + '@' + oEmailServiceAddress.EmailDomainName};
            //List<String> toStr= new List<String>{'test@diageo.com'};
            email.toAddresses = toStr;
        CO_ReminderApprovalEmailController.handleInboundEmail(email,env);
    }
}