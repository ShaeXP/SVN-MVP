# Supabase Auth Testing Scripts

These PowerShell scripts test the Supabase Auth signup and login functionality to diagnose issues with user creation and email confirmation.

## Prerequisites

- PowerShell 5.1 or later
- Internet connection to reach Supabase Auth endpoints
- Gmail access for `svntest+*@gmail.com` addresses

## Scripts

### 1. `auth_signup_test.ps1`

**Purpose:** Creates a fresh user via Auth REST API and triggers confirmation email.

**Usage:**
```powershell
pwsh -File .\scripts\auth_signup_test.ps1
```

**What it does:**
- Generates unique email: `svntest+YYYYMMDDHHMMSS@gmail.com`
- Generates secure password: `Svn!YYYYMMDDHHMMSS!A1`
- Calls `/auth/v1/signup` endpoint
- Calls `/auth/v1/resend` to trigger confirmation email
- Prints full response for debugging

**Expected Success Response:**
```json
{
  "user": {
    "id": "uuid",
    "email": "svntest+timestamp@gmail.com",
    "email_confirmed_at": null,
    "created_at": "2024-01-01T00:00:00Z"
  },
  "session": null
}
```

**Common Error Responses:**
- `400 Bad Request`: Invalid email format, weak password, or signup disabled
- `422 Unprocessable Entity`: Email already exists
- `429 Too Many Requests`: Rate limiting
- `500 Internal Server Error`: Supabase service issue

### 2. `auth_password_login.ps1`

**Purpose:** Tests login with created credentials to verify user was actually created.

**Usage:**
```powershell
pwsh -File .\scripts\auth_password_login.ps1 -Email "svntest+YYYYMMDDHHMMSS@gmail.com" -Password "Svn!YYYYMMDDHHMMSS!A1"
```

**What it does:**
- Calls `/auth/v1/token?grant_type=password` endpoint
- Returns JWT token if successful
- Shows first 24 characters of JWT for verification

**Expected Success Response:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "expires_in": 3600,
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "uuid",
    "email": "svntest+timestamp@gmail.com"
  }
}
```

**Common Error Responses:**
- `400 Bad Request`: Invalid credentials or email not confirmed
- `401 Unauthorized`: Wrong email/password combination
- `422 Unprocessable Entity`: Account not confirmed (if email confirmation required)

## Troubleshooting

### Check Supabase Dashboard
1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Navigate to **Authentication** → **Users**
3. Look for the test user created
4. Check **Authentication** → **Logs** for detailed error messages

### Check Gmail
1. Look for emails to `svntest+*@gmail.com`
2. Check **Spam** folder if not in inbox
3. Look for emails from `noreply@supabase.co` or your custom SMTP

### Common Issues

**"Invalid JWT" errors:**
- Wrong anon key in script
- Project ref mismatch
- Supabase service down

**"Email signups disabled":**
- Check Supabase Dashboard → Authentication → Settings
- Ensure email signups are enabled

**"Rate limit exceeded":**
- Wait 1-2 minutes between test runs
- Use different email addresses

**"Email not confirmed":**
- Check if email confirmation is required in Supabase settings
- Look for confirmation email in Gmail
- Try the resend functionality

## Configuration

The scripts use these hardcoded values:
- **Project Ref:** `gnskowrijoouemlptrvr`
- **Base URL:** `https://gnskowrijoouemlptrvr.supabase.co`
- **Anon Key:** `sb_publishable_LhchOSgqgJp7lza44fB1eg_ye3V3uGS`

If you need to test a different project, update these values in both scripts.

## Success Criteria

✅ **Signup Test Passes:**
- Returns 200 with user object
- User appears in Supabase Dashboard → Auth → Users
- Confirmation email arrives in Gmail

✅ **Login Test Passes:**
- Returns 200 with valid JWT token
- JWT can be used for authenticated API calls
- User session is properly established

## Next Steps

If tests fail:
1. Check Supabase Dashboard for error logs
2. Verify project configuration
3. Test with Supabase CLI: `supabase auth users list`
4. Check email delivery settings in Supabase Dashboard
