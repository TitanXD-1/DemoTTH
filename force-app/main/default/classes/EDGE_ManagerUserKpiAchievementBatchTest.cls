/**
* @Name: EDGE_ManagerUserKpiAchievementBatchTest

* @Req: 
* 

* @History                                                            

* @VERSION     AUTHOR              DATE            DETAIL
*  1.0         Prasanth T                          ES20-10840
*  2.0		   Rajarshi Lahiri	   08/06/2022	   ES20-12745
**/

@isTest
public class EDGE_ManagerUserKpiAchievementBatchTest {
    public static Map<String,Id> geoMap = new Map<String,Id>();
    @isTest
    public static void test(){        
        //create Admin User
        Test.startTest();
        User testSysAdminUser = EDGE_UtilityTestClass.runAsUser('SystemAdmin','System Administrator');
        testSysAdminUser.Available_Countries__c = 'GB';
        insert testSysAdminUser;
        
        //System.runAs(testSysAdminUser){
        //create all the necessary data
        
        createData();            
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_ManagerUserKpiAchievementBatch'
                                                  AND Country_Code__c='GB' LIMIT 1];
        system.assert(batchSetting.Id != null);
        String className = batchSetting.Batch_Class__c;
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));    
        
        Test.stopTest();   
        
        
        //}  
    }
    @isTest
    public static void createData(){
        
        String userKpiRecTypeID =  KPI_Achivement__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('User KPI').getRecordTypeId();
        Id countryId = EDGE_UtilityTestClass.setupCountryGB('GB');
        List<user> repUsersList=new List<user>();
        List<user> mgrUsersList=new List<user>();
        User testQualityMgr = EDGE_UtilityTestClass.runAsUser('QualityMgr','Quality Manager');
        testQualityMgr.Available_Countries__c = 'GB';
        mgrUsersList.add(testQualityMgr);  
        
        User testSalesMgr = EDGE_UtilityTestClass.runAsUser('SalesMgr','Sales Manager');
        testSalesMgr.Available_Countries__c = 'GB';
        mgrUsersList.add(testSalesMgr); 
        
        insert mgrUsersList;
        User testQualityRepUser = EDGE_UtilityTestClass.runAsUser('Qualityrep','Quality Representative');
        testQualityRepUser.Available_Countries__c = 'GB';
        testQualityRepUser.ManagerId  =testQualityMgr.Id;
        repUsersList.add(testQualityRepUser);

        
        User testSalesRepUser = EDGE_UtilityTestClass.runAsUser('Salesrep','Sales Representative');
        testSalesRepUser.Available_Countries__c = 'GB';
        testSalesRepUser.ManagerId  =testSalesMgr.Id;
        repUsersList.add(testSalesRepUser);        
        
        insert repUsersList;
        
        System.assert(testQualityRepUser.ManagerId!=null);
        List<KPI_Achivement__c> kpiAchiveList = new List<KPI_Achivement__c>();
        
        
        KPI_Achivement__c kpiAchive = new KPI_Achivement__c();
        kpiAchive.KPI_Type__c = 'Number of Visits';
        kpiAchive.user__c =testQualityRepUser.Id;
        kpiAchive.Country__c=countryId;
        kpiAchive.RecordTypeId=userKpiRecTypeID;
        kpiAchive.Actual_Numerator__c=10;
        kpiAchive.Total_Denominator__c=10;
        kpiAchive.Achievement__c = 10;// * i - .5;
        kpiAchiveList.add(kpiAchive);           
        
        KPI_Achivement__c kpiAchive1 = new KPI_Achivement__c();
        kpiAchive1.KPI_Type__c = 'Case Task vs Total';
        kpiAchive1.Country__c=countryId;
        kpiAchive1.user__c =testQualityRepUser.Id;
        kpiAchive1.RecordTypeId=userKpiRecTypeID;
        kpiAchive1.Actual_Numerator__c=10;
        kpiAchive1.Total_Denominator__c=10;
        kpiAchive1.Achievement__c = 10 ;
        kpiAchiveList.add(kpiAchive1);          
        
        KPI_Achivement__c kpiAchive2 = new KPI_Achivement__c();
        kpiAchive2.KPI_Type__c = 'Case Task vs SLA';
        kpiAchive2.Country__c=countryId;
        kpiAchive2.user__c =testQualityRepUser.Id;
        kpiAchive2.RecordTypeId=userKpiRecTypeID;
        kpiAchive2.Actual_Numerator__c=10;
        kpiAchive2.Total_Denominator__c=10;
        kpiAchive2.Achievement__c = 10 ;
        kpiAchiveList.add(kpiAchive2);  
        
        KPI_Achivement__c kpiAchive3 = new KPI_Achivement__c();
        kpiAchive3.KPI_Type__c = 'Unique Outlets';
        kpiAchive3.Country__c=countryId;
        kpiAchive3.user__c =testQualityRepUser.Id;
        kpiAchive3.RecordTypeId=userKpiRecTypeID;
        kpiAchive3.Actual_Numerator__c=10;
        kpiAchive3.Total_Denominator__c=10;
        kpiAchive3.Achievement__c = 20 ;
        kpiAchiveList.add(kpiAchive3); 
        
        KPI_Achivement__c kpiAchive4 = new KPI_Achivement__c();
        kpiAchive4.KPI_Type__c = 'Number of Visits';
        kpiAchive4.Country__c=countryId;
        kpiAchive4.user__c =testQualityMgr.Id;
        kpiAchive4.RecordTypeId=userKpiRecTypeID;
        kpiAchive4.Achievement__c = 20 ;
        kpiAchiveList.add(kpiAchive4); 
        
        KPI_Achivement__c kpiAchive5 = new KPI_Achivement__c();
        kpiAchive5.KPI_Type__c = 'Case Task vs Total';
        kpiAchive5.Country__c=countryId;
        kpiAchive5.user__c =testQualityMgr.Id;
        kpiAchive5.RecordTypeId=userKpiRecTypeID;
        kpiAchive5.Achievement__c = 20 ;
        kpiAchiveList.add(kpiAchive5);
        
        KPI_Achivement__c kpiAchive6 = new KPI_Achivement__c();
        kpiAchive6.KPI_Type__c = 'Case Task vs SLA';
        kpiAchive6.Country__c=countryId;
        kpiAchive6.user__c =testQualityMgr.Id;
        kpiAchive6.RecordTypeId=userKpiRecTypeID;
        kpiAchive6.Achievement__c = 20 ;
        kpiAchiveList.add(kpiAchive6);
        
        KPI_Achivement__c kpiAchive7 = new KPI_Achivement__c();
        kpiAchive7.KPI_Type__c = 'Unique Outlets';
        kpiAchive7.Country__c=countryId;
        kpiAchive7.user__c =testQualityMgr.Id;
        kpiAchive7.RecordTypeId=userKpiRecTypeID;
        kpiAchive7.Achievement__c = 20 ;
        kpiAchiveList.add(kpiAchive7);
        
        
        KPI_Achivement__c kpiAchive8 = new KPI_Achivement__c();
        kpiAchive8.KPI_Type__c = 'Plan Call Compliance';
        kpiAchive8.user__c =testSalesRepUser.Id;
        kpiAchive8.Country__c=countryId;
        kpiAchive8.RecordTypeId=userKpiRecTypeID;
        kpiAchive8.Actual_Numerator__c=10;
        kpiAchive8.Total_Denominator__c=10;
        kpiAchive8.Achievement__c = 100;// * i - .5;
        kpiAchiveList.add(kpiAchive8);           
        
        KPI_Achivement__c kpiAchive9 = new KPI_Achivement__c();
        kpiAchive9.KPI_Type__c = 'Virtual Call Compliance';
        kpiAchive9.Country__c=countryId;
        kpiAchive9.user__c =testSalesRepUser.Id;
        kpiAchive9.RecordTypeId=userKpiRecTypeID;
        kpiAchive9.Actual_Numerator__c=10;
        //kpiAchive9.Total_Denominator__c=10;
        kpiAchive9.Achievement__c = 10 ;
        kpiAchiveList.add(kpiAchive9);
        
        KPI_Achivement__c kpiAchive10 = new KPI_Achivement__c();
        kpiAchive10.KPI_Type__c = 'Plan Call Compliance';
        kpiAchive10.Country__c=countryId;
        kpiAchive10.user__c =testSalesMgr.Id;
        kpiAchive10.Actual_Numerator__c=2;
        kpiAchive10.Total_Denominator__c=4;
        kpiAchive10.Manager_Count_Reset__c=true;
        kpiAchive10.RecordTypeId=userKpiRecTypeID;
        kpiAchive10.Achievement__c = 50 ;
        insert kpiAchive10;
        /*
        KPI_Achivement__c kpiAchive11 = new KPI_Achivement__c();
        kpiAchive11.KPI_Type__c = 'Virtual Call Compliance';
        kpiAchive11.Country__c=countryId;
        kpiAchive11.user__c =testSalesMgr.Id;
        kpiAchive11.Actual_Numerator__c=10;
        kpiAchive11.Total_Denominator__c=1;
        kpiAchive11.Manager_Count_Reset__c=false;
        kpiAchive11.RecordTypeId=userKpiRecTypeID;
        kpiAchive11.Achievement__c = 20 ;
        kpiAchiveList.add(kpiAchive11);
        */
        insert kpiAchiveList;
    }
    
}