public class ECM_BulkDataImportTrackerDML {
	public Bulk_Data_Import_Tracker__c generateBulkDataImportLog(string oName, string msg, Id ruser, Integer tRecords, Integer sRecords, Integer fRecords, String bId){
        Bulk_Data_Import_Tracker__c bLog = new Bulk_Data_Import_Tracker__c();
            bLog.Object_Name__c = oName;
            bLog.Message__c = msg;
            bLog.User__c = ruser;
            bLog.Total_Records__c = tRecords;
            bLog.Success_Records__c = sRecords;
            bLog.Failure_Records__c = fRecords;
            bLog.Batch_Id__c = bId;
        
        return bLog;
    }
}