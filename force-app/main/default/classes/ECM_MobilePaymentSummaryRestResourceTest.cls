/*
@Name: ECM_MobilePaymentSummaryRestResourceTest
@Description: This class covers test coverage for ECM_MobilePaymentSummaryRestResource.
@History:                                                           
@VERSION			AUTHOR					DATE				DETAIL
@1.0			Pratik Somani			11/03/2022			ECM-5310 : Payment summary SFDC_need to validate the existing code to reconfigure it to access it through mobile (Part 1)
@1.1			Saurav Prasad			11/03/2022			ECM-5315 : Payment summary SFDC_need to validate the existing code to reconfigure it to access it through mobile (Part 2)
*/
@isTest
public class ECM_MobilePaymentSummaryRestResourceTest {
	
    @isTest
    public static void testMobilePaymentSummaryRestResource(){
                
        Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES');
        Id uid;
        uid = userinfo.getUserId();

        
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        acc.BillingStreet = '17 Asian Highway1 45';
        insert acc;
        System.assert(acc!=null,'acc should not be null');
        acc.country__c = geographyId;
        acc.Sales_Org__c ='sale';
        acc.SAP_Sold_to__c ='sapsold';
        update acc;
        
        Account acc1 = EDGE_UtilityTestClass.getDistriAccRec();
        acc1.country__c = geographyId;
        insert acc1;
        
        Contact con = new Contact();
        con.LastName = 'My';
        con.FirstName = 'Test';
        con.Email = 'test@abc.com';
        con.AccountId = acc1.id;
        con.Contact_Type__c = 'Primary';
        insert con;
        
        ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
        contractType.Name='Promotional';
        contractType.Geography__c=geographyId;
        contractType.ECM_Abbreviation__c='POM';
        contractType.ECM_Automatic_approval_amount_threshold__c=40.00;
        contractType.Volume_UoM_for_Spirits__c='CAS';
        contractType.ECM_Screen_3_field_configuration__c='Product Name;Volume Target;';
        contractType.ECM_Volume_UoM_for_Beer__c = 'KEG';
        insert contractType;
        
        Date myDate = Date.newInstance(2020, 5, 17);
        List<Contract> contractlst =new List<Contract>();
        Contract contr = new Contract(Name = 'Test',AccountId = acc.id,StartDate=myDate.addMonths(-6).toStartOfMonth(),Contract_End_Date__c=myDate.addMonths(1).toStartOfMonth().addDays(-1),ECM_Duration__c=myDate.addMonths(-6).toStartOfMonth().monthsBetween(myDate.addMonths(1).toStartOfMonth()),ECM_Agreement_Type__c=contractType.Id);
        contractlst.add(contr); 
        Contract contr1 = new Contract(Name = 'Test1',AccountId = acc.id,StartDate=myDate.addMonths(-6).toStartOfMonth(),Contract_End_Date__c=myDate.addMonths(1).toStartOfMonth().addDays(-1),ECM_Duration__c=myDate.addMonths(-6).toStartOfMonth().monthsBetween(myDate.addMonths(1).toStartOfMonth()));
        contractlst.add(contr1);
        insert contractlst;  
        
        contr.Status = 'Active';
        update contr;
        
        AccountContactRelation acr = new AccountContactRelation();
        acr.AccountId = acc.id;
        acr.ContactId = con.id;
        acr.Contact_Type__c = 'Primary';
        acr.IsActive = true;
        insert acr;
        String bannerRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        
        Pick_Up_Options__c budgetTypeObj= ECM_UtilityTestClass.createPickUpOption(geographyId,bannerRecordTypeId);
        budgetTypeObj.Name='TI[ES]';
        budgetTypeObj.Geography__c=geographyId;
        budgetTypeObj.ECM_SAP_Order_reason__c = 'Y10'; 
        budgetTypeObj.ECM_SAP_Pricing_condition__c = 'O25';
        insert budgetTypeObj;
        
        Pick_Up_Options__c budgetTypeObj2= new Pick_Up_Options__c();
        budgetTypeObj2.Name='On-Premise[AU]';
        budgetTypeObj2.Geography__c=geographyId;
        budgetTypeObj2.RecordTypeId=Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
        budgetTypeObj2.ECM_SAP_Order_reason__c = 'Y10'; 
        budgetTypeObj2.ECM_SAP_Pricing_condition__c = 'O25';
        insert budgetTypeObj2;
        

        ECM_Payment_Summary__c paymemtSummary2 = new ECM_Payment_Summary__c();
        paymemtSummary2.ECM_Total_Amount_Confirmed__c = 20.00;
        paymemtSummary2.ECM_Payment_Summary_Status__c = 'Open';
        paymemtSummary2.ECM_Type__c = 'Volume-Based';
        paymemtSummary2.ECM_Invoice_Status__c='Requested';
        paymemtSummary2.ECM_Contract__c = contr.id;
        paymemtSummary2.ECM_Start_Period__c = system.today();
        paymemtSummary2.ECM_End_Period__c = system.today()+2;
        paymemtSummary2.ECM_Budget_types__c = budgetTypeObj.id;
        paymemtSummary2.ECM_Invoice_Status__c ='Approved';
        paymemtSummary2.ECM_Invoice_Receival_Date__c = system.today()+1;
        paymemtSummary2.ECM_SAP_payment_Reference_Number__c=10;
        paymemtSummary2.ECM_Email_Sent__c =false;
        //paymemtSummary2.ownerid = uid;
        insert paymemtSummary2;
       
        
   
        
        Test.startTest();
         List<BusinessHours> bHourList = [select id from BusinessHours];
        Market_Setting__c mktSetting = new Market_Setting__c();
        mktSetting.Name = 'Market Setting';
        mktSetting.Geography__c = geographyId;
        mktSetting.Business_Hours__c = bHourList[0].Id;
        mktSetting.Minimum_Product_Assortment__c = 'Binary';
        mktSetting.Minimum_Activation_Standards__c = 'Binary';
        mktSetting.Distribution__c = 'Binary';
        mktSetting.New_Product_Distribution__c = 'Progressive';
        mktSetting.Open_Opportunity__c = 'Calculative';
        mktSetting.Closed_Opportunity__c = 'Calculative';
        mktSetting.Outlet_Execution_Score__c = 'Calculative';
        mktSetting.A_P_Threshold__c=10;
        mktSetting.Prospect_Approver__c = 'Sales Manager & MDM Approval Required' ;
        mktSetting.ECM_SAP_Order_Type__c = 'Sap';
        mktSetting.ECM_Evidence_email_enabled__c=true;
        mktSetting.ECM_Payment_Management_Email__c='TEST@test.com';
        mktSetting.ECM_Diageo_Entity_Address_for_Invoicing__c='TEST@test.com';
        mktSetting.ECM_Payment_Evidence_Pre_Payment_SP__c='ECM_PaymentSummaryEvidenceRequestPrePySP';
        mktSetting.ECM_Payment_Evidence_Pre_Payment__c='ECM_PaymentSummaryEvidenceRequestPrePay';
        mktSetting.ECM_Payment_Evidence_template__c='ECM_PaymentSummaryEvidenceRequestStd';
        mktSetting.ECM_Payment_Evidence_SP_template__c='ECM_PaymentSummaryEvidenceRequestStdSP';
        mktSetting.ECM_Payment_Invoice_SP_template__c='ECM_PaymentSummaryInvoiceRequestSP';
        mktSetting.ECM_Payment_Invoice_template__c='ECM_PaymentSummaryInvoiceRequest';
        mktSetting.ECM_Manager_Approval__c = 'Promo-Standard;Volume-Based;Promo-PrePayment';
       
        insert mktSetting;
        
        Product__c product = new Product__c();
        product.Name='Test';
        product.Product_Full_Name__c='Test';
        product.Country__c=geographyId;
        insert product;
        
        Market_Assortment_Product__c marketassort1 = new Market_Assortment_Product__c();
        marketassort1.Product__c=product.Id;
        marketassort1.Market_Assortment__c=geographyId;
        marketassort1.ECM_INTO_Material__c = 9;
        insert marketassort1;
        
        ECM_Contract_Item__c newcontractitem= new ECM_Contract_Item__c();
        newcontractitem.ECM_Contract__c=contr.Id;
        newcontractitem.ECM_Product__c=marketassort1.id;
        insert newcontractitem;
        
        ECM_Tiering__c tier= new ECM_Tiering__c();
        tier.ECM_Contract_Item__c=newcontractitem.Id;
        tier.ECM_Tier_1_rate_per_UoM__c=1.00;
        tier.ECM_Tier_1_volume_limit__c=1;
        tier.ECM_Tier2_rate_per_UoM__c=2.00;
        tier.ECM_Tier_2_volume_limit__c=2;
        tier.ECM_Tier_3_rate_per_UoM__c=3.00;
        tier.ECM_Tier_3_volume_limit__c=3;
        insert tier;
        
        ECM_Payment_Summary_Item__c paymemtSummaryItem = new ECM_Payment_Summary_Item__c();
        paymemtSummaryItem.ECM_Payment_Summary__c = paymemtSummary2.id;
        paymemtSummaryItem.ECM_Confirm__c = true;
        paymemtSummaryItem.ECM_Contract_Item__c = newcontractitem.id;			
        paymemtSummaryItem.ECM_Confirmed_Amount_Per_Payment__c =10;
        insert paymemtSummaryItem;
        
    
		String reqBody = '{'+
                        '"Id" :"'+ paymemtSummary2.id +'",'+
                        '"ECM_Type__c" : "Volume-Based",'+
                        '"ECM_Payment_Summary_Status__c" : "Submitted",'+
           				'"Payment_Summary_Item__r" : {'+
                        '"totalSize" : 1,'+
           				'"done" : true,'+
             			'"records" :'+
           				 '['+
             			 '{'+
                        '"Id" :"'+paymemtSummaryItem.Id+'",'+
                        '"ECM_Confirm__c" : true,'+
                        '"ECM_Confirmed_Volume__c" : 100,'+
                        '"ECM_To_Pay__c" : false,'+
                        '"ECM_Reject__c" : false,'+
                        '"ECM_Confirmed_Amount_Per_Payment__c" : 100' +
                        '}'+
                        ']'+
                        '}'+
                        '}';
   
            
        system.debug(LoggingLevel.Debug,'test_reqBody' + reqBody);
        
        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();
        RestContext.response = resp;
        RestContext.response.addHeader('Content-Type', 'application/json');   
        req.httpMethod = 'POST';//HTTP Request Type
    	req.requestBody = Blob.valueof(reqBody);
    	RestContext.request = req;
        ECM_MobilePaymentSummaryRestResource.PaymentSummaryConfirmation();
        Test.stopTest();
    }
    
      @isTest
    public static void testMobilePaymentSummaryRestResourceError(){
                
        Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES');
        Id uid;
        uid = userinfo.getUserId();

        
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        acc.BillingStreet = '17 Asian Highway1 45';
        insert acc;
        System.assert(acc!=null,'acc should not be null');
        acc.country__c = geographyId;
        acc.Sales_Org__c ='sale';
        acc.SAP_Sold_to__c ='sapsold';
        update acc;
        
        Account acc1 = EDGE_UtilityTestClass.getDistriAccRec();
        acc1.country__c = geographyId;
        insert acc1;
        
        Contact con = new Contact();
        con.LastName = 'My';
        con.FirstName = 'Test';
        con.Email = 'test@abc.com';
        con.AccountId = acc1.id;
        con.Contact_Type__c = 'Primary';
        insert con;
        
        ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
        contractType.Name='Promotional';
        contractType.Geography__c=geographyId;
        contractType.ECM_Abbreviation__c='POM';
        contractType.ECM_Automatic_approval_amount_threshold__c=40.00;
        contractType.Volume_UoM_for_Spirits__c='CAS';
        contractType.ECM_Screen_3_field_configuration__c='Product Name;Volume Target;';
        contractType.ECM_Volume_UoM_for_Beer__c = 'KEG';
        insert contractType;
        
        Date myDate = Date.newInstance(2020, 5, 17);
        List<Contract> contractlst =new List<Contract>();
        Contract contr = new Contract(Name = 'Test',AccountId = acc.id,StartDate=myDate.addMonths(-6).toStartOfMonth(),Contract_End_Date__c=myDate.addMonths(1).toStartOfMonth().addDays(-1),ECM_Duration__c=myDate.addMonths(-6).toStartOfMonth().monthsBetween(myDate.addMonths(1).toStartOfMonth()),ECM_Agreement_Type__c=contractType.Id);
        contractlst.add(contr); 
        Contract contr1 = new Contract(Name = 'Test1',AccountId = acc.id,StartDate=myDate.addMonths(-6).toStartOfMonth(),Contract_End_Date__c=myDate.addMonths(1).toStartOfMonth().addDays(-1),ECM_Duration__c=myDate.addMonths(-6).toStartOfMonth().monthsBetween(myDate.addMonths(1).toStartOfMonth()));
        contractlst.add(contr1);
        insert contractlst;  
        
        contr.Status = 'Active';
        update contr;
        
        AccountContactRelation acr = new AccountContactRelation();
        acr.AccountId = acc.id;
        acr.ContactId = con.id;
        acr.Contact_Type__c = 'Primary';
        acr.IsActive = true;
        insert acr;
        String bannerRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        
        Pick_Up_Options__c budgetTypeObj= ECM_UtilityTestClass.createPickUpOption(geographyId,bannerRecordTypeId);
        budgetTypeObj.Name='TI[ES]';
        budgetTypeObj.Geography__c=geographyId;
        budgetTypeObj.ECM_SAP_Order_reason__c = 'Y10'; 
        budgetTypeObj.ECM_SAP_Pricing_condition__c = 'O25';
        insert budgetTypeObj;
        
        Pick_Up_Options__c budgetTypeObj2= new Pick_Up_Options__c();
        budgetTypeObj2.Name='On-Premise[AU]';
        budgetTypeObj2.Geography__c=geographyId;
        budgetTypeObj2.RecordTypeId=Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
        budgetTypeObj2.ECM_SAP_Order_reason__c = 'Y10'; 
        budgetTypeObj2.ECM_SAP_Pricing_condition__c = 'O25';
        insert budgetTypeObj2;
        

        ECM_Payment_Summary__c paymemtSummary2 = new ECM_Payment_Summary__c();
        paymemtSummary2.ECM_Total_Amount_Confirmed__c = 20.00;
        paymemtSummary2.ECM_Payment_Summary_Status__c = 'Open';
        paymemtSummary2.ECM_Type__c = 'Volume-Based';
        paymemtSummary2.ECM_Invoice_Status__c='Requested';
        paymemtSummary2.ECM_Contract__c = contr.id;
        PaymemtSummary2.ECM_Start_Period__c = system.today();
        paymemtSummary2.ECM_End_Period__c = system.today()+2;
        paymemtSummary2.ECM_Budget_types__c = budgetTypeObj.id;
        paymemtSummary2.ECM_Invoice_Status__c ='Approved';
        paymemtSummary2.ECM_Invoice_Receival_Date__c = system.today()+1;
        paymemtSummary2.ECM_SAP_payment_Reference_Number__c=10;
        paymemtSummary2.ECM_Email_Sent__c =false;
        //paymemtSummary2.ownerid = uid;
        insert paymemtSummary2;
       
        
   
        
        Test.startTest();
         List<BusinessHours> bHourList = [select id from BusinessHours];
        Market_Setting__c mktSetting = new Market_Setting__c();
        mktSetting.Name = 'Market Setting';
        mktSetting.Geography__c = geographyId;
        mktSetting.Business_Hours__c = bHourList[0].Id;
        mktSetting.Minimum_Product_Assortment__c = 'Binary';
        mktSetting.Minimum_Activation_Standards__c = 'Binary';
        mktSetting.Distribution__c = 'Binary';
        mktSetting.New_Product_Distribution__c = 'Progressive';
        mktSetting.Open_Opportunity__c = 'Calculative';
        mktSetting.Closed_Opportunity__c = 'Calculative';
        mktSetting.Outlet_Execution_Score__c = 'Calculative';
        mktSetting.A_P_Threshold__c=10;
        mktSetting.Prospect_Approver__c = 'Sales Manager & MDM Approval Required' ;
        mktSetting.ECM_SAP_Order_Type__c = 'Sap';
        mktSetting.ECM_Evidence_email_enabled__c=true;
        mktSetting.ECM_Payment_Management_Email__c='TEST@test.com';
        mktSetting.ECM_Diageo_Entity_Address_for_Invoicing__c='TEST@test.com';
        mktSetting.ECM_Payment_Evidence_Pre_Payment_SP__c='ECM_PaymentSummaryEvidenceRequestPrePySP';
        mktSetting.ECM_Payment_Evidence_Pre_Payment__c='ECM_PaymentSummaryEvidenceRequestPrePay';
        mktSetting.ECM_Payment_Evidence_template__c='ECM_PaymentSummaryEvidenceRequestStd';
        mktSetting.ECM_Payment_Evidence_SP_template__c='ECM_PaymentSummaryEvidenceRequestStdSP';
        mktSetting.ECM_Payment_Invoice_SP_template__c='ECM_PaymentSummaryInvoiceRequestSP';
        mktSetting.ECM_Payment_Invoice_template__c='ECM_PaymentSummaryInvoiceRequest';
        mktSetting.ECM_Manager_Approval__c = 'Promo-Standard;Volume-Based;Promo-PrePayment';
       
        insert mktSetting;
        
        Product__c product = new Product__c();
        product.Name='Test';
        product.Product_Full_Name__c='Test';
        product.Country__c=geographyId;
        insert product;
        
        Market_Assortment_Product__c marketassort1 = new Market_Assortment_Product__c();
        marketassort1.Product__c=product.Id;
        marketassort1.Market_Assortment__c=geographyId;
        marketassort1.ECM_INTO_Material__c = 9;
        insert marketassort1;
        
        ECM_Contract_Item__c newcontractitem= new ECM_Contract_Item__c();
        newcontractitem.ECM_Contract__c=contr.Id;
        newcontractitem.ECM_Product__c=marketassort1.id;
        insert newcontractitem;
        
        ECM_Tiering__c tier= new ECM_Tiering__c();
        tier.ECM_Contract_Item__c=newcontractitem.Id;
        tier.ECM_Tier_1_rate_per_UoM__c=1.00;
        tier.ECM_Tier_1_volume_limit__c=1;
        tier.ECM_Tier2_rate_per_UoM__c=2.00;
        tier.ECM_Tier_2_volume_limit__c=2;
        tier.ECM_Tier_3_rate_per_UoM__c=3.00;
        tier.ECM_Tier_3_volume_limit__c=3;
        insert tier;
        
        ECM_Payment_Summary_Item__c paymemtSummaryItem = new ECM_Payment_Summary_Item__c();
        paymemtSummaryItem.ECM_Payment_Summary__c = paymemtSummary2.id;
        paymemtSummaryItem.ECM_Confirm__c = true;
        paymemtSummaryItem.ECM_Contract_Item__c = newcontractitem.id;			
        paymemtSummaryItem.ECM_Confirmed_Amount_Per_Payment__c =10;
        insert paymemtSummaryItem;
        
    
		String reqBody = '{'+
                        '"Id" :"'+ PaymemtSummary2.id +'",'+
                        '"ECM_Type__c" : "Volume-Based",'+
                        '"ECM_Payment_Summary_Status__c" : "Open",'+
           				'"Payment_Summary_Item__r" : {'+
                        '"totalSize" : 1,'+
           				'"done" : true,'+
             			'"records" :'+
           				 '['+
             			 '{'+
                        '"Id" :"'+paymemtSummaryItem.Id+'",'+
                        '"ECM_Confirm__c" : true,'+
                        '"ECM_Confirmed_Volume__c" : 100,'+
                        '"ECM_To_Pay__c" : false,'+
                        '"ECM_Reject__c" : false,'+
                        '"ECM_Confirmed_Amount_Per_Payment__c" : 100' +
                        '}'+
                        ']'+
                        '}'+
                        '}';
   
            
        system.debug(LoggingLevel.Debug,'test_reqBody' + reqBody);
        
        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();
        RestContext.response = resp;
        RestContext.response.addHeader('Content-Type', 'application/json');   
        req.httpMethod = 'POST';//HTTP Request Type
    	req.requestBody = Blob.valueof(reqBody);
    	RestContext.request = req;
        ECM_MobilePaymentSummaryRestResource.PaymentSummaryConfirmation();
        Test.stopTest();
    }
    @isTest
    public static void testMobilePaymentSummaryRestResourceException(){
        //Rest bofy with invalid ID to test the exceptional handling
        String reqBody = '{'+
                        '"Id" :"a3O9E000000DhxVUAS",'+
                        '"ECM_Type__c" : "Volume-Based",'+
                        '"ECM_Payment_Summary_Status__c" : "In Approval process",'+
           				'"Payment_Summary_Item__r" : {'+
                        '"totalSize" : 1,'+
           				'"done" : true,'+
             			'"records" :'+
           				 '['+
             			 '{'+
                        '"Id" :"a3O9E000000DhxVUAS",'+
                        '"ECM_Confirm__c" : true,'+
                        '"ECM_Confirmed_Volume__c" : 100,'+
                        '"ECM_To_Pay__c" : false,'+
                        '"ECM_Reject__c" : false,'+
                        '"ECM_Confirmed_Amount_Per_Payment__c" : 100' +
                        '}'+
                        ']'+
                        '}'+
                        '}';
   
            
        system.debug(LoggingLevel.Debug,'test_reqBody' + reqBody);
        System.assert(reqBody!=null,'reqBody should not be null');
        
        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();
        RestContext.response = resp;
        RestContext.response.addHeader('Content-Type', 'application/json');   
        req.httpMethod = 'POST';//HTTP Request Type
    	req.requestBody = Blob.valueof(reqBody);
    	RestContext.request = req;
        Test.startTest();
        ECM_MobilePaymentSummaryRestResource.PaymentSummaryConfirmation();
        Test.stopTest();
    }
}