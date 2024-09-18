public without sharing class ECM_FileDeletionController {

    
      @AuraEnabled
    public static String deleteFilePermission(String contentDocumentId){
 
            String parentId;
        	List<Id>contractList= new List<Id>();
            for(contentdocumentLink cDoc:[select id,contentdocumentId,linkedentityId from contentdocumentLink where (contentdocumentId=:contentDocumentId)]){
                If(String.ValueOf(cDoc.linkedentityId).startsWith(schema.SObjectType.ECM_Payment_Summary__c.getKeyPrefix()) || String.ValueOf(cDoc.linkedentityId).startsWith(schema.SObjectType.contract.getKeyPrefix()) || String.ValueOf(cDoc.linkedentityId).startsWith(schema.SObjectType.Market_Setting__c.getKeyPrefix())){
                    if(String.ValueOf(cDoc.linkedentityId).startsWith(schema.SObjectType.contract.getKeyPrefix())){
                        contractList.add(cDoc.linkedentityId);
                    }else{
                    	parentId=cDoc.linkedentityId;
                    }
                }
                
            }
        if(!contractList.isEmpty()){
            for(contract c: [select id,recordtype.Name from contract where id=:contractList[0] Limit 1]){
                if(c.recordtype.Name.equals(Label.ECM_Group_Contract_RecordType) || c.recordtype.Name.equals(Label.ECM_Outlet_Contract_RecordType)){
                    parentId=c.Id;
                }
        	}
        }
        if(!String.isBlank(parentId)){
            return parentId;
        }
        return null;
    }
    
    
        
    @AuraEnabled
    public static String deleteFile(String contentDocumentId){
        try{

            if(!String.isBlank(contentDocumentId)){
                Database.delete(contentDocumentId);
                return null;
            }
        }catch(Exception e){
                return e.getMessage();
        }
        return null;
    }
    

}