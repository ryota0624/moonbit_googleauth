///|
/// Sample: ADC authorized_user credentials で Google userinfo を取得
///
/// Prerequisites:
///   gcloud auth application-default login
///
/// Run:
///   moon run cmd/main --target native
///
async fn main {
  println("=== Google Auth ADC Sample ===")
  println("")

  // Step 1: Load credentials from well-known location
  println("[1/4] Loading credentials from well-known location...")
  let (cred_type, json_str) = match @lib.load_json_from_well_known_location() {
    Ok(result) => result
    Err(err) => {
      println(
        "Error: Failed to load credentials. Make sure you have run: gcloud auth application-default login",
      )
      println("  Detail: " + err.to_string())
      return
    }
  }
  println("  Credential type: " + cred_type)
  if cred_type != "authorized_user" {
    println("Error: Expected authorized_user credentials, got: " + cred_type)
    return
  }
  let creds = match @lib.parse_authorized_user_key(json_str) {
    Ok(c) => c
    Err(err) => {
      println("Error: Failed to parse credentials: " + err.to_string())
      return
    }
  }
  match @lib.validate_authorized_user_credentials(creds) {
    Ok(_) => ()
    Err(err) => {
      println("Error: Invalid credentials: " + err.to_string())
      return
    }
  }
  println("  Credentials loaded successfully.")
  println("")

  // Step 2: Exchange refresh_token for access_token
  println("[2/4] Exchanging refresh_token for access_token...")
  let access_token = match @lib.exchange_refresh_token(creds) {
    Ok(token) => token
    Err(err) => {
      println("Error: Token exchange failed: " + err.to_string())
      return
    }
  }
  let token_preview = access_token[:10].to_string() + "..."
  println("  Access token obtained: " + token_preview)
  println("")

  // Step 3: Call userinfo endpoint
  println("[3/4] Calling Google userinfo endpoint...")
  let headers : Map[String, String] = {
    "Authorization": "Bearer " + access_token,
  }
  let (response, body) = @http.get(
    "https://www.googleapis.com/oauth2/v2/userinfo",
    headers~,
  ) catch {
    err => {
      println("Error: Userinfo request failed: " + err.to_string())
      return
    }
  }
  if response.code != 200 {
    let error_text = body.text() catch { _ => "<unreadable>" }
    let status_msg = "Error: Userinfo endpoint returned status " +
      response.code.to_string()
    println(status_msg)
    println("  Body: " + error_text)
    return
  }
  let body_text = body.text() catch {
    err => {
      println("Error: Failed to read response: " + err.to_string())
      return
    }
  }

  // Parse and display userinfo
  println("")
  println("=== User Info ===")
  let json = @json.parse(body_text) catch {
    _ => {
      println("  (raw): " + body_text)
      return
    }
  }
  match json {
    Object(obj) => {
      match obj.get("name") {
        Some(String(name)) => println("  Name:    " + name)
        _ => ()
      }
      match obj.get("email") {
        Some(String(email)) => println("  Email:   " + email)
        _ => ()
      }
      match obj.get("picture") {
        Some(String(pic)) => println("  Picture: " + pic)
        _ => ()
      }
      match obj.get("id") {
        Some(String(id)) => println("  ID:      " + id)
        _ => ()
      }
    }
    _ => println("  (raw): " + body_text)
  }

  // Step 4: List Google Cloud projects
  println("")
  println("[4/4] Listing Google Cloud projects...")
  let projects_url = "https://cloudresourcemanager.googleapis.com/v1/projects"
  let (proj_response, proj_body) = @http.get(projects_url, headers~) catch {
    err => {
      println("Error: Projects request failed: " + err.to_string())
      return
    }
  }
  if proj_response.code != 200 {
    let error_text = proj_body.text() catch { _ => "<unreadable>" }
    let status_msg = "Error: Projects endpoint returned status " +
      proj_response.code.to_string()
    println(status_msg)
    println("  Body: " + error_text)
    return
  }
  let proj_body_text = proj_body.text() catch {
    err => {
      println("Error: Failed to read response: " + err.to_string())
      return
    }
  }
  println("")
  println("=== Projects ===")
  let proj_json = @json.parse(proj_body_text) catch {
    _ => {
      println("  (raw): " + proj_body_text)
      return
    }
  }
  match proj_json {
    Object(obj) =>
      match obj.get("projects") {
        Some(Array(arr)) =>
          arr.each(fn(item) {
            match item {
              Object(p) => {
                let id = match p.get("projectId") {
                  Some(String(s)) => s
                  _ => "<unknown>"
                }
                let name = match p.get("name") {
                  Some(String(s)) => s
                  _ => "<unknown>"
                }
                println("  " + id + " (" + name + ")")
              }
              _ => ()
            }
          })
        _ => println("  No projects found")
      }
    _ => println("  (raw): " + proj_body_text)
  }
  println("")
  println("=== Done ===")
}
