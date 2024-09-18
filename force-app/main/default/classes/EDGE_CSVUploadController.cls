/**********************************************************************
Name : EDGE_CSVUploadController
=======================================================================
Purpose : Controller Class for EDGE_UploadCSVCmp Lightning Component
=======================================================================
History                                                            
------------------------------------------------------------------------                                                            
VERSION    AUTHOR            DATE              DETAIL
1.0      Saurav K Paul    21-02-2019        Initial Development
***********************************************************************/  
public with sharing class EDGE_CSVUploadController{
    
    @AuraEnabled
    public static void processData(String sObjectType, String base64Data, Boolean isCreate){
        //Creating String to Blob
        base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
        Blob fileObj = EncodingUtil.base64Decode(base64Data);
        
        //Executing Batch Class to process CSV file
        EDGE_CSVFileProcessBatch batchable = new EDGE_CSVFileProcessBatch(fileObj,sObjectType,isCreate);
        Database.executeBatch(batchable, Integer.valueOf(Label.CSV_Upload_Batch_Size));
    }
    @AuraEnabled
    public static Id getCSVTemp(String templateName){
        if(Schema.sObjectType.Document.isAccessible()){
            Document csvDoc = [SELECT ContentType,Description,Id,Name FROM Document WHERE Name =:templateName LIMIT 1];
        	return csvDoc.Id;
        }
        return null;
    }
}