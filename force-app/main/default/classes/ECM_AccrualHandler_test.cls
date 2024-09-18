/**
  Name: ECM_AccrualHandler_test
  Purpose: Test Class for ECM_AccrualHandler
    History                                                            
    VERSION  AUTHOR            DATE              DETAIL
    1.0 -    Manikandan.T    15/02/2021      Initial Development
**/
@istest
public class ECM_AccrualHandler_test {
    @isTest
    Public static void testmethod1(){
        
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        String regionrecordtypeId = Territory_Hierarchy__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Region').getRecordTypeId();
        //String PickupRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        //String Type='Local-Segment1';
        Id geographyId = EDGE_UtilityTestClass.setupCountry('ES');
        user newuser = EDGE_UtilityTestClass.runAsUser('Testabc','System Administrator');
        insert newuser;
        
               User salesManager = EDGE_UtilityTestClass.runAsUser('salesRep1','Sales Manager');
            salesManager.Available_Countries__c = 'AU';
          //  salesManager.ManagerId = testAdminUser.id;
            insert salesManager; 
        
        Territory__c  territory = EDGE_UtilityTestClass.getTerritoryRec();
        insert territory;
        
        Territory_Hierarchy__c territoryhierarchy= new Territory_Hierarchy__c();
        territoryhierarchy.Geography__c=geographyId;
        territoryhierarchy.recordtypeId=regionrecordtypeId;
        insert territoryhierarchy;
        
        territory.region__c=territoryhierarchy.id;
        update territory;
        
        Territory_Hierarchy_Member__c thmember= new Territory_Hierarchy_Member__c();
        thmember.Territory_Hierarchy__c=territoryhierarchy.id;
        thmember.Start_Date__c=system.today().adddays(-1);
        thmember.End_Date__c=system.today().adddays(10);
        thmember.user__c=salesManager.id;
        insert thmember;
        
        ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
        contractType.Name='Promotional';
        contractType.Geography__c=geographyId;
        contractType.ECM_Abbreviation__c='POM';
        contractType.ECM_Automatic_approval_amount_threshold__c = 40.00;
        contractType.currencyIsocode='AUD';
        contractType.ECM_Screen_3_field_configuration__c = 'Investment';
        insert contractType;
		
		ECM_Payment_Frequency__c paymentFrequency=new ECM_Payment_Frequency__c();
		paymentFrequency.ECM_Geography__c=geographyId;
		paymentFrequency.ECM_Type__c='Equal Instalments';
		paymentFrequency.ECM_Other_Investment__c=true;
		insert paymentFrequency;
		
		ECM_Payment_Agreement__c paymentAgreement= new ECM_Payment_Agreement__c();
		paymentAgreement.ECM_Agreement_Type__c=contractType.Id;
		paymentAgreement.ECM_Payment_Frequency__c=paymentFrequency.id;
		
		insert paymentAgreement;
		

        
        User cIOuser = EDGE_UtilityTestClass.runAsUser('salesRep1','CIO User');
            cIOuser.Available_Countries__c = 'AU';
          //  salesManager.ManagerId = testAdminUser.id;
            insert CIOuser; 
        
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        insert acc;
        Date myDate = Date.newInstance(system.today().year()+1, 5, 17);
        Date myStartDate = Date.newInstance(system.today().year(), 5, 17);
        Contract con = new Contract(Name = 'Test',StartDate=myStartDate,UOS_Rebate_Rate__c=88, UOS_Target__c=99,AccountId =Acc.id,Contract_End_Date__c=myDate,ECM_Agreement_Type__c=contractType.id,ECM_Duration__c=2,ECM_Overall_Investment_Amount__c=40.00,ECM_Territory__c=territory.id,UOS_Earnt__c=3.00,UOS_AP_Rate__c=2.00,AP_Spent__c=2.00,Opening_AP_Balance__c=5.00,ECM_Channel__c='Hybrid',Venue_Type__c ='Premium[AU]',RecordTypeId = contractRecordTypeId,ECM_Selected_Payment_Schedule_AU__c=paymentFrequency.Id);
        insert con;
        
        ECM_Accrual__c newAccrual= new ECM_Accrual__c();
        newAccrual.ecm_contract__c=con.id;
        insert newAccrual;
        newAccrual=[select id,CurrencyIsoCode,ECM_Sales_Manager__c from ECM_Accrual__c where id=:newAccrual.id limit 1];
        system.assertEquals(newAccrual.ECM_Sales_Manager__c, salesManager.id,'null');
		system.assertEquals(newAccrual.CurrencyIsoCode,contractType.currencyIsocode,'null');
    }
}