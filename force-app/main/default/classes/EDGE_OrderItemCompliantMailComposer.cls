/**********************************************************************
Name: EDGE_OrderItemCompliantMailComposer
=======================================================================
Req: Sending email with order details to Delivery Partner per territory if any defected order is reported
User Story : ES20-12600
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR                   DATE              DETAIL
1.0       Swaraj Samanta        10/11/2022     Email template for replacement request email_SFDC_POS Enhancements(ES20-12600)

***********************************************************************/
public with sharing class EDGE_OrderItemCompliantMailComposer {
    
    /**
*@description  : getDefectedOrderMail - This method populates mail body

*@return : string
*@param : List<Id> OutletIds,Map<Id,Set<EDGE_DefectedOrderWrapper>> orderListMap, Map<String,List<Order_Item__c>> orderListOrderItemMap,String languageName, Map<String, String> labelToTranslatedStrMap,String salesRepName
*/
    public static string getDefectedOrderMail( Set<Id> OutletIds,Map<Id,Set<EDGE_DefectedOrderWrapper>> orderListMap, Map<String,List<Order_Item__c>> orderListOrderItemMap,String languageName, Map<String, String> labelToTranslatedStrMap,String salesRepName){
        String htmlBody = '';
        
        if(languageName != null && languageName != ''){
            htmlBody+= +labelToTranslatedStrMap.get('EDGE_Sender') + '<br/>' ;
            htmlBody+= '<table style="border:1px solid balck;">';
        }
        else{
            htmlBody+= +Label.EDGE_Sender + '<br/>' ;
            htmlBody+= '<table style="border:1px solid balck;">';  
        }
        
        if(OutletIds!=null && OutletIds.size()>0){
            for(Id outlet: OutletIds){
                List<EDGE_DefectedOrderWrapper> orderList =  new List<EDGE_DefectedOrderWrapper>(orderListMap.get(outlet)) ;
                
                if(languageName != null && languageName != ''){
                    htmlBody += '<tr>';
                    htmlBody += '<td style="background: #074465; color: white; font-family: Arial; font: 14px ; font-weight: bold; border:1px solid black ; border-collapse: separate;">'+labelToTranslatedStrMap.get('EDGE_Account_Name')+'</td><td colspan="3" style="border:1px solid black; border-collapse: separate;"> '+orderList[0].accountName+'</td>';
                    htmlBody += '</tr>';
                }else{
                    htmlBody += '<tr>';
                    htmlBody += '<td style="background: #074465; color: white; font-family: Arial; font: 14px ; font-weight: bold; border:1px solid black ; border-collapse: separate;">'+Label.EDGE_Account_Name+'</td><td colspan="5" style="border:1px solid black; border-collapse: separate;"> '+orderList[0].accountName+'</td>';
                    htmlBody += '</tr>';
                }
                for (EDGE_DefectedOrderWrapper ordObj:orderList){
                    if(orderListOrderItemMap.size()>0 && orderListOrderItemMap.containsKey(ordObj.Id)){
                        List<Order_Item__c> orderItemList = orderListOrderItemMap.get(ordObj.Id);
                        Integer ordItemQuantity = orderItemList.size();
                        
                        if(languageName != null && languageName != ''){
                            
                            htmlBody += '<tr>';
                            htmlBody += '<td style="background: #074465; color: white; font-family: Arial; font: 14px ; font-weight: bold; font: 14px ; font-weight: bold; border:1px solid black; border-collapse: separate;">'+labelToTranslatedStrMap.get('EDGE_Order_ID')+'</td><td colspan="3" style="border:1px solid black; border-collapse: separate;"> '+ordObj.orderNumber +'</td>';
                            htmlBody += '</tr>';
                            htmlBody += '<tr>';
                            htmlBody += '<td style="background: #074465; color: white; font-family: Arial; font: 14px ; font-weight: bold; border:1px solid black ; border-collapse: separate;">'+labelToTranslatedStrMap.get('EDGE_OrderCreationDate')+'</td><td colspan="3" style="border:1px solid black; border-collapse: separate;"> '+ ordObj.createdDate.format('dd/MM/yyyy') +'</td>';
                            htmlBody += '</tr>';
                            htmlBody += '<tr>';
                            htmlBody += '<td style="background: #074465; color: white; font-family: Arial; font: 14px ; font-weight: bold; border:1px solid black ; border-collapse: separate;">'+labelToTranslatedStrMap.get('EDGE_ReplacementStatus')+'</td><td colspan="3" style="border:1px solid black; border-collapse: separate;"> '+ '' +'</td>';
                            
                            htmlBody += '</tr>';
                            
                            htmlBody += '<tr>';
                            htmlBody += '<td style="background: #074465; color: white; font-family: Arial; font: 14px ; font-weight: bold; border:1px solid black; border-collapse: separate;">'+labelToTranslatedStrMap.get('EDGE_Brand')+'</td>';
                            htmlBody += '<td style="background: #074465; color: white; font-family: Arial; font: 14px ; font-weight: bold; border:1px solid black; border-collapse: separate;">'+labelToTranslatedStrMap.get('EDGE_ItemName')+'</td>';
                            htmlBody += '<td style="background: #074465; color: white; font-family: Arial; font: 14px ; font-weight: bold; border:1px solid black; border-collapse: separate;">'+labelToTranslatedStrMap.get('EDGE_Status')+'</td>';
                            htmlBody += '<td style="background: #074465; color: white; font-family: Arial; font: 14px ; font-weight: bold; border:1px solid black; border-collapse: separate;">'+labelToTranslatedStrMap.get('EDGE_UnitsAffected')+'</td>';
                            htmlBody += '</tr>'; 
                        }
                        else{//If the Market Setting Language is blank
                            
                            htmlBody += '<tr>';
                            htmlBody += '<td style="background: #074465; color: white; font-family: Arial; font: 14px ; font-weight: bold; font: 14px ; font-weight: bold; border:1px solid black; border-collapse: separate;">'+Label.EDGE_Order_ID+'</td><td colspan="5" style="border:1px solid black; border-collapse: separate;"> '+ordObj.orderNumber +'</td>';
                            htmlBody += '</tr>';
                            htmlBody += '<tr>';
                            htmlBody += '<td style="background: #074465; color: white; font-family: Arial; font: 14px ; font-weight: bold; border:1px solid black ; border-collapse: separate;">'+Label.EDGE_OrderCreationDate+'</td><td colspan="5" style="border:1px solid black; border-collapse: separate;"> '+ordObj.createdDate.format('dd/MM/yyyy') +'</td>';
                            htmlBody += '</tr>';
                            htmlBody += '<tr>';
                            htmlBody += '<td style="background: #074465; color: white; font-family: Arial; font: 14px ; font-weight: bold; border:1px solid black ; border-collapse: separate;">'+Label.EDGE_ReplacementStatus+'</td><td colspan="5" style="border:1px solid black; border-collapse: separate;"> '+ ''+'</td>';
                            htmlBody += '</tr>';
                           
                            htmlBody += '<tr>';
                            htmlBody += '<td style="background: #074465; color: white; font-family: Arial; font: 14px ; font-weight: bold; border:1px solid black; border-collapse: separate;">'+Label.EDGE_Brand+'</td>';
                            htmlBody += '<td style="background: #074465; color: white; font-family: Arial; font: 14px ; font-weight: bold; border:1px solid black; border-collapse: separate;">'+Label.EDGE_ItemName+'</td>';
                            htmlBody += '<td style="background: #074465; color: white; font-family: Arial; font: 14px ; font-weight: bold; border:1px solid black; border-collapse: separate;">'+Label.EDGE_Status+'</td>';
                            htmlBody += '<td style="background: #074465; color: white; font-family: Arial; font: 14px ; font-weight: bold; border:1px solid black; border-collapse: separate;">'+Label.EDGE_UnitsAffected+'</td>';
                            htmlBody += '</tr>';
                        }
                        if(orderListOrderItemMap!=null && orderListOrderItemMap.ContainsKey(ordObj.Id) && ordItemQuantity>0){
                            
                            for(integer i=0;i<ordItemQuantity;i++){
                                htmlBody += '<tr>';
                                htmlBody += '<td height="70" style="border:1px solid black; border-bottom:1px solid black; border-collapse: separate;"">' + ((orderItemList[i].Product__r.Brand_Name__c)!=null? orderItemList[i].Product__r.Brand_Name__c :'') + '</td>';
                                htmlBody += '<td height="70" style="border:1px solid black; border-bottom:1px solid black; border-collapse: separate;"">' +  ((orderItemList[i].Product__r.Product_Full_Name__c)!=null? orderItemList[i].Product__r.Product_Full_Name__c :'') + '</td>';
                                htmlBody += '<td height="70" style="border:1px solid black; border-bottom:1px solid black; border-collapse: separate;"">' + ((orderItemList[i].Status__c)!=null? orderItemList[i].Status__c : '') + '</td>';
                                htmlBody += '<td height="70" style="border:1px solid black; border-bottom:1px solid black; border-collapse: separate;"">' + (orderItemList[i].Pending_Quantity__c) + '</td>';
                                htmlBody += '</tr>';
                            } 
                        }
                    }
                }
                
            }
        }
        htmlBody += '</table>';
        
        if(languageName != null && languageName != ''){
            htmlBody+= +labelToTranslatedStrMap.get('EDGE_DefectedOrderBody') + '<br/>' ;
        }
        else{
            htmlBody+= + Label.EDGE_DefectedOrderBody +'<br/>';
        }
        htmlBody+= + salesRepName + '<br/>';
        return htmlBody;
    }
    
    /**
*@description  : setDefectedOrderEmailBody - This method populates mail subject and cc and recipient

*@return : Messaging.SingleEmailMessage
*@param : String body,List<String> toMail,List<String> ccMail,Messaging.EmailFileAttachment attach,String languageName, Map<String, String> labelToTranslatedStrMap,String identity
*/
    public static Messaging.SingleEmailMessage setDefectedOrderEmailBody(String body,List<String> toMail,List<String> ccMail,Messaging.EmailFileAttachment attach,String languageName, Map<String, String> labelToTranslatedStrMap,String identity){
        
        List<Messaging.SingleEmailMessage> mails =new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage mail=new Messaging.SingleEmailMessage();
        mail.setToAddresses(toMail);
        mail.setCcAddresses(ccMail);
        if(languageName != null && languageName != ''){
            mail.setSubject(labelToTranslatedStrMap.get('EDGE_DefectedOrderMailSubject')+ '-' +identity);
        }
        else{
            mail.setSubject(Label.EDGE_DefectedOrderMailSubject+ '-' +identity);
        }
        mail.setHtmlBody(body);
        mail.saveAsActivity = false;
        if(attach!=null)
        {
            mail.setFileAttachments(new Messaging.EmailFileAttachment[]{attach});
        }
        return mail;
    }
    
}