<?php
require __DIR__ . '/vendor/autoload.php';

use QuickBooksOnline\API\DataService\DataService;
use QuickBooksOnline\API\Facades\Customer;

// ----------------------------------------------------------
// Step 1: Define configuration and environment details
// ----------------------------------------------------------
$config = [
    'auth_mode'         => 'oauth2',
    'ClientID'          => 'YOUR-CLIENT-ID',
    'ClientSecret'      => 'YOUR-CLIENT-SECRET',
    'RedirectURI'       => 'https://yourcrm.com/quickbooks/callback', 
    'scope'             => 'com.intuit.quickbooks.accounting',
    'baseUrl'           => 'Development', // or 'Production'
];

// ----------------------------------------------------------
// Step 2: Initialize the DataService instance
// ----------------------------------------------------------
$dataService = DataService::Configure($config);

// ----------------------------------------------------------
// Step 3: OAuth 2.0 - If we do not have an access token, we
//         must redirect the user to QuickBooks to sign in
// ----------------------------------------------------------
session_start();

// If you do not have the OAuth 2.0 authorization code, redirect user to get it:
if (!isset($_GET['code']) && !isset($_SESSION['sessionAccessToken'])) {
    // Obtain the OAuth authorization URL from QuickBooks
    $OAuth2LoginHelper = $dataService->getOAuth2LoginHelper();
    $authorizationUrl = $OAuth2LoginHelper->getAuthorizationCodeURL();
    
    // Redirect the user to QuickBooks for authorization
    header("Location: " . $authorizationUrl);
    exit;
}

// ----------------------------------------------------------
// Step 4: If user is coming back from QuickBooks, exchange
//         the auth code for access/refresh tokens
// ----------------------------------------------------------
if (isset($_GET['code']) && !isset($_SESSION['sessionAccessToken'])) {
    $OAuth2LoginHelper = $dataService->getOAuth2LoginHelper();
    $accessToken = $OAuth2LoginHelper->exchangeAuthorizationCodeForToken($_GET['code'], $_GET['realmId']);
    
    // Save tokens to session (for demo). Ideally, store securely (DB or vault).
    $_SESSION['sessionAccessToken'] = $accessToken;
    $_SESSION['realmId']            = $_GET['realmId'];
    
    // Redirect to script again without 'code' param to avoid re-processing
    header('Location: quickbooks_integration_demo.php');
    exit;
}

// ----------------------------------------------------------
// Step 5: Use the existing session token to set up DataService
// ----------------------------------------------------------
if (isset($_SESSION['sessionAccessToken'])) {
    $dataService->updateOAuth2Token($_SESSION['sessionAccessToken']);
    $dataService->setLogLocation(__DIR__ . '/logs');
    $dataService->throwExceptionOnError(true);
    
    // Ensure the tokens are valid (refresh if needed)
    $oauth2LoginHelper = $dataService->getOAuth2LoginHelper();
    $refreshToken = $oauth2LoginHelper->refreshToken();
    // Update the stored token with the refreshed one
    $_SESSION['sessionAccessToken'] = $dataService->getOAuth2AccessToken();
}

// ----------------------------------------------------------
// Step 6: Call QuickBooks Online APIs
// For example, create/update a Customer object
// ----------------------------------------------------------

// Example: Simulate retrieving a CRM contact that you want to sync to QuickBooks
$crmContact = [
    'first_name'  => 'John',
    'last_name'   => 'Doe',
    'email'       => 'john.doe@example.com',
    'phone'       => '(555) 555-1234',
];

// Create a new Customer in QuickBooks from this CRM contact
$newCustomerObj = Customer::create([
    "GivenName"   => $crmContact['first_name'],
    "FamilyName"  => $crmContact['last_name'],
    "PrimaryEmailAddr" => [
        "Address" => $crmContact['email']
    ],
    "PrimaryPhone" => [
        "FreeFormNumber" => $crmContact['phone']
    ]
]);

// Push the new customer to QuickBooks
try {
    $resultingCustomer = $dataService->Add($newCustomerObj);
    echo "Successfully created new Customer with Id: " . $resultingCustomer->Id;
} catch (Exception $e) {
    echo "Error creating Customer in QuickBooks: " . $e->getMessage();
}
?>
