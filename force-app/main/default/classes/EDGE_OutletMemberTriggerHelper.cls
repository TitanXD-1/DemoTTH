/**
* @Description: EDGE_OutletMemberTriggerHelper


* @Purpose:  Helper class for EDGE_OutletMemberPrimaryInsertBatch - User Story : ES20-3022 -> Populate details


* @History:                                                            

* @VERSION   AUTHOR              	DATE              DETAIL

* 1.0    	Anuja Chattopadhyay   04/07/2019      Initial Development
* 1.2	    Shahbaz Khan		  1/11/2020		  populate Activation Specialist and Activation Territory [ES20-8796]
* 1.2    	Juned Khan            11/11/2020      ES20-8865 updated   removePrimarySalesDetails
* 1.3    	Juned Khan            04/12/2020      remove Activation Specialist and Activation Territory [ES20-8780]  
* 1.4    	Juned Khan			  21/12/2020      ES20-9163 updated 	removePrimarySalesDetails to remove only Primary_Sales_Rep__c
* 1.5    	Juned Khan			  15/03/2021	  ES20-9961 Outlet removal from territory batch is failing.
* 1.6	    Aparajita/Rajarshi     11/03/2022	  ES20-12216,12231,12213

			/Subhodeep 
* 1.7		Aparajita			  08/04/2022	  ES20-12436(Method:removeContactSharing)
* 1.8       Saranya L			  08/04/2022	  ES20-12449(Method:createContactSharing)
* 1.9		Aparajita    		  27/04/2022      ES20-12476(Method:createContactSharing - modified)
* 2.0       Joshraj Sen           30/06/2022      ES20-13086(Method removePrimarySalesDetails Need to create separate lists for Activation and Sales Territories)
* 2.1       Swaraj Samanta        05/08/2022      ES20-13206(Method removePrimarySalesDetails Corrected Line 196 where  accountListToUpdate has been replaced  accountListToUpdateSales and  accountListToUpdateActivation)   
* 2.2       Priya Soni            04/11/2022      ES20-13469(Method populatePrimarySalesDetails, populate Dispense rep field in Account Object when Primary Territory member is added to Dispense Territory)   
* 2.3       Prasanth T           19/12/2022      ES20-13483(Method removePrimarySalesDetails, remove Dispense rep field in Account Object when Primary Territory member is removed from Dispense Territory)   
*/

public with sharing class EDGE_OutletMemberTriggerHelper {   
    
    //ES20-12216,12231,12213
    final static String SalesRecordTypeId = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Sales Territory').getRecordTypeId();     
    final static String ActivationRecordTypeId = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Activation Territory').getRecordTypeId();
    
    /**
@Description  : populatePrimarySalesDetails
@Purpose : This method used to populate primary sales details on outlet when outlet member gets inserted or updated 
@Parameters : List<Outlet_Member__c> newItems, Map<Id, SObject> oldItems
*/ 
    
    public static void populatePrimarySalesDetails(List<Outlet_Member__c> newItems, Map<Id, SObject> oldItems){
        //Variables
        Date currentDate = Date.today();
        Date yesterdayDate = currentDate.addDays(-1); 
        Set<Id> userIdSet = new Set<Id>();
        Set<Id> outletIdSet = new Set<Id>();
        Set<Id> territoryIdSet = new Set<Id>();

        List<Account> outletList = new  List<Account>();
        //Set<Account> accountListToUpdate = new Set<Account>();// ES20-9961 Outlet removal from territory batch is failing
        Map<Id,Outlet_Member__c> oldOutMemMap; 
        Map<Id,Outlet_Member__c> userOutletMemberMap = new Map<Id,Outlet_Member__c>();
        Map<Id,Outlet_Member__c> actSpecOutletMemberMap = new Map<Id,Outlet_Member__c>();//map to store activation specialist user along with Outlet [ES20-8796]
        Map<Id,Outlet_Member__c> disRepOutletMemberMap = new Map<Id,Outlet_Member__c>();//ES20-13469 - map to store Dispense Rep user along with Outlet
        Map<Id,String> territoryToPrimaryMemberMap = new Map<Id,String>(); //ES20-13469 - map to strore territory id to corresponding User of Primary Territory Member of Dispense Territory
        Map<Id,Map<String,Outlet_Territory__c>> outletTerrMemberMap = new Map<Id,Map<String,Outlet_Territory__c>>();//ES20-13469
        Map<Id,Account> accountIdAccountRecMap = new Map<Id,Account>();
        
        
        if(oldItems!=null){
            oldOutMemMap = (Map<Id,Outlet_Member__c>)oldItems;
        }
        
        EDGE_UtilityClass.printGovLimits(36);

        //If the inserted/updated outlet members are primary,prepare user outlet member map 
        for(Outlet_Member__c outMemObj:newItems){

            if(oldOutMemMap==null || (oldOutMemMap!=null && oldOutMemMap.get(outMemObj.id).Outlet_Role__c != outMemObj.Outlet_Role__c )){
                if(outMemObj.Outlet_Role__c == 'Primary'){
                    outletIdSet.add(outMemObj.Outlet__c);
                    userOutletMemberMap.put(outMemObj.Outlet__c,outMemObj);
                    userIdSet.add(outMemObj.User__c);

                }//store activation specialist user along with Outlet [ES20-8796]
                else if(outMemObj.Outlet_Role__c == 'Activation Specialist'){
                    outletIdSet.add(outMemObj.Outlet__c);
                    actSpecOutletMemberMap.put(outMemObj.Outlet__c,outMemObj);
                    userIdSet.add(outMemObj.User__c);

                }
                //ES20-13469
                else if(outMemObj.Outlet_Role__c == 'Dispense Rep' && outMemObj.Temporary_Assigned__c == false){
                    outletIdSet.add(outMemObj.Outlet__c);
                    disRepOutletMemberMap.put(outMemObj.Outlet__c,outMemObj);
                    userIdSet.add(outMemObj.User__c);
                    
                }
            }
        }

        //EDGE_UtilityClass.printGovLimits(54);
        
        //Fetch all the active outlet territory for the associated outlets && added Territory__r.Activation_Territory__c as part of [ES20-8796]
        //Added Schema.sObjectType.Outlet_Territory__c.isAccessible() && Schema.sObjectType.Territory__c.isAccessible() --by Divya
        //ES20-13469- Changed the logic to preapre outletTerrMemberMap
        if(Schema.sObjectType.Outlet_Territory__c.isAccessible() && Schema.sObjectType.Account.isAccessible() && Schema.sObjectType.Territory__c.isAccessible() ){
            for(Outlet_Territory__c outTerObj: [Select Id,Outlet__c,Territory__c, Territory__r.Territory_Type__c, Territory__r.Region__c,Territory__r.Region__r.Parent_BU__c, //new
                                                Territory__r.Activation_Territory__c,Territory__r.Region__r.Parent_BU__r.Parent_BU__c FROM Outlet_Territory__c
                                                where Outlet__c in : outletIdSet AND (Territory__r.Territory_Type__c='Sales' OR Territory__r.Territory_Type__c='Activation Territory' OR Territory__r.Territory_Type__c='Quality Dispense') AND Active__c ='Active']){ //ES20-12216,12231,12213
                                                    territoryIdSet.add(outTerObj.Territory__c);
                                                    if(!outletTerrMemberMap.containsKey(outTerObj.Outlet__c)){
                                                        Map<String,Outlet_Territory__c> outletTerrMemberInnerMap = new Map<String,Outlet_Territory__c>();
                                                        outletTerrMemberInnerMap.put(outTerObj.Territory__r.Territory_Type__c, outTerObj);
                                                        outletTerrMemberMap.put(outTerObj.Outlet__c, outletTerrMemberInnerMap);
                                                    }else{
                                                        Map<String,Outlet_Territory__c> outletTerrMemberInnerMap = outletTerrMemberMap.get(outTerObj.Outlet__c);
                                                        outletTerrMemberInnerMap.put(outTerObj.Territory__r.Territory_Type__c, outTerObj);
                                                    }
                                                }
        }
        if (schema.SObjectType.Account.isAccessible()){
            outletList = [Select Id, Name, Primary_Sales_Area__c, Primary_Sales_Territory__c,Activation_Territory_LT__c,Activation_Specialist__c, //ES20-12216,12231,12213
                          Primary_Sales_Territory_Region__c, Primary_Sales_Territory_Business_Unit__c ,Dispense_Rep__c
                          from Account where Id In : outletIdSet];
        }
        
        //ES20-13469
        for(Territory_Member__c terMemObj :[SELECT Id,Type__c,User__c,Name,User__r.Name,Territory__c FROM Territory_Member__c 
                                            WHERE Territory__c IN:territoryIdSet AND Start_Date__c <= :currentDate
                                            AND (End_Date__c >= :yesterdayDate OR End_Date__c=null) AND Type__c = 'Primary' 
                                            AND Territory__r.Territory_Type__c='Quality Dispense'
                                            ORDER BY Start_Date__c])
        {
            if (terMemObj.Territory__c != null && terMemObj.User__r.Name != null){
                territoryToPrimaryMemberMap.put(terMemObj.Territory__c,terMemObj.User__r.Name);
            }
        }
        
        //EDGE_UtilityClass.printGovLimits(72);
        //Iterate over all the associated outlets to populate primary sales related fields
        if(outletList != null && outletList.size()>0){
            for(Account accObj : outletList){
                //Map
                //for Sales territory
                if (outletTerrMemberMap.get(accObj.Id)!=null){//to pick outlets that have OT
                    
                    Map<String,Outlet_Territory__c> outletTerrMemberInnerMap = outletTerrMemberMap.get(accObj.Id);
                    if(userOutletMemberMap!=null && userOutletMemberMap.size()>0 
                       && userOutletMemberMap.containsKey(accObj.Id) && outletTerrMemberInnerMap.containsKey('Sales'))
                    {
                        accObj.Primary_Sales_Rep__c = userOutletMemberMap.get(accObj.Id).User__c;
                        accObj.Primary_Sales_Territory__c = outletTerrMemberInnerMap.get('Sales').Territory__c;
                        accObj.Primary_Sales_Territory_Region__c = outletTerrMemberInnerMap.get('Sales').Territory__r.Region__c;
                        accObj.Primary_Sales_Area__c = outletTerrMemberInnerMap.get('Sales').Territory__r.Region__r.Parent_BU__c;
                        accObj.Primary_Sales_Territory_Business_Unit__c = outletTerrMemberInnerMap.get('Sales').Territory__r.Region__r.Parent_BU__r.Parent_BU__c;
                    }
                    if(actSpecOutletMemberMap!=null && actSpecOutletMemberMap.size()>0 
                       && actSpecOutletMemberMap.containsKey(accObj.Id) && 
                       actSpecOutletMemberMap.get(accObj.Id) != null 
                       && outletTerrMemberInnerMap.containsKey('Activation Territory'))
                    { //ES20-12216,12231,12213
                        accObj.Activation_Specialist__c = actSpecOutletMemberMap.get(accObj.Id).User__c;
                        accObj.Activation_Territory_LT__c  = outletTerrMemberInnerMap.get('Activation Territory').Territory__c;//new added as part of ES20-12213
                    }
                    //ES20-13469
                    if(disRepOutletMemberMap!=null && disRepOutletMemberMap.size()>0 
                       && disRepOutletMemberMap.containsKey(accObj.Id)
                       && outletTerrMemberInnerMap.containsKey('Quality Dispense')){
                           //ES20-13483
                           ID territoryId = outletTerrMemberInnerMap.get('Quality Dispense').Territory__c;
                           if (territoryToPrimaryMemberMap.get(territoryId) != null){
                               accObj.Dispense_Rep__c = territoryToPrimaryMemberMap.get(territoryId);
                           }                         
                       }
                    
                    if(accountIdAccountRecMap.containsKey(accObj.Id)){
                        accountIdAccountRecMap.put(accObj.Id,accObj);
                    }else{
                        accountIdAccountRecMap.put(accObj.Id,accObj);
                    }
                }
            }
        }
        
        
        EDGE_UtilityClass.printGovLimits(94);
        
        if(!accountIdAccountRecMap.isEmpty() && accountIdAccountRecMap.size()>0 && Schema.sObjectType.Account.isUpdateable()){
            // ES20-9961 Outlet removal from territory batch is failing.
            List<Account> accountFinalListToUpdate = new List<Account>();
            accountFinalListToUpdate.addAll(accountIdAccountRecMap.values());
            Database.update(accountFinalListToUpdate, false);
        }
        
        EDGE_UtilityClass.printGovLimits(99);
    }
    
    /**
@Description  : removePrimarySalesDetails
@Purpose : This method used to remove primary sales details from outlet when outlet member gets deleted
@Parameter : List<Outlet_Member__c> newItems,Map<Id, SObject> oldItems
*/       
    public static void removePrimarySalesDetails(List<Outlet_Member__c> newItems,Map<Id, SObject> oldItems){
        
        //Variables
        Set<Id> outletIdSet = new Set<Id>();
        Map<Id,Outlet_Member__c> oldOutMemMap;
        //Set<Account> accountListToUpdate = new Set<Account>();// ES20-9961 Outlet removal from territory batch is failing.
        //Set<Account> accountListToUpdateSales = new Set<Account>();//ES20-13086 Outlet Set for Sales Territory
        //Set<Account> accountListToUpdateActivation = new Set<Account>();//ES20-13086 Outlet Set for Activation Territory
        //Set<Account> accountListToUpdateDispenseRep = new Set<Account>();//ES20-13086 Outlet Set for Activation Territory
        Map<Id,Id> outletToOldPrimarySRMap = new Map<Id,Id>();
        Map<Id,Id> outletToOldActivatonSpecMap = new Map<Id,Id>();//added by juned for Activation Specialist ES20-8780
        Map<Id,String> outletToOldDispenseRepSpecMap=new Map<Id,String>();
        Map<Id,Account> accountIdAccountRecRemovalMap = new Map<Id,Account>();
        
        if(oldItems!=null){
            oldOutMemMap = (Map<Id,Outlet_Member__c>)oldItems;
        }
        
        //Added by juned for Bug ES20-8865 11-Nov-2020
        for(Id outMemId : oldOutMemMap.keySet()){
            if(oldOutMemMap.get(outMemId).Outlet_Role__c == 'Primary'){
                Id outletId = oldOutMemMap.get(outMemId).Outlet__c;
                Id primarySRId = oldOutMemMap.get(outMemId).User__c;
                outletIdSet.add(outletId);
                outletToOldPrimarySRMap.put(outletId,primarySRId);
            }
            
            //check for AS related outlet members ES20-8780
            if(oldOutMemMap.get(outMemId).Outlet_Role__c == 'Activation Specialist'){
                Id outletId = oldOutMemMap.get(outMemId).Outlet__c;
                Id asUserId = oldOutMemMap.get(outMemId).User__c; 
                outletIdSet.add(outletId);
                outletToOldActivatonSpecMap.put(outletId,asUserId);   
            }
            //ES20-13483
            if(oldOutMemMap.get(outMemId).Outlet_Role__c == 'Dispense Rep'){
                Id outletId = oldOutMemMap.get(outMemId).Outlet__c;
                Id disUserId = oldOutMemMap.get(outMemId).User__c;
                outletIdSet.add(outletId);
                outletToOldDispenseRepSpecMap.put(outletId,disUserId);   
            }
        }
        
        List<Account> outletList = [Select Id,Primary_Sales_Rep__c,Name,Primary_Sales_Area__c,Primary_Sales_Territory__c,
                                    Primary_Sales_Territory_Region__c,Primary_Sales_Territory_Business_Unit__c,Activation_Territory_LT__c,Dispense_Rep__c,Activation_Specialist__c/* //include AS and AT fields of Account ES20-8780 */
                                    from Account where Id In : outletIdSet];
        //ES20-13483
        Map<Id,User>userNameuserIdMap=new Map<Id,User>([Select Id,Name from User where id in :outletToOldDispenseRepSpecMap.values()]);
        
        //Iterate over all the associated outlets to remove primary sales related fields
        if(outletList != null && outletList.size()>0){
            for(Account accObj : outletList){
                //Added by juned for Bug ES20-8865 11-Nov-2020
                if(outletToOldPrimarySRMap.containsKey(accObj.Id) && accObj.Primary_Sales_Rep__c == outletToOldPrimarySRMap.get(accObj.Id)){
                    accObj.Primary_Sales_Rep__c = null;
                    //accountListToUpdateSales.add(accObj);//ES20-13086 Outlet Set for Sales Territory
                    //ES20-9163  Commenting this part,if outlet is associated with territory and terrmem is just getting removed below fields should still be populated in outlet 
                    /* accObj.Primary_Sales_Territory__c = null;
					accObj.Primary_Sales_Territory_Region__c = null;
					accObj.Primary_Sales_Area__c = null;
					accObj.Primary_Sales_Territory_Business_Unit__c = null;
					*/
                    
                } 
                // (OLD)if outlet member needs to be remove for that AS role then remove AS and AT from outlet ES20-8780 
                // (Modification of previous comment)w.r.t (ES20-12216,12231,12213) only AS should be removed when the OT is Active and TM has expired
                if(outletToOldActivatonSpecMap.containsKey(accObj.Id) && accObj.Activation_Specialist__c == outletToOldActivatonSpecMap.get(accObj.Id)){ //new
                    accObj.Activation_Specialist__c = null;
                    // accountListToUpdateActivation.add(accObj);//ES20-13086 Outlet Set for Activation Territory
                }
                //ES20-13483
                if(outletToOldDispenseRepSpecMap.containsKey(accObj.Id) && userNameuserIdMap.containsKey(outletToOldDispenseRepSpecMap.get((accObj.Id))) && accObj.Dispense_Rep__c ==  userNameuserIdMap.get(outletToOldDispenseRepSpecMap.get(accObj.Id)).Name)//ES20-13483
                {
                    accObj.Dispense_Rep__c = null;
            }
                accountIdAccountRecRemovalMap.put(accObj.Id, accObj);
        }
        }/*
        if(((!accountListToUpdateSales.isEmpty() && accountListToUpdateSales.size()>0)||(!accountListToUpdateActivation.isEmpty() && accountListToUpdateActivation.size()>0)) && Schema.sObjectType.Account.isUpdateable()){//ES20-13206 Replacing accountListToUpdate with accountListToUpdateSales and accountListToUpdateActivation 
            // ES20-9961 Outlet removal from territory batch is failing.
            List<Account> accountFinalListToUpdate = new List<Account>();
            if(!accountListToUpdateSales.isEmpty() && accountListToUpdateSales.size()>0)
            {
            accountFinalListToUpdate.addAll(accountListToUpdateSales);//ES20-13086 Outlet Set for Sales Territory
            Database.update(accountFinalListToUpdate, false);//ES20-13086 Update Outlet Set for Sales Territory
            }
            if(!accountListToUpdateActivation.isEmpty() && accountListToUpdateActivation.size()>0)
            {
            accountFinalListToUpdate.clear();//ES20-13086 Clearing the list of Sales Territories
            accountFinalListToUpdate.addAll(accountListToUpdateActivation);//ES20-13086 Outlet Set for Activation Territory
            Database.update(accountFinalListToUpdate, false);//ES20-13086 Update Outlet Set for Activation Territory
        }
}*/
        //ES20-13483
        if(!accountIdAccountRecRemovalMap.isEmpty() && accountIdAccountRecRemovalMap.size()>0 && Schema.sObjectType.Account.isUpdateable()){
            List<Account> accountFinalListToUpdate = new List<Account>();
            accountFinalListToUpdate.addAll(accountIdAccountRecRemovalMap.values());
            Database.update(accountFinalListToUpdate, false);
    }
    }
    
    /*
* @description: removeContactSharing -> ES20-12436
* @purpose: Removing deleted outlet member's access to indirect contacts
* @parameters: List<Outlet_Member__c> oldItems
*/
    
    public static void removeContactSharing(List<Outlet_Member__c> oldItems){
        
        //Assignment
        Set<Id> accIdSet = new Set<Id>();
        Set<Id> userIdSet = new Set<Id>();
        Set<ContactShare> conShareToDeleteSet = new Set<ContactShare>();
        List<ContactShare> conShareToDeleteList = new List<ContactShare>();
        Map<Id,Id> usrAccountMap = new Map<Id,Id>();
        Boolean shareContactFlag = Boolean.valueOf(Label.shareContactFlag);
        
        //Creating sets of outlet members' userIds and outletIds and mapping them
        if(shareContactFlag){
            if(oldItems!=null && oldItems.size()>0){
                for(Outlet_Member__c om : oldItems){
                    accIdSet.add(om.Outlet__c);
                    userIdSet.add(om.User__c);
                    usrAccountMap.put(om.User__c, om.Outlet__c); 
                }
            }           
            
            //Fetching the ContactShare records which are associated with indirect contacts of the deleted outlet members' outlets
            if(accIdSet!=null && accIdSet.size()>0 && userIdSet!=null && userIdSet.size()>0){
                for(ContactShare conShare : [Select ContactId, Contact.AccountId, Contact.Contact_Type__c, UserOrGroupId from ContactShare 
                                             WHERE UserOrGroupId IN : userIdSet AND ContactId IN (SELECT ContactId FROM AccountContactRelation 
                                             WHERE AccountId IN : accIdSet AND IsDirect = FALSE AND IsDeleted = FALSE AND IsActive = TRUE)])
                {
                    if(conShare.Contact.AccountId != usrAccountMap.get(conShare.UserOrGroupId))
                        conShareToDeleteSet.add(conShare);
                }
            }
        }
        
        //Delete the ContactShare records
        if(conShareToDeleteSet!=null && conShareToDeleteSet.size()>0){
            conShareToDeleteList.addAll(conShareToDeleteSet);
            Database.delete(conShareToDeleteList, false);
        }
        EDGE_UtilityClass.printGovLimits(224);
    }
    
        /*
    * @description: createContactSharing  ES20-12449
    * @purpose: Giving outlet member's access to indirect contacts
    * @parameters: List<Outlet_Member__c> newItems
    */
    public static void createContactSharing(List<Outlet_Member__c> newItems, List<Outlet_Member__c> oldItems){
        
        Set<Id> accIdSet = new Set<Id>();
        Set<Id> userIdSet = new Set<Id>();
        Set<Id> conIdSet = new Set<Id>();
        Set<Contact> conUpdateSet = new Set<Contact>();
        List<Contact> conUpdateList = new List<Contact>();
        List<ContactShare> conShare=new List<ContactShare>();
        Map<Id,List<Id>> outletMemMap=new Map<Id,List<Id>>();
        Map<Id,String> userRoleMap=new Map<Id,String>();
        Map<String,String> roleAccess =new Map<String,String>();
        
        //Creating sets of outlet members' userIds and outletIds and mapping them
        if(System.Label.shareContactFlag.equals('True')){
            if(newItems!=null && newItems.size()>0){
                for(Outlet_Member__c om : newItems){
                    accIdSet.add(om.Outlet__c);
                    userIdSet.add(om.User__c);
                    if(outletMemMap.containsKey(om.Outlet__c)){
                        List<Id> existingUser = outletMemMap.get(om.Outlet__c);
                        existingUser.add(om.User__c);
                        outletMemMap.put(om.Outlet__c,existingUser); 
                    }else {
                        List<Id> newUser = new List<Id>();
                        newUser.add(om.User__c); 
                        outletMemMap.put(om.Outlet__c,newUser); 
                    }
                }
            }
            
            // Fetching the Account contact relationship records which are associated with the indirect contacts of outlet member's outlets
            List<AccountContactRelation> accConList=  [SELECT id,AccountId,ContactId from AccountContactRelation 
                                                       where AccountId IN :accIdSet AND IsActive=True AND isDirect=False ];
            
            // Feching the user's Business Role and mapping the user with gloabl equivalent
            if(userIdSet!=null && userIdSet.size()>0){
                for(User_Business_Role__c ubr : [Select User__c,Business_Role__r.Global_Equivalent__c From User_Business_Role__c Where User__c IN : userIdSet]){
                    userRoleMap.put(ubr.User__c,ubr.Business_Role__r.Global_Equivalent__c);
                }
            }
            
            //Get Access Type from Custom Metdata for Business Roles
            for(Role_Contact_Access_Setting__mdt ra:[Select MasterLabel,Access_Type__c from Role_Contact_Access_Setting__mdt]){
                roleAccess.put(ra.MasterLabel,ra.Access_Type__c);
            }
            
            if(accConList!=null && accConList.size()>0){
                for(AccountContactRelation acr: accConList){
                    if(outletMemMap.containsKey(acr.AccountId)){
                        for(Id usrId : outletMemMap.get(acr.AccountId)){
                            if(roleAccess.containsKey(userRoleMap.get(usrId))){
                                ContactShare conShr=new ContactShare();
                                conShr.ContactId=acr.ContactId;
                                conShr.UserOrGroupId=usrId;
                                conShr.ContactAccessLevel=roleAccess.get(userRoleMap.get(usrId));
                                conShare.add(conShr);
                                conIdSet.add(conShr.ContactId); //ES20-12476 -> Creating a set of contactIds whose Contact_Shared__c flag needs to be updated
                            }
                        }
                    }
                    
                }
            }
        }
        
        //ES20-12476 -> Setting the Contact_Shared__c flag to true and storing in a set to update later
        for(Contact con : [SELECT Id, Contact_Shared__c FROM Contact WHERE Id IN : conIdSet AND Contact_Shared__c = FALSE]){
            con.Contact_Shared__c = TRUE;
            conUpdateSet.add(con);
        }
        
        //ES20-12476 -> Updating Contact records
        if(conUpdateSet!=null && conUpdateSet.size()>0){
            conUpdateList.addAll(conUpdateSet);
            Database.update(conUpdateList, false);
        }
        
        // Creation of contactshare records
        if(!conShare.isEmpty() && conShare.size()>0){
            Database.insert(conShare,false);
        }
        EDGE_UtilityClass.printGovLimits(316);   
    }
}