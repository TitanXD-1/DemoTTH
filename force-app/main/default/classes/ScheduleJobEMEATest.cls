/**********************************************************************
Name: ScheduleJobEMEATest

=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR           DATE            DETAIL
1.0         Dipanjan Das     25/03/2019      Test Class for ScheduleJobEMEA
2.0         Preyanka Ghosh   23/06/2019      Test class for TerritoryManagementBatchJobScheduler,
                                             ActivityManagementBatchJobScheduler, MiscellaneousBatchJobScheduler
***********************************************************************/
@isTest
public class ScheduleJobEMEATest{
    
    @isTest
    public static void testScheduleJob() {
        Test.StartTest();    
        Batch_Job_Current_Region__c batchjob = EDGE_UtilityTestClass.getBatchJobCurrentRegion();
        insert batchjob;
        system.assert(batchjob.Id!=null);
        EDGE_UtilityTestClass.setupCountry('PT');
        ScheduleJobEMEA sh1 = new ScheduleJobEMEA();
        String sch = '0 0 23 * * ?';
        system.schedule('TestScheduleJobAPAC', sch, sh1);
        
        system.assertEquals(batchjob.Name, 'Current Region');
        Test.StopTest(); 
    }
    
    @isTest
    public static void testTerritoryManagement(){
        
        Test.startTest();
        Batch_Job_Current_Region__c batchjob = EDGE_UtilityTestClass.getBatchJobCurrentRegion();
        batchjob.Region__c ='APAC';
        insert batchjob;
        
        //EDGE_UtilityTestClass.setupCountry('AU');
        List<Territory_Member__c> trListMemList = new List<Territory_Member__c>();
        
        User u1  = EDGE_UtilityTestClass.runAsUser('SalesRep','Sales Representative');
        Insert u1;
        
        Territory__c territoryObj =  EDGE_UtilityTestClass.getTerritoryRec();
        territoryObj.Country__c = EDGE_UtilityTestClass.setupCountry('AU');
        insert territoryObj;
        
        Territory_Member__c trListMemObj1 = EDGE_UtilityTestClass.getPrimaryTerrMemberRec(u1.id,territoryObj.id );
        trListMemList.add(trListMemObj1);
        
        insert trListMemList;
        system.assert(trListMemList.size()>0);
        try{
            string territoryMgmt = 'TerritoryManagementBatchJob_Scheduler';
            TerritoryManagementBatchJobScheduler territoryManagementCls = new TerritoryManagementBatchJobScheduler ();
            String strTerritoryMgmt = Datetime.now().addSeconds(120).format('s m H d M ? yyyy');
            System.schedule('Batch Job - ' + territoryMgmt + ' ' + strTerritoryMgmt, strTerritoryMgmt, territoryManagementCls);
        } catch (Exception ex){
            System.debug('Exception:::'+ex.getCause()+ex.getLineNumber()+ex.getMessage());
        }
        Test.stopTest();        
        
    }
    
    @isTest
    public static void testActivityManagement(){
        
        Test.startTest();
        Batch_Job_Current_Region__c batchjob = EDGE_UtilityTestClass.getBatchJobCurrentRegion();
        batchjob.Region__c ='APAC';
        insert batchjob;
        
        Id geographyID = EDGE_UtilityTestClass.setupCountry('AU');
        Target_List__c targetLst =  EDGE_UtilityTestClass.getTargetList(geographyID);
        targetLst.recordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Dynamic_Target_List' LIMIT 1].Id;
        targetLst.Dynamic_Query__c = 'SELECT ID, Name, Status__c, Ref__c, Country__c, Country__r.Name FROM Account Order by Name limit 1';
       
        insert targetLst;
        
        system.debug('targetLstId++ ' + targetLst);
        
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        insert outlet;
        
        Target_List_Member__c  targetLstmem = EDGE_UtilityTestClass.getTargetMemList(outlet.Id, targetLst.Id);
        targetLstmem.Assignment_Status__c = 'Active';
        insert targetLstmem;
        system.assert(targetLstmem.Id!=null);
        
        try{
            //Schedule "Activity Management Batch"
            string activityMgmt = 'ActivityManagementBatchJob_Scheduler';
            ActivityManagementBatchJobScheduler activityManagementCls = new ActivityManagementBatchJobScheduler ();
            String strActivityMgmt = Datetime.now().addSeconds(60).format('s m H d M ? yyyy');
            System.schedule('Batch Job - ' + activityMgmt + ' ' + strActivityMgmt, strActivityMgmt, activityManagementCls);
        } catch (Exception ex){
            System.debug('Exception:::'+ex.getCause()+ex.getLineNumber()+ex.getMessage());
        }
        Test.stopTest();        
        
    }
    
    @isTest
    public static void testMiscellaneousManagement(){
        
        Test.startTest();
        Batch_Job_Current_Region__c batchjob = EDGE_UtilityTestClass.getBatchJobCurrentRegion();
        batchjob.Region__c ='APAC';
        insert batchjob;
        
        Id recordTypeIdContVersion = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName().get('Promotion').getRecordTypeId();
        
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        Promotion__c promoRec = EDGE_UtilityTestClass.getPromotionRecord(countryId );
        promoRec.Start_Date__c = System.today().addDays(-6);
        promoRec.Expiration_Date__c = System.today().addDays(-1);
        insert promoRec;
        System.assert(promoRec.Id != null);
        
        ContentVersion conVerRec = EDGE_UtilityTestClass.gerConVerRec('Test.pdf');
        conVerRec.RecordTypeId = RecordTypeIdContVersion;
        conVerRec.Content_Type__c = 'Promotional PDF';
        insert conVerRec;
        System.assert(conVerRec.Id != null);
        
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        System.assertEquals(documents.size(), 1);
        
        ContentDocumentLink conDocLnkRec = EDGE_UtilityTestClass.getConDocLink (promoRec.Id,documents[0].Id);
        insert conDocLnkRec;
        System.assert(conDocLnkRec.Id != null);
        
        try{
            //Schedule "Territory Management Batch"
            string miscellaneous = 'MiscellaneousBatchJob_Scheduler';
            MiscellaneousBatchJobScheduler miscellaneousCls = new MiscellaneousBatchJobScheduler ();
            String strMiscellaneous = Datetime.now().addSeconds(180).format('s m H d M ? yyyy');
            System.schedule('Batch Job - ' + miscellaneous + ' ' + strMiscellaneous, strMiscellaneous, miscellaneousCls);
        } catch (Exception ex){
            System.debug('Exception:::'+ex.getCause()+ex.getLineNumber()+ex.getMessage());
        }
        Test.stopTest();        
        
    }
}