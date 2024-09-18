@isTest
/*****************************************************************************************
* Class Name   : PNR_CustomerStructureTest
* Purpose      : Test Class for PNR_CustomerStructure
* Created Date : 18th June, 2019
* Created By   : Tanmoy Bardhan
******************************************************************************************/
public class PNR_CustomerStructureTest {

	static testMethod void testfetchSoldToStructurePayer() {
        Account acct = PNR_TestDataUtility.getDirectCustomerRec();
        Insert acct;
        
        PNR_Partner_Function__c pFRec = PNR_TestDataUtility.getPNRPartnerFunctionData();
        pFRec.PNR_Sold_To__c = acct.Id;
        Insert pFRec;
        
        Test.startTest();
        List<PNR_CustomerStructureWrapper> pflist = PNR_CustomerStructure.fetchSoldToStructure(acct.Id , 'SE01');
        PNR_Partner_Function__c pf= [SELECT Id,PNR_Type__c FROM PNR_Partner_Function__c where Id=:pflist[0].pFRecord.Id];
        system.assertEquals(pf.PNR_Type__c, 'Payer');
        Test.stopTest();
	}
	
	static testMethod void testfetchSoldToStructureSoldTo() {
        Account acct = PNR_TestDataUtility.getDirectCustomerRec();
        Insert acct;
        
        PNR_Partner_Function__c pFRec = PNR_TestDataUtility.getPNRPartnerFunctionData();
        pFRec.PNR_Sold_To__c = acct.Id;
        pFRec.PNR_Type__c='Sold-To';
        Insert pFRec;
        
        Test.startTest();
        List<PNR_CustomerStructureWrapper> pflist = PNR_CustomerStructure.fetchSoldToStructure(acct.Id , 'SE01');
        PNR_Partner_Function__c pf= [SELECT Id,PNR_Type__c FROM PNR_Partner_Function__c where Id=:pflist[0].pFRecord.Id];
        system.assertEquals(pf.PNR_Type__c, 'Sold-To');
        Test.stopTest();
	}
	
	static testMethod void testfetchSoldToStructureBillTo() {
        Account acct = PNR_TestDataUtility.getDirectCustomerRec();
        Insert acct;
        
        PNR_Partner_Function__c pFRec = PNR_TestDataUtility.getPNRPartnerFunctionData();
        pFRec.PNR_Sold_To__c = acct.Id;
        pFRec.PNR_Type__c='Bill-To';
        Insert pFRec;
        
        Test.startTest();
        List<PNR_CustomerStructureWrapper> pflist = PNR_CustomerStructure.fetchSoldToStructure(acct.Id , 'SE01');
        PNR_Partner_Function__c pf= [SELECT Id,PNR_Type__c FROM PNR_Partner_Function__c where Id=:pflist[0].pFRecord.Id];
        system.assertEquals(pf.PNR_Type__c, 'Bill-To');
        Test.stopTest();
	}
	
	static testMethod void testfetchSoldToStructureShipTo() {
        Account acct = PNR_TestDataUtility.getDirectCustomerRec();
        Insert acct;
        
        PNR_Partner_Function__c pFRec = PNR_TestDataUtility.getPNRPartnerFunctionData();
        pFRec.PNR_Sold_To__c = acct.Id;
        pFRec.PNR_Type__c='Ship-To';
        Insert pFRec;
        
        Test.startTest();
        List<PNR_CustomerStructureWrapper> pflist = PNR_CustomerStructure.fetchSoldToStructure(acct.Id , 'SE01');
        PNR_Partner_Function__c pf= [SELECT Id,PNR_Type__c FROM PNR_Partner_Function__c where Id=:pflist[0].pFRecord.Id];
        system.assertEquals(pf.PNR_Type__c, 'Ship-To');
        Test.stopTest();
	}
	
	static testMethod void testfetchPayerStructureSoldTo() {
        Account acct = PNR_TestDataUtility.getDirectCustomerRec();
        Insert acct;
        
        PNR_Partner_Function__c pFRec = PNR_TestDataUtility.getPNRPartnerFunctionData();
        pFRec.PNR_Customer_No__c = acct.Id;
        pFRec.PNR_Sold_To__c = acct.Id;
        pFRec.PNR_Type__c='Sold-To';
        Insert pFRec;
        
        Test.startTest();
        List<PNR_CustomerStructureWrapper> pflist = PNR_CustomerStructure.fetchPayerStructure(acct.Id , 'SE01');
        PNR_Partner_Function__c pf= [SELECT Id,PNR_Type__c FROM PNR_Partner_Function__c where Id=:pflist[0].pFRecord.Id];
        system.assertEquals(pf.PNR_Type__c, 'Sold-To');
        Test.stopTest();
	}
	
	static testMethod void testfetchPayerStructurePayer() {
        Account acct = PNR_TestDataUtility.getDirectCustomerRec();
        Insert acct;
        
        PNR_Partner_Function__c pFRec = PNR_TestDataUtility.getPNRPartnerFunctionData();
        pFRec.PNR_Customer_No__c = acct.Id;
        pFRec.PNR_Sold_To__c = acct.Id;
        pFRec.PNR_Type__c='Payer';
        Insert pFRec;
        
        Test.startTest();
        List<PNR_CustomerStructureWrapper> pflist = PNR_CustomerStructure.fetchPayerStructure(acct.Id , 'SE01');
        PNR_Partner_Function__c pf= [SELECT Id,PNR_Type__c FROM PNR_Partner_Function__c where Id=:pflist[0].pFRecord.Id];
        system.assertEquals(pf.PNR_Type__c, 'Payer');
        Test.stopTest();
	}
	
	static testMethod void testfetchPayerStructureBillTo() {
        Account acct = PNR_TestDataUtility.getDirectCustomerRec();
        Insert acct;
        
        PNR_Partner_Function__c pFRec = PNR_TestDataUtility.getPNRPartnerFunctionData();
        pFRec.PNR_Customer_No__c = acct.Id;
        pFRec.PNR_Sold_To__c = acct.Id;
        pFRec.PNR_Type__c='Bill-To';
        Insert pFRec;
        
        Test.startTest();
        List<PNR_CustomerStructureWrapper> pflist = PNR_CustomerStructure.fetchPayerStructure(acct.Id , 'SE01');
        PNR_Partner_Function__c pf= [SELECT Id,PNR_Type__c FROM PNR_Partner_Function__c where Id=:pflist[0].pFRecord.Id];
        system.assertEquals(pf.PNR_Type__c, 'Bill-To');
        Test.stopTest();
	}

}