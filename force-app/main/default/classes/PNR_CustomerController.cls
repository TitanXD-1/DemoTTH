/**********************************************************************
Name: PNR_CustomerController
=======================================================================
Req:Transfer Customer from one service rep to another service rep
=======================================================================
History                                                            
-------                                                            
VERSION   	AUTHOR                   DATE              DETAIL
1.0    	Jyothsna Nagapudi       	29/05/2019      Initial Development
1.1		Tanmoy Bardhan	 			13/06/2019      Modified 
1.2 	Juned Khan					1/07/2019		created new method updateDiageoContactTL for Pion 94
1.3     Juned Khan                  15/07/2019      updated the method updateDiageoContact for Pion 279 
1.4 	Juned Khan					20/07/2019		updated the method updateDiageoContactTL for Pion 597
***********************************************************************/
public without sharing class PNR_CustomerController {
    
    @AuraEnabled
    //Method to display customer assigned to CC/CS/Team Lead
    public static List<Account> getCustomerList(String repNameInfo, Boolean isId) {
       //Variables
		Set<Id> accountSet = new Set<Id>();
        List<Account> customerList = new List<Account>();
        List<PNR_Diageo_Contact__c> diageoContacts= new  List<PNR_Diageo_Contact__c>();
        if(String.isNotBlank(repNameInfo) && Schema.sObjectType.PNR_Diageo_Contact__c.isAccessible()){
            if(isId){
                diageoContacts = [SELECT PNR_Contact_Type__c,PNR_Customer__c,PNR_Diageo_Rep__c 
                              		FROM PNR_Diageo_Contact__c 
                              		WHERE PNR_Diageo_Rep__c = : repNameInfo];
            }else{
                diageoContacts = [SELECT PNR_Contact_Type__c,PNR_Customer__c,PNR_Name__c 
                                  FROM PNR_Diageo_Contact__c 
                                  WHERE PNR_Name__c LIKE: repNameInfo];              
            }
			
            if(!diageoContacts.isEmpty()){
                for(PNR_Diageo_Contact__c diageoContact : diageoContacts) {
                	accountSet.add(diageoContact.PNR_Customer__c);    
            	}
                if(!accountSet.isEmpty() && Schema.sObjectType.Account.isAccessible()){
                    customerList = [SELECT Id, Name, AccountNumber FROM Account where Id IN : accountSet];
                }
            }
        }
        return customerList;
    }
    
    @AuraEnabled
    //Method to retrieve the list of teammember and reportee logged in user
    public static Map<String,String> getReporteeList() { 
        List<User> reporteeList = new List<User>();
        List<User> teamList = new List<User>();
        List<PNR_Diageo_Contact__c> diageoContacts = new  List<PNR_Diageo_Contact__c>();
        Map<String,String> reporteeMap = new Map<String,String>();
        User currentUser = new User();
        //retrieve current logged in user details
        if(Schema.sObjectType.User.isAccessible()){
            currentUser = [SELECT Id,Name,ManagerId,Manager.Name FROM User where Id =: userInfo.getUserId() AND isActive = true];
            reporteeMap.put(currentUser.Id,currentUser.Name);
            if(currentUser.ManagerId == null){
                reporteeList = [SELECT Id,Name,ManagerId FROM User where ManagerId =: currentUser.Id AND isActive = true];
            }else{
                //Fetching the team list of the logged in user
                reporteeList = [SELECT Id, Name,ManagerId FROM User where ManagerId =: currentUser.managerId AND isActive = true];
            }
            if(!reporteeList.isEmpty()){
                for(User userObj:reporteeList){
                    reporteeMap.put(userObj.Id,userObj.Name);
                }
            }
        }
        return reporteeMap; 
    }
    @AuraEnabled  
    //Method to transfer customers from one service representative to another 
    //service representative for Customer Service Rep/Credit Controller Role
    //repNameId == Existing User && userId ==  New UserId
    public static String updateDiageoContact(String repNameId, String roleName, String userId, List<Account> custList, Boolean isId) {
        system.debug('isId'+isId);
        String result='';
        List<PNR_Diageo_Contact__c> diageoContactList = new List<PNR_Diageo_Contact__c>();
        List<PNR_Diageo_Contact__c> updateDiageoContactList = new List<PNR_Diageo_Contact__c>();
        List<PNR_Diageo_Contact__c> newDiageoRepContact = new List<PNR_Diageo_Contact__c>();
        //Map<Id,Account> custMap = new Map<Id,Account>();
        Set<Id>custIdSet = new Set<Id>();
        Boolean isRepPresent = false;
        Boolean isUpdtSucc = true;
        User repList = new User();
        if(!custList.isEmpty()){
            for(Account accObj : custList){
                //custMap.put(accObj.Id,accObj);
                custIdSet.add(accObj.Id);
            }
        }
        //retrieve new service rep cc/cs  user details
        if(isId) {
            if(Schema.sObjectType.User.isAccessible() && String.isNotBlank(userId)){
                repList = [SELECT Id,Name,Email,Phone 
                         	FROM User where Id=: userId AND IsActive = true LIMIT 1];
            }
        }    
        if(Schema.sObjectType.PNR_Diageo_Contact__c.isAccessible()){
            if(String.isNotBlank(userId)){
                if(isId){
                    //retrieve diageo contact details for new selected rep
            		newDiageoRepContact = [SELECT Id,PNR_Contact_Type__c,PNR_Customer__c,PNR_Diageo_Rep__c,PNR_Phone__c,
                                            PNR_Email__c,PNR_Comments__c,PNR_Additional_Info__c 
                                            FROM PNR_Diageo_Contact__c 
                                            WHERE PNR_Diageo_Rep__c = : userId LIMIT 1];
                }else{
                    newDiageoRepContact = [SELECT PNR_Contact_Type__c,PNR_Customer__c,PNR_Name__c,
                                           PNR_Phone__c,PNR_Email__c,PNR_Comments__c,PNR_Additional_Info__c 
                                           FROM PNR_Diageo_Contact__c 
                                           WHERE PNR_Name__c = : userId LIMIT 1]; 
                }
                 
                if(!newDiageoRepContact.isEmpty()){
                    isRepPresent = true;
                }
        	}
            if(String.isNotBlank(repNameId) ){
                if(isId){
                    //retrieve diageo contact details for selected cc/cs/tl
                	diageoContactList = [SELECT PNR_Contact_Type__c,PNR_Customer__c,PNR_Diageo_Rep__c,PNR_Phone__c,PNR_Email__c 
                                         FROM PNR_Diageo_Contact__c 
                                         WHERE PNR_Diageo_Rep__c = : repNameId 
                                         AND PNR_Customer__c IN :custIdSet];
                }else{
                    diageoContactList = [SELECT PNR_Contact_Type__c,PNR_Customer__c,PNR_Name__c,
                                         PNR_Phone__c,PNR_Email__c,PNR_Comments__c,PNR_Additional_Info__c 
                                         FROM PNR_Diageo_Contact__c WHERE PNR_Name__c = : repNameId
                                         AND PNR_Customer__c IN :custIdSet];
                }
                
                if(!diageoContactList.isEmpty()){
                    for(PNR_Diageo_Contact__c diageoContact : diageoContactList){
                            if(!isRepPresent && repList != null){
                                diageoContact.PNR_Diageo_Rep__c = repList.id;
                                diageoContact.PNR_Contact_Type__c = roleName;
                                diageoContact.PNR_Phone__c = repList.Phone;
                                diageoContact.PNR_Email__c = repList.Email;
                                if(isId){
                                    diageoContact.PNR_Name__c = '';
                                }else{
                                   diageoContact.PNR_Name__c = userId; 
                                }
                                diageoContact.PNR_Additional_Info__c = '';
                                diageoContact.PNR_Comments__c = '';
                                updateDiageoContactList.add(diageoContact);
                            }else if(isRepPresent && !newDiageoRepContact.isEmpty()){
                                if(isId){
                                    diageoContact.PNR_Name__c = '';
                                    diageoContact.PNR_Diageo_Rep__c = newDiageoRepContact[0].PNR_Diageo_Rep__c;
                                }else{
                                    diageoContact.PNR_Name__c = newDiageoRepContact[0].PNR_Name__c;
                                    diageoContact.PNR_Diageo_Rep__c = null ;
                                }
                                diageoContact.PNR_Contact_Type__c = roleName;
                                diageoContact.PNR_Phone__c = newDiageoRepContact[0].PNR_Phone__c;
                                diageoContact.PNR_Email__c = newDiageoRepContact[0].PNR_Email__c;
                                diageoContact.PNR_Comments__c = newDiageoRepContact[0].PNR_Comments__c;
                                diageoContact.PNR_Additional_Info__c = newDiageoRepContact[0].PNR_Additional_Info__c;
                                updateDiageoContactList.add(diageoContact);
                            }
                        //}
                    }
                }
            }
            if(!updateDiageoContactList.isEmpty() && Schema.sObjectType.PNR_Diageo_Contact__c.isUpdateable()){
                Database.SaveResult[] srList = Database.update(updateDiageoContactList, false);
                for (Database.SaveResult sr : srList) {
                    if(!sr.isSuccess()){
                       //New Code
                        for(Database.Error err : sr.getErrors()) {
                            result = result +err.getMessage();
                        }
                        //New Code 
                        isUpdtSucc = false;
                        break;
                    }
                } 
                if(isUpdtSucc){
                    result = 'Success';
                }else{
                    result =result;
                }
            }
                         
        }
        return result;
    }
	@AuraEnabled  
    //Method to  unassign the Diageo contact from CC/CS to Team Lead and vice versa.
    public static String updateDiageoContactTL(String repId,List<Account> custList){
        //Variables
        String result='';
        List<User> salesRep = new List<User>();
        List<PNR_Diageo_Contact__c> conList = new List<PNR_Diageo_Contact__c>();
        List<PNR_Diageo_Contact__c> mngrConList = new List<PNR_Diageo_Contact__c>();
        List<PNR_Diageo_Contact__c> updatedConList = new List<PNR_Diageo_Contact__c>();
        Set<Id> accIdSet = new Set<Id>();
        Boolean isUpdtSucc = true;
        Boolean isManager =false ;
        if(!custList.isEmpty()){
            for(Account accObj : custList){
                accIdSet.add(accObj.Id);
            }
        }
        if(String.isNotBlank(repId) && Schema.sObjectType.User.isAccessible()){
            salesRep = [SELECT Id,Name,ManagerId,Manager.Email,Manager.Phone 
                        FROM User 
                        WHERE  Id = : repId ];//This might be an Inactive user too, So no need to add IsActive
        }
        if(String.isNotBlank(repId) && Schema.sObjectType.PNR_Diageo_Contact__c.isAccessible()){
            conList = [SELECT Id,PNR_Diageo_Rep__c,PNR_Name__c,PNR_Phone__c,PNR_Email__c,
                       PNR_Contact_Type__c,PNR_Comments__c,PNR_Additional_Info__c
                       FROM PNR_Diageo_Contact__c 
                       WHERE PNR_Diageo_Rep__c =: repId 
                       AND PNR_Customer__c IN :accIdSet];
            if(!conList.isEmpty() && !salesRep.isEmpty() && salesRep[0].ManagerId != null){
                mngrConList = [SELECT Id,PNR_Additional_Info__c,PNR_Comments__c,PNR_Contact_Type__c 
                          		FROM PNR_Diageo_Contact__c 
                       			WHERE PNR_Diageo_Rep__c =: salesRep[0].ManagerId 
                              	LIMIT 1];
                if(!mngrConList.isEmpty()){
                    isManager = true;
                }
                for(PNR_Diageo_Contact__c diageoConObj : conList){
                    if(isManager){
                    	diageoConObj.PNR_Contact_Type__c = mngrConList[0].PNR_Contact_Type__c;
                    	diageoConObj.PNR_Comments__c = mngrConList[0].PNR_Comments__c;
                        diageoConObj.PNR_Additional_Info__c = mngrConList[0].PNR_Additional_Info__c;
                    }else{
                       	diageoConObj.PNR_Comments__c = '';
                        diageoConObj.PNR_Additional_Info__c = '';
                    }
                    diageoConObj.PNR_Diageo_Rep__c = salesRep[0].ManagerId  ;
                    diageoConObj.PNR_Name__c ='';
                    diageoConObj.PNR_Phone__c = salesRep[0].Manager.Phone;
                    diageoConObj.PNR_Email__c = salesRep[0].Manager.Email;
                    updatedConList.add(diageoConObj);
                }
            }else if(!salesRep.isEmpty() && salesRep[0].ManagerId == null){
                result = Label.PNR_TeamLeadNotFound;
            }
        }	
        if(!updatedConList.isEmpty() && Schema.sObjectType.PNR_Diageo_Contact__c.isUpdateable()){
            Database.SaveResult[] srList = Database.update(updatedConList, false);
            for (Database.SaveResult sr : srList) {
                if(!sr.isSuccess()){
                    //New Code
                    for(Database.Error err : sr.getErrors()) {
                        system.debug('===Inside Error Block===');
                        result = result +err.getMessage();
                    }
                    //New Code
                    isUpdtSucc = false;
                    break;
                }
            }
            if(isUpdtSucc){
                result = 'Success';
            }else{
                result = result;
            }
        }
        return result;
    }
}