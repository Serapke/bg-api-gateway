# API Gateway Postman Collection

This directory contains Postman collection and environment files for testing the Board Game Planner API Gateway.

## Files

- `API_Gateway_Collection.json` - Complete Postman collection with all endpoints
- `API_Gateway_Environment.json` - Environment variables for development
- `README.md` - This documentation file

## Setup Instructions

### 1. Import Collection and Environment

1. Open Postman
2. Click **Import** button
3. Import both files:
   - `API_Gateway_Collection.json`
   - `API_Gateway_Environment.json`

### 2. Configure Environment

1. Select the **API Gateway - Development** environment
2. Update the following variables if needed:
   - `gateway_url`: Your API Gateway URL (default: http://localhost:3000)
   - `user_service_url`: Your User Service URL (default: http://localhost:8080)
   - `user_email`: Valid test user email
   - `user_password`: Valid test user password

### 3. Start Services

Make sure both services are running:

```bash
# Start API Gateway (Rails)
cd api-gateway
rails server -p 3000

# Start User Service (in another terminal)
# Follow your user service startup instructions
```

## Collection Structure

### 📁 Authentication
- **Login** - Authenticate user and get tokens
- **Refresh Token** - Get new access token using refresh token

### 📁 Health Check
- **Gateway Health Check** - Check if API Gateway is running

### 📁 Error Scenarios
- **Invalid Login Credentials** - Test failed authentication
- **Request without Token** - Test unauthorized access
- **Request with Invalid Token** - Test with malformed token
- **Service Not Found** - Test unknown service routing

## Features

### 🔐 Automatic Token Management
- Login automatically saves access and refresh tokens
- Pre-request script automatically refreshes expired access tokens
- No manual token management required

### 🧪 Built-in Tests
Each request includes test scripts that verify:
- Response status codes
- Response data structure
- Token presence and validity
- Error handling

### 🔄 Token Auto-Refresh
The collection includes a pre-request script that:
- Checks if access token is about to expire (5-minute buffer)
- Automatically refreshes using the refresh token
- Updates environment variables with new tokens

## Usage Workflow

### 1. First Time Setup
1. Update `user_email` and `user_password` with valid credentials
2. Run the **Login** request
3. Tokens will be automatically saved to environment

### 2. Making API Calls
1. All authenticated requests automatically use the saved access token
2. If token expires, it will be automatically refreshed
3. Check the **Tests** tab results for validation

### 3. Testing Error Scenarios
1. Use the **Error Scenarios** folder to test various failure cases
2. Verify error responses and status codes

## Environment Variables

| Variable | Description | Auto-populated |
|----------|-------------|----------------|
| `gateway_url` | API Gateway base URL | No |
| `user_service_url` | User Service base URL | No |
| `user_email` | Test user email | No |
| `user_password` | Test user password | No |
| `access_token` | JWT access token | Yes |
| `refresh_token` | JWT refresh token | Yes |
| `access_token_expires_at` | Access token expiration | Yes |
| `refresh_token_expires_at` | Refresh token expiration | Yes |
| `user_id` | Current user ID | Yes |
| `collection_id` | Collection ID for testing | Yes |

## Troubleshooting

### Common Issues

1. **Connection Refused**
   - Ensure API Gateway is running on the correct port
   - Check `gateway_url` environment variable

2. **Authentication Failed**
   - Verify `user_email` and `user_password` are correct
   - Ensure User Service is running and accessible

3. **Service Unavailable**
   - Check if User Service is running
   - Verify `USER_SERVICE_URL` configuration in API Gateway

4. **Token Expired**
   - Use the **Refresh Token** request manually
   - Or wait for automatic refresh in the next request

### Debug Tips

1. Check the **Console** tab in Postman for debug logs
2. Look at the **Tests** tab for detailed test results
3. Use **Postman Console** (View → Show Postman Console) for detailed logs

## Different Environments

To create additional environments (staging, production):

1. Duplicate the environment file
2. Update the URLs and credentials
3. Import the new environment file
4. Switch environments as needed

Example production environment:
```json
{
  "gateway_url": "https://api-gateway.yourdomain.com",
  "user_service_url": "https://user-service.yourdomain.com",
  "user_email": "prod-test@yourdomain.com",
  "user_password": "secure-prod-password"
}
```

## Contributing

When adding new endpoints:
1. Add the request to the appropriate folder
2. Include test scripts for validation
3. Update this README with new endpoint documentation
4. Test with different scenarios (success/error cases)