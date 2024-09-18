/*
* Class Name: EDGE_DeliveryPartnerEmailService
* Author: 
* Description: This class is used to receive inbound email and store email as evidence for POS Replacement Order.
* Created Date: 
* History: 
VERSION    AUTHOR                DATE              DETAIL
1.0		Rajarshi Lahiri			07/11/2022		Initial Development(ES20-13031)
1.1		Rajarshi Lahiri			02/12/2022		ES20-13622(Spanish characters not appearing correctly)


*/
global class EDGE_DeliveryPartnerEmailService implements Messaging.InboundEmailHandler {
	  global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
		  Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
          
          //SELECT Id,AuthorizedSenders,EmailDomainName,IsActive,LocalPart,Function.FunctionName FROM EmailServicesAddress where Function.FunctionName='EDGE_DeliveryPartnerEmailService'
          Id recordIdContentVersion = Schema.SObjectType.ContentVersion.getRecordTypeInfosByDeveloperName().get('Order').getRecordTypeId();

          String subject=email.subject;

          try{
              List<String> recordDataLines = new List<String>();//store to CSV's each data lines
              List<Id> orderList=new List<Id>();
              List<String> orderNames=new List<String>();
              String filename=subject.substringAfter('-')+'.txt';
              String orderDocContent='';
              List<ContentDocumentLink> OrderDoc=[Select Id, ContentDocument.LatestPublishedVersion.VersionData, LinkedEntityId from ContentDocumentLink where LinkedEntityId in (Select Id from Order__c where RecordType.Name = 'POS Order') AND ContentDocument.LatestPublishedVersion.PathOnClient=:filename];
              if(OrderDoc.size()>0 && OrderDoc!=null){
                  string orderListVal = OrderDoc[0].ContentDocument.LatestPublishedVersion.VersionData.tostring();
                  orderListVal = EncodingUtil.base64Decode(EncodingUtil.base64Encode(OrderDoc[0].ContentDocument.LatestPublishedVersion.VersionData)).toString();

                   List<String> orderIds=orderListVal.split(',');
                   for(String line:orderIds){
                        String orderId=line.substring(0, 15);
                        orderList.add(Id.valueOf(orderId));
                    }
              }
              
              //orderList=getOrderIds(orderNames);
              //Iterate over orderIds and store email body for each
              if(orderList.size()>0 && orderList!=null){
                  //System.debug('@@htmlbody'+email.htmlBody);
                  String htmlbody=email.htmlBody;
                  String finalHtml;
                  String htmlMiddle=Label.EmailHead;
                  htmlMiddle = htmlMiddle.replace('{!emailSubject}', email.subject);
                  htmlMiddle = htmlMiddle.replace('{!toAddresses}', email.toAddresses!=null?string.join(email.toAddresses,','):'');
                  htmlMiddle = htmlMiddle.replace('{!fromName}',email.fromName);
                  htmlMiddle = htmlMiddle.replace('{!fromAddress}',email.fromAddress);
                  htmlMiddle = htmlMiddle.replace('{!ccAddresses}',email.ccAddresses!=null?string.join(email.ccAddresses,','):'');
                  htmlMiddle = htmlMiddle.replace('{!inReplyTo}',email.inReplyTo!=null?email.inReplyTo:'');
                  htmlMiddle = htmlMiddle.replace('{!replyTo}',email.replyTo!=null?email.replyTo:'');
                  htmlMiddle = htmlMiddle.replace('{!todayDate}',string.valueofGmt(System.now()));
                  if(htmlbody.contains('<head>')){
                      String htmlTop=htmlbody.substringBefore('<head>');
                      String htmlBottom=htmlbody.substringAfter('</head>');
                      finalHtml=htmlTop+'<head><meta http-equiv="Content-Type" content="text/html; charset=UTF-8">'+htmlMiddle+'</head>'+htmlBottom;//ES20-13622-added encoding utf-8 to handle characters.
                  }
                  else{
                      finalHtml='<html><head><meta http-equiv="Content-Type" content="text/html; charset=UTF-8">'+htmlMiddle+'</head><body>'+htmlbody+'</body></html>';
                  }
                  	//String finalHtml=email.htmlBody;
                    Blob VersionData = Blob.valueOf(finalHtml);//File content
                    ContentVersion cVersion = createContentVersion(VersionData,email.subject+'.html',recordIdContentVersion);
                    insert cVersion;
                     //After saved the Content Verison, get the ContentDocumentId
                    List<ContentDocumentLink> conDocLinkList=new List<ContentDocumentLink>();
                    Id conDocument = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cVersion.Id].ContentDocumentId;
                    
                      for(Id ord:orderList){
                          ContentDocumentLink cDocLink= createContentDocumentLink(conDocument,ord);
                          conDocLinkList.add(cDocLink);
                      }
                    if(!conDocLinkList.isEmpty()){
                    	Database.insert(conDocLinkList,false);
                }
              }

          }
          catch(Exception e){
            system.debug('Exception Caught in EDGE_DeliveryPartnerEmailService class at Line: '+e.getLineNumber()+' Error: '+e.getMessage());
        }
          return result;
      }
        /*
	* @description : Creates ContentVersion Record
	* @return : ContentVersion
	* @param : Blob versionData : Content/VersionData of ContentVersion, String fileName : Title of ContentVersion ,String RecordTypeId : RecordType of ContentVersion
	*/
    public static ContentVersion createContentVersion(Blob versionData, String fileName, String recordTypeId){
        ContentVersion cVersion = new ContentVersion();
        cVersion.RecordTypeId = recordTypeId;
        cVersion.Content_Type__c = 'Other';
        cVersion.ContentLocation = 'S'; //S-Document is in Salesforce. E-Document is outside of Salesforce. L-Document is on a Social Netork.
        cVersion.PathOnClient = fileName;	//File name with extention
        cVersion.Title = fileName;	//Name of the file
        cVersion.VersionData = versionData;
        return cVersion;
    }
    
    /*
	* @description : Creates ContentDocumentLink Record to link ContentDocument & ContentVersion
	* @return : ContentDocumentLink
	* @param : String contentDocumentId : ContentDocumentId of ContentVersion, String orderId : ParentId for ContentDocumentLink
	*/
    public static ContentDocumentLink createContentDocumentLink(String contentDocumentId,String orderId){
        ContentDocumentLink cDocLink = new ContentDocumentLink();
        cDocLink.ContentDocumentId = contentDocumentId;	//Add ContentDocumentId
        cDocLink.LinkedEntityId = orderId;	//Add attachment parentId
        cDocLink.ShareType = 'I';	//V - Viewer permission. C - Collaborator permission. I - Inferred permission.
        cDocLink.Visibility = 'InternalUsers';	//AllUsers, InternalUsers, SharedUsers
        return cDocLink;
    }
  }