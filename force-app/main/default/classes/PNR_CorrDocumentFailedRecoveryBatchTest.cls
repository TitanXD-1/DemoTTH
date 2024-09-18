@isTest
public class PNR_CorrDocumentFailedRecoveryBatchTest {
    @isTest
    public static void validateSendData(){
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AD');
        PNR_TestDataUtility.createOrgSettings();
        Account soldToAccObj  = PNR_TestDataUtility.getDirectCustomerRec();
        soldToAccObj.KUNNR__c = '10483';
        soldToAccObj.Country_ISO_Code__c = 'AD';
        insert soldToAccObj;
        
        Account payerAccObj  = PNR_TestDataUtility.getDirectCustomerRec();
        payerAccObj.AccountNumber = '8348946084';
        payerAccObj.KUNNR__c = '8348946084';
        payerAccObj.Country_ISO_Code__c = 'AD';
        insert payerAccObj;
        
        Order__c odrObj = PNR_TestDataUtility.getNewOrderData();
        odrObj.Account__c = soldToAccObj.Id;
        insert odrObj;
        
        Invoice__c invObj = PNR_TestDataUtility.getPNRInvoiceData();
        invObj.Account__c = soldToAccObj.Id;
        insert invObj;
        
        Invoice_Line_Item__c invItemObj = PNR_TestDataUtility.getInvLineItm(invObj.Id);
        insert invItemObj;
        
        Case caseRec = PNR_TestDataUtility.getDirectDisputesCase(soldToAccObj.Id);
        caseRec.Sales_Org__c = 'PL01'; //PION-1647 : setting sales org in case
        insert caseRec;
        
        Invoice_Line_Item__c invItemObjInsrt = [SELECT Id,Name FROM Invoice_Line_Item__c WHERE Id =:invItemObj.Id];
        
        Correction_Document__c corrDoc = PNR_TestDataUtility.getDirectCorrDoc(caseRec.Id, invObj.Id, soldToAccObj.Id, payerAccObj.Id);
        corrDoc.Sold_To__c = soldToAccObj.Id;
        corrDoc.Payer__c = payerAccObj.Id;
        insert corrDoc;
        PNR_CorrectionDocumentMapping__c docMapp = PNR_TestDataUtility.getCorrDocMap(invObj.Id,invItemObj.Id,corrDoc.Id);
        insert docMapp;
        PNR_CorrectionDocumentMapping__c docMapObj = [SELECT Id,Name FROM PNR_CorrectionDocumentMapping__c WHERE Id =:docMapp.Id];
        Correction_Document__c corrDocUpdt = [SELECT Id, Status__c 
                                              FROM Correction_Document__c 
                                              WHERE Id  =: corrDoc.Id];
        corrDocUpdt.Claimed_Invoice_Line_Items__c = docMapObj.Name;
        update corrDocUpdt; 
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
		mock.setStaticResource('CreditDebitRetSuccesss');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock); 
        
        Test.startTest();
        corrDocUpdt.Status__c = 'Approved';
        update corrDocUpdt;
        Test.stopTest();
        Correction_Document__c corrDocObjUpdt = [SELECT Id, Status__c,Data_Send_to_SAP__c 
                                              	FROM Correction_Document__c 
                                              	WHERE Id  =: corrDoc.Id];
        System.assertEquals(true, corrDocObjUpdt.Data_Send_to_SAP__c);
        
        //PION-1647 : to test billing details response for order held and success status
        corrDocUpdt.PNR_Billing_Document_Status__c = 'H';
        Update corrDocUpdt;
        
        corrDocUpdt.PNR_Billing_Document_Number__c = '12345';
        Update corrDocUpdt;
        PNR_CorrDocumentFailedRecoveryBatch pcrb = new PNR_CorrDocumentFailedRecoveryBatch();
		database.executeBatch(pcrb, 1);
       
        PNR_CorrDocuFailedRecoverySchedular cdsRecovery = new PNR_CorrDocuFailedRecoverySchedular();
        String sch = '0 0 23 * * ?';
        system.schedule('failed Test', sch, cdsRecovery);
    }
    
    //PION-1647 : to test billing details response error status
    @isTest
    public static void validateSendData2(){
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AD');
        PNR_TestDataUtility.createOrgSettings();
        Account soldToAccObj  = PNR_TestDataUtility.getDirectCustomerRec();
        soldToAccObj.KUNNR__c = '10483';
        soldToAccObj.Country_ISO_Code__c = 'AD';
        insert soldToAccObj;
        
        Account payerAccObj  = PNR_TestDataUtility.getDirectCustomerRec();
        payerAccObj.AccountNumber = '8348946084';
        payerAccObj.KUNNR__c = '8348946084';
        payerAccObj.Country_ISO_Code__c = 'AD';
        insert payerAccObj;
        
        Order__c odrObj = PNR_TestDataUtility.getNewOrderData();
        odrObj.Account__c = soldToAccObj.Id;
        insert odrObj;
        
        Invoice__c invObj = PNR_TestDataUtility.getPNRInvoiceData();
        invObj.Account__c = soldToAccObj.Id;
        insert invObj;
        
        Invoice_Line_Item__c invItemObj = PNR_TestDataUtility.getInvLineItm(invObj.Id);
        insert invItemObj;
        
        Case caseRec = PNR_TestDataUtility.getDirectDisputesCase(soldToAccObj.Id);
        caseRec.Sales_Org__c = 'PL01';
        insert caseRec;
        
        Invoice_Line_Item__c invItemObjInsrt = [SELECT Id,Name FROM Invoice_Line_Item__c WHERE Id =:invItemObj.Id];
        
        Correction_Document__c corrDoc = PNR_TestDataUtility.getDirectCorrDoc(caseRec.Id, invObj.Id, soldToAccObj.Id, payerAccObj.Id);
        corrDoc.Sold_To__c = soldToAccObj.Id;
        corrDoc.Payer__c = payerAccObj.Id;
        insert corrDoc;
        PNR_CorrectionDocumentMapping__c docMapp = PNR_TestDataUtility.getCorrDocMap(invObj.Id,invItemObj.Id,corrDoc.Id);
        insert docMapp;
        PNR_CorrectionDocumentMapping__c docMapObj = [SELECT Id,Name FROM PNR_CorrectionDocumentMapping__c WHERE Id =:docMapp.Id];
        Correction_Document__c corrDocUpdt = [SELECT Id, Status__c 
                                              FROM Correction_Document__c 
                                              WHERE Id  =: corrDoc.Id];
        corrDocUpdt.Claimed_Invoice_Line_Items__c = docMapObj.Name;
        update corrDocUpdt; 
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
		mock.setStaticResource('CreditDebitRetSuccesss');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock); 
        
        Test.startTest();
        corrDocUpdt.Status__c = 'Approved';
        update corrDocUpdt;
        Test.stopTest();
        Correction_Document__c corrDocObjUpdt = [SELECT Id, Status__c,Data_Send_to_SAP__c 
                                              	FROM Correction_Document__c 
                                              	WHERE Id  =: corrDoc.Id];
        System.assertEquals(true, corrDocObjUpdt.Data_Send_to_SAP__c);
        
        corrDocUpdt.PNR_Billing_Document_Status__c = 'C';
        Update corrDocUpdt;
		PNR_CorrDocumentFailedRecoveryBatch pcrb = new PNR_CorrDocumentFailedRecoveryBatch();
		database.executeBatch(pcrb, 1);
       
        PNR_CorrDocuFailedRecoverySchedular cdsRecovery = new PNR_CorrDocuFailedRecoverySchedular();
        String sch = '0 0 23 * * ?';
        system.schedule('failed Test', sch, cdsRecovery);
    }
    
    //PION-1647 : to test billing details response error status
    @isTest
    public static void validateSendData3(){
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AD');
        PNR_TestDataUtility.createOrgSettings();
        Account soldToAccObj  = PNR_TestDataUtility.getDirectCustomerRec();
        soldToAccObj.KUNNR__c = '10483';
        soldToAccObj.Country_ISO_Code__c = 'AD';
        insert soldToAccObj;
        
        Account payerAccObj  = PNR_TestDataUtility.getDirectCustomerRec();
        payerAccObj.AccountNumber = '8348946084';
        payerAccObj.KUNNR__c = '8348946084';
        payerAccObj.Country_ISO_Code__c = 'AD';
        insert payerAccObj;
        
        Order__c odrObj = PNR_TestDataUtility.getNewOrderData();
        odrObj.Account__c = soldToAccObj.Id;
        insert odrObj;
        
        Invoice__c invObj = PNR_TestDataUtility.getPNRInvoiceData();
        invObj.Account__c = soldToAccObj.Id;
        insert invObj;
        
        Invoice_Line_Item__c invItemObj = PNR_TestDataUtility.getInvLineItm(invObj.Id);
        insert invItemObj;
        
        Case caseRec = PNR_TestDataUtility.getDirectDisputesCase(soldToAccObj.Id);
        caseRec.Sales_Org__c = 'PL01';
        insert caseRec;
        
        Invoice_Line_Item__c invItemObjInsrt = [SELECT Id,Name FROM Invoice_Line_Item__c WHERE Id =:invItemObj.Id];
        
        Correction_Document__c corrDoc = PNR_TestDataUtility.getDirectCorrDoc(caseRec.Id, invObj.Id, soldToAccObj.Id, payerAccObj.Id);
        corrDoc.Sold_To__c = soldToAccObj.Id;
        corrDoc.Payer__c = payerAccObj.Id;
        insert corrDoc;
        PNR_CorrectionDocumentMapping__c docMapp = PNR_TestDataUtility.getCorrDocMap(invObj.Id,invItemObj.Id,corrDoc.Id);
        insert docMapp;
        PNR_CorrectionDocumentMapping__c docMapObj = [SELECT Id,Name FROM PNR_CorrectionDocumentMapping__c WHERE Id =:docMapp.Id];
        Correction_Document__c corrDocUpdt = [SELECT Id, Status__c 
                                              FROM Correction_Document__c 
                                              WHERE Id  =: corrDoc.Id];
        corrDocUpdt.Claimed_Invoice_Line_Items__c = docMapObj.Name;
        update corrDocUpdt; 
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
		mock.setStaticResource('CreditDebitRetSuccesss');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock); 
        
        Test.startTest();
        corrDocUpdt.Status__c = 'Approved';
        update corrDocUpdt;
        Test.stopTest();
        Correction_Document__c corrDocObjUpdt = [SELECT Id, Status__c,Data_Send_to_SAP__c 
                                              	FROM Correction_Document__c 
                                              	WHERE Id  =: corrDoc.Id];
        System.assertEquals(true, corrDocObjUpdt.Data_Send_to_SAP__c);
        
        corrDocUpdt.PNR_Billing_Document_Status__c = 'D';
        Update corrDocUpdt;
		PNR_CorrDocumentFailedRecoveryBatch pcrb = new PNR_CorrDocumentFailedRecoveryBatch();
		database.executeBatch(pcrb, 1);
       
        PNR_CorrDocuFailedRecoverySchedular cdsRecovery = new PNR_CorrDocuFailedRecoverySchedular();
        String sch = '0 0 23 * * ?';
        system.schedule('failed Test', sch, cdsRecovery);
    }
    
    @isTest
    public static void validateSendDataError(){
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AD');
        PNR_TestDataUtility.createOrgSettings();
        Account soldToAccObj  = PNR_TestDataUtility.getDirectCustomerRec();
        soldToAccObj.KUNNR__c = '10483';
        soldToAccObj.Country_ISO_Code__c = 'AD';
        insert soldToAccObj;
        
        Account payerAccObj  = PNR_TestDataUtility.getDirectCustomerRec();
        payerAccObj.AccountNumber = '8348946084';
        payerAccObj.KUNNR__c = '8348946084';
        payerAccObj.Country_ISO_Code__c = 'AD';
        insert payerAccObj;
        
        Order__c odrObj = PNR_TestDataUtility.getNewOrderData();
        odrObj.Account__c = soldToAccObj.Id;
        insert odrObj;
        
        Invoice__c invObj = PNR_TestDataUtility.getPNRInvoiceData();
        invObj.Account__c = soldToAccObj.Id;
        insert invObj;
        
        Invoice_Line_Item__c invItemObj = PNR_TestDataUtility.getInvLineItm(invObj.Id);
        insert invItemObj;
        Case caseRec = PNR_TestDataUtility.getDirectDisputesCase(soldToAccObj.Id);
        insert caseRec;
        
        
        
        Invoice_Line_Item__c invItemObjInsrt = [SELECT Id,Name FROM Invoice_Line_Item__c WHERE Id =:invItemObj.Id];
        
        Correction_Document__c corrDoc = PNR_TestDataUtility.getDirectCorrDoc(caseRec.Id, invObj.Id, soldToAccObj.Id, payerAccObj.Id);
        corrDoc.Sold_To__c = soldToAccObj.Id;
        corrDoc.Payer__c = payerAccObj.Id;
        corrDoc.Document_Type__c = 'YCR';
        insert corrDoc;
        PNR_CorrectionDocumentMapping__c docMapp = PNR_TestDataUtility.getCorrDocMap(invObj.Id,invItemObj.Id,corrDoc.Id);
        insert docMapp;
        PNR_CorrectionDocumentMapping__c docMapObj = [SELECT Id,Name FROM PNR_CorrectionDocumentMapping__c WHERE Id =:docMapp.Id];

        Correction_Document__c corrDocUpdt = [SELECT Id, Status__c 
                                              FROM Correction_Document__c 
                                              WHERE Id  =: corrDoc.Id];
        corrDocUpdt.Claimed_Invoice_Line_Items__c = docMapObj.Name;
        update corrDocUpdt;
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
		mock.setStaticResource('CreditDebitRetError');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
        
        Test.startTest();
        corrDocUpdt.Status__c = 'Approved';
        update corrDocUpdt;
        Test.stopTest();
        Correction_Document__c corrDocObjUpdt = [SELECT Id, Status__c,Data_Send_to_SAP__c 
                                              	FROM Correction_Document__c 
                                              	WHERE Id  =: corrDoc.Id];
        System.assertEquals(false, corrDocObjUpdt.Data_Send_to_SAP__c);
        PNR_CorrDocumentFailedRecoveryBatch pcrb = new PNR_CorrDocumentFailedRecoveryBatch();
		database.executeBatch(pcrb, 1);
       
        PNR_CorrDocuFailedRecoverySchedular cdsRecovery = new PNR_CorrDocuFailedRecoverySchedular();
        String sch = '0 0 23 * * ?';
        system.schedule('failed Test', sch, cdsRecovery);
    }
    @isTest
    public static void validateErrorStatusCode(){
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AD');
        PNR_TestDataUtility.createOrgSettings();
        Account soldToAccObj  = PNR_TestDataUtility.getDirectCustomerRec();
        soldToAccObj.KUNNR__c = '10483';
        soldToAccObj.Country_ISO_Code__c = 'AD';
        insert soldToAccObj;
        
        Account payerAccObj  = PNR_TestDataUtility.getDirectCustomerRec();
        payerAccObj.AccountNumber = '8348946084';
        payerAccObj.KUNNR__c = '8348946084';
        payerAccObj.Country_ISO_Code__c = 'AD';
        insert payerAccObj;
        
        Order__c odrObj = PNR_TestDataUtility.getNewOrderData();
        odrObj.Account__c = soldToAccObj.Id;
        insert odrObj;
        
        Invoice__c invObj = PNR_TestDataUtility.getPNRInvoiceData();
        invObj.Account__c = soldToAccObj.Id;
        insert invObj;
        
        Invoice_Line_Item__c invItemObj = PNR_TestDataUtility.getInvLineItm(invObj.Id);
        insert invItemObj;
        Case caseRec = PNR_TestDataUtility.getDirectDisputesCase(soldToAccObj.Id);
        insert caseRec;
        
        
        Invoice_Line_Item__c invItemObjInsrt = [SELECT Id,Name FROM Invoice_Line_Item__c WHERE Id =:invItemObj.Id];
        
        Correction_Document__c corrDoc = PNR_TestDataUtility.getDirectCorrDoc(caseRec.Id, invObj.Id, soldToAccObj.Id, payerAccObj.Id);
        corrDoc.Sold_To__c = soldToAccObj.Id;
        corrDoc.Payer__c = payerAccObj.Id;
        insert corrDoc;
        PNR_CorrectionDocumentMapping__c docMapp = PNR_TestDataUtility.getCorrDocMap(invObj.Id,invItemObj.Id,corrDoc.Id);
        insert docMapp;
        PNR_CorrectionDocumentMapping__c docMapObj = [SELECT Id,Name FROM PNR_CorrectionDocumentMapping__c WHERE Id =:docMapp.Id];
        Correction_Document__c corrDocUpdt = [SELECT Id, Status__c 
                                              FROM Correction_Document__c 
                                              WHERE Id  =: corrDoc.Id];
        corrDocUpdt.Claimed_Invoice_Line_Items__c = docMapObj.Name;
        update corrDocUpdt;
        
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
		mock.setStaticResource('CreditDebitRetError');
        mock.setStatusCode(500);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
        
        Test.startTest();
        corrDocUpdt.Status__c = 'Approved';
        update corrDocUpdt;
        Test.stopTest();
        PNR_CorrDocumentFailedRecoveryBatch pcrb = new PNR_CorrDocumentFailedRecoveryBatch();
		database.executeBatch(pcrb, 1);
       
        PNR_CorrDocuFailedRecoverySchedular cdsRecovery = new PNR_CorrDocuFailedRecoverySchedular();
        String sch = '0 0 23 * * ?';
        system.schedule('failed Test', sch, cdsRecovery);
        System.assert(mock!= null);
    }
    @isTest
    public static void validateSendEmail(){
        Test.startTest();
        PNR_CorrDocuTriggerHelper.sendMsg('test@test.com','Error Message','corrDocId');
        Test.stopTest();
    }   
    
}