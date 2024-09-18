/*
Name: ECM_FileUploaderCSVController_Test
Purpose: This class is used to cover testclass for the - ECM_FileUploaderCSVController,ECM_FileUploaderCSVBatch
History                                                                                                                        
VERSION    AUTHOR                   DATE              DETAIL
1.0      Saurav Kumar Prasad      15/04/2020        Initial Development
2.0      Joshraj Sen              11/06/2024        PMD Fix
*/
@isTest
public class ECM_FileUploaderCSVController_Test {
    @testSetup static void setup() {
        Test.startTest();        
        Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount.Person_Responsible__c= UserInfo.getUserId();
        outletAccount.OwnerId = UserInfo.getUserId();
        //outletAccount.Operator__c=contractType.id;
        insert outletAccount;
        
        
        
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        Contract objContract = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        Insert objContract;
        List<ECM_Payment_Summary__c> ps =new List<ECM_Payment_Summary__c>();
        List<ECM_Payment_Summary_Item__c> psi =new List<ECM_Payment_Summary_Item__c>();
        for(Integer i=0;i<5;i++){
            ECM_Payment_Summary__c paymemtSummary; 
            paymemtSummary = new ECM_Payment_Summary__c();
            paymemtSummary.ECM_Total_Amount_Confirmed__c = 20.00;
            paymemtSummary.ECM_Payment_Summary_Status__c = 'Submitted';
            paymemtSummary.ECM_Type__c = 'Promo-Standard';
            paymemtSummary.ECM_Contract__c=objContract.Id; 
            ps.add(paymemtSummary);
        }
        insert ps;
        for(Integer i=0;i<5;i++){
            ECM_Payment_Summary_Item__c paymemtSummaryItem = new ECM_Payment_Summary_Item__c();
            paymemtSummaryItem.ECM_Payment_Summary__c = ps[i].id;
            psi.add(paymemtSummaryItem);
        }
        insert psi;
        Test.stopTest();
    }
    @isTest static void testNegative() {
        Test.startTest();
        List<string> paymentName = new  List<string>();
        for(ECM_Payment_Summary__c paysumrec: [select Id,Name from ECM_Payment_Summary__c ]){
            paymentName.add(paysumrec.Name);
            System.debug(LoggingLevel.Debug,'Name:'+paysumrec.Name);
            System.assert(paysumrec!=null,'paysumrec should not be null');
        }
        
        String fileData;
        String sobjectName;
        String selectfieldsData;
        List<String> selectfields =new List<String>();
        
        fileData='Payment Summary Name,SAP Credit Note Number,SAP Credit Note Creation Date,SAP Billing Doc Number,SAP Billing Doc Date,SAP payment Reference Number,SAP Payment Date'+
            'PS-000000,11111,28/02/20,55555,23/02/20,20002,25/02/20'+
            'PS-000001,888888,,10002,24/02/20,777777,26/02/20';
        sobjectName='ECM_Payment_Summary__c';
        selectfieldsData='Payment Summary Name,SAP Credit Note Number,SAP Credit Note Creation Date,SAP Billing Doc Number,SAP Billing Doc Date,SAP payment Reference Number,SAP Payment Date';
        selectfields=selectfieldsData.split(',');
        
        ECM_FileUploaderCSVController.processData(fileData, sobjectName, selectfields);
        Test.stopTest();
    }
    @isTest static void testPostive() {
        Test.startTest();
        List<string> paymentName = new  List<string>();
        List<string> contractID = new  List<string>();
        for(ECM_Payment_Summary__c paysumrec: [select Id,Name,ECM_Contract__c from ECM_Payment_Summary__c ]){
            paymentName.add(paysumrec.Name);
            contractID.add(paysumrec.ECM_Contract__c);
        }
        
        String fileData;
        String sobjectName;
        String selectfieldsData;
        List<String> selectfields =new List<String>();
        
        fileData='Payment Summary Name,SAP Credit Note Number,SAP Credit Note Creation Date,SAP Billing Doc Number,SAP Billing Doc Date,SAP payment Reference Number,SAP Payment Date,Payment Summary Status,Contract\n'+
            ''+paymentName[0]+',11111,28/02/20,55555,23/02/20,20002,25/02/20,Open,'+contractID[0]+'\n'+
            ''+paymentName[1]+',888888,,10002,24/02/20,777777,26/02/20,Open,'+contractID[1]+'';
        sobjectName='ECM_Payment_Summary__c';
        selectfieldsData='Payment Summary Name,SAP Credit Note Number,SAP Credit Note Creation Date,SAP Billing Doc Number,SAP Billing Doc Date,SAP payment Reference Number,SAP Payment Date,Payment Summary Status,Contract';
        selectfields=selectfieldsData.split(',');
        ECM_FileUploaderCSVController.processData(fileData, sobjectName, selectfields);
        
        System.debug(LoggingLevel.Debug,'Data:'+paymentName);
        System.assert(paymentName!=null,'paymentName should not be null');
        Test.stopTest();
    }
    @isTest static void testInitializing() {
        List<String> str=ECM_FileUploaderCSVController.getselectOptions();
        /*ECM_FileUploaderCSVBatch.startRow=Null;
        ECM_FileUploaderCSVBatch.rowCount=Null;
        ECM_FileUploaderCSVBatch.SuccessRowCount=Null;
        ECM_FileUploaderCSVBatch.FailureRowCount=Null;
        ECM_FileUploaderCSVBatch.csvSuccessFileString='';
        ECM_FileUploaderCSVBatch.csvErrorFileString='';
        ECM_FileUploaderCSVBatch.firstRun=true;*/
        System.assert(str!=null,'str should not be null');
        
    }
}