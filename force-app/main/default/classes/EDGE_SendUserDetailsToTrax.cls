/**********************************************************************
Name: EDGE_GenerateStoreJSON
=======================================================================
Purpose: Generate Additional Attributes for Trax
=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR                  DATE              DETAIL
1.0         Srutadeba Chanda       31/05/2019        (ES20-1582,ES20-162)
2.0         Saikiran			   22/07/2024        155268

***********************************************************************/
public class EDGE_SendUserDetailsToTrax{

    public String countryCode;  
    
    public class userListWrraper{
        string first_name;
        string last_name;
        string email_address;
        string mobile_number;
        set<Id> store_numbers;
        boolean is_deleted;
   
    }
    
    
    
    public string sendUserStoreAssignment(List<User> userList,Map<Id,set<Id>> userOutletMemberMap, string countryCode){
        List<userListWrraper> userWrapper= new List<userListWrraper>();
        string responseMsg='';
        for(user uobj: userList){
            userListWrraper wrap= new userListWrraper();
            
            wrap.first_name=uobj.firstname;
            wrap.last_name=uobj.lastName;
            wrap.email_address=uobj.email;
            wrap.mobile_number=uobj.MobilePhone;
            if(!uobj.isActive || !uObj.Trax_User__c){
                wrap.is_deleted=false;//155268
            }
           
            else if(userOutletMemberMap!= null && userOutletMemberMap.containsKey(uobj.id) && uObj.Trax_User__c){
               wrap.store_numbers=UserOutletMemberMap.get(uobj.Id);     
                wrap.is_deleted=false;
            
            }                
            userWrapper.add(wrap);
        }
        string fileContent= json.serializepretty(userWrapper);
        system.debug(LoggingLevel.DEBUG,'assignment@@@@ '+fileContent);
        //sendToTrax(fileContent,'userAssignment.JSON');        
        responseMsg= EDGE_TraxLinkConnector.uploadFile(fileContent,countryCode,'userAssignment.JSON','user');
        return responseMsg;
    }
    
    
    /*public Void sendToTrax(string fileContent, string fileName){

    String AccessToken = '';
    String targetURL = '';
        if(Gen2_Country_Settings__c.getAll().containsKey(countryCode)){
             AccessToken = Gen2_Country_Settings__c.getAll().get(countryCode).Trax_Authorization_Token__c;   
             targetURL = Gen2_Country_Settings__c.getAll().get(countryCode).Trax_Endpoint__c;
        }
        
        String boundary = '--------------------------848953448533366555074091';
    
        string header='--' + boundary +'\r\nContent-Disposition: form-data; name="entity_type"\r\n\r\nuser\r\n'+                 
                   '--' + boundary +'\r\nContent-Disposition: form-data; name="file_format"\r\n\r\nJSON\r\n'+
                   '--' + boundary +'\r\nContent-Disposition: form-data; name="file"; filename="' + fileName + '"'+
                   '\r\nContent-Type: application/json\r\n\r\n';
   
      String footer = '--'+boundary+'--';             
      String bodyEncoded = fileContent +'\r\n';
      String bodyPayload = header + bodyEncoded + footer  ;
      
         
      HttpRequest req = new HttpRequest();
      req.setHeader('Content-Type','multipart/form-data; boundary='+boundary);
      req.setHeader('Authorization', 'Auth-Token'+AccessToken);
      req.setMethod('POST');
      req.setEndpoint(targetURL);
      req.setBody(BodyPayload);
      req.setTimeout(120000);
      req.setCompressed(false);
      system.debug(bodypayload);
      Http httpToSend = new Http();
      HTTPResponse res = httpToSend.send(req);
                               
      Integer responseCode = res.getStatusCode();
      String responseBody = res.getBody();
      system.debug('responseCode++ ' + responseCode);
      system.debug('Response Body++' + responseBody);

    }*/
}