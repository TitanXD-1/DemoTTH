public with sharing class MetadataInsertUpdate implements Metadata.DeployCallback{
    
    public void handleResult(Metadata.DeployResult result, Metadata.DeployCallbackContext context) {
        if(result.status == Metadata.DeployStatus.Succeeded){
            System.debug(' success: '+ result);
        }else{
            System.debug(' fail: '+ result);
        }
    }  
    
    public static void handleInsertAndUpdate (String fullName, String label, Map<String, Object> fieldWithValuesMap){
        Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
        customMetadata.fullName = fullName;
        customMetadata.label = label;
        
        for (String key: fieldWithValuesMap.keySet()) {
            Metadata.CustomMetadataValue customField = new Metadata.CustomMetadataValue();
            customField.field = key;
            customField.value = fieldWithValuesMap.get(key);
            customMetadata.values.add(customField);
        }
        
        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
        mdContainer.addMetadata(customMetadata);
        metadataInsertUpdate callback = new metadataInsertUpdate();
        Id jobId = Metadata.Operations.enqueueDeployment(mdContainer, callback);
    }
}