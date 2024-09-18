/**
* @Name: Edge_ExportToCaseTaskPdfController 
* @ES20-11095 - Download PDF from CaseTask
* @History                                                            
* 	@VERSION     AUTHOR              DATE              DETAIL
*	1.0 -    Debolina   			12/07/2021     	ES20-11095 (Download PDF from CaseTask)
*	2.0 -    Swaraj Samanta   		18/02/2022     	ES20-11832 (Addition of Case Task Number in PDF Name)

*/
public  with sharing class Edge_ExportToCaseTaskPdfController {
    @AuraEnabled 
    public static String getPdfFile(Id caseTaskId) {
        Blob blobData;
        PageReference pdfpage = Page.Edge_SendCaseTaskPDFVisualPage;
        pdfpage.getParameters().put('taskId',caseTaskId);
        
        pdfpage.setRedirect(true);
        
        if(!Test.isRunningTest()){
            blobData = pdfpage.getContent();
        }
        else{
            blobData=blob.valueOf('Test');  
        }
        String base64Pdf = EncodingUtil.base64Encode(blobData);
        return base64Pdf;
    }  
    
    @AuraEnabled
    public static String getCaseTaskNumber(String caseTaskId){
        Case_Task__c caseTaskInfo = new Case_Task__c();
        String caseTaskNumber = '';
        try{
        	if(Schema.sObjectType.Case_Task__c.isAccessible()){
            	caseTaskInfo = [SELECT Name FROM Case_Task__c WHERE Id = :caseTaskId];
        	}
        }
        catch(Exception ex){
            system.debug('Exception Message =====>: ' + ex.getMessage());
        }
        if(caseTaskInfo != null && caseTaskInfo.Name !=null){
        	 caseTaskNumber = caseTaskInfo.Name;
        }
        return caseTaskNumber;
    }
}