/**
* @Name: MulesoftCustomAuthProviderTest
* 
* Purpose: Test class for MulesoftCustomAuthProvider
* 
* History                                                            
* -                                                           
* VERSION	AUTHOR            		DATE            DETAIL
* 1.0		Subhrojit Majumdar		22/02/2023		NCP-7816
**/
@isTest
public class MulesoftCustomAuthProviderTest {
    
    private static final String OAUTH_TOKEN = 'testToken';
    private static final String REFRESH_TOKEN = 'fakeRefreshToken';
    private static final String KEY = 'testKey';
    private static final String AUTH_URL = 'http://www.dummy.com/authurl';
    private static final String SECRET = 'testSecret';
    private static final String REDIRECT_URL = 'http://localhost/services/authcallback/orgId/Concur';
    private static final String API_USER_URL = 'www.concursolutions.com/user/api';
    private static final String STATE_TO_PROPAGATE = 'mocktestState';
    
    /**
     * @Name : testInitiate
	 * @description : This method is used to test the initiate() method of the MulesoftCustomAuthProvider class
	 */
    @isTest
    public static void testInitiate(){
        Map<String,String> authProviderConfiguration = setupAuthProviderConfig();
        PageReference actualUrl;
        PageReference expectedUrl =  new PageReference(authProviderConfiguration.get('CallbackURL__c') + '?state=' + STATE_TO_PROPAGATE);
        
        Test.startTest();
        MulesoftCustomAuthProvider mcap = new MulesoftCustomAuthProvider();
        actualUrl =  mcap.initiate(authProviderConfiguration, STATE_TO_PROPAGATE);
        Test.stopTest();
        
        System.assertEquals(expectedUrl.getUrl(), actualUrl.getUrl(), 'URLs did not match');
        Assert.areEqual(expectedUrl.getUrl(), actualUrl.getUrl());
    }
    
    /**
     * @Name : testInitiate
	 * @description : This method is used to test the handleCallback() method of the MulesoftCustomAuthProvider class
	 */
    @isTest
    public static void testHandleCallback() {
        Map<String,String> authProviderConfiguration = setupAuthProviderConfig();
        Test.setMock(HttpCalloutMock.class, new MulesoftMockHttpResponseGenerator());
        
        Map<String,String> queryParams = new Map<String,String>();
        queryParams.put('state',authProviderConfiguration.get('State_c'));
        Auth.AuthProviderCallbackState cbState = new Auth.AuthProviderCallbackState(null,null,queryParams);
        
        Auth.AuthProviderTokenResponse expectedAuthProvResponse = new Auth.AuthProviderTokenResponse('MulesoftCustomAuthProvider', OAUTH_TOKEN, REFRESH_TOKEN, null);
        
        Test.startTest();
        MulesoftCustomAuthProvider mcap = new MulesoftCustomAuthProvider();
        Auth.AuthProviderTokenResponse actualAuthProvResponse = mcap.handleCallback(authProviderConfiguration, cbState);
        Test.stopTest();
        
        System.assertEquals(expectedAuthProvResponse.oauthSecretOrRefreshToken, actualAuthProvResponse.oauthSecretOrRefreshToken, 'Tokens do not match');
        Assert.areEqual(expectedAuthProvResponse.oauthSecretOrRefreshToken, actualAuthProvResponse.oauthSecretOrRefreshToken);
    }
    
    /**
     * @Name : testGetUserInfo
	 * @description : This method is used to test the getUserInfo() method of the MulesoftCustomAuthProvider class
	 */
    @isTest
    public static void testGetUserInfo(){
        Map<String,String> authProviderConfiguration = setupAuthProviderConfig();
        Test.setMock(HttpCalloutMock.class, new MulesoftMockHttpResponseGenerator());
        Auth.UserData userData;
        
        Test.startTest();
        MulesoftCustomAuthProvider mcap = new MulesoftCustomAuthProvider();
        userData = mcap.getUserInfo(authProviderConfiguration, null);
        Test.stopTest();
        
        System.assert(userData != null, 'User data was not retrieved');
        Assert.isNotNull(userData);
    }
    
    /**
     * @Name : testRefresh
	 * @description : This method is used to test the refresh() method of the MulesoftCustomAuthProvider class
	 */
    @isTest
    public static void testRefresh(){
        Map<String,String> authProviderConfiguration = setupAuthProviderConfig();
        Test.setMock(HttpCalloutMock.class, new MulesoftMockHttpResponseGenerator());
        Auth.OAuthRefreshResult refreshResult;
        
        Test.startTest();
        MulesoftCustomAuthProvider mcap = new MulesoftCustomAuthProvider();
        refreshResult = mcap.refresh(authProviderConfiguration, null);
        Test.stopTest();
        
        System.assertEquals('fakeRefreshToken', refreshResult.refreshToken, 'Refresh tokens do not match');
        Assert.areEqual('fakeRefreshToken', refreshResult.refreshToken);
    }
        
    /**
     * @Name : setupAuthProviderConfig
	 * @description : This method is used to create dummy Auth Provider Configuration
	 */
    private static Map<String,String> setupAuthProviderConfig(){
        Map<String,String> authProviderConfiguration = new Map<String,String>();
        authProviderConfiguration.put('Key__c', KEY);
        authProviderConfiguration.put('Auth_Url__c', AUTH_URL);
        authProviderConfiguration.put('Secret__c', SECRET);
        authProviderConfiguration.put('CallbackURL__c',REDIRECT_URL);
        authProviderConfiguration.put('APIName__c','MulesoftCustomAuthProvider');
        authProviderConfiguration.put('ClientID__c', '2f2291b722fa4342ac7e8fbb0e622472');
        authProviderConfiguration.put('ClientSecret__c','277968F2cb9F47d3bdBCb66907CfAcFa');
        authProviderConfiguration.put('Token_URL__c',API_USER_URL);
        authProviderConfiguration.put('Token_URL__c',API_USER_URL);
        return authProviderConfiguration;
    }
    
    //Mock Http generator class for MulesoftCustomAuthProvider 
    public  class MulesoftMockHttpResponseGenerator implements HttpCalloutMock{
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse httpResponse = new HttpResponse();
            httpResponse.setHeader('Content-Type', 'application/json');
            httpResponse.setBody('{"example":"test", "error":"errorTest"}');
            httpResponse.setStatusCode(200);
            return httpResponse;
        }
    }
}