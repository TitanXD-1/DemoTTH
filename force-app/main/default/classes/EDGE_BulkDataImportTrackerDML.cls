/**********************************************************************
  Name : EDGE_BulkDataImportTrackerDML
=======================================================================
  Purpose : Helper Class is used to Create Bulk Job Result
=======================================================================
    History                                                            
------------------------------------------------------------------------                                                            
    VERSION    AUTHOR            DATE              DETAIL
     1.0      Saurav K Paul    21-02-2019        Initial Development
***********************************************************************/

public with sharing class EDGE_BulkDataImportTrackerDML {
	//Method Name : generateBulkDataImportLog
	//Description : Used to create Bulk_Data_Import_Tracker Record
    public static Bulk_Data_Import_Tracker__c generateBulkDataImportLog (string oName, string msg, Id rUser, Integer tRecords, 
    																	 Integer sRecords, Integer fRecords, String bId){
        Bulk_Data_Import_Tracker__c bLog = new Bulk_Data_Import_Tracker__c();
        bLog.Object_Name__c = oName;
        bLog.Message__c = msg;
        bLog.User__c = rUser;
        bLog.Total_Records__c = tRecords;
        bLog.Success_Records__c = sRecords;
        bLog.Failure_Records__c = fRecords;
        bLog.Batch_Id__c = bId;
    
        return bLog;
    }
}