/**********************************************************************
  Name: EDGE_PersonalInformationTriggeTest
=======================================================================
  Purpose: This class is to Test EDGE_PersonalInformationTriggerHelper
=======================================================================
    History                                                            
    -------                                                            
 VERSION  	  AUTHOR            DATE              DETAIL
  1.0                          15/02/2020     Initial Development
***********************************************************************/
@isTest
public class EDGE_PersonalInformationTriggerTest {
    @isTest
    public static void testPopulateUserCountry(){
        EDGE_UtilityTestClass.createOrgSettings();
        Personal_Information__c persInfo = new Personal_Information__c();
        persInfo.Registration_Number__c = '262';
        insert persInfo;
        system.assert(persInfo.Id != null);
        persInfo.Car_Model__c = 'BMW';
        update persInfo;
        delete persInfo;
        undelete persInfo;
    }
    @isTest
    public static void populateUserCountryTest(){
        Id countryId= EDGE_UtilityTestClass.setupCountry('AUT');
        EDGE_UtilityTestClass.createOrgSettings();
        
        User salesManager = EDGE_UtilityTestClass.runAsUser('salesRep1','System Administrator');
        salesManager.Available_Countries__c = 'AUT';
        insert salesManager;  
        System.assert(salesManager.Id!=null);
        
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
        salesRep.Available_Countries__c = 'AUT';
        salesRep.ManagerId = salesManager.id;
        insert salesRep; 
        System.assert(salesRep.Id!=null);
        
        Market_Setting__c mktSetting = EDGE_UtilityTestClass.getMarketSetting(countryId);
        mktSetting.Car_Change_Approval__c = 'No Approval Required';
        mktSetting.Display_in_Kilometer__c = True;
        mktSetting.Fleet_Manager__c = 'test@2121.com';
        mktSetting.Threshold_Format__c = 'Percent';
        mktSetting.Last_Travel_Log_Date__c = system.today();
        insert mktSetting;
        
        Personal_Information__c persInfo = new Personal_Information__c();
        persInfo.User__c = salesRep.Id;
        persInfo.Car_Approval_Status__c = 'Pending';
        persInfo.Car_Model__c = 'Hyundai';
        persInfo.Registration_Number__c = 'Hyun2020';
        insert persInfo;
        
        
        Travel_Log__c travelLog = new Travel_log__c();
        travelLog.Start_Date__c = system.today();
        travelLog.End_Date__c = system.today().addDays(10);
        travelLog.Personal_Information__c = persInfo.id;
        travelLog.Odometer_End_Reading__c = 4878;
        travelLog.Odometer_Start_Reading__c = 7858;
        travelLog.Reported__c = false;
        insert travelLog;
        
        persInfo.New_Car_Model__c = 'Hyundai IR';
        persInfo.New_Registration_Number__c ='HyunIR2020';
        update persInfo;
        
        
    }

}