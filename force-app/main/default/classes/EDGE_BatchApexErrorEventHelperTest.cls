/**********************************************************************
Name: EDGE_BatchApexErrorEventHelperTest
=======================================================================
Purpose: This is to cover EDGE_BatchApexErrorEventHelper class
=======================================================================
History                                                            
-------                                                            
VERSION  AUTHOR            DATE              DETAIL
1.0      Shahbaz          02-Jan-2020      Initial Development
***********************************************************************/
@isTest
public class EDGE_BatchApexErrorEventHelperTest {
    
    @isTest
    public static void batchApexErrorEventHelperTest(){
        Test.startTest();
        List<BatchApexErrorEvent> listBatch = new List<BatchApexErrorEvent>();
        Map<Id,BatchApexErrorEvent> mapBatch = new Map<Id,BatchApexErrorEvent>();
        //Id countryID = EDGE_UtilityTestClass.setupCountry('AU'); 
        EDGE_UtilityTestClass.createOrgSettings();
        BatchApexErrorEvent apexError = new BatchApexErrorEvent();     
        apexError.AsyncApexJobId = '7073N000004Kq3IQAS';
        database.insertImmediate(apexError);
        listBatch.add(apexError);
   
        Market_Batch_Job__c markBatch = new Market_Batch_Job__c();
        markBatch.Name = 'Sample';
        markBatch.Status__c = 'Failed';
        markBatch.Current_Market_Order__c= 2;
        markBatch.Type__c = 'Territory Management';
        insert markBatch;
        system.assert(markBatch.Id != null,'markBatch should not be null');
        
        Country_Batch_Job_Log__c countBatchJobLog = new Country_Batch_Job_Log__c();
		countBatchJobLog.Batch_Job_Id__c = '7073N000004Kq3IQAS';
		countBatchJobLog.Batch_Scope__c= 'Normal';
        countBatchJobLog.Exception__c = 'List has no rows';
        countBatchJobLog.Exception_Block__c = 'Out';
        countBatchJobLog.Status__c = 'Failed';
        countBatchJobLog.Market_Batch_Job__c=markBatch.Id;
        insert countBatchJobLog;
        system.assert(countBatchJobLog.id != null,'countBatchJobLog should not be null');
        
        mapBatch.put(countBatchJobLog.Id, apexError);
        BatchApexErrorEventHandler obj= new BatchApexErrorEventHandler();
        obj.beforeInsert(listBatch);
        obj.beforeDelete(mapBatch);
        obj.afterDelete(mapBatch);
        obj.afterUndelete(mapBatch);
        Test.stopTest();
        
    }
}