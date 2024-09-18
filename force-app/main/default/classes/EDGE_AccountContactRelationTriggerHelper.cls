/**
 * @name : EDGE_AccountContactRelationTriggerHelper
 * @description : Trigger Helper Class for AccountContactRelationTrigger
 * @history
 * VERSION      AUTHOR          DATE            DETAIL
 * 1.0          Sagar Barman    20/03/2019      Initial Development (ES20-461)
 * 2.0          Sagar Barman    16/09/2021      ES20-8178
 * 3.0          Kapil Baliyan   27/05/2021      NCP-3459 (validateContactOnInsert, checkPrimaryContactUpdate, populateContactErrorMap)
 * 4.0          Kapil Baliyan   21/12/2021      NCP-5777 (validateUserAccess, updateAccountContactType)
 * 5.0			Rajarshi Lahiri 05/04/2022		ES20-12341(indirectContactShare)
 * 6.0          Anand Uppalapati25/04/2022      ES20-12532(validateContactOnInsert)
 * 7.0          Wribhu Bose		26/04/2022      ES20-12548 and ES20-12393 (commented out methods pertaining to Primary/Secondary Contacts validations)
 * 8.0			Aparajita       06/05/2022      ES20-12476/ES20-12682(Method:indirectContactShare - modified)
 * 9.0			Saranya L		09/05/2022		ES20-12653( new Method:syncOutletRole)
 * 10.0			Swaraj Samanta  03/06/2022		ES20-12654(new Method: updateDirectContactRoleFields)
 * 11.0			Swagata Mondal	06/01/2023		CUS-383(Method:indirectContactShare - modified)
 */
public without sharing class EDGE_AccountContactRelationTriggerHelper {
    
    /**************************************************************************    
    Purpose: The below method checks if the associated Outlet has Primary outletContact
    while Adding OutletContact. If account contact is marked as 
    primary then it marks contact as primary and duplicate rule fires . 
    It show custom error message if duplicate found
    ****************************************************************************/
    /*Commented out for ES20-12548 and ES20-12393
    public static void validateContactOnInsert(List<SObject> newItems){//insert
        Map<Id,String> contactTypeMap = new Map<Id,String>();
        Map<Id, Boolean> outletPrimaryContactmap = new Map<Id,Boolean>();
        Set<Id> secondaryContactIdSet = new Set<Id>();
        Set<Id> contactIdSet = new Set<Id>();
        Set<Id> accIdlist = new Set<Id>();
        Set<Id> accIdSet = new Set<Id>(); //NCP-3459
        Map<Id,String> duplicateContactErrorMAP = new Map<Id,String>();   
        try{
            for(SObject obj :newItems){
                AccountContactRelation newAccContact = (AccountContactRelation)obj;                
                if((newAccContact.AccountId!=null && newAccContact.Contact_Type__c=='Secondary')){ 
                    secondaryContactIdSet.add(newAccContact.ContactId); 
                    System.debug('--secondaryContactIdSet--'+secondaryContactIdSet);
                }                
                if(newAccContact.AccountId!=null && newAccContact.Contact_Type__c=='Primary'){                     
                    accIdlist.add(newAccContact.AccountId);  
                }
                //ES20-12532 - Implemented IsDirect check in below if
                if(newAccContact.AccountId!=null && newAccContact.Contact_Type__c!=null && newAccContact.IsDirect){
                    contactIdSet.add(newAccContact.ContactId); 
                    //populate contact type map with new values
                    contactTypeMap.put(newAccContact.ContactId,newAccContact.Contact_Type__c);
                    accIdSet.add(newAccContact.AccountId); //NCP-3459
                }
            }
            //Update the AccountContactRelation's contact type as Secondary if the Account already has Primary contact
            updateAccountContactType(newItems);
            //update the contact List               
            if(accIdlist.size() > 0){
                outletPrimaryContactmap =  getOutletPrimaryContact(accIdlist);  
            }
            //get duplicate error Map 
            duplicateContactErrorMAP = populateContactErrorMap(contactIdSet,secondaryContactIdSet,contactTypeMap, accIdSet);
            if(!duplicateContactErrorMAP.IsEmpty()){
                for(SObject obj :newItems){
                    AccountContactRelation newcon = (AccountContactRelation)obj;
                    //throw error for Duplicate Contacts                
                    if(!duplicateContactErrorMAP.IsEmpty() && duplicateContactErrorMAP.get(newcon.ContactId)!= null && duplicateContactErrorMAP.get(newcon.ContactId) != 'Record saved successfully'){
                        if(duplicateContactErrorMAP.get(newcon.ContactId).contains('duplicate')){
                            newcon.addError(Label.Contact_Duplicate_Rule_Custom_message+' '+duplicateContactErrorMAP.get(newcon.ContactId));            
                        }
                        else{
                            newcon.addError(duplicateContactErrorMAP.get(newcon.ContactId));    
                        }    
                    }     
                    // throw error if acc has pre-existing primary contacts
                    if(!outletPrimaryContactmap.isEmpty() && outletPrimaryContactmap.get(newcon.AccountId)){
                        newcon.addError(Label.One_Primary_Contact);
                    }
                }     
            }               
        }
        catch(Exception ex){
            System.debug('--Exception--'+ex+ex.getLineNumber());             
        }
    }*/    
    /*******************************************************************    
    Purpose: The below method checks if the associated Outlet has Primary 
    Contact while updating Outlet Contact and update the parent Contact. 
    ********************************************************************/
    /*Commented out for ES20-12548 and ES20-12393
    public static void checkPrimaryContactUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){        
        Map<Id,String> contactTypeMap = new Map<Id,String>();
        Map<Id, Boolean> outletPrimaryContactmap = new Map<Id,Boolean>();
        Set<Id> secondaryContactIdSet = new Set<Id>();
        Set<Id> contactIdSet = new Set<Id>();
        Set<Id> accIdlist = new Set<Id>();      
        Set<Id> accIdSet = new Set<Id>();
        Map<Id,String> duplicateContactErrorMAP = new Map<Id,String>();         
        try{
            if(oldItems != null){
                for(SObject sob:newItems.values()){
                    AccountContactRelation newAccountCon = (AccountContactRelation)sob;
                    AccountContactRelation oldAccountCon = (AccountContactRelation)oldItems.get(newAccountCon.id);
                    if(newAccountCon.Contact_Type__c != oldAccountCon.Contact_Type__c && newAccountCon.Contact_Type__c=='Primary'){
                        accIdlist.add(newAccountCon.AccountId); 
                    }
                    if(newAccountCon.Contact_Type__c != oldAccountCon.Contact_Type__c && newAccountCon.Contact_Type__c=='Secondary'){
                        secondaryContactIdSet.add(newAccountCon.ContactId); 
                    }
                    if(newAccountCon.Contact_Type__c != oldAccountCon.Contact_Type__c){
                        contactIdSet.add(newAccountCon.ContactId);
                        contactTypeMap.put(newAccountCon.ContactId,newAccountCon.Contact_Type__c); 
                        accIdSet.add(newAccountCon.AccountId); //NCP-3459
                    }
                    //if an ACR is getting deactivated make it's Contact Type = Secondary
                    if(newAccountCon.IsActive != oldAccountCon.IsActive && newAccountCon.IsActive == false){
                        newAccountCon.Contact_Type__c = 'Secondary';
                    }
                }
                if(accIdlist.size() >0){
                    outletPrimaryContactmap =  getOutletPrimaryContact(accIdlist);     
                }             
                System.debug('outletPrimaryContactmap'+outletPrimaryContactmap);
                duplicateContactErrorMAP = populateContactErrorMap(contactIdSet,secondaryContactIdSet,contactTypeMap, accIdSet); //NCP-3459
                for(SObject obj :newItems.values()){
                    AccountContactRelation newcon = (AccountContactRelation)obj;
                    //throw error for Duplicate Contacts
                    if(!duplicateContactErrorMAP.IsEmpty() && duplicateContactErrorMAP.get(newcon.ContactId)!= null && duplicateContactErrorMAP.get(newcon.ContactId) != 'Record saved successfully'){
                        if(duplicateContactErrorMAP.get(newcon.ContactId).containsIgnoreCase('Use one of these records?')){//errorMessageFor duplicate
                            newcon.addError(Label.Contact_Duplicate_Rule_Custom_message);            
                        }
                        else{
                            newcon.addError(duplicateContactErrorMAP.get(newcon.ContactId));    
                        }    
                    }             
                    // throw error if acc has pre-existing primary contacts
                    if(!outletPrimaryContactmap.isEmpty() && outletPrimaryContactmap.get(newcon.AccountId)){
                        newcon.addError(Label.One_Primary_Contact); 
                    }
                }     
            }
        }catch(Exception ex){
            System.debug('--Exception--'+ex+ex.getLineNumber());           
        }        
    }
*/
    /*******************************************************************    
    Purpose: The below method provides the MAP of oulet and boolean values
    depending on if the Outlet has promary Acoountcontact or not.
    ********************************************************************/
	/*Commented out for ES20-12548 and ES20-12393
    public static Map<Id, Boolean> getOutletPrimaryContact(Set<Id> accIdSet){
        Map<Id, Boolean> outletPrimaryContactmap = new map<Id,Boolean>();
        List<Account> acclist = new List<Account>();
        if(Schema.sObjectType.Account.isAccessible() && Schema.sObjectType.AccountContactRelation.isAccessible() && Schema.sObjectType.AccountContactRelation.isUpdateable()) {//NCP-5777: Commented this line //&& Schema.sObjectType.Account.isUpdateable() because we are just querying on account so no need to check whether Account is Updateable or not
            //AND IsActive=true ES20-8178
            acclist = [SELECT Id, (SELECT Id, Contact_Type__c FROM AccountContactRelations WHERE Contact_Type__c = 'Primary' AND IsActive=true) FROM Account WHERE Id IN :accIdSet]; // All Accounts and corressponding contacts pre-existing in the system where ID is acclist            
        }
        if(acclist.size() > 0){
            for(Account ac : acclist){
                outletPrimaryContactmap.put(ac.Id, ac.AccountContactRelations.size()>0 ? true : false); //checking if the acc has pre-existing primary contacts
            }    
        }       
        return outletPrimaryContactmap;        
    }
*/
    /*******************************************************************    
    Purpose: The below method generates the MAP for duplicate contact with error message
    ********************************************************************/ 
    /*Commented out for ES20-12548 and ES20-12393
    public static Map<Id,String> populateContactErrorMap(Set<Id> contactIdSet,Set<Id> secondaryContactIdSet, Map<Id,String> contactTypeMap, Set<Id> accIdSet){
        Map<Id,String> duplicateContactErrorMAP = new Map<Id,String>(); 
        List<Contact> parentContactsList = new List<Contact>();
        List<AccountContactRelation> accConRelList = new List<AccountContactRelation>();
        Map<Id,String> existingPrimaryContactMap= new MAP<Id,String>();

        //get parent Contacts List from the AccountContact insertion
        if(contactIdSet != null && contactIdSet.size()>0){
            if(Schema.sObjectType.Contact.isAccessible()) {
                parentContactsList = [SELECT Id,AccountId, Contact_Type__c,Account.Country__r.Code__c FROM Contact WHERE Id IN : contactIdSet AND AccountId IN : accIdSet]; 
            }    
        } 
          
        //get parent primary Contacts           
        if(secondaryContactIdSet != null && !secondaryContactIdSet.isEmpty()){
            if(Schema.sObjectType.AccountContactRelation.isAccessible()) {
*/
                /*ES20-8178: AND IsActive=true
                NCP-3459: Remove NOT from ContactId NOT IN :secondaryContactIdSet & added AccountId NOT IN :accIdSet
                - Due to Contact NOT IN :secondaryContactIdSet, system is returning more than 50K records due to which we are hitting salesforce limit.
                - Also, this is causing another issue if Contact has 2 ACR Record with Contact Type = Primary, when you tried to mark Contact Type = Secondary for 1 ACR it 
                update Contact's Contact Type = Secondary but it should not make Contact's Contact Type = Secondary bcoz in system we still have 1 ACR with Contact Type = Primary
                - WHERE (Contact_Type__c = 'Primary' OR Contact.Contact_Type__c = 'Primary') replaced by WHERE Contact_Type__c = 'Primary' 
                */
    /*
                accConRelList = [SELECT Id,ContactId,Contact_Type__c,Contact.Contact_Type__c 
                                 FROM AccountContactRelation 
                                 WHERE Contact_Type__c = 'Primary' 
                                 AND ContactID IN :secondaryContactIdSet AND IsActive=true AND AccountId NOT IN :accIdSet];
                System.debug('@@accConRelList' + accConRelList.size());
                System.debug('@@accConRelList' + accConRelList);
            }    
        }  
        if(accConRelList != null && !accConRelList.isEmpty()){
            for(AccountContactRelation acr : accConRelList){
                existingPrimaryContactMap.put(acr.ContactId,acr.Contact_Type__c);    
            }    
        }  
        for(Contact con : parentContactsList){
            if(contactTypeMap.get(con.Id) != null){
                // check if the Contact is getting added as Secondary from Primary, 
                // if the contact is already added to a Account as Primary AccountContact,then do not change the Contacts Contype type
                if(!existingPrimaryContactMap.keyset().contains(con.Id)){                        
                    con.Contact_Type__c = contactTypeMap.get(con.Id);
                }
            }           
        }                      
        //update the Contact type of existing related Contact
        Database.SaveResult[] contactUpdateResult; 
        if(parentContactsList != null && !parentContactsList.isEmpty()) {
            contactUpdateResult = Database.update(parentContactsList,false);  
        }        
        if(contactUpdateResult!= null && contactUpdateResult.size()>0){
            for(Integer i=0; i < contactUpdateResult.size(); i++) {
                if(contactUpdateResult.get(i).isSuccess()) {
                    duplicateContactErrorMAP.put(parentContactsList.get(i).Id,'Record saved successfully'); // will move into custom Label
                } 
                else if(!contactUpdateResult.get(i).isSuccess()) {
                    //DML failed
                    Database.Error errors =  contactUpdateResult.get(i).getErrors().get(0);                   
                    duplicateContactErrorMAP.put(parentContactsList.get(i).Id,errors.getMessage()); // contactUpdateResult.get(i).Id giving null
                }   
            }    
        }
        return duplicateContactErrorMAP;
    }
*/
    /*Commented out for ES20-12548 and ES20-12393
    //Update the AccountContactRelation's contact type as Secondary if the Account already has Primary contact
    public static void updateAccountContactType(List<SObject> newItems){        
        Set<Id> accIdSet = new Set<Id>();
        Set<Id> updatedAccIdSet = new Set<Id>();        
        Map<Id, Boolean> outletPrimaryContactmap = new Map<Id,Boolean>();
        for(SObject sob:newItems){
            AccountContactRelation newAccContact = (AccountContactRelation)sob;
            if(newAccContact.Contact_Type__c==null || String.isBlank(newAccContact.Contact_Type__c)){
                accIdSet.add(newAccContact.AccountId);     
            }
        }
        //update the contact type for AccountContact               
        if(accIdSet.size() > 0){
            outletPrimaryContactmap =  getOutletPrimaryContact(accIdSet);  
        }
        for(SObject sob:newItems){
            AccountContactRelation newcon = (AccountContactRelation)sob;
            //Update the AccountContactRelation's contact type as Secondary if the Account already has Primary contact                              
            if(!outletPrimaryContactmap.IsEmpty() && outletPrimaryContactmap.get(newcon.AccountId)){                
                newcon.Contact_Type__c = 'Secondary';    
            }else if(!outletPrimaryContactmap.IsEmpty() && outletPrimaryContactmap.get(newcon.AccountId) == false){ //NCP-5777: If Account dont have any Primary ACR, Update Contact Type of ACR to Primary      
                newcon.Contact_Type__c = 'Primary';    
            }
        }    
    }
*/
    
    //ES20-8178: Update Contact Type = Secondary, if Deactivated Contact dont have any primary AccountContact
    /*Commented out for ES20-12548 and ES20-12393
    public static void updateRelatedContact(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        //When deactivating Primary Outlet-contact, SFDC system should update the contact type on contact as secondary 
        //if there is no more Account-Contact association as Primary
        Map<Id,AccountContactRelation> mapAccConOld,mapAccConNew ;
        Set<Id> contactIdSet = new Set<Id>();
        List<Contact> nonPrimaryContactList = new List<Contact>();        
        if(null != newItems){
            mapAccConNew = (Map<Id,AccountContactRelation>)newItems;   
        }
        if(null != oldItems){
            mapAccConOld = (Map<Id,AccountContactRelation>)oldItems;   
        }
        for(AccountContactRelation acr : mapAccConNew.values()){
            if(mapAccConNew.get(acr.Id).IsActive != mapAccConOld.get(acr.Id).IsActive && mapAccConNew.get(acr.Id).IsActive == false){
                contactIdSet.add(acr.ContactId);    
            }
        }
        //find if deactivationg contact has no more Account-Contact association as Primary
        if(contactIdSet.size()>0){
            nonPrimaryContactList = [SELECT Id,Contact_Type__c FROM Contact WHERE Id IN :contactIdSet AND 
                                     Id NOT IN (SELECT ContactId FROM AccountContactRelation WHERE Contact_Type__c = 'Primary' AND IsActive=true)];    
            for(Contact con : nonPrimaryContactList){
                con.Contact_Type__c = 'Secondary';    
            }            
            if(!nonPrimaryContactList.isEmpty() && nonPrimaryContactList.size()>0){
                update nonPrimaryContactList;   
            }
        }
    }
    */
      /**
    @Description  : indirectContactShare
    @Purpose : This method used to create ContactShare for AccountTeam Members of Account related with Indirect Contact when ACR is created
    @Parameters : Map<Id, SObject> newItems
    */ 
    //ES20-12341-Viewing Indirect child contacts////(CUS-383 line no 301,306,323,329,330)
    public static void indirectContactShare(Map<Id, SObject> newItems,Map<Id, SObject> oldItems){
        
        EDGE_UtilityClass.printGovLimits(285);
        
        Map<Id,AccountContactRelation> mapAccConNew ;
        Map<Id,AccountContactRelation> mapAccConOld ;
        Set<Id> accIdSet = new Set<Id>();
        Set<Id> userSet =new Set<Id>();
        Set<Id> conIdSet = new Set<Id>();
        Map<Id,Set<Id>> accContMap=new Map<Id,Set<Id>>();
        Map<AccountTeamMember,Set<Id>> accTeamMap=new Map<AccountTeamMember,Set<Id>>();
        Map<Id,String> userRoleMap=new Map<Id,String>();
        Map<String,String> roleAccess =new Map<String,String>();
        Set<ContactShare> conShareSet=new Set<ContactShare>();
        List<ContactShare> conShareList=new List<ContactShare>();
        Set<Contact> conUpdateSet = new Set<Contact>();
        List<Contact> conUpdateList = new List<Contact>();
        
        String outletRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        if(null != newItems){
            mapAccConNew = (Map<Id,AccountContactRelation>)newItems;   
        }
        if(null != oldItems){
            mapAccConOld = (Map<Id,AccountContactRelation>)oldItems;   
        }
        
        if(System.Label.shareContactFlag.equals('True')){
            for(AccountContactRelation acr : mapAccConNew.values()){
                
                if((oldItems == null || (oldItems != null && mapAccConNew.get(acr.Id).isDirect != mapAccConOld.get(acr.Id).isDirect)) 
                     && mapAccConNew.get(acr.Id).isDirect==False && mapAccConNew.get(acr.Id).IsActive==True){//Only taking ACR if it's indirect
                     
                    if(accContMap.containsKey(acr.AccountId)){
                        Set<Id> existingCont = accContMap.get(acr.AccountId);
                        existingCont.add(acr.ContactId);
                        accContMap.put(acr.AccountId,existingCont); //Populating a map of Account with indirect Contact list
                    }
                    else {
                        Set<Id> newCont = new Set<Id>();
                        newCont.add(acr.ContactId); 
                        accContMap.put(acr.AccountId,newCont); //Populating a map of Account with indirect Contact list
                    }
                    accIdSet.add(acr.AccountId); // Set of all account ids in context
                }
            }
            
            
            //System.debug('accContMap'+accContMap);
            
            for(AccountTeamMember accMem: [SELECT UserId,AccountId,Account.RecordTypeId from AccountTeamMember WHERE AccountId IN: accIdSet AND Account.RecordTypeId =: outletRecordTypeId]){
                Set<Id> contacts=accContMap.get(accMem.AccountId);
                accTeamMap.put(accMem,contacts); //Map of account member with contacts. accMem = who would need access to the contacts 
                userSet.add(accMem.UserId);
            }
            
            EDGE_UtilityClass.printGovLimits(326);
            
            //System.debug('accTeamMap'+accTeamMap);
            
            //Get Access Type from Custom Metdata for Business Roles
            for(Role_Contact_Access_Setting__mdt ra:[Select MasterLabel,Access_Type__c from Role_Contact_Access_Setting__mdt]){
                roleAccess.put(ra.MasterLabel,ra.Access_Type__c);
            }
            for(User_Business_Role__c ubr:[Select User__c,Business_Role__r.Global_Equivalent__c From User_Business_Role__c Where User__c IN:userSet]){
                userRoleMap.put(ubr.User__c,ubr.Business_Role__r.Global_Equivalent__c);
            }
            //Iterating over Accounts to create Contact Share for every Account team member(Specific business roles) with Indirect Contact
            for(AccountTeamMember atm : accTeamMap.keySet()){
                Set<Id> conIds=accTeamMap.get(atm);
                Id usr = atm.UserId;     
                for(Id conId:conIds){
                    if(userRoleMap.get(usr) != null && roleAccess.containsKey(userRoleMap.get(usr))){
                        ContactShare conShr=new ContactShare();
                        conShr.ContactId=conId;
                        conShr.UserOrGroupId=usr;
                        conShr.ContactAccessLevel=roleAccess.get(userRoleMap.get(usr));
                        conShareSet.add(conShr);
                        conIdSet.add(conShr.ContactId); //ES20-12476/ES20-12682 -> Creating a set of contactIds whose Contact_Shared__c flag needs to be updated
                    }
                }
            }
            System.debug('@@@conIdSet'+conIdSet);


            


            //ES20-12476/ES20-12682 -> Setting the Contact_Shared__c flag to true and storing in a set to update later
            for(Contact con : [SELECT Id, Contact_Shared__c FROM Contact WHERE Id IN : conIdSet AND Contact_Shared__c = FALSE]){
                con.Contact_Shared__c = TRUE;
                conUpdateSet.add(con);
            }
            
            //ES20-12476/ES20-12682 -> Updating Contact records
            if(conUpdateSet!=null && conUpdateSet.size()>0){
                conUpdateList.addAll(conUpdateSet);
                Database.update(conUpdateList, false);
            }

            if(!conShareSet.isEmpty() && conShareSet.size()>0){
                conShareList.addAll(conShareSet);
                List<Database.SaveResult> srList = Database.insert(conShareList,false);
                
                // Iterate through each returned result
                for (Database.SaveResult sr : srList) {
                    if (!sr.isSuccess()) {
                        // Operation failed, so get all errors 
                        System.debug('error details : '+ sr.getErrors());
                    }
                }
            }
            
            EDGE_UtilityClass.printGovLimits(367);
        }
    }
    /**
    @Description  : syncOutletRole - ES20-12653
    @Purpose : This method used to Map the Roles Field to Current Outlet Role Field in the Contact object for the Contacts who are Direct Childs of the Outlet
    @Parameters : Map<Id, SObject> newItems
    */
    public static void syncOutletRole(Map<Id, SObject> newItems){
        //Assignment
        //Map<Id,AccountContactRelation> mapAccConNew ;
        List<AccountContactRelation> newACRList;
        List<AccountContactRelation> accConRelList;
        Set<Id> conIdSet = new Set<Id>();
        Set<Id> aCRIdSet = new Set<Id>();
        Map<Id,Contact> contactMap  = new Map<Id,Contact>();
        Map<Id, AccountContactRelation> accConReMap = new Map<Id, AccountContactRelation>();
        Map<Id, AccountContactRelation> accountContactRelMap = new Map<Id, AccountContactRelation>();
        
        if(newItems != null){
            newACRList = (List<AccountContactRelation>)newItems.values();
        }
        
        //Creating Sets of Contact Id's and ACR Id's
        if(newACRList != null && newACRList.size()> 0){
            for(AccountContactRelation newACR: newACRList){
                aCRIdSet.add(newACR.Id);
                conIdSet.add(newACR.ContactId);
            }   
        }
        
        //Fetching Contacts of ACR's to get the Current Outlet Role and Creating a Map
        if(conIdSet != null && conIdSet.Size() > 0){
            for(Contact conRec : [SELECT Id,Name,MD_CurrentRole__c FROM Contact WHERE Id =:conIdSet]){
                contactMap.put(conRec.Id,conRec);
            }
        }
        
        //Querying inserted ACR's to get required fields and Creating a Map
        if(aCRIdSet != null && aCRIdSet.Size() > 0){
            for(AccountContactRelation aCRRec : [SELECT Id,ContactId,IsDirect,Roles FROM AccountContactRelation 
                                                 WHERE Id =:aCRIdSet])
            {
                accConReMap.put(aCRRec.Id,aCRRec);
            }
        }
        
        if(accConReMap.size() > 0){
            accConRelList = (List<AccountContactRelation>)accConReMap.values();
        }
        
        //Iterate over ACR records to Map Roles Field with Current Outlet Role of Direct Contacts
        if(accConRelList != null && accConRelList.Size()> 0){            
            for(AccountContactRelation accConRelRec : accConRelList){ 
                Contact conRec = contactMap.get(accConRelRec.ContactId);
                if(conRec != null && accConRelRec.IsDirect == true){
                    if(conRec.MD_CurrentRole__c != null){
                        accConRelRec.Roles = conRec.MD_CurrentRole__c;
                        accountContactRelMap.put(accConRelRec.Id,accConRelRec);
                    }
                }
            }
        }
        
        //Updating the AccountContactRelationship Records
        if( accountContactRelMap != null && !accountContactRelMap.isEmpty() && Schema.sObjectType.AccountContactRelation.isUpdateable()){
            Database.update(accountContactRelMap.values(),false);  
        }
        
    }
    
    /**
    @Description  : updateDirectContactRoleFields - ES20-12654
    @Purpose : This method used to reverse sync of roles field of updated acr to Outlet role of contact 
    @Parameters : List<AccountContactRelation>newacrList , Map<Id, SObject> oldItems
    */
    public static void updateDirectContactRoleFields(List<AccountContactRelation>newacrList,Map<Id,SObject>oldItems){
        Set<Id> contactIds = new Set<Id>();
		Set<Id> acrIds = new Set<Id>();
        Map<Id,AccountContactRelation> acrMap = new Map<Id,AccountContactRelation>();
        List<Contact> updatedconList = new List<Contact>();
        Map<Id,AccountContactRelation> oldacrMap = (Map<Id,AccountContactRelation>)oldItems;
        
        
        //Iterate Over new updated ACR to check whether role is changed or not and if it is changed then we are adding it within a list
        if (newacrList != null &&  newacrList.size() > 0){
            for(AccountContactRelation newACR : newacrList){
                if (oldacrMap.get(newACR.Id).Roles != newACR.Roles && newACR.IsDirect == TRUE) {
                    contactIds.add(newACR.ContactId);
                    acrMap.put(newACR.ContactId, newACR);
                }
            }
        }
        
        //Iterate over Direct contact records Corresponding to UpdatedAccountContact to assign new Role value to Direct contact records
        if (contactIds != null && contactIds.size() > 0){
            for (Contact con:[SELECT Id,MD_CurrentRole__c  FROM Contact Where Id IN:contactIds]){
                if (con.MD_CurrentRole__c != acrMap.get(con.Id).Roles){
                    con.MD_CurrentRole__c = acrMap.get(con.Id).Roles ;
                    updatedconList.add(con);
                }
            }
        }
        
        //Updating the Contact Records
        if (!updatedconList.isEmpty() && updatedconList.size() > 0 && Schema.SObjectType.Contact.isUpdateable()){
            database.update(updatedconList, false);
        }
        system.debug('updatedconList::'+updatedconList);
    }

}