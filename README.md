# Custom Authentication Provider in Salesforce

This guide explains how to create a custom authentication provider in Salesforce, enabling seamless integration with external systems using OAuth 2.0.

## Steps to Create a Custom Authentication Provider

### 1. Create Custom Metadata to Store Auth Credentials

Fields:
- Client Id
- Client Secret
- Base URL
- Authorize Endpoint URL
- Token Endpoint URL
- Scope

### 2. Develop a Custom Auth Provider Class

1. Create an Apex class that extends `Auth.AuthProviderPluginClass`.
2. Implement the required methods:
    - `getCustomMetadataType`: This method returns the custom metadata name created in step #1.
    - `initiate`: This method is mainly used to initiate the authorization code flow.
    - `handleCallback`: Once we've hit the authorization code URL using our code, we'll be taken to the login page by Salesforce followed by the permissions page according to the features of the third-party app we're going to use. Finally, we're redirected to our callback URL with the unique code embedded. That callback is handled by our `handleCallback` method in which we get the `authProviderConfiguration`, which we know is the metadata as a map of string and string. The second parameter is the state using which we can get the query parameters, which if you remember consists of the state and unique authorization code.
    - `refresh`: Returns a new access token, which is used to update an expired access token.
    - `getUserInfo`: Returns information from the custom authentication provider about the current user. This information is used by the registration handler and in other authentication provider flows.

### 3. Create an Authentication Provider

1. Navigate to `Setup` -> `Auth. Providers`.
2. Click `New`.
3. Select Provider Type, the Apex Class name will be available here, created in step #2.
4. Fill in the necessary details; fields created in custom metadata will be available here.
5. Choose Execute Registration As.

### 4. Create a Named Credential

1. Navigate to `Setup` -> `Named Credentials`.
2. Click `New Named Credential`.
3. Fill in the required fields:
    - **Label**: [Your Label]
    - **Name**: [Your Name]
    - **URL**: [Endpoint of the external system]
4. Choose `Identity Type` as `Named Principal` and `Authentication Protocol` as `OAuth 2.0`.
5. Fill in the `Scope`, `Authentication Provider` details.
