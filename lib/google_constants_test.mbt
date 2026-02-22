///|
/// Google定数定義のテスト
test "auth_url is correctly defined" {
  assert_eq(
    auth_url.to_string(),
    "https://accounts.google.com/o/oauth2/v2/auth",
  )
}

///|
test "token_url is correctly defined" {
  assert_eq(token_url.to_string(), "https://oauth2.googleapis.com/token")
}

///|
test "revoke_url is correctly defined" {
  assert_eq(revoke_url, "https://oauth2.googleapis.com/revoke")
}

///|
test "userinfo_url is correctly defined" {
  assert_eq(userinfo_url, "https://www.googleapis.com/oauth2/v2/userinfo")
}

///|
test "scope_userinfo_email is defined" {
  assert_eq(
    scope_userinfo_email.to_string(),
    "https://www.googleapis.com/auth/userinfo.email",
  )
}

///|
test "scope_userinfo_profile is defined" {
  assert_eq(
    scope_userinfo_profile.to_string(),
    "https://www.googleapis.com/auth/userinfo.profile",
  )
}

///|
test "scope_drive is defined" {
  assert_eq(scope_drive.to_string(), "https://www.googleapis.com/auth/drive")
}

///|
test "scope_drive_readonly is defined" {
  assert_eq(
    scope_drive_readonly.to_string(),
    "https://www.googleapis.com/auth/drive.readonly",
  )
}

///|
test "scope_gmail_readonly is defined" {
  assert_eq(
    scope_gmail_readonly.to_string(),
    "https://www.googleapis.com/auth/gmail.readonly",
  )
}

///|
test "scope_gmail_send is defined" {
  assert_eq(
    scope_gmail_send.to_string(),
    "https://www.googleapis.com/auth/gmail.send",
  )
}

///|
test "scope_calendar is defined" {
  assert_eq(
    scope_calendar.to_string(),
    "https://www.googleapis.com/auth/calendar",
  )
}

///|
test "basic_scopes returns email and profile" {
  let scopes = basic_scopes()
  assert_eq(scopes.length(), 2)
  assert_eq(
    scopes[0].to_string(),
    "https://www.googleapis.com/auth/userinfo.email",
  )
  assert_eq(
    scopes[1].to_string(),
    "https://www.googleapis.com/auth/userinfo.profile",
  )
}

///|
test "drive_scopes returns drive scope" {
  let scopes = drive_scopes()
  assert_eq(scopes.length(), 1)
  assert_eq(scopes[0].to_string(), "https://www.googleapis.com/auth/drive")
}

///|
test "gmail_scopes returns gmail scopes" {
  let scopes = gmail_scopes()
  assert_eq(scopes.length(), 2)
  assert_eq(
    scopes[0].to_string(),
    "https://www.googleapis.com/auth/gmail.readonly",
  )
  assert_eq(scopes[1].to_string(), "https://www.googleapis.com/auth/gmail.send")
}

///|
test "calendar_scopes returns calendar scope" {
  let scopes = calendar_scopes()
  assert_eq(scopes.length(), 1)
  assert_eq(scopes[0].to_string(), "https://www.googleapis.com/auth/calendar")
}
