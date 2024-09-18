/***************************************************************************************************************
Name: EDGE_UserImageService
================================================================================================================
Req: Api Class to generate USer image file in base64 encoded format
User Story :ES20-10058
================================================================================================================
History                                                            
-------                                                            
VERSION   AUTHOR                  DATE              DETAIL
1.0     Manikant              04/07/2021       Api Class to generate USer image file in base64 encoded format
2.0		Aparajita		      06/07/2021	   Added error-handling for inactive users(ES20-10211)
******************************************************************************************************************/
@RestResource(urlMapping='/UserImageService/*')
global with sharing class EDGE_UserImageService {
    
    @HttpGet
    global static EDGE_UserDetailsWrapper doGet(){       
        EDGE_UserDetailsWrapper userWrapper = new EDGE_UserDetailsWrapper();

        try{
            Id userId = Restcontext.request.params.get('userid');
            Blob strImg ;
            
            if(userId != null){
                List<User> userRecList = [SELECT Id, lastModifiedDate,SmallPhotoUrl, FullPhotoUrl FROM User WHERE id = :userId 
                                          AND IsActive = true ]; //modified : ES20-10211
                if(userRecList != null && userRecList.size() > 0) 
                {
                    User userRec = userRecList[0];
                    
                    PageReference ref = new PageReference(userRec.FullPhotoUrl); 
                    if(Test.isRunningTest()){
                        strImg = blob.valueOf('Unit.Test');
                    }else{
                        strImg = ref.getContent();
                    }
                    userWrapper.userImageData =  EncodingUtil.base64Encode(strImg);
                    //ES20-10211
                    userWrapper.isError = false;
                    userWrapper.errorMessage = '';          
                } 
                //ES20-10211
                else
                {  
                    userWrapper.userImageData =  '';
                    userWrapper.isError = true ;
                    userWrapper.errorMessage = 'User not found';
                }
            }
        }catch(Exception serviceException){
            userWrapper.userImageData =  '';
            userWrapper.isError = true ;
            userWrapper.errorMessage = serviceException.getMessage();
        }
        
        return userWrapper;
    }
}