/**********************************************************************
Class Name: ECM_DeleteExistingFiles

Test Class Name: ECM_Legal_ContractsView_Controller_Test 
=======================================================================
Purpose: To delete the exsisting documents in the Addendum from Amend Addendum screen 
=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR            		DATE              DETAIL
1.0      Chandrakanth Suram  	 24/02/2021        	ECM- 3950 

***********************************************************************/
public without sharing class ECM_DeleteExistingFiles {
    
    @AuraEnabled  
    public static string deleteFile(String LinkEntiId){ 
        string result;
        List<ContentDocumentLink> conDocLst = new List<ContentDocumentLink>();
        List<String> conIdLst = new List<String>();
        conDocLst=[select ContentDocumentId FROM ContentDocumentLink where LinkedEntityId=:LinkEntiId];
        if(conDocLst.size()>0){
            for(ContentDocumentLink con : conDocLst){
                conIdLst.add(con.ContentDocumentId); 
            }
            if(conIdLst.size()>0){
                delete [SELECT Id,Title from ContentDocument WHERE Id IN: conIdLst];
                result = 'success';
            }
        }else{
            result = 'NoFile';
        }
        return result;
    } 
    
}