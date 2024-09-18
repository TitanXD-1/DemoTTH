/*
*@Name: ECM_ContractApprovalEmailService_Test
*@Purpose: This class is used to cover testclass for the - ECM_ContractApprovalEmailService
*@History                                                            

VERSION      AUTHOR                  DATE                DETAIL
1.0      Saurav Kumar Prasad      26/05/2020        Initial Development
2.0			Saurav Prasad		  23/08/2021		ECM-4740 Approval Logs: Change field type to multi select pick list

*/
@istest
public class ECM_ContractApprovalEmailService_Test {
    
    @isTest 
    public static void test1(){
        Test.startTest();
        
        Profile prof = [select id from profile where name=: 'Sales Representative'];
        User usr = new User();
        usr.firstName = 'test1';
        usr.lastName = 'test2';
        usr.profileId = prof.id;        
        usr.email = 'test@test.com';
        usr.Username ='testcm123'+'_'+userinfo.getOrganizationId()+'@test.com';
        usr.Alias='test';
        usr.Timezonesidkey='America/Los_Angeles';
        usr.LocaleSidKey='en_US';
        usr.LanguageLocaleKey='en_US';
        usr.EmailEncodingKey='UTF-8';
        usr.Available_Countries__c='ES';
        usr.Title='Legal';
        insert usr;
        System.runAs(usr){
            Id geographyId = EDGE_UtilityTestClass.setupCountry('ES'); 
            // Id geographyId1 = EDGE_UtilityTestClass.setupCountry('AU'); 
            Territory__c testterritory=New Territory__c();
            testterritory.Name='Testterriotory';
            testterritory.Territory_Type__c='Sales';
            testterritory.Country__c= geographyId;
            testterritory.Status__c='Active';
            testterritory.Primary_Sales_Rep__c = usr.id;
            insert testterritory;
            
            ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
            contractType.Name='Promotional';
            contractType.Geography__c=geographyId;
            contractType.ECM_Abbreviation__c='POM';
            contractType.ECM_Automatic_approval_amount_threshold__c=40.00;
            contractType.Volume_UoM_for_Spirits__c='BTL';
            contractType.ECM_Screen_3_field_configuration__c='Product Name;Brand;Volume Target;Investment';
            contractType.ECM_Volume_UoM_for_Beer__c='EU';
            insert contractType;
            
            String bannerRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
            
            Pick_Up_Options__c banner= new Pick_Up_Options__c();
            banner.Name='Range[ES]';
            banner.Geography__c=geographyId;
            banner.RecordTypeId=bannerRecordTypeId;
            insert banner;
            
            Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
            outletAccount.Person_Responsible__c= usr.Id;
            outletAccount.OwnerId = usr.Id;
            //outletAccount.Operator__c=contractType.id;
            insert outletAccount;
            
            String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
            Contract objContract = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
            objContract.Status = 'Draft';
            objContract.Contract_End_Date__c = System.today()+29;
            objContract.AccountId=outletAccount.Id;
            objContract.ECM_Territory__c=testterritory.Id;
            objContract.ECM_Overall_Investment_Amount__c=100020.55;
            objContract.ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c=12000934.32;
            objContract.ECM_Hybrid_CustInvest_Total_PercentGP__c=243123.33;
            objContract.ECM_Overall_Investment_Figure__c=122.43;
            //objContract.ECM_Contract_Type__c=contractType.Id;
            objContract.ECM_Agreement_Type__c=contractType.Id;
            objContract.recordTypeId=contractRecordTypeId;
            objContract.ECM_Channel__c='On-Premise';
            objContract.ECM_Banner__c=banner.Id;
            objContract.StartDate = system.today();
            objContract.Contract_End_Date__c = system.today()+360;
            insert objContract;
            objContract.Status ='In Approval Process';
            update objContract;
            String eCMApprovalLogRecordTypeId = ECM_Approval_Log__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Primary approver').getRecordTypeId();
            ECM_Approval_Log__c ecmCurrentApprovalLog = new ECM_Approval_Log__c();
            ecmCurrentApprovalLog.ECM_Approver_s_Position__c='Legal';
            ecmCurrentApprovalLog.Name='test@test.com';
            ecmCurrentApprovalLog.ECM_Status__c='Requested';
            ecmCurrentApprovalLog.ECM_Comment__c='Test User';
            ecmCurrentApprovalLog.ECM_No_of_Approval_Cycles__c = 1;
            ecmCurrentApprovalLog.ECM_Type__c = 'Contract';
            //ecmCurrentApprovalLog.ECM_Time_Date_Log__c=;
            ecmCurrentApprovalLog.ECM_Contract__c=objContract.Id;
            ecmCurrentApprovalLog.RecordTypeId=eCMApprovalLogRecordTypeId;
            Insert ecmCurrentApprovalLog;
            
            
            Messaging.InboundEmail email = new Messaging.InboundEmail();
            Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
            
            Contract con=new contract();
            con=[select ContractNumber,Status,Owner.Name from Contract where Id=:objContract.Id];
            
            email.subject='Sandbox:'+con.ContractNumber+'_Please approve commercial contract';
            email.fromAddress='test@test.com';
            email.plainTextBody='Dear Approver,\n\n'+
                +'Please review the contract details and make a decision following the below INSTRUCTIONS:\n'+
                +'If you APPROVE the offer, please reply to this email and type “approve” in the 1st line,\n'+
                +'If you REJECT the offer, please reply to this email and type “reject” in the 1st line,\n'+
                +'If you want to add a comment to your reply, please type it in the 2nd line.\n\n'+
                +'Please do NOT CHANGE or REMOVE the subject of this email.\n\n'+
                +'Thank you!';
            
            Messaging.InboundEmail email1 = new Messaging.InboundEmail();
            email1.subject='Sandbox:'+objContract.Id+'_Please approve commercial contract';
            email1.fromAddress='test@test.com';
            email1.plainTextBody='Dear Approver,\n\n'+
                +'Please review the contract details and make a decision following the below INSTRUCTIONS:\n'+
                +'If you APPROVE the offer, please reply to this email and type “approve” in the 1st line,\n'+
                +'If you REJECT the offer, please reply to this email and type “reject” in the 1st line,\n'+
                +'If you want to add a comment to your reply, please type it in the 2nd line.\n\n'+
                +'Please do NOT CHANGE or REMOVE the subject of this email.\n\n'+
                +'Thank you!';
            Messaging.InboundEmail email2 = new Messaging.InboundEmail();
            email2.subject='Re:'+con.ContractNumber+'_Please approve commercial contract';
            email2.fromAddress='test@test.com';
            email2.plainTextBody='Approved';
            
            ECM_ContractApprovalEmailService catcher= new ECM_ContractApprovalEmailService();
            Messaging.InboundEmailResult result = catcher.handleInboundEmail(email, envelope);
            Messaging.InboundEmailResult result1 = catcher.handleInboundEmail(email1, envelope);
            Messaging.InboundEmailResult result2 = catcher.handleInboundEmail(email2, envelope);
            System.assertEquals( result.success  ,true,'Both parameter should match');  
            System.assertEquals( result1.success  ,true,'Both parameter should match');  
            System.assertEquals( result2.success  ,true,'Both parameter should match');
            
        }
        
        Test.stopTest();
    }
    @isTest 
    public static void test2(){
        Test.startTest();
        
        Profile prof = [select id from profile where name=: 'Sales Representative'];
        User usr = new User();
        usr.firstName = 'test1';
        usr.lastName = 'test2';
        usr.profileId = prof.id;        
        usr.email = 'test@test.com';
        usr.Username ='testcm12'+'_'+userinfo.getOrganizationId()+'@test.com';
        usr.Alias='test';
        usr.Timezonesidkey='America/Los_Angeles';
        usr.LocaleSidKey='en_US';
        usr.LanguageLocaleKey='en_US';
        usr.EmailEncodingKey='UTF-8';
        usr.Available_Countries__c='ES';
        usr.Title='Legal';
        insert usr;
        System.runAs(usr){
            Id geographyId = EDGE_UtilityTestClass.setupCountry('ES'); 
            // Id geographyId1 = EDGE_UtilityTestClass.setupCountry('AU'); 
            Territory__c testterritory=New Territory__c();
            testterritory.Name='Testterriotory';
            testterritory.Territory_Type__c='Sales';
            testterritory.Country__c= geographyId;
            testterritory.Status__c='Active';
            testterritory.Primary_Sales_Rep__c = usr.id;
            insert testterritory;
            
            ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
            contractType.Name='Promotional';
            contractType.Geography__c=geographyId;
            contractType.ECM_Abbreviation__c='POM';
            contractType.ECM_Automatic_approval_amount_threshold__c=40.00;
            contractType.Volume_UoM_for_Spirits__c='BTL';
            contractType.ECM_Volume_UoM_for_Beer__c='EU';
            contractType.ECM_Screen_3_field_configuration__c='Product Name;Brand;Volume Target;Investment';
            insert contractType;
            
            String bannerRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
            
            Pick_Up_Options__c banner= new Pick_Up_Options__c();
            banner.Name='Range[ES]';
            banner.Geography__c=geographyId;
            banner.RecordTypeId=bannerRecordTypeId;
            insert banner;
            
            Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
            outletAccount.Person_Responsible__c= usr.Id;
            outletAccount.OwnerId = usr.Id;
            //outletAccount.Operator__c=contractType.id;
            insert outletAccount;
            
            String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
            Contract objContract = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
            objContract.Status = 'Draft';
            objContract.Contract_End_Date__c = System.today()+29;
            objContract.AccountId=outletAccount.Id;
            objContract.ECM_Territory__c=testterritory.Id;
            objContract.ECM_Overall_Investment_Amount__c=100020.55;
            objContract.ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c=12000934.32;
            objContract.ECM_Hybrid_CustInvest_Total_PercentGP__c=243123.33;
            objContract.ECM_Overall_Investment_Figure__c=122.43;
            //objContract.ECM_Contract_Type__c=contractType.Id;
            objContract.ECM_Agreement_Type__c=contractType.Id;
            objContract.recordTypeId=contractRecordTypeId;
            objContract.ECM_Channel__c='On-Premise';
            objContract.ECM_Banner__c=banner.Id;
            objContract.StartDate = system.today();
            objContract.Contract_End_Date__c = system.today()+360;
            insert objContract;
            objContract.Status ='In Approval Process';
            update objContract;
            
            String eCMApprovalLogRecordTypeId = ECM_Approval_Log__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Primary approver').getRecordTypeId();
            ECM_Approval_Log__c ecmCurrentApprovalLog = new ECM_Approval_Log__c();
            ecmCurrentApprovalLog.ECM_Approver_s_Position__c='Legal';
            ecmCurrentApprovalLog.Name='test@test.com';
            ecmCurrentApprovalLog.ECM_Status__c='Requested';
            ecmCurrentApprovalLog.ECM_Comment__c='Test User';
            //ecmCurrentApprovalLog.ECM_Time_Date_Log__c=;
            ecmCurrentApprovalLog.ECM_Contract__c=objContract.Id;
            ecmCurrentApprovalLog.RecordTypeId=eCMApprovalLogRecordTypeId;
            //Insert ecmCurrentApprovalLog;
            
            
            Messaging.InboundEmail email = new Messaging.InboundEmail();
            Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
            
            Contract con=new contract();
            con=[select ContractNumber,Status,Owner.Name from Contract where Id=:objContract.Id];
            
            email.subject='Sandbox:'+con.ContractNumber+'_Please approve commercial contract';
            email.fromAddress='test@test.com';
            email.plainTextBody='Dear Approver,\n\n'+
                +'Please review the contract details and make a decision following the below INSTRUCTIONS:\n'+
                +'If you APPROVE the offer, please reply to this email and type “approve” in the 1st line,\n'+
                +'If you REJECT the offer, please reply to this email and type “reject” in the 1st line,\n'+
                +'If you want to add a comment to your reply, please type it in the 2nd line.\n\n'+
                +'Please do NOT CHANGE or REMOVE the subject of this email.\n\n'+
                +'Thank you!';
            
            Messaging.InboundEmail email1 = new Messaging.InboundEmail();
            email1.subject='Sandbox:'+con.ContractNumber+'_Please approve commercial contract';
            email1.fromAddress='test1@test.com';
            email1.plainTextBody='Dear Approver,\n\n'+
                +'Please review the contract details and make a decision following the below INSTRUCTIONS:\n'+
                +'If you APPROVE the offer, please reply to this email and type “approve” in the 1st line,\n'+
                +'If you REJECT the offer, please reply to this email and type “reject” in the 1st line,\n'+
                +'If you want to add a comment to your reply, please type it in the 2nd line.\n\n'+
                +'Please do NOT CHANGE or REMOVE the subject of this email.\n\n'+
                +'Thank you!'+
                +'Contract Header Details\n'+ 
                +'Contract created by 	Nelson Sahu - Srep AU\n' 
                +'Territory 	Sales NSW \n'+
                +'Customer name 	CAFE PACI \n'+
                +'Agreement type 	Events & Sponsorship \n'+
                +'Start date 	01/06/2020 \n'+
                +'End date 	31/05/2021 \n'+
                +'Contract number, name 	00002695, CAFE PACI_ENS_2020-06-01 \n'+
                +'\n'+
                +'Investment summary \n'+
                +'Total trade investment 	\n'+
                +'Total A&P investment 	\n'+
                +'Overall investment 	€ \n'+
                +'Total GP 	\n'+
                +'GP ROI 	\n'+
                +'CAP ROI 	\n'+
                +'% of the total investment vs NSV 	\n'+
                +'fix/variable share 	/ € \n'+
                +'Generated NSV 	\n'+
                +'\n'+
                +'Category split \n'+
                +'KPI	Reserve	Innovation	Premium core 	Local priority\n'+
                +'NSV 		\n'+		
                +'Gross Profit \n'+				
                +'Gross Margin \n'+				
                +'\n'+
                +'Products & investment details \n'+
                +'No.	Product name	Retro Investment	Trade Investment	A&P Invest	Gross Margin	Gross Profit	NSV\n'+
                +'1 	BAILEYS ORIGINAL 0.7L 12X01 17.0% 		€ 	€ 	66.67% 	5.52€ 	8.29€ \n'+
                +'2 	BUNDABERG RED 0.7L 12X01 37.0% 		€ 	€ 	16.67% 	2.00€ 	12.00€ \n'+
                +'\n'+
                +'Thanks and Regards,\n'+
                +'Contract Management System \n\n'+ 
                +'________________________________________\n'+
                +'This email and any files transmitted with it are confidential and intended solely for the use of the individual or entity to which they are addressed. If you have received this email in error please notify the Global Diageo Service Desk on +44 (0) 203 684 9280. For Diageo India, please contact - 1800 3000 1197 \n'+
                +'This footnote also confirms that this email has been scanned for all viruses by the Proofpoint Email Security service. \n'+
                +'http://www.diageo.com';
            for(Integer i=0;i<=10;i++){
                String temp=email1.plainTextBody;
                email1.plainTextBody='\n Loop repeats:'+i+'\n\n'+temp;
                if(i==9){
                    email1.plainTextBody=email1.plainTextBody+'From:';
                }
            }
            
            ECM_ContractApprovalEmailService catcher= new ECM_ContractApprovalEmailService();
            Messaging.InboundEmailResult result = catcher.handleInboundEmail(email, envelope);
            Messaging.InboundEmailResult result1 = catcher.handleInboundEmail(email1, envelope);
            System.assertEquals( result.success  ,true,'Both parameter should match');  
            System.assertEquals( result1.success  ,true,'Both parameter should match');     
            
        }
        
        Test.stopTest();
    }
    
    @isTest 
    public static void test3(){
        Test.startTest();
        
        Profile prof = [select id from profile where name=: 'Sales Representative'];
        User usr = new User();
        usr.firstName = 'test1';
        usr.lastName = 'test2';
        usr.profileId = prof.id;        
        usr.email = 'test@test.com';
        usr.Username ='testcm1'+'_'+userinfo.getOrganizationId()+'@test.com';
        usr.Alias='test';
        usr.Timezonesidkey='America/Los_Angeles';
        usr.LocaleSidKey='en_US';
        usr.LanguageLocaleKey='en_US';
        usr.EmailEncodingKey='UTF-8';
        usr.Available_Countries__c='AU';
        usr.Title='Legal';
        insert usr;
        System.runAs(usr){
            Id geographyId = EDGE_UtilityTestClass.setupCountry('AU'); 
            // Id geographyId1 = EDGE_UtilityTestClass.setupCountry('AU'); 
            Territory__c testterritory=New Territory__c();
            testterritory.Name='Testterriotory';
            testterritory.Territory_Type__c='Sales';
            testterritory.Country__c= geographyId;
            testterritory.Status__c='Active';
            testterritory.Primary_Sales_Rep__c = usr.id;
            insert testterritory;
            
            ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
            contractType.Name='Promotional';
            contractType.Geography__c=geographyId;
            contractType.ECM_Abbreviation__c='POM';
            contractType.ECM_Automatic_approval_amount_threshold__c=40.00;
            contractType.Volume_UoM_for_Spirits__c='BTL';
            contractType.ECM_Screen_3_field_configuration__c='Product Name;Brand;Volume Target;Investment';
            contractType.ECM_Volume_UoM_for_Beer__c='EU';
            insert contractType;
            
            String bannerRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
            
            Pick_Up_Options__c banner= new Pick_Up_Options__c();
            banner.Name='Range[ES]';
            banner.Geography__c=geographyId;
            banner.RecordTypeId=bannerRecordTypeId;
            insert banner;
            
            Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
            outletAccount.Person_Responsible__c= usr.Id;
            outletAccount.OwnerId = usr.Id;
            //outletAccount.Operator__c=contractType.id;
            insert outletAccount;
            
            String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
            Contract objContract = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
            objContract.Status = 'Draft';
            objContract.Contract_End_Date__c = System.today()+29;
            objContract.AccountId=outletAccount.Id;
            objContract.ECM_Territory__c=testterritory.Id;
            objContract.ECM_Overall_Investment_Amount__c=100020.55;
            objContract.ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c=12000934.32;
            objContract.ECM_Hybrid_CustInvest_Total_PercentGP__c=243123.33;
            objContract.ECM_Overall_Investment_Figure__c=122.43;
            //objContract.ECM_Contract_Type__c=contractType.Id;
            objContract.ECM_Agreement_Type__c=contractType.Id;
            objContract.recordTypeId=contractRecordTypeId;
            objContract.ECM_Channel__c='On-Premise';
            objContract.ECM_Banner__c=banner.Id;
            objContract.StartDate = system.today();
            objContract.Contract_End_Date__c = system.today()+360;
            insert objContract;
            objContract.Status ='In Approval Process';
            update objContract;
            
            String eCMApprovalLogRecordTypeId = ECM_Approval_Log__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Primary approver').getRecordTypeId();
            ECM_Approval_Log__c ecmCurrentApprovalLog = new ECM_Approval_Log__c();
            ecmCurrentApprovalLog.ECM_Approver_s_Position__c='Legal';
            ecmCurrentApprovalLog.Name='test@test.com';
            ecmCurrentApprovalLog.ECM_Status__c='Requested';
            ecmCurrentApprovalLog.ECM_Comment__c='Test User';
            //ecmCurrentApprovalLog.ECM_Time_Date_Log__c=;
            ecmCurrentApprovalLog.ECM_Contract__c=objContract.Id;
            ecmCurrentApprovalLog.RecordTypeId=eCMApprovalLogRecordTypeId;
            Insert ecmCurrentApprovalLog;
            
            ECM_Approval_Log__c ecmCurrentApprovalLog1 = new ECM_Approval_Log__c();
            ecmCurrentApprovalLog1.ECM_Approver_s_Position__c='Legal';
            ecmCurrentApprovalLog1.Name='test1@test.com';
            ecmCurrentApprovalLog1.ECM_Status__c='Requested';
            ecmCurrentApprovalLog1.ECM_Comment__c='Test User';
            //ecmCurrentApprovalLog1.ECM_Time_Date_Log__c=;
            ecmCurrentApprovalLog1.ECM_Contract__c=objContract.Id;
            ecmCurrentApprovalLog1.RecordTypeId=eCMApprovalLogRecordTypeId;
            Insert ecmCurrentApprovalLog1;
            
            
            Messaging.InboundEmail email = new Messaging.InboundEmail();
            Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
            
            Contract con=new contract();
            con=[select ContractNumber,Status,Owner.Name from Contract where Id=:objContract.Id];
            
            email.subject='Sandbox:'+con.ContractNumber+'_Please approve commercial contract';
            email.fromAddress='test@test.com';
            email.plainTextBody='Dear Approver,\n\n'+
                +'Please review the contract details and make a decision following the below INSTRUCTIONS:\n'+
                +'If you APPROVE the offer, please reply to this email and type “approve” in the 1st line,\n'+
                +'If you REJECT the offer, please reply to this email and type “reject” in the 1st line,\n'+
                +'If you want to add a comment to your reply, please type it in the 2nd line.\n\n'+
                +'Please do NOT CHANGE or REMOVE the subject of this email.\n\n'+
                +'Thank you!';
            
            Messaging.InboundEmail email1 = new Messaging.InboundEmail();
            email1.subject='Re:'+con.ContractNumber+'_Please approve commercial contract';
            email1.fromAddress='test@test.com';
            email1.plainTextBody='Approved';
            
            Messaging.InboundEmail email2 = new Messaging.InboundEmail();
            email2.subject='Re:'+con.ContractNumber+'_Please approve commercial contract';
            email2.fromAddress='test@test.com';
            email2.plainTextBody='Reject';
            
            ECM_ContractApprovalEmailService catcher= new ECM_ContractApprovalEmailService();
            Messaging.InboundEmailResult result = catcher.handleInboundEmail(email, envelope);
            Messaging.InboundEmailResult result1 = catcher.handleInboundEmail(email1, envelope);
            Messaging.InboundEmailResult result2 = catcher.handleInboundEmail(email2, envelope);
            System.assertEquals( result.success  ,true,'Both parameter should match');  
            System.assertEquals( result1.success  ,true,'Both parameter should match');  
            System.assertEquals( result2.success  ,true,'Both parameter should match');
        }
        
        Test.stopTest();
    }
    @isTest 
    public static void test4(){
        Test.startTest();
        
        Profile prof = [select id from profile where name=: 'Sales Representative'];
        User usr = new User();
        usr.firstName = 'test1';
        usr.lastName = 'test2';
        usr.profileId = prof.id;        
        usr.email = 'test@test.com';
        usr.Username ='testcm1235'+'_'+userinfo.getOrganizationId()+'@test.com';
        usr.Alias='test';
        usr.Timezonesidkey='America/Los_Angeles';
        usr.LocaleSidKey='en_US';
        usr.LanguageLocaleKey='en_US';
        usr.EmailEncodingKey='UTF-8';
        usr.Available_Countries__c='ES';
        usr.Title='Legal';
        insert usr;
        System.runAs(usr){
            Id geographyId = EDGE_UtilityTestClass.setupCountry('ES'); 
            // Id geographyId1 = EDGE_UtilityTestClass.setupCountry('AU'); 
            Territory__c testterritory=New Territory__c();
            testterritory.Name='Testterriotory';
            testterritory.Territory_Type__c='Sales';
            testterritory.Country__c= geographyId;
            testterritory.Status__c='Active';
            testterritory.Primary_Sales_Rep__c = usr.id;
            insert testterritory;
            
            ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
            contractType.Name='Promotional';
            contractType.Geography__c=geographyId;
            contractType.ECM_Abbreviation__c='POM';
            contractType.ECM_Automatic_approval_amount_threshold__c=40.00;
            contractType.Volume_UoM_for_Spirits__c='BTL';
            contractType.ECM_Volume_UoM_for_Beer__c='EU';
            contractType.ECM_Screen_3_field_configuration__c='Product Name;Brand;Volume Target;Investment';
            insert contractType;
            
            String bannerRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
            
            Pick_Up_Options__c banner= new Pick_Up_Options__c();
            banner.Name='Range[ES]';
            banner.Geography__c=geographyId;
            banner.RecordTypeId=bannerRecordTypeId;
            insert banner;
            
            Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
            outletAccount.Person_Responsible__c= usr.Id;
            outletAccount.OwnerId = usr.Id;
            //outletAccount.Operator__c=contractType.id;
            insert outletAccount;
            
            String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
            Contract objContract = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
            objContract.Status = 'Draft';
            objContract.Contract_End_Date__c = System.today()+29;
            objContract.AccountId=outletAccount.Id;
            objContract.ECM_Territory__c=testterritory.Id;
            objContract.ECM_Overall_Investment_Amount__c=100020.55;
            objContract.ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c=12000934.32;
            objContract.ECM_Hybrid_CustInvest_Total_PercentGP__c=243123.33;
            objContract.ECM_Overall_Investment_Figure__c=122.43;
            //objContract.ECM_Contract_Type__c=contractType.Id;
            objContract.ECM_Agreement_Type__c=contractType.Id;
            objContract.recordTypeId=contractRecordTypeId;
            objContract.ECM_Channel__c='On-Premise';
            objContract.ECM_Banner__c=banner.Id;
            objContract.StartDate = system.today();
            objContract.Contract_End_Date__c = system.today()+360;
            insert objContract;
            objContract.Status ='In Approval Process';
            update objContract;
            String eCMApprovalLogRecordTypeId = ECM_Approval_Log__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Primary approver').getRecordTypeId();
            ECM_Approval_Log__c ecmCurrentApprovalLog = new ECM_Approval_Log__c();
            ecmCurrentApprovalLog.ECM_Approver_s_Position__c='Legal';
            ecmCurrentApprovalLog.Name='test@test.com';
            ecmCurrentApprovalLog.ECM_Status__c='Requested';
            ecmCurrentApprovalLog.ECM_Comment__c='Test User';
            ecmCurrentApprovalLog.ECM_No_of_Approval_Cycles__c = 1;
            ecmCurrentApprovalLog.ECM_Type__c = 'Contract';
            //ecmCurrentApprovalLog.ECM_Time_Date_Log__c=;
            ecmCurrentApprovalLog.ECM_Contract__c=objContract.Id;
            ecmCurrentApprovalLog.RecordTypeId=eCMApprovalLogRecordTypeId;
            Insert ecmCurrentApprovalLog;
            
            
            Messaging.InboundEmail email = new Messaging.InboundEmail();
            Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
            
            Contract con=new contract();
            con=[select ContractNumber,Status,Owner.Name from Contract where Id=:objContract.Id];
            
            email.subject='Sandbox:'+con.ContractNumber+'_Please approve contract, sales driver and sales driver item details';
            email.fromAddress='test@test.com';
            email.plainTextBody='Dear Approver,\n\n'+
                +'Please review the contract details and make a decision following the below INSTRUCTIONS:\n'+
                +'If you APPROVE the offer, please reply to this email and type “approve” in the 1st line,\n'+
                +'If you REJECT the offer, please reply to this email and type “reject” in the 1st line,\n'+
                +'If you want to add a comment to your reply, please type it in the 2nd line.\n\n'+
                +'Please do NOT CHANGE or REMOVE the subject of this email.\n\n'+
                +'Thank you!';
            
            Messaging.InboundEmail email1 = new Messaging.InboundEmail();
            email1.subject='Sandbox:'+objContract.Id+'_Please approve contract and sales driver details';
            email1.fromAddress='test@test.com';
            email1.plainTextBody='Dear Approver,\n\n'+
                +'Please review the contract details and make a decision following the below INSTRUCTIONS:\n'+
                +'If you APPROVE the offer, please reply to this email and type “approve” in the 1st line,\n'+
                +'If you REJECT the offer, please reply to this email and type “reject” in the 1st line,\n'+
                +'If you want to add a comment to your reply, please type it in the 2nd line.\n\n'+
                +'Please do NOT CHANGE or REMOVE the subject of this email.\n\n'+
                +'Thank you!';
            Messaging.InboundEmail email2 = new Messaging.InboundEmail();
            email2.subject='Re:'+con.ContractNumber+'_Please approve contract and sales driver item details';
            email2.fromAddress='test@test.com';
            email2.plainTextBody='Approved';
            
             Messaging.InboundEmail email3 = new Messaging.InboundEmail();
            email3.subject='Re:'+con.ContractNumber+'_Please approve sales driver and sales driver item details';
            email3.fromAddress='test@test.com';
            email3.plainTextBody='Approved';
            
            Messaging.InboundEmail email4 = new Messaging.InboundEmail();
            email4.subject='Re:'+con.ContractNumber+'_Please approve sales driver item details';
            email4.fromAddress='test@test.com';
            email4.plainTextBody='Approved';
            
            Messaging.InboundEmail email5 = new Messaging.InboundEmail();
            email5.subject='RE:'+con.ContractNumber+'_Please approve sales driver details';
            email5.fromAddress='test@test.com';
            email5.plainTextBody='Approved';
            
            
            ECM_ContractApprovalEmailService catcher= new ECM_ContractApprovalEmailService();
            Messaging.InboundEmailResult result = catcher.handleInboundEmail(email, envelope);
            Messaging.InboundEmailResult result1 = catcher.handleInboundEmail(email1, envelope);
            Messaging.InboundEmailResult result2 = catcher.handleInboundEmail(email2, envelope);
            Messaging.InboundEmailResult result3 = catcher.handleInboundEmail(email3, envelope);
            Messaging.InboundEmailResult result4 = catcher.handleInboundEmail(email4, envelope);
            Messaging.InboundEmailResult result5 = catcher.handleInboundEmail(email5, envelope);

            System.assertEquals( result.success  ,true,'Both parameter should match');  
            System.assertEquals( result1.success  ,true,'Both parameter should match');  
            System.assertEquals( result2.success  ,true,'Both parameter should match');
            System.assertEquals( result3.success  ,true,'Both parameter should match');  
            System.assertEquals( result4.success  ,true,'Both parameter should match');  
            System.assertEquals( result5.success  ,true,'Both parameter should match');
            
        }
    
        Test.stopTest();
    }
    
    //Changes related to addendum
     @isTest 
    public static void test5(){
        Test.startTest();
        
        Profile prof = [select id from profile where name=: 'Sales Representative'];
        User usr = new User();
        usr.firstName = 'test1';
        usr.lastName = 'test2';
        usr.profileId = prof.id;        
        usr.email = 'test@test.com';
        usr.Username ='testcm1'+'_'+userinfo.getOrganizationId()+'@test.com';
        usr.Alias='test';
        usr.Timezonesidkey='America/Los_Angeles';
        usr.LocaleSidKey='en_US';
        usr.LanguageLocaleKey='en_US';
        usr.EmailEncodingKey='UTF-8';
        usr.Available_Countries__c='AU';
        usr.Title='Legal';
        insert usr;
        System.runAs(usr){
            Id geographyId = EDGE_UtilityTestClass.setupCountry('AU'); 
            // Id geographyId1 = EDGE_UtilityTestClass.setupCountry('AU'); 
            Territory__c testterritory=New Territory__c();
            testterritory.Name='Testterriotory';
            testterritory.Territory_Type__c='Sales';
            testterritory.Country__c= geographyId;
            testterritory.Status__c='Active';
            testterritory.Primary_Sales_Rep__c = usr.id;
            insert testterritory;
            
            ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
            contractType.Name='Promotional';
            contractType.Geography__c=geographyId;
            contractType.ECM_Abbreviation__c='POM';
            contractType.ECM_Automatic_approval_amount_threshold__c=40.00;
            contractType.Volume_UoM_for_Spirits__c='BTL';
            contractType.ECM_Screen_3_field_configuration__c='Product Name;Brand;Volume Target;Investment';
            contractType.ECM_Volume_UoM_for_Beer__c='EU';
            insert contractType;
            
            String bannerRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
            
            Pick_Up_Options__c banner= new Pick_Up_Options__c();
            banner.Name='Range[ES]';
            banner.Geography__c=geographyId;
            banner.RecordTypeId=bannerRecordTypeId;
            insert banner;
            
            Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
            outletAccount.Person_Responsible__c= usr.Id;
            outletAccount.OwnerId = usr.Id;
            //outletAccount.Operator__c=contractType.id;
            insert outletAccount;
            
            String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
            Contract objContract = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
            objContract.Status = 'Draft';
            objContract.Contract_End_Date__c = System.today()+29;
            objContract.AccountId=outletAccount.Id;
            objContract.ECM_Territory__c=testterritory.Id;
            objContract.ECM_Overall_Investment_Amount__c=100020.55;
            objContract.ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c=12000934.32;
            objContract.ECM_Hybrid_CustInvest_Total_PercentGP__c=243123.33;
            objContract.ECM_Overall_Investment_Figure__c=122.43;
            //objContract.ECM_Contract_Type__c=contractType.Id;
            objContract.ECM_Agreement_Type__c=contractType.Id;
            objContract.recordTypeId=contractRecordTypeId;
            objContract.ECM_Channel__c='On-Premise';
            objContract.ECM_Banner__c=banner.Id;
            objContract.StartDate = system.today();
            objContract.Contract_End_Date__c = system.today()+360;
            insert objContract;
            objContract.Status ='Active';
            update objContract;
            
            ECM_Addendum__c addendum=new ECM_Addendum__c();
            addendum.Name = 'Test_addendum';
            addendum.ECM_Status__c ='In Approval';
            addendum.ECM_Addendum_Type__c= 'Add New Product';
            addendum.ECM_Contract__c=objContract.id;
            insert addendum;
            
            String eCMApprovalLogRecordTypeId = ECM_Approval_Log__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Primary approver').getRecordTypeId();
            ECM_Approval_Log__c ecmCurrentApprovalLog = new ECM_Approval_Log__c();
            ecmCurrentApprovalLog.ECM_Approver_s_Position__c='Legal';
            ecmCurrentApprovalLog.Name='test@test.com';
            ecmCurrentApprovalLog.ECM_Status__c='Requested';
            ecmCurrentApprovalLog.ECM_Comment__c='Test User';
            //ecmCurrentApprovalLog.ECM_Time_Date_Log__c=;
            ecmCurrentApprovalLog.ECM_Contract__c=objContract.Id;
            ecmCurrentApprovalLog.ECM_Addendum__c = addendum.id;
            ecmCurrentApprovalLog.RecordTypeId=eCMApprovalLogRecordTypeId;
            Insert ecmCurrentApprovalLog;
            
            ECM_Approval_Log__c ecmCurrentApprovalLog1 = new ECM_Approval_Log__c();
            ecmCurrentApprovalLog1.ECM_Approver_s_Position__c='Legal';
            ecmCurrentApprovalLog1.Name='test1@test.com';
            ecmCurrentApprovalLog1.ECM_Status__c='Requested';
            ecmCurrentApprovalLog1.ECM_Comment__c='Test User';
            //ecmCurrentApprovalLog1.ECM_Time_Date_Log__c=;
            ecmCurrentApprovalLog1.ECM_Contract__c=objContract.Id;
            ecmCurrentApprovalLog.ECM_Addendum__c = addendum.id;
            ecmCurrentApprovalLog1.RecordTypeId=eCMApprovalLogRecordTypeId;
            Insert ecmCurrentApprovalLog1;
            
            
            Messaging.InboundEmail email = new Messaging.InboundEmail();
            Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
            
            Contract con=new contract();
            con=[select ContractNumber,Status,Owner.Name from Contract where Id=:objContract.Id];
            
            email.subject='Sandbox:'+con.ContractNumber+'_Please approve commercial contract Addendum';
            email.fromAddress='test@test.com';
            email.plainTextBody='Dear Approver,\n\n'+
                +'Please review the contract details and make a decision following the below INSTRUCTIONS:\n'+
                +'If you APPROVE the offer, please reply to this email and type “approve” in the 1st line,\n'+
                +'If you REJECT the offer, please reply to this email and type “reject” in the 1st line,\n'+
                +'If you want to add a comment to your reply, please type it in the 2nd line.\n\n'+
                +'Please do NOT CHANGE or REMOVE the subject of this email.\n\n'+
                +'Thank you!';
            
            Messaging.InboundEmail email1 = new Messaging.InboundEmail();
            email1.subject='Re:'+con.ContractNumber+'_Please approve commercial contract';
            email1.fromAddress='test@test.com';
            email1.plainTextBody='Approved';
            
            Messaging.InboundEmail email2 = new Messaging.InboundEmail();
            email2.subject='Re:'+con.ContractNumber+'_Please approve commercial contract';
            email2.fromAddress='test@test.com';
            email2.plainTextBody='Reject';
            
            ECM_ContractApprovalEmailService catcher= new ECM_ContractApprovalEmailService();
            Messaging.InboundEmailResult result = catcher.handleInboundEmail(email, envelope);
            Messaging.InboundEmailResult result1 = catcher.handleInboundEmail(email1, envelope);
            Messaging.InboundEmailResult result2 = catcher.handleInboundEmail(email2, envelope);
            System.assertEquals( result.success  ,true,'Both parameter should match');  
            System.assertEquals( result1.success  ,true,'Both parameter should match');  
            System.assertEquals( result2.success  ,true,'Both parameter should match');
        }
        
        Test.stopTest();
    }
    
}