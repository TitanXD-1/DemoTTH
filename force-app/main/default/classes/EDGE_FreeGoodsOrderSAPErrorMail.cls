/*
*@Name: EDGE_FreeGoodsOrderSAPErrorMail
*@Description: This Class is build to Send Email when SAP transmission Status as Failed
*@History                                                            
*
*VERSION			AUTHOR					DATE				DETAIL
*1.0				Doman/Shivam			27/11/2023			Initial Development: 147971/148542
*1.1				Doman Murmu				11/12/2023			149245 - QA_SAP error message value text is not visible in email
*/
public with sharing class EDGE_FreeGoodsOrderSAPErrorMail {
    public static final String FAIL = 'Failed';		//149245
    
    public static void sendSAPErrorEmail(List<Order__c> updateOrderList,Map<Id,Market_Setting__c> marketSettingMap){
        String languageName = '';
        String body = '';
        List<String> ccEmail = new List<String>();
        List<Order__c> orderList = new List<Order__c>();
        for(Order__c ord:[SELECT Id,Name,CreatedDate,SAP_Error_Message__c,Account__r.Name,Account__r.BillingStreet,Account__r.BillingCity,Account__r.BillingState,Account__r.BillingPostalCode,Account__r.Phone__c,Account__r.Global_Segment__c,Account__r.Global_Sub_Segment__c,Account__r.Country__c,Account__r.Country__r.Code__c FROM Order__c 	//149245 - added SAP_Order_Transmission_Status__c status check
                          WHERE Id =: updateOrderList and SAP_Order_Transmission_Status__c =:FAIL WITH SECURITY_ENFORCED]){
                              if(marketSettingMap.get(ord.Account__r.Country__c).Send_SAP_Order_Failure_Email__c){
                                  orderList.add(ord);
                              }
                          }
        
        if(orderList.size() > 0 && orderList!=null){
            languageName = marketSettingMap.get(orderList[0].Account__r.Country__c).Language__c;
            Map<String, String> labelToTranslatedStrMap = EDGE_UtilityClass.translate(new List<String>{'EDGE_FreeGoodsOrder_SAPBody','EDGE_FreeGoodsSAP_EmailSubject','EDGE_FreeGoods_OrderId','EDGE_AccName','EDGE_AccAddress','EDGE_AccountTelNumber','EDGE_Global_Segment','EDGE_Global_SubSegment','EDGE_OrderPlaced_Date','EDGE_SAPError_Message','EDGE_OrderDetail'}, languageName);
            body = getFreeGoodsSAPErrorMail(orderList,languageName,labelToTranslatedStrMap);
            getCCEmail(orderList,ccEmail);
            List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String currUserEmail = UserInfo.getUserEmail();
            mail.setToAddresses(new List<String> {currUserEmail});
            
            if(!ccEmail.isEmpty()){
                mail.setCcAddresses(ccEmail);
            }
            if(languageName != null && languageName != ''){
                mail.setSubject(labelToTranslatedStrMap.get('EDGE_FreeGoodsSAP_EmailSubject'));
            }else{
                mail.setSubject(Label.EDGE_FreeGoodsSAP_EmailSubject);
            }
            mail.setHtmlBody(body);
            emailList.add(mail);
            Messaging.SendEmailResult[] results = Messaging.sendEmail(emailList);
            if (results[0].success) 
            {
                System.debug(LoggingLevel.INFO, 'The email was sent successfully.');
            } else {
                System.debug(LoggingLevel.ERROR, results[0].errors[0].message);
            }
        }
    }
    
    /**
    * @description : getFreeGoodsSAPErrorMail - Used for sending email when SAP Order Transmission Status is Failed
    * @return : String
    * @param : List<Order__c>,String,Map<String, String>
    * Story	:	147971 - Send Free Goods SAP Order Failure Email to Sales Rep
    */
    public static String getFreeGoodsSAPErrorMail(List<Order__c> orderList,String languageName,Map<String, String> labelToTranslatedStrMap){
        String htmlEmailBody = '';
        if(orderList!=null && orderList.size()>0){
            for(Order__c order: orderList){
                if(languageName != null && languageName != ''){
                    htmlEmailBody = labelToTranslatedStrMap.get('EDGE_FreeGoodsOrder_SAPBody');
                    htmlEmailBody += '<br/>' + '<br/>';
                    htmlEmailBody += labelToTranslatedStrMap.get('EDGE_FreeGoods_OrderId') + ':' + ' ' + order.Name +'<br/>';
                    htmlEmailBody += labelToTranslatedStrMap.get('EDGE_AccName') + ':' + ' ' + order.Account__r.Name +'<br/>';
                    htmlEmailBody += labelToTranslatedStrMap.get('EDGE_AccAddress') + ':' + ' ' + order.Account__r.BillingStreet + ' '+ order.Account__r.BillingCity +', ' + nullCheck(order.Account__r.BillingState) + ' ' + order.Account__r.BillingPostalCode + '<br/>';
                    htmlEmailBody += labelToTranslatedStrMap.get('EDGE_AccountTelNumber') + ':' + ' ' + nullCheck(order.Account__r.Phone__c) + '<br/>';
                    htmlEmailBody += labelToTranslatedStrMap.get('EDGE_Global_Segment') + ':' + ' ' + order.Account__r.Global_Segment__c +'<br/>';
                    htmlEmailBody += labelToTranslatedStrMap.get('EDGE_Global_SubSegment') + ':' + ' ' + order.Account__r.Global_Sub_Segment__c +'<br/>';
                    htmlEmailBody += labelToTranslatedStrMap.get('EDGE_OrderPlaced_Date') + ':' + ' ' + order.CreatedDate.format('dd/MM/YYYY') +'<br/>';
                    htmlEmailBody += labelToTranslatedStrMap.get('EDGE_SAPError_Message') + ':' + ' ' + nullCheck(order.SAP_Error_Message__c) +'<br/>'+'<br/>';
                    htmlEmailBody += labelToTranslatedStrMap.get('EDGE_OrderDetail') + ':' + ' ' + URL.getOrgDomainURL().toExternalForm() + '/' + order.Id;
                }else{
                    htmlEmailBody = Label.EDGE_FreeGoodsOrder_SAPBody;
                    htmlEmailBody += '<br/>' + '<br/>';
                    htmlEmailBody += Label.EDGE_FreeGoods_OrderId + ':' + ' ' + order.Name +'<br/>';
                    htmlEmailBody += Label.EDGE_AccName + ':' + ' ' + order.Account__r.Name +'<br/>';
                    htmlEmailBody += Label.EDGE_AccAddress + ':' + ' ' + order.Account__r.BillingStreet + ' '+ order.Account__r.BillingCity +', ' + nullCheck(order.Account__r.BillingState) + ' ' + order.Account__r.BillingPostalCode + '<br/>';
                    htmlEmailBody += Label.EDGE_AccountTelNumber + ':' + ' ' + nullCheck(order.Account__r.Phone__c) + '<br/>';
                    htmlEmailBody += Label.EDGE_Global_Segment + ':' + ' ' + order.Account__r.Global_Segment__c +'<br/>';
                    htmlEmailBody += Label.EDGE_Global_SubSegment + ':' + ' ' + order.Account__r.Global_Sub_Segment__c +'<br/>';
                    htmlEmailBody += Label.EDGE_OrderPlaced_Date + ':' + ' ' + order.CreatedDate.format('dd/MM/YYYY') +'<br/>';
                    htmlEmailBody += Label.EDGE_SAPError_Message + ':' + ' ' + nullCheck(order.SAP_Error_Message__c) +'<br/>'+'<br/>';
                    htmlEmailBody += Label.EDGE_OrderDetail + ':' + ' ' + URL.getOrgDomainURL().toExternalForm() + '/' + order.Id;
                }
            }
        }
        return htmlEmailBody;
    } 
    
    /**
    * @description : getCCEmail - Populate ccEmail for sending email when SAP Order Transmission Status is Failed
    * @return : void
    * @param : List<Order__c>,List<String>
    * Story	:	147971 - Send Free Goods SAP Order Failure Email to Sales Rep
    */
	public static void getCCEmail(List<Order__c> orderList,List<String> ccEmail){
        Set<string> countryCodeQueue = new Set<string>();
        Set<Id> setUserId = new Set<Id>();
        for(Order__c ordGeoCode :orderList){
            countryCodeQueue.add(ordGeoCode.Account__r.Country__r.Code__c+'_MDM');
        }
        for(GroupMember sgm : [SELECT Group.Name,UserOrGroupId FROM GroupMember WHERE group.name IN :countryCodeQueue and group.type='Queue' WITH SECURITY_ENFORCED]){
            setUserId.add(sgm.UserOrGroupId);
        }
        for(User usr : [Select Id,email from User where Id IN : setUserId WITH SECURITY_ENFORCED]){    
            ccEmail.add(usr.email);  
        }
    }
    
    private static String nullCheck(String str){
        return String.isBlank(str)?'':str;
    }
}