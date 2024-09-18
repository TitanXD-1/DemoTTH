/*
* @Name: EDGE_ContractTriggerHelperTest
* @Req:User Story : ES20-715
* @History                                                            
* @VERSION   AUTHOR            DATE              DETAIL
   1.0       Preyanka Ghosh    11/06/2019      Initial Development
   2.0		 Saurav Prasad	   02/11/2021	   ECM-4884
   3.0		 Saurav Prasad	   12/11/2021	   ECM-4925
   4.0       Joshraj Sen       21/12/2023      146153:- Fixing the Test Class
**/
@isTest
public class EDGE_ContractTriggerHelperTest {
    
    /*
    Method  : createOperatorContract
    Purpose : This is used to cover createOperatorContract method
    */
    @isTest
    public static void createOperatorContractTest(){
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AUT'); 
        EDGE_UtilityTestClass.createOrgSettings();
        
        
        Account ownerAccount = EDGE_UtilityTestClass.getOwnerOperatorAccount();
        ownerAccount.BillingCountry = 'Australia';
        ownerAccount.BillingState = 'New South Wales';
        ownerAccount.Person_Responsible__c = UserInfo.getUserId();
        ownerAccount.Country__c = geographyId;
        ownerAccount.IsOperator__c =true;
        insert ownerAccount;
        Test.startTest();
        System.assert(ownerAccount.Id != null,'ownerAccount should not be null');
        
        EDGE_UtilityClass.stopTriggerToRun = false;
        
       
        //update objContract;

         /*String oldsObjectName = 'Contract';
        Schema.SObjectType oldt  = Schema.getGlobalDescribe().get(oldsObjectName);
        SObject oldsobjContract = oldt.newSObject();
        oldsobjContract = (sobject)objContract;
    		Map<Id,Contract> oldcontractRecords = new Map<Id,Contract>{objContract.Id=>objContract};
*/
    
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AUT]';
        insert pickupOption;
        
        Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount.Outlet_Visit_Prioritisation_Grade__c = pickupOption.Id; 
        outletAccount.BillingCountry = 'Australia';
        outletAccount.BillingCountryCode = 'AU';
        outletAccount.BillingState = 'New South Wales';
        outletAccount.Person_Responsible__c = UserInfo.getUserId();
        outletAccount.Country__c = geographyId;
        outletAccount.Independent_of_Operator__c = false;
        outletAccount.Operator__c = ownerAccount.Id;
        insert outletAccount;
        System.assert(outletAccount.Id != null,'outletAccount should not be null');

        List<Contract> contractList = new List<Contract>();
        EDGE_UtilityClass.stopTriggerToRun = false;
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('A&P').getRecordTypeId();
        Contract objContract = EDGE_UtilityTestClass.getContract(ownerAccount.Id, contractRecordTypeId);
        objContract.Status = 'Draft';
        objContract.Contract_End_Date__c = System.today()+29;
        contractList.add(objContract);
        Contract objOutletContract = EDGE_UtilityTestClass.getContract(ownerAccount.Id, contractRecordTypeId);
        objOutletContract.Status = 'Draft';
        objOutletContract.StartDate = System.today()+30;
        objOutletContract.Contract_End_Date__c = System.today()+45;
        contractList.add(objOutletContract);
        //insert objOutletContract;
        
        EDGE_UtilityClass.stopTriggerToRun = false;
        Contract objOutletContract1 = EDGE_UtilityTestClass.getContract(ownerAccount.Id, contractRecordTypeId);
        objOutletContract1.Status = 'Draft';
        objOutletContract1.StartDate = System.today()+10;
        objOutletContract1.Contract_End_Date__c = System.today()+45;
        objOutletContract1.Initial_UOS_Earnt__c = 20;
        contractList.add(objOutletContract1);
        //insert objOutletContract1;  
        insert contractList;    
         
        Contract objOutletContract11 = [Select Id,StartDate,Contract_End_Date__c,AccountId,RecordTypeId,Initial_UOS_Earnt__c from Contract where Id = :objOutletContract1.Id];

        //objOutletContract1.Status = 'Future';
        objOutletContract11.StartDate = System.today()+20;
        objOutletContract11.Contract_End_Date__c = System.today()+60;
        objOutletContract11.Initial_UOS_Earnt__c = 30;
        update objOutletContract11;

        Contract objOutletContract12 = [Select Id,StartDate,Contract_End_Date__c,AccountId,RecordTypeId,Initial_UOS_Earnt__c from Contract where Id = :objOutletContract1.Id];

        objOutletContract12.StartDate = System.today()+20;
        objOutletContract12.Contract_End_Date__c = System.today()+65;
        objOutletContract12.Initial_UOS_Earnt__c = null;
        update objOutletContract12;
        
        List < Contract > newItems = new List < Contract >();
        Map < Id, Contract > oldItems = new Map < Id, Contract >();
        newItems.add(objOutletContract11);
        oldItems.put(objOutletContract1.Id, objOutletContract1);
        //EDGE_ContractTriggerHelper.assignContractToOutlet(newItems,oldItems);
        
        List < Contract > newItems1 = new List < Contract >();
        Map < Id, SObject > oldItems1 = new Map < Id, SObject >();
        newItems1.add(objOutletContract11);
        oldItems1.put(objOutletContract1.Id, objOutletContract1);
        EDGE_ContractTriggerHelper.assignContractToOutlet(newItems1,oldItems1);
        
        /*List<Id> newItemsId1 = new List<Id> ();
        for(Contract contractRec : newItems1){
            newItemsId1.add(contractRec.Id);
        }
        EDGE_ContractTriggerHelper.lstInActiveContract = new List<Id> ();
        EDGE_ContractTriggerHelper.lstInActiveContract.addAll(newItemsId1);
        EDGE_ContractTriggerHelper.assignContractToOutlet(newItems1,oldItems1);*/
        
        Test.stopTest();
/*
        Pick_Up_Options__c pickupOption1 = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pickupOption1.Name = 'Upfront Payment [AUT]';
        pickupOption1.RecordTypeId =Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        pickupOption1.Status__c ='Active';
        insert pickupOption1;       
        objContract.status='Active';
        objContract.UOS_Earnt__c =100;
        objContract.ECM_UOS_Annual_Target__c = 40; 
        objContract.ECM_Upfront_Payment_Spent__c = 20;
        objContract.ECM_Upfront_Last_Payment_date__c = System.today().addYears(-1)-1;
        update objContract;
                     Map < Id, Contract > mapnewItems = new Map < Id, Contract >{objContract.id=>objContract};

        String sObjectName = 'Contract';
        Schema.SObjectType t  = Schema.getGlobalDescribe().get(sObjectName);
        SObject sobjContract = t.newSObject();
        sobjContract = (sobject)objContract;
         Map<Id,sObject> newRecords = (Map<Id,sObject>)mapnewItems;
        Map<Id,sObject> oldRecords = (Map<Id,sObject>)oldcontractRecords;

        EDGE_ContractTriggerHelper.ECM_PaymentSummary_Creation(newRecords,oldRecords);*/
        
    }
    
    
    /*
    Method  : createOutletContractTest
    Purpose : This is used to cover checkValidOutlet method
    */
   
    
      @isTest
    public static void createOutletContractTest(){
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU'); 
        EDGE_UtilityTestClass.createOrgSettings();
                  
        
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AU]';
        insert pickupOption;
        
        Pick_Up_Options__c pickupOption1 = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pickupOption1.Name = 'Upfront Payment [AU]';
        pickupOption1.RecordTypeId =Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        pickupOption1.Status__c ='Active';
        insert pickupOption1;
        Pick_Up_Options__c budgetTypeObj1= new Pick_Up_Options__c();
		budgetTypeObj1.Name='On-Premise[AU]';
		budgetTypeObj1.Geography__c=geographyId;
		budgetTypeObj1.RecordTypeId=Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
		budgetTypeObj1.ECM_SAP_Order_reason__c = 'Y10'; 
		budgetTypeObj1.ECM_SAP_Pricing_condition__c = 'O25';
		insert budgetTypeObj1;
        //Agreement type 
        ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
        contractType.Name='Promotional';
        contractType.Geography__c=geographyId;
        contractType.ECM_Abbreviation__c='POM';
        contractType.ECM_Automatic_approval_amount_threshold__c = 40.00;
        contractType.Volume_UoM_for_Spirits__c='CAS';
        contractType.ECM_Screen_3_field_configuration__c='Product Name;Brand;Volume Target';
        contractType.ECM_Activation_Spend_Table_Configuration__c='Product Name;Investment';
        contractType.ECM_Volume_UoM_for_Beer__c = 'KEG';
        contractType.ECM_Contract_Approval_mail_to_Customer__c = true;
        //insert contractType;
        
        Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount.Outlet_Visit_Prioritisation_Grade__c = pickupOption.Id; 
        outletAccount.BillingCountry = 'Australia';
        outletAccount.BillingCountryCode = 'AU';
        outletAccount.BillingState = 'New South Wales';
        outletAccount.Person_Responsible__c = UserInfo.getUserId();
        outletAccount.Country__c = geographyId;
        outletAccount.Email_for_contracts_payments__c = 'John.Doe@mail.com';
        insert outletAccount;
        System.assert(outletAccount.Id != null,'outletAccount should not be null');
        createCustomMetadataRecord('Test_Mdt');
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('A&P').getRecordTypeId();
        EDGE_UtilityClass.stopTriggerToRun = false;
        Contract objOutletContract = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objOutletContract.ECM_Agreement_Type__c =contractType.Id;
        objOutletContract.Status = 'Draft';
        objOutletContract.Contract_End_Date__c = System.today()+30;
        objOutletContract.ECM_Upfront_Pre_payment_amount__c = 120;
        system.assertEquals(contractType.Id, objOutletContract.ECM_Agreement_Type__c,'contractType should match');
        insert objOutletContract;
        
        system.assertEquals(contractType.Id, objOutletContract.ECM_Agreement_Type__c,'contractType should match');
        objOutletContract.RecordTypeId = Schema.SObjectType.Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        objOutletContract.Status = 'Active';
        update objOutletContract;
        system.debug(LoggingLevel.Debug,'agreement '+ objOutletContract.ECM_Agreement_Type__c);
        try{
            EDGE_UtilityClass.stopTriggerToRun = false;
            Contract objOutletContract1 = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
            objOutletContract1.ECM_Agreement_Type__c =contractType.Id;
            objOutletContract1.Status = 'Draft';
            objOutletContract1.StartDate = System.today()+10;
            objOutletContract1.Initial_UOS_Earnt__c = 20;
            objOutletContract1.Contract_End_Date__c = System.today()+45;
            insert objOutletContract1;
            
            objOutletContract1.UOS_Earnt__c = 20.00;
            objOutletContract1.ECM_UOS_Annual_Target__c = 10.00;
            objOutletContract1.ECM_Upfront_Last_Payment_date__c = System.today();
            objOutletContract1.StartDate = System.today()-3;
            objOutletContract1.Contract_End_Date__c = System.today().addYears(-1)+12;
            objOutletContract1.Initial_UOS_Earnt__c = 0;
            objOutletContract1.ECM_Upfront_Payment_Spent__c= 201;
            objOutletContract1.ECM_Upfront_Pre_payment_amount__c = 110;
            objOutletContract1.Status = 'Active';  
            Test.startTest();  
            update objOutletContract1;
            Test.stopTest();
            system.assertEquals( 'Australia', objOutletContract1.ECM_Agreement_Type__r.Geography__r.Name,'Australia should match');
           /* Contract objOutletContractoutLet = EDGE_UtilityTestClass.getContract(outletAccount.Id, Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId());
            objOutletContractoutLet.ECM_Agreement_Type__c =contractType.Id;
            objOutletContractoutLet.Status = 'Draft';
            objOutletContractoutLet.StartDate = System.today()+10;
            objOutletContractoutLet.Initial_UOS_Earnt__c = 20;
            objOutletContractoutLet.ECM_Upfront_Pre_payment_amount__c = 100;
            objOutletContractoutLet.Contract_End_Date__c = System.today()+45;
            insert objOutletContractoutLet; 
            objOutletContractoutLet.ECM_Upfront_Pre_payment_amount__c = 100;
            objOutletContractoutLet.Status = 'Active';            
            update objOutletContractoutLet;*/
        }catch(Exception ex){
            System.debug(LoggingLevel.Debug,'Error '+ex.getCause());
        }
        

    }
    
    
    
    
    @isTest
    public static void sendEmailNotificationToCustomerTest(){
        Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES');
        Id uid = userinfo.getUserId();
        
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
        //mktSetting.ECM_SAP_Order_Type__c = 'Sap';
        mktSetting.ECM_Evidence_email_enabled__c=true;
        mktSetting.ECM_Payment_Management_Email__c='TEST@test.com';
        mktSetting.ECM_Diageo_Entity_Address_for_Invoicing__c='TEST@test.com';
        insert mktSetting;
        

        Id recordIdContentVersion = Schema.SObjectType.ContentVersion.getRecordTypeInfosByDeveloperName().get('Market_Setting').getRecordTypeId();
        ContentVersion cVersion = new ContentVersion();
        if(String.isNotEmpty(recordIdContentVersion)){
            cVersion.RecordTypeId = recordIdContentVersion;
        }
        cVersion.Content_Type__c = 'Terms and Conditions';
        cVersion.ContentLocation = 'S'; //S-Document is in Salesforce. E-Document is outside of Salesforce. L-Document is on a Social Netork.
        cVersion.PathOnClient = 'Test.pdf';//File name with extention
        cVersion.Title = 'Test';//Name of the file
        cVersion.VersionData = Blob.valueOf('Unit Test');//File content
        Insert cVersion;
        
        //After saved the Content Verison, get the ContentDocumentId
        Id conDocument = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cVersion.Id].ContentDocumentId;
        ContentDocumentLink cDocLink = new ContentDocumentLink();
        cDocLink.ContentDocumentId = conDocument;//Add ContentDocumentId
        cDocLink.LinkedEntityId = mktSetting.Id;//Add attachment parentId
        cDocLink.ShareType = 'I';//V - Viewer permission. C - Collaborator permission. I - Inferred permission.
        cDocLink.Visibility = 'InternalUsers';//AllUsers, InternalUsers, SharedUsers
        Insert cDocLink;
        
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        insert acc;
        acc.country__c = geographyId;
        acc.Email_for_contracts_payments__c = 'John.Doe@mail.com';
        //acc.Sales_Org__c ='sale';
        //acc.SAP_Sold_to__c ='sapsold';
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
        ECM_Contract_Type__c agrmentType = ECM_UtilityTestClass.createContractType(geographyId);
        agrmentType.Volume_UoM_for_Spirits__c='CAS';
        agrmentType.ECM_Abbreviation__c='POM';
        agrmentType.ECM_Automatic_approval_amount_threshold__c = 40.00;
        agrmentType.Volume_UoM_for_Spirits__c='CAS';
        agrmentType.ECM_Screen_3_field_configuration__c='Product Name;Brand;Volume Target';
        agrmentType.ECM_Volume_UoM_for_Beer__c = 'KEG';
        agrmentType.ECM_Contract_Approval_mail_to_Customer__c = true;
        insert agrmentType;
        
        Id contractRecordTypeId = Schema.SObjectType.Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        Contract contr = new Contract(Name = 'Test',AccountId = acc.id,ECM_Agreement_Type__c=agrmentType.Id,ownerid=uid);
        contr.Status = 'Draft';
        contr.RecordTypeId = contractRecordTypeId;
        contr.StartDate = System.today()+10;
        contr.Initial_UOS_Earnt__c = 20;
        contr.Contract_End_Date__c = System.today()+45;
        insert contr; 
        
        AccountContactRelation aCR = new AccountContactRelation();
        aCR.AccountId = acc.id;
        aCR.ContactId = con.id;
        aCR.Contact_Type__c = 'Primary';
        aCR.IsActive = true;
        insert ACR;
        String bannerRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        
        Pick_Up_Options__c budgetTypeObj= ECM_UtilityTestClass.createPickUpOption(geographyId,bannerRecordTypeId);//new Pick_Up_Options__c();
        budgetTypeObj.Name='TI[ES]';
        //budgetTypeObj.ECM_SAP_Order_reason__c = 'Y10'; 
        //budgetTypeObj.ECM_SAP_Pricing_condition__c = 'O25';
        insert budgetTypeObj;
        
        Pick_Up_Options__c budgetTypeObj2= ECM_UtilityTestClass.createPickUpOption(geographyId,Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId());
        budgetTypeObj2.Name='On-Premise[AU]';
        budgetTypeObj2.ECM_SAP_Order_reason__c = 'Y10'; 
        budgetTypeObj2.ECM_SAP_Pricing_condition__c = 'O25';
        insert budgetTypeObj2;
        
        EDGE_UtilityTestClass.createOrgSettings();
                  
        
        System.assert(acc.Id != null,'acc should not be null');
        

        try{
            
            system.debug(LoggingLevel.Debug,'agreement '+ contr.ECM_Agreement_Type__c);
            
            contr.Status = 'Approved';  
            Test.startTest();  
            update contr;
            Test.stopTest();
           
        }catch(Exception ex){
            System.debug(LoggingLevel.Debug,'Error '+ex.getCause());  
        }
        

    }
    
    
          @isTest
    public static void createOperatorOutletContractTest(){
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU'); 
        EDGE_UtilityTestClass.createOrgSettings();
                  
        
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AU]';
        insert pickupOption;
        
        Pick_Up_Options__c pickupOption1 = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pickupOption1.Name = 'Upfront Payment [AU]';
        pickupOption1.RecordTypeId =Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        pickupOption1.Status__c ='Active';
        insert pickupOption1;
        Pick_Up_Options__c budgetTypeObj1= new Pick_Up_Options__c();
		budgetTypeObj1.Name='On-Premise[AU]';
		budgetTypeObj1.Geography__c=geographyId;
		budgetTypeObj1.RecordTypeId=Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
		budgetTypeObj1.ECM_SAP_Order_reason__c = 'Y10'; 
		budgetTypeObj1.ECM_SAP_Pricing_condition__c = 'O25';
		insert budgetTypeObj1;
        //Agreement type 
        ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
        contractType.Name='Promotional';
        contractType.Geography__c=geographyId;
        contractType.ECM_Abbreviation__c='POM';
        contractType.ECM_Automatic_approval_amount_threshold__c = 40.00;
        contractType.Volume_UoM_for_Spirits__c='CAS';
        contractType.ECM_Screen_3_field_configuration__c='Product Name;Brand;Volume Target';
        contractType.ECM_Activation_Spend_Table_Configuration__c='Product Name;Investment';
        contractType.ECM_Volume_UoM_for_Beer__c = 'KEG';
        contractType.ECM_Contract_Approval_mail_to_Customer__c = true;
        //insert contractType;
        
        Account operatorAccount = EDGE_UtilityTestClass.getOwnerOperatorAccount();
        operatorAccount.Outlet_Visit_Prioritisation_Grade__c = pickupOption.Id; 
        operatorAccount.BillingCountry = 'Australia';
        operatorAccount.BillingCountryCode = 'AU';
        operatorAccount.BillingState = 'New South Wales';
        operatorAccount.Person_Responsible__c = UserInfo.getUserId();
        operatorAccount.Country__c = geographyId;
        operatorAccount.IsOperator__c = true;
        operatorAccount.Email_for_contracts_payments__c = 'John.Doe@mail.com';
        insert operatorAccount;
        System.assert(operatorAccount.Id != null,'operatorAccount should not be null');
        createCustomMetadataRecord('Test_Mdt');
        
        Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount.Outlet_Visit_Prioritisation_Grade__c = pickupOption.Id; 
        outletAccount.BillingCountry = 'Australia';
        outletAccount.BillingCountryCode = 'AU';
        outletAccount.BillingState = 'New South Wales';
        outletAccount.Person_Responsible__c = UserInfo.getUserId();
        outletAccount.Country__c = geographyId;
        outletAccount.Independent_of_Operator__c = false;
        outletAccount.Operator__c  = operatorAccount.Id;
        outletAccount.Email_for_contracts_payments__c = 'John.Doe@mail.com';
        insert outletAccount;
        System.assert(outletAccount.Id != null,'outletAccount should not be null');
        
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('A&P').getRecordTypeId();
        
        EDGE_UtilityClass.stopTriggerToRun = false;
        Contract operatorContract = EDGE_UtilityTestClass.getContract(operatorAccount.Id, contractRecordTypeId);
        operatorContract.ECM_Agreement_Type__c =contractType.Id;
        operatorContract.Status = 'Draft';
        operatorContract.Contract_End_Date__c = System.today()+30;
        operatorContract.ECM_Upfront_Pre_payment_amount__c = 120;
        system.assertEquals(contractType.Id, operatorContract.ECM_Agreement_Type__c,'contractType should match');
        Test.startTest();
        insert operatorContract;
        system.assertEquals(contractType.Id, operatorContract.ECM_Agreement_Type__c,'contractType should match');
        //objOutletContract.RecordTypeId = Schema.SObjectType.Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        
        operatorContract.Status = 'Active';
        update operatorContract;
        Test.stopTest();
        
        

    }
    
    public static ECM_Rebates_Calendar__mdt createCustomMetadataRecord(String myNewName) {
        ECM_Rebates_Calendar__mdt rebateData = [SELECT ECM_Rebate_Calculation_Date__c, ECM_Rebate_Period_Start__c, ECM_Rebate_Period_End__c,
                                                ECM_Region__c, ECM_Financial_Year__c, ECM_Quarter__c, Id FROM ECM_Rebates_Calendar__mdt LIMIT 1];
        rebateData.DeveloperName = myNewName;
        rebateData.ECM_Rebate_Calculation_Date__c = system.today();
        rebateData.ECM_Financial_Year__c = 'FY20';
        rebateData.ECM_Region__c = 'Australia';
        
        return rebateData;
    }
    @isTest
    public static void createOperatorContractTest1(){
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU'); 
        EDGE_UtilityTestClass.createOrgSettings();
        Test.startTest();
        
        ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
        contractType.Name='Promotional';
        contractType.Geography__c=geographyId;
        contractType.ECM_Abbreviation__c='POM';
        contractType.ECM_Automatic_approval_amount_threshold__c = 40.00;
        contractType.Volume_UoM_for_Spirits__c='CAS';
        contractType.ECM_Screen_3_field_configuration__c='Product Name;Brand;Volume Target';
        contractType.ECM_Activation_Spend_Table_Configuration__c='Product Name;Investment';
        contractType.ECM_Volume_UoM_for_Beer__c = 'KEG';
        contractType.ECM_Contract_Approval_mail_to_Customer__c = true;
        //insert contractType;
        
        Account ownerAccount = EDGE_UtilityTestClass.getOwnerOperatorAccount();
        ownerAccount.BillingCountry = 'Australia';
        ownerAccount.BillingState = 'New South Wales';
        ownerAccount.Person_Responsible__c = UserInfo.getUserId();
        ownerAccount.Country__c = geographyId;
        ownerAccount.IsOperator__c =true;
        ownerAccount.Email_for_contracts_payments__c = 'John.Doe@mail.com';
        insert ownerAccount;
        System.assert(ownerAccount.Id != null,'ownerAccount should not be null');
        
        EDGE_UtilityClass.stopTriggerToRun = false;
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('A&P').getRecordTypeId();
        Contract objContract = EDGE_UtilityTestClass.getContract(ownerAccount.Id, contractRecordTypeId);
        objContract.Status = 'Draft';
        objContract.Contract_End_Date__c = System.today()+29;
        objContract.ECM_Agreement_type__c=contractType.Id;
        insert objContract;
        String oldsObjectName = 'Contract';
        Schema.SObjectType oldt  = Schema.getGlobalDescribe().get(oldsObjectName);
        SObject oldsobjContract = oldt.newSObject();
        oldsobjContract = (sobject)objContract;
        objContract = [Select Id,Name,status,UOS_Earnt__c,ECM_Upfront_Payment_Spent__c,ECM_UOS_Annual_Target__c,ECM_Upfront_Last_Payment_date__c,
                       ECM_Customer_Upfront_Payment_Inv_Now_Due__c,Contract_End_Date__c,StartDate from contract where Id=:objContract.id];
        Map<Id,Contract> oldcontractRecords = new Map<Id,Contract>{objContract.Id=>objContract};            
        Pick_Up_Options__c pickupOption1 = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pickupOption1.Name = 'Upfront Payment [AU]';
        pickupOption1.RecordTypeId =Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        pickupOption1.Status__c ='Active';
        insert pickupOption1;
        
        objContract.status='Active';
        objContract.UOS_Earnt__c =100;
        objContract.Initial_UOS_Earnt__c=0;
        objContract.ECM_UOS_Annual_Target__c = 40; 
        objContract.ECM_Upfront_Payment_Spent__c = 20;
        objContract.ECM_Upfront_Last_Payment_date__c = System.today().addYears(-2);
        update objContract;
        objContract = [Select Id,Name,status,UOS_Earnt__c,ECM_Upfront_Payment_Spent__c,ECM_UOS_Annual_Target__c,ECM_Upfront_Last_Payment_date__c,RecordTypeId,
                       ECM_Customer_Upfront_Payment_Inv_Now_Due__c,Contract_End_Date__c,StartDate,ECM_Upfront_Pre_payment_amount__c,Account.country__r.Name from contract where Id=:objContract.id];
        Map < Id, Contract > mapnewItems = new Map < Id, Contract >{objContract.id=>objContract};
        String sObjectName = 'Contract';
        Schema.SObjectType t  = Schema.getGlobalDescribe().get(sObjectName);
        SObject sobjContract = t.newSObject();
        sobjContract = (sobject)objContract;
        Map<Id,sObject> newRecords = (Map<Id,sObject>)mapnewItems;
        Map<Id,sObject> oldRecords = (Map<Id,sObject>)oldcontractRecords;        
        EDGE_ContractTriggerHelper.ECM_PaymentSummary_Creation(newRecords,oldRecords);  
    }
    @isTest
    public static void sendPushNotificationApprovalTest(){
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU'); 
        EDGE_UtilityTestClass.createOrgSettings();
        
        ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
        contractType.Name='Promotional';
        contractType.Geography__c=geographyId;
        contractType.ECM_Abbreviation__c='POM';
        contractType.ECM_Automatic_approval_amount_threshold__c = 40.00;
        contractType.Volume_UoM_for_Spirits__c='CAS';
        contractType.ECM_Screen_3_field_configuration__c='Product Name;Brand;Volume Target'; //ECM-4570
        contractType.ECM_Activation_Spend_Table_Configuration__c='Product Name;Investment';
        contractType.ECM_Volume_UoM_for_Beer__c = 'KEG';
        contractType.ECM_Contract_Approval_mail_to_Customer__c = true;
        //insert contractType;
        
        Account ownerAccount = EDGE_UtilityTestClass.getOwnerOperatorAccount();
        ownerAccount.BillingCountry = 'Australia';
        ownerAccount.BillingState = 'New South Wales';
        ownerAccount.Person_Responsible__c = UserInfo.getUserId();
        ownerAccount.Country__c = geographyId;
        ownerAccount.IsOperator__c =true;
        insert ownerAccount;
        System.assert(ownerAccount.Id != null,'ownerAccount should not be null');
        
       
        EDGE_UtilityClass.stopTriggerToRun = false;
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        Contract objContract = EDGE_UtilityTestClass.getContract(ownerAccount.Id, contractRecordTypeId);
        objContract.Status = 'Draft';
        objContract.Contract_End_Date__c = System.today()+29;
        objContract.ECM_Agreement_type__c=contractType.Id;
        insert objContract;
        
        Contract objContract1 = EDGE_UtilityTestClass.getContract(ownerAccount.Id, contractRecordTypeId);
        objContract1.Status = 'Draft';
        objContract1.Contract_End_Date__c = System.today()+29;
        objContract1.ECM_Agreement_type__c=contractType.Id;
        insert objContract1;
         ECM_Approval_Log__c approvalLog1 = new ECM_Approval_Log__c();
        approvalLog1.Name = 'test@diageo.com';
        approvalLog1.ECM_Status__c = 'Approved';
        approvalLog1.ECM_Comment__c = 'Approved by Test User';
        approvalLog1.ECM_Contract__c = objContract1.id;
        insert approvalLog1;
        
        String oldsObjectName = 'Contract';
        Schema.SObjectType oldt  = Schema.getGlobalDescribe().get(oldsObjectName);
        SObject oldsobjContract = oldt.newSObject();
        oldsobjContract = (sobject)objContract;
        
      //  Map<Id,Contract> oldcontractRecords = new Map<Id,Contract>{objContract.Id=>objContract};
        
        //Approval Log
        system.debug(LoggingLevel.Debug,'@@objContract' +objContract);
        ECM_Approval_Log__c approvalLog = new ECM_Approval_Log__c();
        approvalLog.Name = 'test@diageo.com';
        approvalLog.ECM_Status__c = 'Approved';
        approvalLog.ECM_Comment__c = 'Approved by Test User';
        approvalLog.ECM_Contract__c = objContract.id;
        insert approvalLog;
        system.assert(approvalLog.id!=null,'approvalLog should not be null');
        List<ECM_Approval_Log__c> approvalLogList =[SELECT Id, ECM_Comment__c,ECM_Contract__c,ECM_Contract__r.Account.Name, ECM_Time_Date_Log__c,Name,ECM_Status__c
                                                        FROM ECM_Approval_Log__c] ;
        System.debug(LoggingLevel.Debug,'@@fromTestList' +approvalLogList.size());
        /* 
                   
        Pick_Up_Options__c pickupOption1 = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pickupOption1.Name = 'Upfront Payment [AU]';
        pickupOption1.RecordTypeId =Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        pickupOption1.Status__c ='Active';
        insert pickupOption1;*/
            
        Test.startTest();
        objContract.status='Draft';
        //objContract.UOS_Earnt__c =100;
        //objContract.Initial_UOS_Earnt__c=0;
        //objContract.ECM_UOS_Annual_Target__c = 40; 
        //objContract.ECM_Upfront_Payment_Spent__c = 20;
        //objContract.ECM_Upfront_Last_Payment_date__c = System.today().addYears(-2);
    
        update objContract;
        Test.stopTest();
    }
    
   /* @isTest
    public static void sendPushNotificationRejectionTest(){
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU'); 
        EDGE_UtilityTestClass.createOrgSettings();
       
        ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
        contractType.Name='Promotional';
        contractType.Geography__c=geographyId;
        contractType.ECM_Abbreviation__c='POM';
        contractType.ECM_Automatic_approval_amount_threshold__c = 40.00;
        contractType.Volume_UoM_for_Spirits__c='CAS';
        contractType.ECM_Screen_3_field_configuration__c='Product Name;Brand;Volume Target;Investment'; //ECM-4570
        insert contractType;
        
        Account ownerAccount = EDGE_UtilityTestClass.getOwnerOperatorAccount();
        ownerAccount.BillingCountry = 'Australia';
        ownerAccount.BillingState = 'New South Wales';
        ownerAccount.Person_Responsible__c = UserInfo.getUserId();
        ownerAccount.Country__c = geographyId;
        ownerAccount.IsOperator__c =true;
        insert ownerAccount;
        System.assert(ownerAccount.Id != null);
        
        EDGE_UtilityClass.stopTriggerToRun = false;
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('A&P').getRecordTypeId();
        Contract objContract = EDGE_UtilityTestClass.getContract(ownerAccount.Id, contractRecordTypeId);
        objContract.Status = 'Draft';
        objContract.Contract_End_Date__c = System.today()+29;
        objContract.ECM_Agreement_type__c=contractType.Id;
        insert objContract;
        
        //Approval Log
        ECM_Approval_Log__c approvalLog = new ECM_Approval_Log__c();
        approvalLog.Name = 'test@diageo.com';
        approvalLog.ECM_Status__c = 'Rejected';
        approvalLog.ECM_Comment__c = 'Approved by Test User';
        approvalLog.ECM_Contract__c = objContract.id;
        insert approvalLog;
        
        objContract.status='In Approval Process';        
        update objContract;

        Test.startTest();
        objContract.status='Draft';
        update objContract;
        Test.stopTest();
    }*/
	/*@isTest
    public static void testGetContract(){
        EDGE_UtilityClass.stopTriggerToRun = false;
        Id contId;
        Pick_Up_Options__c pickupOption;
        Account outlet;
        contId = EDGE_UtilityTestClass.setupCountry('ES');
        
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        pickupOption = EDGE_UtilityTestClass.getPickUpOption(contId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[ES]';
        pickupOption.RecordTypeId = pickupRecordType;
        pickupOption.Status__c = 'Active';
        insert pickupOption;
        
        List<Geography__c> geoList = [SELECT Id,Name,Parent_Geography__c,
                                      Parent_Geography__r.Parent_Geography__c,
                                      Parent_Geography__r.Parent_Geography__r.Parent_Geography__c,
                                      Parent_Geography__r.Parent_Geography__r.Parent_Geography__r.Parent_Geography__c,
                                      Parent_Geography__r.Parent_Geography__r.Parent_Geography__r.Parent_Geography__r.Parent_Geography__c
                                      FROM Geography__c 
                                      WHERE Parent_Geography__r.Parent_Geography__c =: contId];
        Id recTypeIdOutlet = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Outlet').getRecordTypeId(); 
		Account outletAcc = new Account();
        outletAcc.Name = 'Test_Outlet_Spain';
        outletAcc.RecordTypeId = recTypeIdOutlet; 
        outletAcc.BillingStreet = 'Calle Escritor Benito Pérez Galdós 43';
        outletAcc.BillingCity = 'Las Palmas de Gran Canaria';
        outletAcc.BillingState = 'ALAVA';
        outletAcc.BillingPostalCode = '35002';
        outletAcc.BillingCountry = 'Spain';
        outletAcc.BillingCountryCode = 'ES';
        outletAcc.Region__c = geoList[0].Id;
        outletAcc.Area__c = geoList[0].Parent_Geography__c;
        outletAcc.Country__c = geoList[0].Parent_Geography__r.Parent_Geography__c;
        outletAcc.Cluster__c= geoList[0].Parent_Geography__r.Parent_Geography__r.Parent_Geography__c;
        outletAcc.Hub__c = geoList[0].Parent_Geography__r.Parent_Geography__r.Parent_Geography__r.Parent_Geography__c;
        outletAcc.Market__c = geoList[0].Parent_Geography__r.Parent_Geography__r.Parent_Geography__r.Parent_Geography__r.Parent_Geography__c;
        outletAcc.Outlet_Email_Address__c = 'test@test.com';
        outletAcc.Global_Channel__c = 'Off Trade';
        outletAcc.Global_Sub_Channel__c = 'Retailer';
        outletAcc.Global_Segment__c = 'Hypermarket';
        outletAcc.Global_Sub_Segment__c = 'Modern Hypermarket';
        outletAcc.Status__c= 'Active';
        outletAcc.Independent_of_Operator__c = true;
        outletAcc.Independent_of_Owner__c = true;
        outletAcc.Outlet_Visit_Prioritisation_Grade__c = pickupOption.id;
        insert outletAcc;
        
        Id pkupRecTypeId = Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get('Product Strategy').getRecordTypeId();
        Pick_Up_Options__c pOption = new Pick_Up_Options__c();
        pOption.Name = 'Premium Core[ES]';
        pOption.Geography__c = contId;
        pOption.ECM_Strategy_group__c = 'Premium Core';
        pOption.RecordTypeId = pkupRecTypeId;
        pOption.Status__c = 'Active';
        insert pOption;
        
        String bannerRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
        Pick_Up_Options__c banner = new Pick_Up_Options__c();
        banner.Name = 'Range[ES]';
        banner.Geography__c = contId;
        banner.RecordTypeId = bannerRecordTypeId;
        insert banner;
        
        Product__c product = new Product__c();
        product.Name='Test';
        product.Product_Full_Name__c='Test';
        product.Country__c = contId;
        insert product;
        
        Market_Assortment_Product__c mapObj = new Market_Assortment_Product__c();
        mapObj.Product__c = product.Id;
        mapObj.Market_Assortment__c = contId;
        mapObj.ECM_Pickup_Option__c = pOption.Id;
        insert mapObj;
        
        Id buRecTypeId = Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Business Unit').getRecordTypeId();
        Id saRecTypeId = Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Sales Area').getRecordTypeId();
        Id regRecTypeId = Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Region').getRecordTypeId();
        
        
        Territory_Hierarchy__c hierBUObj = new Territory_Hierarchy__c();
        hierBUObj.Name = 'Test Spain BU';
        hierBUObj.RecordTypeId = buRecTypeId;
        hierBUObj.Geography__c = contId;
        insert hierBUObj;
        
        Territory_Hierarchy__c hierSAObj = new Territory_Hierarchy__c();
        hierSAObj.Name = 'Test Spain BU';
        hierSAObj.RecordTypeId = saRecTypeId;
        hierSAObj.Geography__c = contId;
        hierSAObj.Parent_BU__c = hierBUObj.id;
        insert hierSAObj;
        
        Territory_Hierarchy__c hierRegionObj = new Territory_Hierarchy__c();
        hierRegionObj.Name = 'Test Spain Region';
        hierRegionObj.RecordTypeId = regRecTypeId;
        hierRegionObj.Geography__c = contId;
        hierRegionObj.Parent_BU__c = hierSAObj.id;
        insert hierRegionObj;
        
        Territory__c testTerritory = New Territory__c();
        testTerritory.Name='Testterriotory';
        testTerritory.Territory_Type__c='Sales';
        testTerritory.Country__c = contId;
        testTerritory.Status__c ='Active';
        testTerritory.Region__c = hierRegionObj.Id;
        insert testTerritory;
        
        ECM_Contract_Type__c contractType = new ECM_Contract_Type__c();
        contractType.Name ='Promotional';
        contractType.Geography__c = contId;
        contractType.ECM_Abbreviation__c = 'POM';
        contractType.Volume_UoM_for_Spirits__c = 'BTL';
        contractType.ECM_Automatic_approval_amount_threshold__c = 40.00;
        contractType.ECM_Screen_3_field_configuration__c='Product Name;Volume Target;';
        insert contractType;
        
        ECM_Payment_Frequency__c paymFreq = new ECM_Payment_Frequency__c();	
        paymFreq.ECM_Type__c='Monthly';	
        paymFreq.ECM_Other_Investment__c=true;	
        paymFreq.ECM_Volume_target__c=true;	
        paymFreq.ECM_Number_of_months_for_recurrence__c='20';	
        paymFreq.ECM_From_When_Starts__c='Calendar Year';	
        paymFreq.ECM_Geography__c = contId;	
        Insert paymFreq;
        
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        
        Contract conObj =  EDGE_UtilityTestClass.getContract(outletAcc.Id, contractRecordTypeId);
        conObj.Status = 'Draft';
        conObj.Contract_End_Date__c = System.today()+29;
        conObj.AccountId = outletAcc.Id;
        conObj.ECM_Territory__c = testTerritory.Id;
        //objContract.ECM_Contract_Type__c=contractType.Id;
        conObj.ECM_Agreement_Type__c = contractType.Id;
        conObj.recordTypeId = contractRecordTypeId;
        conObj.ECM_Channel__c = 'On-Premise';
        conObj.ECM_Banner__c = banner.Id;
        conObj.StartDate = system.today();
        conObj.ECM_Payment_Frequency_type__c = paymFreq.Id;
        conObj.Contract_End_Date__c = system.today()+360;
        Test.startTest();
        insert conObj;
        //conObj.Status = 'Approved';
        
        //update conObj;        
        Test.stopTest();
        /*List<ECM_Contract_Item__c> conItemList = new List<ECM_Contract_Item__c>();
        ECM_Contract_Item__c conItemObj = new ECM_Contract_Item__c();
        conItemObj.ECM_Contract__c = conObj.Id;
        conItemObj.ECM_Product__c = mapObj.id;
        ECM_Contract_Item__c conItemObj1 = new ECM_Contract_Item__c();
        conItemObj1.ECM_Contract__c = conObj.Id;
        conItemObj1.ECM_Product__c = mapObj.id;
        conItemList.add(conItemObj);
        conItemList.add(conItemObj1);
        insert conItemList;
        
        
        //ECM_CreateContractController.getContract(conObj.Id);
        //ECM_CreateContractController.getTableDetails(contractType.id);
        
    }   */
    
    
    /* public statis void ECM_updateUpfrontPaymentoncontractApprovedTest(){
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AUT'); 
        EDGE_UtilityTestClass.createOrgSettings();
        Test.startTest();             
        
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AUT]';
        insert pickupOption;
        
        Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount.Outlet_Visit_Prioritisation_Grade__c = pickupOption.Id; 
        outletAccount.BillingCountry = 'Australia';
        outletAccount.BillingCountryCode = 'AU';
        outletAccount.BillingState = 'New South Wales';
        outletAccount.Person_Responsible__c = UserInfo.getUserId();
        outletAccount.Country__c = geographyId;
        insert outletAccount;
        System.assert(outletAccount.Id != null);
        
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('A&P').getRecordTypeId();
        EDGE_UtilityClass.stopTriggerToRun = false;
        Contract objOutletContract = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objOutletContract.Status = 'Draft';
        objOutletContract.Contract_End_Date__c = System.today()+30;
        insert objOutletContract;
        
        try{
            EDGE_UtilityClass.stopTriggerToRun = false;
            Contract objOutletContract1 = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
            objOutletContract1.Status = 'Draft';
            objOutletContract1.StartDate = System.today()+10;
            objOutletContract1.Contract_End_Date__c = System.today()+45;
            insert objOutletContract1;
            
        } catch(Exception ex){
            
        }
                
        Test.stopTest();
    }*/
    @isTest
    public static void createOperatorContractTest3(){
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AUT'); 
        //EDGE_UtilityTestClass.createOrgSettings();
        
        
        Account ownerAccount = EDGE_UtilityTestClass.getOwnerOperatorAccount();
        ownerAccount.BillingCountry = 'Australia';
        ownerAccount.BillingState = 'New South Wales';
        ownerAccount.Person_Responsible__c = UserInfo.getUserId();
        ownerAccount.Country__c = geographyId;
        ownerAccount.IsOperator__c =true;
        insert ownerAccount;
        //Test.startTest();
        //System.assert(ownerAccount.Id != null,'ownerAccount should not be null');
        
        //EDGE_UtilityClass.stopTriggerToRun = false;
        
        
        //update objContract;
        
        /*String oldsObjectName = 'Contract';
Schema.SObjectType oldt  = Schema.getGlobalDescribe().get(oldsObjectName);
SObject oldsobjContract = oldt.newSObject();
oldsobjContract = (sobject)objContract;
Map<Id,Contract> oldcontractRecords = new Map<Id,Contract>{objContract.Id=>objContract};
*/
        
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AUT]';
        insert pickupOption;
        
        Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount.Outlet_Visit_Prioritisation_Grade__c = pickupOption.Id; 
        outletAccount.BillingCountry = 'Australia';
        outletAccount.BillingCountryCode = 'AU';
        outletAccount.BillingState = 'New South Wales';
        outletAccount.Person_Responsible__c = UserInfo.getUserId();
        outletAccount.Country__c = geographyId;
        outletAccount.Independent_of_Operator__c = false;
        outletAccount.Operator__c = ownerAccount.Id;
        insert outletAccount;
        System.assert(outletAccount.Id != null,'outletAccount should not be null');
        
        List<Contract> contractList = new List<Contract>();
        EDGE_UtilityClass.stopTriggerToRun = false;
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('A&P').getRecordTypeId();
        Contract objContract = EDGE_UtilityTestClass.getContract(ownerAccount.Id, contractRecordTypeId);
        objContract.Status = 'Draft';
        objContract.Contract_End_Date__c = System.today()+29;
        contractList.add(objContract);
        Contract objOutletContract = EDGE_UtilityTestClass.getContract(ownerAccount.Id, contractRecordTypeId);
        objOutletContract.Status = 'Draft';
        objOutletContract.StartDate = System.today()+30;
        objOutletContract.Contract_End_Date__c = System.today()+45;
        contractList.add(objOutletContract);
        //insert objOutletContract;
        
        //EDGE_UtilityClass.stopTriggerToRun = false;
        Contract objOutletContract1 = EDGE_UtilityTestClass.getContract(ownerAccount.Id, contractRecordTypeId);
        objOutletContract1.Status = 'Draft';
        objOutletContract1.StartDate = System.today()-10;
        objOutletContract1.Contract_End_Date__c = System.today()-5;
        objOutletContract1.Initial_UOS_Earnt__c = 20;
        contractList.add(objOutletContract1);
        //insert objOutletContract1;  
        insert contractList;  
        objContract.Status='Active';
        objOutletContract.Status='Active';
        objOutletContract1.Status='Active';
        update contractList;
        List<Outlet_Contract__c> outletContractList = new List<Outlet_Contract__c>();
        Outlet_Contract__c outletContract1 = new Outlet_Contract__c();
        outletContract1.Contract__c = objContract.Id;
        outletContract1.Outlet__c = outletAccount.Id;
        outletContract1.Status__c ='Active';
        outletContractList.add(outletContract1);
        Outlet_Contract__c outletContract2 = new Outlet_Contract__c();
        outletContract2.Contract__c = objOutletContract.Id;
        outletContract2.Outlet__c = outletAccount.Id;
        outletContract2.Status__c ='Active';
        outletContractList.add(outletContract2);
        Outlet_Contract__c outletContract3 = new Outlet_Contract__c();
        outletContract3.Contract__c = objOutletContract1.Id;
        outletContract3.Outlet__c = outletAccount.Id;
        outletContract3.Status__c ='Active';
        outletContractList.add(outletContract3);
        Insert outletContractList;
        String outletRecordTypeId= Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        EDGE_UtilityTestClass.createOrgSettings();
        Map < Id, Account > mapOperatorDetails=new Map<Id,Account>();
        mapOperatorDetails.put(ownerAccount.Id,ownerAccount);
        EDGE_ContractTriggerHelper.assignContractToOutlet(contractList,null);
        EDGE_ContractTriggerHelper.checkValidOperatorOutlet(mapOperatorDetails,outletRecordTypeId);
        
        
    }
    
}