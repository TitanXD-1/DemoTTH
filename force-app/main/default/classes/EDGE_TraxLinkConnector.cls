/**********************EDGE_TraxLinkConnector***************************************************************************
Apex Class Name     : EDGE_TraxLinkConnector
Version             : 1.0
Date Created        : 04th June-2019
Function            :  
Author              : Anuja Chattopadhyay
Modification Log    :
--------------------------------------------------------------------------------------------------
* Developer             Date                    Description
* ---------------       -----------             ----------------------------------------------
***************************************************************************************************************/
global with sharing class EDGE_TraxLinkConnector{
    
    public static string uploadFile(String fileContent,String countryCode,String fileName, string entityType){
        
        String accessToken = '';
        String targetURL = '';
        String responseBody='';
        if(Schema.SObjectType.TRAX_Country_Setting__mdt.isAccessible()){
            TRAX_Country_Setting__mdt traxSetting = [Select Country__c,Endpoint_URL__c,Trax_Authorization_Token__c 
                                                     from TRAX_Country_Setting__mdt where Country__c =:countryCode];
            
            accessToken = traxSetting.Trax_Authorization_Token__c;
            targetURL = traxSetting.Endpoint_URL__c;
            String boundary = '--------------------------848953448533366555074091';
            
            String header='--' + boundary +'\r\nContent-Disposition: form-data; name="entity_type"\r\n\r\n'+entityType+'\r\n'+                 
                '--' + boundary +'\r\nContent-Disposition: form-data; name="file_format"\r\n\r\nJSON\r\n'+
                '--' + boundary +'\r\nContent-Disposition: form-data; name="file"; filename="' + fileName + '"'+
                '\r\nContent-Type: application/json\r\n\r\n';
            
            String footer = '--'+boundary+'--';             
            String bodyEncoded = fileContent +'\r\n';
            String bodyPayload = header + bodyEncoded + footer  ;
            
            if(String.isNotBlank(accessToken) && String.isNotBlank(targetURL)){
                // Send HTTP request
                HttpRequest request = new HttpRequest();
                request.setHeader('Content-Type', 'multipart/form-data; boundary='+boundary);
                request.setHeader('Authorization', 'Auth-Token'+accessToken);
                request.setMethod('POST');
                system.debug('@@targetURL' + targetURL);    
                request.setEndpoint(targetURL);
                request.setBody(BodyPayload);
                request.setCompressed(false);
                request.setTimeout(120000); 
                
                
                // Get HTTP response
                Http http = new Http();
                HttpResponse response = http.send(request);
                responseBody= response.getBody();
                Integer responseCode = response.getStatusCode();
                system.debug('@@responseBody: ' + responseBody);
                system.debug('@@responseCode: ' + responseCode);
                
            }
        }
        return responseBody;
    }
    
}