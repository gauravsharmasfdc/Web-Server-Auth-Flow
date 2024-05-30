public with sharing class WebServerOAuthFlow extends Auth.AuthProviderPluginClass{

    private string clientId;
    private string clientSecret;
    private string redirectUri;
    private string baseUrl;
    private string authorizeEndpoint;
    private string accessTokenEndpoint;
    private string scope;

    public String getCustomMetadataType(){
        return 'OAuth_Credentials__mdt';
    }

    public System.PageReference initiate(Map<String,String> authProviderConfiguration, String stateToPropagate) {
        this.clientId = authProviderConfiguration.get('Client_Id__c');
        this.baseUrl = authProviderConfiguration.get('Base_URL__c');
        this.authorizeEndpoint = authProviderConfiguration.get('Authorize_Endpoint_URL__c');
        this.redirectUri = authProviderConfiguration.get('Redirect_Uri__c');
        this.scope = authProviderConfiguration.get('Scope__c');
        
        String url = String.format('{0}{1}?scope={2}&client_id={3}&redirect_uri={4}&state={5}&response_type=code', 
                                new String[]{baseUrl, authorizeEndpoint, scope, clientId, redirectUri, stateToPropagate});
        return new PageReference(url);
    }



    public Auth.AuthProviderTokenResponse handleCallback(Map<String, String> authProviderConfiguration, Auth.AuthProviderCallbackState callbackState) {
        // Fetch values from the map using getOrDefault to avoid null pointer exceptions
        this.clientId = authProviderConfiguration.get('Client_Id__c');
        this.clientSecret = authProviderConfiguration.get('Client_Secret__c');
        this.baseUrl = authProviderConfiguration.get('Base_URL__c');
        this.accessTokenEndpoint = authProviderConfiguration.get('Access_Token_Endpoint_URL__c');
        this.redirectUri = authProviderConfiguration.get('Redirect_Uri__c');
        
        // Extract query parameters from the callback state
        Map<String, String> queryParameters = callbackState.queryParameters;
        System.debug('Handle Callback: ' + queryParameters); 
    
        String code = queryParameters.get('code');
    
        if (String.isBlank(code)) {
            throw new Auth.AuthProviderPluginException('Authorization code is missing from the callback parameters.');
        }

        String endpoint = String.format('{0}{1}', new String[]{baseUrl, accessTokenEndpoint});
    
        // Construct the HTTP request
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setEndpoint(endpoint);
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        request.setHeader('Accept', 'application/json');
    
        // Use String.format for cleaner body construction
        String requestBody = String.format(
            'grant_type=authorization_code&code={0}&client_id={1}&client_secret={2}&redirect_uri={3}',
            new String[] { code, clientId, clientSecret, redirectUri }
        );
        request.setBody(requestBody);
    
        // Send the request and process the response
        Http http = new Http();
        HttpResponse httpResponse;
        try {
            httpResponse = http.send(request);
        } catch (Exception e) {
            throw new Auth.AuthProviderPluginException('Failed to send the access token request: ' + e.getMessage());
        }
    
        // Handle non-200 responses
        if (httpResponse.getStatusCode() != 200) {
            throw new Auth.AuthProviderPluginException('Failed to retrieve access token, status: ' + httpResponse.getStatus());
        }
    
        String responseBody = httpResponse.getBody();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        System.debug('Access Token Call Response: ' + response.keySet());
    
        // Extract tokens from the response
        String accessToken = (String) response.get('access_token');
        String refreshToken = (String) response.get('refresh_token');
        String state = queryParameters.get('state');
    
        return new Auth.AuthProviderTokenResponse('CustomSalesforce', accessToken, refreshToken, state);
    }
    

    public override Auth.OAuthRefreshResult refresh(Map<String, String> authProviderConfiguration, String refreshToken) {
        // Fetch values from the map using getOrDefault to avoid null pointer exceptions
        this.baseUrl = authProviderConfiguration.get('Base_URL__c');
        this.accessTokenEndpoint = authProviderConfiguration.get('Access_Token_Endpoint_URL__c');
        this.clientId = authProviderConfiguration.get('Client_Id__c');
    
        // Validate essential values
        if (String.isBlank(this.baseUrl) || String.isBlank(this.accessTokenEndpoint) || String.isBlank(this.clientId) || String.isBlank(refreshToken)) {
            throw new Auth.AuthProviderPluginException('Required parameters are missing.');
        }
    
        String endpoint = String.format('{0}{1}', new String[]{baseUrl, accessTokenEndpoint});
        // Construct the HTTP request
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        request.setHeader('Accept', 'application/json');
    
        // Use String.format for cleaner body construction
        String requestBody = String.format(
            'grant_type=refresh_token&client_id={0}&refresh_token={1}',
            new String[] { this.clientId, refreshToken }
        );
        request.setBody(requestBody);
    
        // Send the request and process the response
        Http http = new Http();
        HttpResponse response;
        try {
            response = http.send(request);
        } catch (Exception e) {
            throw new Auth.AuthProviderPluginException('Failed to send the refresh token request: ' + e.getMessage());
        }
    
        // Handle non-200 responses
        if (response.getStatusCode() != 200) {
            throw new Auth.AuthProviderPluginException('Failed to refresh access token, status: ' + response.getStatus());
        }
    
        String responseBody = response.getBody();
        Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        System.debug('Refresh Token response: ' + responseData);
    
        // Extract tokens from the response
        String accessToken = (String) responseData.get('access_token');
        String newRefreshToken = (String) responseData.get('refresh_token');
    
        return new Auth.OAuthRefreshResult(accessToken, newRefreshToken, null);
    }
    

    public Auth.UserData getUserInfo(Map<String,String> authProviderConfiguration, Auth.AuthProviderTokenResponse response) {
        System.debug('Inside getUserInfo');
        return new Auth.UserData(null, null, null, null, null, null, null, null, null, null, null);
    }


}