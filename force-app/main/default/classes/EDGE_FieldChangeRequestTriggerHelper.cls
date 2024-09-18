/*
Name: EDGE_FieldChangeRequestTriggerHelper
Req: 
ES20-628 - Outlet Management - Edit Outlet Attributes Approval Process- MDM Approval
ES20-632 - Outlet Management - Edit Outlet Attributes Approval Process- Sales Manager Approval

History                                                            
                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0       Sandeep Sahoo     30/04/2019        Initial Development
2.0		  Preyanka Ghosh	21/05/2019		  ES20-1615
3.0       Juned Khan        12/10/2020        ES20-8621 (Updated updateSobjectFields method to include PERCENT logic)
4.0		  Swaraj Samanta	26/09/2022		  ES20-12995 (added sendPushNotificationForApprovedRejectedFCR method)
5.0       Shivam Chauhan	27/12/2023	      148622 - Define Approvers in Approval Flow for Strategic Fit updates based on FPS Setting

*/

public with sharing class EDGE_FieldChangeRequestTriggerHelper {
    
    /*
Method  : updateAccountFieldUpdates
Purpose : This method is used to update Outlet Fields after Approval Process approves.
*/  
    public static void approveFieldUpdateRequests(List<SObject> fcrNewList, Map<Id,SObject> oldMap, Boolean isUpdate){
        Map<Id,List<Field_Change_Request__c>> fcrOutletValueMap = new Map<Id,List<Field_Change_Request__c>>();//Map to contain Outlet,FCR Records
        Map<Id,List<Field_Change_Request__c>> fcrLicenseValueMap = new Map<Id,List<Field_Change_Request__c>>();
        Map<Id,List<Field_Change_Request__c>> fcrSupplierOutletValueMap = new Map<Id,List<Field_Change_Request__c>>();
        Map<Id,List<Field_Change_Request__c>> fcrOutletStrategicValueMap = new Map<Id,List<Field_Change_Request__c>>();//148622
        List<Field_Change_Request__c> childFCRList = new List<Field_Change_Request__c>();
        List<Field_Change_Request__c> fcrTempList;
        Set<Id> parentFCRIdset = new Set<Id>();
        Map<Id,List<Field_Change_Request__c>> childFCRMap = new Map<Id,List<Field_Change_Request__c>>();
        for(SObject sObj : fcrNewList){
            Field_Change_Request__c newFCR = (Field_Change_Request__c)sObj;
            Field_Change_Request__c oldFCR = (Field_Change_Request__c)oldmap.get(newFCR.Id);
            if(newFCR.Status__c == 'Approved' && oldFCR.Status__c != 'Approved' && newFCR.Object_Type__c == 'Account' && newFCR.Approval_Header__c){
                parentFCRIdset.add(newFCR.Id);    
            }    
        }
        if(Schema.sObjectType.Field_Change_Request__c.isAccessible()) {
            childFCRList = [SELECT Id,Field_Name__c,Field_Type__c, Parent_Approval__c, New_Value__c FROM Field_Change_Request__c WHERE Parent_Approval__c IN : parentFCRIdset];
        }
        //create the Map
        for(Field_Change_Request__c fcr : childFCRList){
            fcr.Status__c= 'Approved';
            if(!childFCRMap.isEmpty() && childFCRMap.containsKey(fcr.Parent_Approval__c)){
                childFCRMap.get(fcr.Parent_Approval__c).add(fcr);    
            }else{
                childFCRMap.put(fcr.Parent_Approval__c,new List<Field_Change_Request__c>{fcr});  
            }
        }
        for(SObject sObj : fcrNewList){
            Field_Change_Request__c newFCR = (Field_Change_Request__c)sObj;
            Field_Change_Request__c oldFCR = (Field_Change_Request__c)oldmap.get(newFCR.Id);            
            if(newFCR.Status__c == 'Approved' && oldFCR.Status__c != 'Approved' && newFCR.Object_Type__c == 'Account'){                              
                if(fcrOutletValueMap.containsKey(newFCR.Outlet__c)){
                    fcrTempList = fcrOutletValueMap.get(newFCR.Outlet__c);    
                }  
                else{
                    fcrTempList = new List<Field_Change_Request__c>();    
                }
                fcrTempList.add(newFCR);
                if(!childFCRMap.isEmpty() && childFCRMap.containsKey(newFCR.Id)){
                    fcrTempList.addAll(childFCRMap.get(newFCR.Id));    
                }
                fcrOutletValueMap.put(newFCR.Outlet__c,fcrTempList);// Map to contain Outlet,FCR Records
            }else if(newFCR.Status__c == 'Approved' && oldFCR.Status__c != 'Approved' && newFCR.Object_Type__c == 'License__c'){
                if(fcrLicenseValueMap.containsKey(newFCR.License__c)){
                    fcrTempList = fcrLicenseValueMap.get(newFCR.License__c);    
                }  
                else{
                    fcrTempList = new List<Field_Change_Request__c>();    
                }
                fcrTempList.add(newFCR);
                fcrLicenseValueMap.put(newFCR.License__c,fcrTempList);// Map to contain Outlet,FCR Records
            }else  if(newFCR.Status__c == 'Approved' && oldFCR.Status__c != 'Approved' && newFCR.Object_Type__c == 'Supplier_Outlet__c'){
                if(fcrSupplierOutletValueMap.containsKey(newFCR.Supplier_Outlet__c)){
                    fcrTempList = fcrSupplierOutletValueMap.get(newFCR.Supplier_Outlet__c);    
                }  
                else{
                    fcrTempList = new List<Field_Change_Request__c>();    
                }
                fcrTempList.add(newFCR);
                fcrSupplierOutletValueMap.put(newFCR.Supplier_Outlet__c,fcrTempList);// Map to contain Outlet,FCR Records
            }else  if(newFCR.Status__c == 'Approved' && oldFCR.Status__c != 'Approved' && newFCR.Object_Type__c == 'Outlet_Strategic_Fit__c'){//148622 (else If block)
                if(fcrOutletStrategicValueMap.containsKey(newFCR.Outlet_Strategic_Fit__c)){
                    fcrTempList = fcrOutletStrategicValueMap.get(newFCR.Outlet_Strategic_Fit__c);    
                }  
                else{
                    fcrTempList = new List<Field_Change_Request__c>();    
                }
                fcrTempList.add(newFCR);
                fcrOutletStrategicValueMap.put(newFCR.Outlet_Strategic_Fit__c,fcrTempList);// Map to contain Outlet,FCR Records
            }
        }
        
        if(!fcrLicenseValueMap.isEmpty()){
            updateSobjectFields(fcrLicenseValueMap,'License__c');    
        }
        if(!fcrOutletValueMap.isEmpty()){
            updateSobjectFields(fcrOutletValueMap,'Account');
            //update child fcr with Approved status
            Database.update(childFCRList);
        }
        if(!fcrSupplierOutletValueMap.isEmpty()){
            updateSobjectFields(fcrSupplierOutletValueMap,'Supplier_Outlet__c');
        }
        if(!fcrOutletStrategicValueMap.isEmpty()){//148622
            updateSobjectFields(fcrOutletStrategicValueMap,'Outlet_Strategic_Fit__c');
        }
    }
    // update object records 
    public static void updateSobjectFields(Map<Id,List<Field_Change_Request__c>> fcrValueMap,String objectType){
        List<sObject> listToUpdate = new List<sObject>();              
        for(Id newsObjId : fcrValueMap.keySet()){                    
            sObject sObj = Schema.getGlobalDescribe().get(objectType).newSObject() ;           
            sObj.Id = newsObjId; 
            for(Field_Change_Request__c fcr : fcrValueMap.get(sObj.Id)){
                if(fcr.Field_Type__c =='Boolean'){                    
                    sObj.put(fcr.Field_Name__c,Boolean.ValueOf(fcr.New_Value__c)); 
                }
                else if(fcr.Field_Type__c =='DOUBLE'){
                    sObj.put(fcr.Field_Name__c,Double.ValueOf(fcr.New_Value__c));    
                }else if(fcr.Field_Type__c =='Date'){
                    sObj.put(fcr.Field_Name__c,Date.ValueOf(fcr.New_Value__c));    
                }
                //Percent added by juned ES20-8621
                else if(fcr.Field_Type__c =='PERCENT'){
                    sObj.put(fcr.Field_Name__c,Double.ValueOf(fcr.New_Value__c));    
                }
                else{
                    System.debug('--fcr.Field_Name__c--'+fcr.Field_Name__c+'---fcr.New_Value__c--'+fcr.New_Value__c);
                    sObj.put(fcr.Field_Name__c,fcr.New_Value__c); 
                }
                //Replace Old Value with New Value               
            }
            listToUpdate.add(sObj);
        }
        EDGE_UtilityClass.stopTriggerToRun  = True;//Used to Avoid Recursion
        Database.SaveResult[] srList = Database.update(listToUpdate);
        for(Database.saveResult sr : srList){
            if(sr.isSuccess()){
                System.debug('Record Updated');    
            }  
            else{
                for(Database.Error err : sr.getErrors()){
                    System.debug('****error****'+err.getMessage()+'*****'+err.getFields());
                }
            }
        }       
    }
    // change the owner of field change request records to automatically assign approver 
    public static void changeOwnerOfFCR(List<SObject> newItems){
        
        Set<Id> countrySetId = new Set<Id>();
        Map<Id,String> countryNameMap = new Map<Id,String>(); 
        Map<String,Id> queueMap = new Map<String,Id>();
        List<String> queueStrList =new List<String>();
        List<Geography__c> countryList = new List<Geography__c>();
        List<Group> queueList = new List<Group>();
        for(SObject sObj : newItems){
            Field_Change_Request__c newFCR = (Field_Change_Request__c)sObj;
            countrySetId.add(newFCR.Geography__c);
        }
        if(Schema.sObjectType.Geography__c.isAccessible()){
            countryList  = [SELECT Id, Code__c FROM Geography__c WHERE Id IN : countrySetId];    
        }
        for(Geography__c geo : countryList){
            countryNameMap.put(geo.Id,geo.Code__c);        
        }
        for(Id geoId : countryNameMap.keyset()){
            String tempStr = countryNameMap.get(geoId)+ Label.EDGE_AccountFCRMDMApproval;
            queueStrList.add(tempStr);
        }
        if(Schema.sObjectType.Group.isAccessible()){
            queueList = [Select Id,Name from Group where Type = 'Queue' AND Name like :queueStrList];    
        } 
        for(Group grp :queueList){
            queueMap.put(grp.Name,grp.Id);      
        }
        for(SObject sObj : newItems){
            Field_Change_Request__c newFCR = (Field_Change_Request__c)sObj;
            for(String queueName : queueMap.keySet()){
                if(queueName.contains(countryNameMap.get(newFCR.Geography__c))){                    
                    newFCR.OwnerId = queueMap.get(queueName);       
                }    
            }
        }
    }
    
    /*
Method  : checkAndGenerateSharing
Purpose : To create sharing record on Insert
*/
    public static void checkAndGenerateSharing(List<Field_Change_Request__c> newItems){
        EDGE_SharingUtil.validateCreatePermission(newItems, 'Geography__c');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Geography__c', 'Up', 'Read');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Geography__c', 'Down', 'Edit');        
    }
    
    /*
Method  : validateAndReGenerateSharing
Purpose : Modify, Validate sharing record on update
*/
    public static void validateAndReGenerateSharing(List<Field_Change_Request__c> newItems,Map<Id, SObject> oldItems){
        Map<Id, Field_Change_Request__c> mapOldItems;
        List<Field_Change_Request__c> lstNewChangeGeography = new List<Field_Change_Request__c>();
        List<Field_Change_Request__c> lstOldChangeGeography = new List<Field_Change_Request__c>();
        
        EDGE_SharingUtil.validateEditPermission(newItems);
        
        if(oldItems != null){
            mapOldItems = (Map<Id, Field_Change_Request__c>)oldItems;
        }
        
        for(Field_Change_Request__c objFieldChange : newItems){
            if(mapOldItems.containsKey(objFieldChange.Id) && objFieldChange.Geography__c != mapOldItems.get(objFieldChange.Id).Geography__c){
                lstNewChangeGeography.add(objFieldChange);
                lstOldChangeGeography.add(mapOldItems.get(objFieldChange.Id));
            }
        }
        
        if(lstNewChangeGeography != null && lstNewChangeGeography.size()>0){
            EDGE_SharingUtil.validateCreatePermission(lstNewChangeGeography, 'Geography__c');
            EDGE_SharingUtil.updateSharingRecords(lstNewChangeGeography, lstOldChangeGeography, 'Geography__c');
            EDGE_SharingUtil.generateSharingFromGeography(lstNewChangeGeography, 'Geography__c', 'Up', 'Read');
            EDGE_SharingUtil.generateSharingFromGeography(lstNewChangeGeography, 'Geography__c', 'Down', 'Edit');
        }       
    }
       /*
Method  : sendPushNotificationForApprovedRejectedFCR (ES20-12995)
Purpose : Send Push Notification to FE once FCR gets rejected or approved
*/
    public static void sendPushNotificationForApprovedRejectedFCR(List<SObject> newItems,Map<Id,SObject> oldItems){
        List<Field_Change_Request__c> newFCRs = newItems;
        Map<String,Object> custom = new Map<String,Object>();
        Map<Id,String> fcrAccountMap = new Map<Id,String>();
        List<Id> outletIds = new List<Id>();
        //initialize a Map to store all FCR.Id to wrapper
        Map<Id,EDGE_FCRDetailsWrapper> fcrIdtoDetailsMap = new Map<Id,EDGE_FCRDetailsWrapper>();

        for(Field_Change_Request__c fCR:newFCRs){
            outletIds.add(fCR.Outlet__c);
        }
        for(Account outlet:[Select Id,Name from Account where Id IN:outletIds]){
            fcrAccountMap.put(outlet.Id,outlet.Name);
        }
   
        //Check New items status and old items status to check further logic else escapefrom here
        for(Field_Change_Request__c newFCR:newFCRs){
            
            Field_Change_Request__c oldFCR = (Field_Change_Request__c) oldItems.get(newFCR.id);
           
            if((newFCR.Status__c == 'Approved' || newFCR.Status__c == 'Rejected') && (oldFCR.Status__c != 'Approved' && oldFCR.Status__c != 'Rejected')){
                //crete a wrapper items and put value within it
                EDGE_FCRDetailsWrapper fcrWrapper = New EDGE_FCRDetailsWrapper();
                fcrWrapper.outletId = newFCR.Outlet__c ;
                fcrWrapper.outletName = fcrAccountMap.get(newFCR.Outlet__c);
                fcrWrapper.status = newFCR.Status__c;
                fcrWrapper.createdById = newFCR.CreatedById;
                fcrWrapper.fieldName = newFCR.Field_Name__c;
                fcrWrapper.id = newFCR.Id;
                //add all approved,rejected FCR into Map to store FCR.id to wrapper
                fcrIdtoDetailsMap.put(newFCR.id,fcrWrapper);
            }
        }
        //loop the wrapper 
        for(Id fcrId:fcrIdtoDetailsMap.keySet()){
            EDGE_FCRDetailsWrapper fcrWrapper = fcrIdtoDetailsMap.get(fcrId);
            //create msg body
            String pushNotifMsg='';
            List<String> paramlist = new List<String>();
            paramlist.add(fcrWrapper.fieldName);
            paramlist.add(fcrWrapper.outletName);
            if(fcrWrapper.status=='Approved'){
                pushNotifMsg = String.format(System.Label.EDGE_MsgForApprovedFCRPushNotif,paramlist);
            }
            else{
                pushNotifMsg = String.format(System.Label.EDGE_MsgForRejectedFCRPushNotif,paramlist);
            }
            
            //create userlist which should be owner of FCR record
            String userToNotify = fcrWrapper.createdById;
            Set<String> usersList = new Set<String>();
            usersList.add(userToNotify);
            
            //Send Push Notificationwith msgBody,paylaod,userlist
            String msgBody = pushNotifMsg.stripHtmlTags();
            custom.put('AccountID',fcrWrapper.outletId);
            custom.put('Field_Name__c',fcrWrapper.fieldName);
            custom.put('fcrId',fcrWrapper.id);
            
            //create paylaod
            Messaging.PushNotification msg = new Messaging.PushNotification();
            Map<String, Object> payload = Messaging.PushNotificationPayload.apple(msgBody,'',null,custom);
            msg.setPayload(payload);
            System.debug(LoggingLevel.Debug,'@@@payload'+payload);
            System.debug(LoggingLevel.Debug,'@@@usersList'+usersList);
            if(!Test.isRunningTest()){
                msg.send('Edge_SFA_2_0', usersList);  
            } 
        }
        
    }
}