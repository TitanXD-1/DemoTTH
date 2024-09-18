global class MD_RegistrationSaveClass {
    
    
    global class saveContact implements DiageoCMS.FormSaveInterface{
        
        global DiageoCMS.FormResponseWrapper execute(Map<String,SObject> formData){
            MD_JSONResponse jsonResponse = MD_ES_RegistrationUtil.checkVATNumber(formData);
            return MD_ES_RegistrationUtil.resolveResponse(jsonResponse);
        }
    }
    
    
    
    global class saveContactExtended implements DiageoCMS.FormSaveInterface{
        
        global DiageoCMS.FormResponseWrapper execute(Map<String,SObject> formData){
            MD_JSONResponse jsonResponse = MD_ES_RegistrationUtil.submitRequestForApproval(formData);
            return MD_ES_RegistrationUtil.resolveResponse(jsonResponse);   
        }
    }
    
}