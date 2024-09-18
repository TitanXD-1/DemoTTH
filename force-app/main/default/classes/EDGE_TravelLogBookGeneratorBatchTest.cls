/**********************************************************************
Name: EDGE_TravelLogBookGeneratorBatchTest
=======================================================================
Req: Test class of EDGE_TravelLogBookGeneratorBatch
=======================================================================
History                                                            
-------                                                            
VERSION    AUTHOR             DATE      DETAIL
1.0                  
***********************************************************************/
@istest
public class EDGE_TravelLogBookGeneratorBatchTest {
     @isTest
    public static void travelLogBookGeneratorBatchTest(){
        Test.startTest(); 
        
        createData();
        
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,Frequency__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_TravelLogBookGeneratorBatch'
                                                  and Country_Code__c ='AU' LIMIT 1];
        system.assert(batchSetting.Id != null);
        String className = batchSetting.Batch_Class__c;
        Type t = Type.forName(className);
        
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
        Test.stopTest();
        
    }
    public static void createData(){
        

        Id countryId= EDGE_UtilityTestClass.setupCountry('AU');
        User salesManager = EDGE_UtilityTestClass.runAsUser('salesRep1','System Administrator');
        salesManager.Available_Countries__c = 'AU';
        insert salesManager;  
        System.assert(salesManager.Id!=null);
        
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
        salesRep.Available_Countries__c = 'AU';
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
        
        EDGE_UtilityTestClass.createOrgSettings();
        
        Personal_Information__c persInfo = new Personal_Information__c();
        persInfo.User__c = salesRep.Id;
        persInfo.Car_Approval_Status__c = 'Pending';
        persInfo.Car_Model__c = 'Hyundai';
        persInfo.Registration_Number__c = 'Hyun2020';
        insert persInfo;
        system.assert(persInfo.Id != null);
        
        
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
        List<Personal_Information__c> personalInfoList = new List<Personal_Information__c>();
        personalInfoList.add(persInfo);
        
    }

}