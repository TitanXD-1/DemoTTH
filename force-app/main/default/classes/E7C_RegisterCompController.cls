public without sharing class E7C_RegisterCompController{
    
    @AuraEnabled
    public static void registerUser(User usr, String profileName, String pass)
    {
        try{
            if(!usr.Email.contains('@diageo.com')){
                
                System.debug('User Register>>> '+usr);
                System.debug('profileName>>> '+profileName);
                Account acc = [SELECT Id FROM Account WHERE Name = 'Guinness 7Cs' LIMIT 1];
                
                Id profileId = [SELECT Id FROM Profile WHERE Name =: 'E7C_Community User' LIMIT 1].Id;
                System.debug('profile Id>>> ' +profileId);
                
                User u = new User();
                u.FirstName = 'Guinness';
                u.LastName = 'User'+String.valueof(Integer.valueof(Math.random()*1000));
                u.Email = usr.Email;
                u.Username = usr.Email+'.7Cs';
                u.Alias = 'GuiUsr';
                u.CommunityNickname = 'GuiUsr'+''+String.valueof(Integer.valueof(Math.random()*1000));
                u.LOCALESIDKEY = 'en_GB';
                u.LANGUAGELOCALEKEY = 'en_GB';
                u.EmailEncodingKey = 'UTF-8';
                u.TIMEZONESIDKEY = 'Europe/London';
                u.CURRENCYISOCODE = 'GBP';
                u.ProfileId = profileId;
                u.Assigned_Markets__c = 'Europe and Turkey';
                //Site.createPortalUser(u, acc.Id, pass, true);
                Id usrId = Site.createExternalUser(u, acc.Id, pass, true);
                System.debug('newUSerId:: '+usrId);
                User newUser;
                if(!Test.isRunningTest())
                	newUser = [SELECT Id, ContactId, Contact.E7C_Persona__c FROM User WHERE Id =: usrId LIMIT 1];
                else
                    newUser = [SELECT Id, ContactId, Contact.E7C_Persona__c FROM User LIMIT 1];
                System.debug('newUSer:: '+newUser);
                Contact con = new Contact();
                con.Id = newUser.ContactId;
                con.E7C_Persona__c = profileName;
                update con;
            }else{
                throw new E7C_GenericException('Diageo employees need to raise a JML request to get access to the app');
            }
            
        }
        catch(E7C_GenericException ex){
            throw new AuraHandledException(ex.getMessage());
        }
        catch(TypeException te){
            if(te.getMessage() == 'Your request cannot be processed at this time. The site administrator has been alerted.'){
                throw new AuraHandledException('An account is already registered to this email address. '+
                                               'Please try login with your account or reset your password.');
            }else{
                throw new AuraHandledException(te.getMessage());
            }
        }
        catch(Exception e){
            System.debug('Exception>>> '+e.getStackTraceString());
            System.debug('Exception Type>>> '+e.getTypeName());
            System.debug('Exception Message>>> '+e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
        
    }
    
    @AuraEnabled
    public static List<String> getValidPersonas(String location){
        List<String> personas = new List<String>();
        for(Survey__c survey: [SELECT E7Cs_Persona__c FROM Survey__c WHERE Country__r.Name =: location ORDER BY E7Cs_Persona__c]){
            personas.add(survey.E7Cs_Persona__c);
        }
        if(personas.size() > 0 && !personas.isEmpty())
        {
            return personas;
        }else{
            return null;
        }
    }
}