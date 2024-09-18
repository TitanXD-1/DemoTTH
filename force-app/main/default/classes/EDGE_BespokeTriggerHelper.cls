/**
* @Name: EDGE_BespokeTriggerHelper


* @History                                                            
                                                          
* @VERSION   AUTHOR            DATE              DETAIL
*  1.0       Sandeep Sahoo    07/08/2019        ES20-3468
*  2.0       Manohar Burkala  10/11/2019        ES20-5025 (modification done in Email templete)
*  3.0       Amar Deep        17/03/2019        ES20-6153 (modification done in Email template)
*  4.0       Anand Uppalapati 27/04/2022        ES20-12607(sendEmailToDeliveryPartner)
*/
public with sharing class EDGE_BespokeTriggerHelper {
    public static void updateCountry(List<Bespoke__c> newItems){
        Set<Id>accountSetId = new Set<Id>();
        Map<String,Id> accountCountryMap = new Map<String,Id>();
        if(newItems!=null){
            for(Bespoke__c newBespokeRec : newItems){
                accountSetId.add(newBespokeRec.Account__c);
            }
        }
        
        If(accountSetId != null && accountSetId.size() > 0 ){
            for(Account acc : [SELECT Id, Country__c FROM Account WHERE Id IN : accountSetId]){
                accountCountryMap.put(acc.Id,acc.Country__c);
            }
            
        }
        
        for(Bespoke__c newBespokeRec : newItems){
            if(accountCountryMap!=null && accountCountryMap.containsKey(newBespokeRec.Account__c)){
              newBespokeRec.Country__c = accountCountryMap.get(newBespokeRec.Account__c);   
            }
            
        }
    }
    
    public static void updateUserFields(List<Bespoke__c> newItems){
        Set<Id> countrySetId = new Set<Id>();
        List<Geography__c> countryList = new List<Geography__c>();
        Map<Id, String> countryNameMap = new Map<Id, String>();
        Set<String> queueStrSet = new Set<String>();
        
        Map<String,List<Id>> queueUserMap = new Map<String,List<Id>>();
        
        
        for(Bespoke__c newBespokeRec : newItems){
            countrySetId.add(newBespokeRec.Country__c);
        }
        if(Schema.sObjectType.Geography__c.isAccessible()){
            countryList  = [SELECT Id,Code__c FROM Geography__c WHERE Id IN : countrySetId];    
        }
        for(Geography__c geo : countryList){
            countryNameMap.put(geo.Id,geo.Code__c);        
        }
        for(Id geoId : countryNameMap.keyset()){
            String tempStr ='';
            tempStr += countryNameMap.get(geoId)+'_CFM' ;
            queueStrSet.add(tempStr);
        }
        
        if(queueStrSet.size()>0 &&  Schema.SObjectType.GroupMember.isAccessible() && Schema.SObjectType.Group.isAccessible()){
            List<GroupMember> grpMemberList = [SELECT Group.name,Userorgroupid from GroupMember where Group.type='Queue' and Group.Name IN: queueStrSet];
            for(GroupMember grpmem : grpMemberList){
                if(!queueUserMap.containsKey(grpmem.Group.name)){
                    List<Id> tempList = new List<Id>();
                    tempList.add(grpmem.Userorgroupid);
                    queueUserMap.put(grpmem.Group.name,tempList);                   
                }else{
                    queueUserMap.get(grpmem.Group.name).add(grpmem.Userorgroupid);
                }    
            }
        }
        
        Integer count = 0;
        for(Bespoke__c newBespokeRec : newItems){
            if(countryNameMap.containsKey(newBespokeRec.Country__c)){
                String queueName = countryNameMap.get(newBespokeRec.Country__c)+'_CFM';
                List<Id> userList = new List<Id>();
                if(null != queueUserMap && queueUserMap.containsKey(queueName)){
                	userList = queueUserMap.get(queueName);    
                }
                
                if(userList.size()!=0){
                    if(userList.size()>=3){                     
                        newBespokeRec.Approver1__c = userList[0];
                        newBespokeRec.Approver2__c = userList[1];
                        newBespokeRec.Approver3__c = userList[2]; 
                    }else if(userList.size()==2){
                        newBespokeRec.Approver1__c = userList[0];
                        newBespokeRec.Approver2__c = userList[1];
                        newBespokeRec.Approver3__c = userList[1]; 
                    }else if(userList.size()==1){
                        newBespokeRec.Approver1__c = userList[0];
                        newBespokeRec.Approver2__c = userList[0];
                        newBespokeRec.Approver3__c = userList[0];
                    }    
                }                 
            }
        }     
    }
    
    // update the Bespokestatus 
    public static void updateBespokeStatus(List<Bespoke__c> newItems, Map<Id, SObject> mapOldItems){
        Set<Id> countrySetId = new Set<Id>();
        List<id> contentDocumentids = new List<id>(); Set <String > emailSet = new Set<String>();
        List<Bespoke__c> bespokeList = new List<Bespoke__c>();
        List<Messaging.Emailfileattachment> fileAttachments = new List<Messaging.Emailfileattachment>();
        Map<Id,Bespoke__c> oldItems;
        
        if(mapOldItems != null){
            oldItems = (Map<Id,Bespoke__c>)mapOldItems;
        }
        
        for( Bespoke__c besRec : newItems ){
            if(mapOldItems != null && (besRec.Status__c != oldItems.get(besRec.id).Status__c) && (besRec.Status__c == 'Ready For Order')){
                emailSet.add(besRec.Delivery_Partner__r.Email__c);
                besRec.Status__c = 'Order Placed';
                bespokeList.add(besRec);
            }                
        }
        
    }
    
    public static void sendEmailToDeliveryPartner(List<Bespoke__c> newItems){ 
        
        Set<ID> contentDocSet = new Set<ID>();
        List<Bespoke__c> bespokeList = new List<Bespoke__c>();
        Map<Id,List<Id>> contentDocumentidMap = new Map<Id,List<Id>>();
        Map<ID,List<Messaging.Emailfileattachment>> contentAttachmentMap = new Map<ID,List<Messaging.Emailfileattachment>>();
        Map<Id,Bespoke__c> deliveryPartnerMap = new Map<Id,Bespoke__c>();      
        Messaging.SingleEmailMessage[] emailMessageList = new Messaging.SingleEmailMessage[]{};
            
            for(Bespoke__c beSpkRec : [Select ID,Sales_Rep__r.Name,Account__r.Name,Account__r.Unique_Record_ID__c,Project_Name__c,
                                       Delivery_Partner__c,RecordType.Name,Delivery_Partner__r.Email__c from Bespoke__c where ID IN: newItems and Status__c = 'Order Placed']){            
                                           deliveryPartnerMap.put(beSpkRec.Id,beSpkRec);
                                       }
       
        If(deliveryPartnerMap.size()>0 && deliveryPartnerMap != null){
        system.debug('CDList++ ' + [SELECT LinkedEntityid, ContentDocumentid FROM contentDocumentLink WHERE LinkedEntityid IN: deliveryPartnerMap.keyset()]);
        for(contentDocumentLink cDLink : [SELECT LinkedEntityid, ContentDocumentid FROM contentDocumentLink WHERE LinkedEntityid IN: deliveryPartnerMap.keyset()]){
            if(!contentDocumentidMap.containsKey(cDLink.LinkedEntityid)){
                List<Id> tempList = new List<Id>();
                tempList.add(cDLink.ContentDocumentid);
                contentDocumentidMap.put(cDLink.LinkedEntityid,tempList);
                contentDocSet.add(cDLink.ContentDocumentid);
            }else{
                contentDocumentidMap.get(cDLink.LinkedEntityid).add(cDLink.ContentDocumentid);
                contentDocSet.add(cDLink.ContentDocumentid);
            }  
        }
        }
        
        if(contentDocSet.size()>0){
            for ( ContentVersion cversion : [SELECT title,PathOnClient,ContentDocumentId, FileType, versiondata FROM contentversion WHERE ContentDocumentId IN :contentDocSet]){            
                Messaging.Emailfileattachment efa1 = new Messaging.Emailfileattachment();
                efa1.setFileName(cversion.title+'.'+cversion.FileType);//ES20-12607
                //System.debug('cversion.FileType'+cversion.title+cversion.FileType);
                efa1.setBody(cversion.versiondata);             
                if(!contentAttachmentMap.containsKey(cversion.ContentDocumentId)){
                    List<Messaging.Emailfileattachment> fileAttachments = new List<Messaging.Emailfileattachment>();
                    fileAttachments.add(efa1);
                    contentAttachmentMap.put(cversion.ContentDocumentId,fileAttachments);
                }else{
                    contentAttachmentMap.get(cversion.ContentDocumentId).add(efa1);
                } 
            }
        }
        
        if(deliveryPartnerMap.size()>0 && contentAttachmentMap.size()>0 && contentDocumentidMap.size()>0){
            for( Bespoke__c besRec : newItems ){
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                List<Messaging.Emailfileattachment> fileAttachments = new List<Messaging.Emailfileattachment>();
                
                if((deliveryPartnerMap.get(besRec.Id) != NULL && deliveryPartnerMap.get(besRec.Id).Delivery_Partner__c != null)) {
                    mail.setToAddresses(new String[]{deliveryPartnerMap.get(besRec.Id).Delivery_Partner__r.Email__c});
                    mail.setSubject('A new Bespoke was created');
                    for(ID temp1 : contentDocumentidMap.get(besRec.Id)){
                        for(Messaging.Emailfileattachment emailAttachment : contentAttachmentMap.get(temp1)){
                            fileAttachments.add(emailAttachment);
                            mail.setFileAttachments(fileAttachments);
                        }
                    } 
                    String body = ' ';
                    body += '<html width="600px">';
                    body += '<body><center><table>';
                    body += '<tr><td><b>Sales Representative : </b></td>';
                    if(deliveryPartnerMap.get(besRec.Id).Sales_Rep__r.Name!=null){
                        body += '<td>'+deliveryPartnerMap.get(besRec.Id).Sales_Rep__r.Name+'</td>';
                    }
                    body += '</tr>';
                    body += '<tr><td><b>Outlet Name : </b></td>';
                    if(deliveryPartnerMap.get(besRec.Id).Account__r.Name!=null){
                        body +='<td>'+ deliveryPartnerMap.get(besRec.Id).Account__r.Name+'</td>'; 
                    }
                    body += '</tr>'; 
                    body += '<tr><td><b>Unique Record ID : </b></td>';
                    if(deliveryPartnerMap.get(besRec.Id).Account__r.Unique_Record_ID__c!=null){
                    body += '<td>'+ deliveryPartnerMap.get(besRec.Id).Account__r.Unique_Record_ID__c+'</td>'; 
                    }
                    body += '</tr>'; 
                    body += '<tr><td><b>Type : </b></td>';
                    if(deliveryPartnerMap.get(besRec.Id).RecordType.Name!=null)
                    {
                        body += '<td>'+ deliveryPartnerMap.get(besRec.Id).RecordType.Name+'</td>'; 
                    }
                    body += '</tr>';
                    body += '<tr><td><b>Project Name : </b></td>';
                    if(besRec.Project_Name__c!=null){
                        body += '<td>'+ besRec.Project_Name__c+'</td>'; 
                    }
                    body += '</tr>';
                    body += '<tr><td><b>Start Date : </b></td>';
                    if(besRec.Start_Date__c!=null){
                        body += '<td>'+ besRec.Start_Date__c.format()+'</td>'; 
                    }
                    body += '</tr>';
                    body += '<tr><td><b>End Date : </b></td>';
                    if(besRec.End_Date__c!=null){
                        body += '<td>'+ besRec.End_Date__c.format()+'</td>';    
                    }
                    body += '</tr>';
                    body += '<tr><td><b>Bump In : </b></td>';
                    if(besRec.Bump_In__c!=null){
                        body += '<td>'+ besRec.Bump_In__c.format()+'</td>';
                    }
                    body += '</tr>';
                    body += '<tr><td><b>Bump Out : </b></td>';
                    if(besRec.Bump_Out__c!=null){
                        body +='<td>'+ besRec.Bump_Out__c.format()+'</td>';
                    }
                    body += '</tr>';
                    body += '<tr><td><b>Product Focus : </b></td>';
                    if(besRec.Product_Focus__c!=null){
                        body +='<td>'+ besRec.Product_Focus__c+'</td>';
                    }
                    body += '</tr>';
                    body += '<tr><td><b>Activity Objectives : </b></td>';
                    if(besRec.Activity_Objectives__c!=null){
                        body += '<td>' +besRec.Activity_Objectives__c+'</td>';
                    }
                    body += '</tr>';
                    body += '<tr><td><b>Diageo Contact : </b></td>';
                    if(besRec.Diageo_Contact__c!=null){
                        body += '<td>' + besRec.Diageo_Contact__c+'</td>';
                    }
                    body += '</tr>';
                    body += '<tr><td><b>Diageo Contact Email : </b></td>';
                    if(besRec.Diageo_Contact_Email__c!=null){
                        body +='<td>' + besRec.Diageo_Contact_Email__c+'</td>';
                    }
                    body += '</tr>';
                    body += '<tr><td><b>Diageo Contact Phone Number : </b></td>';
                    if(besRec.Diageo_Contact_Phone_Number__c!=null){
                        body += '<td>' + besRec.Diageo_Contact_Phone_Number__c+'</td>';
                    }
                    body += '</tr>';
                    body += '<tr><td><b>Customer Preferred Contact : </b></td>';
                    if(besRec.Customer_Preferred_Contact__c!=null){
                        body +='<td>' +  besRec.Customer_Preferred_Contact__c+'</td>';
                    }
                    body += '</tr>';
                    body += '<tr><td><b>Customer Contact Email : </b></td>';
                    if(besRec.Customer_Contact_Email__c!=null){
                        body += '<td>' + besRec.Customer_Contact_Email__c+'</td>';
                    }
                    body += '</tr>';
                    body += '<tr><td><b>Customer Contact Phone : </b></td>';
                    if(besRec.Customer_Contact_Phone__c!=null){
                        body +='<td>' + besRec.Customer_Contact_Phone__c+'</td>';
                    }
                    body += '</tr>';
                    body += '<tr><td><b>Site Visit Date : </b></td>';
                    if(besRec.Site_Visit_Date__c!=null){
                        body += '<td>' + besRec.Site_Visit_Date__c.format()+'</td>';
                    }
                    body += '</tr>';
                    body += '<tr><td><b>Site Visit Time : </b></td>';
                    if(besRec.Site_Visit_Time__c!=null){
                        time dt = besRec.Site_Visit_Time__c;
                        String s= String.valueOf(dt);
						String[] a = s.split(':');
                        body +='<td>' + a[0] +':'+a[1]+' '+'AEST'+'</td>';
                    }
                    body += '</tr>';
                    body += '<tr><td><b>Venue Notes : </b></td>';
                    if(besRec.Venue_Notes__c!=null){
                        body += '<td>' + besRec.Venue_Notes__c+'</td>';
                    }
                    body += '</tr>';
                    body += '<tr><td><b>Will field Team be attending? : </b></td>';
                    if(besRec.Field_Team_Attending__c!=null){
                        body += '<td>' + besRec.Field_Team_Attending__c+'</td>';
                    }
                    body += '</tr>';
                    body += '<tr><td><b>Budget  : </b></td>';
                    if(besRec.Budget__c!=null){
                        body += '<td>' + besRec.Budget__c+'</td>';
                    }
                    body += '</tr>';
                    body += '<tr><td><b>Incremental Volume  : </b></td>';
                    if(besRec.Incremental_Volume__c!=null){
                        body += '<td>' + besRec.Incremental_Volume__c+'</td>';
                    }
                    body += '</tr>';
                    body += '<tr><td><b>Incremental NSV  : </b></td>';
                    if(besRec.Incremental_NSV__c!=null){
                        body += '<td>' + besRec.Incremental_NSV__c+'</td>';
                    }
                    body += '</tr>';
                    body += '<tr><td><b>ROI   : </b></td>';
                    if(besRec.ROI__c!=null){
                        body += '<td>' + besRec.ROI__c+'</td>';
                    }
                    body += '</tr>';
                    body += '</table></center></body>';
                    
                    mail.setHtmlBody(body);
                }
                emailMessageList.add(mail);
            }
        }           
        if(emailMessageList.size()>0){
            Messaging.sendEmail(emailMessageList);
        }
        
    }
    /*******************************************************************
Method  : autoPopulateDeliveryPartner
Purpose : AutoPopulate DeliveryPartner from Market Setting to Bespoke
********************************************************************/
    public static void autoPopulateDeliveryPartner(List<Bespoke__c> newItems){
        Id promoRecordTypeId = Bespoke__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Bespoke Promotion').getRecordTypeId();
        Id activRecordTypeId = Bespoke__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Bespoke Activation').getRecordTypeId();
        
        Set<Id> countrySetId = new Set<Id>();
        
        Map<Id,Market_Setting__c> countrySupplierMap= new Map<Id,Market_Setting__c>();
        List<Bespoke__c> bespokeList = new List<Bespoke__c>();
        
        for(Bespoke__c bespokeRec : newItems){
            countrySetId.add(bespokeRec.Country__c);
            bespokeList.add(bespokeRec);
            
        }
        if(Schema.sObjectType.Market_Setting__c.isAccessible()){
            for(Market_Setting__c marketSetting :  [SELECT Id,Geography__c,Supplier_Bespoke_Activation__c,Supplier_Bespoke_Promotion__c FROM Market_Setting__c WHERE Geography__c  IN : countrySetId]){
                
                countrySupplierMap.Put(marketSetting.Geography__c,marketSetting );
                system.debug('----countrySupplierMap----'+countrySupplierMap);
            }
        }
        for(Bespoke__c bespokeRec : newItems){
            if(bespokeRec.Delivery_Partner__c == null && countrySupplierMap != null && countrySupplierMap.containsKey(bespokeRec.Country__c)){
                
                if( bespokeRec.RecordTypeId == promoRecordTypeId && countrySupplierMap.get(bespokeRec.Country__c).Supplier_Bespoke_Promotion__c!=null ){
                    bespokeRec.Delivery_Partner__c = countrySupplierMap.get(bespokeRec.Country__c).Supplier_Bespoke_Promotion__c;
                    
                } else if( bespokeRec.RecordTypeId == activRecordTypeId && countrySupplierMap.get(bespokeRec.Country__c).Supplier_Bespoke_Activation__c != null  ) {
                    bespokeRec.Delivery_Partner__c = countrySupplierMap.get(bespokeRec.Country__c).Supplier_Bespoke_Activation__c;
                    
                    
                }
            }
        }
    }
    
}