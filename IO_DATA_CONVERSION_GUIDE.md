# Converting @io.Data to String in MoonBit

## Overview

When working with MoonBit's async I/O library (`@moonbitlang/async`), file reads and network operations return `&@io.Data` objects. This guide covers how to convert `@io.Data` to `String` using the built-in conversion methods.

## Key Conversion Methods

The `@io.Data` type provides three main conversion methods:

### 1. `.text()` - Convert to String (UTF-8)
```mbt
let data : &@io.Data = /* ... */
let text_string : String = data.text()
```

This is the primary method for converting binary data to a UTF-8 encoded String.

### 2. `.binary()` - Convert to Bytes
```mbt
let data : &@io.Data = /* ... */
let bytes : Bytes = data.binary()
```

Returns the raw byte data as a `Bytes` object.

### 3. `.json()` - Parse as JSON
```mbt
let data : &@io.Data = /* ... */
let json_value : JsonValue = data.json()
```

Parses the data as JSON (requires `@json` module).

## Practical Examples

### Example 1: Reading a File and Converting to String

Using **mizchi/x fs** library:

```mbt
async fn read_json_config(path : StringView) -> String {
  let file_data = @fs.read_file(path)
  let json_string = file_data.text()
  json_string
}
```

### Example 2: Reading from stdin/Reader

```mbt
async fn process_lines(input : &@io.Reader) -> Unit {
  // read_until returns Some(String) automatically
  while input.read_until("\n") is Some(line) {
    println("Got line: \{line}")
  }
}
```

### Example 3: WebSocket Message to String

From the async library examples:

```mbt
async fn echo_server() -> Unit {
  let server = @http.Server::new(@socket.Addr::parse("0.0.0.0:9001"))
  server.run_forever((request, _, conn) => {
    let ws = @websocket.from_http_server(request, conn)
    let msg = ws.recv()
    match msg.kind {
      Text => {
        // Convert @io.Data to String
        let text : String = msg.read_all().text()
        println("Received: \{text}")
        ws.send_text(text)
      }
      Binary => {
        // Convert @io.Data to Bytes
        let data : Bytes = msg.read_all().binary()
        println("Received binary data (\{data.length()} bytes)")
        ws.send_binary(data)
      }
    }
  })
}
```

### Example 4: HTTP Response Body

```mbt
async fn fetch_and_parse(url : String) -> String {
  let (_response, body) = @http.get_stream(url)
  defer body.close()
  // read_all() returns &@io.Data
  // .text() converts to String
  let content : String = body.read_all().text()
  content
}
```

## Bytes Type in MoonBit

MoonBit supports convenient Bytes initialization with string literals (UTF-8 encoded):

```mbt
// String literals as Bytes (UTF-8 encoded)
let xs : Bytes = "123"
let ys : Bytes = "你好，世界"

// Byte literals
let bs : Bytes = b"\x01\x02\x03"
```

### Unicode Escape Sequences

Note: Unicode escape sequences in Bytes and string literals are now deprecated in favor of hexadecimal escapes.

## Pattern: Chaining `.read_all().text()`

The most common pattern for file reading is:

```mbt
let data_ref = @fs.read_file("path/to/file.json")
let text_content = data_ref.text()  // Direct conversion to String

// Or in one line:
let text = @fs.read_file("path/to/file.json").text()
```

## Integration with mizchi/x fs Library

The **mizchi/x fs** package provides async file operations that return `&@io.Data`:

```mbt
// From mizchi/x/src/fs/fs_native.mbt
pub async fn read_file(path : StringView) -> &@io.Data raise IOError {
  @async_fs.read_file(path) catch {
    err => raise IOError::IOError(err.to_string())
  }
}
```

Usage:

```mbt
async fn load_service_account() -> String {
  let content = @fs.read_file("service_account.json")
  content.text()  // Convert to String
}
```

## Error Handling

When converting to JSON:

```mbt
async fn parse_config(path : StringView) -> Result[JsonValue, String] {
  try {
    let data = @fs.read_file(path)
    Ok(data.json())
  } catch {
    IOError(err) => Err("Failed to read file: \{err}")
    JsonError(err) => Err("Failed to parse JSON: \{err}")
  }
}
```

## Performance Notes

- `.text()` decodes UTF-8 once during the call
- `.binary()` returns a direct reference to the bytes without copying
- `.json()` parses JSON and creates value objects
- For large files, consider streaming with `@io.Reader` instead of `read_all()`

## Files Referenced in This Project

1. **mizchi/x fs library**: `/Users/ryota.suzuki/git/moonbit_googleauth/.mooncakes/mizchi/x/src/fs/fs_native.mbt`
   - Provides `read_file()` function

2. **Async examples**:
   - WebSocket echo server: `/Users/ryota.suzuki/git/moonbit_googleauth/.mooncakes/moonbitlang/async/examples/websocket_echo_server/main.mbt`
   - HTTP file server: `/Users/ryota.suzuki/git/moonbit_googleauth/.mooncakes/moonbitlang/async/examples/http_file_server/main.mbt`

3. **MoonBit async documentation**: https://mooncakes.io/assets/moonbitlang/async/io/reader.mbt.html

## Related Documentation

- [MoonBit async programming library](https://github.com/moonbitlang/async)
- [mooncakes.io - MoonBit package registry](https://mooncakes.io/)
- [mizchi/x - Cross-platform IO abstraction](https://github.com/mizchi/moonbit-x)

## Quick Reference

| Task | Code |
|------|------|
| Read file as string | `@fs.read_file("path").text()` |
| Read WebSocket text | `ws.recv().read_all().text()` |
| Read HTTP response | `@http.get_stream(url).read_all().text()` |
| Convert to bytes | `data.binary()` |
| Parse JSON | `data.json()` |
| Read until newline | `reader.read_until("\n")` returns `Some(String)` |
