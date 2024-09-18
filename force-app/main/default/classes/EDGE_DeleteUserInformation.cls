/**
   Name : EDGE_DeleteUserInformation 

   Description: This is the server side controller class for <DeleteUserInformation> lightning component.
                 Server side update, fetch record will be perform here.

   History                                                            
   -------                                                            
   VERSION   	AUTHOR            	DATE              DETAIL
   1.0       Monalisa Halder      25/09/2020        ES20-8282
   1.1       Monalisa Halder      24/11/2020        ES20-8882
   1.2		 Doman Murmu		  17/07/2023		142822
**/
public without sharing class EDGE_DeleteUserInformation {
    public static List<ContentDocument> contentDocDeleteList = new List<ContentDocument>();
    
    /*
    Purpose: To fetch the Users depend on the criteria selected on UI                                                          
    */
    @AuraEnabled
    public static List<User> searchUserDetails(String queryString){
        List<User> userList = new List<User>();
        String SalesRep = 'Sales Representative';	//NOPMD	//142822
        String SalesManager = 'Sales Manager';		//NOPMD
      
        try{
            if(String.isNotBlank(queryString)){
                //Append AND/OR to create the query properly
                if(queryString.startsWith(' OR')){
                    queryString = queryString.removeStart(' OR');
                    queryString = ' AND ( ' + queryString + ' )';
                }
                if(Schema.sObjectType.User.isAccessible() && Schema.sObjectType.User.fields.FirstName.isAccessible() && 
                   Schema.sObjectType.User.fields.isActive.isAccessible() 
                  ){
                      String strQuery = 'SELECT Id, FirstName,LastName, Email, isActive, Profile.Name,LastLoginDate,Available_Countries__c FROM User';
                      strQuery += ' WHERE isActive = False AND (Profile.Name =:SalesRep OR Profile.Name =:SalesManager)';
                    strQuery = String.escapeSingleQuotes(strQuery);		//142822
                      //Add Filter Query String
                      strQuery += queryString;
                      strQuery += ' Order by Name';
                      System.debug('Query -> '+ strQuery);
                      System.debug(String.escapeSingleQuotes(strQuery));
                      userList = Database.query(strQuery);
                      // Added for ES20-8882
                      userList = searchInactiveUserByCountry(userList);
                      
                  }
                
            }        
        } catch(Exception ex){
            System.debug(LoggingLevel.DEBUG,'Exception::::'+ex.getLineNumber()+ex.getMessage());
            //throw new AuraHandledException(ex.getMessage());
            AuraHandledException ae = new AuraHandledException(ex.getMessage());
            ae.setMessage(ex.getMessage());
            throw ae;
        }
        return userList;
    }
    /***************************************************************
    User Story : ES20-8882
	Purpose: To fetch the Users filtering based on available country   
    *****************************************************************/
    private static List<User> searchInactiveUserByCountry(List<User> userList){
        String mdmCountry;
        String salesRepManagerCountry;
        List<String> salesRepManagerCountryList = new List<String>();
        List<String> mdmCountryList = new List<String>();
        User loggedInUser = [Select Id,Available_Countries__c,Profile.Name from User where Id = :userinfo.getUserId()];
        if(loggedInUser.Profile.Name == 'Master Data Manager'){
            List <User> finalUserList = new List <User>();
            if(loggedInUser.Available_Countries__c != null){
                mdmCountry = loggedInUser.Available_Countries__c;
                mdmCountryList = mdmCountry.split(';');
            }
            for(User usr :userList){
                if(usr.Available_Countries__c != null){
                    salesRepManagerCountry = usr.Available_Countries__c;
                    salesRepManagerCountryList = salesRepManagerCountry.split(';');    
                }
                if(salesRepManagerCountryList.size()>0 && salesRepManagerCountryList != null && mdmCountryList.size()>0 && mdmCountryList != null){
                    for(String countryMatch :salesRepManagerCountryList){
                        if(mdmCountryList.contains(countryMatch)){
                            finalUserList.add(usr);
                            break;  
                        }
                    }
                }
            }
            userList = finalUserList;
        }
        return userList;
    }
    /***************************************************************
    User Story : ES20-8882
	Purpose: //Parent Method
    *****************************************************************/
    
    @AuraEnabled
    public static void deleteUserInfo(List<Id> userIdList){
        List<Id> salesRepUserIdList = new List<Id>();
        List<User> salesRepUserList = new List<User>();
        if(userIdList != null && userIdList.size()>0){
            List<User> userList = [Select Id,Profile.Name,IsProfilePhotoActive,Start_Street__c,Start_City__c,Start_State__c,Start_Postcode__c,Start_Country__c,Start_Latitude__c,Start_Longitude__c from User where Id IN :userIdList];
           
            for(User user :userList){
                if(!Test.isRunningTest()){
                	System.UserManagement.obfuscateUser(user.Id);    
                }
                
                if(user.IsProfilePhotoActive == true){
                	removePhoto(user.Id);    
                }
                
                if(user.Profile.Name == 'Sales Representative'){
                    salesRepUserIdList.add(user.Id);
                    salesRepUserList.add(user);
                }
            }
            if(salesRepUserIdList != null && salesRepUserIdList.size()>0){
                deleteCoachingForm(salesRepUserIdList);
                deletePersonalInformation(salesRepUserIdList);
                deleteMapsLocation(salesRepUserIdList);
                updateUserRecord(salesRepUserList);
                deleteContentDocument(contentDocDeleteList);
                
            }
            
            
        }  
        
    }
    
     /*****************************
     Method Name: removePhoto      
     Description: Deletes uploaded photo of Inactive User
    *************************************/
    @AuraEnabled
    public static void removePhoto(Id userId) {
        try{
            ConnectApi.UserProfiles.deletePhoto(null,userId);    
        }catch(Exception ex){
            System.debug(LoggingLevel.DEBUG,'Exception:::'+ex.getLineNumber()+ex.getCause()+ex.getMessage());
            
        } 
    }
    
        /*****************************
     Method Name: deleteCoachingForm      
     Description: Deletes the coaching report and its related document
    *************************************/
    @AuraEnabled
    public static void deleteCoachingForm(List<id> userIdList){
        List<ContentDocument> conDocUpdateList = new List<ContentDocument>();
        try{
            Set<Id> contentDocIdSet = new Set<Id>();
            List<Id> contentDocIdList = new List<Id>();
            List<ContentDocument> conDocList = new List<ContentDocument>(); 
            List<Coaching_Report__c> coachingReportList = [Select Id,Sales_Representative__c,Content_Document_Id__c from Coaching_Report__c where Sales_Representative__c IN :userIdList];
            for(Coaching_Report__c creport :coachingReportList){
                contentDocIdSet.add(creport.Content_Document_Id__c);
                contentDocIdList.add(creport.Content_Document_Id__c);
            }
            
            if(contentDocIdSet != null){
                conDocList = [Select Id  from ContentDocument where Id IN :contentDocIdSet];
            }
            if(coachingReportList != null && coachingReportList.size() > 0){
                Database.delete(coachingReportList,true);
            }
            
            if(conDocList != null && conDocList.size() > 0){
                for(ContentDocument conDoc :conDocList ){
                    conDoc.OwnerId = UserInfo.getUserId();
                    conDocUpdateList.add(conDoc);
                    contentDocDeleteList.add(conDoc);
                    system.debug(LoggingLevel.DEBUG,'@@conDocUpdateListCoaching Reports' +conDocUpdateList);
                }
                
                Database.Update(conDocUpdateList,true);
            }
           
        }catch(Exception ex){
            System.debug(LoggingLevel.DEBUG,'Exception:::'+ex.getLineNumber()+ex.getCause()+ex.getMessage());
            
        }       
    }  
    /*****************************
     Method Name: deletePersonalInformation      
     Description: Deletes personal information and its child records - travel log and travel logbook
    *************************************/
    @AuraEnabled
    public static void deletePersonalInformation(List<id> userIdList){
        List<ContentDocument> conDocList = new List<ContentDocument>();
        List<ContentDocument> conDocUpdateList = new List<ContentDocument>();
        List<Travel_Logbook__c> travelLogBookLists = new List<Travel_Logbook__c>();
        Set<Id> conDocIdSet = new Set<Id>();
        try{
            List<Personal_Information__c> perInfoList = [Select Id,User__c from Personal_Information__c where User__c IN :userIdList];
            
            if(perInfoList != null && perInfoList.size()>0){
                travelLogBookLists = [Select Id,Content_Document_Id__c,Personal_Information__c from Travel_Logbook__c where Personal_Information__c IN :perInfoList];
            }
            
            for(Travel_Logbook__c tl :travelLogBookLists){
                conDocIdSet.add(tl.Content_Document_Id__c); 
                system.debug(LoggingLevel.DEBUG,'@@conDocIdSet' +conDocIdSet);
            }
            if(conDocIdSet !=null){
                conDocList =[Select Id  from ContentDocument where Id IN :conDocIdSet];
                system.debug(LoggingLevel.DEBUG,'@@conDocList' +conDocList);
            }
            if(conDocList != null && conDocList.size() > 0){
                for(ContentDocument conDoc :conDocList ){
                    conDoc.OwnerId = UserInfo.getUserId();
                    conDocUpdateList.add(conDoc);
                    contentDocDeleteList.add(conDoc);
                    system.debug(LoggingLevel.DEBUG,'@@conDocUpdateList' +conDocUpdateList);
                }
                
                Database.Update(conDocUpdateList,true);
            }
            
            if(perInfoList != null && perInfoList.size() > 0){
               Database.delete(perInfoList,true);
            }
         
        }catch(Exception ex){
            System.debug(LoggingLevel.DEBUG,'Exception:::'+ex.getLineNumber()+ex.getCause()+ex.getMessage());
            
        } 
    } 
    
    /*****************************
     Method Name: deletePersonalInformation      
     Description: Deletes personal information and its child records - travel log and travel logbook
    *************************************/
    @AuraEnabled
    public static void deleteMapsLocation(List<id> userIdList){
        try{
            List<maps__Location__c> mapsLocationList = [Select Id,maps__User__c from maps__Location__c where maps__User__c IN :userIdList];
            if(mapsLocationList != null && mapsLocationList.size() > 0){
                Database.delete(mapsLocationList,true);
            }
        }catch(Exception ex){
            System.debug(LoggingLevel.DEBUG,'Exception:::'+ex.getLineNumber()+ex.getCause()+ex.getMessage());
            
        } 
        
    } 
    /*****************************
     Method Name: update User records     
     Description: 
    *************************************/
    @AuraEnabled
    public static void updateUserRecord(List<User> userList){
        try{
            List<User> userUpdateList = new List<User>();
            for(User usr :userList){
                usr.Start_Street__c = '';
                usr.Start_City__c = '';
                usr.Start_State__c = '';
                usr.Start_Postcode__c = '';
                usr.Start_Country__c = '';
                usr.Start_Latitude__c = 0.00;
                usr.Start_Longitude__c = 0.00;
                usr.maps__MapsSetting__c = '';
                userUpdateList.add(usr);   
            }
           
            
            if(userUpdateList != null && userUpdateList.size() > 0){
                Database.update(userUpdateList,true);
            }
        }catch(Exception ex){
            System.debug(LoggingLevel.DEBUG,'Exception:::'+ex.getLineNumber()+ex.getCause()+ex.getMessage());
            
        } 
        
    } 
    /*****************************
     Method Name: update User records     
     Description: 
    *************************************/
   
    public static void deleteContentDocument(List<ContentDocument> contentDocDeleteList){
        system.debug(LoggingLevel.DEBUG,'@@contentDocDeleteList' +contentDocDeleteList);
         ID contentDocumentDeleteJobId = System.enqueueJob(new EDGE_ContentDocumentAsyncDelete(contentDocDeleteList));
        
    }
    

}