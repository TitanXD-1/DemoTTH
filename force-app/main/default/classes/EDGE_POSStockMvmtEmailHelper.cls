/*
* @Name: EDGE_POSStockMvmtEmailHelper
* @Purpose: Trigger Helper Class for OrderTriggerHandler
* @History:
* @Author          Version      Date             Detail
* Sandip Ghosh      V1.0       02/03/2020     [ES20-6909]SFDC_POS Delivery Partner Email - Change to CSV attachment
* Amar Deep         v1.1       12/06/2020     [ES20-8022] Adding ContactName And ContactPhoneNumber in POS template - 'getOutletContactMap'
* Amar Deep         v1.2       28/07/2020     [ES20-7236]  Changed Billing country to Geo country in the email template of all types of Order
* Rubeena			v1.3	   2/12/2020      [CR-2178] Included two new fields Legacy Front Office Number and Territory Name of Rep for POS Order Email Attachment
* Swaraj Samanta   	v1.4       06/05/2022     [ES20-12606] Populate Shipping Delivery Address in a POS order Email for Other Delivery Location- later it got cancelled so commenting the code
* Monalisa Halder   v1.5       23/05/2022     ES20-12732 
* Sudipta &Shameer	V1.6		07/06/2022	  [ES20-12722]- Now in the Email, which is sent to Delivery Partner, Contact Name
                                                           and Phone Number of the Order Object will be populated
* Rajarshi Lahiri	v1.7 	   22/06/2022	  [ES20-12606]-Added logic to fetch Address from Alternate Delivery address
* Anamika Shukla    v1.8       23/06/2022     [ES20-12954]-Added Field SAP Ship To in the Attached Order CSV.
* Monalisa Halder   v1.9       05/08/2022     [ES20-13180]-Separate CSV Mails for Delivery Partners
* Wribhu Bose       V2.0       07/11/2022     [ES20-13023] Added Parent Order field in Attached Order CSV
*/

public with sharing class EDGE_POSStockMvmtEmailHelper {
	
    static String outletRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId(); 
    static String shedRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Shed').getRecordTypeId();
    static String posorderRecordTypeId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS Order').getRecordTypeId();
    static Map<String, List<String>> countryCodeToCCListMap = new Map<String, List<String>>();
    static String stockmovmntOrderRecordTypeId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Stock Movement').getRecordTypeId();
    
    /*Used by the Order Trigger helper to call VF page getContent method through future context to avoid Exception*/
    @future(callout=true)
    public static void sendEmailAsync(Set<Id> orderIds, List<String> toEmailAddresses, String languageName){
        sendExcelBodyEmail(orderIds, toEmailAddresses, languageName, null, false, null, null);
    }
    
    /* Method called from Batch and indirectly from Order Trigger helper via sendEmailAsync to initiate mail sending in Excel format*/
    public static void sendExcelBodyEmail(Set<Id> orderIds, List<String> toEmailAddresses, String languageName, String countryCode, Boolean batchContext, String delPartnerId, Map<String, String> labelToTranslatedStrMap){
        
        String unitTestStr = 'Unit.Test';
        PageReference vfPage = null;
        //System.debug('batchContext = '+ batchContext);
        //System.debug('languageName = '+ languageName);
        //System.debug('orderIds = '+ orderIds);
        //System.debug('delPartnerId = '+ delPartnerId);

        vfPage = Page.EDGE_POSOrderEmailAttachment;
        vfPage.getParameters().put('label_lang', languageName);
        if(batchContext){//Batch context
            vfPage.getParameters().put('batch_context', 'true');
        	vfPage.getParameters().put('del_partner_id', delPartnerId);
        }else{//Trigger context
            vfPage.getParameters().put('batch_context', 'false');
            vfPage.getParameters().put('order_ids', JSON.serialize(orderIds)); 
        }

        if(Test.isRunningTest()) {
            blob pdfBody = blob.valueOf(unitTestStr);
        } else {
            if(vfPage != null){
            	Blob emailBody = vfPage.getContent();
            	//System.debug('emailBody : Excel format = '+ emailBody);
                sendEmail(emailBody, toEmailAddresses, false, countryCode, labelToTranslatedStrMap);
            }
        }
    }

	/* Get CC email addresses based on country code - applicable for Batch context only*/    
    private static List<String> getCCEmailListForBatch(String countryCode){
        
        if(countryCodeToCCListMap.containsKey(countryCode)){
            return countryCodeToCCListMap.get(countryCode);
        }else{
            //String tempStr = '%'+countryCode+'_'+'MDM'+'%';
             String tempStr = countryCode+'_'+'MDM';//included for ES20-9247
            Map<Id,GroupMember> salesMembers = new Map<Id,GroupMember>(); 
            List<String> emailList = new List<String>();
            //replaced "LIKE:tempStr" with "=:tempStr" for ES20-9247
            for(GroupMember sgm : [SELECT Group.Name,UserOrGroupId FROM GroupMember WHERE group.name =:tempStr and group.type='Queue' ]){   
                salesMembers.put(sgm.UserOrGroupId,sgm);
            } 
            
            for(User usr : [Select Id,email from User where Id IN : salesMembers.keySet()]){    
                emailList.add(usr.email);  
            }
            countryCodeToCCListMap.put(countryCode, emailList);
            return emailList;
        }
    } 
    
    /* Method responsible for actually sending e-mails in CSV or xls format */
    private static void sendEmail(Blob blobEmailBody, List<String> toEmailAddresses, Boolean isCSVAttachment, String countryCode, Map<String, String> labelToTranslatedStrMap){
        //toEmailAddresses = new List<String>{'sandip.ghosh@diageo.com'};
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
		List<String> ccEmailAddresses = new List<String>();
        
        if(countryCode != null){
           	ccEmailAddresses =  getCCEmailListForBatch(countryCode);
            //System.debug('ccEmailAddresses = '+ ccEmailAddresses);
            if(ccEmailAddresses.size() > 0){
                email.setCcAddresses(ccEmailAddresses);
            }
        }  
        
        String todayDate = date.today().format();
        if(labelToTranslatedStrMap != null && labelToTranslatedStrMap.containsKey('EDGE_POS_Email_Subject')){
           email.setSubject(labelToTranslatedStrMap.get('EDGE_POS_Email_Subject') + todayDate); 
        }else{
            email.setSubject(Label.EDGE_POS_Email_Subject + todayDate);
        }
        
        email.setToAddresses(toEmailAddresses);
        email.setPlainTextBody('');
        Messaging.EmailFileAttachment excelCSVAttc = new Messaging.EmailFileAttachment();
        excelCSVAttc.setBody(blobEmailBody);
        
        String fileName = '';
        
        if(labelToTranslatedStrMap != null && labelToTranslatedStrMap.containsKey('EDGE_POS_Attachment_Name')){
            fileName = labelToTranslatedStrMap.get('EDGE_POS_Attachment_Name'); 
        }else{
            fileName = Label.EDGE_POS_Attachment_Name;
        } 
        
        if(isCSVAttachment){
            //excelCSVAttc.setFileName(Label.EDGE_POS_Attachment_Name + '.csv');
            excelCSVAttc.setFileName(fileName + '.csv');
        }else{
            //excelCSVAttc.setFileName(Label.EDGE_POS_Attachment_Name + '.xls');
            excelCSVAttc.setFileName(fileName + '.xls');
        }
        
        email.setFileAttachments(new Messaging.EmailFileAttachment[]{excelCSVAttc});
        //System.debug('email = '+ email);
        Messaging.SendEmailResult[] emailResult = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
        //System.debug('Mail tracker'+ emailResult);
    }
    
    /* Prepares a list of Order records based on the order ids passed*/
    public static List<Order__c> getOrderList(Set<Id> orderIds, Boolean batchContext, Id delPartnerId){
        
        List<Order__c> orderList = new List<Order__c>();
        //Added Alternate_Delivery_Address__r as part of ES20-12606
         //Added SAP_Ship_To__c as part of ES20-12954
         //Added Parent_Order__c as part of ES20-13023
        String queryStr = 'SELECT Id,Name,Status__c,RecordTypeId,Delivery_End_Date__c,Delivery_Start_Date__c, Delivery_Location__c,Order_Header_Notes__c,Order_Group__c,Delivery_Partner__r.Email__c,Delivery_Partner__c,Account__c, Account__r.RecordTypeId,'
                         +' Account__r.name,Sales_Representative__r.TimeZoneSidKey,Sales_Representative__r.name,Sales_Representative__r.MobilePhone,Sales_Representative__r.Email,Sales_Representative__r.Street,'
                         +' Sales_Representative__r.City,Sales_Representative__r.State,Sales_Representative__r.PostalCode,Sales_Representative__r.Country,Account__r.BillingStreet,Account__r.BillingState,Account__r.BillingCity,Account__r.BillingCountry,Account__r.BillingPostalCode,Account__r.Country__c,Account__r.Country__r.Name,'
            			 +'Account__r.Legacy_Front_Office_Account_No__c, Account__r.Primary_Sales_Territory__r.Name,Contact__c,Contact__r.Name,Contact__r.Phone,Alternate_Delivery_Address__r.Address,Account__r.SAP_Ship_to__c,Parent_Order__c from Order__c';                        // included legacy Front office Number and Primary Sales Territory field [CR-2178]
        
        
        if(batchContext){
            if(delPartnerId != null){
            	queryStr +=  ' where Delivery_Partner__c = \''+ delPartnerId +'\' and ( RecordTypeId =:posOrderRecordTypeId or RecordTypeId =:stockmovmntOrderRecordTypeId ) and Status__c = \'Ready for Order\' AND Delivery_Partner__r.Batch_Notification__c = ' + batchContext;
            }
        }else{
            if(orderIds != null && orderIds.size() > 0){
                queryStr +=  ' WHERE Id IN :orderIds  AND Delivery_Partner__r.Batch_Notification__c = ' + batchContext;                
            }
        }
        
        //System.debug('queryStr = '+ queryStr);
        orderList = Database.query(queryStr);
        
        return orderList;
    }
    
    /* Creates a map of order and corresponding address values, formatted start and end delivery dates based on the condition of fetching address*/
    public static Map<Id,EDGE_POSStockMvmtEmailHelper.OrderRecord> getAddressMap(List<Order__c> orderList/*,Map<Id, AccountContactRelation> orderIdsToContactMap*/){
        
        Set<Id> setOrderPOS = new set<Id>();
        List<AccountShare> shedAccountList = new List<AccountShare>();
        Map<Id,Id> shedAccountUserMap = new Map<Id,Id>();
        Map<Id,Account>  shedIdtoAccountMap = new Map<Id,Account>();
        Map<Id,Account>  salesRepIdtoShedAccountMap = new Map<Id,Account>();
        Map<Id,EDGE_POSStockMvmtEmailHelper.OrderRecord>  orderIdToOrderAddressMap = new Map<Id,EDGE_POSStockMvmtEmailHelper.OrderRecord>();
        
        if(orderList!=null && orderList.size()>0){
            for(Order__c ordObj : orderList){
                if(ordObj.Delivery_Location__c == 'shed' && ordObj.RecordTypeId == posorderRecordTypeId ){
                    setOrderPOS.add(ordObj.Sales_Representative__c);      
                } 
            }
            
        }
        //Added isAccessible check for AccountShare by Vikas
        if(setOrderPOS != null && setOrderPOS.size()>0 && Schema.sObjectType.AccountShare.isAccessible()){
            shedAccountList = [SELECT AccountId,Account.BillingStreet, Account.BillingCity, Account.BillingState, 
                               Account.BillingPostalCode,Account.BillingCountry,UserOrGroupId,Account.Country__c,Account.Country__r.Name FROM AccountShare WHERE UserOrGroupId IN :setOrderPOS AND Account.RecordTypeId =:shedRecordTypeId];
            for(AccountShare accShare : shedAccountList){
                //shedAccountUserMap.put(accShare.UserOrGroupId, accShare.AccountId); 
                Account accObj= new Account(id=accShare.AccountId,
                                            BillingStreet=accShare.Account.BillingStreet,
                                            BillingCity=accShare.Account.BillingCity,
                                            BillingState=accShare.Account.BillingState,
                                            BillingPostalCode=accShare.Account.BillingPostalCode,
                                            BillingCountry=accShare.Account.Country__r.Name); //accShare.Account.BillingCountry
                
                salesRepIdtoShedAccountMap.put(accShare.UserOrGroupId,accObj);
            }
        }
        
        if(orderList!=null && orderList.size()>0){
            
            for(Order__c ordObj : orderList){
                
                EDGE_POSStockMvmtEmailHelper.OrderRecord orderRec = new EDGE_POSStockMvmtEmailHelper.OrderRecord();
                    
                if((ordObj.Account__r.RecordTypeId == shedRecordTypeId && ordObj.Delivery_Location__c =='Sales Rep')){
                	
                    orderRec.street = ((ordObj.Sales_Representative__r.Street)!=null ? ordObj.Sales_Representative__r.Street:'');
                    orderRec.city = ((ordObj.Sales_Representative__r.City)!=null ? ordObj.Sales_Representative__r.City:'');
                    orderRec.state = ((ordObj.Sales_Representative__r.State)!=null ? ordObj.Sales_Representative__r.State:'');
                    orderRec.postalCode = ((ordObj.Sales_Representative__r.PostalCode)!=null ? ordObj.Sales_Representative__r.PostalCode:'');
                    orderRec.country = ((ordObj.Sales_Representative__r.Country)!=null ? ordObj.Sales_Representative__r.Country:'');
                    
                }else if((ordObj.Account__r.RecordTypeId == shedRecordTypeId  && ordObj.Delivery_Location__c =='Shed') || (ordObj.Account__r.RecordTypeId == outletRecordTypeId  && ordObj.Delivery_Location__c =='Outlet')){
                	
                    orderRec.street = ((ordObj.Account__r.BillingStreet)!=null ? ordObj.Account__r.BillingStreet:'');
                    orderRec.city = ((ordObj.Account__r.BillingCity)!=null ? ordObj.Account__r.BillingCity:'');
                    orderRec.state = ((ordObj.Account__r.BillingState)!=null ? ordObj.Account__r.BillingState:'');
                    orderRec.postalCode = ((ordObj.Account__r.BillingPostalCode)!=null ? ordObj.Account__r.BillingPostalCode:'');
                    orderRec.country = ((ordObj.Account__r.country__c)!=null ? ordObj.Account__r.country__r.name:'');
                    
                }else if(ordObj.Account__r.RecordTypeId == outletRecordTypeId && ordObj.Delivery_Location__c =='Shed'){
                    
                    if(salesRepIdtoShedAccountMap != null && salesRepIdtoShedAccountMap.size()>0 && salesRepIdtoShedAccountMap.get(ordObj.Sales_Representative__c) != null){
                        orderRec.street = ((salesRepIdtoShedAccountMap.get(ordObj.Sales_Representative__c).BillingStreet)!=null ? salesRepIdtoShedAccountMap.get(ordObj.Sales_Representative__c).BillingStreet:'') ;
                        orderRec.city = ((salesRepIdtoShedAccountMap.get(ordObj.Sales_Representative__c).BillingCity)!=null ? salesRepIdtoShedAccountMap.get(ordObj.Sales_Representative__c).BillingCity:'');
                        orderRec.state = ((salesRepIdtoShedAccountMap.get(ordObj.Sales_Representative__c).BillingState)!=null ? salesRepIdtoShedAccountMap.get(ordObj.Sales_Representative__c).BillingState:'');
                        orderRec.postalCode = ((salesRepIdtoShedAccountMap.get(ordObj.Sales_Representative__c).BillingPostalCode)!=null ? salesRepIdtoShedAccountMap.get(ordObj.Sales_Representative__c).BillingPostalCode:'');
                        orderRec.country = ((salesRepIdtoShedAccountMap.get(ordObj.Sales_Representative__c).BillingCountry)!=null ? salesRepIdtoShedAccountMap.get(ordObj.Sales_Representative__c).BillingCountry:'');
                    }
                }else if(ordObj.Account__r.RecordTypeId == outletRecordTypeId  && ordObj.Delivery_Location__c =='Other'){//Fetching address from Alternate Delivery Address as part of ES20-12606
                	
                    Address altAddress=ordObj.Alternate_Delivery_Address__r.Address;
                    if(altAddress != null){
                        orderRec.street = ((altAddress.street)!=null ? altAddress.street:'');
                        orderRec.city = ((altAddress.city)!=null ? altAddress.city:'');
                        orderRec.state = ((altAddress.state)!=null ? altAddress.state:'');
                        orderRec.postalCode = ((altAddress.postalcode)!=null ? altAddress.postalcode:'');
                        orderRec.country = ((altAddress.country)!=null ? altAddress.country:'');
                    }
                    
                }
                //end of 2nd else if block 
                orderRec.deliveryStartDate = ((ordObj.Delivery_Start_Date__c)!=null ? ordObj.Delivery_Start_Date__c.format('dd/MM/yyyy HH:mm',ordObj.Sales_Representative__r.TimeZoneSidKey):'');
                orderRec.deliveryEndDate = ((ordObj.Delivery_End_Date__c)!=null ? ordObj.Delivery_End_Date__c.format('dd/MM/yyyy HH:mm',ordObj.Sales_Representative__r.TimeZoneSidKey):'');
                //ES20-12722
                /*if(orderIdsToContactMap != null && orderIdsToContactMap.size()>0 && orderIdsToContactMap.get(ordObj.Id) != null){
                    orderRec.outletContactName = ((orderIdsToContactMap.get(ordObj.Id).Contact.Name) != null ? orderIdsToContactMap.get(ordObj.Id).Contact.Name: '');
                    orderRec.outletContactPhoneNumber = ((orderIdsToContactMap.get(ordObj.Id).Contact.Phone) != null ? (orderIdsToContactMap.get(ordObj.Id).Contact.Phone): ''); //Phone__c  
                }*/ //ES20-12722 - 
                if(ordObj.Contact__c!=Null){
                    orderRec.outletContactName = ordObj.Contact__r.Name;
                    orderRec.outletContactPhoneNumber = ordObj.Contact__r.Phone;
                }
                else{
                    orderRec.outletContactName = '';
                    orderRec.outletContactPhoneNumber = '';
                }
                orderIdToOrderAddressMap.put(ordObj.Id, orderRec);
            }//end of Order List iteration
        }//end of outer if
        
        return orderIdToOrderAddressMap;
    }
    
 // Create a map of Order Outlet and corresponding outlet contact name ,outlet contact phone number 
/*
    public static Map<Id, AccountContactRelation> getOutletContactMap(List<Order__c> orderList){
        
        set<Id> outletIdsSet = new set<Id>();
        List<AccountContactRelation> accountContactList = new List<AccountContactRelation>();
        Map<Id, AccountContactRelation> orderIdsToContactMap = new Map<Id, AccountContactRelation>();
        Map<Id, AccountContactRelation> accountIdsToContactMap = new Map<Id, AccountContactRelation>();
        
        If(orderList != null && orderList.size()> 0){
            for( Order__c ordObj : orderList ){
                outletIdsSet.add(ordObj.Account__c);
            }
        }
        
        If(outletIdsSet != null && outletIdsSet.size()>0 && Schema.sObjectType.AccountContactRelation.isAccessible()){
            
            for(AccountContactRelation accContactObj : [ SELECT AccountId,ContactId,Contact.Name,Contact.Phone__c,Contact.Phone,Display_Contact__c  FROM AccountContactRelation WHERE AccountId IN : outletIdsSet AND Display_Contact__c  = true]){//ES20-12732
                accountIdsToContactMap.put(accContactObj.AccountId,accContactObj);
            }
        }
        
        If(orderList != null && orderList.size()>0){
            for(Order__c ordObj : orderList){
                If(ordObj.Account__r.RecordTypeId == outletRecordTypeId){
                    If(accountIdsToContactMap != null && accountIdsToContactMap.size()>0 && accountIdsToContactMap.get(ordObj.Account__c) != null ){
                        orderIdsToContactMap.put(ordObj.Id ,accountIdsToContactMap.get(ordObj.Account__c) );
                    }
                    
                }
            }
        }
        return orderIdsToContactMap;
        
    }*/
    
    /* Prepares a map of delivery partner and List of corresponding Orders in context*/
     public static Map<Id,Set<Order__c>> getDlvryPartnerOrderMap(List<Order__c> orderList, Map<Id,String> delivryPartnrEmailMap){//ES20-13180  
        Map<Id,Set<Order__c>> delivryPartnrOrderIdsMap = new Map<Id,Set<Order__c>>();//ES20-13180  
        if(orderList!=null && orderList.size()>0){//ES20-13180  
            for(Order__c orderRec : orderList){//ES20-13180  
                //delivryPartnrMailSet.add(orderRec.Delivery_Partner__c); 
                if(delivryPartnrOrderIdsMap.containsKey(orderRec.Delivery_Partner__c)){//ES20-13180  
                    Set<Order__c> orderIdList = delivryPartnrOrderIdsMap.get(orderRec.Delivery_Partner__c);//ES20-13180  
                    orderIdList.add(orderRec);//ES20-13180  
                    delivryPartnrOrderIdsMap.put(orderRec.Delivery_Partner__c,orderIdList);//ES20-13180  
                }else{//ES20-13180  
                    delivryPartnrOrderIdsMap.put(orderRec.Delivery_Partner__c,new Set<Order__c> {orderRec});//ES20-13180  
                } 
                //System.debug('@@orderRec.Delivery_Partner__r.Email__c'+orderRec.Delivery_Partner__r.Email__c);//ES20-13180  
                delivryPartnrEmailMap.put(orderRec.Delivery_Partner__c,orderRec.Delivery_Partner__r.Email__c);//ES20-13180  
            }       
        } 
      return delivryPartnrOrderIdsMap;//ES20-13180  
    }     
    /* Prepares a map of order and List of Order Items in context*/
    public static Map<String,List<Order_Item__c>> getOrderToOrderItemMap(List<Order__c> orderList){
        
        Map<String,List<Order_Item__c>> orderListOrderMap = new Map<String,List<Order_Item__c>>();
        List<Order_Item__c> orderItemToUpdate = new List<Order_Item__c>();
        
        if(orderList != null && orderList.size()>0){
            for(Order_Item__c orderItem : [SELECT Id,Status__c, Order__r.Id,Product__c,Product__r.Product_Code__c,Order__c,Quantity__c,Note__c,Text_to_Print__c
                                           ,Product_Variant__r.Size__c,Product_Variant__r.Paper_Finish__c,toLabel(Product_Variant__r.Colour__c),
                                           Product_Variant__r.Gender__c FROM Order_Item__c WHERE Order__c IN : orderList
                                           /*AND Status__c!= 'Order Placed'*/ ]){                                       
                                               orderItem.Status__c = 'Order Placed';
                                               orderItemToUpdate.add(orderItem);   
                                               String orderId = orderItem.Order__r.Id;
                                               if(orderListOrderMap.containsKey(orderId)){
                                                   orderListOrderMap.get(orderId).add(orderItem);
                                               }else{
                                                   orderListOrderMap.put(orderId, new List<Order_Item__c> { orderItem });
                                               }            
                                           }            
        }
        
        if(orderItemToUpdate.size()>0 && Schema.sObjectType.Order_Item__c.isUpdateable()){
            //update orderItemToUpdate;
        }
        return orderListOrderMap;
        
    }
    
    /* Method called from the Batch class execute method to initiate mail sending in CSV format */
    public static void sendCsvAttachment(List<Order__c> orderList, List<String> toEmailAddresses, Map<String, String> labelToTranslatedStrMap, String countryCode){
        
        Set<Id> delivryPartnrMailSet = new Set<Id>();
        List<Delivery_Partner__c> deliveryPartMailList = new List<Delivery_Partner__c>();
        Map<String,List<Order_Item__c>> orderToOrderItemMap = new Map<String,List<Order_Item__c>>();
        Map<Id,EDGE_POSStockMvmtEmailHelper.OrderRecord> orderIdToOrderAddressMap = new Map<Id,EDGE_POSStockMvmtEmailHelper.OrderRecord>();
       
        
        if(orderList != null && orderList.size() > 0){
            
            orderToOrderItemMap = EDGE_POSStockMvmtEmailHelper.getOrderToOrderItemMap(orderList);
            //System.debug('orderToOrderItemMap = '+ orderToOrderItemMap);
            
      // ES20-12722     Map<Id, AccountContactRelation> orderIdsToContactMap = EDGE_POSStockMvmtEmailHelper.getOutletContactMap(orderList);
            orderIdToOrderAddressMap = EDGE_POSStockMvmtEmailHelper.getAddressMap(orderList/*,orderIdsToContactMap*/);//ES20-12722
            //System.debug('orderIdToOrderAddressMap = '+ orderIdToOrderAddressMap);
            
            String emailBody = prepareCSVBody(orderList, orderIdToOrderAddressMap, orderToOrderItemMap, labelToTranslatedStrMap/*, orderIdsToContactMap*/); //ES20-12722
           // System.debug('emailBody : CSV format = '+ emailBody);
            //Added '\uFEFF' for encoding issue
            sendEmail(Blob.valueOf('\uFEFF'+ emailBody), toEmailAddresses, true, countryCode, labelToTranslatedStrMap); 
        }
        
    }
    
    /* Prepares the CSV attachment body using order list, order item map, orderIdToOrderAddressMap and translated strings */
    public static String prepareCSVBody(List<Order__c> orderList, Map<Id,EDGE_POSStockMvmtEmailHelper.OrderRecord> orderIdToOrderAddressMap, Map<String,List<Order_Item__c>> orderListOrderMap, Map<String, String> labelToTranslatedStrMap/*, Map<Id, AccountContactRelation> orderIdsToContactMap*/){ 
        
        String emailBody = '';

        for(Order__c ordObj : orderList){
            
            if(orderList != null && orderList.size() > 0){
                
                if(labelToTranslatedStrMap != null){ // Batch context
                    
                    emailBody += labelToTranslatedStrMap.get('EDGE_ClientCode') + ','+ 'DIAGEO' + '\n';
                    emailBody += labelToTranslatedStrMap.get('EDGE_OutletID') + ','+ checkForNull(ordObj.Account__c) + '\n';
                    emailBody += labelToTranslatedStrMap.get('EDGE_OutletName') + ','+ checkForNull(ordObj.Account__r.name) + '\n';
                    emailBody += labelToTranslatedStrMap.get('EDGE_SAPShipTo') + ','+ checkForNull(ordObj.Account__r.SAP_Ship_to__c) + '\n';
                    emailBody += labelToTranslatedStrMap.get('EDGE_LegacyFrontOfficeNmbr') + ','+ checkForNull(ordObj.Account__r.Legacy_Front_Office_Account_No__c) + '\n'; //Addition of new coulmn[CR-2178]
                    emailBody += labelToTranslatedStrMap.get('EDGE_TerritoryName') + ','+ checkForNull(ordObj.Account__r.Primary_Sales_Territory__r.Name) + '\n';  //Addition of new column[CR-2178]
                    emailBody += labelToTranslatedStrMap.get('EDGE_SalesRepName') + ','+ checkForNull(ordObj.Sales_Representative__r.name) + '\n';
                    emailBody += labelToTranslatedStrMap.get('EDGE_SalesRepMobile') + ','+ checkForNull(ordObj.Sales_Representative__r.MobilePhone) + '\n';
                    emailBody += labelToTranslatedStrMap.get('EDGE_SalesRepEmail') + ','+ checkForNull(ordObj.Sales_Representative__r.Email) + '\n';
                    emailBody += labelToTranslatedStrMap.get('EDGE_ToDelivery') + ','+ checkForNull(ordObj.Delivery_Location__c) + '\n';
                                     
                    if(orderIdToOrderAddressMap.get(ordObj.Id) != null){
                    	emailBody += labelToTranslatedStrMap.get('EDGE_Address') + ','+ checkForNull(orderIdToOrderAddressMap.get(ordObj.Id).street) + '\n';
                    	emailBody += labelToTranslatedStrMap.get('EDGE_City') + ','+ checkForNull(orderIdToOrderAddressMap.get(ordObj.Id).city) + '\n';
                    	emailBody += labelToTranslatedStrMap.get('EDGE_State') + ','+ checkForNull(orderIdToOrderAddressMap.get(ordObj.Id).state) + '\n';
                    	emailBody += labelToTranslatedStrMap.get('EDGE_PostalCode') + ','+ checkForNull(orderIdToOrderAddressMap.get(ordObj.Id).postalCode) + '\n';
                        emailBody += labelToTranslatedStrMap.get('EDGE_Country') + ','+ checkForNull(orderIdToOrderAddressMap.get(ordObj.Id).country) + '\n';
                    }
                    emailBody += labelToTranslatedStrMap.get('EDGE_OrderNumber') + ','+ checkForNull(ordObj.Name) + '\n';
                    emailBody += labelToTranslatedStrMap.get('EDGE_IsReplacementOrder') + ','+ (checkForNull(ordObj.Parent_Order__c) != '' ? 'YES' : 'NO') + '\n'; //ES20-13023                    
                    emailBody += checkForNull(labelToTranslatedStrMap.get('EDGE_DeliveryStartDate')) + ','+ ((ordObj.Delivery_Start_Date__c)!=null ? ordObj.Delivery_Start_Date__c.format('dd/MM/yyyy HH:mm',ordObj.Sales_Representative__r.TimeZoneSidKey):'') + '\n';
                    emailBody += checkForNull(labelToTranslatedStrMap.get('EDGE_DeliveryEndDate')) + ','+ ((ordObj.Delivery_End_Date__c)!=null ? ordObj.Delivery_End_Date__c.format('dd/MM/yyyy HH:mm',ordObj.Sales_Representative__r.TimeZoneSidKey):'')  + '\n';
                    emailBody += labelToTranslatedStrMap.get('EDGE_OrderHeaderNotes') + ','+ checkForNull(ordObj.Order_Header_Notes__c) + '\n';
                    if(orderIdToOrderAddressMap.get(ordObj.Id) != null){
                        emailBody += labelToTranslatedStrMap.get('EDGE_OutletContactName') + ','+ checkForNull(orderIdToOrderAddressMap.get(ordObj.Id).outletContactName) + '\n';
                        emailBody += labelToTranslatedStrMap.get('EDGE_OutletContactPhoneNumber') + ','+ checkForNull(orderIdToOrderAddressMap.get(ordObj.Id).outletContactPhoneNumber) + '\n\n';  
                    }
                    emailBody += checkForNull(labelToTranslatedStrMap.get('EDGE_ProductCode')) + ','+ labelToTranslatedStrMap.get('EDGE_Quantity') + ','+ labelToTranslatedStrMap.get('EDGE_Notes') + ','+ labelToTranslatedStrMap.get('EDGE_TextToPrint') + ','+ labelToTranslatedStrMap.get('EDGE_Size') + ','+ labelToTranslatedStrMap.get('EDGE_Gender') + ','+ labelToTranslatedStrMap.get('EDGE_Colour') + ','+ labelToTranslatedStrMap.get('EDGE_PaperFinish') + '\n';
                }else{ // Trigger context                    
                    emailBody +=  Label.EDGE_ClientCode + ','+ 'DIAGEO' + '\n';
                    emailBody +=  Label.EDGE_OutletID + ','+ checkForNull(ordObj.Account__c) + '\n';
                    emailBody +=  Label.EDGE_OutletName + ','+ checkForNull(ordObj.Account__r.name) + '\n';
                    emailBody +=  Label.EDGE_SAPShipTo + ','+ checkForNull(ordObj.Account__r.SAP_Ship_to__c) + '\n';
                    emailBody +=  Label.EDGE_LegacyFrontOfficeNmbr + ','+ checkForNull(ordObj.Account__r.Legacy_Front_Office_Account_No__c) + '\n'; //addition of new column[CR-2178]
                    emailBody +=  Label.EDGE_TerritoryName + ','+ checkForNull(ordObj.Account__r.Primary_Sales_Territory__r.Name) + '\n'; //addition of new column[CR-2178]
                    emailBody +=  Label.EDGE_SalesRepName + ','+ checkForNull(ordObj.Sales_Representative__r.name) + '\n';
                    emailBody +=  Label.EDGE_SalesRepMobile + ','+ checkForNull(ordObj.Sales_Representative__r.MobilePhone) + '\n';
                    emailBody +=  Label.EDGE_SalesRepEmail + ','+ checkForNull(ordObj.Sales_Representative__r.Email) + '\n';
                    emailBody +=  Label.EDGE_ToDelivery + ','+ checkForNull(ordObj.Delivery_Location__c) + '\n';
                    emailBody +=  Label.EDGE_Address + ','+ checkForNull(orderIdToOrderAddressMap.get(ordObj.Id).street) + '\n';
                    emailBody +=  Label.EDGE_City + ','+ checkForNull(orderIdToOrderAddressMap.get(ordObj.Id).city) + '\n';
                    emailBody +=  Label.EDGE_State + ','+ checkForNull(orderIdToOrderAddressMap.get(ordObj.Id).state) + '\n';
                    emailBody +=  Label.EDGE_PostalCode + ','+ checkForNull(orderIdToOrderAddressMap.get(ordObj.Id).postalCode) + '\n';
                    emailBody +=  Label.EDGE_Country + ','+ checkForNull(orderIdToOrderAddressMap.get(ordObj.Id).country) + '\n';
                    emailBody +=  Label.EDGE_OrderNumber + ','+ checkForNull(ordObj.Name) + '\n';
                    emailBody +=  Label.EDGE_IsReplacementOrder + ','+ (checkForNull(ordObj.Parent_Order__c) != '' ? 'YES' : 'NO') + '\n'; //ES20-13023                   
                    if(ordObj.Delivery_Start_Date__c != null && ordObj.Sales_Representative__c != null && ordObj.Sales_Representative__r.TimeZoneSidKey != null){
                    	emailBody +=  Label.EDGE_DeliveryStartDate + ','+ checkForNull(ordObj.Delivery_Start_Date__c.format('dd/MM/yyyy HH:mm',ordObj.Sales_Representative__r.TimeZoneSidKey)) + '\n';
                    }else{
                        emailBody +=  Label.EDGE_DeliveryStartDate + ','+ '' + '\n';
                    }
                    if(ordObj.Delivery_End_Date__c != null  && ordObj.Sales_Representative__c != null && ordObj.Sales_Representative__r.TimeZoneSidKey != null){
                    	emailBody +=  Label.EDGE_DeliveryEndDate + ','+ checkForNull(ordObj.Delivery_End_Date__c.format('dd/MM/yyyy HH:mm',ordObj.Sales_Representative__r.TimeZoneSidKey)) + '\n';
                    }else{
                        emailBody +=  Label.EDGE_DeliveryEndDate + ','+ '' + '\n';                        
                    }  
                    emailBody +=  Label.EDGE_OrderHeaderNotes + ','+ checkForNull(ordObj.Order_Header_Notes__c) + '\n';
                    emailBody +=  Label.EDGE_OutletContactName + ','+ checkForNull(orderIdToOrderAddressMap.get(ordObj.Id).outletContactName) + '\n';
                    emailBody +=  Label.EDGE_OutletContactPhoneNumber + ','+ checkForNull(orderIdToOrderAddressMap.get(ordObj.Id).outletContactPhoneNumber) + '\n\n';
                    //emailBody +=  Label.EDGE_OutletContactPhoneNumber + ','+ checkForNull(orderIdsToContactMap.get(ordObj.Id).Contact.Phone) + '\n\n';
                    emailBody +=  Label.EDGE_ProductCode + ','+  Label.EDGE_Quantity + ','+  Label.EDGE_Notes + ','+  Label.EDGE_TextToPrint + ','+  Label.EDGE_Size + ','+  Label.EDGE_Gender + ','+  Label.EDGE_Colour + ','+  Label.EDGE_PaperFinish + '\n';
                }
                //System.debug('ordObj.Order_Header_Notes__c = '+ ordObj.Order_Header_Notes__c);
                //System.debug('orderListOrderMap = '+ orderListOrderMap);
                if(orderListOrderMap.containsKey(ordObj.Id)){
                    for(Order_Item__c orderPrdObj : orderListOrderMap.get(ordObj.Id)){
                        emailBody += checkForNull(orderPrdObj.Product__r.Product_Code__c) + ','+ checkForNull(orderPrdObj.Quantity__c) + ',' + checkForNull(orderPrdObj.Note__c) + ','+ checkForNull(orderPrdObj.Text_to_Print__c) + ','+ checkForNull(orderPrdObj.Product_Variant__r.Size__c) + ','+ checkForNull(orderPrdObj.Product_Variant__r.Gender__c) + ','+ checkForNull(orderPrdObj.Product_Variant__r.Colour__c) + ','+ checkForNull(orderPrdObj.Product_Variant__r.Paper_Finish__c) + '\n';                  
                    } 
                }           
            }
        }
        
        return emailBody;
    }
    
    /* Wrapper class used in the VF page to display Address and formatted delivery start and end dates*/
    public class OrderRecord{
        public String street{get;set;}
        public String city{get;set;}
        public String state{get;set;}
        public String postalCode{get;set;}
        public String country{get;set;}
        public String deliveryStartDate{get;set;}
        public String deliveryEndDate{get;set;}
        public String outletContactName{get;set;}
        public String outletContactPhoneNumber{get;set;}
    }
    
    //Return Blank if value is null
    public static Object checkForNull(Object val){
        if(val != null){
            return val;
        }else{
            return '';
        }
    }
}