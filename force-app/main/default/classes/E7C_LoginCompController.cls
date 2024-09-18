public without sharing class E7C_LoginCompController{
    
    @AuraEnabled
    public static void validateUserLogin(String user_name, String user_pwd){
        try{
            System.debug('username>>>'+user_name);
            System.debug('user_pwd>>>'+user_pwd);
            List<User> userList = [SELECT Id,username FROM User WHERE Email= :user_name AND IsActive = true];
            if(userList.size() > 0)
            {
                User u = userList[0];
                ApexPages.PageReference lgn = Site.login(u.username, user_pwd, '/s/user-welcome');
                aura.redirect(lgn);
            }else{
                throw new E7C_GenericException('Invalid Email');
            }
            
        }catch(E7C_GenericException e){
            System.debug('Exception>>>'+e.getStackTraceString());
            throw new AuraHandledException('The Email Id entered is not registered!');
        }catch(Exception e){
            System.debug('Exception>>>'+e.getStackTraceString());
            throw new AuraHandledException('Wrong Password! Access will be locked after 10 unsuccessful attempts.');
        }
    }
    
    
    @AuraEnabled 
    public static boolean fetchUserType() {
        boolean isLoggedIn = false;
        String userType = UserInfo.getUserType();
        if (userType != 'Guest') {
            isLoggedIn = true;
        }
        return isLoggedIn;
    }
    
    @AuraEnabled
    public static String getLoginURLfromSSO(){
        if(Test.isRunningTest()){
            return '';
        }else{
            return [SELECT LoginUrl, Id, DeveloperName FROM SamlSsoConfig where MasterLabel =: Label.E7C_SAMLLabel].LoginUrl;    
        }
        
    }
    
    
    /*@AuraEnabled
public static List<E7C_Survey_Question__c> fetchSurveyQuestions()
{
// try{
system.debug('called');
List<E7C_Survey_Question__c> surveyQuestionList= new List<E7C_Survey_Question__c>();
surveyQuestionList= [SELECT Id,E7C_Question__c,E7C_Question_Category__c,E7C_Question_Priority__c,E7C_Response_Type__c FROM E7C_Survey_Question__c];
system.debug('df'+surveyQuestionList);
return surveyQuestionList;
//}catch(exception ex){
//  system.debug('getline number'+ex.getLineNumber()+'getmessage '+ex.getMessage());
//  return new List<E7C_Survey_Question__c>();
//}

}*/
}