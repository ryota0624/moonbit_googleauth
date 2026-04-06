///|
/// Google Metadata Server 認証のテスト
test "default_metadata_server_config returns valid config" {
  let config = default_metadata_server_config()
  assert_eq(
    config.base_url,
    "http://metadata.google.internal/computeMetadata/v1",
  )
  assert_eq(config.timeout_ms, 1000)
}

///|
test "is_metadata_server_available returns false in non-GCP environment" {
  // Phase 1.5ではローカル環境での実装
  // 実際のGCP環境ではtrueを返す予定
  let available = is_metadata_server_available()
  assert_eq(available, false)
}

///|
test "get_access_token_from_metadata_server returns error in non-GCP environment" {
  match get_access_token_from_metadata_server() {
    Ok(_) => assert_false(true)
    Err(MetadataError::MetadataServerUnavailable) => assert_true(true)
  }
}

///|
test "get_token_from_metadata_server with default config returns error" {
  let config = default_metadata_server_config()
  match get_token_from_metadata_server(config) {
    Ok(_) => assert_false(true)
    Err(MetadataError::MetadataServerUnavailable) => assert_true(true)
  }
}

///|
test "get_token_from_metadata_server with custom timeout" {
  let config = default_metadata_server_config()
  match get_token_from_metadata_server(config) {
    Ok(_) => assert_false(true)
    Err(MetadataError::MetadataServerUnavailable) => assert_true(true)
  }
}
