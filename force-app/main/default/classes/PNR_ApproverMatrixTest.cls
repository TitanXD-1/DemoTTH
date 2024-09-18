/**********************************************************************
Name: PNR_ApproverMatrixTest
=======================================================================
Req: This is the test class for the  PNR_ApproverMatrix class. 
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0   Sudipta Nandi        02/09/2019      Initial Development
2.0   Tanmoy Bardhan       03/09/2019      Final Development
***********************************************************************/
@isTest
public class PNR_ApproverMatrixTest {
    
    @testSetup static void testDataSetup() {
       
        PNR_TestDataUtility.createOrgSettings();
        Id countryId = PNR_TestDataUtility.setupCountry('GB');
        
        Sales_Organisation__c regGroup1 = new Sales_Organisation__c();
        regGroup1.RecordTypeId = Schema.sObjectType.Sales_Organisation__c.getRecordTypeInfosByDeveloperName().get('Regional_Group').getRecordTypeId();
        regGroup1.Name = 'Europe';
        regGroup1.Description__c = 'Europe';
        insert regGroup1;
        System.debug(regGroup1);
        
        //Creating sales organisation Record
        
        Sales_Organisation__c so = new Sales_Organisation__c();
        so.RecordTypeId = Schema.sObjectType.Sales_Organisation__c.getRecordTypeInfosByDeveloperName().get('SalesOrg').getRecordTypeId();
        so.Name = 'GreatBritain';
        so.Description__c = 'GreatBritain';
        so.Code__c = 'GB01';
        so.Country__c = countryId;
        
        so.PNR_Regional_Group__c = regGroup1.Id;
        insert so;
        //update so;
        System.debug('so'+so);
        
        List<Account> acclist=new List<Account>();
        Account cust= PNR_TestDataUtility.getDirectCustomerRec();
        cust.Country__c=countryId;
        cust.Sales_Org__c = 'GB01';
        accList.add(cust);
        
        Account cust2 = PNR_TestDataUtility.getDirectCustomerRec();
        cust2.Country__c=countryId;
        cust2.Sales_Org__c = 'GB01';
        cust2.Name = 'Test Customer Account2';
        cust2.AccountNumber = '10482';
        accList.add(cust2);
        Insert accList;
            
        PNR_Partner_Function__c pf=new PNR_Partner_Function__c();
        pf.PNR_Sales_Office__c = '001';
        pf.PNR_Sold_To__c = cust2.id;
        pf.PNR_Customer_No__c = cust2.id;
        pf.PNR_Type__c = 'Ship-To';
        insert pf;
        
        List<Invoice__c> invList = new List<Invoice__c>();
        Invoice__c inv =PNR_TestDataUtility.getPNRInvoiceData();
        inv.Account__c=cust.Id;
        inv.Sales_Org__c='GB01';
        invList.add(inv);
        
        Invoice__c inv2 =PNR_TestDataUtility.getPNRInvoiceData();
        inv2.Account__c=cust2.Id;
        inv2.Sales_Org__c='GB01';
        invList.add(inv2);
        insert invList;

		 Test.startTest();
        List<Case> caseList = new List<Case>();
        Case cse =PNR_TestDataUtility.getCaseData();
        cse.CurrencyIsoCode = 'GBP';
        cse.Claimed_Amount__c = 102.00;
        cse.AccountId=cust.Id;
        cse.Sales_Org__c = 'GB01';
        cse.Reference_Invoice__c=inv.Id;
        caseList.add(cse);
        
        
        Case cse2 =PNR_TestDataUtility.getCaseData();
        cse2.CurrencyIsoCode = 'AUD';
        cse2.Claimed_Amount__c = 102.00;
        cse2.AccountId=cust2.Id;
        cse2.Sales_Org__c = 'GB01';
        cse2.Reference_Invoice__c=inv2.Id;
        cse2.Type = 'Dispute - Delivery';
        caseList.add(cse2);
        insert caseList;
       
        List<Correction_Document__c> cdList = new List<Correction_Document__c>();
        Correction_Document__c crd =PNR_TestDataUtility.getCorrectionDocData();
        crd.Type_of_Reference__c='Single';
        crd.Reference_invoice__c =inv.Id;
        crd.Document_Type__c='YDR';
        crd.Correction_Of__c = 'Base Price - YPRI';
        crd.Approver_Email__c = 'a.a@gmail.com';
        crd.Case__c = cse.Id;
        crd.Sales_Org__c = 'GB01';
        crd.Reason_Code__c = 'B04 - Pricing - wrong base price / disc (IMC)';
        crd.Status__c = 'Externally Approved With Change';
        cdList.add(crd);
        
        Correction_Document__c crd2 =PNR_TestDataUtility.getCorrectionDocData();
        crd2.Type_of_Reference__c='Single';
        crd2.Reference_invoice__c =inv2.Id;
        crd2.Document_Type__c='YRET';
        crd2.Correction_Of__c = 'Base Price - YPRI';
        crd2.Approver_Email__c = 'a.a@gmail.com';
        crd2.Case__c = cse2.Id;
        crd2.Sales_Org__c = 'GB01';
        crd2.Reason_Code__c = 'Return: CUSTOMER ERROR';
        crd2.Status__c = 'Externally Approved With Change';
        crd2.Sold_To__c = cust2.Id;
        crd2.Payer__c = cust2.Id;
        cdList.add(crd2);
        insert cdList;
     
        List<Invoice_Line_Item__c> invLIList = new List<Invoice_Line_Item__c>();
        Invoice_Line_Item__c invLI = new Invoice_Line_Item__c();
        invLI.Invoice__c = inv.Id;
        invLI.Product_Number__c = 'Test01';
        invLI.SAP_Line_Item_Number__c = 'Test01';
        invLI.Correction_Document__c=crd.Id;
        invLIList.add(invLI);
        
        Invoice_Line_Item__c invLI2 = new Invoice_Line_Item__c();
        invLI2.Invoice__c = inv2.Id;
        invLI2.Product_Number__c = 'Test01';
        invLI2.SAP_Line_Item_Number__c = 'Test01';
        invLI2.Correction_Document__c=crd.Id;
        invLIList.add(invLI2);
        insert invLIList;
        
        List<PNR_CorrectionDocumentMapping__c> docMapList = new  List<PNR_CorrectionDocumentMapping__c>();
        PNR_CorrectionDocumentMapping__c docMapp = PNR_TestDataUtility.getCorrDocMap(inv.Id,invLI.Id,crd.Id);
        docMapList.add(docMapp);
         PNR_CorrectionDocumentMapping__c docMapp2 = PNR_TestDataUtility.getCorrDocMap(inv2.Id,invLI2.Id,crd2.Id);
        docMapList.add(docMapp2);
        Insert docMapList;
        
        PNR_CorrectionDocumentMapping__c docMapObj = [SELECT Id,Name FROM PNR_CorrectionDocumentMapping__c WHERE Correction_Document__c =:crd.Id];
        PNR_CorrectionDocumentMapping__c docMapObj2 = [SELECT Id,Name FROM PNR_CorrectionDocumentMapping__c WHERE Correction_Document__c =:crd2.Id];
        
        List<Correction_Document__c>  corrDocUpdtList = new List<Correction_Document__c>();
        crd.Claimed_Invoice_Line_Items__c = docMapObj.Name;
        corrDocUpdtList.add(crd);
        crd2.Claimed_Invoice_Line_Items__c = docMapObj2.Name;
        corrDocUpdtList.add(crd2);
        update corrDocUpdtList; 
        
        List<Approver_Matrix__c> appMatList = new List<Approver_Matrix__c>();
        Approver_Matrix__c appMat = PNR_TestDataUtility.getApproverMatrix();
        appMatList.add(appMat);
        
        Approver_Matrix__c appMat2 = PNR_TestDataUtility.getApproverMatrix();
        appMat2.Approval_Category__c = 'Return order approval';
        appMat2.PNR_Sales_Office__c = '001';
        appMatList.add(appMat2);
        insert appMatList;
        Test.stopTest();
    
    }
    
    
    @isTest 
    static void validatedmethod(){
     
        User usr = [SELECT Id,Name,LastName FROM User WHERE Id=:UserInfo.getUserID()];
        System.runAs (usr) {
            
            Account acc = [Select id from Account where Name = 'Test Customer Account'];
            Invoice__c inv = [Select id from Invoice__c where Account__c = :acc.Id];
            Correction_Document__c crd = [Select id from Correction_Document__c where Reference_invoice__c = :inv.id];
             Test.startTest();
            PNR_ApproverMatrix.updateEmailAdd(crd.Id, 'tanmoy.bardhan@diageo.com');
            PNR_ApproverMatrix.validateApproverEmail(crd.Id, 'tanmoy.bardhan@diageo.com');
            PNR_ApproverMatrix.getCorDocApproverEmail(crd.Id);

            StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
            mock.setStaticResource('CreditDebitRetSuccesss');
            mock.setStatusCode(200);
            mock.setHeader('Content-Type', 'application/json');
            Test.setMock(HttpCalloutMock.class, mock); 
           
            User testTLUser = PNR_TestDataUtility.runAsUser('TL','PNR_Teamlead'); 
            testTLUser.Regional_Group__c = 'Europe';
            insert testTLUser;
            PNR_ApproverMatrix.createRequestByTL(crd.Id);
            User usr_TL = [SELECT Id,Name,LastName,Regional_Group__c FROM User WHERE Id =:testTLUser.Id];
           
            System.runAs (usr_TL) {
                PNR_ApproverMatrix.createRequestByTL(crd.Id);
                PNR_ApproverMatrix.createRequestByTL(crd.Id);
                PNR_ApproverMatrix.checkTL();
            }
            
            PNR_ApproverMatrix.checkDataSentToSAP(crd.Id);
            PNR_ApproverMatrix.valStatus(crd.Id);
            //Boolean dataSentSAP = [SELECT Id,Data_Send_to_SAP__c FROM Correction_Document__c WHERE Id = :crd.Id].Data_Send_to_SAP__c;
            // system.assertEquals(True, dataSentSAP);
            Test.stopTest();
            
        }
    }
    
    @isTest 
    static void validatedmethod2(){
        
        User usr = [SELECT Id,Name,LastName FROM User WHERE Id=:UserInfo.getUserID()];
        System.runAs (usr) {
           
            
           Account acc = [Select id from Account where Name = 'Test Customer Account2'];
            Invoice__c inv = [Select id from Invoice__c where Account__c = :acc.Id];
            Correction_Document__c crd = [Select id  from Correction_Document__c where Reference_invoice__c = :inv.id];
           
            PNR_ApproverMatrix.updateEmailAdd(crd.Id, 'tanmoy.bardhan@diageo.com');
            StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
            mock.setStaticResource('CreditDebitRetSuccesss');
            mock.setStatusCode(200);
            mock.setHeader('Content-Type', 'application/json');
            Test.setMock(HttpCalloutMock.class, mock); 
            Test.startTest();
            
            User testTLUser = PNR_TestDataUtility.runAsUser('TestTL','PNR_Teamlead'); 
            testTLUser.Regional_Group__c = 'Europe';
            insert testTLUser;
            User usr_TL = [SELECT Id,Name,LastName,Regional_Group__c FROM User WHERE Id =:testTLUser.Id];
            System.runAs (usr_TL) {
                
                PNR_ApproverMatrix.createRequestByTL(crd.Id);
            }
            PNR_ApproverMatrix.checkDataSentToSAP(crd.Id);
            PNR_ApproverMatrix.valStatus(crd.Id);
            //Boolean dataSentSAP = [SELECT Id,Data_Send_to_SAP__c FROM Correction_Document__c WHERE Id = :crd.Id].Data_Send_to_SAP__c;
            // system.assertEquals(True, dataSentSAP);
            Test.stopTest();
            
        }
    }
    
}