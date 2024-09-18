/**
* @Name: MulesoftCustomAuthProvider
* 
* Purpose: Custom Auth Provider Plugin Class
* 
* History                                                            
* -                                                           
* VERSION   AUTHOR                  DATE            DETAIL
* 1.0                               22/02/2023      NCP-7816
**/

public with sharing class MulesoftCustomAuthProvider extends Auth.AuthProviderPluginClass {
    
    public static final String CUSTOM_METADATA_TYPE = 'MulesoftCustomAuth__mdt';
    
    public String getCustomMetadataType() {
        return CUSTOM_METADATA_TYPE;
    }
    
    @SuppressWarnings('PMD.ApexOpenRedirect')
    public PageReference initiate(Map<String, String> config, String stateToPropagate) {        
        String url = config.get('CallbackURL__c') + '?state=' + stateToPropagate;       
        return new PageReference(url);
    }
    
    public Auth.AuthProviderTokenResponse handleCallback(Map<String, String> config, Auth.AuthProviderCallbackState callbackState) {
        
        final String accTkn = this.retrieveToken(config);
        final String state = callbackState.queryParameters.get('state');
                
        return new Auth.AuthProviderTokenResponse(
            config.get('APIName__c'), 
            accTkn, 
            'fakeRefreshToken', 
            state
        );
    }
    
    public Auth.UserData getUserInfo(Map<String, String> config, Auth.AuthProviderTokenResponse response) {
        return new Auth.UserData('fakeId', 'first', 'last', 'full', 'email', 'link', null, null, null, null, null);
    }
        
    public override Auth.OAuthRefreshResult refresh(Map<String, String> config, String refreshToken) {
        final String accTkn = this.retrieveToken(config);
        return new Auth.OAuthRefreshResult(accTkn, 'fakeRefreshToken');
    }
    
    
    private String retrieveToken(Map<String, String> config) {            
        final String clntKey = config.get('ClientID__c'); 
        final String clntSec = config.get('ClientSecret__c'); 
        final String accTknUrl = config.get('Token_URL__c'); 
                        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(accTknUrl);
        req.setHeader('Content-Type', 'application/json;charset=UTF-8');
        req.setMethod('POST');
        req.setHeader('grant_type', 'client_credentials');
        req.setHeader('client_id', clntKey);
        req.setHeader('client_secret',clntSec);
        String body = '{"message":"token request"}';
        req.setBody(body);
        Http h = new Http();
        HttpResponse res = h.send(req);

        // get token from response
        return this.getTokenFromHttpResponse(res);
    }

    /**
     * Get the accTkn from Http response.
     *
    */
    private String getTokenFromHttpResponse(HttpResponse res) {
        System.debug(Logginglevel.INFO, 'Body --> ' + res.getBody());
        final Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        final String errorCode = (String) data.get('error');
        string errDescTrace ='';
        if (String.isNotEmpty(errorCode)) {
            String errorDesc = (String) data.get('error_description');
            String traceId = (String) data.get('trace_id');
            errDescTrace = errorCode + 'TraceId '+traceId +'Desc '+errorDesc; 
            return errDescTrace ;
        } else {
            return (String) data.get('access_token');
        }
    }
    
}