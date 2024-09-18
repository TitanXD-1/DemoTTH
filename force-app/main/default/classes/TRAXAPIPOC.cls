public class TRAXAPIPOC {
    @AuraEnabled(cacheable=true)
    public static String getErrorFile(String apiResponce, String fileType){
        System.debug(apiResponce);
        Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(apiResponce);
        String fileUrl = fileType=='fileId'? 'https://services.traxretail.com/api/v5/diageoga1-sand/store-import/file/'+ (String) jsonMap.get('fileId'): (String) jsonMap.get('errorJSON');
        System.debug('fileUrl: ' + fileUrl);
        
        String boundary = '--------------------------848953448533366555074091';
        String accessToken = 'mcFlwQHtVIvspk8JdZsjPqfezs2wJOcKLPpaDQ94iLCCc76iHkolQxQPa4haDxqCki0ydtaJ1yPrI8FDVLICL3eQVIG02TuUy3gkKCKRfCfaezyGvoYOsZO6eTMAt4jz9wn5fT7LhfzTAZxYez2vUxBc';
        String responseBody='';
        //String fileUrl  = 'https://services.traxretail.com/api/v5/diageoga1-sand/store-import/file/'+fileId;

        HttpRequest request = new HttpRequest();
        request.setHeader('Content-Type', 'multipart/form-data; boundary='+boundary);
        request.setHeader('Authorization', 'Auth-Token '+accessToken);
        request.setMethod('GET');
        system.debug('@@targetURL' + fileUrl);    
        request.setEndpoint(fileUrl);
        request.setCompressed(false);
        request.setTimeout(120000); 
        
        Http http = new Http();
        HttpResponse res;
         try {
            res = http.send(request);
            
            if (res.getStatusCode() == 200) {
                String responce = res.getBody();
                System.debug(responce);
                //String responceCSV = convertJSONtoCSV(responce);
                //System.debug(responceCSV);
                return responce;
            } else {
                System.debug('Failed to download file. Status code: ' + res.getStatusCode());
                return null;
            }
        } catch (Exception e) {
            System.debug('Error during file download: ' + e.getMessage());
            return null;
        }
    }
    
   
    
    
    public static void getResponce(){
        String fileContent = createJSONAttachment();
        String entityType = 'store';
        String fileName = 'OutletFile.json';
        String boundary = '--------------------------848953448533366555074091';
        String header='--' + boundary +'\r\nContent-Disposition: form-data; name="entity_type"\r\n\r\n'+entityType+'\r\n'+                 
            '--' + boundary +'\r\nContent-Disposition: form-data; name="file_format"\r\n\r\nJSON\r\n'+
            '--' + boundary +'\r\nContent-Disposition: form-data; name="file"; filename="' + fileName + '"'+
            '\r\nContent-Type: application/json\r\n\r\n';
        
        String footer = '--'+boundary+'--';             
        String bodyEncoded = fileContent +'\r\n';
        String bodyPayload = header + bodyEncoded + footer  ;
        String targetURL = 'https://services.traxretail.com/api/v5/diageoga1-sand/store-import/upload';
        String accessToken = 'mcFlwQHtVIvspk8JdZsjPqfezs2wJOcKLPpaDQ94iLCCc76iHkolQxQPa4haDxqCki0ydtaJ1yPrI8FDVLICL3eQVIG02TuUy3gkKCKRfCfaezyGvoYOsZO6eTMAt4jz9wn5fT7LhfzTAZxYez2vUxBc';
        String responseBody='';
        // Send HTTP request
        HttpRequest request = new HttpRequest();
        request.setHeader('Content-Type', 'multipart/form-data; boundary='+boundary);
        request.setHeader('Authorization', 'Auth-Token '+accessToken);
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
    
    
    public static void getImportStatus(String importID){
        String boundary = '--------------------------848953448533366555074091';
        String accessToken = 'mcFlwQHtVIvspk8JdZsjPqfezs2wJOcKLPpaDQ94iLCCc76iHkolQxQPa4haDxqCki0ydtaJ1yPrI8FDVLICL3eQVIG02TuUy3gkKCKRfCfaezyGvoYOsZO6eTMAt4jz9wn5fT7LhfzTAZxYez2vUxBc';
        String targetURL = 'https://services.traxretail.com/api/v5/diageoga1-sand/store-import/'+importID;
        String responseBody='';
        // Send HTTP request
        HttpRequest request = new HttpRequest();
        request.setHeader('Content-Type', 'multipart/form-data; boundary='+boundary);
        request.setHeader('Authorization', 'Auth-Token '+accessToken);
        request.setMethod('GET');
        system.debug('@@targetURL' + targetURL);    
        request.setEndpoint(targetURL);
        //request.setBody(BodyPayload);
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
    
    public static String createJSONAttachment() {
        // Step 1: Create your data
        Map<String, Object> dataMap = new Map<String, Object>();
        dataMap.put('street', 'Leipziger Platz 11');
        dataMap.put('store_type_name', 'On Trade');
        dataMap.put('store_number', '001070000031MSdAAM');
        dataMap.put('store_name', 'Eleven');
        dataMap.put('store_display_name', 'Eleven');
        dataMap.put('state_name', 'Germany');
        dataMap.put('retailer_name', 'Spar');
        dataMap.put('region_name', 'Berlin');
        dataMap.put('postal_code', '10117');
        dataMap.put('longitude', 3.379749);
        dataMap.put('latitude', 2.509449);
        dataMap.put('is_active', true);
        dataMap.put('city', 'Berlin');
        dataMap.put('additional_attribute_9', '');
        dataMap.put('additional_attribute_8', 'Neighbourhood Bar Mainstream');
        dataMap.put('additional_attribute_7', 'Getränke Preuss Münchhagen Gmbh Berlin');
        dataMap.put('additional_attribute_6', '');
        dataMap.put('additional_attribute_5', '');
        dataMap.put('additional_attribute_4', 'BRONZE');
        dataMap.put('additional_attribute_3', 'The Usual at the Bar');
        dataMap.put('additional_attribute_2', 'Bar');
        dataMap.put('additional_attribute_16', '');
        dataMap.put('additional_attribute_10', 'Modern Bar');
        dataMap.put('additional_attribute_1', 'On Trade');
        
        List <Map<String, Object>> dataMapList = new List<Map<String, Object>>();
        dataMapList.add(dataMap);
        // Step 2: Serialize the data to JSON
        return JSON.serializePretty(dataMapList);
        
        
    }
    
    public void sendRequest() {
        // Create an instance of HttpRequest
        HttpRequest req = new HttpRequest();
        
        // Set the endpoint URL
        req.setEndpoint('https://example.com/api/endpoint');
        
        // Set the HTTP method (POST in this case)
        req.setMethod('POST');
        
        // Set the content type to multipart/form-data
        String boundary = '----WebKitFormBoundary7MA4YWxkTrZu0gW';
        req.setHeader('Content-Type', 'multipart/form-data; boundary=' + boundary);
        
        // Create a sample JSON content
        String jsonContent = '{"key1": "value1", "key2": "value2"}';
        
        // Construct the form-data body
        String body = '--' + boundary + '\r\n' +
            'Content-Disposition: form-data; name="file"; filename="sample.json"\r\n' +
            'Content-Type: application/json\r\n\r\n' +
            jsonContent + '\r\n' +
            '--' + boundary + '--';
        
        // Set the body of the request
        req.setBody(body);
        
        // Create an instance of Http
        Http http = new Http();
        
        // Send the request
        HttpResponse res = http.send(req);
        
        // Process the response
        if (res.getStatusCode() == 200) {
            System.debug('Response: ' + res.getBody());
        } else {
            System.debug('Error: ' + res.getStatusCode() + ' ' + res.getStatus());
        }
    }
    public static void attachFileAsContentVersion(Id recordId, String fileUrl) {
        Blob fileBlob = downloadFileFromUrl(fileUrl);
        String fileName = 'output.xlsx';
        
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = fileName;
        contentVersion.PathOnClient = fileName;
        contentVersion.VersionData = fileBlob;
        insert contentVersion;
        
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
        contentDocumentLink.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId;
        contentDocumentLink.LinkedEntityId = recordId;
        contentDocumentLink.ShareType = 'V';
        contentDocumentLink.Visibility = 'AllUsers';
        insert contentDocumentLink;
    }
    
    public static Blob downloadFileFromUrl(String fileUrl) {
        String boundary = '--------------------------848953448533366555074091';
        String accessToken = 'mcFlwQHtVIvspk8JdZsjPqfezs2wJOcKLPpaDQ94iLCCc76iHkolQxQPa4haDxqCki0ydtaJ1yPrI8FDVLICL3eQVIG02TuUy3gkKCKRfCfaezyGvoYOsZO6eTMAt4jz9wn5fT7LhfzTAZxYez2vUxBc';
        String responseBody='';

        HttpRequest request = new HttpRequest();
        request.setHeader('Content-Type', 'multipart/form-data; boundary='+boundary);
        request.setHeader('Authorization', 'Auth-Token '+accessToken);
        request.setMethod('GET');
        system.debug('@@targetURL' + fileUrl);    
        request.setEndpoint(fileUrl);
        //request.setBody(BodyPayload);
        request.setCompressed(false);
        request.setTimeout(120000); 
        
        Http http = new Http();
        HttpResponse response = http.send(request);
        
        if (response.getStatusCode() == 200) {
            return response.getBodyAsBlob();
        } else {
            throw new CalloutException('Failed to download file: ' + response.getStatus());
        }
    }
    
}