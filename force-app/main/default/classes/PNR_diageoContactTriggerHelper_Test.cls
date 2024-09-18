/**********************************************************************
  Name: PNR_diageoContactTriggerHelper_Test
=======================================================================
  Purpose: This is the test class for PNR_diageoContactTriggerHelper
=======================================================================
    History                                                            
    -------                                                            
    VERSION  AUTHOR             DATE              DETAIL
    1.0 -    Tanmoy Bardhan     05/07/2019      Initial Development
***********************************************************************/
@isTest
public class PNR_diageoContactTriggerHelper_Test  {

    static testMethod void testRep() {
        /*EDGE_UtilityTestClass.createOrgSettings();
        Account acct = PNR_TestDataUtility.getDirectCustomerRec();
        Insert acct;*/
        PNR_DiageoContactTriggerHandler dcHandler = new PNR_DiageoContactTriggerHandler(); 
        Id geographyId = EDGE_UtilityTestClass.setupCountry('GB');
        EDGE_UtilityTestClass.createOrgSettings();
        Account acct  = PNR_TestDataUtility.getDirectCustomerRec();
        acct.Country_ISO_Code__c = 'GB';
        insert acct;
        
        User usr = PNR_TestDataUtility.runAsUser('tanmB', 'System Administrator');
        Insert usr;
        List < PNR_Diageo_Contact__c > repDiageoConList = new List < PNR_Diageo_Contact__c > ();
        Map<Id,PNR_Diageo_Contact__c> repDiageoMap = new Map<Id,PNR_Diageo_Contact__c>();
        
        PNR_Diageo_Contact__c diaCon = new PNR_Diageo_Contact__c();
        diaCon.PNR_Customer__c = acct.Id;
        diaCon.PNR_Contact_Type__c = 'Customer Service Rep';
        diaCon.PNR_Diageo_Rep__c = usr.Id;
        Insert diaCon;
        //repDiageoConList.add(diaCon);
        PNR_Diageo_Contact__c diaCon1 = new PNR_Diageo_Contact__c();
        diaCon1.PNR_Customer__c = acct.Id;
        diaCon1.PNR_Contact_Type__c = 'Customer Service Rep';
        diaCon1.PNR_Diageo_Rep__c = usr.Id;
        Insert diaCon1;
        
        PNR_Diageo_Contact__c diaConUpd = new PNR_Diageo_Contact__c();
        diaConUpd.PNR_Customer__c = acct.Id;
        diaConUpd.PNR_Contact_Type__c = 'Credit Controller';
        diaConUpd.PNR_Diageo_Rep__c = usr.Id;
        diaConUpd.Id = diaCon1.Id;
        Update diaConUpd;
        
        PNR_Diageo_Contact__c diaConUpd3 = new PNR_Diageo_Contact__c();
        diaConUpd3.PNR_Customer__c = acct.Id;
        diaConUpd3.PNR_Contact_Type__c = 'Credit Controller';
        diaConUpd3.PNR_Diageo_Rep__c = usr.Id;
        diaConUpd3.Id = diaCon1.Id;
        Update diaConUpd3;
        
        PNR_Diageo_Contact__c diaConUpd2 = new PNR_Diageo_Contact__c();
        diaConUpd2.PNR_Email__c = 'john.test@gmail.com';
        diaConUpd2.Id = diaCon1.Id;
        Update diaConUpd2;
        
        dcHandler.beforeDelete(null);
        dcHandler.afterDelete(null);
        dcHandler.afterUndelete(null);
        dcHandler.afterUpdate(null, null);
        dcHandler.afterInsert(null);
        
        List<PNR_Diageo_Contact__c> custrep=[Select id,PNR_Diageo_Rep__c from PNR_Diageo_Contact__c where Id=:diaCon1.Id];
        Integer custrepsize=custrep.size();
        System.assertNotEquals(custrepsize, 0);
       
    }
    
    static testMethod void testName() {
        Id geographyId = EDGE_UtilityTestClass.setupCountry('GB');
        PNR_DiageoContactTriggerHandler dcHandler = new PNR_DiageoContactTriggerHandler(); 
        
        EDGE_UtilityTestClass.createOrgSettings();
        Account acct  = PNR_TestDataUtility.getDirectCustomerRec();
        acct.Country_ISO_Code__c = 'GB';
        insert acct;
        
        
        PNR_Diageo_Contact__c diaConNameIns = new PNR_Diageo_Contact__c();
        diaConNameIns.PNR_Name__c = 'Tanmoy';
        diaConNameIns.PNR_Contact_Type__c = 'Account Manager';
        diaConNameIns.PNR_Customer__c = acct.Id;
        Insert diaConNameIns;
        
        PNR_Diageo_Contact__c diaConNameIns1 = new PNR_Diageo_Contact__c();
        diaConNameIns1.PNR_Name__c = 'Tanmoy';
        diaConNameIns1.PNR_Customer__c = acct.Id;
        diaConNameIns1.PNR_Contact_Type__c = 'Account Manager';
        Insert diaConNameIns1;
        
        PNR_Diageo_Contact__c diaConNameUpd = new PNR_Diageo_Contact__c();
        diaConNameUpd.PNR_Name__c = 'Tanmoy';
        diaConNameUpd.PNR_Contact_Type__c = 'Account Manager';
        diaConNameUpd.PNR_Customer__c = acct.Id;
        diaConNameUpd.Id = diaConNameIns1.Id;
        Update diaConNameUpd;
        
        PNR_Diageo_Contact__c diaConNameUpd2 = new PNR_Diageo_Contact__c();
        diaConNameUpd2.PNR_Name__c = 'Tanmoy';
        diaConNameUpd2.PNR_Contact_Type__c = 'Other';
        diaConNameUpd2.PNR_Customer__c = acct.Id;
        diaConNameUpd2.Id = diaConNameIns1.Id;
        Update diaConNameUpd2;
        
        PNR_Diageo_Contact__c diaConNameUpd3 = new PNR_Diageo_Contact__c();
        diaConNameUpd3.PNR_Email__c = 'john3.test@gmail.com';
        diaConNameUpd3.Id = diaConNameIns1.Id;
        Update diaConNameUpd3;
        
        dcHandler.beforeDelete(null);
        dcHandler.afterDelete(null);
        dcHandler.afterUndelete(null);
        dcHandler.afterUpdate(null, null);
        dcHandler.afterInsert(null);
        
        List<PNR_Diageo_Contact__c> custrep=[Select id,PNR_Name__c from PNR_Diageo_Contact__c where Id=:diaConNameIns1.Id];
        Integer custrepsize=custrep.size();
        System.assertNotEquals(custrepsize, 0);
        
    }

}